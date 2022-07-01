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
import vibe.d : HTTPStatusException, HTTPStatus;
import vibe.d : logInfo, logError;
public import avalanche.node.interfaces;

/**
 * Root RPC interface
 */
public final class NodeApp : NodeAPIv1
{
    this()
    {
        /* TODO: Obviously initialise from somewhere safe. */
        tokens = new TokenAuthenticator(cast(ubyte[]) "password");
    }

    override @property string versionIdentifier() @safe
    {
        return "0.0.0";
    }

    /**
     * Requested build of a given bundle.
     */
    override void buildBundle(string authHeader, BuildBundle bundle) @system
    {
        /* If the token is invalid we'll throw rthe error */
        auto token = tokens.checkTokenHeader(authHeader);
        if (token.expiredUTC)
        {
            logError("Refusing expired credentials: %s", token);
            throw new HTTPStatusException(HTTPStatus.forbidden, "Expired credentials");
        }
        logInfo("BUNDLE BUILD: %s", bundle);
    }

private:

    TokenAuthenticator tokens;
}
