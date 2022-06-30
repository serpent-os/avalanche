/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.cli
 *
 * CLI definitions
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.cli;

public import moss.core.cli;
public import avalanche.cli.run_command;

/**
 * Core CLI for avalanche
 */
@RootCommand public struct AvalancheCLI
{
    BaseCommand pt;
    alias pt this;
}
