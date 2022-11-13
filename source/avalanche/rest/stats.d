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

public import avalanche.rest : StatsAPIv1, MemoryReport, TimeDatapoint, DataSeries, MemoryReportIndex;
import vibe.d;
import moss.core.memoryinfo;
import vibe.utils.array;
import std.array : array;
import vibe.core.core : setTimer;
import std.range : popFront;

const auto maxEvents = 60;

/**
 * Statistics API
 */
public final class AvalancheStats : StatsAPIv1
{

    /**
     * Construct new stats api impl
     */
    this() @safe
    {
        minfo = new MemoryInfo();
        events.reserve(maxEvents);
        refresh();
    }

    /**
     * Integrate REST app
     */
    void configure(URLRouter router) @safe
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
        mr.series[MemoryReportIndex.Used] = DataSeries!TimeDatapoint("Free", events[0..numEvents]);
        mr.series[MemoryReportIndex.Available] = DataSeries!TimeDatapoint("Available", availEvents[0..numEvents]);
        mr.series[MemoryReportIndex.Free] = DataSeries!TimeDatapoint("Free", usedEvents[0..numEvents]);
        return mr;
    }

private:

    void refresh() @safe
    {
        minfo.refresh();

        auto event = TimeDatapoint();
        event.x = Clock.currTime(UTC()).toUnixTime();
        event.y = minfo.free;

        auto availEvent = TimeDatapoint();
        availEvent.x = event.x;
        availEvent.y = minfo.available;

        auto usedEvent = TimeDatapoint();
        usedEvent.x = event.x;
        usedEvent.y = minfo.total - minfo.free;

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
    }

    MemoryInfo minfo;

    TimeDatapoint[] events;
    TimeDatapoint[] availEvents;
    TimeDatapoint[] usedEvents;
    ulong numEvents = 0;
}
