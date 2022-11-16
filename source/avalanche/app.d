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
import moss.db.keyvalue;
import moss.db.keyvalue.errors;
import moss.db.keyvalue.orm;
import moss.service.accounts;
import moss.service.models.endpoints;
import moss.service.sessionstore;
import moss.service.tokens;
import moss.service.tokens.manager;
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

        accountManager = new AccountManager(dbPath);

        immutable driver = format!"lmdb://%s"(dbPath.buildPath("appDB"));
        appDB = Database.open(driver, DatabaseFlags.CreateIfNotExists)
            .tryMatch!((Database db) => db);
        immutable dbErr = appDB.update((scope tx) => tx.createModel!(SummitEndpoint));
        enforceHTTP(dbErr.isNull, HTTPStatus.internalServerError, dbErr.message);

        tokenManager = new TokenManager(statePath);
        logInfo(format!"Instance pubkey: %s"(tokenManager.publicKey));

        router = new URLRouter();

        /* Set up the server */
        serverSettings = new HTTPServerSettings();
        serverSettings.errorPageHandler = &errorHandler;
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
        bAPI.configure(appDB, tokenManager, accountManager, router);

        auto web = new AvalancheWeb(accountManager, tokenManager);
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
        appDB.close();
        accountManager.close();
    }

    /**
     * Handle erronous requests
     */
    void errorHandler(HTTPServerRequest req, HTTPServerResponse res, HTTPServerErrorInfo error) @safe
    {
        res.render!("errors/generic.dt", req, error);
    }

private:

    URLRouter router;
    HTTPFileServerSettings fileSettings;
    SessionStore sessionStore;
    HTTPServerSettings serverSettings;
    HTTPListener listener;
    AccountManager accountManager;
    TokenManager tokenManager;
    Database appDB;
}
