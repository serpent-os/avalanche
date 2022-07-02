/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.controller
 *
 * REST API for the controller mechanism
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module avalanche.controller;

public import avalanche.controller.interfaces;

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
