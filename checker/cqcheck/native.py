"""The checker's native helpers (cq-8m6v): checker/native/*.cpp as one shared library, built into the
tool cache (run.tool_root) by a hash of its sources and the compiler, loaded with ctypes. A source
that does not build is an internal error of the checker (NativeError), never a silent fallback."""
from __future__ import annotations

import ctypes
import hashlib
import os
import subprocess
import tempfile
import threading
from pathlib import Path

SRC = Path(__file__).resolve().parents[1] / "native"
_LOCK = threading.Lock()
_LIB = None


class NativeError(RuntimeError):
    pass


def _clangxx() -> str:
    from cqcheck import run
    return str(run.LLVM_BIN / "clang++")


def path() -> Path:
    from cqcheck import run
    srcs = sorted(SRC.glob("*.cpp"))
    h = hashlib.sha256(_clangxx().encode())
    for s in srcs:
        h.update(s.name.encode() + b"\0" + s.read_bytes() + b"\0")
    return run.tool_root() / "native" / f"libcqnative-{h.hexdigest()[:20]}.so"


def lib() -> ctypes.CDLL:
    global _LIB
    if _LIB is not None:
        return _LIB
    with _LOCK:
        if _LIB is not None:
            return _LIB
        out = path()
        if not out.exists():
            out.parent.mkdir(parents=True, exist_ok=True)
            fd, tmp = tempfile.mkstemp(prefix=out.name + ".", dir=out.parent)
            os.close(fd)
            r = subprocess.run([_clangxx(), "-std=c++17", "-O2", "-shared", "-fPIC", "-w",
                                *map(str, sorted(SRC.glob("*.cpp"))), "-o", tmp], capture_output=True, text=True)
            if r.returncode != 0:
                os.unlink(tmp)
                raise NativeError(f"cq: chk-compare: building checker/native failed:\n{r.stderr[-3000:]}")
            os.replace(tmp, out)
        L = ctypes.CDLL(str(out))
        L.cq_match_c.restype = ctypes.c_int64
        L.cq_match_c.argtypes = [ctypes.POINTER(ctypes.c_int64), ctypes.c_int64,
                                 ctypes.POINTER(ctypes.c_int64), ctypes.c_int64]
        _LIB = L
        return L


def match_c(data, n: int):
    """cq_match_c over the marshalled input (compare._match_input): (status, found_any, found,
    assign, unprep)."""
    L = lib()
    arr = (ctypes.c_int64 * len(data))(*data)
    out = (ctypes.c_int64 * (3 + 2 * n))()
    rc = L.cq_match_c(arr, len(data), out, 3 + 2 * n)
    if rc != 0:
        raise NativeError(f"cq: chk-compare: cq_match_c failed ({rc})")
    return (out[0], bool(out[1]), bool(out[2]), [None if x < 0 else int(x) for x in out[3:3 + n]],
            {i for i in range(n) if out[3 + n + i]})


def launcher() -> Path:
    """The cqcheck launcher (native/cqcheck_launch.c, step 6 option b): tool_root()/cqcheck, which execs
    the interpreter `python3` resolves to (outside any shim) on the checker, with -S. Rebuilt when its
    source, the interpreter or the checker's place changes."""
    from cqcheck import run
    py = subprocess.run(["python3", "-c", "import sys; print(sys.executable)"], capture_output=True,
                        text=True).stdout.strip() or sys_executable()
    checker = str(SRC.parent)
    src = SRC / "cqcheck_launch.c"
    h = hashlib.sha256("\0".join([py, checker, str(run.LLVM_BIN)]).encode() + src.read_bytes()).hexdigest()[:20]
    built = run.tool_root() / "native" / f"cqcheck-{h}"
    if not built.exists():
        built.parent.mkdir(parents=True, exist_ok=True)
        tmp = built.with_name(built.name + f".{os.getpid()}.tmp")
        r = subprocess.run([str(run.LLVM_BIN / "clang"), "-O1", "-w", f"-DCQ_PY={_c_str(py)}",
                            f"-DCQ_CHECKER={_c_str(repr(checker))}", str(src), "-o", str(tmp)],
                           capture_output=True, text=True)
        if r.returncode != 0:
            raise NativeError(f"cq: building the cqcheck launcher failed:\n{r.stderr[-3000:]}")
        os.replace(tmp, built)
    link = run.tool_root() / "cqcheck"
    tmpl = link.with_name(f"cqcheck.{os.getpid()}.tmp")
    if tmpl.exists() or tmpl.is_symlink():
        tmpl.unlink()
    os.symlink(built.name if built.parent == link.parent else os.path.relpath(built, link.parent), tmpl)
    os.replace(tmpl, link)
    return link


def sys_executable() -> str:
    import sys
    return sys.executable


def _c_str(s: str) -> str:
    """A C string literal of s, for a -D definition."""
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'
