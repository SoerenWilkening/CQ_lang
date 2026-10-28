"""The C oracle (cq-w0-chk-oracle): the example's .O1.ll run as the C program it is, under CR §2 and §6.

CLAUDE.md "The §6 checker", oracle (b): ``name.O1.ll`` with ``cq_theta``/``cq_measure`` as the
identity, logging each ``cq_theta``/``cq_phi`` call site reached and its angle. The program is linked
with a generated driver (and the injection bundle when ``bundle/manifest.json`` lists one), instrumented
by ``checker/oracle/OracleInstr.cpp`` (the ``cq-oracle`` opt pass) and linked with
``checker/oracle/cqo_rt.c``. Every sample runs in its own forked child from the pristine program
state, so a trap, an abort or a hang ends that sample only.

Trace events (cq-arch; values are hex bit patterns ``0x`` + lowercase digits, no leading zeros):

- ``{"ev":"site","fn","site","kind","angle","reg"}``: ``site`` is the ordinal of the call among the
  ``cq_theta_*``/``cq_phi``/``cq_measure_*``/``__cq_invert_*`` calls of function ``fn`` in textual order
  of the input IR. ``kind`` is ``theta``, ``phi``, ``measure`` (reg = the measured value) or
  ``invert_begin``/``invert_end`` (markers) (cq-arch T1.1). ``angle`` is the f64 bit pattern (null for
  measure and markers); ``reg`` the register value at its width (null for phi and markers).
- ``{"ev":"trip","loop","n"}`` once per loop activation, when the loop is left (T1.2). ``loop`` is
  ``<fn>:<header>``, the header block's label spelled as an operand in the input .O1.ll (``%7``,
  ``%for.body``), taken before the instrumentation edits the function. ``n`` counts the trips begun: header
  executions, less the final one when it only ran the exit test (an exit from a header that is not a
  latch). A guard branch whose other successor is an exit block reports ``n = 0`` when it skips the loop;
  the guard may reach the header directly or through single-predecessor blocks that branch
  unconditionally on (a preheader, as in 55).
- ``{"ev":"ret","v"}``: the driver call's return value (``null`` for void).

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
whose ``before_call``/``after_call`` fork one child per sample (cqo_rt.c). The driver reads the
samples at run time from ``drivers.sample_file`` in ``$CQD_SAMPLES`` (cq-arch Z2): one build per
example, and the samples run in up to ``PARTS`` runner processes in parallel. The driver discards the
call's result, so the instrumentation logs it at the IR call (``-cq-oracle-entries``). An optional
``"subst": {"<fn>:<site>": hex}`` replaces the register value at a ``cq_theta`` site each time it is
reached, or with a list ``[hex, ...]`` the r-th reach takes entry r mod len (cq-arch Z4, cq-6m2: CR §6
item 1, "each cq_theta input replaced by a chosen bit pattern"); it never reaches the driver. The
trace's ``reg`` of a substituted theta site is the chosen value. A site with no entry is the
identity.

Sample outcome: ``ret`` (returned), ``noreturn:<callee>`` (abort, exit, __builtin_trap, ...),
``raise:<sig>`` (the program raised a fatal signal), ``cap:<loop>`` (stopped after K trips). Anything else is a failure with a reason, never
dropped: ``unreachable`` reached, an out-of-bounds atomic, a timeout or the runaway trip cap, a signal no hook
explains (a trap the totalization should have prevented), a bad sample.

API: ``run_sample(o1, spec, sample) -> RunResult`` and ``trace_sample(o1, spec, sample) -> [event]``
(both frozen by Z1, cq-zew); ``run_samples(o1, spec, samples, ..., k=None, k_default=None) ->
[SampleRun]`` runs a whole batch and keeps failed samples' partial events.
CLI: ``python3 -m cqcheck.oracle <NN_name|O1.ll> [--samples JSON] [--driver JSON] [--json OUT]
[--k fn=k,...] [--k-default K]``.
"""
from __future__ import annotations

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
    for p in [SRC / "OracleInstr.cpp", SRC / "cqo_rt.c", STANDIN] + _pass_inputs():
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
        units = [cpp] + PASS_SOURCES
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


def program(o1: Path, k: Optional[Dict[str, int]] = None, k_default: Optional[int] = None) -> Tuple[Path, str]:
    """The instrumented program object of one .O1.ll (cached), and its target triple. k / k_default:
    the cutoff flags (default none: CQ_K, then 4)."""
    o1 = Path(o1)
    plugin, rt = toolchain()
    text = o1.read_text()
    bundle = _bundle_files()
    kf = _k_flags(k, k_default)
    key = hashlib.sha256("\0".join([text, SRC_KEY, *kf] + [f"{b}:{b.stat().st_mtime_ns}" for b in bundle])
                         .encode()).hexdigest()[:20]
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
        _run([_tool("opt"), f"-load-pass-plugin={plugin}", "-passes=cq-oracle",
              f"-cq-oracle-stubs={d / 'stubs.txt'}", *kf, str(linked), "-o", str(d / "prog.bc")],
             "the cq-oracle instrumentation of the program")
        _run([_tool("clang"), "-target", triple, "-O0", "-Wno-override-module", "-c", str(d / "prog.bc"),
              "-o", str(d / "prog.o")], "compiling the instrumented program")

    d = _atomic_dir(_build_root() / "prog" / f"{o1.stem}-{key}", fill)
    return d / "prog.o", triple


BEFORE_CALL = ("int __cqo_sample_begin(int); void __cqo_sample_end(void); "
               "if (__cqo_sample_begin(CQD_SAMPLE)) {")
AFTER_CALL = "__cqo_sample_end(); }"
DRIVER_MAIN = "__cqo_drv_main"


def _drivers():
    from . import drivers
    if getattr(drivers, "driver_source", None) is None:
        raise OracleError("cq: unimplemented: chk-drivers: drivers.driver_source")
    return drivers


def _driver_source(spec: DriverSpec, samples: Sequence[dict]) -> str:
    return _drivers().driver_source(spec, list(samples), before_call=BEFORE_CALL, after_call=AFTER_CALL,
                                    main_name=DRIVER_MAIN)


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
    elif wait == "wait timeout":
        sr.failed, sr.reason = True, "timeout"
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
    """Every sample in one oracle program; each sample's call runs in its own forked child.

    A sample may carry an optional "subst": {"<fn>:<site>": hex | [hex, ...]} (cq-arch Z4: the value
    each reach of a cq_theta site takes; a list gives reach r its entry r mod len); the driver ignores
    keys other than call and args."""
    if not samples:
        return []
    # Results are cached per (instrumented program, driver spec, sample, limits): a repeated run, or
    # run_sample over a SampleSet already run as a batch, costs no build.
    prog_o, _ = program(Path(o1), k, k_default)
    from .contracts import to_json
    base = "\0".join([str(prog_o), to_json(spec), str(timeout_ms), str(tripcap)])
    drivers = _drivers()
    base += "\0" + hashlib.sha256(Path(drivers.__file__).read_bytes()).hexdigest()   # the driver's shape
    keys = [hashlib.sha256("\0".join([base, drivers.sample_record(spec, s),
                                       json.dumps(s.get("subst"), sort_keys=True), str(SRC_KEY)])
                           .encode()).hexdigest()[:24] for s in samples]
    cache = _build_root() / "results"
    out: List[Optional[SampleRun]] = [None] * len(samples)
    todo = []
    for i, (s, key) in enumerate(zip(samples, keys)):
        f = cache / key[:2] / f"{key}.json"
        if f.exists():
            d = json.loads(f.read_text())
            out[i] = SampleRun(i, s, d["events"], d["outcome"], d["failed"], d["reason"], d["notes"],
                               d["loops"])
        else:
            todo.append(i)
    if todo:
        fresh = _run_uncached(Path(o1), spec, [samples[i] for i in todo], timeout_ms, tripcap, k, k_default)
        for i, r in zip(todo, fresh):
            r.index = i
            out[i] = r
            f = cache / keys[i][:2] / f"{keys[i]}.json"
            f.parent.mkdir(parents=True, exist_ok=True)
            tmp = f.with_suffix(f".{os.getpid()}.tmp")
            tmp.write_text(json.dumps({"events": r.events, "outcome": r.outcome, "failed": r.failed,
                                       "reason": r.reason, "notes": r.notes, "loops": r.loops}))
            os.replace(tmp, f)
    return out  # type: ignore[return-value]


def _jobs_cap() -> int:
    """$CQCHECK_JOBS when set (the machine-wide cap on parallel processes), else the CPU count."""
    try:
        j = int(os.environ.get("CQCHECK_JOBS", ""))
    except ValueError:
        j = 0
    return max(1, j) if j else (os.cpu_count() or 1)


# The samples run in up to PARTS runner processes at once (each forks one child per sample in turn):
# min(8, CPU count), and never more than $CQCHECK_JOBS; a part has at least MIN_PART samples.
PARTS = max(1, min(8, os.cpu_count() or 1, _jobs_cap()))
MIN_PART = 16


def _run_uncached(o1: Path, spec: DriverSpec, samples: Sequence[Dict[str, Any]], timeout_ms: int,
                  tripcap: int, k: Optional[Dict[str, int]] = None,
                  k_default: Optional[int] = None) -> List[SampleRun]:
    from concurrent.futures import ThreadPoolExecutor
    exe = executable(Path(o1), spec, [{"call": s["call"], "args": s["args"]} for s in samples], k, k_default)
    n = max(1, min(PARTS, len(samples) // MIN_PART))
    parts = [list(range(k, len(samples), n)) for k in range(n)]
    with ThreadPoolExecutor(max_workers=n) as ex:
        done = list(ex.map(lambda ix: _run_part(exe, spec, [samples[i] for i in ix], timeout_ms, tripcap),
                           parts))
    runs: List[Optional[SampleRun]] = [None] * len(samples)
    for ix, part in zip(parts, done):
        for i, r in zip(ix, part):
            r.index = i
            runs[i] = r
    return runs  # type: ignore[return-value]


def _run_part(exe: Path, spec: DriverSpec, samples: Sequence[Dict[str, Any]], timeout_ms: int,
              tripcap: int) -> List[SampleRun]:
    with tempfile.TemporaryDirectory(prefix="cqo-run.") as td:
        t = Path(td)
        (t / "samples").write_text(_drivers().sample_file(spec, samples))
        cmd = [str(exe), str(t / "trace"), str(t / "status"), str(timeout_ms), str(tripcap)]
        sub = _subst_lines(samples)
        if sub:
            (t / "subst").write_text("".join(l + "\n" for l in sub))
            cmd.append(str(t / "subst"))
        budget = (2 * timeout_ms + 1000) * len(samples) / 1000 + 60
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=budget,
                           env=dict(os.environ, **{_drivers().SAMPLES_ENV: str(t / "samples")}))
        if p.returncode != 0:
            raise OracleError(f"oracle: runner failed ({p.returncode}): {p.stderr.strip()[-2000:]}")
        runs = [SampleRun(i, s) for i, s in enumerate(samples)]
        for line in (t / "trace").read_text().splitlines():
            i, ev = line.split("\t", 1)
            if int(i) < 0:
                continue   # the driver's own setup, before any sample: no sample's event
            e = json.loads(ev)
            if e.get("ev") == "kloop":   # a T2 cutoff record, not a trace event
                del e["ev"]
                runs[int(i)].loops.append(e)
            else:
                runs[int(i)].events.append(e)
        for line in (t / "status").read_text().splitlines():
            i, n = line.split("\t", 1)
            if int(i) < 0:
                raise OracleError(f"oracle: the driver setup failed: {n}")
            runs[int(i)].notes.append(n)
    for r in runs:
        _classify(r)
    return runs


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
    did not return give no record), "end": outcome, "loops": the T2 cutoff records}; measured: [{"h": None, "w": the register's rail
    type, "v": hex}] per reached measure site, in order; rotations: the site events of kind theta,
    phi, invert_begin and invert_end verbatim, in order; kept/clean: None (the C program has no
    rails); violations: [] or [{"what": "c_oracle", "h": None, "msg": reason}]."""
    measured, rotations = [], []
    for e in sr.events:
        if e.get("ev") != "site":
            continue
        if e["kind"] == "measure":
            measured.append({"h": None, "w": _measure_rail(o1, e["fn"], e["site"]), "v": e["reg"]})
        else:
            rotations.append(dict(e))
    return RunResult(side="c", sample=sr.sample,
                     outputs={"ret": _typed_ret(spec, sr), "end": sr.outcome, "loops": list(sr.loops)},
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
