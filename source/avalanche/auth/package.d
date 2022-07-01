/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.auth
 *
 * Authentication + authorization helpers for REST
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.auth;

import std.exception : assumeUnique;
import std.sumtype;
import std.stdint : uint8_t;
import std.datetime : DateTime;

/**
 * A token key is just a sequence of bytes.
 */
public alias TokenKey = ubyte[];

/**
 * Authentication can fail for numerous reasons
 */
public enum TokenError : uint8_t
{
    /**
     * Incorrect signature on token
     */
    Signature,

    /**
     * Incorrect header on token
     */
    Header,
}

/**
 * Tokens must include sub/iss/iat/eat
 */
public struct Token
{
    /**
     * Primary subject (i.e. user) of the Token
     */
    string subject;

    /**
     * Who issued it?
     */
    string issuer;

    /**
     * Date and time when the Token was issued
     */
    DateTime issuedAt;

    /**
     * Date and time when the Token expires
     */
    DateTime expiresAt;
}

/**
 * A TokenAuthenticator is a thin shim around the JWT library.
 * Currently we use HMAC and require all of our services to run
 * over SSL.
 */
public class TokenAuthenticator
{

    /**
     * Initialise the authenticator with our own key
     */
    this(TokenKey ourKey) @system
    {
        this.ourKey = assumeUnique(ourKey);
    }

    invariant ()
    {
        assert(ourKey !is null);
    }

private:

    immutable(TokenKey) ourKey;
}
