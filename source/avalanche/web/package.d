/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.web
 *
 * Core web interface
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.web;

import vibe.d;

import moss.service.tokens.manager;
import moss.core.memoryinfo;

/**
 * Core entry into the Avalanche Web UI
 */
@path("/") public final class AvalancheWeb
{

    @disable this();

    /**
     * Construct new frontend with the given token manager
     */
    this(TokenManager tokenManager) @safe
    {
        this.tokenManager = tokenManager;

        scope mminfo = new MemoryInfo();
        totalRam = mminfo.total;
    }

    /**
     * Integrate Avalanche web with the router
     */
    @noRoute void configure(URLRouter router) @safe
    {
        router.registerWebInterface(this);
    }

    /**
     * Render the landing page
     */
    void index() @safe
    {
        immutable publicKey = tokenManager.publicKey;
        render!("index.dt", publicKey, totalRam);
    }

    double totalRam;

private:

    TokenManager tokenManager;
}
