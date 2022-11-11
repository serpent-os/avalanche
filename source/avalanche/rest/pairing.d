/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.rest.pairing
 *
 * ServiceEnrolmentAPI implementation for Avalanche
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.rest.pairing;

import vibe.d;

import moss.service.interfaces;

/**
 * Implements the enrolment API for Avalanche
 */
public final class AvalanchePairingAPI : ServiceEnrolmentAPI
{
    /**
     * Integrate pairing API
     */
    @noRoute void configure(URLRouter router) @safe
    {
        router.registerRestInterface(this);
    }

    override void enrol(ServiceEnrolmentRequest request) @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented, "enrol(): Not yet implemented");
    }

    override void accept(ServiceEnrolmentRequest request) @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented, "accept(): Not yet implemented");
    }

    override void decline() @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented, "decline(): Not yet implemented");
    }

    override void leave() @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented, "leave(): Not yet implemented");
    }

    override string refreshToken() @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented,
                "refreshToken(): Not yet implemented");
    }

    override string refreshIssueToken() @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented,
                "refreshIssueToken(): Not yet implemented");
    }
}
