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
    DataSeries, MemoryReportIndex, DiskReport, DiskReportIndex;
import vibe.d;
import moss.core.sizing;
import moss.core.memoryinfo;
import vibe.utils.array;
import std.array : array;
import vibe.core.core : setTimer;
import std.range : popFront;
import core.sys.posix.sys.statvfs;

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
        events.reserve(maxEvents);
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

    MemoryInfo minfo;

    TimeDatapoint[] events;
    TimeDatapoint[] availEvents;
    TimeDatapoint[] usedEvents;
    double diskUsed;
    double diskFree;
    ulong numEvents = 0;
}
