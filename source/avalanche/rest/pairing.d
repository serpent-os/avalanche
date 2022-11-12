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

import moss.service.models.endpoints;
import moss.service.interfaces;
import moss.service.tokens;
import moss.service.tokens.manager;
import std.sumtype : tryMatch;
import moss.db.keyvalue;

/**
 * Implements the enrolment API for Avalanche
 */
public final class AvalanchePairingAPI : ServiceEnrolmentAPI
{
    /**
     * Integrate pairing API
     */
    @noRoute void configure(Database appDB, TokenManager tokenManager, URLRouter router) @safe
    {
        this.appDB = appDB;
        this.tokenManager = tokenManager;
        router.registerRestInterface(this);
    }

    override void enrol(ServiceEnrolmentRequest request) @safe
    {
        /* Grab the token itself. */
        Token tk = Token.decode(request.issueToken).tryMatch!((Token tk) => tk);
        enforceHTTP(tokenManager.verify(tk, request.issuer.publicKey),
                HTTPStatus.forbidden, "Fraudulent packet");
        enforceHTTP(request.role == EnrolmentRole.Builder,
                HTTPStatus.methodNotAllowed, "Avalanche only supports Builder role");
        enforceHTTP(request.issuer.role == EnrolmentRole.Hub,
                HTTPStatus.methodNotAllowed, "Avalanche can only be paired with Summit");
        enforceHTTP(tk.payload.purpose == TokenPurpose.Authorization,
                HTTPStatus.forbidden, "enrol(): Require an Authorization token");

        logInfo(format!"Got a pairing request: %s"(request));
        SummitEndpoint endpoint;
        endpoint.id = request.issuer.publicKey;
        endpoint.hostAddress = request.issuer.url;
        endpoint.publicKey = request.issuer.publicKey;
        immutable err = appDB.update((scope tx) => endpoint.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
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
        TokenPayload payload;
        payload.iss = "avalanche";
        payload.sub = "user";
        Token token = tokenManager.createAPIToken(payload);
        return tokenManager.signToken(token).tryMatch!((string s) => s);
    }

    override string refreshIssueToken() @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented,
                "refreshIssueToken(): Not yet implemented");
    }

private:

    TokenManager tokenManager;
    Database appDB;
}
