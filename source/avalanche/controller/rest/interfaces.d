/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.controller.rest
 *
 * REST API for the controller mechanism
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.controller.rest.interfaces;

public import vibe.d : path;

/**
 * Our "v1" API for the Controller
 */
@path("api/v1/controller") public interface ControllerAPIv1
{

    /**
     * GET /api/v1/controller/version_identifier
     *
     * Placeholder. :)
     */
    @property string versionIdentifier() @safe;
}
