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
    auto app = new AvalancheApp();
    app.start();
    scope (exit)
    {
        app.stop();
    }
    return runApplication();
}
