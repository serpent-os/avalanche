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

/**
 * Core entry into the Avalanche Web UI
 */
@path("/") public final class AvalancheWeb
{
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
        render!"index.dt";
    }
}
