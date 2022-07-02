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
 * Shared configuration between the web views
 */
public struct SiteConfiguration
{

    string siteName = "Unconfigured!";

    /**
     * Icon name to use
     */
    string iconName = "error-404";

    /**
     * Icon size, in pixels
     */
    uint iconSize = 32;
}
