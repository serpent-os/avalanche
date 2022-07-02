/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.web
 *
 * Web interface for the controller and builders
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module avalanche.web;

public import avalanche.controller.interfaces;
import vibe.d;

/**
 * Implementation of a controller for builders
 */
public final class WebApp
{
    /**
     * Return the index page
     */
    void index() @safe
    {
        render!"controller/index.dt";
    }
}
