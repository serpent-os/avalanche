/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.build
 *
 * Module level types
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module avalanche.build;

import std.stdint : uint64_t;

/**
 * Collections to add to the profile
 */
struct BinaryCollection
{
    /**
     * Where to find the index
     */
    string indexURI;

    /**
     * Name of the collection
     */
    string name;

    /**
     * Priority for the collection (default 0)
     */
    uint priority;
}

/**
 * JSON Object
 */
struct PackageBuild
{
    /**
     * Remote build identifier
     */
    uint64_t buildID;

    /**
     * Upstream git URI
     */
    string uri;

    /**
     * Some git ref to checkout
     */
    string commitRef;

    /**
     * Relative path to the source, i.e. base/moss/stone.yml
     */
    string relativePath;

    /** 
     * The build architecture. MUST match the boulder architecture
     */
    string buildArchitecture;

    /**
     * The collections to enable in this build
     * Default boulder profiles are ignored
     */
    BinaryCollection[] collections;
}
