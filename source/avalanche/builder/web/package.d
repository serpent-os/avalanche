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

/**
 * Web configuration for Builder
 */
public static SiteConfiguration site = SiteConfiguration("Builder", "tabler-bulldozer");

/**
 * Placeholder for roles
 */
public struct Auth
{
}
/**
 * Builder UI
 */
@requiresAuth() public final class BuilderWeb
{

    /**
     * You're not coming in :3
     */
    @noRoute Auth authenticate(HTTPServerRequest req, HTTPServerResponse res)
    {
        if (!context.loggedIn)
        {
            throw new HTTPStatusException(HTTPStatus.forbidden);
        }
        return Auth();
    }

    /**
     * Return the index page
     */
    @anyAuth void index() @safe
    {
        render!("builder/index.dt", context, site);
    }

    WebContext context;
}
