/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.app
 *
 * Main application runtime for build control
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.rest;

import vibe.d;
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

/**
 * The BuildAPI
 */
@path("/api/v1") public interface BuildAPIv1
{
    @path("version")
    string versionIdentifier() @safe;
}

/**
 * Main entry point from the server side, storing our
 * databases and interfaces.
 */
public final class BuildAPI : BuildAPIv1
{

    /**
     * Configure BuildAPI for integration
     */
    @noRoute void configure(URLRouter root) @safe
    {
        auto apiRoot = root.registerRestInterface(this);
    }

    override string versionIdentifier() @safe
    {
        return "0.0.1";
    }
}
