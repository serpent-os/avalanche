/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.node
 *
 * REST API for the node mechanism
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.node;

import avalanche.auth;
import vibe.d;
import vibe.web.auth;
public import avalanche.node.interfaces;

/**
 * Implements our JWT-based authentication to guard our
 * resources.
 */
public struct NodeAuthentication
{

    /**
     * Construct new authenticator from request
     */
    this(scope TokenAuthenticator tokens, scope HTTPServerRequest request)
    {
        auto header = request.headers.get("Authorization");
        if (header is null)
        {
            logError("Refusing connection that lacks Authorization header");
            throw new HTTPStatusException(HTTPStatus.forbidden);
        }
        auto token = tokens.checkTokenHeader(header);
        if (token.expiredUTC)
        {
            logError("Refusing expired credentials: %s", token);
            throw new HTTPStatusException(HTTPStatus.forbidden, "Expired credentials");
        }
    }

private:

    bool active;
}

/**
 * Root RPC interface
 */
public final class NodeApp : NodeAPIv1
{
    @noRoute this()
    {
        /* TODO: Obviously initialise from somewhere safe. */
        tokens = new TokenAuthenticator(cast(ubyte[]) "password");
    }

    /**
     * Handle authentication via JWT
     */
    @noRoute NodeAuthentication authenticate(HTTPServerRequest req, HTTPServerResponse res)
    {
        return NodeAuthentication(tokens, req);
    }

    override @property string versionIdentifier() @safe
    {
        return "0.0.0";
    }

    /**
     * Requested build of a given bundle.
     */
    override void buildBundle(BuildBundle bundle) @system
    {
        logInfo("BUNDLE BUILD: %s", bundle);
    }

    /**
     * Handle a CER
     */
    override void enrol(ControllerEnrolmentRequest cer) @system
    {
        logInfo("Got an enrolment request: %s", cer);
    }

private:

    TokenAuthenticator tokens;
}
