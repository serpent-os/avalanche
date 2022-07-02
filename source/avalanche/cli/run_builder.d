/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.cli.run
 *
 * Run avalanche in some given mode
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.cli.run_builder;

import moss.core.cli;

import avalanche.server;
import avalanche.builder;

/**
 * Handle the `avalanche run builder` subcommand
 */
@CommandName("builder") @CommandHelp("start avalanche builder", "Run Avalanche Builder")
public struct RunBuilderCommand
{
    BaseCommand pt;
    alias pt this;

    /**
     * Start a builder
     */
    @CommandEntry()
    int run(ref string[] args)
    {
        auto server = new BuilderServer();
        scope (exit)
        {
            server.stop();
            server.destroy();
        }
        return server.run();
    }
}
