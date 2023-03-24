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

import moss.service.models;
import moss.service.interfaces;
import moss.service.accounts;
import moss.service.tokens;
import moss.service.tokens.manager;
import std.sumtype : tryMatch;
import moss.db.keyvalue;
import std.algorithm : map;
import std.array : array;
import moss.service.context;

/**
 * Implements the enrolment API for Avalanche
 */
public final class AvalanchePairingAPI : ServiceEnrolmentAPI
{

    mixin AppAuthenticatorContext;

    @disable this();

    /** 
     * Construct new pairing API
     *
     * Params:
     *   context = global shared context
     */
    @noRoute this(ServiceContext context) @safe
    {
        this.context = context;
    }

    /**
     * Integrate pairing API
     */
    @noRoute void configure(URLRouter router) @safe
    {
        router.registerRestInterface(this);
    }

    /**
     * Sanitize display of endpoints without revealing tokens
     */
    override VisibleEndpoint[] enumerate() @safe
    {
        VisibleEndpoint[] items;

        context.appDB.view((in tx) @safe {
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
        enforceHTTP(context.tokenManager.verify(tk, request.issuer.publicKey),
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
        immutable err = context.appDB.update((scope tx) => endpoint.save(tx));
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

    /** 
     * Largely clone the original token and sign it. Access checks have already
     * been performed, and we know the bearer token is in use.
     *
     * Params:
     *   token = Session token
     * Returns: Newly refreshed token
     */
    override string refreshToken(NullableToken token) @safe
    {
        enforceHTTP(!token.isNull, HTTPStatus.forbidden);
        TokenPayload payload;
        payload.iss = "avalanche";
        payload.sub = token.payload.sub;
        payload.aud = token.payload.aud;
        payload.admin = token.payload.admin;
        payload.uid = token.payload.uid;
        payload.act = token.payload.act;
        Token refreshedToken = context.tokenManager.createAPIToken(payload);
        return context.tokenManager.signToken(refreshedToken).tryMatch!((string s) => s);
    }

    override string refreshIssueToken(NullableToken token) @safe
    {
        string newToken;

        enforceHTTP(!token.isNull, HTTPStatus.forbidden);
        context.accountManager.getUser(token.payload.uid).match!((Account account) {
            TokenPayload payload;
            payload.iss = "summit";
            payload.sub = token.payload.sub;
            payload.aud = token.payload.aud;
            payload.admin = context.accountManager.accountInGroup(account.id,
                BuiltinGroups.Admin).tryMatch!((bool b) => b);
            payload.uid = account.id;
            payload.act = account.type;
            Token refreshedToken = context.tokenManager.createBearerToken(payload);
            newToken = context.tokenManager.signToken(refreshedToken).tryMatch!((string s) => s);
            BearerToken bt;
            bt.rawToken = newToken;
            bt.id = account.id;
            bt.expiryUTC = refreshedToken.payload.exp;
            auto err = context.accountManager.setBearerToken(account, bt);
            enforceHTTP(err.isNull, HTTPStatus.forbidden, err.message);
        }, (DatabaseError err) {
            throw new HTTPStatusException(HTTPStatus.forbidden, err.message);
        });
        return newToken;
    }

private:

    ServiceContext context;
}
