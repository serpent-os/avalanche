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
        events.length = 100;
        events.reserve(100);
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
        mr.used = events[0 .. numEvents];
        mr.total = minfo.total;
        return mr;
    }

private:

    void refresh() @safe
    {
        minfo.refresh();

        auto event = TimeDatapoint();
        event.value = minfo.total - minfo.free;
        event.timestamp = Clock.currTime(UTC()).toUnixTime();
        if (numEvents + 1 >= 100)
        {
            events.popFront();
            events ~= event;
        }
        else
        {
            events[numEvents] = event;
            ++numEvents;
        }
    }

    MemoryInfo minfo;

    TimeDatapoint[] events;
    ulong numEvents = 0;
}
