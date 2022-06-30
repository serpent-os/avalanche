/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.node
 *
 * REST API for the node mechanism
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.node.interfaces;

public import vibe.d : path;

/**
 * Our "v1" API for the Node
 */
@path("api/v1/node") public interface NodeAPIv1
{

    /**
     * GET /api/v1/node/version_identifier
     *
     * Placeholder. :)
     */
    @property string versionIdentifier() @safe;
}
