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
import avalanche.auth.users;

public enum FormProblem
{
    None = 0,
    MissingUsername = 1 << 0,
    UsernameTooShort = 1 << 1,
    MissingPassword = 1 << 2,
    PasswordTooShort = 1 << 3,
    UnknownAccount = 1 << 4,
}

/**
 * SessionAuthentication is required for HTTP web sessions, not for API use.
 */
public struct SessionAuthentication
{
    /**
     * Are we currently logged in?
     */
    SessionVar!(bool, "loggedIn") loggedIn;

    /**
     * What UID are we authed as? - volatile
     */
    SessionVar!(UserIdentifier, "uid") uid;

    /**
     * The visible username - volatile
     */
    SessionVar!(string, "visibleUsername") visibleUsername;
}

/**
 * Session management APIs under /ac/ PATH
 */
@requiresAuth @path("ac") public final class SessionManagement
{

    this(SiteConfiguration site, UserManager users)
    {
        this.site = site;
        this.users = users;
    }

    /**
     * Simply - are we able to access these portions
     */
    @noRoute SessionAuthentication authenticate(HTTPServerRequest req, HTTPServerResponse res) @safe
    {
        /* Is .loggedIn set? */
        auto session = SessionAuthentication();
        enforceHTTP(session.loggedIn, HTTPStatus.forbidden);
        return session;
    }

    /**
     * Provide the login form over GET
     */
    @noAuth @path("login") @method(HTTPMethod.GET) void login()
    {
        auto session = SessionAuthentication();
        FormProblem problems = FormProblem.None;
        render!("common/login.dt", site, session, problems);
    }

    /**
     * Provide the login validation
     */
    @noAuth @path("login") @method(HTTPMethod.POST) void processLogin(string username,
            string password) @safe
    {
        auto problems = FormProblem.None;
        if (username == "")
        {
            problems |= FormProblem.MissingUsername;
        }
        if (password == "")
        {
            problems |= FormProblem.MissingPassword;
        }

        problems |= FormProblem.UnknownAccount;
        auto session = SessionAuthentication();
        render!("common/login.dt", site, session, problems);
    }

    /**
     * GET request to logout
     */
    @anyAuth @path("logout") @method(HTTPMethod.GET) void logout()
    {
        auto session = SessionAuthentication();
        session.loggedIn = false;
        terminateSession();
        redirect("/");
    }

    /**
     * GET register form
     */
    @noAuth @path("register") @method(HTTPMethod.GET) void register()
    {
        auto session = SessionAuthentication();
        render!("common/register.dt", site, session);
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

private:

    UserManager users;
}
