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

import avalanche.builder.app;
import avalanche.builder.rest;
import avalanche.builder.web;
import avalanche.auth.session;

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
        auto web = new BuilderWeb();
        auto session = new SessionManagement(site, web.context);
        addWeb(web);
        addWeb(session);
        configureFileSharing("public", "/static");
        this.siteConfig = site;

        builderApp.startup();
    }

    ~this() @safe
    {
        builderApp.shutdown();
    }
}
