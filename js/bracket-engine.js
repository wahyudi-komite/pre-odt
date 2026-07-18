import { escapeHtml, statusLabel, statusBadgeClass, stageLabel } from "./utils.js";

export function renderBracket(area, teams, matches) {
    const teamMap = {};
    for (const t of teams) {
        teamMap[t.id] = t;
    }

    const matchMap = {};
    for (const m of matches) {
        matchMap[m.match_code] = m;
    }

    const container = document.createElement("div");
    container.className = "bracket-container";

    const cols = [
        { title: "Perempat Final", codes: ["QF1", "QF2", "QF3", "QF4"] },
        { title: "Semifinal", codes: ["SF1", "SF2"] },
        { title: "Final & Juara 3", codes: ["F", "TP"] },
        { title: "Podium", codes: ["podium"] }
    ];

    for (const col of cols) {
        const colDiv = document.createElement("div");
        colDiv.className = "bracket-col";

        const header = document.createElement("div");
        header.className = "bracket-col-header";
        header.textContent = col.title;
        colDiv.appendChild(header);

        if (col.codes[0] === "podium") {
            colDiv.appendChild(renderPodium(matchMap, teamMap));
        } else {
            for (const code of col.codes) {
                const m = matchMap[code];
                if (m) {
                    colDiv.appendChild(renderMatchCard(m, matchMap, teamMap));
                }
            }
        }

        container.appendChild(colDiv);
    }

    return container;
}

function renderMatchCard(match, matchMap, teamMap) {
    const card = document.createElement("div");
    card.className = "match-card";
    card.dataset.matchId = match.id;

    const header = document.createElement("div");
    header.className = "match-header";

    const codeSpan = document.createElement("span");
    codeSpan.className = "match-code";
    codeSpan.textContent = match.match_code;

    const badge = document.createElement("span");
    badge.className = "match-badge " + statusBadgeClass(match.status);
    badge.textContent = statusLabel(match.status);

    header.appendChild(codeSpan);
    header.appendChild(badge);
    card.appendChild(header);

    const stageSpan = document.createElement("div");
    stageSpan.className = "match-stage";
    stageSpan.textContent = stageLabel(match.stage);
    card.appendChild(stageSpan);

    const t1 = match.team1_id ? teamMap[match.team1_id] : null;
    const t2 = match.team2_id ? teamMap[match.team2_id] : null;

    const t1Row = document.createElement("div");
    t1Row.className = "team-row";
    if (match.winner_team_id && match.team1_id === match.winner_team_id) {
        t1Row.classList.add("team-winner");
    }
    if (match.loser_team_id && match.team1_id === match.loser_team_id) {
        t1Row.classList.add("team-loser");
    }

    const t1Name = document.createElement("span");
    t1Name.className = "team-name";
    if (t1) {
        if (match.winner_team_id === t1.id) {
            const check = document.createElement("span");
            check.className = "check-icon";
            check.textContent = "✓ ";
            t1Name.prepend(check);
        }
        t1Name.append(document.createTextNode(t1.name));
    } else {
        t1Name.textContent = getPlaceholderText(match, "team1", matchMap);
    }

    const t1Score = document.createElement("span");
    t1Score.className = "team-score";
    if (t1 && match.score_team1 != null) {
        t1Score.textContent = match.score_team1;
        if (match.penalty_team1 != null && match.score_team1 === match.score_team2) {
            t1Score.textContent += " (" + match.penalty_team1 + ")";
        }
    }

    t1Row.appendChild(t1Name);
    t1Row.appendChild(t1Score);
    card.appendChild(t1Row);

    const t2Row = document.createElement("div");
    t2Row.className = "team-row";
    if (match.winner_team_id && match.team2_id === match.winner_team_id) {
        t2Row.classList.add("team-winner");
    }
    if (match.loser_team_id && match.team2_id === match.loser_team_id) {
        t2Row.classList.add("team-loser");
    }

    const t2Name = document.createElement("span");
    t2Name.className = "team-name";
    if (t2) {
        if (match.winner_team_id === t2.id) {
            const check = document.createElement("span");
            check.className = "check-icon";
            check.textContent = "✓ ";
            t2Name.prepend(check);
        }
        t2Name.append(document.createTextNode(t2.name));
    } else {
        t2Name.textContent = getPlaceholderText(match, "team2", matchMap);
    }

    const t2Score = document.createElement("span");
    t2Score.className = "team-score";
    if (t2 && match.score_team2 != null) {
        t2Score.textContent = match.score_team2;
        if (match.penalty_team2 != null && match.score_team1 === match.score_team2) {
            t2Score.textContent += " (" + match.penalty_team2 + ")";
        }
    }

    t2Row.appendChild(t2Name);
    t2Row.appendChild(t2Score);
    card.appendChild(t2Row);

    if (match.status === "finished" && match.penalty_team1 != null) {
        const penNote = document.createElement("div");
        penNote.className = "penalty-note";
        penNote.textContent = "Menang adu penalti";
        card.appendChild(penNote);
    }

    return card;
}

function renderPodium(matchMap, teamMap) {
    const podium = document.createElement("div");
    podium.className = "podium-container";

    const finalMatch = matchMap["F"];
    const tpMatch = matchMap["TP"];

    const champion = finalMatch && finalMatch.winner_team_id ? teamMap[finalMatch.winner_team_id] : null;
    const runnerUp = finalMatch && finalMatch.loser_team_id ? teamMap[finalMatch.loser_team_id] : null;
    const third = tpMatch && tpMatch.winner_team_id ? teamMap[tpMatch.winner_team_id] : null;

    const items = [
        { place: "Juara 1", team: champion, cls: "gold" },
        { place: "Juara 2", team: runnerUp, cls: "silver" },
        { place: "Juara 3", team: third, cls: "bronze" }
    ];

    for (const item of items) {
        const div = document.createElement("div");
        div.className = "podium-item podium-" + item.cls;

        const label = document.createElement("div");
        label.className = "podium-label";
        label.textContent = item.place;

        const name = document.createElement("div");
        name.className = "podium-team";
        if (item.team) {
            name.textContent = item.team.name;
        } else {
            name.textContent = "Belum Ditentukan";
            name.style.opacity = "0.5";
        }

        div.appendChild(label);
        div.appendChild(name);
        podium.appendChild(div);
    }

    return podium;
}

function getPlaceholderText(match, side, matchMap) {
    const sourceId = side === "team1" ? match.source_team1_match_id : match.source_team2_match_id;
    const result = side === "team1" ? match.source_team1_result : match.source_team2_result;

    if (!sourceId) return "---";

    const prefix = result === "winner" ? "Pemenang " : result === "loser" ? "Kalah " : "";

    const sourceMatch = Object.values(matchMap).find(m => m.id === sourceId);
    const sourceCode = sourceMatch ? sourceMatch.match_code : "";

    return prefix + "Pertandingan " + sourceCode;
}
