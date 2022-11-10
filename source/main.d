/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * main
 *
 * Main entry point into Avaanche
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module main;

import vibe.d;
import avalanche.app;
import std.path : absolutePath, asNormalizedPath;
import std.string : format;
import std.conv : to;

/**
 * Gets our builder up and running
 *
 * Params:
 *      args = CLI arguments
 * Returns: 0 if everything went to plan
 */
int main(string[] args)
{
    logInfo("Starting Avalanche");
    auto rootDir = absolutePath(".").asNormalizedPath.to!string;
    logInfo(format!"Root dir: %s"(rootDir));
    auto app = new AvalancheApp(rootDir);
    app.start();
    scope (exit)
    {
        app.stop();
    }
    return runApplication();
}