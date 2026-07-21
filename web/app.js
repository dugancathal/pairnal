// Client-side board state. The server is stateless -- everyone's grouping
// lives only here, in the browser, until "Suggest" or "Save" ask the server
// to do something with it.
let displayNames = {};
let staleness = {};
let streams = []; // [{ name, members: [id...], groups: [[id...], ...] }]
const suggestCycle = {}; // stream name -> which of the top-3 suggestions we're on

const boardsEl = document.getElementById("boards");
const boardTpl = document.getElementById("board-template");
const chipTpl = document.getElementById("chip-template");
const groupTpl = document.getElementById("group-template");

async function loadState() {
  try {
    const res = await fetch("/api/state");
    const data = await res.json();
    displayNames = data.displayNames;
    staleness = data.staleness;
    // Groups start pre-filled with whoever was grouped together last
    // session, so pairs stay put unless you deliberately drag them apart.
    streams = data.streams.map((s) => ({name: s.name, members: s.members, groups: s.groups || []}));
    document.getElementById("today").textContent = data.today;
    render();
  } catch (err) {
    boardsEl.innerHTML = "<p class=\"loading\">Couldn't reach the Pairnal server.</p>";
  }
}

function displayName(id) {
  return displayNames[id] || id;
}

function render() {
  boardsEl.innerHTML = "";

  streams.forEach((stream) => {
    const node = boardTpl.content.cloneNode(true);
    node.querySelector(".board-name").textContent = stream.name || "Everyone";

    const placed = new Set(stream.groups.flat());
    const pool = node.querySelector(".pool");
    stream.members
      .filter((person) => !placed.has(person))
      .forEach((person) => pool.appendChild(makeChip(person, stream.name)));
    wireDropTarget(pool, null);

    const groupsEl = node.querySelector(".groups");
    stream.groups.forEach((members, index) => {
      groupsEl.appendChild(makeGroup(stream, index, members));
    });

    node.querySelector(".btn-suggest").addEventListener("click", () => suggest(stream.name));
    node.querySelector(".btn-add-group").addEventListener("click", () => {
      stream.groups.push([]);
      render();
    });

    boardsEl.appendChild(node);
  });
}

function makeChip(person, streamName) {
  const chip = chipTpl.content.firstElementChild.cloneNode(true);
  chip.textContent = displayName(person);
  chip.addEventListener("dragstart", (e) => {
    e.dataTransfer.setData("text/plain", JSON.stringify({person, stream: streamName}));
    e.dataTransfer.effectAllowed = "move";
    chip.classList.add("dragging");
  });
  chip.addEventListener("dragend", () => chip.classList.remove("dragging"));
  return chip;
}

function makeGroup(stream, index, members) {
  const node = groupTpl.content.cloneNode(true);
  const group = node.querySelector(".group");
  group.classList.toggle("is-empty", members.length === 0);

  const peopleEl = node.querySelector(".group-people");
  members.forEach((person) => peopleEl.appendChild(makeChip(person, stream.name)));

  setCaption(node.querySelector(".group-caption"), members);

  node.querySelector(".group-remove").addEventListener("click", () => {
    stream.groups.splice(index, 1);
    render();
  });

  wireDropTarget(group, index);
  return group;
}

function setCaption(el, members) {
  el.textContent = "";
  el.className = "group-caption";

  if (members.length === 1) {
    el.textContent = "needs a partner";
    return;
  }
  if (members.length >= 3) {
    el.textContent = "mob";
    return;
  }
  if (members.length !== 2) return;

  const info = staleness[[...members].sort().join("|")];
  if (!info) return;

  if (!info.everPaired) {
    el.textContent = "never paired";
    el.classList.add("never-paired");
    return;
  }

  el.textContent = `${info.days}d since together${info.overPaired ? " (!)" : ""}`;
  if (info.overPaired) el.classList.add("over-paired");
}

// `targetGroupIndex` is null for the "available" pool, otherwise the index
// of the group being dropped into.
function wireDropTarget(el, targetGroupIndex) {
  el.addEventListener("dragover", (e) => {
    e.preventDefault();
    el.classList.add("drag-over");
  });
  el.addEventListener("dragleave", () => el.classList.remove("drag-over"));
  el.addEventListener("drop", (e) => {
    e.preventDefault();
    el.classList.remove("drag-over");
    const {person, stream: streamName} = JSON.parse(e.dataTransfer.getData("text/plain"));
    movePerson(streamName, person, targetGroupIndex);
  });
}

function movePerson(streamName, person, targetGroupIndex) {
  const stream = streams.find((s) => s.name === streamName);
  if (!stream) return;

  stream.groups.forEach((group) => {
    const i = group.indexOf(person);
    if (i !== -1) group.splice(i, 1);
  });
  if (targetGroupIndex !== null) stream.groups[targetGroupIndex].push(person);

  render();
}

// Each click cycles through the top-3 suggestions for that stream, so
// "Suggest" doubles as a "try another" button.
async function suggest(streamName) {
  const stream = streams.find((s) => s.name === streamName);
  if (!stream) return;

  let data;
  try {
    const res = await fetch("/api/suggest", {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({stream: streamName, groups: stream.groups})
    });
    data = await res.json();
  } catch (err) {
    showToast("Couldn't reach the server", "error");
    return;
  }

  if (data.error) return showToast(data.error, "error");
  if (!data.options || data.options.length === 0) return showToast("No valid arrangement found", "error");

  const cycle = suggestCycle[streamName] ?? 0;
  stream.groups = data.options[cycle % data.options.length].groups;
  suggestCycle[streamName] = cycle + 1;
  render();
}

async function saveAll() {
  const groups = streams.flatMap((s) => s.groups.filter((g) => g.length > 0));
  if (groups.length === 0) return showToast("Nothing to save yet", "error");

  let data;
  try {
    const res = await fetch("/api/save", {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({groups})
    });
    data = await res.json();
  } catch (err) {
    showToast("Couldn't reach the server", "error");
    return;
  }

  if (data.error) return showToast(data.error, "error");

  showToast("Saved today's pairings", "success");
  streams.forEach((s) => (s.groups = []));
  Object.keys(suggestCycle).forEach((k) => delete suggestCycle[k]);
  render();
}

let toastTimer = null;
function showToast(message, kind = "info") {
  const el = document.getElementById("toast");
  el.textContent = message;
  el.className = `toast visible ${kind === "info" ? "" : kind}`.trim();
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => el.classList.remove("visible"), 2600);
}

document.getElementById("save-btn").addEventListener("click", saveAll);
loadState();
