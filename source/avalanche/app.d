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

import avalanche.rest;
import avalanche.web;
import moss.service.sessionstore;
import std.file : mkdirRecurse;
import std.path : buildPath;
import vibe.d;

/**
 * Main entry point from the server side, storing our
 * databases and interfaces.
 */
public final class AvalancheApp
{
    /**
     * Construct a new SummitApp
     */
    this(string rootDir) @safe
    {
        immutable statePath = rootDir.buildPath("state");
        immutable dbPath = statePath.buildPath("db");
        dbPath.mkdirRecurse();

        router = new URLRouter();

        /* Set up the server */
        serverSettings = new HTTPServerSettings();
        serverSettings.disableDistHost = true;
        serverSettings.useCompressionIfPossible = true;
        serverSettings.port = 8082;
        serverSettings.sessionOptions = SessionOption.secure | SessionOption.httpOnly;
        serverSettings.serverString = "avalanche/0.0.1";
        serverSettings.sessionIdCookie = "avalanche.session_id";

        /* Session persistence */
        sessionStore = new DBSessionStore(dbPath.buildPath("session"));
        serverSettings.sessionStore = sessionStore;

        /* File settings for /static/ serving */
        fileSettings = new HTTPFileServerSettings();
        fileSettings.serverPathPrefix = "/static";
        //fileSettings.maxAge = 30.days;
        fileSettings.options = HTTPFileServerOption.failIfNotFound;
        router.get("/static/*", serveStaticFiles(rootDir.buildPath("static/"), fileSettings));

        /* Bring up our core routes */
        auto bAPI = new BuildAPI(rootDir);
        bAPI.configure(router);

        auto web = new AvalancheWeb();
        web.configure(router);

        router.rebuild();
    }

    /**
     * Start the app properly
     */
    void start() @safe
    {
        listener = listenHTTP(serverSettings, router);
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
    HTTPFileServerSettings fileSettings;
    SessionStore sessionStore;
    HTTPServerSettings serverSettings;
    HTTPListener listener;
}
