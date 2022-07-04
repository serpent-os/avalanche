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

import std.concurrency : initOnce;
import std.exception : assumeWontThrow;

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

package:

    AppStage stage = AppStage.AwaitingSetup;
}
