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

public static SiteConfiguration site = SiteConfiguration("Dashboard",
        "tabler-dashboard", 32, [
            PrimaryMenuItem("/", "Builds"), PrimaryMenuItem("/hosts", "Hosts"),
            PrimaryMenuItem("/targets", "Targets"),
        ]);

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
        auto session = SessionAuthentication();
        enforceHTTP(session.loggedIn, HTTPStatus.forbidden);
        return session;
    }

    /**
     * Return the index page
     */
    @noAuth void index() @safe
    {
        auto session = SessionAuthentication();
        render!("controller/index.dt", site, session);
    }

    /**
     * Render the hosts page
     */
    @path("hosts") @method(HTTPMethod.GET)
    @noAuth void hosts() @safe
    {
        auto session = SessionAuthentication();
        render!("controller/hosts.dt", site, session);
    }
}
