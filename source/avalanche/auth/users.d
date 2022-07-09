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
     * Cleanup on aisle 3.
     */
    void close() @safe
    {
        db.close();
    }

private:

    string databaseURI;
    Database db;
}
