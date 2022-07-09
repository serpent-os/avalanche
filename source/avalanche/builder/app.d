/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.builder.app
 *
 * Actual Builder implementation
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.builder.app;

import std.algorithm : each;
import std.concurrency : initOnce;
import std.exception : assumeWontThrow;
import std.file : mkdir;
import moss.db.keyvalue;
import moss.db.keyvalue.interfaces;

private __gshared BuilderApp __appInstance = null;

/**
 * Simple state tracking.
 */
public enum AppStage
{
    AwaitingSetup,
    AwaitingEnrolment,
    Active,
}

/**
 * Return a shared instance builder app
 */
public static BuilderApp builderApp() @safe nothrow
{
    auto ret = assumeWontThrow(() @trusted {
        return initOnce!__appInstance(new BuilderApp());
    }());
    return ret;
}

/**
 * The "real" Builder application - gated from REST/WEB
 */
public final class BuilderApp
{

    /**
     * Start the application proper - prior to web serve.
     */
    public void startup() @safe
    {
        immutable requiredDirs = ["db",];
        requiredDirs.each!((d) => d.mkdir());
        db = Database.open("lmdb://db/builderDB",
                DatabaseFlags.CreateIfNotExists).tryMatch!((Database db) => db);
    }

    void shutdown() @safe
    {
        db.close();
    }

package:

    AppStage stage = AppStage.AwaitingSetup;
    Database db;
}
