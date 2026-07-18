import { statusLabel, statusBadgeClass, stageLabel } from "./utils.js";

export function renderBracket(area, teams, matches) {
  const teamMap = {};
  for (const t of teams) teamMap[t.id] = t;

  const matchMap = {};
  for (const m of matches) matchMap[m.match_code] = m;

  const container = document.createElement("div");
  container.className = "bracket-svg-container";

  const bracketEl = document.createElement("div");
  bracketEl.className = "bracket";

  bracketEl.appendChild(buildRound("PEREMPAT FINAL", ["QF1", "QF2", "QF3", "QF4"], matchMap, teamMap));
  bracketEl.appendChild(buildRound("SEMIFINAL", ["SF1", "SF2"], matchMap, teamMap));
  bracketEl.appendChild(buildRound("FINAL & JUARA 3", ["F", "TP"], matchMap, teamMap));
  bracketEl.appendChild(buildPodium(matchMap, teamMap));

  container.appendChild(bracketEl);

  requestAnimationFrame(() => {
    if (container.isConnected) {
      drawConnectors(container);
    }
  });

  return container;
}

function buildRound(title, codes, matchMap, teamMap) {
  const col = document.createElement("div");
  col.className = "bracket-round";
  col.dataset.round = title;

  const header = document.createElement("div");
  header.className = "bracket-round-header";
  header.textContent = title;
  col.appendChild(header);

  for (const code of codes) {
    const m = matchMap[code];
    if (m) col.appendChild(createMatchCard(m, matchMap, teamMap));
  }

  return col;
}

function buildPodium(matchMap, teamMap) {
  const col = document.createElement("div");
  col.className = "bracket-round round-podium";

  const header = document.createElement("div");
  header.className = "bracket-round-header";
  header.textContent = "PODIUM";
  col.appendChild(header);

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
    name.textContent = item.team ? item.team.name : "Belum Ditentukan";
    if (!item.team) name.style.opacity = "0.5";

    div.appendChild(label);
    div.appendChild(name);
    col.appendChild(div);
  }

  return col;
}

function createMatchCard(match, matchMap, teamMap) {
  const wrapper = document.createElement("div");
  wrapper.className = "match-wrapper";
  wrapper.dataset.matchId = match.id;
  wrapper.dataset.matchCode = match.match_code;

  const card = document.createElement("div");
  card.className = "match-card";

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
  if (match.winner_team_id && match.team1_id === match.winner_team_id) t1Row.classList.add("team-winner");
  if (match.loser_team_id && match.team1_id === match.loser_team_id) t1Row.classList.add("team-loser");

  const t1Name = document.createElement("span");
  t1Name.className = "team-name";
  if (t1) {
    if (match.winner_team_id === t1.id) {
      const check = document.createElement("span");
      check.className = "check-icon";
      check.textContent = "\u2713 ";
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
  if (match.winner_team_id && match.team2_id === match.winner_team_id) t2Row.classList.add("team-winner");
  if (match.loser_team_id && match.team2_id === match.loser_team_id) t2Row.classList.add("team-loser");

  const t2Name = document.createElement("span");
  t2Name.className = "team-name";
  if (t2) {
    if (match.winner_team_id === t2.id) {
      const check = document.createElement("span");
      check.className = "check-icon";
      check.textContent = "\u2713 ";
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

  wrapper.appendChild(card);
  return wrapper;
}

function getPlaceholderText(match, side, matchMap) {
  const sourceId = side === "team1" ? match.source_team1_match_id : match.source_team2_match_id;
  const result = side === "team1" ? match.source_team1_result : match.source_team2_result;
  if (!sourceId) return "---";
  const prefix = result === "winner" ? "Pemenang " : result === "loser" ? "Kalah " : "";
  const sourceMatch = Object.values(matchMap).find(m => m.id === sourceId);
  return prefix + "Pertandingan " + (sourceMatch ? sourceMatch.match_code : "???");
}

function drawConnectors(container) {
  const oldSvg = container.querySelector(".bracket-svg-connectors");
  if (oldSvg) oldSvg.remove();

  const bracket = container.querySelector(".bracket");
  if (!bracket) return;

  const rounds = bracket.querySelectorAll(".bracket-round");
  if (rounds.length < 3) return;

  const BRect = bracket.getBoundingClientRect();

  function getRightCenter(el) {
    const r = el.getBoundingClientRect();
    return { x: r.right - BRect.left, y: r.top - BRect.top + r.height / 2 };
  }

  function getLeftCenter(el) {
    const r = el.getBoundingClientRect();
    return { x: r.left - BRect.left, y: r.top - BRect.top + r.height / 2 };
  }

  const wrapperMap = {};
  const allWrappers = bracket.querySelectorAll(".match-wrapper");
  for (const w of allWrappers) {
    wrapperMap[w.dataset.matchCode] = w;
  }

  const connections = [];

  function addConn(fromCode, toCode, result) {
    const from = wrapperMap[fromCode];
    const to = wrapperMap[toCode];
    if (from && to) {
      connections.push({ from, to, result });
    }
  }

  addConn("QF1", "SF1", "winner");
  addConn("QF2", "SF1", "winner");
  addConn("QF3", "SF2", "winner");
  addConn("QF4", "SF2", "winner");
  addConn("SF1", "F", "winner");
  addConn("SF2", "F", "winner");
  addConn("SF1", "TP", "loser");
  addConn("SF2", "TP", "loser");

  if (connections.length === 0) return;

  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  svg.setAttribute("class", "bracket-svg-connectors");
  svg.style.position = "absolute";
  svg.style.top = "0";
  svg.style.left = "0";
  svg.style.width = "100%";
  svg.style.height = "100%";
  svg.style.pointerEvents = "none";
  svg.style.overflow = "visible";

  for (const conn of connections) {
    const fromCol = conn.from.closest(".bracket-round");
    const toCol = conn.to.closest(".bracket-round");
    if (!fromCol || !toCol) continue;

    const fromRight = fromCol.offsetLeft + fromCol.offsetWidth;
    const toLeft = toCol.offsetLeft;
    const midX = (fromRight + toLeft) / 2;

    const from = getRightCenter(conn.from);
    const to = getLeftCenter(conn.to);

    const color = conn.result === "winner"
      ? "rgba(46,204,113,0.2)"
      : "rgba(255,255,255,0.1)";
    const width = conn.result === "winner" ? "2" : "1.5";

    const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
    const d = `M ${from.x} ${from.y} L ${midX} ${from.y} L ${midX} ${to.y} L ${to.x} ${to.y}`;
    path.setAttribute("d", d);
    path.setAttribute("stroke", color);
    path.setAttribute("stroke-width", width);
    path.setAttribute("fill", "none");
    if (conn.result === "loser") {
      path.setAttribute("stroke-dasharray", "4,3");
    }
    svg.appendChild(path);
  }

  container.insertBefore(svg, bracket);
}
