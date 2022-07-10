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

import std.algorithm : each, filter;
import std.concurrency : initOnce;
import std.exception : assumeWontThrow;
import std.file : mkdir, exists;
import avalanche.auth.users;
import std.exception : enforce;

private __gshared BuilderApp __appInstance = null;

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

    this()
    {
        users = new UserManager("lmdb://db/userDB");
    }

    /**
     * Start the application proper - prior to web serve.
     */
    public void startup() @safe
    {
        immutable requiredDirs = ["db",];
        requiredDirs.filter!((p) => !p.exists)
            .each!((d) => d.mkdir());

        /* Connect user db */
        auto result = users.connect();
        enforce(result.isNull, "Cannot establish connection to UserDB");
    }

    void shutdown() @safe
    {
        users.close();
    }

package:

    UserManager users;
}
