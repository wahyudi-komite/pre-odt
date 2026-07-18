import { supabase } from "./supabase-client.js";

export async function fetchTournament(slug) {
    const { data, error } = await supabase
        .from("tournaments")
        .select("*")
        .eq("slug", slug)
        .single();
    if (error) throw error;
    return data;
}

export async function fetchAreas(tournamentId) {
    const { data, error } = await supabase
        .from("areas")
        .select("*")
        .eq("tournament_id", tournamentId)
        .order("area_number", { ascending: true });
    if (error) throw error;
    return data;
}

export async function fetchTeams(areaId) {
    const { data, error } = await supabase
        .from("teams")
        .select("*")
        .eq("area_id", areaId)
        .order("seed_number", { ascending: true });
    if (error) throw error;
    return data;
}

export async function fetchAllTeams(areaIds) {
    const { data, error } = await supabase
        .from("teams")
        .select("*")
        .in("area_id", areaIds)
        .order("seed_number", { ascending: true });
    if (error) throw error;
    return data;
}

export async function fetchMatches(areaId) {
    const { data, error } = await supabase
        .from("matches")
        .select("*")
        .eq("area_id", areaId)
        .order("display_order", { ascending: true });
    if (error) throw error;
    return data;
}

export async function fetchAllMatches(areaIds) {
    const { data, error } = await supabase
        .from("matches")
        .select("*")
        .in("area_id", areaIds)
        .order("display_order", { ascending: true });
    if (error) throw error;
    return data;
}

export async function fetchAuditLogs(areaId, limit = 30) {
    const { data, error } = await supabase
        .from("match_audit_logs")
        .select("*")
        .eq("area_id", areaId)
        .order("created_at", { ascending: false })
        .limit(limit);
    if (error) throw error;
    return data;
}

export async function saveMatchResult(params) {
    const { data, error } = await supabase.rpc("save_match_result", params);
    if (error) throw error;
    if (data && data.ok === false) throw new Error(data.message || "Gagal menyimpan.");
    return data;
}

export async function resetMatchResult(params) {
    const { data, error } = await supabase.rpc("reset_match_result", params);
    if (error) throw error;
    return data;
}

export async function updateTeamName(params) {
    const { data, error } = await supabase.rpc("update_team_name", params);
    if (error) throw error;
    return data;
}

export async function resetArea(params) {
    const { data, error } = await supabase.rpc("reset_area", params);
    if (error) throw error;
    return data;
}
