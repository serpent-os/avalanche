/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.rest.pairing
 *
 * ServiceEnrolmentAPI implementation for Avalanche
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module avalanche.rest.pairing;

import vibe.d;

import moss.service.models.endpoints;
import moss.service.interfaces;
import moss.service.accounts;
import moss.service.tokens;
import moss.service.tokens.manager;
import std.sumtype : tryMatch;
import moss.db.keyvalue;
import std.algorithm : map;
import std.array : array;

/**
 * Implements the enrolment API for Avalanche
 */
public final class AvalanchePairingAPI : ServiceEnrolmentAPI
{

    mixin AppAuthenticator;

    /**
     * Integrate pairing API
     */
    @noRoute void configure(Database appDB, TokenManager tokenManager,
            AccountManager accountManager, URLRouter router) @safe
    {
        this.appDB = appDB;
        this.accountManager = accountManager;
        this.tokenManager = tokenManager;
        router.registerRestInterface(this);
    }

    /**
     * Sanitize display of endpoints without revealing tokens
     */
    override VisibleEndpoint[] enumerate() @safe
    {
        VisibleEndpoint[] items;

        appDB.view((in tx) @safe {
            auto d = tx.list!SummitEndpoint
                .map!((e) {
                    return VisibleEndpoint(e.id, e.hostAddress, e.publicKey, e.status);
                });
            items = () @trusted { return d.array; }();
            return NoDatabaseError;
        });
        return items;
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
        endpoint.status = EndpointStatus.AwaitingAcceptance;
        endpoint.id = request.issuer.publicKey;
        endpoint.hostAddress = request.issuer.url;
        endpoint.publicKey = request.issuer.publicKey;
        endpoint.bearerToken = request.issueToken;
        immutable err = appDB.update((scope tx) => endpoint.save(tx));
        enforceHTTP(err.isNull, HTTPStatus.internalServerError, err.message);
    }

    /**
     * Noop: We don't accept enrolments locally
     */
    override void accept(ServiceEnrolmentRequest request, NullableToken token) @safe
    {
        throw new HTTPStatusException(HTTPStatus.methodNotAllowed,
                "accept(): Avalanche doesn't accept requests");
    }

    /**
     * Noop: We don't decline enrolments locally
     */
    override void decline(NullableToken token) @safe
    {
        throw new HTTPStatusException(HTTPStatus.methodNotAllowed,
                "decline(): Avalanche doesn't decline requests");
    }

    override void leave(NullableToken token) @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented, "leave(): Not yet implemented");
    }

    override string refreshToken(NullableToken token) @safe
    {
        TokenPayload payload;
        payload.iss = "avalanche";
        payload.sub = "user";
        Token refreshedToken = tokenManager.createAPIToken(payload);
        return tokenManager.signToken(refreshedToken).tryMatch!((string s) => s);
    }

    override string refreshIssueToken(NullableToken token) @safe
    {
        throw new HTTPStatusException(HTTPStatus.notImplemented,
                "refreshIssueToken(): Not yet implemented");
    }

private:

    AccountManager accountManager;
    TokenManager tokenManager;
    Database appDB;
}
