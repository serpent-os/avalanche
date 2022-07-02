/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.builder
 *
 * Builder Server
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module avalanche.builder;

public import avalanche.server;

import avalanche.builder.rest;
import avalanche.builder.web;

/**
 * Extend general server for Builder use
 */
final class BuilderServer : Server
{
    /**
     * Construct a new BuilderServer
     */
    this()
    {
        addInterface(new Builder());
        addWeb(new BuilderWeb());
        configureFileSharing("public", "/static");
    }
}
