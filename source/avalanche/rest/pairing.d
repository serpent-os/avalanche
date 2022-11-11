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
import moss.service.tokens;
import moss.service.tokens.manager;

/**
 * Implements the enrolment API for Avalanche
 */
public final class AvalanchePairingAPI : ServiceEnrolmentAPI
{
    /**
     * Integrate pairing API
     */
    @noRoute void configure(TokenManager tokenManager, URLRouter router) @safe
    {
        this.tokenManager = tokenManager;
        router.registerRestInterface(this);
    }

    override void enrol(ServiceEnrolmentRequest request) @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented, "enrol(): Not yet implemented");
    }

    /**
     * Noop: We don't accept enrolments locally
     */
    override void accept(ServiceEnrolmentRequest request) @safe
    {
        throw new HTTPStatusException(HTTPStatus.methodNotAllowed,
                "accept(): Avalanche doesn't accept requests");
    }

    /**
     * Noop: We don't decline enrolments locally
     */
    override void decline() @safe
    {
        throw new HTTPStatusException(HTTPStatus.methodNotAllowed,
                "decline(): Avalanche doesn't decline requests");
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

private:

    TokenManager tokenManager;
}
