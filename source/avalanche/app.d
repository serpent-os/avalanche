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
import moss.service.models.endpoints;
import moss.service.sessionstore;
import std.file : mkdirRecurse;
import std.path : buildPath;
import vibe.d;
import moss.service.context;

/**
 * Main entry point from the server side, storing our
 * databases and interfaces.
 */
public final class AvalancheApp
{
    /**
     * Construct a new app
     */
    this(ServiceContext context) @safe
    {
        router = new URLRouter();

        /* Set up the server */
        serverSettings = new HTTPServerSettings();
        serverSettings.errorPageHandler = &errorHandler;
        serverSettings.disableDistHost = true;
        serverSettings.useCompressionIfPossible = true;
        serverSettings.port = 8082;
        serverSettings.sessionOptions = SessionOption.httpOnly;
        serverSettings.serverString = "avalanche/0.0.1";
        serverSettings.sessionIdCookie = "avalanche.session_id";

        /* Session persistence */
        sessionStore = new DBSessionStore(context.dbPath.buildPath("session"));
        serverSettings.sessionStore = sessionStore;

        /* File settings for /static/ serving */
        fileSettings = new HTTPFileServerSettings();
        fileSettings.serverPathPrefix = "/static";
        //fileSettings.maxAge = 30.days;
        fileSettings.options = HTTPFileServerOption.failIfNotFound;
        router.get("/static/*",
                serveStaticFiles(context.rootDirectory.buildPath("static/"), fileSettings));

        /* Bring up our core routes */
        auto bAPI = new BuildAPI(context);
        bAPI.configure(router);

        auto web = new AvalancheWeb(context);
        web.configure(router);
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
        context.close();
    }

    /**
     * Handle erronous requests
     */
    void errorHandler(HTTPServerRequest req, HTTPServerResponse res, HTTPServerErrorInfo error) @safe
    {
        immutable bool needLogin = error.code == HTTPStatus.forbidden
            && retrieveToken(req, res).isNull;

        if (needLogin)
        {
            res.render!("errors/login.dt", req, error);
        }
        else
        {
            res.render!("errors/generic.dt", req, error);
        }
    }

private:

    URLRouter router;
    HTTPFileServerSettings fileSettings;
    SessionStore sessionStore;
    HTTPServerSettings serverSettings;
    HTTPListener listener;
    ServiceContext context;
}
