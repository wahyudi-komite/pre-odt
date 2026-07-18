import { supabase } from "./supabase-client.js";

let activeChannels = [];

export function subscribeMatches(areaIds, onChange) {
    const topic = "matches:" + areaIds.join(",");
    const channel = supabase.channel(topic);

    channel.on(
        "postgres_changes",
        {
            event: "*",
            schema: "public",
            table: "matches"
        },
        (payload) => {
            onChange(payload);
        }
    );

    channel.subscribe();
    activeChannels.push(channel);
    return channel;
}

export function subscribeTeams(areaIds, onChange) {
    const topic = "teams:" + areaIds.join(",");
    const channel = supabase.channel(topic);

    channel.on(
        "postgres_changes",
        {
            event: "*",
            schema: "public",
            table: "teams"
        },
        (payload) => {
            onChange(payload);
        }
    );

    channel.subscribe();
    activeChannels.push(channel);
    return channel;
}

export function subscribeAll(callback) {
    const channel = supabase.channel("all-changes");

    channel.on(
        "postgres_changes",
        { event: "*", schema: "public", table: "matches" },
        (payload) => callback("matches", payload)
    );

    channel.on(
        "postgres_changes",
        { event: "*", schema: "public", table: "teams" },
        (payload) => callback("teams", payload)
    );

    channel.subscribe();
    activeChannels.push(channel);
    return channel;
}

export function unsubscribeAll() {
    for (const ch of activeChannels) {
        supabase.removeChannel(ch);
    }
    activeChannels = [];
}
