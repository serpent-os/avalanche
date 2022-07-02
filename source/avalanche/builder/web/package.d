/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.controller.web
 *
 * Web interface for the builder
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module avalanche.builder.web;

import vibe.d;

/**
 * Builder UI
 */
public final class BuilderWeb
{
    /**
     * Return the index page
     */
    void index() @safe
    {
        render!"builder/index.dt";
    }
}
