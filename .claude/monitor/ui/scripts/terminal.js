/**
 * Terminal integration using xterm.js + WebSocket → node-pty
 */
(function () {
  const container = document.getElementById("terminal-container");
  const toggleBtn = document.getElementById("terminal-toggle");
  const body = document.getElementById("terminal-body");
  let term = null;
  let ws = null;
  let fitAddon = null;
  let collapsed = false;

  function initTerminal() {
    term = new Terminal({
      fontFamily: "'JetBrainsMono NF', 'JetBrains Mono', 'MesloLGS NF', 'Hack Nerd Font', Menlo, monospace",
      fontSize: 13,
      lineHeight: 1.4,
      cursorBlink: true,
      cursorStyle: "bar",
      theme: {
        background: "#0f172a",
        foreground: "#e2e8f0",
        cursor: "#3b82f6",
        selectionBackground: "rgba(59, 130, 246, 0.3)",
        black: "#1e293b",
        red: "#ef4444",
        green: "#22c55e",
        yellow: "#eab308",
        blue: "#3b82f6",
        magenta: "#a855f7",
        cyan: "#06b6d4",
        white: "#f1f5f9",
        brightBlack: "#475569",
        brightRed: "#f87171",
        brightGreen: "#4ade80",
        brightYellow: "#facc15",
        brightBlue: "#60a5fa",
        brightMagenta: "#c084fc",
        brightCyan: "#22d3ee",
        brightWhite: "#f8fafc",
      },
      allowProposedApi: true,
    });

    fitAddon = new FitAddon.FitAddon();
    const webLinksAddon = new WebLinksAddon.WebLinksAddon();
    term.loadAddon(fitAddon);
    term.loadAddon(webLinksAddon);
    term.open(container);
    fitAddon.fit();

    connectWebSocket();

    // Handle resize
    const resizeObserver = new ResizeObserver(() => {
      if (fitAddon && !collapsed) {
        fitAddon.fit();
      }
    });
    resizeObserver.observe(container);

    term.onResize(({ cols, rows }) => {
      if (ws && ws.readyState === WebSocket.OPEN) {
        // Send resize signal: \x01cols,rows
        ws.send("\x01" + cols + "," + rows);
      }
    });
  }

  function connectWebSocket() {
    const protocol = location.protocol === "https:" ? "wss:" : "ws:";
    ws = new WebSocket(`${protocol}//${location.host}`);

    ws.onopen = () => {
      // Delay fit to ensure container is fully rendered
      setTimeout(() => {
        if (fitAddon) {
          fitAddon.fit();
          const dims = fitAddon.proposeDimensions();
          if (dims) {
            ws.send("\x01" + dims.cols + "," + dims.rows);
          }
        }
      }, 150);
    };

    ws.onmessage = (e) => {
      term.write(e.data);
    };

    ws.onclose = () => {
      term.write("\r\n\x1b[90m[Disconnected — reconnecting...]\x1b[0m\r\n");
      setTimeout(connectWebSocket, 2000);
    };

    // Terminal input → WebSocket → pty
    term.onData((data) => {
      if (ws && ws.readyState === WebSocket.OPEN) {
        ws.send(data);
      }
    });
  }

  // Toggle terminal visibility
  if (toggleBtn) {
    toggleBtn.addEventListener("click", () => {
      collapsed = !collapsed;
      body.style.display = collapsed ? "none" : "block";
      toggleBtn.textContent = collapsed ? "▲" : "▼";
      if (!collapsed && fitAddon) {
        setTimeout(() => fitAddon.fit(), 50);
      }
    });
  }

  // Init when DOM is ready
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initTerminal);
  } else {
    // xterm.js loads via CDN script tag — wait a tick for it
    setTimeout(initTerminal, 100);
  }
})();
