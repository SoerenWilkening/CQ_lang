"""The checker's run directories in the user temp dir (cq-3fjt).

The evaluator's runner directories (``cqe-run.*``, run.py) and the C oracle's (``cqo-run.*``,
oracle.py) live as long as the Python process that made them, which removes them at its end. A process
that is killed (heavy.sh's time limit or memory cap, a SIGKILL) leaves them behind; on 2026-11-01 279
of them filled the disk. Each one therefore records its owner, the pid of the Python process that made
it, in the file ``owner``, and ``sweep`` (run at every checker start, and by heavy.sh after it kills a
run) removes the ones whose owner is dead. A directory whose owner is alive is never removed. One with
no readable owner (made before cq-3fjt, or in the instant between mkdtemp and the owner file) is removed
only when nothing in it changed for LEGACY_AGE seconds: no run lives that long (heavy.sh's cap is
600 s).
"""
import os
import shutil
import tempfile
import time
from pathlib import Path
from typing import List, Optional

PREFIXES = ("cqe-run.", "cqo-run.")
OWNER = "owner"
LEGACY_AGE = 2 * 3600


def make_run_dir(prefix: str) -> Path:
    """A fresh run directory in the user temp dir, its owner this process."""
    assert prefix in PREFIXES, prefix
    d = Path(tempfile.mkdtemp(prefix=prefix))
    (d / OWNER).write_text(f"{os.getpid()}\n")
    return d


def pid_alive(pid: int) -> bool:
    if pid <= 0:
        return False
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:   # someone else's process: alive
        return True
    return True


def _owner(d: Path) -> Optional[int]:
    try:
        return int((d / OWNER).read_text().strip())
    except (OSError, ValueError):
        return None


def _newest(d: Path) -> float:
    t = d.lstat().st_mtime
    try:
        for e in os.scandir(d):
            try:
                t = max(t, e.stat(follow_symlinks=False).st_mtime)
            except OSError:
                pass
    except OSError:
        pass
    return t


def sweep(root: Optional[Path] = None, now: Optional[float] = None) -> List[Path]:
    """Remove the run directories under `root` (default: the user temp dir) whose owner is dead; the
    ones removed."""
    root = Path(root or tempfile.gettempdir())
    now = time.time() if now is None else now
    gone: List[Path] = []
    try:
        entries = list(os.scandir(root))
    except OSError:
        return gone
    for e in entries:
        if not e.name.startswith(PREFIXES) or not e.is_dir(follow_symlinks=False):
            continue
        d = Path(e.path)
        pid = _owner(d)
        try:
            if pid is not None:
                if pid_alive(pid):
                    continue
            elif now - _newest(d) < LEGACY_AGE:
                continue
        except OSError:
            continue
        shutil.rmtree(d, ignore_errors=True)
        gone.append(d)
    return gone
