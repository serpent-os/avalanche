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
import std.sumtype;

public enum FormProblem
{
    None = 0,
    MissingUsername = 1 << 0,
    UsernameTooShort = 1 << 1,
    MissingPassword = 1 << 2,
    PasswordTooShort = 1 << 3,
    UnknownAccount = 1 << 4,
    PasswordMismatch = 1 << 5,
    UsernameRegistered = 1 << 6,
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
        auto session = SessionAuthentication();

        if (username == "")
        {
            problems |= FormProblem.MissingUsername;
        }
        if (password == "")
        {
            problems |= FormProblem.MissingPassword;
        }

        /* u fail */
        if (problems != FormProblem.None)
        {
            render!("common/login.dt", site, session, problems);
            return;
        }

        /* See if the user exists.. */
        User user;
        UserError err;
        users.byUsername(username).match!((u) { user = u; }, (e) { err = e; });
        if (err != UserError.init)
        {
            problems |= FormProblem.UnknownAccount;
        }
        else
        {
            if (!users.authenticate(user, password))
            {
                problems |= FormProblem.UnknownAccount;
            }
        }

        /* Shucks, you still didn't get in */
        if (problems != FormProblem.None)
        {
            render!("common/login.dt", site, session, problems);
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
        auto problems = FormProblem.None;
        auto session = SessionAuthentication();
        auto suggestedUsername = "";
        render!("common/register.dt", site, session, problems, suggestedUsername);
    }

    /**
     * POST register form
     */
    @noAuth @path("register") @method(HTTPMethod.POST) void processRegister(
            string username, string password, string passwordRepeat)
    {
        auto problems = FormProblem.None;
        auto session = SessionAuthentication();
        auto suggestedUsername = username;

        /* Already logged in.. can't register mate */
        enforceHTTP(!session.loggedIn, HTTPStatus.forbidden);

        if (username == "")
        {
            problems |= FormProblem.MissingUsername;
        }
        if (password == "")
        {
            problems |= FormProblem.MissingPassword;
        }
        if (passwordRepeat != password)
        {
            problems |= FormProblem.PasswordMismatch;
        }

        /* Got problems - but a registration aint one */
        if (problems != FormProblem.None)
        {
            render!("common/register.dt", site, session, problems, suggestedUsername);
            return;
        }

        User newUser;
        UserError newError;
        users.registerUser(username, password).match!((User u) { newUser = u; }, (UserError e) {
            newError = e;
        });

        if (newError != UserError.init)
        {
            if (newError.code == UserErrorCode.AlreadyRegistered)
            {
                problems |= FormProblem.UsernameRegistered;
            }
            render!("common/register.dt", site, session, problems, suggestedUsername);
            return;
        }

        logInfo("New user registered: %s", username);
        session.loggedIn = true;
        redirect("/");
    }

    SiteConfiguration site;

private:

    UserManager users;
}
