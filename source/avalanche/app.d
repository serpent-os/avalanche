/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.app
 *
 * Main application runtime for build control
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module avalanche.app;

import avalanche.rest;
import avalanche.web;
import moss.db.keyvalue;
import moss.db.keyvalue.errors;
import moss.db.keyvalue.orm;
import moss.service.context;
import moss.service.models.endpoints;
import moss.service.server;
import moss.service.sessionstore;
import std.file : mkdirRecurse;
import std.path : buildPath;
import vibe.d;

/**
 * Main entry point from the server side, storing our
 * databases and interfaces.
 */
public final class AvalancheApp : Application
{
    /**
     * Construct a new app
     */
    override void initialize(ServiceContext context) @safe
    {
        _router = new URLRouter();

        /* Bring up our core routes */
        auto bAPI = new BuildAPI(context);
        bAPI.configure(router);

        auto web = new AvalancheWeb(context);
        web.configure(router);
    }

    override void close() @safe {}

    override pure @property URLRouter router() @safe @nogc nothrow
    {
        return _router;
    }

private:

    URLRouter _router;
    ServiceContext context;
}
