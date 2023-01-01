/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.web.accounts
 *
 * User account interface
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module avalanche.web.accounts;

import moss.service.accounts;
import moss.service.tokens.manager;
import vibe.d;

/**
 * Extends generic base web for rendering
 */
@path("/accounts") public final class AvalancheAccountsWeb : AccountsWeb
{
    @disable this();

    /**
     * Construct a new accounts web
     */
    this(AccountManager accountManager, TokenManager tokenManager) @safe
    {
        super(accountManager, tokenManager, "avalanche");
    }

    /**
     * Render the login form
     */
    override void renderLogin() @safe
    {
        render!"accounts/login.dt";
    }

    /**
     * Render registration form
     */
    override void renderRegister() @safe
    {
        render!"accounts/register.dt";
    }
}
