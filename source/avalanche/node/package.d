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
    @noRoute ApplicationAuthentication authenticate(HTTPServerRequest req, HTTPServerResponse res)
    {
        return ApplicationAuthentication(tokens, req);
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
