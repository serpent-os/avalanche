/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.server
 *
 * Core server setup
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.server;

import vibe.d;

/**
 * Implements the core server.
 */
public final class Server
{
    this()
    {
        router = new URLRouter();
        settings = new HTTPServerSettings();
        settings.disableDistHost = true;
        settings.useCompressionIfPossible = true;
        /* Force to localhost 8081 */
        settings.bindAddresses = ["127.0.0.1",];
        settings.port = 8081;
        listener = listenHTTP(settings, router);

        fileSettings = new HTTPFileServerSettings();
        fileSettings.serverPathPrefix = "/static";

        /* Serve static files.. */
        router.get("/static/*", serveStaticFiles("public/", fileSettings));
    }

    /**
     * Add a REST interface by its own @path attribute.
     */
    void addInterface(T)(T iface)
    {
        router.registerRestInterface(iface);
    }

    void addWeb(T)(T web)
    {
        router.registerWebInterface(web);
    }

private:

    URLRouter router;
    HTTPServerSettings settings;
    HTTPFileServerSettings fileSettings;
    HTTPListener listener;
}
