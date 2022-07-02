/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.server
 *
 * Core server setup. A server can be used with 
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.server;

import vibe.d;

/**
 * Implements the core server.
 */
public class Server
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
    }

    /**
     * Add a REST interface by its own @path attribute.
     */
    final void addInterface(T)(T iface) if (is(T == class))
    {
        router.registerRestInterface(iface);
    }

    /**
     * Add a web interface
     */
    final void addWeb(T)(T web) if (is(T == class))
    {
        router.registerWebInterface(web);
    }

    /**
     * Configure publically accessible file sharing
     */
    final void configureFileSharing(const(string) inputDirectory, const(string) webPrefix)
    in
    {
        assert(fileSettings is null, "Attempted to reconfigure file sharing");
    }
    do
    {

        fileSettings = new HTTPFileServerSettings();
        fileSettings.serverPathPrefix = webPrefix;
        router.get(format!"%s/*"(webPrefix), serveStaticFiles(inputDirectory, fileSettings));
    }

    /**
     * Get the server running
     */
    final int run()
    {
        return runEventLoop();
    }

    /**
     * Non-GC dependent stop helper
     */
    final void stop()
    {
        listener.stopListening();
    }

private:

    URLRouter router;
    HTTPServerSettings settings;
    HTTPFileServerSettings fileSettings;
    HTTPListener listener;
}
