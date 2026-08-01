import { escapeHtml } from "./utils.js";

/**
 * Render Fun Game display for public monitoring page.
 * Shows point tables for Batch 1, Batch 2, and Final with podium.
 */
export function renderFunGame(area, teams, entries) {
    const teamMap = {};
    for (const t of teams) teamMap[t.id] = t;

    const batch1 = entries
        .filter(e => e.phase === "batch_1")
        .sort((a, b) => {
            if (a.final_rank && b.final_rank) return a.final_rank - b.final_rank;
            if (a.final_rank) return -1;
            if (b.final_rank) return 1;
            return (b.total_points || 0) - (a.total_points || 0);
        });

    const batch2 = entries
        .filter(e => e.phase === "batch_2")
        .sort((a, b) => {
            if (a.final_rank && b.final_rank) return a.final_rank - b.final_rank;
            if (a.final_rank) return -1;
            if (b.final_rank) return 1;
            return (b.total_points || 0) - (a.total_points || 0);
        });

    const finalEntries = entries
        .filter(e => e.phase === "final")
        .sort((a, b) => {
            if (a.final_rank && b.final_rank) return a.final_rank - b.final_rank;
            if (a.final_rank) return -1;
            if (b.final_rank) return 1;
            return (b.total_points || 0) - (a.total_points || 0);
        });

    const container = document.createElement("div");
    container.className = "fun-game-container";

    // Batch 1 Table
    container.appendChild(buildBatchSection("BATCH 1", "B-1", batch1, teamMap, true));

    // Batch 2 Table
    container.appendChild(buildBatchSection("BATCH 2", "B-2", batch2, teamMap, true));

    // Final Table (if exists)
    if (finalEntries.length > 0) {
        container.appendChild(buildBatchSection("FINAL", "FINAL", finalEntries, teamMap, false));
        container.appendChild(buildFunGamePodium(finalEntries, teamMap));
    } else {
        const pending = document.createElement("div");
        pending.className = "fg-final-pending";
        pending.innerHTML = `
            <div class="fg-final-pending-icon">🏆</div>
            <div class="fg-final-pending-text">FINAL</div>
            <div class="fg-final-pending-sub">Menunggu hasil Batch 1 & Batch 2</div>
        `;
        container.appendChild(pending);
    }

    return container;
}

function buildBatchSection(title, shortTitle, entries, teamMap, showQualifier) {
    const section = document.createElement("div");
    section.className = "fg-batch-section";

    const header = document.createElement("div");
    header.className = "fg-batch-header";
    header.innerHTML = `<span class="fg-batch-badge">${shortTitle}</span><span class="fg-batch-title">${title}</span>`;
    section.appendChild(header);

    const table = document.createElement("table");
    table.className = "fg-table";

    // Responsive wrapper
    const wrapper = document.createElement("div");
    wrapper.className = "fg-table-wrapper";

    table.innerHTML = `
        <thead>
            <tr>
                <th class="fg-th-rank">#</th>
                <th class="fg-th-team">TIM</th>
                <th class="fg-th-game" colspan="2">TARIK TAMBANG</th>
                <th class="fg-th-game" colspan="2">L. SARUNG</th>
                <th class="fg-th-game" colspan="2">L. BOLA</th>
                <th class="fg-th-total">TOTAL</th>
            </tr>
            <tr class="fg-sub-header">
                <th></th>
                <th></th>
                <th class="fg-sub">WIN</th>
                <th class="fg-sub">POIN</th>
                <th class="fg-sub">RANK</th>
                <th class="fg-sub">POIN</th>
                <th class="fg-sub">RANK</th>
                <th class="fg-sub">POIN</th>
                <th></th>
            </tr>
        </thead>
        <tbody></tbody>
    `;

    const tbody = table.querySelector("tbody");

    entries.forEach((entry, idx) => {
        const team = teamMap[entry.team_id];
        const teamName = team ? team.name : "—";
        const rank = entry.final_rank || (idx + 1);
        const isQualifier = showQualifier && rank <= 2;
        const hasData = entry.tt_wins > 0 || entry.sarung_rank || entry.bola_rank;

        const tr = document.createElement("tr");
        tr.className = `fg-row ${isQualifier ? "fg-row-qualifier" : ""} ${rank === 1 ? "fg-row-first" : ""}`;

        tr.innerHTML = `
            <td class="fg-rank">
                <span class="fg-rank-badge fg-rank-${rank}">${rank}</span>
            </td>
            <td class="fg-team-name">${escapeHtml(teamName)}</td>
            <td class="fg-value">${entry.tt_wins || 0}</td>
            <td class="fg-value fg-points">${entry.tt_points || 0}</td>
            <td class="fg-value">${entry.sarung_rank || "—"}</td>
            <td class="fg-value fg-points">${entry.sarung_points || 0}</td>
            <td class="fg-value">${entry.bola_rank || "—"}</td>
            <td class="fg-value fg-points">${entry.bola_points || 0}</td>
            <td class="fg-total ${hasData ? "fg-total-active" : ""}">${entry.total_points || 0}</td>
        `;

        tbody.appendChild(tr);
    });

    wrapper.appendChild(table);
    section.appendChild(wrapper);

    if (showQualifier && entries.length > 0) {
        const note = document.createElement("div");
        note.className = "fg-qualifier-note";
        note.innerHTML = `<span class="fg-qualifier-dot"></span> Peringkat 1 & 2 lolos ke Final`;
        section.appendChild(note);
    }

    return section;
}

function buildFunGamePodium(finalEntries, teamMap) {
    const podium = document.createElement("div");
    podium.className = "fg-podium";

    const items = [
        { place: "Juara 1", cls: "gold", rank: 1 },
        { place: "Juara 2", cls: "silver", rank: 2 },
        { place: "Juara 3", cls: "bronze", rank: 3 },
        { place: "Juara 4", cls: "fourth", rank: 4 }
    ];

    for (const item of items) {
        const entry = finalEntries.find(e => e.final_rank === item.rank)
            || finalEntries[item.rank - 1];

        const team = entry ? teamMap[entry.team_id] : null;

        const div = document.createElement("div");
        div.className = `fg-podium-item fg-podium-${item.cls}`;

        div.innerHTML = `
            <div class="fg-podium-label">${item.place}</div>
            <div class="fg-podium-team">${team ? escapeHtml(team.name) : "Belum Ditentukan"}</div>
            ${entry && entry.total_points ? `<div class="fg-podium-points">${entry.total_points} poin</div>` : ""}
        `;

        if (!team) div.style.opacity = "0.5";
        podium.appendChild(div);
    }

    return podium;
}
