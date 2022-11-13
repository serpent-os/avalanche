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
import vibe.utils.array : FixedRingBuffer;
import std.array : array;

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
        refresh();
    }

    /**
     * Integrate REST app
     */
    void configure(URLRouter router) @safe
    {
        router.registerRestInterface(this);
    }

    /**
     * Provide the latest report
     */
    override MemoryReport memory() @safe
    {
        refresh();
        MemoryReport mr;
        mr.total = minfo.total;
        mr.used = () @trusted { return events[].array; }();
        return mr;
    }

private:

    void refresh() @safe
    {
        minfo.refresh();

        auto event = TimeDatapoint();
        event.value = minfo.total - minfo.free;
        event.timestamp = Clock.currTime(UTC()).toUnixTime();
        if (events.full)
        {
            events.popFront();
        }
        events.putBack(event);
    }

    MemoryInfo minfo;

    FixedRingBuffer!(TimeDatapoint, 100) events;
}
