#!/usr/bin/env python3
"""
VFM Agent Company — license gate (single secret activation token).

ONE secret token (8 UPPERCASE letters, A–Z) unlocks the plugin. Only the
maintainer knows it. The repo commits ONLY a slow scrypt hash of the token
(`license.hash`) — never the token itself — so this public repo does not
reveal it.

Commands
--------
  set [TOKEN]        (maintainer) hash TOKEN and write license.hash. Commit
                     that file — it does NOT reveal the token. Prompts if
                     TOKEN is omitted.
  verify TOKEN       exit 0 if TOKEN matches the stored hash, else 1.
  check              read the token from $VFM_INSTALL_TOKEN or the activation
                     file and verify it; exit 0 if this machine is activated,
                     else 1. Used by the UserPromptSubmit hook.
  activate [TOKEN]   verify TOKEN, then save it to ~/.vfm-agent-company/license
                     (chmod 600) so future sessions stay unlocked.

Note on strength: an 8-letter token is only ~37.6 bits of entropy, so the
committed hash is, in theory, brute-forceable offline. scrypt (memory-hard)
makes each guess expensive, but treat this as a friction gate, not DRM.
"""
import argparse
import hashlib
import hmac
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
HASH_FILE = os.path.join(SCRIPT_DIR, "license.hash")
LICENSE_FILE = os.path.expanduser("~/.vfm-agent-company/license")

ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
TOKEN_LEN = 8
SCRYPT_N, SCRYPT_R, SCRYPT_P = 1 << 14, 8, 1  # ~16 MB, tens of ms per guess
MAXMEM = 64 * 1024 * 1024


def _normalize(token) -> str:
    return "".join((token or "").split()).upper()


def _well_formed(token: str) -> bool:
    return len(token) == TOKEN_LEN and all(c in ALPHABET for c in token)


def _scrypt(token: str, salt: bytes, n: int, r: int, p: int, dklen: int) -> bytes:
    return hashlib.scrypt(token.encode("ascii"), salt=salt, n=n, r=r, p=p,
                          maxmem=MAXMEM, dklen=dklen)


def _read_prompt(label: str) -> str:
    if not sys.stdin.isatty():
        return ""
    try:
        import getpass
        return getpass.getpass(label)
    except Exception:
        return ""


# --- maintainer: store the hash ---------------------------------------------
def cmd_set(token) -> int:
    token = _normalize(token if token is not None else _read_prompt("Choose install token (8 letters A–Z): "))
    if not _well_formed(token):
        print("✗ Token must be exactly 8 letters A–Z.", file=sys.stderr)
        return 1
    salt = os.urandom(16)
    digest = _scrypt(token, salt, SCRYPT_N, SCRYPT_R, SCRYPT_P, 32)
    with open(HASH_FILE, "w") as fh:
        fh.write("scrypt$%d$%d$%d$%s$%s\n" % (SCRYPT_N, SCRYPT_R, SCRYPT_P, salt.hex(), digest.hex()))
    print("✓ Wrote %s" % HASH_FILE)
    print("  Commit it — it does NOT reveal the token. Unlock a machine with:")
    print("      export VFM_INSTALL_TOKEN=<your token>")
    return 0


# --- verify a token against the committed hash ------------------------------
def _load_hash():
    if not os.path.exists(HASH_FILE):
        return None
    try:
        algo, n, r, p, salt_hex, hash_hex = open(HASH_FILE).read().strip().split("$")
        if algo != "scrypt":
            return None
        return int(n), int(r), int(p), bytes.fromhex(salt_hex), bytes.fromhex(hash_hex)
    except Exception:
        return None


def is_valid(token) -> bool:
    token = _normalize(token)
    rec = _load_hash()
    if rec is None or not _well_formed(token):
        return False
    n, r, p, salt, expected = rec
    try:
        got = _scrypt(token, salt, n, r, p, len(expected))
    except Exception:
        return False
    return hmac.compare_digest(got, expected)


def cmd_verify(token) -> int:
    if is_valid(token):
        print("VALID")
        return 0
    print("INVALID")
    return 1


# --- runtime: is THIS machine activated? ------------------------------------
def _machine_token():
    tok = os.environ.get("VFM_INSTALL_TOKEN")
    if tok:
        return tok
    if os.path.exists(LICENSE_FILE):
        try:
            return open(LICENSE_FILE).read().strip()
        except Exception:
            return None
    return None


def cmd_check() -> int:
    return 0 if is_valid(_machine_token() or "") else 1


def cmd_activate(token) -> int:
    token = token if token is not None else _read_prompt("Enter install token: ")
    if not is_valid(token):
        print("✗ Invalid token — not activated.", file=sys.stderr)
        return 1
    os.makedirs(os.path.dirname(LICENSE_FILE), exist_ok=True)
    with open(LICENSE_FILE, "w") as fh:
        fh.write(_normalize(token) + "\n")
    os.chmod(LICENSE_FILE, 0o600)
    print("✓ Activated. VFM Agent Company is unlocked on this machine.")
    return 0


def main(argv=None) -> int:
    p = argparse.ArgumentParser(prog="license.py", description="VFM Agent Company license gate.")
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("set", help="(maintainer) store the hash of a token")
    s.add_argument("token", nargs="?")
    v = sub.add_parser("verify", help="verify a token against license.hash")
    v.add_argument("token")
    sub.add_parser("check", help="is this machine activated? exit 0/1")
    a = sub.add_parser("activate", help="save a valid token to this machine")
    a.add_argument("token", nargs="?")
    args = p.parse_args(argv)

    if args.cmd == "set":
        return cmd_set(args.token)
    if args.cmd == "verify":
        return cmd_verify(args.token)
    if args.cmd == "check":
        return cmd_check()
    if args.cmd == "activate":
        return cmd_activate(args.token)
    return 2


if __name__ == "__main__":
    sys.exit(main())
