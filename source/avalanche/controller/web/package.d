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

public import avalanche.controller.rest.interfaces;
import vibe.d;

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
        render!"controller/index.dt";
    }
}
