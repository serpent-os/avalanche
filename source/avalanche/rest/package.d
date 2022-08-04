/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.app
 *
 * Main application runtime for build control
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.rest;

import vibe.d;

@path("/api/v1") public interface BaseAPIv1
{
    @path("version")
    string versionIdentifier() @safe;
}

/**
 * Main entry point from the server side, storing our
 * databases and interfaces.
 */
public final class BaseAPI : BaseAPIv1
{

    /**
     * Configure BaseAPI for integration
     */
    @noRoute void configure(URLRouter root) @safe
    {
        auto apiRoot = root.registerRestInterface(this);
    }

    override string versionIdentifier() @safe
    {
        return "0.0.1";
    }
}
