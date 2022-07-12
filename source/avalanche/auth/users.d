/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.auth
 *
 * Authentication + authorization helpers for REST
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.auth.users;

import moss.db.keyvalue;
import moss.db.keyvalue.interfaces;
public import std.stdint : uint64_t;

/**
 * We never recycle these in Avalanche because
 * we would never exceed this value ...
 */
public alias UserIdentifier = uint64_t;

/**
 * So we want different password hashing, for now we
 * store plain text but we'll likely hook up argon2
 * or similar.
 */
public enum PasswordHashing
{
    None = 0
}

/**
 * A User is a composition of a a minimal number of
 * data fields. We don't actually *care* for information,
 * only the whole "user can access services" notion"
 */
public struct User
{
    UserIdentifier uid;
    string username;

    /* We need to know what hash its stored with in case
       of security issue montioring */
    PasswordHashing hash;
}

/**
 * Identification of the user error
 */
public enum UserErrorCode
{
    AlreadyRegistered,
    DatabaseError,
    NoSuchUsername,
}

/**
 * A user error has a distinct code and message
 */
public struct UserError
{
    UserErrorCode code;

    string message;

    /**
     * Handle toString conversion
     */
    auto toString() @safe const
    {
        return message;
    }
}

/**
 * Either a User or a result - assignment of UID already handled
 */
public alias UserResult = SumType!(User, UserError);

/**
 * The UserManager is initialised from a writeable database
 * and is responsible for managing it. It contains only the
 * absolute basics of authentication - and is in no way
 * related to profile metadata (separate use case)
 */
public final class UserManager
{
    @disable this();

    /**
     * Construct a new UserManager
     *
     * Params:
     *      databaseURI = moss-db key-value compatible URI
     */
    this(const(string) databaseURI) @safe
    {
        this.databaseURI = databaseURI;
    }

    /**
     * Connect the UserManager to the underlying database
     */
    DatabaseResult connect() @safe
    {
        DatabaseResult error;
        Database.open(this.databaseURI, DatabaseFlags.CreateIfNotExists).match!((Database db) {
            this.db = db;
        }, (DatabaseError err) { error = err; });
        /* Couldn't connect. :sadface: */
        if (!error.isNull)
        {
            return error;
        }
        /* All good. */
        return NoDatabaseError;
    }

    /**
     * Registration failed
     */
    UserResult registerUser(in string username, in ubyte[] credentials) @safe
    {
        return UserResult(UserError(UserErrorCode.DatabaseError, "DERP NO REGISTER"));
    }

    /**
     * Attempt to lookup the user by their username
     */
    UserResult byUsername(in string username) @safe
    {
        return UserResult(UserError(UserErrorCode.NoSuchUsername, "DERP NO USER"));
    }

    /**
     * Sorry - not coming in
     */
    bool authenticate(in User user, in ubyte[] credentials) @safe
    {
        return false;
    }

    /**
     * Cleanup on aisle 3.
     */
    void close() @safe
    {
        db.close();
    }

    /**
     * Hashing style
     */
    pure @property auto passwordHashing() @safe @nogc nothrow inout
    {
        return hashStyle;
    }

private:

    string databaseURI;
    Database db;
    PasswordHashing hashStyle = PasswordHashing.None;
}
