/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.controller.web
 *
 * Web interface for the controller
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module avalanche.controller.web;

import vibe.d;

public import avalanche.server.site_config;
import avalanche.server.context;

public static SiteConfiguration site = SiteConfiguration("Controller", "tabler-compass");

/**
 * Implementation of a controller for builders
 */
public final class ControllerWeb
{
    /**
     * Return the index page
     */
    void index() @safe
    {
        render!("controller/index.dt", context, site);
    }

    WebContext context;
}
