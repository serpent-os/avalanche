/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.controller.web
 *
 * Web interface for the builder
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module avalanche.builder.web;

import vibe.d;
import vibe.web.auth;
public import avalanche.server.site_config;

import avalanche.builder.app;
import avalanche.server.context;
import avalanche.auth.session;

/**
 * Web configuration for Builder
 */
public static SiteConfiguration site = SiteConfiguration("Builder", "tabler-bulldozer");

/**
 * Builder UI
 */
@requiresAuth() public final class BuilderWeb
{

    /**
     * You're not coming in :3
     */
    @noRoute auto authenticate(HTTPServerRequest req, HTTPServerResponse res)
    {
        auto session = SessionAuthentication();
        enforceHTTP(session.loggedIn, HTTPStatus.forbidden);
        return session;
    }

    /**
     * Return the index page
     */
    @anyAuth void index() @safe
    {
        auto session = SessionAuthentication();
        render!("builder/index.dt", site, session);
    }
}
