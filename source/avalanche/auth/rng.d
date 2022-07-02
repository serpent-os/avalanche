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
import std.exception : enforce, assumeUnique;
import std.random : rndGen;
import std.range : take;
import std.array : array;
import std.digest : toHexString, LetterCase;

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
 * 512-bit keys
 */
private enum BitSize = 512 / 8;
/**
 * Loose abstraction around openssl rand behaviour
 */
public final class RandomNumberGenerator
{

public:

    /**
     * Return a newly generated key with the given size
     */
    ubyte[BitSize] generate() @safe
    {
        ubyte[BitSize] buffer;
        int rc = () @trusted {
            return RAND_bytes(&buffer[0], cast(int) buffer.sizeof);
        }();
        enforce(rc == 1, "RNG.generate(): Failed to generate random bytes");
        return buffer;
    }

    /**
     * Generate a new key encoded as hex
     */
    string generateHex() @safereturn
    {
        ubyte[BitSize] buffer = generate();
        char[BitSize * 2] hexBuffer = toHexString!(LetterCase.lower)(buffer);
        return hexBuffer.dup;
    }

package:

    this() @trusted
    {
        /* Ensure RAND is initialised */
        RAND_poll();

        /* Initialise RNG */
        auto rx = RAND_load_file("/dev/random", BitSize);
        enforce(rx == BitSize, "RNG(): Failed to load random data");

        regenerateSeed();
    }

private:

    /**
     * Regenerate the seed using dlang functions
     */
    void regenerateSeed()
    {
        auto dRng = rndGen();
        immutable(uint[]) sequence = assumeUnique(dRng.take(BitSize).array);

        /* Seed OpenSSL RAND */
        RAND_seed(cast(void*) sequence.ptr, BitSize);
    }
}
