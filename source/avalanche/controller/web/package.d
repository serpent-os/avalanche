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
import avalanche.auth.session;

public static SiteConfiguration site = SiteConfiguration("Controller", "tabler-compass");

/**
 * Implementation of a controller for builders
 */
@requiresAuth public final class ControllerWeb
{
    /**
     * Gate web access behind a session token
     */
    @noRoute SessionAuthentication authenticate(HTTPServerRequest req, HTTPServerResponse res)
    {
        enforceHTTP(context.loggedIn, HTTPStatus.forbidden);
        return SessionAuthentication();
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
