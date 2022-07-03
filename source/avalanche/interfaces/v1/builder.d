/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.interfaces.v1.builder
 *
 * REST API for the builder mechanism
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.interfaces.v1.builder;

public import vibe.d : path, method, HTTPMethod;
public import vibe.web.auth;

/**
 * `avalanche` only supports Git upstreams
 */
public enum OriginType : string
{
    /**
     * Git origin - default
     */
    Git = "git",

    /**
     * S-O-L
     */
    Unsupported = ":error:",
}

/**
 * What we define as being buildable.
 */
public struct BuildBundle
{
    /** Decided on by summit */
    ulong remoteIdentifier;

    /** Git or .. what? */
    OriginType originType;

    /** Relative recipe */
    string recipePath;

    /* Where do we get this? */
    string originURI;

    /** Git ref */
    string originRef;

    /** Architecture to build for */
    string architecture;
}

/**
 * A Controller can send a request for the builder to enrol.
 *
 * Note, it is not automatically accepted - rather, it is
 * reviewed by a human.
 */
public struct ControllerEnrolmentRequest
{
    /**
     * Controllers host/IP
     */
    string host;

    /**
     * Controllers port number
     */
    uint port;

    /**
     * Assigned JWT for us
     */
    string token;
}

/**
 * Our "v1" API for the Builder
 */
@requiresAuth @path("api/v1/builder") public interface BuilderAPIv1
{

    /**
     * GET /api/v1/builder/version_identifier
     *
     * Placeholder. :)
     */
    @noAuth @property string versionIdentifier() @safe;

    /**
     * PUT /api/v1/builder/build_bundle
     *
     * Request build of the given bundle
     */
    @anyAuth @method(HTTPMethod.PUT) void buildBundle(BuildBundle bundle) @system;

    /**
     * PUT /api/v1/builder/enroll
     */
    @noAuth @method(HTTPMethod.PUT) void enrol(ControllerEnrolmentRequest cer) @system;
}