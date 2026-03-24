import { formatTime, formatName, getInitials, getColorClass } from "./utils.js";

const defaultSubagents = [
  "general-purpose",
  "Explore",
  "Plan",
  "statusline-setup",
  "claude-code-guide",
];

/**
 * Update the UI with new state
 */
function update(state) {
  updateCoreTeam(state);
  updateSpecialists(state);
  updateStats(state);
  updateTimeline(state);
  updateProgress(state);
  updateTasks(state);
}

/**
 * Update Core Team section
 * Each session = 1 active core role
 * Multiple sessions can show multiple active roles
 */
function updateCoreTeam(state) {
  const counts = { CEO: 0, CTO: 0, PM: 0, BA: 0, HR: 0 };
  const sessions = Object.values(state.sessions || {});

  sessions.forEach((s) => {
    if (s.role in counts) counts[s.role]++;
  });

  const hasActive = sessions.length > 0;

  document.querySelectorAll(".member").forEach((el) => {
    const role = el.dataset.role;
    const cnt = counts[role] || 0;

    el.classList.remove("active", "inactive");

    if (cnt > 0) {
      el.classList.add("active");
      el.querySelector(".member-count").textContent =
        cnt > 1 ? cnt + " active" : "active";
      el.querySelector(".member-count").style.visibility = "visible";
    } else {
      if (hasActive) el.classList.add("inactive");
      el.querySelector(".member-count").textContent = "";
      el.querySelector(".member-count").style.visibility = "hidden";
    }
  });
}

/**
 * Update Specialists section
 */
function updateSpecialists(state) {
  const running = (state.subagents || []).filter((a) => a.status === "running");
  const list = document.getElementById("agents-list");

  if (running.length === 0) {
    list.innerHTML = '<div class="empty-state">No agents running</div>';
    return;
  }

  list.innerHTML = running
    .reverse()
    .map((a) => {
      const humanName = a.name || formatName(a.type);
      const agentType = a.type || "unknown";
      const initials = getInitials(humanName);
      const colorClass = getColorClass(a.type);

      if (defaultSubagents.includes(a.type)) {
        return "";
      }

      return `
      <div class="agent-item">
        <div class="agent-icon ${colorClass}">${initials}</div>
        <div class="agent-info">
          <div class="agent-name">${humanName} <span class="agent-type">(${agentType})</span></div>
          <div class="agent-desc">Started ${formatTime(a.started_at)}</div>
        </div>
        <div class="agent-badge">running</div>
      </div>`;
    })
    .join("");
}

/**
 * Update Stats section
 */
function updateStats(state) {
  const sessions = Object.values(state.sessions || {});
  const running = (state.subagents || []).filter((a) => a.status === "running");

  document.getElementById("stat-sessions").textContent = sessions.length;
  document.getElementById("stat-agents").textContent = running.length;
}

/**
 * Update Timeline section
 */
function updateTimeline(state) {
  const history = state.history || [];
  const tl = document.getElementById("timeline");
  if (!tl) return;

  if (history.length === 0) {
    tl.innerHTML = '<div class="empty-state">Waiting for activity...</div>';
    return;
  }

  tl.innerHTML = history
    .slice()
    .reverse()
    .slice(0, 20)
    .map((e) => {
      const isStart = e.event.includes("start") || e.event.includes("switch");
      console.log(e);
      return `
      <div class="timeline-item ${isStart ? "" : "done"}">
        <div class="timeline-dot ${isStart ? "" : "stop"}"></div>
        <span class="timeline-agent">${e.agentName || e.agent}</span>
        <span class="timeline-time">${formatTime(e.timestamp)}</span>
      </div>`;
    })
    .join("");
}

/**
 * Update Progress section
 */
function updateProgress(state) {
  const project = state.project;

  if (!project) {
    const projEl = document.getElementById("progress-project");
    if (projEl) projEl.textContent = "No active project";
    document.getElementById("progress-sprint").textContent = "-";
    document.getElementById("progress-bar").style.width = "0%";
    document.getElementById("stat-complete").textContent = "0";
    document.getElementById("stat-in-progress").textContent = "0";
    document.getElementById("stat-pending").textContent = "0";
    return;
  }

  document.getElementById("progress-sprint").textContent = project.currentSprint
    ? `Sprint ${project.currentSprint}`
    : "Sprint 0";
  document.getElementById("progress-bar").style.width =
    `${project.progress.percent}%`;
  document.getElementById("stat-complete").textContent =
    project.progress.completed;
  document.getElementById("stat-in-progress").textContent =
    project.progress.inProgress;
  document.getElementById("stat-pending").textContent =
    project.progress.total -
    project.progress.completed -
    project.progress.inProgress;
}

/**
 * Update Tasks section
 */
function updateTasks(state) {
  const project = state.project;
  const list = document.getElementById("tasks-list");

  if (!project || !project.tasks || project.tasks.length === 0) {
    list.innerHTML = '<div class="empty-state">No tasks</div>';
    return;
  }

  list.innerHTML = project.tasks
    .map((t) => {
      const statusClass = t.status.toLowerCase().replace("_", "-");
      const typeClass = getTaskTypeClass(t.type);
      if (defaultSubagents.includes(t.type)) {
        return "";
      }
      return `
      <div class="task-item ${statusClass}">
        <div class="task-id">${t.id}</div>
        <div class="task-name"><div class="task-name-inner">${t.name}</div></div>
        <div class="task-type ${typeClass}">${t.type}</div>
        <div class="task-status ${t.status.toLowerCase()}">${formatStatus(t.status)}</div>
      </div>`;
    })
    .join("");
}

function getTaskTypeClass(type) {
  const t = type.toLowerCase();
  if (t.includes("front") || t.includes("ui")) return "frontend";
  if (t.includes("back") || t.includes("api")) return "backend";
  if (t.includes("devops") || t.includes("deploy")) return "devops";
  if (t.includes("qa") || t.includes("test")) return "qa";
  if (t.includes("design") || t.includes("ux")) return "design";
  return "";
}

function formatStatus(status) {
  if (status === "COMPLETE") return "Done";
  if (status === "IN_PROGRESS") return "In Progress";
  return "Pending";
}

/**
 * Initialize SSE connection with auto-reconnect
 */
let sse = null;
let reconnectAttempts = 0;
let lastEventTime = Date.now();

function initSSE() {
  const dot = document.getElementById("status-dot");
  const txt = document.getElementById("status-text");

  if (sse) {
    sse.close();
  }

  sse = new EventSource("/events");

  sse.onopen = () => {
    dot.classList.add("live");
    txt.textContent = "Live";
    reconnectAttempts = 0;
    lastEventTime = Date.now();
  };

  sse.onmessage = (e) => {
    lastEventTime = Date.now();
    update(JSON.parse(e.data));
  };

  sse.onerror = () => {
    dot.classList.remove("live");
    sse.close();

    // Exponential backoff: 1s, 2s, 4s, max 10s
    const delay = Math.min(1000 * Math.pow(2, reconnectAttempts), 10000);
    reconnectAttempts++;
    txt.textContent = `Reconnecting in ${delay / 1000}s...`;

    setTimeout(initSSE, delay);
  };
}

// Heartbeat: check if connection is stale (no events for 30s on 4G can be normal)
setInterval(() => {
  const timeSinceLastEvent = Date.now() - lastEventTime;
  const dot = document.getElementById("status-dot");
  const txt = document.getElementById("status-text");

  // If no event for 60s and we think we're connected, reconnect
  if (
    timeSinceLastEvent > 60000 &&
    sse &&
    sse.readyState === EventSource.OPEN
  ) {
    dot.classList.remove("live");
    txt.textContent = "Stale, reconnecting...";
    sse.close();
    initSSE();
  }
}, 15000);

// Start the app
initSSE();
