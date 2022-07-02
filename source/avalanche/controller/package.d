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
        addInterface(new Controller());
        addWeb(new WebApp());
        configureFileSharing("public", "/static/");
    }
}
