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

import std.experimental.typecons : wrap;
import std.typecons : Nullable;
import std.traits : getSymbolsByUDA;
import std.traits : OriginalType;

/**
 * UDA: Usually applies to the username field.
 */
public struct UserIdentifier
{
}

/**
 * Specialist contract for Users
 * Note that *user properties* are metadata and outside the
 * scope of a user implementation.
 */
public interface User
{
    /**
     * Attempt to authenticate the user with the given hash
     */
    bool authenticate(in ubyte[] hash);

    /**
     * Update the password
     */
    void updatePassword(in ubyte[] newPassword);
}

/**
 * If the type is a class and implements User interface,
 * or if the type is a struct and *conforms* to User interface, yes.
 */
static bool isUserType(U)()
{
    /* Ensure this conforms to the User interface */
    static if (is(U == struct) && is(typeof({ U val; val.wrap!User; return; }()) == void))
    {
        return true;
    }
    else
    {
        /* Class based, does it implement User? */
        static if (is(U == class) && is(U == User))
        {
            return true;
        }
        else
        {
            return false;
        }
    }
}

/**
 * Helper mixin to determine the User struct's identifier **type**
 */
static template identifierType(U)
{
    static assert(getSymbolsByUDA!(U, UserIdentifier).length == 1,
            U.stringof ~ " must provide ONE field marked with UserIdentifier");
    const char[] identifierType = "typeof(getSymbolsByUDA!(U, UserIdentifier)[0])";
}

/**
 * UserManager is responsible for storing all Users
 */
public final class UserManager(U)
{
    static assert(isUserType!U, "UserManager must be used with a valid User implementation");
    alias UserType = U;

    alias NullableUser = Nullable!(UserType, UserType.init);
    alias ID = mixin(identifierType!U);

    /**
     * Return a user object by the identifier
     */
    NullableUser getUser(in ID search)
    {
        return NullableUser(UserType.init);
    }
}
