/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.auth.rpc
 *
 * Authorization RESTful APIs
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.auth.rpc;

public import avalanche.interfaces.v1.auth;

import vibe.d : HTTPServerRequest, HTTPServerResponse, enforceHTTP, HTTPStatus;

public struct AuthServerAuth
{

}

/**
 * Our token based implementation of the v1 Auth API
 */
public final class AuthServer : AuthAPIv1
{

    /**
     * Basically - anyone is auth'd atm.
     * TODO: Check JWTs!
     */
    AuthServerAuth authenticate(HTTPServerRequest req, HTTPServerResponse res) @safe
    {
        return AuthServerAuth();
    }

    override TokenResponse login(string username, string password) @safe
    {
        return TokenResponse("chicken", "admin", "token");
    }

    override void logout() @safe
    {

    }

    override TokenResponse register(string username, string password,
            Confirm!"password" passwordRepeat) @safe
    {
        return TokenResponse("chicken", "admin", "token");
    }
}
