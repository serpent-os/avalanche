/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.cli.run_controller
 *
 * Run Avalanche Controller
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.cli.run_controller;

import moss.core.cli;

import avalanche.server;
import avalanche.controller;

/**
 * Handle the `avalanche run controller` subcommand
 */
@CommandName("controller") @CommandHelp("start avalanche controller", "Run Avalanche Controller")
public struct RunControllerCommand
{
    BaseCommand pt;
    alias pt this;

    /**
     * Start a builder
     */
    @CommandEntry()
    int run(ref string[] args)
    {
        auto server = new ControllerServer();
        scope (exit)
        {
            server.stop();
            server.destroy();
        }
        return server.run();
    }
}
