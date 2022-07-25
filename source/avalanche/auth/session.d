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
import vibe.web.validation;

import avalanche.server.site_config;
import avalanche.auth.users;
import std.sumtype;

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

    /**
     * The last error that the user caused
     */
    SessionVar!(string, "lastError") lastError;
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
     * Provide the login validation
     */
    @noAuth @path("login") @method(HTTPMethod.POST) void processLogin(
            ValidUsername username, ValidPassword password) @safe
    {
        auto session = SessionAuthentication();

        /* See if the user exists.. */
        User user;
        UserError err;
        bool userError;
        users.byUsername(username).match!((u) { user = u; }, (e) { err = e; });
        if (err != UserError.init)
        {
            userError = true;
        }
        else
        {
            /* invaid pass */
            if (!users.authenticate(user, password))
            {
                userError = true;
            }
        }

        /* Shucks, you still didn't get in */
        if (userError)
        {
            session.lastError = "Invalid username or password";
            redirect("/");
            return;
        }

        /* Hey this guy knows us */
        session.uid = user.uid;
        session.visibleUsername = user.username;
        session.loggedIn = true;

        redirect("/");
    }

    /**
     * GET request to logout
     */
    @anyAuth @path("logout") @method(HTTPMethod.GET) void logout()
    {
        auto session = SessionAuthentication();
        enforceHTTP(session.loggedIn, HTTPStatus.forbidden);
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
        auto suggestedUsername = "";
        render!("common/register.dt", site, session, suggestedUsername);
    }

    /**
     * POST register form
     */
    @noAuth @path("register") @method(HTTPMethod.POST) void processRegister(
            ValidUsername username, ValidPassword password, Confirm!"password" passwordRepeat)
    {
        auto session = SessionAuthentication();
        auto suggestedUsername = username;

        /* Already logged in.. can't register mate */
        enforceHTTP(!session.loggedIn, HTTPStatus.forbidden);

        User newUser;
        UserError newError;
        users.registerUser(username, password).match!((User u) { newUser = u; }, (UserError e) {
            newError = e;
        });

        if (newError != UserError.init)
        {
            if (newError.code == UserErrorCode.AlreadyRegistered)
            {
                session.lastError = "The requested username is not available";
            }
            render!("common/register.dt", site, session, suggestedUsername);
            return;
        }

        logInfo("New user registered: %s", username);
        session.uid = newUser.uid;
        session.visibleUsername = newUser.username;
        session.loggedIn = true;
        redirect("/");
    }

    SiteConfiguration site;

private:

    UserManager users;
}
