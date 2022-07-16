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
import std.string : format;

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
        User newUser = User(0, username, passwordHashing);

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

            auto e2 = tx.set(userBucket, "hashMethod", newUser.hash);
            if (!e2.isNull)
            {
                return e2;
            }

            auto e3 = tx.set(userBucket, "username", newUser.username);
            if (!e3.isNull)
            {
                return e3;
            }

            /* TODO: Encrypt the damn credentials! */
            return tx.set(userBucket, "hash", credentials);
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
            auto authMethod = tx.get!PasswordHashing(result, "hashMethod");
            auto authHash = tx.get!string(result, "hash");
            if (authHash.isNull)
            {
                return NoDatabaseError;
            }

            /* TODO: Proper hash method based checks */
            didAuth = credentials == authHash.get;
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
     * Hashing style
     */
    pure @property auto passwordHashing() @safe @nogc nothrow inout
    {
        return hashStyle;
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
                return User(t.value, t.key, PasswordHashing.None);
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
    PasswordHashing hashStyle = PasswordHashing.None;
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
