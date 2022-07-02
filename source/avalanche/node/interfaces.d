/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.node
 *
 * REST API for the node mechanism
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.node.interfaces;

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
 * A Controller can send a request for the node to enrol.
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
 * Our "v1" API for the Node
 */
@requiresAuth @path("api/v1/node") public interface NodeAPIv1
{

    /**
     * GET /api/v1/node/version_identifier
     *
     * Placeholder. :)
     */
    @noAuth @property string versionIdentifier() @safe;

    /**
     * PUT /api/v1/node/build_bundle
     *
     * Request build of the given bundle
     */
    @anyAuth @method(HTTPMethod.PUT) void buildBundle(BuildBundle bundle) @system;

    /**
     * PUT /api/v1/node/enroll
     */
    @noAuth @method(HTTPMethod.PUT) void enrol(ControllerEnrolmentRequest cer) @system;
}
