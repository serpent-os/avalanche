/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.setup
 *
 * Setup UI for avalanche
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module avalanche.setup;

import avalanche.models;
import moss.service.context;
import moss.service.server;
import vibe.d;

/**
 * Main web frontend for Avalanche
 */
@path("/") public final class AvalancheSetup : Application
{

    @noRoute override void initialize(ServiceContext context) @safe
    {
        this.context = context;
        _router = new URLRouter();
        _router.registerWebInterface(this);
    }

    /**
     * / redirects to make our intent obvious
     */
    void index() @safe
    {
        immutable path = request.path.endsWith("/") ? request.path[0 .. $ - 1] : request.path;
        redirect(format!"%s/setup"(path));
    }

    /**
     * Real index page
     */
    @path("setup") @method(HTTPMethod.GET)
    void setupIndex() @safe
    {
        render!"setup/index.dt";
    }

    /**
     * Attempt to apply setup.
     *
     * Params:
     *      instanceURI = Our public instance URI
     *      description = Friendly description for our instance
     *      username = Administrator username
     *      emailAddress = Admin email
     *      password = Admin password
     *      confirmPassword = Confirmation that password matches
     */
    @path("setup/apply") @method(HTTPMethod.POST) void applySetup(string instanceURI,
            string description, ValidUsername username,
            ValidEmail emailAddress, ValidPassword password, Confirm!"password" confirmPassword) @sanitizeUTF8
    {
        Settings appSettings;

        /* Try to get our settings */
        getSettings(context.appDB).match!((Settings s) { appSettings = s; }, (DatabaseError err) {
            throw new HTTPStatusException(HTTPStatus.internalServerError, err.message);
        });

        /* Basic settings */
        appSettings.instanceDescription = description;
        appSettings.instanceURI = instanceURI;
        appSettings.setupComplete = true;

        /*  Add admin account :) */
        context.accountManager.registerUser(username, password, emailAddress).match!((Account acct) {
            logError("New user: %s", acct);
            immutable err = context.accountManager.addAccountToGroups(acct.id,
                [BuiltinGroups.Admin, BuiltinGroups.Users]);
            enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
        }, (DatabaseError err) {
            throw new HTTPStatusException(HTTPStatus.internalServerError, err.message);
        });


        /* Now save the settings! */
        immutable err = context.appDB.update((scope tx) => appSettings.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);

        /* Done! */
        completed.emit();
        redirect("/");
    }

    /**
     * Returns: router property
     */
    @noRoute override pure @property URLRouter router() @safe @nogc nothrow
    {
        return _router;
    }

    @noRoute override void close() @safe
    {
    }

private:

    ServiceContext context;
    URLRouter _router;
}
