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

/**
 * Handle the `avalanche run` subcommand
 */
@CommandName("run") @CommandHelp("run avalanche daemon", "Run avalanche daemons")
public struct RunCommand
{
    BaseCommand pt;
    alias pt this;
}
