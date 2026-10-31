"""The C oracle (cq-w0-chk-oracle): the example's .O1.ll run as the C program it is, under CR §2 and §6.

CLAUDE.md "The §6 checker", oracle (b): ``name.O1.ll`` with ``cq_theta``/``cq_measure`` as the
identity, logging each ``cq_theta``/``cq_phi`` call site reached and its angle. The program is linked
with a generated driver (and the injection bundle when ``bundle/manifest.json`` lists one), instrumented
by ``checker/oracle/OracleInstr.cpp`` (the ``cq-oracle`` opt pass) and linked with
``checker/oracle/cqo_rt.c``. Every sample runs from the program's post-setup state, as a child forked
for it alone would: one worker process runs the batch in-process and puts that state back after each
sample, and a trap, an abort, a crash or a hang ends that sample only (cqo_rt.c, samples; cq-pz9h).

Trace events (cq-arch; values are hex bit patterns ``0x`` + lowercase digits, no leading zeros):

- ``{"ev":"site","fn","site","kind","angle","reg"}``: ``site`` is the ordinal of the call among the
  ``cq_theta_*``/``cq_phi``/``cq_measure_*``/``__cq_invert_*`` calls of function ``fn`` in textual order
  of the input IR. ``kind`` is ``theta``, ``phi``, ``measure`` (reg = the measured value) or
  ``invert_begin``/``invert_end`` (markers) (cq-arch T1.1), or ``read``: a ``cq_measure`` of a value CR
  rule 2's classical collapse made classical (computed only from measured rails and classical values,
  owner ruling cq-r6bc; OracleInstr.cpp, shadows), which is no gate and is neither measured nor a rotation
  (bead cq-y1ll). ``angle`` is the f64 bit pattern (null for
  measure and markers); ``reg`` the register value at its width (null for phi and markers).
- ``{"ev":"trip","loop","n"}`` once per loop activation, when the loop is left (T1.2). ``loop`` is
  ``<fn>:<header>``, the header block's label spelled as an operand in the input .O1.ll (``%7``,
  ``%for.body``), taken before the instrumentation edits the function. ``n`` counts the trips begun: header
  executions, less the final one when it only ran the exit test (an exit from a header that is not a
  latch). A guard branch whose other successor is an exit block reports ``n = 0`` when it skips the loop;
  the guard may reach the header directly or through single-predecessor blocks that branch
  unconditionally on (a preheader, as in 55).
- ``{"ev":"ret","v"}``: the driver call's return value (``null`` for void).
- ``{"ev":"effect","name","args"}`` (cq-e4jk): a call of a host-effect function (compare.HOST_EFFECTS:
  remove, unlink, rename, raise), logged at the call, before it runs; args ``[{"s": str} | {"w":
  "i<N>", "v": hex}]`` (a pointer argument read as a C string, an integer at its IR width).
- ``{"ev":"stdout","s"}`` (cq-e4jk): once per sample, at its end, what the program printed to stdout
  (the driver's setup, then the sample), bytes as the code points of the same number. stdout is
  unbuffered in the oracle, so a sample that ends by abort or a signal keeps what it printed before
  (CR §1.3: the tape entries before an abort flag reading 1 are performed).
  Both go to ``SampleRun.effects`` and ``SampleRun.stdout`` and side 'c' outputs["effects"] and
  outputs["stdout"] (compare.py, Host output), never to ``SampleRun.events``.

The cutoff K (CR §6 at eb8a11a, ruling cq-1di; bead cq-8ay). Every quantum-exit loop and
quantum-depth recursion stops after K trips, as in the circuit: when the trips begun would exceed K
(the exit test after the K-th body admits trip K+1) the sample ends there with outcome
``cap:<loop>``, which is not a failure. Each activation gets a cq-arch T2 record in
``SampleRun.loops`` and side 'c' ``outputs["loops"]``: ``{"loop", "act", "n", "capped"}`` when it
ends by itself (n as T1.2 counts trips), ``{..., "n": K, "capped": true, "cut", "mcut"}`` at the cap
(cut/mcut: the rotations and measurements recorded so far). A recursion is ``<fn>:recursion`` (T2.2),
its n the levels along the deepest chain. Classical loops and classical-bound loops with a quantum
exit run to completion (the trip cap below still ends a runaway one). K resolves as the circuit
resolves it: ``k`` (per-function, cq-lower's ``-cq-k``), ``CQ_K(f, k)``, ``k_default`` (cq-lower's
``-cq-k-default``), 4. Which loops and recursions are quantum is the circuit's own answer: the
instrumentation links the pass's taint and rule-14 classification (``cq::computeTaint``,
``cq::loops::classify``; ``PASS_SOURCES``), runs them on the pristine program, and tracks each
frame's specialization at run time (OracleInstr.cpp ``KInfo``). A capped trip count reports no T1
trip event (the loop never took an exit edge).

§2 and §6 in the C program: div/rem by 0 and INT_MIN/-1, shifts >= W (amount mod W), fptosi/fptoui
(row by row), maxnum/minnum, fmuladd unfused, abs(INT_MIN), ctlz/cttz(0) are rewritten to the table;
allocas, lifetime starts and heap blocks read 0 until written; a load outside every object (globals,
allocas, heap blocks, byval parameter copies, the register save and overflow areas va_start points
at) reads 0 and a store there is dropped. Threads collapse (rule 24).

A function nothing defines (after libc/libm) gets the checker's model (OracleInstr.cpp ``stubs``):
FNV-1a-64 over the name bytes, then ``h = (h ^ w) * 0x100000001b3`` per 64-bit word of each non-pointer
argument; the result is the low W bits; no memory effect.

Samples are Z1's ``{"call", "args"}`` (SampleSet.samples entries); the driver is rendered only by
``drivers.driver_source(spec, samples, before_call=..., after_call=..., main_name="__cqo_drv_main")``,
whose ``before_call``/``after_call`` hand each record to cqo_rt.c's in-process worker. The driver reads the
samples at run time from ``drivers.sample_file`` in ``$CQD_SAMPLES`` (cq-arch Z2): one build per
example; one persistent runner process per executable serves every batch (``PARTS``, default 1).
The driver discards the
call's result, so the instrumentation logs it at the IR call (``-cq-oracle-entries``). An optional
``"subst": {"<fn>:<site>": hex}`` replaces the register value at a ``cq_theta`` site each time it is
reached, or with a list ``[hex, ...]`` the r-th reach takes entry r mod len (cq-arch Z4, cq-6m2: CR §6
item 1, "each cq_theta input replaced by a chosen bit pattern"); it never reaches the driver. The
trace's ``reg`` of a substituted theta site is the chosen value. A site with no entry is the
identity.

Sample outcome: ``ret`` (returned), ``noreturn:<callee>`` (abort, exit, __builtin_trap, ...),
``raise:<sig>`` (the program raised a fatal signal), ``cap:<loop>`` (stopped after K trips). Anything else is a failure with a reason, never
dropped: ``unreachable`` reached, an out-of-bounds atomic, the runaway trip cap, a signal no hook
explains (a trap the totalization should have prevented), a bad sample.

Determinism (cq-sqn6; orchestrator decision under determinism, owner may override): no sample's
result depends on time or machine load. A runaway program ends at the trip cap, a step budget
(``tripcap`` loop-header executions per sample). ``timeout_ms`` is only a hang guard for what the
budget does not count (a loop inside an uninstrumented library function, a blocking call): a sample
that passes it in CPU time, or a worker that makes no progress for a minute of wall-clock time, raises
OracleError naming the sample, an internal error of the checker and never a sample outcome.

API: ``run_sample(o1, spec, sample) -> RunResult`` and ``trace_sample(o1, spec, sample) -> [event]``
(both frozen by Z1, cq-zew); ``run_samples(o1, spec, samples, ..., k=None, k_default=None) ->
[SampleRun]`` runs a whole batch and keeps failed samples' partial events.
CLI: ``python3 -m cqcheck.oracle <NN_name|O1.ll> [--samples JSON] [--driver JSON] [--json OUT]
[--k fn=k,...] [--k-default K]``.
"""
from __future__ import annotations

import atexit
import ctypes
import dataclasses
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import threading
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence, Tuple

from .contracts import DriverSpec, RunResult

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "checker" / "oracle"
LLVM_BIN = Path(os.environ.get("CQ_LLVM_BIN", "/usr/local/opt/llvm@19/bin"))
SPEC = Path(os.environ.get("CQ_SPEC_DIR", ROOT.parent / "CQ_spec"))
DEFAULT_TIMEOUT_MS = 2000
DEFAULT_TRIPCAP = 10_000_000


class OracleError(RuntimeError):
    """The oracle could not build or run (an internal error of the checker, never a sample verdict)."""


def _build_root() -> Path:
    return Path(os.environ.get("CQ_BUILD_DIR", ROOT / "build")) / "oracle"


def _tool(name: str) -> str:
    return str(LLVM_BIN / name)


def _run(cmd: Sequence[str], what: str, **kw) -> subprocess.CompletedProcess:
    p = subprocess.run(list(cmd), capture_output=True, text=True, **kw)
    if p.returncode != 0:
        raise OracleError(f"oracle: {what} failed ({p.returncode}): {' '.join(map(str, cmd))}\n"
                          f"{p.stderr.strip()[-4000:]}")
    return p


def _atomic_dir(final: Path, fill) -> Path:
    """Build into a fresh temp dir and rename it into place (concurrent builders are safe)."""
    if final.exists():
        return final
    from .run import key_lock
    with key_lock(final):   # cq-8m6v: a concurrent builder of the same entry in this process waits
        return _atomic_dir_locked(final, fill)


def _atomic_dir_locked(final: Path, fill) -> Path:
    if final.exists():
        return final
    final.parent.mkdir(parents=True, exist_ok=True)
    tmp = Path(tempfile.mkdtemp(prefix=final.name + ".", dir=final.parent))
    try:
        fill(tmp)
        try:
            os.rename(tmp, final)
        except OSError:
            if not final.exists():
                raise
    finally:
        if tmp.exists():
            shutil.rmtree(tmp, ignore_errors=True)
    return final


# ------------------------------------------------------------------------------------------------
# toolchain: the instrumentation plugin and the runtime, rebuilt when their sources change

STANDIN = ROOT / "checker" / "rt" / "cq_standin.h"   # included by both sources (cq-25vx)
# The pass's taint and rule-14 classification, linked into the instrumentation (cq-8ay): the oracle
# caps exactly the loops and recursions the circuit cuts at K. These four translation units depend on
# nothing else of the pass.
PASS = ROOT / "pass"
PASS_SOURCES = [PASS / "lib" / "taint" / "Taint.cpp", PASS / "lib" / "spine" / "Classify.cpp",
                PASS / "lib" / "Common.cpp", PASS / "lib" / "abi" / "Abi.cpp"]


def _pass_inputs() -> List[Path]:
    hdrs = sorted((PASS / "include").rglob("*.h")) + sorted(
        p for d in ("taint", "spine", "abi") for p in (PASS / "lib" / d).glob("*.h"))
    return PASS_SOURCES + hdrs


def _src_hash() -> str:
    h = hashlib.sha256()
    for p in [SRC / "OracleInstr.cpp", SRC / "TripFacts.cpp", SRC / "cqo_rt.c", STANDIN] + _pass_inputs():
        h.update(str(p.relative_to(ROOT)).encode() + b"\0" + p.read_bytes() + b"\0")
    return h.hexdigest()[:16]


TOOL_KEY = _src_hash()
SRC_KEY = hashlib.sha256((TOOL_KEY + "\0").encode() + Path(__file__).read_bytes()).hexdigest()[:16]


def toolchain() -> Tuple[Path, Path]:
    cpp, rt = SRC / "OracleInstr.cpp", SRC / "cqo_rt.c"

    def fill(d: Path) -> None:
        from concurrent.futures import ThreadPoolExecutor
        flags = _run([_tool("llvm-config"), "--cxxflags"], "llvm-config").stdout.split()
        cxx = [_tool("clang++"), *flags, "-fno-rtti", "-fPIC", "-O1", "-I", str(PASS / "include")]
        units = [cpp, SRC / "TripFacts.cpp"] + PASS_SOURCES
        objs = [d / f"{k}-{u.stem}.o" for k, u in enumerate(units)]
        with ThreadPoolExecutor(max_workers=min(len(units), _jobs_cap())) as ex:
            list(ex.map(lambda uo: _run([*cxx, "-c", str(uo[0]), "-o", str(uo[1])],
                                        f"compiling {uo[0].name} for the oracle plugin"), zip(units, objs)))
        _run([_tool("clang++"), "-shared", "-undefined", "dynamic_lookup", *map(str, objs),
              "-o", str(d / "libCQOracle.so")], "linking the oracle plugin")
        _run([_tool("clang"), "-std=c17", "-O1", "-c", str(rt), "-o", str(d / "cqo_rt.o")],
             "building the oracle runtime")

    d = _atomic_dir(_build_root() / f"tool-{TOOL_KEY}", fill)
    return d / "libCQOracle.so", d / "cqo_rt.o"


# ------------------------------------------------------------------------------------------------
# C types (only the return type matters here: the argument encoding is chk-drivers')

_ALIASES = {"signed": "int", "signed int": "int", "unsigned int": "unsigned", "short int": "short",
            "signed short": "short", "unsigned short int": "unsigned short", "long int": "long",
            "signed long": "long", "unsigned long int": "unsigned long", "long long int": "long long",
            "signed long long": "long long", "unsigned long long int": "unsigned long long"}


def norm_ctype(t: str) -> str:
    t = " ".join(t.replace("*", " * ").split()).replace(" *", "*")
    return _ALIASES.get(t, t)


def parse_protos(protos: Sequence[str]) -> Dict[str, Tuple[str, List[str]]]:
    """fn -> (return ctype, parameter ctypes) from prototype strings like ``int f(int,double);``."""
    out: Dict[str, Tuple[str, List[str]]] = {}
    for chunk in protos:
        for p in chunk.split(";"):
            p = p.strip()
            m = re.match(r"^(.*?)([A-Za-z_][A-Za-z_0-9]*)\s*\((.*)\)\s*$", p, re.S)
            if not m:
                continue
            ret, fn, params = m.group(1).strip(), m.group(2), m.group(3).strip()
            plist = [] if params in ("", "void") else [x.strip() for x in params.split(",")]
            out[fn] = (norm_ctype(ret), [norm_ctype(x) for x in plist])
    return out


_FP_RAIL = {"float": "f32", "double": "f64", "long double": "f80", "_Float16": "f16", "__fp16": "f16",
            "__bf16": "bf16"}


def _ret_ctype(spec: DriverSpec, fn: str) -> str:
    r = parse_protos(spec.protos).get(fn)
    if r is None:
        raise OracleError(f"oracle: no prototype for {fn} in the driver of {spec.example}")
    return r[0]


# ------------------------------------------------------------------------------------------------
# build: the instrumented program once per .O1.ll, a driver per batch of samples

def _triple(ll_text: str) -> str:
    m = re.search(r'^target triple = "([^"]+)"', ll_text, re.M)
    return m.group(1) if m else "x86_64-apple-macosx"


def _bundle_files() -> List[Path]:
    man = ROOT / "bundle" / "manifest.json"
    if not man.exists():
        return []
    return [(man.parent / p).resolve() for p in json.loads(man.read_text())]


_BUNDLE_INFO: Dict[Tuple[str, int, int], Tuple[frozenset, str]] = {}


def _bundle_info(b: Path) -> Tuple[frozenset, str]:
    """(the symbols bundle file `b` defines, as llvm-nm prints them; the sha256 of its content)."""
    st = b.stat()
    memo = (str(b), st.st_mtime_ns, st.st_size)
    if memo not in _BUNDLE_INFO:
        sha = hashlib.sha256(b.read_bytes()).hexdigest()
        # the symbol list is a function of the bytes and the toolchain (cq-8m6v: kept across runs)
        from .run import tool_root
        kept = tool_root() / "bundle-nm" / hashlib.sha256(f"{sha}\0{LLVM_BIN}".encode()).hexdigest()[:24]
        if kept.exists():
            defs = kept.read_text().split()
        else:
            defs = _run([_tool("llvm-nm"), "--defined-only", "--format=just-symbols", str(b)],
                        "llvm-nm of the injection bundle").stdout.split()
            kept.parent.mkdir(parents=True, exist_ok=True)
            tmp = kept.with_name(f"{kept.name}.{os.getpid()}.{threading.get_ident()}.tmp")
            tmp.write_text("".join(d + "\n" for d in defs))
            os.replace(tmp, kept)
        _BUNDLE_INFO[memo] = (frozenset(defs), sha)
    return _BUNDLE_INFO[memo]


_NAME = r'([-\w$.]+|"[^"]+")'
_DECLARED = re.compile(r'^(?:declare\b[^@]*@' + _NAME + r'\(|@' + _NAME + r' = (?:\S+ )*?external\b)', re.M)


def bundle_for(ll_text: str) -> List[Path]:
    """The injection bundle files to link into a module (cq-b041; CR rule 18, CLAUDE.md "Pipeline"):
    every bundle/manifest.json file, linked --only-needed, when the module declares without a body
    at least one symbol the bundle defines; otherwise none, and the module is used as clang wrote it."""
    bundle = _bundle_files()
    if not bundle:
        return []
    names = {(a or b).strip('"') for a, b in _DECLARED.findall(ll_text)}
    if "-apple-" in _triple(ll_text):  # Mach-O symbol names carry a leading underscore
        names = {"_" + n for n in names}
    if any(names & _bundle_info(b)[0] for b in bundle):
        return bundle
    return []


def bundle_key(files: Sequence[Path]) -> str:
    """A cache-key part for the bundle files actually linked: their paths and contents."""
    return "\0".join(f"{b}:{_bundle_info(Path(b))[1]}" for b in files)


_LIBC = None


def _host_defines(name: str) -> bool:
    global _LIBC
    if _LIBC is None:
        _LIBC = ctypes.CDLL(None)
    try:
        getattr(_LIBC, name)
        return True
    except AttributeError:
        return False


# Provided by the instrumentation or the runtime, never modelled.
_PROVIDED = re.compile(r"^(llvm\.|__cqo_|cq_theta_|cq_measure_|cq_phi$|__cq_invert_|cqrt_alloc_i(1|8|16|32)$)")


def _k_flags(k: Optional[Dict[str, int]], k_default: Optional[int]) -> List[str]:
    """cq-oracle's K flags, the same chain as cq-lower's -cq-k / -cq-k-default (CR §0: per-function
    flag, CQ_K, global flag, 4)."""
    out = []
    if k:
        out.append("-cq-oracle-k=" + ",".join(f"{f}={int(v)}" for f, v in sorted(k.items())))
    if k_default is not None:
        out.append(f"-cq-oracle-k-default={int(k_default)}")
    return out


# Process state a sample can change that the in-process runner (cqo_rt.c, samples) does not put back:
# a program that uses any of these runs every sample in a worker of its own, as the forked child of
# one sample did (signal dispositions, atexit handlers, timers, the C library's hidden state).
_ISOLATE = {"signal", "sigaction", "sigprocmask", "pthread_sigmask", "atexit", "__cxa_atexit",
            "__cxa_thread_atexit", "alarm", "setitimer", "ualarm", "fork", "vfork", "sigaltstack",
            "sigset", "bsd_signal", "rand", "srand", "random", "srandom", "initstate", "setstate",
            "drand48", "erand48", "lrand48", "nrand48", "mrand48", "jrand48", "srand48", "seed48",
            "lcong48", "strtok", "setlocale", "uselocale", "setenv", "putenv", "unsetenv", "fopen",
            "freopen", "fdopen", "tmpfile", "open", "creat", "dup2", "close", "chdir", "umask",
            "tmpnam", "tempnam", "mkstemp", "remove", "unlink", "rename"}
_PROGRAMS: Dict[Tuple[str, int, str], Tuple[Path, str]] = {}


# Of _ISOLATE, the calls that reach the file system (cq-8m6v): a program that makes one may let a
# sample see what an earlier sample of its batch left there, so its batches are run whole, as asked,
# in one runner (no per-sample reuse across batches, no parallel parts).
_FS = {"fopen", "freopen", "fdopen", "tmpfile", "open", "creat", "dup2", "close", "chdir", "umask", "tmpnam",
       "tempnam", "mkstemp", "remove", "unlink", "rename"}


def touches_files(prog_o: Path) -> bool:
    f = Path(prog_o).parent / "isolate.txt"
    return f.exists() and bool(set(f.read_text().split()) & _FS)


def isolated(prog_o: Path) -> bool:
    """Whether the program runs every sample in a worker of its own (_ISOLATE)."""
    f = Path(prog_o).parent / "isolate.txt"
    return f.exists() and bool(f.read_text().strip())


def program(o1: Path, k: Optional[Dict[str, int]] = None, k_default: Optional[int] = None) -> Tuple[Path, str]:
    """The instrumented program object of one .O1.ll (cached), and its target triple. k / k_default:
    the cutoff flags (default none: CQ_K, then 4)."""
    o1 = Path(o1)
    st = o1.stat()
    memo = (str(o1.resolve()), st.st_mtime_ns, repr((sorted((k or {}).items()), k_default)))
    if memo in _PROGRAMS and _PROGRAMS[memo][0].exists():
        return _PROGRAMS[memo]
    plugin, rt = toolchain()
    text = o1.read_text()
    bundle = bundle_for(text)
    kf = _k_flags(k, k_default)
    key = hashlib.sha256("\0".join([text, SRC_KEY, *kf] + ([bundle_key(bundle)] if bundle else [])).encode()).hexdigest()[:20]
    triple = _triple(text)

    def fill(d: Path) -> None:
        linked = d / "linked.bc"
        _run([_tool("llvm-as"), str(o1), "-o", str(linked)], "llvm-as")
        if bundle:
            _run([_tool("llvm-link"), str(linked), "--only-needed", *map(str, bundle), "-o", str(linked)],
                 "llvm-link with the injection bundle")
        und = _run([_tool("llvm-nm"), "--undefined-only", "--format=just-symbols", str(linked)],
                   "llvm-nm").stdout.split()
        if "-apple-" in triple:  # Mach-O symbol names carry a leading underscore
            und = [n[1:] if n.startswith("_") else n for n in und]
        stubs = sorted(n for n in und if not _PROVIDED.match(n) and not _host_defines(n))
        (d / "stubs.txt").write_text("".join(n + "\n" for n in stubs))
        iso = sorted(set(und) & _ISOLATE) + (["thread_local"] if "thread_local" in text else [])
        (d / "isolate.txt").write_text("".join(n + "\n" for n in iso))
        _run([_tool("opt"), f"-load-pass-plugin={plugin}", "-passes=cq-oracle",
              f"-cq-oracle-stubs={d / 'stubs.txt'}", *kf, str(linked), "-o", str(d / "prog.bc")],
             "the cq-oracle instrumentation of the program")
        _run([_tool("clang"), "-target", triple, "-O0", "-Wno-override-module", "-c", str(d / "prog.bc"),
              "-o", str(d / "prog.o")], "compiling the instrumented program")

    d = _atomic_dir(_build_root() / "prog" / f"{o1.stem}-{key}", fill)
    _PROGRAMS[memo] = (d / "prog.o", triple)
    return d / "prog.o", triple


# cqo_rt.c, samples: the worker runs each record's call in-process from the post-setup state; a sample
# that ends by exit, abort or the runtime's own end jumps back here.
DRIVER_PRELUDE = ("#include <setjmp.h>\nsigjmp_buf *__cqo_jb(void); void __cqo_resume(void); "
                  "int __cqo_sample_begin(int); void __cqo_sample_end(void);\n")
BEFORE_CALL = ("if (sigsetjmp(*__cqo_jb(), 1) != 0) __cqo_resume(); "
               "else if (__cqo_sample_begin(CQD_SAMPLE)) {")
AFTER_CALL = "__cqo_sample_end(); }"
DRIVER_MAIN = "__cqo_drv_main"


def _drivers():
    from . import drivers
    if getattr(drivers, "driver_source", None) is None:
        raise OracleError("cq: unimplemented: chk-drivers: drivers.driver_source")
    return drivers


CELLS_C_SIDE = "    } else {          /* the setup's cqrt_alloc_i"


def _driver_source(spec: DriverSpec, samples: Sequence[dict]) -> str:
    src = _drivers().driver_source(spec, list(samples), before_call=BEFORE_CALL,
                                   after_call=AFTER_CALL, main_name=DRIVER_MAIN)
    # handle cells (cq-oou2): the object the C program sees is its N cells (cqo_rt.c __cqo_cells_object)
    for w in sorted({a["cells"]["w"] for c in spec.calls for a in c["args"] if a.get("cells")}):
        head = f"static void cqd_cells_i{w}(void *p, int n, const unsigned long long *v) {{"
        i = src.find(head)
        j = src.find(CELLS_C_SIDE, i)
        if i < 0 or j < 0:
            raise OracleError(f"cq: unimplemented: chk-oracle: the driver's handle cell writer for i{w} not found")
        j = src.index("\n", j) + 1
        src = (src[:j] + f"        __cqo_cells_object(p, (unsigned long long)n * {max(1, w // 8)});\n" + src[j:])
    return DRIVER_PRELUDE + "void __cqo_cells_object(void *, unsigned long long);\n" + src


def executable(o1: Path, spec: DriverSpec, samples: Sequence[dict] = (),
               k: Optional[Dict[str, int]] = None, k_default: Optional[int] = None) -> Path:
    """The oracle program of one example: instrumented program + instrumented driver + runtime. The
    driver reads its samples at run time (cq-arch Z2), so one build serves every sample; `samples`
    only supply the pointer expressions the driver accepts."""
    prog_o, triple = program(o1, k, k_default)
    plugin, rt = toolchain()
    src = _driver_source(spec, samples)
    entries = sorted({c["fn"] for c in spec.calls})   # every call the driver can make
    key = hashlib.sha256("\0".join([str(prog_o), src, ",".join(entries)]).encode()).hexdigest()[:20]

    def fill(d: Path) -> None:
        (d / "driver.c").write_text(src)
        env = dict(os.environ, CQO_AT_END="1", CQO_ENTRIES=",".join(entries))
        _run([_tool("clang"), "-target", triple, "-std=gnu17", "-O1", "-w", f"-fpass-plugin={plugin}",
              str(d / "driver.c"), str(prog_o), str(rt), "-o", str(d / "prog")],
             "compiling, instrumenting and linking the driver", env=env)

    d = _atomic_dir(_build_root() / "exe" / f"{Path(o1).stem}-{key}", fill)
    return d / "prog"


# ------------------------------------------------------------------------------------------------
# run

@dataclass
class SampleRun:
    index: int
    sample: Dict[str, Any]
    events: List[Dict[str, Any]] = field(default_factory=list)
    outcome: str = ""            # ret | noreturn:<callee> | raise:<sig> | cap:<loop> | "" when failed
    failed: bool = False
    reason: str = ""
    notes: List[str] = field(default_factory=list)
    loops: List[Dict[str, Any]] = field(default_factory=list)   # T2 cutoff records (outputs["loops"])
    stdout: str = ""             # the program's stdout in this sample (outputs["stdout"], cq-e4jk)
    effects: List[Dict[str, Any]] = field(default_factory=list)  # its host-effect calls (outputs["effects"])


def _classify(sr: SampleRun) -> None:
    notes = sr.notes
    wait = next((n for n in reversed(notes) if n.startswith("wait ")), "wait missing")
    bad = [n for n in notes if n.startswith(("ub ", "crash ", "tripcap", "internal "))]
    noret = [n for n in notes if n.startswith("noreturn ")]
    cap = [n for n in notes if n.startswith("cap ")]
    raised = [n for n in notes if n.startswith("raise ")]
    has_ret = any(e.get("ev") == "ret" for e in sr.events)
    if bad:
        b = bad[0]
        sr.failed = True
        sr.reason = ("nonterminating: trip cap reached (the C program does not stop on this input)"
                     if b == "tripcap" else b)
    elif wait == "wait exited 0" and has_ret:
        sr.outcome = "ret"
    elif wait == "wait exited 0" and cap:
        sr.outcome = "cap:" + cap[-1].split(" ", 1)[1]   # stopped after K trips (T2.7): no violation
    elif noret:
        sr.outcome = "noreturn:" + noret[-1].split(" ", 1)[1]
    elif raised and wait.startswith("wait signaled ") and raised[-1].split()[1] == wait.split()[2]:
        sr.outcome = "raise:" + raised[-1].split()[1]
    else:
        sr.failed, sr.reason = True, f"{wait} with no explaining note (a trap the oracle did not totalize)"


def subst_values(val: Any) -> List[int]:
    """The per-reach values of one "subst" entry (cq-arch Z4): a hex string (every reach) or a
    non-empty list of them (reach r takes entry r mod len)."""
    vals = val if isinstance(val, list) else [val]
    if not vals:
        raise OracleError(f"oracle: an empty subst list {val!r}")
    out = []
    for v in vals:
        if isinstance(v, str) and re.fullmatch(r"0x[0-9a-fA-F]+", v):
            out.append(int(v, 16))
        elif isinstance(v, int) and not isinstance(v, bool) and v >= 0:
            out.append(v)
        else:
            raise OracleError(f"oracle: subst value {v!r} is not a 0x<hex> bit pattern")
        if out[-1] >> 128:
            raise OracleError(f"oracle: subst value {v!r} is wider than 128 bits")
    return out


def _subst_lines(samples: Sequence[dict]) -> List[str]:
    """cqo_rt.c's <subst> file: `<index> <fn> <site> <period> <occ> <nwords> <w>...` per reach value."""
    out = []
    for i, s in enumerate(samples):
        for k, val in sorted((s.get("subst") or {}).items()):
            fn, site = k.rsplit(":", 1)
            if not fn or re.search(r"\s", fn):
                raise OracleError(f"oracle: subst key {k!r} is not <fn>:<site>")
            vals = subst_values(val)
            for occ, v in enumerate(vals):
                words = [v & ((1 << 64) - 1)] + ([v >> 64] if v >> 64 else [])
                out.append(f"{i} {fn} {int(site)} {len(vals)} {occ} {len(words)} "
                           + " ".join(f"{w:x}" for w in words))
    return out


def run_samples(o1: Path, spec: DriverSpec, samples: Sequence[Dict[str, Any]],
                timeout_ms: int = DEFAULT_TIMEOUT_MS, tripcap: int = DEFAULT_TRIPCAP,
                k: Optional[Dict[str, int]] = None, k_default: Optional[int] = None) -> List[SampleRun]:
    """Every sample in one oracle program, each from the post-setup state as a child forked for it
    alone would run it (cqo_rt.c, samples). The batch entry point: the program's runner process
    stays up across calls (one per example and part, per Python process), so a call costs a fork of
    the runner plus microseconds per sample.

    A sample may carry an optional "subst": {"<fn>:<site>": hex | [hex, ...]} (cq-arch Z4: the value
    each reach of a cq_theta site takes; a list gives reach r its entry r mod len); the driver ignores
    keys other than call and args."""
    if not samples:
        return []
    return _run_uncached(Path(o1), spec, samples, timeout_ms, tripcap, k, k_default)


def _jobs_cap() -> int:
    """$CQCHECK_JOBS when set (the machine-wide cap on parallel processes), else the CPU count."""
    try:
        j = int(os.environ.get("CQCHECK_JOBS", ""))
    except ValueError:
        j = 0
    return max(1, j) if j else (os.cpu_count() or 1)


# A batch runs in up to PARTS runner processes at once, read at each call and never more than
# $CQCHECK_JOBS; a part has at least MIN_PART samples. The default is one: a sample costs
# microseconds, and the callers (report, selftest, sampling) already run up to $CQCHECK_JOBS
# examples in parallel, so a wider oracle would pass the machine-wide cap.
PARTS = 1
MIN_PART = 16


class Runner:
    """One persistent runner process of an oracle executable (``prog --serve``): each batch runs in a
    child it forks from its pristine state."""

    def __init__(self, exe: Path):
        self.exe = exe
        self.dir = Path(tempfile.mkdtemp(prefix="cqo-run."))
        self.lock = threading.Lock()
        self.pid = os.getpid()   # a runner belongs to the Python process that started it
        self.p = subprocess.Popen([str(exe), "--serve"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                  stderr=subprocess.DEVNULL, text=True, bufsize=1)

    def alive(self) -> bool:
        return self.pid == os.getpid() and self.p.poll() is None

    def run(self, spec: DriverSpec, samples: Sequence[Dict[str, Any]], timeout_ms: int, tripcap: int,
            isolate: bool) -> List[SampleRun]:
        with self.lock:
            t = self.dir
            (t / "samples").write_text(_drivers().sample_file(spec, samples))
            sub = _subst_lines(samples)
            if sub:
                (t / "subst").write_text("".join(l + "\n" for l in sub))
            req = " ".join([str(t / "trace"), str(t / "status"), str(t / "err"), str(int(timeout_ms)),
                            str(int(tripcap)), "1" if isolate else "0", str(t / "samples"),
                            str(t / "subst") if sub else "-"])
            try:
                self.p.stdin.write(req + "\n")
                self.p.stdin.flush()
                reply = self.p.stdout.readline()
            except (BrokenPipeError, OSError) as e:
                raise OracleError(f"oracle: runner {self.exe} died: {e}")
            if reply.strip() != "0":
                err = (t / "err").read_text(errors="replace") if (t / "err").exists() else ""
                raise OracleError(f"oracle: runner failed ({reply.strip() or 'no reply'}): {err.strip()[-2000:]}")
            with open(t / "trace") as tf:     # read line by line (cq-8m6v), never as one string
                return _parse_runs(samples, tf, (t / "status").read_text())

    def close(self) -> None:
        try:
            if self.p.poll() is None:
                self.p.stdin.close()
                try:
                    self.p.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    self.p.kill()
                    self.p.wait()
        except OSError:
            pass
        shutil.rmtree(self.dir, ignore_errors=True)


_RUNNERS: Dict[Tuple[str, int], Runner] = {}   # in least-recently-used order
MAX_RUNNERS = 8   # idle runner processes kept per Python process
_RUNNERS_LOCK = threading.Lock()


def _runner(exe: Path, part: int) -> Runner:
    key = (str(exe), part)
    with _RUNNERS_LOCK:
        r = _RUNNERS.pop(key, None)
        if r is not None and not r.alive():
            if r.pid == os.getpid():
                r.close()
            r = None
        old = []
        while len(_RUNNERS) >= MAX_RUNNERS:
            old.append(_RUNNERS.pop(next(iter(_RUNNERS))))
        r = _RUNNERS[key] = r or Runner(exe)
    for o in old:
        with o.lock:   # never while a batch runs on it
            o.close()
    return r


def close_runners() -> None:
    """End every runner process of this Python process (also run at exit)."""
    with _RUNNERS_LOCK:
        rs = list(_RUNNERS.values())
        _RUNNERS.clear()
    for r in rs:
        if r.pid == os.getpid():
            r.close()


atexit.register(close_runners)


def _run_uncached(o1: Path, spec: DriverSpec, samples: Sequence[Dict[str, Any]], timeout_ms: int,
                  tripcap: int, k: Optional[Dict[str, int]] = None,
                  k_default: Optional[int] = None) -> List[SampleRun]:
    from concurrent.futures import ThreadPoolExecutor
    exe = executable(Path(o1), spec, _pointer_samples(spec, samples), k, k_default)
    iso = isolated(program(Path(o1), k, k_default)[0])
    # cq-8m6v: a batch's runs are a function of the executable (its path is its content key), the
    # samples and the limits (cq-sqn6: no result depends on time or load; a hang raises instead)
    from .run import load_runs, save_runs
    key = [_RUNS_VERSION, str(exe), iso, int(timeout_ms), int(tripcap), list(samples)]
    got = load_runs("oracle", key)
    if got is None and touches_files(program(Path(o1), k, k_default)[0]):
        runs = _run_batch(exe, spec, samples, timeout_ms, tripcap, iso, whole=True)
        save_runs("oracle", key, [{f: getattr(r, f) for f in _RUN_FIELDS} for r in runs])
        return runs
    if got is None:
        # and per sample within this process (cq-8m6v): every sample runs from the post-setup state
        # as a process of its own would, so a sample run in an earlier batch (the sampler's searches,
        # the theta schedules) is not run again; the rest run as one batch
        mk = (str(exe), iso, int(timeout_ms), int(tripcap))
        with _MEMO_LOCK:
            memo = _SAMPLE_MEMO.pop(mk, None)
            if memo is None:
                memo = {}
            _SAMPLE_MEMO[mk] = memo                     # most recently used last
            while len(_SAMPLE_MEMO) > MAX_RUNNERS:      # the executables of the examples in flight
                _SAMPLE_MEMO.pop(next(iter(_SAMPLE_MEMO)))
        skeys = [json.dumps(s, sort_keys=True) for s in samples]
        todo = [i for i, sk in enumerate(skeys) if sk not in memo]
        if todo:
            ran = _run_batch(exe, spec, [samples[i] for i in todo], timeout_ms, tripcap, iso)
            with _MEMO_LOCK:
                for i, r in zip(todo, ran):
                    memo[skeys[i]] = {f: getattr(r, f) for f in _RUN_FIELDS}
        got = [memo[sk] for sk in skeys]
        save_runs("oracle", key, got)
    return [SampleRun(index=i, sample=s, **{f: (list(v) if isinstance(v, list) else v) for f, v in d.items()})
            for i, (s, d) in enumerate(zip(samples, got))]


_SAMPLE_MEMO: Dict[Tuple, Dict[str, Dict[str, Any]]] = {}
_MEMO_LOCK = threading.Lock()


_RUNS_VERSION = "oracle-runs-1"
_RUN_FIELDS = ("events", "outcome", "failed", "reason", "notes", "loops", "stdout", "effects")


def _run_batch(exe: Path, spec: DriverSpec, samples: Sequence[Dict[str, Any]], timeout_ms: int, tripcap: int,
               iso: bool, whole: bool = False) -> List[SampleRun]:
    from concurrent.futures import ThreadPoolExecutor
    n = 1 if whole else max(1, min(PARTS, _jobs_cap(), len(samples) // MIN_PART))
    if n == 1:
        return _runner(exe, 0).run(spec, samples, timeout_ms, tripcap, iso)
    parts = [list(range(j, len(samples), n)) for j in range(n)]
    with ThreadPoolExecutor(max_workers=n) as ex:
        done = list(ex.map(lambda jx: _runner(exe, jx[0]).run(spec, [samples[i] for i in jx[1]], timeout_ms,
                                                              tripcap, iso), enumerate(parts)))
    runs: List[Optional[SampleRun]] = [None] * len(samples)
    for ix, part in zip(parts, done):
        for i, r in zip(ix, part):
            r.index = i
            runs[i] = r
    return runs  # type: ignore[return-value]


def _pointer_samples(spec: DriverSpec, samples: Sequence[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """One sample per distinct (call, pointer arguments) of `samples`: the driver depends on nothing
    else of them (drivers.driver_source renders the pointer expressions only)."""
    from .drivers import parse_ctype
    ptr = {ci: [j for j, a in enumerate(c["args"]) if parse_ctype(a["ctype"]).kind == "p"]
           for ci, c in enumerate(spec.calls)}
    out: Dict[Any, Dict[str, Any]] = {}
    for s in samples:
        ci = s["call"]
        js = ptr.get(ci) if isinstance(ci, int) and not isinstance(ci, bool) else None
        key = (ci, tuple(s["args"][j] for j in js) if js is not None and len(s["args"]) == len(
            spec.calls[ci]["args"]) else json.dumps(s["args"], sort_keys=True))
        if key not in out:
            out[key] = {"call": ci, "args": s["args"]}
    return list(out.values())


def _trace_pairs(trace):
    """(index, event) of every `<index>\t<event JSON>` line of a trace (text or an open file), one line
    at a time."""
    lines = trace.split("\n") if isinstance(trace, str) else trace
    for line in lines:
        line = line.rstrip("\n")
        if not line:
            continue
        i, e = line.split("\t", 1)
        yield int(i), json.loads(e)


def _parse_runs(samples: Sequence[Dict[str, Any]], trace, status: str) -> List[SampleRun]:
    runs = [SampleRun(i, s) for i, s in enumerate(samples)]
    for i, e in _trace_pairs(trace):
        if i < 0:
            continue   # the driver's own setup, before any sample: no sample's event
        if e.get("ev") == "kloop":   # a T2 cutoff record, not a trace event
            del e["ev"]
            runs[i].loops.append(e)
        elif e.get("ev") == "stdout":   # host output (cq-e4jk), not a trace event
            runs[i].stdout = _bytes_text(e.get("s", ""))
        elif e.get("ev") == "effect":
            runs[i].effects.append({"name": e.get("name"), "args": [
                {"s": _bytes_text(a["s"])} if "s" in a else {"w": a.get("w"), "v": a.get("v")}
                for a in e.get("args", [])]})
        else:
            runs[i].events.append(e)
    for line in status.splitlines():
        i, n = line.split("\t", 1)
        if int(i) < 0:
            raise OracleError(f"oracle: the driver setup failed: {n}")
        runs[int(i)].notes.append(n)
    for r in runs:
        hang = next((n for n in r.notes if n.startswith("hang ")), None)
        if hang:
            raise OracleError(f"oracle: hang guard ({hang}) on sample {r.index} {json.dumps(r.sample)}: "
                              "the sample ran past the guard without reaching the trip cap")
    for r in runs:
        _classify(r)
    return runs


def _bytes_text(s: str) -> str:
    """A captured byte string (each byte one code point), decoded as UTF-8 as run.py decodes ours."""
    try:
        return s.encode("latin-1").decode("utf-8", errors="replace")
    except UnicodeEncodeError:
        return s


# cq_theta_<t> / cq_measure_<t> suffix (CQ.h) -> the register's rail type
_SITE_RAIL = {"i1": "i1", "c": "i8", "si8": "i8", "ui8": "i8", "si16": "i16", "ui16": "i16",
              "si32": "i32", "ui32": "i32", "sl": "i64", "ul": "i64", "sll": "i64", "ull": "i64",
              "f16": "f16", "bf16": "bf16", "f32": "f32", "f64": "f64", "f80": "f80"}
_SITE_CALL = re.compile(r'\bcall\b[^@]*@(cq_theta_\w+|cq_measure_\w+|cq_phi|__cq_invert_begin|__cq_invert_end)\(')
_DEFINE = re.compile(r'^define\b[^@]*@("(?:[^"\\]|\\.)*"|[-\w$.]+)\(')
_SITE_CACHE: Dict[Path, Dict[Tuple[str, int], str]] = {}


def site_callees(o1: Path) -> Dict[Tuple[str, int], str]:
    """(fn, site ordinal) -> the callee name of each site call in the input .O1.ll (T1.1 ordinals:
    textual order of the calls to cq_theta_*, cq_phi, cq_measure_*, __cq_invert_* within fn)."""
    o1 = Path(o1).resolve()
    if o1 in _SITE_CACHE:
        return _SITE_CACHE[o1]
    out: Dict[Tuple[str, int], str] = {}
    fn, k = None, 0
    for line in o1.read_text().splitlines():
        m = _DEFINE.match(line)
        if m:
            fn, k = m.group(1), 0
            if fn.startswith('"'):
                fn = fn[1:-1]
            continue
        if line.startswith("}"):
            fn = None
            continue
        if fn is None:
            continue
        c = _SITE_CALL.search(line)
        if c:
            out[(fn, k)] = c.group(1)
            k += 1
    _SITE_CACHE[o1] = out
    return out


def _measure_rail(o1: Path, fn: str, site: int) -> str:
    callee = site_callees(o1).get((fn, int(site)))
    if callee is None or not callee.startswith("cq_measure_"):
        raise OracleError(f"oracle: measure site {fn}:{site} is not a cq_measure_* call in {o1}")
    w = _SITE_RAIL.get(callee[len("cq_measure_"):])
    if w is None:
        raise OracleError(f"cq: unimplemented: oracle: rail type of {callee}")
    return w


def _typed_ret(spec: DriverSpec, sr: SampleRun) -> List[Dict[str, Any]]:
    """outputs["ret"] in run.py's encoding (T1.5): one record for an arithmetic or aggregate return
    of a sample that ended by return; none for void, pointer, or any other end."""
    from .run import ctype_kind
    if sr.outcome != "ret":
        return []
    ev = next((e for e in sr.events if e.get("ev") == "ret"), None)
    fn = spec.calls[sr.sample["call"]]["fn"]
    rt = _ret_ctype(spec, fn)
    kind, bits = ctype_kind(rt)
    if ev is None or ev.get("v") is None or rt == "void" or kind == "ptr":
        return []
    if rt in _FP_RAIL:
        v: Any = {"w": _FP_RAIL[rt], "v": ev["v"]}
    elif kind == "fp":
        v = {"w": f"f{bits}", "v": ev["v"]}
    elif kind == "int":
        v = {"w": f"i{bits}", "v": ev["v"]}
    else:
        v = ev["v"]   # an aggregate return: bare hex
    return [{"call": sr.sample["call"], "fn": fn, "v": v}]


def run_result(sr: SampleRun, spec: DriverSpec, o1: Path) -> RunResult:
    """A sample under the C oracle as the side 'c' RunResult (cq-arch T1.5).

    outputs: {"ret": [{"call", "fn", "v"}] in run.py's encoding (integer returns {"w": "i<N>"} at the
    C width, fp {"w": "f32"|"f64"|"f80"|...}, an aggregate bare hex; void, pointer and samples that
    did not return give no record), "end": outcome, "loops": the T2 cutoff records, "stdout": the
    program's stdout, "effects": its host-effect calls (cq-e4jk)}; measured: [{"h": None, "w": the register's rail
    type, "v": hex}] per reached measure site that is a gate (not a rule 2 classical read), in order; rotations: the site events of kind theta,
    phi, invert_begin and invert_end verbatim, in order; kept/clean: None (the C program has no
    rails); violations: [] or [{"what": "c_oracle", "h": None, "msg": reason}]."""
    measured, rotations = [], []
    for e in sr.events:
        if e.get("ev") != "site":
            continue
        if e["kind"] == "measure":
            measured.append({"h": None, "w": _measure_rail(o1, e["fn"], e["site"]), "v": e["reg"]})
        elif e["kind"] == "read":
            continue   # CR rule 2: a classical read of a collapsed value, no gate (cq-y1ll)
        else:
            rotations.append(dict(e))
    return RunResult(side="c", sample=sr.sample,
                     outputs={"ret": _typed_ret(spec, sr), "end": sr.outcome, "loops": list(sr.loops),
                              "stdout": sr.stdout, "effects": list(sr.effects)},
                     measured=measured, rotations=rotations, kept=None, clean=None,
                     violations=[{"what": "c_oracle", "h": None, "msg": sr.reason}] if sr.failed else [])


def run_sample(o1: Path, spec: DriverSpec, sample: dict) -> RunResult:
    """Z1 (cq-zew): one sample of the C program as RunResult side 'c'; RunResult.sample is `sample`."""
    return run_result(run_samples(Path(o1), spec, [sample])[0], spec, Path(o1))


def trace_sample(o1: Path, spec: DriverSpec, sample: dict) -> List[dict]:
    """Z1 (cq-zew): the oracle's events of one sample in order; raises OracleError with the reason
    when the sample cannot run (never a partial trace)."""
    r = run_samples(Path(o1), spec, [sample])[0]
    if r.failed:
        raise OracleError(f"oracle: sample {sample} cannot run: {r.reason}")
    return r.events


# ------------------------------------------------------------------------------------------------
# CLI

def _example_o1(arg: str) -> Path:
    p = Path(arg)
    if p.suffix == ".ll" and p.exists():
        return p
    d = SPEC / "examples" / arg
    base = arg.split("_", 1)[1]
    return d / f"{base}.O1.ll"


def main(argv: Optional[Sequence[str]] = None) -> int:
    import argparse
    from .contracts import from_json
    ap = argparse.ArgumentParser(prog="cqcheck.oracle", description=__doc__.split("\n\n")[0])
    ap.add_argument("program", help="NN_name of a CQ_spec example, or a .O1.ll")
    ap.add_argument("--driver", required=True, help="DriverSpec JSON file")
    ap.add_argument("--samples", required=True, help="SampleSet JSON file, or a JSON list of samples")
    ap.add_argument("--timeout-ms", type=int, default=DEFAULT_TIMEOUT_MS)
    ap.add_argument("--tripcap", type=int, default=DEFAULT_TRIPCAP)
    ap.add_argument("--k", default="", help="per-function cutoffs fn=k,... (cq-lower's -cq-k)")
    ap.add_argument("--k-default", type=int, help="global cutoff (cq-lower's -cq-k-default)")
    ap.add_argument("--json", help="write [{sample, outcome, failed, reason, notes, events, loops}] here")
    a = ap.parse_args(argv)
    kmap = {f: int(v) for f, v in (x.split("=", 1) for x in a.k.split(",") if x)}
    spec = from_json(DriverSpec, Path(a.driver).read_text())
    data = json.loads(Path(a.samples).read_text())
    samples = data["samples"] if isinstance(data, dict) else data
    runs = run_samples(_example_o1(a.program), spec, samples, a.timeout_ms, a.tripcap, kmap or None, a.k_default)
    out = [dataclasses.asdict(r) for r in runs]
    if a.json:
        Path(a.json).write_text(json.dumps(out, indent=1))
    failed = [r for r in runs if r.failed]
    for r in failed:
        print(f"FAIL sample {r.index}: {r.reason}", file=sys.stderr)
    print(f"{len(runs)} samples, {len(failed)} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
