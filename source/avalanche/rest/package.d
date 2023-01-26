/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.app
 *
 * Main application runtime for build control
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: Zlib
 */

module avalanche.rest;

import vibe.d;
import avalanche.build;
import avalanche.build.job;
import avalanche.rest.pairing;
import avalanche.rest.stats;
import moss.service.interfaces.avalanche;
import moss.db.keyvalue;
import moss.service.context;
import moss.service.models.endpoints;

/**
 * Used in the statistics API
 */
public struct TimeDatapoint
{
    /**
     * When the sample was taken
     */
    long x;

    /**
     * Sample value
     */
    double y;
}

/**
 * Dataseries of specific points
 */
public struct DataSeries(T)
{
    string name;
    T[] data;
}

/**
 * Field indexing
 */
public enum MemoryReportIndex : ulong
{
    Free = 0,
    Available,
    Used
}

/**
 * Simple format memory report
 */
public struct MemoryReport
{
    /**
     * How much memory exists?
     */
    double maxy;

    /**
     * Raw series data
     */
    DataSeries!(TimeDatapoint)[3] series;
}

public struct CpuReport
{
    DataSeries!(TimeDatapoint)[] series;
}

public enum DiskReportIndex : ulong
{
    Free = 0,
    Used,
}

public struct DiskReport
{
    /**
     * Snapshot data for disk usage
     */
    double[2] series;
    string[2] labels;
}

/**
 * Simplistic API that powers our charts
 */
@requiresAuth @path("/api/v1/stats") public interface StatsAPIv1
{
    /**
     * Current memory usage
     */
    @anyAuth @path("memory") @method(HTTPMethod.GET) MemoryReport memory() @safe;

    /**
     * Current disk usage
     */
    @anyAuth @path("disk") @method(HTTPMethod.GET) DiskReport disk() @safe;

    /** 
     * CPU metrics
     */
    @anyAuth @path("cpu") @method(HTTPMethod.GET) CpuReport cpu() @safe;
}

/**
 * Main entry point from the server side, storing our
 * databases and interfaces.
 */
public final class BuildAPI : AvalancheAPI
{

    @disable this();

    mixin AppAuthenticatorContext;

    /**
     * Construct new BuildAPI using the specified rootDir
     */
    this(ServiceContext context) @safe
    {
        this.context = context;
    }

    /**
     * Configure BuildAPI for integration
     */
    @noRoute void configure(URLRouter root) @safe
    {
        auto apiRoot = root.registerRestInterface(this);
        auto pair = new AvalanchePairingAPI(context);
        pair.configure(apiRoot);
        auto stats = new AvalancheStats(context);
        stats.configure(root);
    }

    /**
     * Go ahead and schedule build of the package on a separate fiber
     */
    override void buildPackage(PackageBuild request, NullableToken token) @safe
    {
        enforceHTTP(!working, HTTPStatus.serviceUnavailable, "Sorry, already building something");
        enforceHTTP(request.collections.length > 0, HTTPStatus.badRequest, "Missing collections");
        enforceHTTP(!token.isNull, HTTPStatus.forbidden);

        SummitEndpoint endpoint;
        immutable err = context.appDB.view((in tx) => endpoint.load(tx, token.payload.sub));
        enforceHTTP(err.isNull, HTTPStatus.notFound, "Request from unconfigured SummitEndpoint");

        logInfo(format!"Got a build request from endpoint: %s"(endpoint));

        working = true;
        runTask({
            auto b = new BuildJob(context, request, endpoint);
            b.run();
            working = false;
        });
    }

private:

    string rootDir;
    bool working = false;
    ServiceContext context;
}
