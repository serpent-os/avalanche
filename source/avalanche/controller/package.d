/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.controller
 *
 * REST API for the controller mechanism
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module avalanche.controller;

public import avalanche.server;

import avalanche.controller.rest;
import avalanche.controller.web;
import avalanche.auth.session;
import avalanche.auth.users;
import std.exception : enforce;
import std.file : mkdirRecurse;

/**
 * Extend general server for Controller use
 */
final class ControllerServer : Server
{
    /**
     * Construct a new ControllerServer
     */
    this()
    {
        "db/controller/users".mkdirRecurse();
        users = new UserManager("lmdb://db/controller/users");
        addInterface(new Controller());
        addWeb(new ControllerWeb());
        addWeb(new SessionManagement(site, users));
        configureFileSharing("public", "/static");
        siteConfig = site;

        auto result = users.connect();
        enforce(result.isNull);
    }

    ~this()
    {
        users.close();
    }

private:

    UserManager users;
}
