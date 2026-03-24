#!/usr/bin/env python3
"""
PTY bridge: Creates a real pseudo-terminal and relays I/O via stdin/stdout.
Used by server.cjs to provide terminal functionality without native Node modules.
"""

import pty
import os
import sys
import select
import signal
import struct
import fcntl
import termios

def set_pty_size(fd, cols, rows):
    """Set the size of the PTY."""
    size = struct.pack("HHHH", rows, cols, 0, 0)
    fcntl.ioctl(fd, termios.TIOCSWINSZ, size)

def main():
    shell = os.environ.get("SHELL", "/bin/zsh")
    cwd = os.environ.get("PTY_CWD", os.getcwd())
    cols = int(os.environ.get("COLUMNS", "120"))
    rows = int(os.environ.get("LINES", "24"))

    # Create PTY pair
    master_fd, slave_fd = pty.openpty()
    set_pty_size(master_fd, cols, rows)

    pid = os.fork()
    if pid == 0:
        # Child: become session leader, set slave as controlling terminal
        os.close(master_fd)
        os.setsid()

        # Set slave as stdin/stdout/stderr
        os.dup2(slave_fd, 0)
        os.dup2(slave_fd, 1)
        os.dup2(slave_fd, 2)
        if slave_fd > 2:
            os.close(slave_fd)

        os.chdir(cwd)
        os.environ["TERM"] = "xterm-256color"
        os.execvp(shell, [shell, "-l"])
    else:
        # Parent: relay between stdin/stdout and master_fd
        os.close(slave_fd)

        # Make stdin non-blocking
        import fcntl
        flags = fcntl.fcntl(sys.stdin.fileno(), fcntl.F_GETFL)
        fcntl.fcntl(sys.stdin.fileno(), fcntl.F_SETFL, flags | os.O_NONBLOCK)

        # Make master non-blocking
        flags = fcntl.fcntl(master_fd, fcntl.F_GETFL)
        fcntl.fcntl(master_fd, fcntl.F_SETFL, flags | os.O_NONBLOCK)

        # Make stdout unbuffered
        stdout_fd = sys.stdout.fileno()

        try:
            while True:
                rlist, _, _ = select.select([sys.stdin.fileno(), master_fd], [], [], 0.05)

                for fd in rlist:
                    if fd == sys.stdin.fileno():
                        try:
                            data = os.read(fd, 4096)
                            if not data:
                                # stdin closed
                                os.kill(pid, signal.SIGHUP)
                                return

                            # Check for resize command: \x01cols,rows
                            if data[:1] == b'\x01':
                                try:
                                    parts = data[1:].decode().strip().split(",")
                                    c, r = int(parts[0]), int(parts[1])
                                    set_pty_size(master_fd, c, r)
                                    # Send SIGWINCH to child process group
                                    os.killpg(os.getpgid(pid), signal.SIGWINCH)
                                except (ValueError, IndexError, ProcessLookupError):
                                    pass
                                continue

                            os.write(master_fd, data)
                        except OSError:
                            pass

                    elif fd == master_fd:
                        try:
                            data = os.read(master_fd, 4096)
                            if not data:
                                return
                            os.write(stdout_fd, data)
                        except OSError:
                            pass

                # Check if child is still alive
                result = os.waitpid(pid, os.WNOHANG)
                if result[0] != 0:
                    # Drain remaining output
                    try:
                        while True:
                            data = os.read(master_fd, 4096)
                            if not data:
                                break
                            os.write(stdout_fd, data)
                    except OSError:
                        pass
                    return

        except KeyboardInterrupt:
            os.kill(pid, signal.SIGHUP)
        finally:
            os.close(master_fd)

if __name__ == "__main__":
    main()
