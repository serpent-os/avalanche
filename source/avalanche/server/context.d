/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

module avalanche.server.context;

public import vibe.d : SessionVar;

/**
 * avalanche.server.context
 *
 * Shared context type for session + rendering
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
public struct WebContext
{
    /**
     * Is the user logged in?
     * TODO: Something less sucky. :)
     */
    SessionVar!(bool, "loggedIn") loggedIn;
}
