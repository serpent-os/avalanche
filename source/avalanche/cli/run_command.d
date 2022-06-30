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

module avalanche.cli.run_command;

import moss.core.cli;
import std.experimental.logger;

import avalanche.server;
import avalanche.controller;
import avalanche.web;
import vibe.d;

/**
 * Handle the `avalanche run` subcommand
 */
@CommandName("run") @CommandHelp("run the avalanche daemon", "Run Avalanche Daemon locally")
public struct RunCommand
{
    BaseCommand pt;
    alias pt this;

    @CommandEntry()
    int run(ref string[] args)
    {
        auto server = new Server();
        server.addInterface(new Controller());
        server.addWeb(new WebApp());
        server.configureFileSharing("public", "/static");
        return runEventLoop();
    }
}
