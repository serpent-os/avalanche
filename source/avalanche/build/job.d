/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.build.job
 *
 * Module level types
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.build.job;

public import avalanche.build : PackageBuild;

import vibe.d;

/**
 * Encapsulation of the entire build job from cloning
 * to building.
 *
 * This should be constructed in a runTask() call to ensure
 * proper fiber multiplexing
 */
public final class BuildJob
{

    @disable this();

    /**
     * Construct a new BuildJob from the given definition
     */
    this(PackageBuild def) @safe nothrow
    {
        this.def = def;
    }

    void run() @safe nothrow
    {
        logInfo("Beginning build");
        checkoutRecipe();
        configureRoot();
        buildRecipe();
        publishArtefacts();
    }

private:

    /**
     * Get the recipe
     */
    void checkoutRecipe() @safe nothrow
    {
        logInfo("Checking out recipe");
    }

    /**
     * Configure the root build tree.
     */
    void configureRoot() @safe nothrow
    {
        logInfo("Configuring recipe root");
    }
    /**
     * Actually *build* the recipe
     */
    void buildRecipe() @safe nothrow
    {
        logInfo("Building recipe");
    }

    /**
     * make the stones available
     */
    void publishArtefacts() @safe nothrow
    {
        logInfo("Publishing artefacts");
    }

    /**
     * Build definition
     */
    PackageBuild def;
}
