/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.interfaces.v1.auth
 *
 * REST API for the authentication mechanism
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.interfaces.v1.auth;

public import vibe.d : path, method, HTTPMethod;
public import vibe.web.auth;
public import vibe.web.validation;

/** 
 * Response to login/register to recieve our initial token.
 */
public struct TokenResponse
{
    /** 
     * Known identity
     */
    string username;

    /**
     * Role within the app
     */
    string role;

    /**
     * JWT
     */
    string token;
}

/**
 * Our "v1" API for the Auth module
 *
 */
@requiresAuth @path("api/v1/auth") public interface AuthAPIv1
{

    /**
     * Attempt login
     */
    @noAuth TokenResponse login(string username, string password) @safe;

    /**
     * Kill the currently allocated token for the user
     */
    @anyAuth void logout() @safe;

    /**
     * Register with the auth module
     *
     * Right now we *just* register/login. We actually want pending states..
     */
    @noAuth TokenResponse register(string username, string password,
            Confirm!"password" passwordRepeat) @safe;
}
