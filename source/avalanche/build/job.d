/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.build.job
 *
 * Module level types
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module avalanche.build.job;

public import avalanche.build : PackageBuild;

import avalanche.models.settings;
import moss.core.util;
import moss.service.context;
import moss.service.interfaces;
import moss.service.models.endpoints;
import moss.service.tokens.refresh;
import std.algorithm : filter, map;
import std.array : appender, array;
import std.experimental.logger.core;
import std.file : dirEntries, exists, mkdirRecurse, rmdirRecurse, SpanMode;
import std.path : buildPath, baseName, dirName;
import std.range : chain;
import std.stdio : File;
import std.string : startsWith, join;
import vibe.core.process;
import vibe.d;

/**
 * Encapsulation of the entire build job from cloning
 * to building.
 *
 * This should be constructed in a runTask() call to ensure
 * proper fiber multiplexing
 */
public final class BuildJob
{

    @disable this();

    /**
     * Construct a new BuildJob from the given definition
     */
    this(ServiceContext context, PackageBuild def, SummitEndpoint endpoint) @safe
    {
        this.context = context;
        this.def = def;
        this.rootDir = context.rootDirectory;
        this.endpoint = endpoint;

        cacheDir = context.cachePath;
        workDir = context.statePath.buildPath("work");
        sourceDir = workDir.buildPath("source");
        /* Job specific path */
        assetDir = rootDir.buildPath("public".buildPath(to!string(def.buildID)));

        /* Eventually compressed */
        logFile = assetDir.buildPath("build.log");

        /* Determine the cache portion of the URI */
        auto uri = URL(def.uri);
        auto path = uri.path.toString();
        if (path.startsWith("/"))
        {
            path = path[1 .. $];
        }
        auto portion = uri.host.buildPath(path);

        /* We expect the recipe tree cloned here */
        cacheDir = cacheDir.buildPath(portion);
    }

    /**
     * Encapsulate the build
     */
    void run() @safe
    {
        logInfo("Beginning build");

        /* Ensure we have a usable workdir */
        if (workDir.exists)
        {
            workDir.rmdirRecurse();
        }

        if (assetDir.exists)
        {
            assetDir.rmdirRecurse();
        }

        workDir.mkdirRecurse();
        assetDir.mkdirRecurse();

        if (!ensureCached())
        {
            publishStatus(false);
            return;
        }
        if (!checkoutRecipe())
        {
            publishStatus(false);
            return;
        }
        configureRoot();
        if (!buildRecipe())
        {
            publishStatus(false);
            return;
        }
        publishStatus(true);
    }

private:

    bool ensureCached() @safe
    {
        scope (failure)
        {
            logError("Failed to checkout the recipe");
            cacheDir.rmdirRecurse();
        }

        string[] cmd;
        string cmdWorkDir;

        /* We now need the cache :) */
        if (!cacheDir.exists)
        {
            cacheDir.mkdirRecurse();
            cmd = ["git", "clone", "--mirror", "--", def.uri, cacheDir,];
            cmdWorkDir = rootDir;
            logInfo(format!"Creating mirror clone of %s"(def.uri));
        }
        else
        {
            /* Update the clone */
            cmd = ["git", "remote", "update",];
            cmdWorkDir = cacheDir;
            logInfo(format!"Updating mirror clone of %s"(def.uri));
        }

        string[string] env;
        auto p = spawnProcess(cmd, env, Config.none, NativePath(cmdWorkDir));
        auto statusCode = p.wait();
        return statusCode == 0;
    }

    /**
     * Get the recipe
     */
    bool checkoutRecipe() @safe
    {
        logInfo("Cloning to work tree");
        string[string] env;
        string[] cmd = ["git", "clone", "--", def.uri, sourceDir,];
        auto p = spawnProcess(cmd, env, Config.none, NativePath(workDir));
        auto statusCode = p.wait();

        if (statusCode != 0)
        {
            return false;
        }

        logInfo(format!"Reset clone to ref %s"(def.commitRef));
        cmd = ["git", "reset", "--hard", def.commitRef,];
        auto pc = spawnProcess(cmd, env, Config.none, NativePath(sourceDir));
        statusCode = pc.wait();
        return statusCode == 0;
    }

    /**
     * Configure the root build tree.
     */
    void configureRoot() @safe
    {
        logInfo("Configuring recipe root");

        immutable collections = def.collections.map!((c) {
            return format!"
        - %s:
            uri: \"%s\"
            description: \"%s\"
            priority: %s
"(c.name, c.indexURI, "Remotely configured collection", c.priority);
        }).join("\n");

        immutable boulderConf = format!"
- avalanche:
    collections:
%s"(collections);

        immutable confDir = workDir.buildPath("etc", "boulder", "profiles.conf.d");
        immutable confFile = confDir.buildPath("avalanche.conf");
        confDir.mkdirRecurse();
        import std.file : write;

        confFile.write(boulderConf);
    }

    /**
     * Actually *build* the recipe
     */
    bool buildRecipe() @safe
    {
        auto logOutputFile = File(logFile, "w");
        scope (exit)
        {
            logOutputFile.close();
        }

        logInfo(format!"Building recipe %s"(def.relativePath));
        string[string] env;
        string[] cmd = [
            "sudo",
            //"-n",
            "boulder", "build", "-o", assetDir, "-p", "avalanche", "-C",
            workDir, "-a", def.buildArchitecture, "-j", "0", "--",
            def.relativePath,
        ];

        import std.process : spawnProcess, pipe;

        auto stdin_fake = pipe();

        auto pid = () @trusted {
            return spawnProcess(cmd, stdin_fake.readEnd, logOutputFile,
                    logOutputFile, env, Config.none, sourceDir);
        }();
        auto p = adoptProcessID(pid);

        auto statusCode = p.wait();
        return statusCode == 0;
    }

    /** 
     * Publish the build status to Summit
     */
    void publishStatus(bool succeeded) @safe
    {
        if (!ensureEndpointUsable(endpoint, context))
        {
            logError(format!"Unable to publish status for %s"(def));
            return;
        }
        auto api = new RestInterfaceClient!SummitAPI(endpoint.hostAddress);
        api.requestFilter = (req) {
            req.headers["Authorization"] = format!"Bearer %s"(endpoint.apiToken);
        };

        auto col = scanCollectables();

        /**
         * For now - everything fails.
         */
        try
        {
            if (succeeded)
            {
                api.buildSucceeded(def.buildID, col, NullableToken());
            }
            else
            {
                api.buildFailed(def.buildID, col, NullableToken());
            }
        }
        catch (Exception ex)
        {
            logError(ex.message);
        }
    }

    /** 
     * Returns: A set of collectables for the build
     */
    Collectable[] scanCollectables() @safe
    {
        auto settings = context.appDB.getSettings().tryMatch!((Settings s) => s);

        auto diskResults = () @trusted {
            return assetDir.dirEntries(SpanMode.shallow, false).map!((n) => n.name).array;
        }();
        auto allResults = diskResults.chain([logFile]).filter!((f) => f.exists)
            .map!((f) {
                CollectableType t = CollectableType.Unknown;
                if (f.endsWith(".bin"))
                {
                    t = CollectableType.Manifest;
                }
                else if (f.endsWith(".log") || f.endsWith(".log.gz"))
                {
                    t = CollectableType.Log;
                }
                else if (f.endsWith(".stone"))
                {
                    t = CollectableType.Package;
                }
                auto uri = format!"%s/assets/%s/%s"(settings.instanceURI, f.dirName, f.baseName);
                return Collectable(t, uri, computeSHA256(f, true));
            });
        return () @trusted { return allResults.array; }();
    }

    /**
     * Build definition
     */
    PackageBuild def;

    /**
     * Root directory for all ops
     */
    string rootDir;

    /**
     * Where do we cache things?
     */
    string cacheDir;

    /**
     * Where will our work take place..?
     */
    string workDir;

    /**
     * Where will we clone to?
     */
    string sourceDir;

    /**
     * Where do we sync assets?
     */
    string assetDir;

    string logFile;

    ServiceContext context;

    /** 
     * From whence we came
     */
    SummitEndpoint endpoint;
}
