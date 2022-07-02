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
module avalanche.controller.rest;

public import avalanche.controller.rest.interfaces;

/**
 * Implementation of a controller for builders
 */
public final class Controller : ControllerAPIv1
{
    override @property string versionIdentifier() @safe
    {
        return "someVersionID";
    }
}
