/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.auth.session
 *
 * Shared session management
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.auth.session;

import vibe.d;
import vibe.web.auth;

import avalanche.server.site_config;
import avalanche.server.context;

/**
 * Placeholder.
 */
public struct SessionAuthentication
{

}

/**
 * Session management APIs under /session/ PATH
 */
@requiresAuth @path("session") public final class SessionManagement
{

    this(SiteConfiguration site, WebContext context)
    {
        this.site = site;
    }

    /**
     * Simply - are we able to access these portions
     */
    @noRoute SessionAuthentication authenticate(HTTPServerRequest req, HTTPServerResponse res) @safe
    {
        /* Is .loggedIn set? */
        enforceHTTP(context.loggedIn, HTTPStatus.forbidden);
        return SessionAuthentication();
    }

    /**
     * Provide the login form over GET
     */
    @noAuth @path("login") @method(HTTPMethod.GET) void login()
    {
        render!("common/login.dt", site, context);
    }

    /**
     * Provide the login validation
     */
    @noAuth @path("login") @method(HTTPMethod.POST) void processLogin()
    {
        logWarn("NOT HANDLING LOGINS :p");
        context.loggedIn = true;
        redirect("/");
    }

    /**
     * GET request to logout
     */
    @anyAuth @path("logout") @method(HTTPMethod.GET) void logout()
    {
        context.loggedIn = false;
        terminateSession();
        redirect("/");
    }

    /**
     * GET register form
     */
    @noAuth @path("register") @method(HTTPMethod.GET) void register()
    {
        render!("common/register.dt", site, context);
    }

    /**
     * POST register form
     */
    @noAuth @path("register") @method(HTTPMethod.POST) void processRegister()
    {
        logWarn("NOT HANDLING REGISTER");
        redirect("/");
    }

    SiteConfiguration site;
    WebContext context;
}
