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
import moss.service.accounts;
import moss.service.tokens.manager;

/**
 * Core entry into the Avalanche Web UI
 */
@path("/") @requiresAuth public final class AvalancheWeb
{

    @disable this();

    mixin AppAuthenticator;

    /**
     * Construct new frontend with the given token manager
     */
    this(AccountManager accountManager, TokenManager tokenManager) @safe
    {
        this.accountManager = accountManager;
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
    @anyAuth void index() @safe
    {
        immutable publicKey = tokenManager.publicKey;
        render!("index.dt", publicKey, totalRam);
    }

    double totalRam;

private:

    AccountManager accountManager;
    TokenManager tokenManager;
}
