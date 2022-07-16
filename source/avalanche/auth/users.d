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
import std.string : format, toStringz, fromStringz;
import libsodium;

public import std.stdint : uint64_t;

/**
 * We never recycle these in Avalanche because
 * we would never exceed this value ...
 */
public alias UserIdentifier = uint64_t;

/**
 * A User is a composition of a a minimal number of
 * data fields. We don't actually *care* for information,
 * only the whole "user can access services" notion"
 */
public struct User
{
    UserIdentifier uid;
    string username;
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

        /* Ensure we haz buckets */
        db.update((scope tx) @safe {
            foreach (bucket; [".meta", ".users"])
            {
                auto bkR = tx.createBucketIfNotExists(bucket);
                bkR.tryMatch!((Bucket b) {});
            }
            return NoDatabaseError;
        });

        /* All good. */
        return NoDatabaseError;
    }

    /**
     * Registration failed
     */
    UserResult registerUser(in string username, in string credentials) @safe
    {
        UserError err;
        /* TODO: Assign uid */
        User newUser = User(0, username);

        /* Atomically locked operation */
        db.update((scope tx) @safe {
            auto userTable = tx.bucket(".users");
            assert(!userTable.isNull);

            /* Can't replace old identity, sorry */
            auto oldIdent = tx.get!UserIdentifier(userTable, username);
            if (!oldIdent.isNull)
            {
                err = UserError(UserErrorCode.AlreadyRegistered, "That username is already taken");
                return NoDatabaseError;
            }

            /* Grab a UID please. */
            auto result = nextUserIdentifier(tx);
            result.match!((UserIdentifier id) { newUser.uid = id; }, (DatabaseError uErr) {
                err.code = UserErrorCode.DatabaseError;
                err.message = uErr.message;
            });

            if (err != UserError.init)
            {
                return NoDatabaseError;
            }

            /* try to assign the usernames and account */
            auto e = tx.set(userTable, username, newUser.uid);
            if (!e.isNull)
            {
                return e;
            }

            /* Now we need a per-user bucket */
            auto bucketID = () @trusted {
                return format!"account.%d"(newUser.uid);
            }();

            /* Technically we crash if the account bucket exists, but
               absofuckinglutely it should not exist. */
            Bucket userBucket = tx.createBucket(bucketID).tryMatch!((Bucket b) => b);
            auto e2 = tx.set(userBucket, "username", newUser.username);
            if (!e2.isNull)
            {
                return e2;
            }

            auto hashed = generateSodiumHash(credentials);
            assert(hashed !is null);
            return tx.set(userBucket, "hash", hashed);
        });

        if (err != UserError.init)
        {
            return UserResult(err);
        }

        return UserResult(newUser);
    }

    /**
     * Attempt to lookup the user by their username
     */
    UserResult byUsername(in string username) @safe
    {
        User lookup;
        UserError err = UserError.init;
        db.view((in tx) @safe {
            auto bk = tx.bucket(".users");
            auto identity = tx.get!UserIdentifier(bk, username);
            if (identity.isNull)
            {
                err = UserError(UserErrorCode.NoSuchUsername, "Unknown username");
                return NoDatabaseError;
            }
            lookup.username = username;
            lookup.uid = identity;
            return NoDatabaseError;
        });
        if (err != UserError.init)
        {
            return UserResult(err);
        }
        return UserResult(lookup);
    }

    /**
     * Sorry - not coming in
     */
    bool authenticate(in User user, in string credentials) @safe
    {
        bool didAuth = false;

        /* Now we need a per-user bucket */
        auto bucketID = () @trusted { return format!"account.%d"(user.uid); }();

        db.view((in tx) @safe {
            auto result = tx.bucket(bucketID);
            if (result.isNull)
            {
                return NoDatabaseError;
            }
            auto authHash = tx.get!string(result, "hash");
            if (authHash.isNull)
            {
                return NoDatabaseError;
            }

            didAuth = sodiumHashMatch(authHash.get, credentials);
            return NoDatabaseError;
        });
        return didAuth;
    }

    /**
     * Cleanup on aisle 3.
     */
    void close() @safe
    {
        if (db !is null)
        {
            db.close();
        }
    }

    /**
     * Grab all users.
     */
    auto users() @safe
    {
        User[] users;
        import std.algorithm : map;
        import std.array : array;

        db.view((in tx) @safe {
            auto bk = tx.bucket(".users");
            users = tx.iterator!(string, UserIdentifier)(bk).map!((t) @safe {
                return User(t.value, t.key);
            }).array;
            return NoDatabaseError;
        });
        return users;
    }

private:

    /**
     * Allocate a new user identity - doesn't mean its *valid*
     */
    auto nextUserIdentifier(scope Transaction tx) return @safe
    {
        /* Start at 1, 0 is invalid */
        UserIdentifier next = 1;
        auto bucket = tx.bucket(".meta");
        assert(!bucket.isNull);

        /* Got an existing one? */
        auto existing = tx.get!UserIdentifier(bucket, "nextUserIdentifier");
        if (!existing.isNull)
        {
            next = existing + 1;
        }

        auto ret = tx.set(bucket, "nextUserIdentifier", next);
        if (!ret.isNull)
        {
            return SumType!(UserIdentifier, DatabaseError)(ret);
        }
        return SumType!(UserIdentifier, DatabaseError)(next);
    }

    string databaseURI;
    Database db;
}

/**
 * Generate sodium hash from input
 */
static private string generateSodiumHash(in string password) @safe
{
    char[crypto_pwhash_STRBYTES] ret;
    auto inpBuffer = password.toStringz;
    int rc = () @trusted {
        return crypto_pwhash_str(ret, cast(char*) inpBuffer, password.length,
                crypto_pwhash_OPSLIMIT_INTERACTIVE, crypto_pwhash_MEMLIMIT_INTERACTIVE);
    }();

    if (rc != 0)
    {
        return null;
    }
    return ret.fromStringz.dup;
}

/**
 * Verify a password matches the given stored hash
 */
static private bool sodiumHashMatch(in string hash, in string userPassword) @safe
in
{
    assert(hash.length <= crypto_pwhash_STRBYTES);
}
do
{
    return () @trusted {
        char[crypto_pwhash_STRBYTES] buf;
        auto pwPtr = hash.toStringz;
        auto userPtr = userPassword.toStringz;
        buf[0 .. hash.length + 1] = pwPtr[0 .. hash.length + 1];

        return crypto_pwhash_str_verify(buf, userPtr, userPassword.length);
    }() == 0;
}

@("Test basic functionality for UserManagement") @safe unittest
{
    auto db = new UserManager("lmdb://TESTUSERS");
    db.connect();
    scope (exit)
    {
        import std.file : rmdirRecurse;

        db.close();
        rmdirRecurse("TESTUSERS");
    }

    /* Make sure we have no users */
    assert(db.users.length == 0);

    /* Ensure we can register the "root" user */
    auto result = db.registerUser("root", "uncomplexPassword");
    auto user = result.tryMatch!((User u) => u);

    /* Lets authenticate with the right password */
    assert(db.authenticate(user, "uncomplexPassword"), "Password auth failed");
    assert(!db.authenticate(user, "uncomplexPassw0rd"), "Password should NOT work");

    assert(db.users.length == 1);

    /* Ensure we can find *only* the root user */
    auto root = db.byUsername("root");
    auto ud = root.tryMatch!((User u) => u);
    auto non = db.byUsername("bob");
    auto ud2 = non.tryMatch!((UserError e) => e);

    auto result2 = db.registerUser("root", "notagainsurely");
    auto err = result2.tryMatch!((UserError e) => e);
    assert(err.code == UserErrorCode.AlreadyRegistered);

    /* Now try registering another user - ensure uid is 2 */
    auto bob = db.registerUser("bob", "chickendippers");
    User b = bob.tryMatch!((User u) => u);
    assert(b.uid == 2, "UID progression broken");

    assert(!db.authenticate(b, "uncomplexPassword"), "Ehhh");
    assert(db.authenticate(b, "chickendippers"), "Something is fucked");
}
