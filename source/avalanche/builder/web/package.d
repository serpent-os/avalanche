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
public import avalanche.server.site_config;

import avalanche.builder.app;

/**
 * Web configuration for Builder
 */
public static SiteConfiguration site = SiteConfiguration("Builder", "tabler-bulldozer");

/**
 * Builder UI
 */
public final class BuilderWeb
{
    /**
     * Return the index page
     */
    void index() @safe
    {
        render!("builder/index.dt", site);
    }

    /**
     * Return the login form
     */
    @method(HTTPMethod.GET) @path("login")
    void login() @safe
    {
        if (loggedIn)
        {
            redirect("/");
            return;
        }
        render!("builder/login.dt", site);
    }

    /**
     * User requested a logout so kill the session
     */
    @method(HTTPMethod.GET) @path("logout")
    void logout() @safe
    {
        if (loggedIn)
        {
            loggedIn = false;
            terminateSession();
        }
        redirect("/");
    }

    /**
     * Looking to log in.
     */
    @method(HTTPMethod.POST) @path("login")
    void handleLogin(string username, string password) @safe
    {
        /* TODO: Auth them! */
        logWarn("HUR DUR WE DIDNT AUTHENTICATE %s", username);
        loggedIn = true;
        redirect("/");
    }

    /**
     * Handle user registration
     */
    @method(HTTPMethod.GET) @path("register")
    void register()
    {
        /* Already logged in why are you registering. */
        if (loggedIn)
        {
            redirect("/");
            return;
        }
        render!("builder/register.dt", site);
    }

private:

    /* True if they're logged in. All we really care for */
    SessionVar!(bool, "loggedIn") loggedIn;
}
