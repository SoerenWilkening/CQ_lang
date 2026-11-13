"""Pruning of the checker's content-keyed caches (cq-p9pty task B).

Every cache entry of the checker is keyed by the content of what made it (the checker's sources, the toolchain, the
input text): a checker or pass change leaves the old entries behind, never read again, and nothing deleted them
(64 GB on 2026-11-12). The caches pruned here:

    $CQE_CACHE (run._cache_root)           drv/, prog/, lower/, verify/, rt/, ... and runs/<kind>/<xx>/
    $CQ_SAMPLES_CACHE (sampling._cache_dir) the sample sets and domain lists, and probe/
    <build>/oracle (oracle._build_root)     exe/, prog/ and the tool-* directories

An entry is a direct child of one of those directories (a file or a directory). A cache hit marks its entry used
(`used`: its mtime set to now), so an entry's mtime is the last time a checker built or read it. `prune` removes the
entries not used for $CQCHECK_CACHE_DAYS days (default 2; `off` or 0 disables), never one used within MIN_AGE (a
concurrent checker process reading an entry has touched it). It runs at most once per process (cli.main) and at
most once per STAMP_EVERY across processes (a stamp file in the cache root), and reads only directory listings and
each entry's own lstat: no walk below an entry. A directory is first renamed to a tombstone (`.cqgc.<pid>.<name>`)
in its own directory, then removed; a rename or removal that loses a race to another process is skipped. Tombstones
left by a killed process are removed by the next prune.
"""
from __future__ import annotations

import os
import shutil
import threading
import time
from pathlib import Path
from typing import Iterable, List, Optional, Sequence, Tuple

DAYS_ENV = "CQCHECK_CACHE_DAYS"
DEFAULT_DAYS = 2.0
MIN_AGE = 6 * 3600           # never remove an entry used within the last 6 hours, whatever the setting
STAMP = ".cqgc-stamp"
STAMP_EVERY = 3600           # a prune in any process within the last hour: none now
TOMB = ".cqgc."

_DONE = False
_LOCK = threading.Lock()


def used(path: Path) -> None:
    """Mark a cache entry used (a cache hit): its mtime is now. Never fails."""
    try:
        os.utime(path)
    except OSError:
        pass


def max_age() -> Optional[float]:
    """Seconds after which an unused entry is removed, or None when pruning is off."""
    v = os.environ.get(DAYS_ENV, "").strip().lower()
    if v in ("off", "no", "never"):
        return None
    try:
        days = float(v) if v else DEFAULT_DAYS
    except ValueError:
        days = DEFAULT_DAYS
    if days <= 0:
        return None
    return max(days * 86400.0, float(MIN_AGE))


def containers() -> List[Tuple[Path, Tuple[str, ...], Optional[str]]]:
    """(directory, names of its children that are containers themselves, prefix its entries must have or None)."""
    from cqcheck import oracle, run, sampling
    out: List[Tuple[Path, Tuple[str, ...], Optional[str]]] = []
    root = run._cache_root()
    for c in _subdirs(root):
        if c.name == "runs":
            for kind in _subdirs(c):
                out.extend((xx, (), None) for xx in _subdirs(kind))
        else:
            out.append((c, (), None))
    s = sampling._cache_dir()
    out.append((s, ("probe",), None))
    out.append((s / "probe", (), None))
    o = oracle._build_root()
    out.append((o, (), "tool-"))
    out.extend((o / k, (), None) for k in ("exe", "prog"))
    return out


def _subdirs(d: Path) -> List[Path]:
    try:
        return sorted(Path(e.path) for e in os.scandir(d) if e.is_dir(follow_symlinks=False) and not e.name.startswith("."))
    except OSError:
        return []


def _tomb_owner_alive(name: str) -> bool:
    from cqcheck import tmpdirs
    try:
        return tmpdirs.pid_alive(int(name[len(TOMB):].split(".", 1)[0]))
    except ValueError:
        return False


def _remove(path: Path, is_dir: bool) -> bool:
    if not is_dir:
        try:
            os.unlink(path)
            return True
        except OSError:
            return False
    if path.name.startswith(TOMB):
        tomb = path
    else:
        tomb = path.with_name(f"{TOMB}{os.getpid()}.{path.name}")
        try:
            os.rename(path, tomb)        # atomic: a reader finds the entry whole or not at all
        except OSError:
            return False                 # gone already, or another pruner took it
    shutil.rmtree(tomb, ignore_errors=True)
    return True


def prune_dirs(dirs: Iterable[Tuple[Path, Sequence[str], Optional[str]]], age: float,
               now: Optional[float] = None) -> List[Path]:
    """Remove the entries of `dirs` (see containers) last used more than `age` seconds before `now` (never less
    than MIN_AGE), and every tombstone whose owner is dead; the paths removed."""
    now = time.time() if now is None else now
    age = max(age, float(MIN_AGE))
    gone: List[Path] = []
    for d, skip, prefix in dirs:
        try:
            entries = list(os.scandir(d))
        except OSError:
            continue
        for e in entries:
            name = e.name
            if name in skip or name == STAMP:
                continue
            tomb = name.startswith(TOMB)
            if not tomb and prefix is not None and not name.startswith(prefix):
                continue
            try:
                st = e.stat(follow_symlinks=False)
                is_dir = e.is_dir(follow_symlinks=False)
            except OSError:
                continue
            if tomb:
                if _tomb_owner_alive(name) and now - st.st_mtime < MIN_AGE:
                    continue
            elif now - st.st_mtime <= age:
                continue
            if _remove(Path(e.path), is_dir):
                gone.append(Path(e.path))
    return gone


def prune(force: bool = False) -> List[Path]:
    """The prune of this process (the module docstring): at most once per process, and not when another process
    pruned within STAMP_EVERY (unless `force`). Never raises."""
    global _DONE
    with _LOCK:
        if _DONE and not force:
            return []
        _DONE = True
    age = max_age()
    if age is None:
        return []
    try:
        from cqcheck import run
        root = run._cache_root()
        stamp = root / STAMP
        now = time.time()
        if not force:
            try:
                if now - stamp.stat().st_mtime < STAMP_EVERY:
                    return []
            except OSError:
                pass
        try:
            root.mkdir(parents=True, exist_ok=True)
            stamp.touch()
        except OSError:
            pass
        return prune_dirs(containers(), age, now)
    except Exception:  # noqa: BLE001 - pruning is housekeeping: a failure never stops a check
        return []
