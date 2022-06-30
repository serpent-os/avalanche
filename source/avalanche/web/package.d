/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.web
 *
 * Web interface for the controller and nodes
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module avalanche.web;

public import avalanche.controller.interfaces;
import vibe.d;

/**
 * Implementation of a controller for builder nodes
 */
public final class WebApp
{
    /**
     * Return the index page
     */
    void index() @safe
    {
        render!"index.dt";
    }
}
