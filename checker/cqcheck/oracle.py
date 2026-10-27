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
  of the input IR. ``kind`` is ``theta`` or ``phi`` (frozen) and, as extensions pending a freeze-rule
  bead, ``measure`` (reg = the measured value) and ``invert_begin``/``invert_end`` (markers). ``angle``
  is the f64 bit pattern (null for measure and markers); ``reg`` the register value at its width
  (null for phi and markers).
- ``{"ev":"trip","loop","n"}`` once per loop activation, when the loop is left. ``loop`` is
  ``<fn>/<k>``, k the loop's index in LoopInfo preorder. ``n`` counts the trips begun: header
  executions, less the final one when it only ran the exit test (an exit from a header that is not a
  latch). A guard branch whose other successor is an exit block reports ``n = 0`` when it skips the loop.
- ``{"ev":"ret","v"}``: the driver call's return value (``null`` for void).

§2 and §6 in the C program: div/rem by 0 and INT_MIN/-1, shifts >= W (amount mod W), fptosi/fptoui
(row by row), maxnum/minnum, fmuladd unfused, abs(INT_MIN), ctlz/cttz(0) are rewritten to the table;
allocas, lifetime starts and heap blocks read 0 until written; a load outside every object (globals,
allocas, heap blocks) reads 0 and a store there is dropped. Threads collapse (rule 24).

A function nothing defines (after libc/libm) gets the checker's model (OracleInstr.cpp ``stubs``):
FNV-1a-64 over the name bytes, then ``h = (h ^ w) * 0x100000001b3`` per 64-bit word of each non-pointer
argument; the result is the low W bits; no memory effect.

Samples are Z1's ``{"call", "args"}`` (SampleSet.samples entries); the driver is rendered only by
``drivers.driver_source(spec, samples, before_call=..., after_call=..., main_name="__cqo_drv_main")``,
whose ``before_call``/``after_call`` fork one child per sample (cqo_rt.c). The driver discards the
call's result, so the instrumentation logs it at the IR call (``-cq-oracle-entries``). An optional
``"subst": {"<fn>:<site>": hex}`` replaces the register value at a ``cq_theta`` site each time it is
reached (for usercheck); it never reaches the driver.

Sample outcome: ``ret`` (returned), ``noreturn:<callee>`` (abort, exit, __builtin_trap, ...),
``raise:<sig>`` (the program raised a fatal signal). Anything else is a failure with a reason, never
dropped: ``unreachable`` reached, an out-of-bounds atomic, a timeout or trip cap, a signal no hook
explains (a trap the totalization should have prevented), a bad sample.

API: ``run_sample(o1, spec, sample) -> RunResult`` and ``trace_sample(o1, spec, sample) -> [event]``
(both frozen by Z1, cq-zew); ``run_samples(o1, spec, samples) -> [SampleRun]`` builds one program for
a whole batch (one build instead of one per sample) and keeps failed samples' partial events.
CLI: ``python3 -m cqcheck.oracle <NN_name|O1.ll> [--samples JSON] [--driver JSON] [--json OUT]``.
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

SRC_KEY = hashlib.sha256((SRC / "OracleInstr.cpp").read_bytes() + (SRC / "cqo_rt.c").read_bytes()
                         + Path(__file__).read_bytes()).hexdigest()[:16]


def toolchain() -> Tuple[Path, Path]:
    cpp, rt = SRC / "OracleInstr.cpp", SRC / "cqo_rt.c"
    h = hashlib.sha256(cpp.read_bytes() + b"\0" + rt.read_bytes()).hexdigest()[:16]

    def fill(d: Path) -> None:
        flags = _run([_tool("llvm-config"), "--cxxflags"], "llvm-config").stdout.split()
        _run([_tool("clang++"), *flags, "-fno-rtti", "-fPIC", "-shared", "-undefined", "dynamic_lookup",
              "-O1", str(cpp), "-o", str(d / "libCQOracle.so")], "building the oracle plugin")
        _run([_tool("clang"), "-std=c17", "-O1", "-c", str(rt), "-o", str(d / "cqo_rt.o")],
             "building the oracle runtime")

    d = _atomic_dir(_build_root() / f"tool-{h}", fill)
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


def program(o1: Path) -> Tuple[Path, str]:
    """The instrumented program object of one .O1.ll (cached), and its target triple."""
    o1 = Path(o1)
    plugin, rt = toolchain()
    text = o1.read_text()
    bundle = _bundle_files()
    key = hashlib.sha256("\0".join([text, SRC_KEY] + [f"{b}:{b.stat().st_mtime_ns}" for b in bundle])
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
              f"-cq-oracle-stubs={d / 'stubs.txt'}", str(linked), "-o", str(d / "prog.bc")],
             "the cq-oracle instrumentation of the program")
        _run([_tool("clang"), "-target", triple, "-O0", "-Wno-override-module", "-c", str(d / "prog.bc"),
              "-o", str(d / "prog.o")], "compiling the instrumented program")

    d = _atomic_dir(_build_root() / "prog" / f"{o1.stem}-{key}", fill)
    return d / "prog.o", triple


BEFORE_CALL = ("int __cqo_sample_begin(int); void __cqo_sample_end(void); "
               "if (__cqo_sample_begin(CQD_SAMPLE)) {")
AFTER_CALL = "__cqo_sample_end(); }"
DRIVER_MAIN = "__cqo_drv_main"


def _driver_source(spec: DriverSpec, samples: Sequence[dict]) -> str:
    from . import drivers
    fn = getattr(drivers, "driver_source", None)
    if fn is None:
        raise OracleError("cq: unimplemented: chk-drivers: drivers.driver_source")
    return fn(spec, list(samples), before_call=BEFORE_CALL, after_call=AFTER_CALL, main_name=DRIVER_MAIN)


def executable(o1: Path, spec: DriverSpec, samples: Sequence[dict]) -> Path:
    """The oracle program for these samples: instrumented program + instrumented driver + runtime."""
    prog_o, triple = program(o1)
    plugin, rt = toolchain()
    src = _driver_source(spec, samples)
    entries = sorted({spec.calls[s["call"]]["fn"] for s in samples})
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
    outcome: str = ""            # ret | noreturn:<callee> | raise:<sig> | "" when failed
    failed: bool = False
    reason: str = ""
    notes: List[str] = field(default_factory=list)


def _classify(sr: SampleRun) -> None:
    notes = sr.notes
    wait = next((n for n in reversed(notes) if n.startswith("wait ")), "wait missing")
    bad = [n for n in notes if n.startswith(("ub ", "crash ", "tripcap"))]
    noret = [n for n in notes if n.startswith("noreturn ")]
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
    elif noret:
        sr.outcome = "noreturn:" + noret[-1].split(" ", 1)[1]
    elif raised and wait.startswith("wait signaled ") and raised[-1].split()[1] == wait.split()[2]:
        sr.outcome = "raise:" + raised[-1].split()[1]
    else:
        sr.failed, sr.reason = True, f"{wait} with no explaining note (a trap the oracle did not totalize)"


def _subst_lines(samples: Sequence[dict]) -> List[str]:
    out = []
    for i, s in enumerate(samples):
        for k, val in (s.get("subst") or {}).items():
            fn, site = k.rsplit(":", 1)
            v = int(val, 16) if isinstance(val, str) else int(val)
            words = [v & ((1 << 64) - 1)] + ([v >> 64] if v >> 64 else [])
            out.append(f"{i} {fn} {int(site)} {len(words)} " + " ".join(f"{w:x}" for w in words))
    return out


def run_samples(o1: Path, spec: DriverSpec, samples: Sequence[Dict[str, Any]],
                timeout_ms: int = DEFAULT_TIMEOUT_MS, tripcap: int = DEFAULT_TRIPCAP) -> List[SampleRun]:
    """Every sample in one oracle program; each sample's call runs in its own forked child.

    A sample may carry an optional "subst": {"<fn>:<site>": hex} (usercheck: the value a cq_theta
    site takes); the driver ignores keys other than call and args."""
    if not samples:
        return []
    # Results are cached per (instrumented program, driver spec, sample, limits): a repeated run, or
    # run_sample over a SampleSet already run as a batch, costs no build.
    prog_o, _ = program(Path(o1))
    from .contracts import to_json
    base = "\0".join([str(prog_o), to_json(spec), str(timeout_ms), str(tripcap)])
    keys = [hashlib.sha256("\0".join([base, _driver_source(spec, [{"call": s["call"], "args": s["args"]}]),
                                       json.dumps(s.get("subst"), sort_keys=True), str(SRC_KEY)])
                           .encode()).hexdigest()[:24] for s in samples]
    cache = _build_root() / "results"
    out: List[Optional[SampleRun]] = [None] * len(samples)
    todo = []
    for i, (s, k) in enumerate(zip(samples, keys)):
        f = cache / k[:2] / f"{k}.json"
        if f.exists():
            d = json.loads(f.read_text())
            out[i] = SampleRun(i, s, d["events"], d["outcome"], d["failed"], d["reason"], d["notes"])
        else:
            todo.append(i)
    if todo:
        fresh = _run_uncached(Path(o1), spec, [samples[i] for i in todo], timeout_ms, tripcap)
        for i, r in zip(todo, fresh):
            r.index = i
            out[i] = r
            f = cache / keys[i][:2] / f"{keys[i]}.json"
            f.parent.mkdir(parents=True, exist_ok=True)
            tmp = f.with_suffix(f".{os.getpid()}.tmp")
            tmp.write_text(json.dumps({"events": r.events, "outcome": r.outcome, "failed": r.failed,
                                       "reason": r.reason, "notes": r.notes}))
            os.replace(tmp, f)
    return out  # type: ignore[return-value]


def _run_uncached(o1: Path, spec: DriverSpec, samples: Sequence[Dict[str, Any]], timeout_ms: int,
                  tripcap: int) -> List[SampleRun]:
    exe = executable(Path(o1), spec, [{"call": s["call"], "args": s["args"]} for s in samples])
    with tempfile.TemporaryDirectory(prefix="cqo-run.") as td:
        t = Path(td)
        cmd = [str(exe), str(t / "trace"), str(t / "status"), str(timeout_ms), str(tripcap)]
        sub = _subst_lines(samples)
        if sub:
            (t / "subst").write_text("".join(l + "\n" for l in sub))
            cmd.append(str(t / "subst"))
        budget = (2 * timeout_ms + 1000) * len(samples) / 1000 + 60
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=budget)
        if p.returncode != 0:
            raise OracleError(f"oracle: runner failed ({p.returncode}): {p.stderr.strip()[-2000:]}")
        runs = [SampleRun(i, s) for i, s in enumerate(samples)]
        for line in (t / "trace").read_text().splitlines():
            i, ev = line.split("\t", 1)
            runs[int(i)].events.append(json.loads(ev))
        for line in (t / "status").read_text().splitlines():
            i, n = line.split("\t", 1)
            if int(i) < 0:
                raise OracleError(f"oracle: the driver setup failed: {n}")
            runs[int(i)].notes.append(n)
    for r in runs:
        _classify(r)
    return runs


def run_result(sr: SampleRun, spec: DriverSpec) -> RunResult:
    """A sample under the C oracle as the side 'c' RunResult.

    outputs: {"ret": value, "end": outcome}, an fp return typed as {"w": "f32"|"f64"|"f80"|..., "v": hex}
    (cq-pq3), an integer return as its hex, void as None; measured: the measure sites' values in order;
    rotations: the theta/phi sites reached, in order, with the invert markers ({"gate": "ry"|"phase"|
    "invert_begin"|"invert_end", "fn", "site", "angle", "reg"}); kept/clean: None (the C program has no
    rails); violations: [] or the failure reason."""
    ret = next((e["v"] for e in sr.events if e.get("ev") == "ret"), None)
    rt = _ret_ctype(spec, spec.calls[sr.sample["call"]]["fn"])
    if ret is not None and rt in _FP_RAIL:
        ret = {"w": _FP_RAIL[rt], "v": ret}
    measured, rotations = [], []
    gate = {"theta": "ry", "phi": "phase", "invert_begin": "invert_begin", "invert_end": "invert_end"}
    for e in sr.events:
        if e.get("ev") != "site":
            continue
        if e["kind"] == "measure":
            measured.append(e["reg"])
        else:
            rotations.append({"gate": gate[e["kind"]], "fn": e["fn"], "site": e["site"],
                              "angle": e["angle"], "reg": e["reg"]})
    return RunResult(side="c", sample=sr.sample, outputs={"ret": ret, "end": sr.outcome},
                     measured=measured, rotations=rotations, kept=None, clean=None,
                     violations=[sr.reason] if sr.failed else [])


def run_sample(o1: Path, spec: DriverSpec, sample: dict) -> RunResult:
    """Z1 (cq-zew): one sample of the C program as RunResult side 'c'; RunResult.sample is `sample`."""
    return run_result(run_samples(Path(o1), spec, [sample])[0], spec)


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
    ap.add_argument("--json", help="write [{sample, outcome, failed, reason, notes, events}] here")
    a = ap.parse_args(argv)
    spec = from_json(DriverSpec, Path(a.driver).read_text())
    data = json.loads(Path(a.samples).read_text())
    samples = data["samples"] if isinstance(data, dict) else data
    runs = run_samples(_example_o1(a.program), spec, samples, a.timeout_ms, a.tripcap)
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
