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

module avalanche.cli.run_node;

import moss.core.cli;

import avalanche.server;
import avalanche.node;

/**
 * Handle the `avalanche run node` subcommand
 */
@CommandName("node") @CommandHelp("start avalanche node", "Run Avalanche Node")
public struct RunNodeCommand
{
    BaseCommand pt;
    alias pt this;

    /**
     * Start a node
     */
    @CommandEntry()
    int run(ref string[] args)
    {
        auto server = new Server();
        server.addInterface(new NodeApp());
        return server.run();
    }
}
