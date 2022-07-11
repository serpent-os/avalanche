/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.controller.web
 *
 * Web interface for the controller
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module avalanche.controller.web;

import vibe.d;
import vibe.web.auth;

public import avalanche.server.site_config;
import avalanche.server.context;

public static SiteConfiguration site = SiteConfiguration("Controller", "tabler-compass");

/**
 * Placeholder for real authentication.
 */
public struct ControllerAuth
{

}

/**
 * Implementation of a controller for builders
 */
@requiresAuth public final class ControllerWeb
{
    /**
     * Gate web access behind a session token
     */
    @noRoute ControllerAuth authenticate(HTTPServerRequest req, HTTPServerResponse res)
    {
        enforceHTTP(context.loggedIn, HTTPStatus.forbidden);
        return ControllerAuth();
    }

    /**
     * Return the index page
     */
    @anyAuth void index() @safe
    {
        render!("controller/index.dt", context, site);
    }

    WebContext context;
}
