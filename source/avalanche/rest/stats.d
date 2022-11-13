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

public import avalanche.rest : StatsAPIv1, MemoryReport, TimeDatapoint;
import vibe.d;
import moss.core.memoryinfo;
import vibe.utils.array;
import std.array : array;
import vibe.core.core : setTimer;
import std.range : popFront;

const auto maxEvents = 100;

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
        () @trusted { setTimer(3.seconds, () => refresh(), true); }();
    }

    /**
     * Provide the latest report
     */
    override MemoryReport memory() @safe
    {
        MemoryReport mr;
        mr.available = availEvents[0 .. numEvents];
        mr.free = events[0 .. numEvents];
        mr.used = usedEvents[0 .. numEvents];
        mr.total = minfo.total;
        return mr;
    }

private:

    void refresh() @safe
    {
        minfo.refresh();

        auto event = TimeDatapoint();
        event.value = minfo.free;
        event.timestamp = Clock.currTime(UTC()).toUnixTime();

        auto availEvent = TimeDatapoint();
        availEvent.timestamp = event.timestamp;
        availEvent.value = minfo.available;

        auto usedEvent = TimeDatapoint();
        usedEvent.timestamp = event.timestamp;
        usedEvent.value = minfo.total - minfo.free;

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
