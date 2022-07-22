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

import jwt = jwtd.jwt;
import std.datetime : SysTime, UTC, Clock;
import std.exception : assumeUnique;
import std.json : JSONValue, toJSON;
import std.stdint : uint8_t, uint64_t;
import std.string : startsWith, strip;
import std.sumtype;
import vibe.d : HTTPStatusException, HTTPStatus, logError, HTTPServerRequest, enforceHTTP;

/**
 * Add "free" JWT based authentication for REST APIs.
 *
 * Currently this just requires that a JWT is valid, and doesn't do
 * any kind of role checks. They will be added through an abstract API
 * in future.
 */
public struct ApplicationAuthentication
{

    /**
     * True if using cookie based authentication
     */
    pragma(inline, true) pure @property bool isWebClient() @safe @nogc nothrow
    {
        return webClient;
    }

    /**
     * True if using header based authentication
     */
    pragma(inline, true) pure @property bool isAppClient() @safe @nogc nothrow
    {
        return !webClient;
    }

    /**
     * Construct ApplicationAuthentication from a request and authenticator
     */
    this(scope TokenAuthenticator tokens, scope HTTPServerRequest request)
    {
        Token tok;

        auto cookie = request.cookies.get("avalanche.token");
        auto header = request.headers.get("Authorization");

        if (cookie !is null)
        {
            webClient = true;
            tok = tokens.checkCookie(cookie);
        }
        else if (header !is null)
        {
            tok = tokens.checkTokenHeader(header);
        }
        else
        {
            throw new HTTPStatusException(HTTPStatus.forbidden);
        }

        /* Is it actually valid? */
        enforceHTTP(!tok.expiredUTC, HTTPStatus.forbidden, "Forbidden - Expired credentials");

        /* TODO: Set up roles */
    }

private:

    bool webClient;
}

/**
 * A token key is just a sequence of bytes.
 */
public alias TokenString = ubyte[];

/**
 * Authentication can fail for numerous reasons
 */
public enum TokenErrorType : uint8_t
{
    /**
     * No error detected
     */
    None = 0,

    /**
     * Incorrect token format
     */
    InvalidFormat,

    /**
     * Invalid JSON
     */
    InvalidJSON,
}

/**
 * Simplistic wrapping of errors
 */
public struct TokenError
{
    TokenErrorType type;
    string errorString;

    auto toString() @safe @nogc nothrow const
    {
        return errorString;
    }
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
     * Date and time when the Token was issued (UTC)
     */
    SysTime issuedAt;

    /**
     * Date and time when the Token expires (UTC)
     */
    SysTime expiresAt;

    /**
     * True if this token has expired by UTC time
     */
    @property bool expiredUTC() @safe nothrow
    {
        auto tnow = Clock.currTime(UTC());
        return tnow > this.expiresAt;
    }
}

/**
 * Our methods can either return a token or an error.
 */
public alias TokenReturn = SumType!(Token, TokenError);

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
    this(TokenString ourKey) @system
    {
        this.ourKey = assumeUnique(ourKey);
    }

    invariant ()
    {
        assert(ourKey !is null);
    }

    /**
     * Attempt to decode the input, or fail spectacularly
     */
    TokenReturn decode(TokenString input)
    {
        JSONValue value;
        Token tok;
        try
        {
            value = jwt.decode(cast(string) input, cast(string) ourKey);
        }
        catch (jwt.VerifyException ex)
        {
            return TokenReturn(TokenError(TokenErrorType.InvalidFormat, cast(string) ex.message));
        }

        /* Decode the JSON now */
        try
        {
            tok.issuer = value["iss"].get!string;
            tok.subject = value["sub"].get!string;
            auto iat = value["iat"].get!uint64_t;
            auto eat = value["exp"].get!uint64_t;
            tok.issuedAt = SysTime.fromUnixTime(iat, UTC());
            tok.expiresAt = SysTime.fromUnixTime(eat, UTC());
        }
        catch (Exception ex)
        {
            return TokenReturn(TokenError(TokenErrorType.InvalidJSON, cast(string) ex.message));
        }
        return TokenReturn(tok);
    }

    /**
     * Encode a Token into a proper JWT
     */
    TokenString encode(in Token token, jwt.JWTAlgorithm algorithm = jwt.JWTAlgorithm.HS512)
    {
        JSONValue payload;
        payload["iss"] = JSONValue(token.issuer);
        payload["subject"] = JSONValue(token.subject);
        payload["iat"] = JSONValue(cast(uint64_t) token.issuedAt.toUnixTime);
        payload["exp"] = JSONValue(cast(uint64_t) token.expiresAt.toUnixTime);
        return cast(ubyte[]) jwt.encode(payload, cast(string) ourKey, algorithm);
    }

    /**
     * Check our header and potentially throw an error until its correct looking
     */
    Token checkTokenHeader(string authHeader)
    {
        if (!authHeader.startsWith("Bearer"))
        {
            throw new HTTPStatusException(HTTPStatus.badRequest);
        }
        /* Strip the header down */
        auto substr = authHeader["Bearer".length .. $].strip();
        logError(substr);
        Token ret;

        /* Get it decoded. */
        this.decode(cast(TokenString) substr).match!((TokenError err) {
            logError("Invalid token encountered: %s", err.toString);
            throw new HTTPStatusException(HTTPStatus.expectationFailed, err.toString);
        }, (Token t) { ret = t; });

        /* Check expiry, subject, etc. */
        return ret;
    }

    Token checkCookie(in string cookie)
    {
        Token ret;

        /* Get it decoded. */
        this.decode(cast(TokenString) cookie).match!((TokenError err) {
            logError("Invalid token encountered: %s", err.toString);
            throw new HTTPStatusException(HTTPStatus.expectationFailed, err.toString);
        }, (Token t) { ret = t; });

        /* Check expiry, subject, etc. */
        return ret;
    }

private:

    immutable(TokenString) ourKey;
}
