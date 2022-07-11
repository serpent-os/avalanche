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

public import avalanche.server.site_config;
public import avalanche.server.context;

/**
 * Implements the core server.
 */
public class Server
{
    /**
     * Lazy - require super constructor for initialisation
     */
    this(ushort portNumber = 8081)
    {
        router = new URLRouter();
        settings = new HTTPServerSettings();
        settings.disableDistHost = true;
        settings.useCompressionIfPossible = true;
        settings.errorPageHandler = &errorHandler;
        /* Force to localhost 8081 */
        settings.bindAddresses = ["127.0.0.1",];
        settings.port = portNumber;
        /* TODO: Incorporate component into this, i.e. ".builder." */
        settings.sessionIdCookie = "avalanche.session_id";
        settings.sessionOptions = SessionOption.httpOnly | SessionOption.secure;
        settings.sessionStore = new MemorySessionStore();
        listener = listenHTTP(settings, router);
    }

    /**
     * Without the site config we can't handle error pages. :)
     */
    pure @property void siteConfig(SiteConfiguration config) @safe @nogc nothrow
    {
        this.site = config;
    }

    /**
     * Add a REST interface by its own @path attribute.
     */
    void addInterface(T)(T iface) if (is(T == class))
    {
        router.registerRestInterface(iface);
    }

    /**
     * Add a web interface
     */
    void addWeb(T)(T web) if (is(T == class))
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

    void errorHandler(HTTPServerRequest req, HTTPServerResponse res, HTTPServerErrorInfo error)
    {
        auto site = this.site;
        if (error.code == HTTPStatus.forbidden)
        {
            res.render!("error_forbidden.dt", site, error, req);
        }
        else
        {
            res.render!("error.dt", site, error, req);
        }
    }

    URLRouter router;
    HTTPServerSettings settings;
    HTTPFileServerSettings fileSettings;
    HTTPListener listener;
    SiteConfiguration site;
}
