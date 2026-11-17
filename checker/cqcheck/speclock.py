"""The spec.lock check of every checker run (CLAUDE.md Pins: tools/spec_lock.py before any test run;
drift exits 1), in this process and stamped (cq-8m6v): no interpreter or git start on a warm run.

check() runs tools/spec_lock.py's own main() in this process unless a stamp says it already passed on
exactly the current state: spec.lock's content, the script's content, CQ_spec's HEAD (the HEAD file,
the ref file it names and packed-refs, by content and stat) and the stat (inode, size, mtime) of every
file the script hashes and of every entry of the directories it walks (spec_lock.FILES, DIRS). Any change to any
of these runs the full check again; only a pass is stamped, so a drift fails every run until it is
fixed. A git layout this does not read (no .git directory or gitdir file) is never stamped."""
from __future__ import annotations

import contextlib
import hashlib
import importlib.util
import io
import os
import sys
from pathlib import Path
from typing import Optional

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "tools" / "spec_lock.py"
_MOD = None


def _script():
    global _MOD
    if _MOD is None:
        sp = importlib.util.spec_from_file_location("cqcheck_spec_lock_tool", SCRIPT)
        m = importlib.util.module_from_spec(sp)
        sp.loader.exec_module(m)
        _MOD = m
    return _MOD


def _git_dir(spec: Path) -> Optional[Path]:
    g = spec / ".git"
    if g.is_dir():
        return g
    if g.is_file():
        t = g.read_text().strip()
        if t.startswith("gitdir:"):
            p = Path(t.split(":", 1)[1].strip())
            return p if p.is_absolute() else (spec / p).resolve()
    return None


def _stat(p: Path) -> str:
    try:
        st = p.stat()
    except OSError:
        return f"{p}\0-\n"
    return f"{p}\0{st.st_ino}\0{st.st_size}\0{st.st_mtime_ns}\n"


def _content(p: Path) -> bytes:
    try:
        return p.read_bytes()
    except OSError:
        return b"-"


def state_key(spec: Path) -> Optional[str]:
    g = _git_dir(spec)
    if g is None:
        return None
    h = hashlib.sha256()
    for p in (SCRIPT, ROOT / "spec.lock"):
        h.update(_content(p) + b"\0")
    head = _content(g / "HEAD")
    h.update(_stat(g / "HEAD").encode() + head + b"\0")
    common = g
    cd = g / "commondir"            # a linked worktree keeps its refs in the common dir
    if cd.is_file():
        common = (g / cd.read_text().strip()).resolve()
    if head.startswith(b"ref:"):
        ref = head[4:].strip().decode()
        for base in (g, common):
            h.update(_stat(base / ref).encode() + _content(base / ref) + b"\0")
    h.update(_stat(common / "packed-refs").encode())
    for f in _script().FILES:
        h.update(_stat(spec / f).encode())
    for d in _script().DIRS:
        _walk(spec / d, h)
    return h.hexdigest()


def _walk(d: Path, h) -> None:
    """The stat of every entry under d (directories too: an added or removed file changes its
    directory), in name order; os.scandir, not pathlib (a tenth of the time)."""
    h.update(_stat(d).encode())
    try:
        entries = sorted(os.scandir(d), key=lambda e: e.name)
    except OSError:
        return
    for e in entries:
        if e.is_dir(follow_symlinks=False):
            _walk(Path(e.path), h)
        else:
            try:
                st = e.stat()
                h.update(f"{e.path}\0{st.st_ino}\0{st.st_size}\0{st.st_mtime_ns}\n".encode())
            except OSError:
                h.update(f"{e.path}\0-\n".encode())


def _stamp_dir() -> Path:
    from cqcheck import run
    return run.tool_root() / "spec-lock"


def check() -> int:
    """tools/spec_lock.py's exit status (its output on stderr when it fails)."""
    spec = ROOT / "spec"
    try:
        key = state_key(spec)
    except OSError:
        key = None
    stamp = _stamp_dir() / key if key else None
    if stamp is not None and stamp.exists():
        return 0
    out, err = io.StringIO(), io.StringIO()
    try:
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            rc = _script().main([])
    except Exception as e:  # noqa: BLE001 - as the script's own crash: a failed check
        err.write(f"{type(e).__name__}: {e}\n")
        rc = 1
    if rc != 0:
        sys.stderr.write(out.getvalue() + err.getvalue())
        return rc
    if stamp is not None:
        stamp.parent.mkdir(parents=True, exist_ok=True)
        tmp = stamp.with_name(f"{stamp.name}.{os.getpid()}.tmp")
        tmp.write_text(out.getvalue())
        os.replace(tmp, stamp)
    return 0
