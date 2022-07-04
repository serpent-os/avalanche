/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.controller.web
 *
 * Web interface for the builder
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */
module avalanche.builder.web;

import vibe.d;
public import avalanche.server.site_config;

import avalanche.builder.app;

/**
 * Web configuration for Builder
 */
public static SiteConfiguration site = SiteConfiguration("Builder", "tabler-bulldozer");

/**
 * Builder UI
 */
public final class BuilderWeb
{
    /**
     * Return the index page
     */
    void index() @safe
    {
        /* We can't do anything unless we're setup! */
        if (builderApp.stage == AppStage.AwaitingSetup)
        {
            redirect("/setup");
            return;
        }
        render!("builder/index.dt", site);
    }

    /**
     * Present the user with a setup screen
     */
    @path("/setup") @method(HTTPMethod.GET)
    void presentSetup()
    {
        enforceHTTP(builderApp.stage == AppStage.AwaitingSetup,
                HTTPStatus.internalServerError, "Server already configured");
        render!("builder/first_run.dt", site);
    }

    /**
     * Up and running!
     */
    @path("/setup") @method(HTTPMethod.POST)
    void handleSetup(string password, Confirm!"password" passwordCheck, string buildProfile)
    {
        logWarn("We're now up and running");
        builderApp.stage = AppStage.AwaitingEnrolment;
        redirect("/");
    }
}
