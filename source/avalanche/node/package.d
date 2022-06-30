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

module avalanche.node;

public import avalanche.node.interfaces;

/**
 * Root RPC interface
 */
public final class NodeApp : NodeAPIv1
{
    override @property string versionIdentifier() @safe
    {
        return "0.0.0";
    }
}
