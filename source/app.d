/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * main
 *
 * Main entry point into Avalanche
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module main;

import avalanche.cli;
import moss.core.logger;

int main(string[] args)
{
    configureLogger();

    /* Everything can happen via CLI execution */
    auto cli = cliProcessor!AvalancheCLI(args);
    auto run = cli.addCommand!RunCommand;
    run.addCommand!RunBuilderCommand;
    return cli.process(args);
}
