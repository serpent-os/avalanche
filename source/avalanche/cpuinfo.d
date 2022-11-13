/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.cpuinfo
 *
 * Query the CPU information
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.cpuinfo;

import std.algorithm : each, map;
import std.conv : to;
import std.file : readText;
import std.parallelism : totalCPUs;
import std.range : iota;
import std.string : format, strip;
import std.typecons : tuple;

/**
 * CPU information
 */
public final class CpuInfo
{
    /**
     * Construct new CpuInfo
     */
    this() @safe
    {
        numCPU = totalCPUs();
        _frequences.reserve(totalCPUs);
        _frequences.length = totalCPUs;

        refresh();
    }

    /**
     * Refresh data
     */
    void refresh() @safe
    {

        iota(0, totalCPUs).map!((i) => tuple!("cpu", "freq")(i,
                readText(format!"/sys/devices/system/cpu/cpu%d/cpufreq/scaling_cur_freq"(i))
                .strip.to!double))
            .each!((cpu, freq) => _frequences[cpu] = freq);
    }

    /**
     * Return the frequencies rifht now
     */
    @property auto frequences() @safe
    {
        return _frequences[0 .. numCPU];
    }

    ulong numCPU = 0;

private:
    double[] _frequences;
}
