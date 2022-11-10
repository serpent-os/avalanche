/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.memoryinfo
 *
 * Access to memory information
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.memoryinfo;

private static immutable meminfoFile = "/proc/meminfo";

import std.stdio : File;
import std.string : split, strip;
import std.conv : to;

private enum MemParse : string
{
    Total = "MemTotal",
    Free = "MemFree",
    Available = "MemAvailable",
}

/**
 * Simple abstraction of memory information with the ability
 * to refresh it.
 */
public final class MemoryInfo
{
    /**
     * Construct new MemoryInfo
     */
    this() @safe
    {
        refresh();
    }

    /**
     * Returns: How much memory do we have in total?
     */
    pure @property double total() @safe @nogc nothrow const
    {
        return _total;
    }

    /**
     * Returns: How much memory is currently available?
     */
    pure @property double available() @safe @nogc nothrow const
    {
        return _available;
    }

    /**
     * Returns: How much free memory do we have?
     */
    pure @property double free() @safe @nogc nothrow const
    {
        return _free;
    }

    /**
     * Reload the stats
     */
    void refresh() @trusted
    {
        auto fi = File(meminfoFile, "r");
        scope (exit)
        {
            fi.close();
        }
        foreach (line; fi.byLine)
        {
            auto splits = line.split(":");
            if (splits.length < 2)
            {
                continue;
            }
            auto kw = splits[0].strip();
            auto val = splits[1].split[0].strip;
            switch (kw)
            {
            case MemParse.Total:
                _total = to!double(val) * 1024.0;
                break;
            case MemParse.Available:
                _available = to!double(val) * 1024.0;
                break;
            case MemParse.Free:
                _free = to!double(val) * 1024.0;
                break;
            default:
                break;
            }
        }
    }

private:

    double _total = 0;
    double _available = 0;
    double _free = 0;
}
