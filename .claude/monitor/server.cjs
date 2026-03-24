#!/usr/bin/env node
/**
 * Agent Monitor - Real-time dashboard for X Company
 * Shows core roles and subagents activity
 */

const http = require("http");
const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");
const WebSocket = require("./vendor/ws");

// Generate stable port per project (range 3800-3999)
function getProjectPort() {
  const projectName = path.basename(path.join(__dirname, "../.."));
  const hash = require("crypto").createHash("md5").update(projectName).digest("hex");
  return 3800 + (parseInt(hash.substring(0, 4), 16) % 200);
}
const PORT = process.env.PORT || getProjectPort();
const STATE_FILE = path.join(__dirname, "state/activity.json");
const UI_DIR = path.join(__dirname, "ui");
const PROJECT_DIR = path.join(__dirname, "../..");
const ACTIVE_CORE_FILE = path.join(__dirname, "../.active-core");

// Map core file to role name
const CORE_FILE_TO_ROLE = {
  "ceo.md": "CEO",
  "cto.md": "CTO",
  "pm.md": "PM",
  "ba.md": "BA",
  "hr.md": "HR",
};

// Track connected SSE clients
const clients = new Set();

// Read state file with auto-cleanup of stale sessions
function readState() {
  try {
    const state = JSON.parse(fs.readFileSync(STATE_FILE, "utf8"));

    return state;
  } catch {
    return {
      session_start: null,
      core_roles: {},
      subagents: [],
      history: [],
    };
  }
}

// Read project data (tasks, progress)
function readProject() {
  try {
    const projectPath = PROJECT_DIR;
    if (!fs.existsSync(projectPath)) return null;

    // Derive project ID from directory name
    let projectId = path.basename(projectPath);

    // Parse sprint files
    const sprintsPath = path.join(projectPath, ".project", "sprints");
    const tasks = [];
    let totalTasks = 0,
      completedTasks = 0,
      inProgressTasks = 0;
    let currentSprint = null;
    let lastSprintNum = 0;

    if (fs.existsSync(sprintsPath)) {
      const files = fs
        .readdirSync(sprintsPath)
        .filter((f) => f.match(/sprint-\d+\.md/))
        .sort();

      for (const file of files) {
        const content = fs.readFileSync(path.join(sprintsPath, file), "utf8");
        const sprintMatch = content.match(/Sprint.*?(\d+)/);
        const sprintNum = sprintMatch ? parseInt(sprintMatch[1]) : 0;
        if (sprintNum > lastSprintNum) lastSprintNum = sprintNum;
        // Determine sprint status: check header first, then infer from task completion
        const sprintStatusMatch = content.match(
          /^\*\*Status\*\*:\s*\[?x?\]?\s*(.+)/im,
        );
        let sprintStatus = sprintStatusMatch
          ? sprintStatusMatch[1].trim().toUpperCase()
          : "UNKNOWN";

        // If header says PLANNED but all tasks are COMPLETE, treat as COMPLETE
        const allTaskLines =
          content.match(/^\|\s*\d+\.[0-9A-Za-z]+\s*\|/gm) || [];
        const completeTaskLines =
          content.match(/^\|\s*\d+\.[0-9A-Za-z]+\s*\|.*\[COMPLETE\]/gm) || [];
        if (
          allTaskLines.length > 0 &&
          allTaskLines.length === completeTaskLines.length
        ) {
          sprintStatus = "COMPLETE";
        }

        // Find current sprint (first non-complete sprint)
        if (!currentSprint && sprintStatus !== "COMPLETE") {
          currentSprint = sprintNum;
        }

        // Parse tasks by splitting into sections (support letter suffixes: S, R, Q, F)
        const taskSections = content.split(
          /(?=###\s*Task\s+\d+\.[0-9A-Za-z]+)/,
        );
        for (const section of taskSections) {
          const headerMatch = section.match(
            /###\s*Task\s+(\d+\.[0-9A-Za-z]+):\s*(.+?)\s*\[([^\]]+)\]/,
          );
          if (!headerMatch) continue;

          const [, id, name, type] = headerMatch;
          // Match status like **Status**: [COMPLETE] or **Status**: [NOT STARTED]
          const stMatch = section.match(/\*\*Status\*\*:\s*\[([^\]]*)\]/i);
          const status = stMatch
            ? stMatch[1].replace(/\s+/g, "_").toUpperCase()
            : "PENDING";

          totalTasks++;
          if (status === "COMPLETE") completedTasks++;
          else if (
            status === "IN_PROGRESS" ||
            status === "IN" ||
            status === "STARTED"
          )
            inProgressTasks++;

          tasks.push({
            id,
            name: name.trim(),
            type,
            status,
            sprint: sprintNum,
          });
        }
      }
    }

    // If all sprints complete, show last sprint
    if (!currentSprint && lastSprintNum > 0) currentSprint = lastSprintNum;

    // Filter tasks: show current sprint, or last sprint if all complete
    const sprintTasks = tasks.filter((t) => t.sprint === currentSprint);

    return {
      id: projectId,
      currentSprint,
      tasks:
        sprintTasks.length > 0 ? sprintTasks.slice(0, 10) : tasks.slice(-10),
      progress: {
        total: totalTasks,
        completed: completedTasks,
        inProgress: inProgressTasks,
        percent:
          totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0,
      },
    };
  } catch (e) {
    console.error("Error reading project:", e);
    return null;
  }
}

// Read and sync .active-core to activity.json sessions
function syncActiveCoreToState() {
  try {
    if (!fs.existsSync(ACTIVE_CORE_FILE)) return false;

    const content = fs.readFileSync(ACTIVE_CORE_FILE, "utf8").trim();
    if (!content) return false;

    const state = readState();
    const now = new Date().toISOString();
    let changed = false;

    // Parse each line: "session_id:core_file.md:timestamp"
    const newSessions = {};
    for (const line of content.split("\n")) {
      const parts = line.split(":");
      if (parts.length < 2) continue;

      const sessionId = parts[0].trim();
      const coreFile = parts[1].trim();
      const timestamp = parts[2] ? parseInt(parts[2].trim(), 10) : null;

      const role = CORE_FILE_TO_ROLE[coreFile];
      if (!role) continue;

      newSessions[sessionId] = {
        role,
        timestamp,
        last_seen: now,
      };
    }

    // Check if sessions changed
    const oldSessionsStr = JSON.stringify(state.sessions || {});
    const newSessionsStr = JSON.stringify(newSessions);

    if (oldSessionsStr !== newSessionsStr) {
      // Add history entries for role switches
      for (const [sessionId, session] of Object.entries(newSessions)) {
        const oldSession = state.sessions?.[sessionId];
        if (!oldSession || oldSession.role !== session.role) {
          state.history = state.history || [];
          state.history.push({
            event: "core_role_switch",
            agent: session.role,
            session: sessionId,
            timestamp: now,
          });
          if (state.history.length > 15) {
            state.history = state.history.slice(-15);
          }
        }
      }

      state.sessions = newSessions;
      fs.writeFileSync(STATE_FILE, JSON.stringify(state, null, 2));
      changed = true;
    }

    return changed;
  } catch (e) {
    console.error("Error syncing active-core:", e);
    return false;
  }
}

// Watch state file and broadcast changes (use watchFile for reliable macOS support)
let lastState = JSON.stringify(readState());

fs.watchFile(STATE_FILE, { interval: 500 }, () => {
  const state = readState();
  const newStateStr = JSON.stringify(state);
  if (newStateStr !== lastState) {
    lastState = newStateStr;
    const fullState = { ...state, project: readProject() };
    broadcast(JSON.stringify(fullState));
  }
});

// Watch .active-core file for core role changes
fs.watchFile(ACTIVE_CORE_FILE, { interval: 500 }, () => {
  if (syncActiveCoreToState()) {
    const state = readState();
    const fullState = { ...state, project: readProject() };
    broadcast(JSON.stringify(fullState));
  }
});

function broadcast(data) {
  for (const client of clients) {
    client.write(`data: ${data}\n\n`);
  }
}

// HTTP Server
const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);

  // SSE endpoint for real-time updates
  if (url.pathname === "/events") {
    res.writeHead(200, {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache",
      Connection: "keep-alive",
      "Access-Control-Allow-Origin": "*",
    });

    // Send current state + project immediately
    const fullState = { ...readState(), project: readProject() };
    res.write(`data: ${JSON.stringify(fullState)}\n\n`);
    clients.add(res);

    req.on("close", () => clients.delete(res));
    return;
  }

  // API endpoint for current state
  if (url.pathname === "/api/state") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(readState()));
    return;
  }

  // API endpoint for project data
  if (url.pathname === "/api/project") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(readProject()));
    return;
  }

  // Serve static files
  let filePath = url.pathname === "/" ? "/index.html" : url.pathname;
  filePath = path.join(UI_DIR, filePath);

  const ext = path.extname(filePath);
  const contentTypes = {
    ".html": "text/html",
    ".css": "text/css",
    ".js": "application/javascript",
    ".json": "application/json",
  };

  fs.readFile(filePath, (err, content) => {
    if (err) {
      res.writeHead(404);
      res.end("Not Found");
      return;
    }
    res.writeHead(200, { "Content-Type": contentTypes[ext] || "text/plain" });
    res.end(content);
  });
});

// WebSocket server for terminal
const PTY_BRIDGE = path.join(__dirname, "pty-bridge.py");
const wss = new WebSocket.Server({ server });

wss.on("connection", (ws) => {
  const proc = spawn("python3", [PTY_BRIDGE], {
    env: {
      ...process.env,
      TERM: "xterm-256color",
      COLUMNS: "80",
      LINES: "24",
      PTY_CWD: PROJECT_DIR,
    },
  });

  proc.stdout.on("data", (data) => {
    if (ws.readyState === WebSocket.OPEN) ws.send(data.toString("utf-8"));  // Text frame, valid UTF-8
  });

  proc.stderr.on("data", (data) => {
    console.error("pty-bridge stderr:", data.toString());
  });

  proc.on("exit", () => {
    if (ws.readyState === WebSocket.OPEN) ws.close();
  });

  proc.on("error", (err) => {
    console.error("Failed to spawn terminal:", err.message);
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(`\r\n\x1b[31mError: ${err.message}\x1b[0m\r\n`);
    }
  });

  ws.on("message", (msg) => {
    if (proc.stdin.writable) proc.stdin.write(msg);
  });

  ws.on("close", () => {
    proc.kill();
  });
});

server.listen(PORT, () => {
  console.log(`
  ╔═══════════════════════════════════════════╗
  ║     AGENT MONITOR                         ║
  ║     http://localhost:${PORT}              ║
  ║     Terminal: WebSocket on same port      ║
  ╚═══════════════════════════════════════════╝
  `);
});
