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

import vibe.d;
import vibe.core.process;
import std.algorithm : map;
import std.string : join;
import std.path : buildPath;
import std.string : startsWith;
import std.file : rmdirRecurse, mkdirRecurse, exists;
import std.array : appender;

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
    this(string rootDir, PackageBuild def) @safe
    {
        this.def = def;
        this.rootDir = rootDir;
        cacheDir = rootDir.buildPath("avl", "cache");
        workDir = rootDir.buildPath("avl", "work");
        sourceDir = workDir.buildPath("source");
        assetDir = rootDir.buildPath("avl", "assets");

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
        workDir.mkdirRecurse();
        assetDir.mkdirRecurse();

        ensureCached();
        checkoutRecipe();
        configureRoot();
        buildRecipe();
        publishArtefacts();
    }

private:

    void ensureCached() @safe
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
    }

    /**
     * Get the recipe
     */
    void checkoutRecipe() @safe
    {
        logInfo("Cloning to work tree");
        string[string] env;
        string[] cmd = ["git", "clone", "--", def.uri, sourceDir,];
        auto p = spawnProcess(cmd, env, Config.none, NativePath(workDir));
        auto statusCode = p.wait();

        logInfo(format!"Reset clone to ref %s"(def.commitRef));
        cmd = ["git", "reset", "--hard", def.commitRef,];
        auto pc = spawnProcess(cmd, env, Config.none, NativePath(sourceDir));
        statusCode = pc.wait();
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
    void buildRecipe() @safe
    {
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
        import std.stdio : stdout;

        auto stdin_fake = pipe();

        auto pid = () @trusted {
            return spawnProcess(cmd, stdin_fake.readEnd, stdout, stdout, env,
                    Config.none, sourceDir);
        }();
        auto p = adoptProcessID(pid);

        auto statusCode = p.wait();
    }

    /**
     * make the stones available
     */
    void publishArtefacts() @safe nothrow
    {
        logInfo("Publishing artefacts");
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
}
