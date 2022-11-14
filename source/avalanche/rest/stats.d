/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * avalanche.rest.stats
 *
 * ServiceEnrolmentAPI implementation for Avalanche
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

module avalanche.rest.stats;

public import avalanche.rest : StatsAPIv1, MemoryReport, TimeDatapoint,
    DataSeries, MemoryReportIndex, DiskReport, DiskReportIndex, CpuReport;
import vibe.d;
import moss.core.sizing;
import moss.core.memoryinfo;
import vibe.utils.array;
import std.array : array;
import vibe.core.core : setTimer;
import std.range : popFront, enumerate;
import core.sys.posix.sys.statvfs;
import avalanche.cpuinfo;
import std.range : iota;
import std.algorithm : each, map;

const auto maxEvents = 60;

/**
 * Statistics API
 */
public final class AvalancheStats : StatsAPIv1
{

    /**
     * Construct new stats api impl
     */
    @noRoute this() @safe
    {
        minfo = new MemoryInfo();
        cpuinfo = new CpuInfo();
        events.reserve(maxEvents);
        usedEvents.reserve(maxEvents);
        availEvents.reserve(maxEvents);

        cpuEvents.reserve(cpuinfo.numCPU);
        cpuEvents.length = cpuinfo.numCPU;
        foreach (i; 0 .. cpuinfo.numCPU)
        {
            auto series = &cpuEvents[i];
            series.data.reserve(numEvents);
            series.name = format!"cpu%s"(i);
        }
        refresh();
    }

    /**
     * Integrate REST app
     */
    @noRoute void configure(URLRouter router) @safe
    {
        router.registerRestInterface(this);
        () @trusted { setTimer(1.seconds, () => refresh(), true); }();
    }

    /**
     * Provide the latest report
     */
    override MemoryReport memory() @safe
    {
        MemoryReport mr;
        mr.maxy = minfo.total;
        mr.series[MemoryReportIndex.Free] = DataSeries!TimeDatapoint("Free", events[0 .. numEvents]);
        mr.series[MemoryReportIndex.Available] = DataSeries!TimeDatapoint("Available",
                availEvents[0 .. numEvents]);
        mr.series[MemoryReportIndex.Used] = DataSeries!TimeDatapoint("Used",
                usedEvents[0 .. numEvents]);
        return mr;
    }

    override CpuReport cpu() @safe
    {
        CpuReport cr;
        cr.series = cpuEvents;
        return cr;
    }

    override DiskReport disk() @safe
    {
        DiskReport dr;
        dr.series[DiskReportIndex.Free] = diskFree;
        dr.series[DiskReportIndex.Used] = diskUsed;
        dr.labels[DiskReportIndex.Free] = "Free";
        dr.labels[DiskReportIndex.Used] = "Used";
        return dr;
    }

private:

    void refresh() @safe
    {
        minfo.refresh();
        cpuinfo.refresh();

        refreshCPU();

        auto event = TimeDatapoint();
        /* JS Conversion */
        event.x = (Clock.currTime(UTC()).toUnixTime()) * 1000;
        event.y = minfo.free;

        auto availEvent = TimeDatapoint();
        availEvent.x = event.x;
        availEvent.y = minfo.available;

        auto usedEvent = TimeDatapoint();
        usedEvent.x = event.x;
        usedEvent.y = minfo.total - minfo.free;

        statvfs_t st;
        immutable rc = () @trusted {
            return statvfs("/var/cache/boulder".toStringz, &st);
        }();
        enforceHTTP(rc == 0, HTTPStatus.internalServerError, "Failed to statvfs()");
        immutable diskSpace = st.f_blocks * st.f_frsize;
        immutable freeSpace = st.f_bfree * st.f_bsize;
        immutable usedSpace = diskSpace - freeSpace;

        if (numEvents + 1 >= maxEvents)
        {
            events.popFront();
            availEvents.popFront();
            usedEvents.popFront();
        }
        else
        {
            ++numEvents;
        }
        events ~= event;
        availEvents ~= availEvent;
        usedEvents ~= usedEvent;

        diskFree = freeSpace;
        diskUsed = usedSpace;
    }

    /**
     * Refresh CPU data
     */
    void refreshCPU() @safe
    {
        immutable timestamp = (Clock.currTime(UTC()).toUnixTime) * 1000;
        immutable needPop = numCPUEvents + 1 >= maxEvents;

        if (!needPop)
        {
            ++numCPUEvents;
        }

        foreach (i; 0 .. cpuinfo.numCPU)
        {
            auto series = &cpuEvents[i];
            if (needPop)
            {
                series.data.popFront();
            }
            series.data ~= TimeDatapoint(timestamp, cpuinfo.frequences[i]);
        }
    }

    MemoryInfo minfo;
    CpuInfo cpuinfo;

    TimeDatapoint[] events;
    TimeDatapoint[] availEvents;
    TimeDatapoint[] usedEvents;

    DataSeries!(TimeDatapoint)[] cpuEvents;
    double diskUsed;
    double diskFree;
    ulong numEvents = 0;

    ulong numCPUEvents = 0;
}
