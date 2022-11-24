/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.web
 *
 * Core web interface
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.web;

import vibe.d;

import moss.service.tokens.manager;
import moss.core.memoryinfo;
import moss.service.accounts;
import moss.service.tokens;
import moss.service.tokens.manager;
import avalanche.web.accounts;
import moss.db.keyvalue;
import moss.db.keyvalue.orm;
import moss.service.interfaces;
import moss.service.models.bearertoken;
import moss.service.models.endpoints;

/**
 * Core entry into the Avalanche Web UI
 */
@path("/") @requiresAuth public final class AvalancheWeb
{

    @disable this();

    mixin AppAuthenticator;

    /**
     * Construct new frontend with the given token manager
     */
    this(AccountManager accountManager, TokenManager tokenManager, Database appDB) @safe
    {
        this.accountManager = accountManager;
        this.tokenManager = tokenManager;
        this.appDB = appDB;

        scope mminfo = new MemoryInfo();
        totalRam = mminfo.total;
    }

    /**
     * Integrate Avalanche web with the router
     */
    @noRoute void configure(URLRouter router) @safe
    {
        auto acct = new AvalancheAccountsWeb(accountManager, tokenManager);
        auto root = router.registerWebInterface(this);
        root.registerWebInterface(cast(AccountsWeb) acct);
    }

    /**
     * Render the landing page
     */
    @anyAuth void index() @safe
    {
        immutable publicKey = tokenManager.publicKey;
        render!("index.dt", publicKey, totalRam);
    }

    /**
     * Admin accepting enrolment
     */
    @path("avl/accept/:id")
    @auth(Role.notExpired & Role.web & Role.accessToken & Role.userAccount) @method(HTTPMethod.GET) void acceptEnrolment(
            string _id) @safe
    {
        /* Grab the endpoint. */
        SummitEndpoint endpoint;
        immutable err = appDB.view((in tx) => endpoint.load(tx, _id));
        enforceHTTP(err.isNull, HTTPStatus.notFound, err.message);

        /* OK - first up we need a service account */
        immutable serviceUser = format!"%s%s"(serviceAccountPrefix, endpoint.id);
        Account serviceAccount;
        accountManager.registerService(serviceUser, endpoint.hostAddress).match!((Account u) {
            serviceAccount = u;
        }, (DatabaseError e) {
            throw new HTTPStatusException(HTTPStatus.forbidden, e.message);
        });

        logInfo(format!"Constructed new service account '%s': %s"(serviceAccount.id, serviceUser));

        /* Construct the bearer token */
        string encodedToken;
        TokenPayload payload;
        payload.iss = "avalanche";
        payload.sub = serviceAccount.username;
        payload.uid = serviceAccount.id;
        payload.act = serviceAccount.type;
        Token bearer = tokenManager.createBearerToken(payload);
        tokenManager.signToken(bearer).match!((TokenError err) {
            throw new HTTPStatusException(HTTPStatus.internalServerError, err.message);
        }, (string s) { encodedToken = s; });

        /* Set the token in the DB now */
        BearerToken storedToken;
        storedToken.id = serviceAccount.id;
        storedToken.rawToken = encodedToken;
        storedToken.expiryUTC = bearer.payload.exp;
        immutable bErr = accountManager.setBearerToken(serviceAccount, storedToken);
        enforceHTTP(bErr.isNull, HTTPStatus.internalServerError, bErr.message);

        /* Set up a corresponding acceptance call */
        ServiceEnrolmentRequest request;
        request.role = EnrolmentRole.Hub;
        request.issueToken = encodedToken;
        request.issuer.role = EnrolmentRole.Builder;
        request.issuer.publicKey = tokenManager.publicKey;
        // request.issuer.url = ;

        /* assuming this works, we'll update our own model now */
        logInfo(format!"Sending .accept() to %s (%s)"(endpoint.hostAddress, endpoint.publicKey));

        /* So, all in, all out. */
        endpoint.serviceAccount = serviceAccount.id;
        try
        {
            auto client = new RestInterfaceClient!ServiceEnrolmentAPI(endpoint.hostAddress);
            client.requestFilter = (req) {
                req.headers["Authorization"] = format!"Bearer %s"(endpoint.bearerToken);
            };
            client.accept(request, NullableToken(Token.init));
            endpoint.status = EndpointStatus.Operational;
            endpoint.statusText = "Fully configured";
        }
        catch (RestException rx)
        {
            endpoint.status = EndpointStatus.Failed;
            endpoint.statusText = format!"%s"(rx.message);
        }

        immutable uErr = appDB.update((scope tx) => endpoint.save(tx));
        enforceHTTP(uErr.isNull, HTTPStatus.internalServerError, uErr.message);

        redirect("/");
    }

    double totalRam;

private:

    AccountManager accountManager;
    TokenManager tokenManager;
    Database appDB;
}
