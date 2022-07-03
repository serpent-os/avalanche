/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.server.site_config
 *
 * Shared configuration for the renderable site
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.server.site_config;

/**
 * A primary menu item has a root path we can match.
 */
public struct PrimaryMenuItem
{
    /**
     * The path prefix, i.e. /blog/ (stripped both ways)
     */
    string pathPrefix;

    /**
     * Display label
     */
    string label;
}

/**
 * Shared configuration between the web views
 */
public struct SiteConfiguration
{

    string siteName = "Unconfigured!";

    /**
     * Icon name to use
     */
    string iconName = "tabler-error-404";

    /**
     * Icon size, in pixels
     */
    uint iconSize = 32;

    /**
     * Renderable menu
     */
    PrimaryMenuItem[] primaryMenu = [PrimaryMenuItem("/", "Home"),];
}
