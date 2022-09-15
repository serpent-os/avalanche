/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.app
 *
 * Main application runtime for build control
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.app;

import vibe.d;
import avalanche.rest;

/**
 * Main entry point from the server side, storing our
 * databases and interfaces.
 */
public final class AvalancheApp
{
    /**
     * Construct a new SummitApp
     */
    this() @safe
    {
        settings = new HTTPServerSettings();
        settings.disableDistHost = true;
        settings.useCompressionIfPossible = true;
        settings.bindAddresses = ["127.0.0.1"];
        settings.port = 8082;
        settings.serverString = "avalanche/0.0.1";

        /* Bring up our core routes */
        router = new URLRouter();
        auto bAPI = new BuildAPI();
        bAPI.configure(router);
        router.rebuild();
    }

    /**
     * Start the app properly
     */
    void start() @safe
    {
        listener = listenHTTP(settings, router);
    }

    /**
     * Correctly stop the application
     */
    void stop() @safe
    {
        listener.stopListening();
    }

private:

    URLRouter router;
    HTTPServerSettings settings;
    HTTPListener listener;
}
