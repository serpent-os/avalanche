/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * main
 *
 * Main entry point into Avaanche
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module main;

import avalanche.app;
import avalanche.models;
import avalanche.setup;
import libsodium;
import moss.service.context;
import moss.service.models;
import moss.service.server;
import std.conv : to;
import std.getopt;
import std.path : absolutePath, asNormalizedPath;
import std.string : format;
import vibe.d;

/**
 * Gets our builder up and running
 *
 * Params:
 *      args = CLI arguments
 * Returns: 0 if everything went to plan
 */
int main(string[] args) @safe
{
    ushort portNumber = 8082;
    /* It's safer to set this to localhost and allow the user to override (not append!) */
    static string[] defaultAddress = ["localhost"];
    string[] cmdLineAddresses;

    auto opts = () @trusted {
        return getopt(args, config.bundling, "p|port", "Specific port to serve on",
                &portNumber, "a|address", "Host address to bind to", &cmdLineAddresses);
    }();

    if (opts.helpWanted)
    {
        defaultGetoptPrinter("avalanche", opts.options);
        return 1;
    }

    logInfo("Initialising libsodium");
    immutable rc = () @trusted { return sodium_init(); }();
    enforce(rc == 0, "Failed to initialise libsodium");

    logInfo("Starting Avalanche");
    auto rootDir = absolutePath(".").asNormalizedPath.to!string;

    auto server = new Server!(AvalancheSetup, AvalancheApp)(rootDir);
    scope (exit)
    {
        server.close();
    }
    server.serverSettings.port = portNumber;
    server.serverSettings.serverString = "avalanche/0.0.1";
    server.serverSettings.sessionIdCookie = "avalanche.session_id";
    server.serverSettings.bindAddresses = cmdLineAddresses.empty ? defaultAddress : cmdLineAddresses;
    immutable dbErr = server.context.appDB.update(
            (scope tx) => tx.createModel!(SummitEndpoint, Settings));
    enforceHTTP(dbErr.isNull, HTTPStatus.internalServerError, dbErr.message);

    const settings = server.context.appDB.getSettings.tryMatch!((Settings s) => s);
    server.mode = settings.setupComplete ? ApplicationMode.Main : ApplicationMode.Setup;
    server.start();

    return runApplication();
}
