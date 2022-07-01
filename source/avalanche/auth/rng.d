/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.auth.rng
 *
 * Random Number Generation helpers
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.auth.rng;

import deimos.openssl.rand;
import std.concurrency : initOnce;

private __gshared RandomNumberGenerator _rng;

/**
 * Return the shared RNG
 */
public static RandomNumberGenerator RNG() @trusted
{
    return initOnce!_rng(new RandomNumberGenerator());
}

shared static ~this()
{
    _rng.destroy();
    _rng = null;
}

/**
 * Loose abstraction around openssl rand behaviour
 */
public final class RandomNumberGenerator
{

}
