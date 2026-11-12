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
- ``{"ev":"effect","name","args"}`` (cq-e4jk, rulings Q8): a call of a host-effect function
  (compare.HOST_EFFECTS: raise, real, ``args``) or any other direct host call (drivers.effect_callees),
  which is that log and §6's stand-in, never the real call (fx_call.h, ``fields``: an INPUT call stores the
  stand-in's bytes). A field is ``{"w": "i<N>", "v": hex[, "p": 1][, "cap": str]}``: a value at its
  width, a pointer ("p"), the bytes it reads ("cap").
- ``{"ev":"out_mem","name","addr","w","v"}`` (CR §6 item 1, drivers.py "Driver objects"): a named
  output in memory after the driver call, ``v`` its bytes little-endian; ``{"ev":"object","name",
  "addr","size"}``, ``{"ev":"region","name","lo","hi"}``: the addresses that read a pointer value
  relationally (compare.py "Pointers"); ``{"ev":"allocs","n"}``: the sample's heap blocks. They go to
  side 'c' outputs["mem"], ["objects"], ["regions"], ["allocs"], never to ``SampleRun.events``.
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
allocas and heap blocks read 0 until written, a lifetime start changes nothing (a block-scoped object
re-entered by a loop holds what the trip before left there: rule 20's one block, rulings Q16), and no
address of a heap block comes back; a load outside every object (globals,
allocas, heap blocks, byval parameter copies, the register save and overflow areas va_start points
at) reads 0 and a store there is dropped. Threads collapse (rule 24).

A rule 27 root (the `roots=` field of drivers.txt) or another function neither libc nor the driver defines and
drivers.effect_callees leaves gets the checker's model (OracleInstr.cpp ``stubs``):
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
dropped: ``unreachable`` reached (a failure of the oracle run; the sampler keeps no such input, its probe ends the sample at the instruction as undefined, cq-by8qu), an out-of-bounds atomic, the runaway trip cap, a signal no hook
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
import contextlib
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
                PASS / "lib" / "Common.cpp", PASS / "lib" / "abi" / "Abi.cpp", PASS / "lib" / "calls" / "LibCalls.cpp"]


def _pass_inputs() -> List[Path]:
    hdrs = sorted((PASS / "include").rglob("*.h")) + sorted(
        p for d in ("taint", "spine", "abi") for p in (PASS / "lib" / d).glob("*.h")) + [PASS / "lib" / "calls" / "LibCalls.h"]
    return PASS_SOURCES + hdrs


def _src_hash() -> str:
    h = hashlib.sha256()
    for p in [SRC / "OracleInstr.cpp", SRC / "TripFacts.cpp", SRC / "cqo_rt.c", SRC / "fx_call.h", STANDIN,
              STANDIN.with_name("fx_standin.h")] + _pass_inputs():
        h.update(str(p.relative_to(ROOT)).encode() + b"\0" + p.read_bytes() + b"\0")
    return h.hexdigest()[:16]


TOOL_KEY = _src_hash()
# drivers.py writes the named outputs' reader into the built program (out_globals_ir).
SRC_KEY = hashlib.sha256((TOOL_KEY + "\0").encode() + Path(__file__).read_bytes() +
                         (Path(__file__).parent / "drivers.py").read_bytes()).hexdigest()[:16]


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


_LIBM_INTRINSIC = re.compile(r'^declare\b[^@]*@llvm\.(exp|exp2|exp10|log|log2|log10|sin|cos|tan|asin|acos|atan|sinh|cosh|'
                             r'tanh|pow)\.(f32|f64|f80)\(', re.M)
_LIBM_TYPE = {"f32": ("float", "f"), "f64": ("double", ""), "f80": ("x86_fp80", "l")}


def _libm_intrinsics(ll_text: str) -> List[Tuple[str, str]]:
    """The libm functions the module's LLVM math intrinsics stand for (CR rule 18): (name, its declaration)."""
    out = []
    for op, t in _LIBM_INTRINSIC.findall(ll_text):
        ty, sfx = _LIBM_TYPE[t]
        params = f"{ty}, {ty}" if op == "pow" else ty
        out.append((op + sfx, f"declare {ty} @{op}{sfx}({params})\n"))
    return out


def bundle_libm_decls(ll_text: str, bundle: Sequence[Path]) -> str:
    """One small IR unit, linked before `--only-needed`, that makes it link the bundle's body of each libm function an
    intrinsic of the module stands for (rule 18: lifted from its body whenever the module has one after injection), which
    no call names: declarations held by @llvm.compiler.used (llvm-link drops an unused declaration). "" when none."""
    defined = set()
    for b in bundle:
        defined |= set(_bundle_info(Path(b))[0])
    mach = "-apple-" in _triple(ll_text)
    declared = {(a or b).strip('"') for a, b in _DECLARED.findall(ll_text)}
    want = [(n, d) for n, d in _libm_intrinsics(ll_text) if ("_" + n if mach else n) in defined and n not in declared]
    if not want:
        return ""
    head = "".join(l + "\n" for l in ll_text.splitlines() if l.startswith(("target datalayout", "target triple")))
    used = ", ".join(f"ptr @{n}" for n, _ in want)
    return (head + "".join(d for _, d in want) + f"@llvm.compiler.used = appending global [{len(want)} x ptr] [{used}], "
            'section "llvm.metadata"\n')


def bundle_for(ll_text: str) -> List[Path]:
    """The injection bundle files to link into a module (cq-b041; CR rule 18, CLAUDE.md "Pipeline"):
    every bundle/manifest.json file, linked --only-needed, when the module declares without a body
    at least one symbol the bundle defines; otherwise none, and the module is used as clang wrote it."""
    bundle = _bundle_files()
    if not bundle:
        return []
    names = {(a or b).strip('"') for a, b in _DECLARED.findall(ll_text)}
    names |= {n for n, _ in _libm_intrinsics(ll_text)}
    if "-apple-" in _triple(ll_text):  # Mach-O symbol names carry a leading underscore
        names = {"_" + n for n in names}
    if any(names & _bundle_info(b)[0] for b in bundle):
        return bundle
    return []


# CR rule 16's stream calls by C name, as pass/lib/Common.cpp streamName lists them: every <stdio.h> function and the
# five POSIX descriptor calls, never the string formatters. Only a prefilter for host_streams: the plugin decides.
_STREAM_NAMES = frozenset((
    "fopen freopen fclose fflush setbuf setvbuf fprintf printf vfprintf vprintf fscanf scanf vfscanf vscanf fgetc getc "
    "getchar fgets gets fputc putc putchar fputs puts ungetc fread fwrite fgetpos fseek fsetpos ftell rewind clearerr "
    "feof ferror perror remove rename tmpfile tmpnam getline getdelim fdopen fileno popen pclose fseeko ftello dprintf "
    "vdprintf flockfile funlockfile ftrylockfile getc_unlocked getchar_unlocked putc_unlocked putchar_unlocked ctermid "
    "fmemopen open_memstream renameat tempnam open close read write lseek "
    # cq-ojgho: the <wchar.h> stream functions (pass/lib/Common.cpp streamName)
    "fwprintf wprintf vfwprintf vwprintf fwscanf wscanf vfwscanf vwscanf fgetwc fgetws fputwc fputws fwide getwc getwchar "
    "putwc putwchar ungetwc open_wmemstream").split())
_DEFINED = re.compile(r'(?m)^define\b[^@\n]*@("[^"]*"|[-A-Za-z$._0-9]+)\(')


def host_streams(text: str) -> str:
    """cq-8bq66 (CR rule 16): the C program with every stream call the module defines made a declaration, so a call of it
    by name is the host's function, as on the lowered side, where it is rule 16's host boundary and its body is never
    lifted for the call (BACKEND_ABI §1.11: the backend performs the entry with the host C library). Recognised by name
    and signature as cq-lower does (OracleInstr.cpp, cq-oracle-host-streams). A module that defines none is text as it
    stands. cq-tgl3i: what only those bodies reached goes too (musl's __stdin_FILE, its buffer, its locks: the host
    library's objects, CR rule 16, no named output of the program's, §6 item 1), as it goes from the lowered module."""
    from . import drivers
    if not {drivers._c_name(n) for n in _DEFINED.findall(text)} & _STREAM_NAMES:
        return text
    plugin, _ = toolchain()
    with tempfile.TemporaryDirectory(prefix="cqo-streams.") as d:
        src, dst = Path(d) / "in.ll", Path(d) / "out.ll"
        src.write_text(text)
        _run([_tool("opt"), f"-load-pass-plugin={plugin}", "-passes=cq-oracle-host-streams", "-S", str(src), "-o", str(dst)],
             "the stream calls' bodies (cq-oracle-host-streams)")
        return dst.read_text()


# Owner ruling 2026-11-12 (item 4): the C library output calls whose result the C program reads take musl's value
# (OracleInstr.cpp cq-oracle-output-results; the names of pass/lib/eff/tape/Tape.cpp outputFunction).
_OUTPUT_NAMES = frozenset((
    "printf fprintf dprintf vprintf vfprintf vdprintf wprintf fwprintf vwprintf vfwprintf puts fputs fflush putw fputc putc "
    "putchar fwrite fputwc putwc putwchar fputws").split())
_DECLARED_ANY = re.compile(r'(?m)^declare\b[^@\n]*@("[^"]*"|[-A-Za-z$._0-9]+)\(')


def _entries_mod():
    import importlib.util
    spec = importlib.util.spec_from_file_location("cq_entries", ROOT / "driver" / "cq_entries.py")
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


def output_results(text: str) -> str:
    """The C program with every read result of a C library output call replaced by musl's value when every write
    succeeds (owner ruling 2026-11-12 item 4): the closed forms inline, the counts by the bundle's result entries
    (bundle/recipe.json "entries"), which program() links from the bundle and runs natively. The call stays: it is the
    write. A module that declares no such function is text as it stands."""
    from . import drivers
    names = {drivers._c_name(n) for n in _DECLARED_ANY.findall(text)}
    if not {n[:-len("_unlocked")] if n.endswith("_unlocked") else n for n in names} & _OUTPUT_NAMES:
        return text
    plugin, _ = toolchain()
    with tempfile.TemporaryDirectory(prefix="cqo-outres.") as d:
        src, dst = Path(d) / "in.ll", Path(d) / "out.ll"
        src.write_text(text)
        _run([_tool("opt"), f"-load-pass-plugin={plugin}", "-passes=cq-oracle-output-results", "-S", str(src), "-o", str(dst)],
             "the output calls' results (cq-oracle-output-results)")
        return dst.read_text()


def entries_bundle(text: str) -> List[Path]:
    """The bundle files to link for the result entries text needs and does not define (cq_entries.needed)."""
    need = _entries_mod().needed(text)
    defined = set(_DEFINED.findall(text))
    return _bundle_files() if [n for n in need if n not in defined and f'"{n}"' not in defined] else []


def _internalize_bundle(path: Path, triple: str) -> None:
    """The bundle's definitions the program holds (musl's vsnprintf, memcpy, ...) made internal after the
    instrumentation: external, they interpose on the host C library the oracle runtime calls (cqo_rt.c note()'s
    vsnprintf ran musl's instrumented body on the runtime's own buffer, outside every object of the program: its stores
    dropped, the status notes garbage). The program reaches them by its own calls as before; the instrumentation (and
    its taint) ran on the module as linked. Nothing changes for a module that defines no bundle symbol."""
    names = set()
    for b in _bundle_files():
        names |= set(_bundle_info(Path(b))[0])
    if "-apple-" in triple:
        names = {n[1:] for n in names if n.startswith("_")}
    text = path.read_text()
    defined = {n.strip('"') for n in re.findall(r'(?m)^define\b[^@\n]*@("[^"]*"|[-A-Za-z$._0-9]+)\(', text)}
    defined |= {n.strip('"') for n in re.findall(r'(?m)^@("[^"]*"|[-A-Za-z$._0-9]+) = (?!(?:private|internal)\b)', text)}
    if not defined & names:
        return
    keep = sorted(defined - names)
    lst = path.with_name("public.txt")
    lst.write_text("".join(n + "\n" for n in keep))
    _run([_tool("opt"), "-S", "-passes=internalize", f"-internalize-public-api-file={lst}", str(path), "-o", str(path)],
         "internalizing the bundle's definitions in the oracle program")


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
_PROVIDED = re.compile(r"^(llvm\.|__cqo_|cqd_fx_|cqd_in_|cq_theta_|cq_measure_|cq_phi$|__cq_invert_)")


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


K2_DEFAULT = 4096        # CR §0: CQ_K2(f, k), -cq-k2, -cq-k2-default, 4096
_K2_ALLOC = {"malloc": "__cqo_malloc_k2", "calloc": "__cqo_calloc_k2", "aligned_alloc": "__cqo_aligned_alloc_k2",
             "realloc": "__cqo_realloc_k2"}


def _k2_sites(text: str, o1_text: str) -> str:
    """Rulings Q16, CR §6: a rail-sized allocation is made at K2 bytes, and an access at or beyond byte K2 is
    outside the block (cqo_rt.c totalizes it). Each allocation whose size derives, by SSA or through a defined
    callee's parameter, from a cq_theta result, a load (rule 3: every load is a rail) or a call result, goes to
    the runtime's _k2 entry with K2 as a last argument. A size no such value reaches is classical. An allocator
    with a body in the module is no such allocation (the pass lowers its body: bus hostAllocKind)."""
    import tempfile
    from . import drivers
    with tempfile.NamedTemporaryFile("w", suffix=".ll") as t:
        t.write(o1_text)
        t.flush()
        mod = drivers.read_module(Path(t.name))
    tainted: Dict[str, set] = {f: set() for f in mod.functions}
    changed = True
    while changed:
        changed = False
        for f in mod.functions.values():
            s = tainted[f.name]
            for ins in f.insts():
                hit = False
                if ins.dest and ins.dest not in s:
                    if ins.op == "load" or (ins.op == "call" and ins.callee not in mod.functions):
                        hit = not (ins.callee or "").startswith("@llvm.") or any(r in s for r in ins.refs())
                    elif ins.op not in ("alloca", "getelementptr") or any(r in s for r in ins.refs()):
                        hit = any(r in s for r in ins.refs())
                    if ins.op == "call" and ins.callee in mod.functions:
                        g = mod.functions[ins.callee]
                        hit = hit or any(r in tainted[g.name] for j in g.insts() if j.op == "ret" for r in j.refs())
                if hit:
                    s.add(ins.dest)
                    changed = True
                if ins.op == "call" and ins.callee in mod.functions:
                    g = mod.functions[ins.callee]
                    for i, a in enumerate(ins.call_args):
                        if i < len(g.params) and g.params[i][1] and g.params[i][1] not in tainted[g.name] \
                                and any(r in s for r in drivers.locals_in(a)):
                            tainted[g.name].add(g.params[i][1])
                            changed = True
    sized = {"malloc": [0], "calloc": [0, 1], "aligned_alloc": [1], "realloc": [1]}
    lines = text.splitlines()
    fname = None
    used = set()
    for li, line in enumerate(lines):
        m = re.match(r'define [^@]*(@(?:"[^"]*"|[-A-Za-z$._0-9]+))\(', line)
        if m:
            fname = m.group(1)
        m = re.search(r"@(malloc|calloc|aligned_alloc|realloc)\(", line)
        if not m or line.startswith(("declare", "define")) or fname not in tainted:
            continue
        name = m.group(1)
        if "@" + name in mod.functions:
            continue   # a body in the module (injected source) is code like any other, as OracleInstr's replaceLibrary
        start = m.end() - 1
        args = drivers.split_operands(drivers._balanced(line, start))
        if not any(r in tainted[fname] for i in sized[name] for r in drivers.locals_in(args[i])):
            continue
        fm = re.search(r"@__cq_k2_" + re.escape(fname[1:]) + r"\s*=[^\n]*?\bi64 (\d+)", o1_text)
        k2 = int(fm.group(1)) if fm else K2_DEFAULT
        end = start + len(drivers._balanced(line, start)) + 2
        lines[li] = line[:m.start()] + f"@{_K2_ALLOC[name]}(" + ", ".join(args + [f"i64 {k2}"]) + ")" + line[end:]
        used.add(name)
    decls = {"malloc": "declare noalias ptr @__cqo_malloc_k2(i64, i64)", "calloc": "declare noalias ptr @__cqo_calloc_k2(i64, i64, i64)",
             "aligned_alloc": "declare noalias ptr @__cqo_aligned_alloc_k2(i64, i64, i64)",
             "realloc": "declare ptr @__cqo_realloc_k2(ptr, i64, i64)"}
    return "\n".join(lines + [decls[n] for n in sorted(used)]) + "\n"


def program(o1: Path, k: Optional[Dict[str, int]] = None, k_default: Optional[int] = None,
            defined: Sequence[str] = ()) -> Tuple[Path, str]:
    """The instrumented program object of one .O1.ll (cached), and its target triple. k / k_default:
    the cutoff flags (default none: CQ_K, then 4). defined: the functions the driver line defines (203's
    ext_fill): neither stand-in nor model; the driver's body is linked. Beside the object, fx.o: the direct
    host calls' wrappers, apart from the instrumented module, so a callee stays bodiless for its taint."""
    o1 = Path(o1)
    st = o1.stat()
    memo = (str(o1.resolve()), st.st_mtime_ns, repr((sorted((k or {}).items()), k_default, sorted(defined), os.environ.get("CQ_ROOTS_EXTRA"))))
    if memo in _PROGRAMS and _PROGRAMS[memo][0].exists():
        return _PROGRAMS[memo]
    plugin, rt = toolchain()
    text = o1.read_text()
    bundle = bundle_for(text) or entries_bundle(text)
    kf = _k_flags(k, k_default)
    from . import drivers as _drv
    key = hashlib.sha256("\0".join([text, SRC_KEY, *kf, *sorted(defined), *sorted(_drv.corpus_roots()),
                                   *sorted(_drv.effect_callees(text, frozenset(defined) | _drv.corpus_roots()))] + ([bundle_key(bundle)] if bundle else [])).encode()).hexdigest()[:20]
    triple = _triple(text)

    def fill(d: Path) -> None:
        linked = d / "linked.bc"
        # no direct host call runs for real (rulings Q8)
        from . import drivers
        host = host_streams(text)    # cq-8bq66: a stream call by name is the host's, whatever the module defines
        host = output_results(host)  # owner ruling 2026-11-12: an output call's result is musl's, the call the write
        host = drivers.route_scans(host)   # cq-tgl3i: the scanf family, the host's on the checker's empty input
        callees = drivers.effect_callees(host, frozenset(defined) | drivers.corpus_roots())
        renamed = _k2_sites(drivers.rename_effects(host, callees), host)
        decls = "".join(f"declare {r} @{drivers.FX_PREFIX}{c}({p})\n" for c, (_, r, p) in callees.items())
        (d / "prog.ll").write_text(renamed + decls)
        (d / "fx.ll").write_text(f'target triple = "{triple}"\n' + drivers.effect_wrappers_ir(callees))
        _run([_tool("clang"), "-target", triple, "-O0", "-Wno-override-module", "-c", str(d / "fx.ll"), "-o", str(d / "fx.o")],
             "compiling the host calls' wrappers")
        _run([_tool("llvm-as"), str(d / "prog.ll"), "-o", str(linked)], "llvm-as")
        if bundle:
            libm = bundle_libm_decls(text, bundle)
            (d / "libm.ll").write_text(libm)
            _run([_tool("llvm-link"), str(linked), *([str(d / "libm.ll")] if libm else []), "--only-needed",
                  *map(str, bundle), "-o", str(linked)],
                 "llvm-link with the injection bundle")
        und = _run([_tool("llvm-nm"), "--undefined-only", "--format=just-symbols", str(linked)],
                   "llvm-nm").stdout.split()
        if "-apple-" in triple:  # Mach-O symbol names carry a leading underscore
            und = [n[1:] if n.startswith("_") else n for n in und]
        stubs = sorted(n for n in und if not _PROVIDED.match(n) and not _host_defines(n) and n not in defined)
        (d / "stubs.txt").write_text("".join(n + "\n" for n in stubs))
        iso = sorted(set(und) & _ISOLATE) + (["thread_local"] if "thread_local" in text else [])
        (d / "isolate.txt").write_text("".join(n + "\n" for n in iso))
        _run([_tool("opt"), f"-load-pass-plugin={plugin}", "-passes=cq-oracle",
              f"-cq-oracle-stubs={d / 'stubs.txt'}", *kf, "-S", str(linked), "-o", str(d / "prog.inst.ll")],
             "the cq-oracle instrumentation of the program")
        # the named outputs' reader joins after the instrumentation: its uses of the globals' addresses
        # are no escape of the program's (rule 2's collapse reads them), and its accesses no program access
        inst = (d / "prog.inst.ll").read_text()
        inst += drivers.out_globals_ir(text, inst, "__cqo_out_globals", "__cqo_out_mem", "__cqo_out_object")
        # the same objects by address alone, for a sample that ends before its outputs (BEFORE_CALL)
        (d / "prog.inst.ll").write_text(inst + drivers.out_globals_ir(text, inst, "__cqo_out_table", "__cqo_out_object",
                                                                       "__cqo_out_object", tag=".t"))
        _internalize_bundle(d / "prog.inst.ll", triple)
        _run([_tool("clang"), "-target", triple, "-O0", "-Wno-override-module", "-c", str(d / "prog.inst.ll"),
              "-o", str(d / "prog.o")], "compiling the instrumented program")

    d = _atomic_dir(_build_root() / "prog" / f"{o1.stem}-{key}", fill)
    _PROGRAMS[memo] = (d / "prog.o", triple)
    return d / "prog.o", triple


# cqo_rt.c, samples: the worker runs each record's call in-process from the post-setup state; a sample
# that ends by exit, abort or the runtime's own end jumps back here.
DRIVER_PRELUDE = ("#include <setjmp.h>\n#include <stdint.h>\n#include <string.h>\n"
                  "sigjmp_buf *__cqo_jb(void); void __cqo_resume(void); "
                  "int __cqo_sample_begin(int); void __cqo_sample_end(void);\n"
                  "void __cqo_out_mem(const char *, const void *, unsigned long long); void __cqo_out_globals(void); "
                  "void __cqo_out_regions(void); void __cqo_out_globals_tls(void);\n"
                  "static void __cqo_out_all(void) { __cqo_out_globals(); __cqo_out_regions(); }\n"
                  "void __cqo_out_table(void);\n")
# A sample that ended before the driver's outputs (a cut, exit, abort) still reads its pointer fields relationally (CR §6;
# compare.py "Pointers"), so the address table goes out; its named outputs do not (a capped or ended sample has none).
BEFORE_CALL = ("if (sigsetjmp(*__cqo_jb(), 1) != 0) { __cqo_out_table(); __cqo_out_regions(); __cqo_resume(); } "
               "else if (__cqo_sample_begin(CQD_SAMPLE)) {")
AFTER_CALL = "__cqo_sample_end(); }"
DRIVER_MAIN = "__cqo_drv_main"


def _drivers():
    from . import drivers
    if getattr(drivers, "driver_source", None) is None:
        raise OracleError("cq: unimplemented: chk-drivers: drivers.driver_source")
    return drivers


def _driver_source(spec: DriverSpec, samples: Sequence[dict]) -> str:
    d = _drivers()
    return (DRIVER_PRELUDE
            + d.driver_source(spec, list(samples), before_call=BEFORE_CALL, after_call=AFTER_CALL,
                              main_name=DRIVER_MAIN, out_mem="__cqo_out_mem", out_globals="__cqo_out_all",
                              reset_globals="__cqo_out_globals_tls"))


def executable(o1: Path, spec: DriverSpec, samples: Sequence[dict] = (),
               k: Optional[Dict[str, int]] = None, k_default: Optional[int] = None) -> Path:
    """The oracle program of one example: instrumented program + instrumented driver + runtime. The
    driver reads its samples at run time (cq-arch Z2), so one build serves every sample; `samples`
    only supply the pointer expressions the driver accepts."""
    prog_o, triple = program(o1, k, k_default, sorted(_drivers().proto_definitions(spec)))
    plugin, rt = toolchain()
    src = _driver_source(spec, samples)
    entries = sorted({c["fn"] for c in spec.calls})   # every call the driver can make
    key = hashlib.sha256("\0".join([str(prog_o), src, ",".join(entries)]).encode()).hexdigest()[:20]

    def fill(d: Path) -> None:
        (d / "driver.c").write_text(src)
        env = dict(os.environ, CQO_AT_END="1", CQO_ENTRIES=",".join(entries))
        _run([_tool("clang"), "-target", triple, "-std=gnu17", "-O1", "-w", f"-fpass-plugin={plugin}",
              str(d / "driver.c"), str(prog_o), str(prog_o.parent / "fx.o"), str(rt), "-o", str(d / "prog")],
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
    mem: List[Dict[str, Any]] = field(default_factory=list)      # named outputs in memory (outputs["mem"])
    objects: List[Dict[str, Any]] = field(default_factory=list)  # its address table (outputs["objects"])
    regions: List[Dict[str, Any]] = field(default_factory=list)  # (outputs["regions"])
    k2: List[List[int]] = field(default_factory=list)  # its rail-sized blocks, [n, K2] (outputs["k2"])
    fenv: Optional[int] = None   # the exception flags at the sample's end (cqo_rt.c; outputs["fenv_flags"], rule 23)


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


def _exit_status(sr: SampleRun) -> Optional[int]:
    """The status of a sample that ended in a noreturn call by a process exit (exit, _exit, _Exit); else None.
    Read from the notes, which the run cache holds (a longjmp arm or an abort leaves no "wait exited")."""
    if not sr.outcome.startswith("noreturn:"):
        return None
    wait = next((n for n in reversed(sr.notes) if n.startswith("wait ")), "")
    return int(wait.split()[2]) if wait.startswith("wait exited ") else None


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
                k: Optional[Dict[str, int]] = None, k_default: Optional[int] = None,
                trips_only: bool = False) -> List[SampleRun]:
    """Every sample in one oracle program, each from the post-setup state as a child forked for it
    alone would run it (cqo_rt.c, samples). The batch entry point: the program's runner process
    stays up across calls (one per example and part, per Python process), so a call costs a fork of
    the runner plus microseconds per sample.

    A sample may carry an optional "subst": {"<fn>:<site>": hex | [hex, ...]} (cq-arch Z4: the value
    each reach of a cq_theta site takes; a list gives reach r its entry r mod len); the driver ignores
    keys other than call and args.

    `trips_only` (cq-g8md, cqo_rt.c trip mode): the runs keep only the outcome, the notes, each
    distinct trip event (with "h", the header executions when it was reached), the cutoff records
    and a final {"ev": "ticks", "n"} event with the sample's header executions; no site event. For
    the sampler's trip searches past millions of header executions."""
    if not samples:
        return []
    return _run_uncached(Path(o1), spec, samples, timeout_ms, tripcap, k, k_default, trips_only)


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
        from cqcheck import tmpdirs
        self.dir = tmpdirs.make_run_dir("cqo-run.")   # owned by this process (cq-3fjt: swept if killed)
        self.lock = threading.Lock()
        self.pid = os.getpid()   # a runner belongs to the Python process that started it
        # cq-5f7p: leases (_lease) and retirement are counted under _RUNNERS_LOCK; a retired runner
        # (evicted from _RUNNERS, or found dead) is closed by its last lessee, never under a lease
        self.users = 0
        self.retired = False
        self.p = subprocess.Popen([str(exe), "--serve"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                  stderr=subprocess.DEVNULL, text=True, bufsize=1)

    def alive(self) -> bool:
        return self.pid == os.getpid() and self.p.poll() is None

    def run(self, spec: DriverSpec, samples: Sequence[Dict[str, Any]], timeout_ms: int, tripcap: int,
            isolate: bool, trips_only: bool = False) -> List[SampleRun]:
        with self.lock:
            t = self.dir
            (t / "samples").write_text(_drivers().sample_file(spec, samples))
            sub = _subst_lines(samples)
            if sub:
                (t / "subst").write_text("".join(l + "\n" for l in sub))
            req = " ".join([str(t / "trace"), str(t / "status"), str(t / "err"), str(int(timeout_ms)),
                            str(int(tripcap)), "1" if isolate else "0", str(t / "samples"),
                            str(t / "subst") if sub else "-", "1" if trips_only else "0"])
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


def _retire(r: Runner) -> bool:
    """Under _RUNNERS_LOCK: mark `r` retired (no longer in _RUNNERS); True when the caller is to close
    it now, i.e. no lease holds it. A leased one is closed by its last lessee (cq-5f7p: closing it
    under a lease removed its directory between _lease and run, a FileNotFoundError on 'samples')."""
    r.retired = True
    return r.users == 0 and r.pid == os.getpid()


@contextlib.contextmanager
def _lease(exe: Path, part: int):
    """The runner of (exe, part), held for the body: no other thread closes it meanwhile."""
    key = (str(exe), part)
    close = []
    with _RUNNERS_LOCK:
        r = _RUNNERS.pop(key, None)
        if r is not None and not r.alive():
            if _retire(r):
                close.append(r)
            r = None
        if r is None:
            r = Runner(exe)
        r.users += 1
        _RUNNERS[key] = r                      # most recently used last
        # past MAX_RUNNERS the least recently used idle runners go; leased ones stay until released
        for k in [k for k, o in _RUNNERS.items() if o.users == 0][:max(0, len(_RUNNERS) - MAX_RUNNERS)]:
            o = _RUNNERS.pop(k)
            if _retire(o):
                close.append(o)
    for o in close:
        with o.lock:
            o.close()
    try:
        yield r
    finally:
        with _RUNNERS_LOCK:
            r.users -= 1
            last = r.retired and r.users == 0 and r.pid == os.getpid()
        if last:
            with r.lock:
                r.close()


def close_runners() -> None:
    """End every runner process of this Python process (also run at exit)."""
    with _RUNNERS_LOCK:
        rs = [r for r in _RUNNERS.values() if _retire(r)]   # a leased one closes at its release
        _RUNNERS.clear()
    for r in rs:
        with r.lock:
            r.close()


atexit.register(close_runners)


def _run_uncached(o1: Path, spec: DriverSpec, samples: Sequence[Dict[str, Any]], timeout_ms: int,
                  tripcap: int, k: Optional[Dict[str, int]] = None,
                  k_default: Optional[int] = None, trips_only: bool = False) -> List[SampleRun]:
    from concurrent.futures import ThreadPoolExecutor
    exe = executable(Path(o1), spec, _pointer_samples(spec, samples), k, k_default)
    iso = isolated(program(Path(o1), k, k_default)[0])
    # cq-8m6v: a batch's runs are a function of the executable (its path is its content key), the
    # samples and the limits (cq-sqn6: no result depends on time or load; a hang raises instead)
    from .run import load_runs, save_runs
    key = [_RUNS_VERSION, str(exe), iso, int(timeout_ms), int(tripcap), list(samples)] + (["trips"] if trips_only else [])
    got = load_runs("oracle", key)
    if got is None and touches_files(program(Path(o1), k, k_default)[0]):
        runs = _run_batch(exe, spec, samples, timeout_ms, tripcap, iso, whole=True, trips_only=trips_only)
        save_runs("oracle", key, [{f: getattr(r, f) for f in _RUN_FIELDS} for r in runs])
        return runs
    if got is None:
        # and per sample within this process (cq-8m6v): every sample runs from the post-setup state
        # as a process of its own would, so a sample run in an earlier batch (the sampler's searches,
        # the theta schedules) is not run again; the rest run as one batch
        mk = (str(exe), iso, int(timeout_ms), int(tripcap), trips_only)
        with _MEMO_LOCK:
            memo = _SAMPLE_MEMO.pop(mk, None)
            if memo is None:
                memo = {}
            _SAMPLE_MEMO[mk] = memo                     # most recently used last
            while len(_SAMPLE_MEMO) > MAX_RUNNERS:      # the executables of the examples in flight
                _SAMPLE_MEMO.pop(next(iter(_SAMPLE_MEMO)))
        skeys = [json.dumps(s, sort_keys=True) for s in samples]
        todo = [i for i, sk in enumerate(skeys) if sk not in memo]
        fresh: Dict[str, Dict[str, Any]] = {}
        if todo:
            ran = _run_batch(exe, spec, [samples[i] for i in todo], timeout_ms, tripcap, iso, trips_only=trips_only)
            with _MEMO_LOCK:
                for i, r in zip(todo, ran):
                    d = fresh[skeys[i]] = {f: getattr(r, f) for f in _RUN_FIELDS}
                    # bounded (a trip search runs very many samples): past MEMO_EVENTS events an
                    # executable's memo takes no more, and those samples simply run again when asked
                    n = len(d["events"]) + 1
                    if memo.get("\0events", 0) + n <= MEMO_EVENTS:
                        memo[skeys[i]] = d
                        memo["\0events"] = memo.get("\0events", 0) + n
        got = [fresh.get(sk) or memo[sk] for sk in skeys]
        save_runs("oracle", key, got)
    return [SampleRun(index=i, sample=s, **{f: (list(v) if isinstance(v, list) else v) for f, v in d.items()})
            for i, (s, d) in enumerate(zip(samples, got))]


_SAMPLE_MEMO: Dict[Tuple, Dict[str, Any]] = {}
MEMO_EVENTS = 50_000          # trace events kept per executable's memo
_MEMO_LOCK = threading.Lock()


_RUNS_VERSION = "oracle-runs-3"
_RUN_FIELDS = ("events", "outcome", "failed", "reason", "notes", "loops", "stdout", "effects", "mem", "objects",
               "regions", "k2", "fenv")


def _run_batch(exe: Path, spec: DriverSpec, samples: Sequence[Dict[str, Any]], timeout_ms: int, tripcap: int,
               iso: bool, whole: bool = False, trips_only: bool = False) -> List[SampleRun]:
    from concurrent.futures import ThreadPoolExecutor
    n = 1 if whole else max(1, min(PARTS, _jobs_cap(), len(samples) // MIN_PART))
    if n == 1:
        with _lease(exe, 0) as r:
            return r.run(spec, samples, timeout_ms, tripcap, iso, trips_only)
    parts = [list(range(j, len(samples), n)) for j in range(n)]
    with ThreadPoolExecutor(max_workers=n) as ex:
        def part(jx):
            with _lease(exe, jx[0]) as r:
                return r.run(spec, [samples[i] for i in jx[1]], timeout_ms, tripcap, iso, trips_only)
        done = list(ex.map(part, enumerate(parts)))
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
                {"s": _bytes_text(a["s"])} if "s" in a
                else dict({k: a[k] for k in ("w", "v", "p") if k in a}, **({"cap": _bytes_text(a["cap"])} if "cap" in a else {}))
                for a in e.get("fields", e.get("args", []))]})
        elif e.get("ev") == "out_mem":
            del e["ev"]
            runs[i].mem.append(e)
        elif e.get("ev") == "object":
            del e["ev"]
            runs[i].objects.append(e)
        elif e.get("ev") == "region":
            del e["ev"]
            runs[i].regions.append(e)
        elif e.get("ev") == "allocs":
            pass
        elif e.get("ev") == "k2":
            runs[i].k2.append([int(e["n"]), int(e["k2"])])
        elif e.get("ev") == "fenv":
            runs[i].fenv = int(e["flags"])
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


def _effects_of(sr: SampleRun) -> List[dict]:
    """The C program's effect sequence: a raise a handler took, or one that does nothing, is no effect of
    the circuit (rule 16's signal table dispatches it in lowered code; only the complement branch, the
    fatal raise that ends the sample here, is an entry)."""
    fatal = sr.outcome.startswith("raise:")
    return [e for e in sr.effects if e.get("name") != "raise" or fatal]


_TOUCHES_FENV: Dict[str, bool] = {}


def _touches_fenv(o1: Path) -> bool:
    k = str(o1)
    if k not in _TOUCHES_FENV:
        from .run import touches_fenv
        _TOUCHES_FENV[k] = touches_fenv(Path(o1).read_text())
    return _TOUCHES_FENV[k]


def run_result(sr: SampleRun, spec: DriverSpec, o1: Path) -> RunResult:
    """A sample under the C oracle as the side 'c' RunResult (cq-arch T1.5).

    outputs: {"ret": [{"call", "fn", "v"}] in run.py's encoding (integer returns {"w": "i<N>"} at the
    C width, fp {"w": "f32"|"f64"|"f80"|...}, an aggregate bare hex; void, pointer and samples that
    did not return give no record), "end": outcome, "exit_status": the status of a sample that ended in a process exit, else absent, "loops": the T2 cutoff records, "stdout": the
    program's stdout, "effects": its host-effect calls (cq-e4jk), "mem", "objects", "regions":
    the module docstring's; "k2": the rail-sized blocks, [n, K2] (_k2_sites); "entered": the functions this
    input enters among those with a cq_measure or a call chain to one (compare._meas_extra); "fenv_flags": the final exception
    flags of a program that touches the environment (rule 23; run.touches_fenv), else absent}; measured: [{"h": None, "w": the register's rail
    type, "v": hex}] per reached measure site that is a gate (not a rule 2 classical read), in order; rotations: the site events of kind theta,
    phi, invert_begin and invert_end verbatim, in order, each with "nmeas", the number of entries of
    measured before it (cq-459d); kept/clean: None (the C program has no
    rails); violations: [] or [{"what": "c_oracle", "h": None, "msg": reason}]."""
    measured, rotations, reads, skips = [], [], [], []
    status = _exit_status(sr)
    for e in sr.events:
        if e.get("ev") == "skip":
            # rulings Q3: the measurement sites a branch left, after len(measured) measurements, and whether its
            # condition was quantum (cqo_rt.c __cqo_skip)
            skips.append({"n": len(measured), "q": bool(e.get("q")), "s": list(e.get("s", []))})
            continue
        if e.get("ev") != "site":
            continue
        if e["kind"] == "measure":
            measured.append({"h": None, "w": _measure_rail(o1, e["fn"], e["site"]), "v": e["reg"],
                             "cs": f"{e['fn']}:{e['site']}"})
        elif e["kind"] == "read":
            # CR rule 2: a classical read of a collapsed value, no gate (cq-y1ll); the lowered side may
            # measure a load copy of it, classical-valued (rule 3: every load is a rail, 207)
            reads.append({"w": _measure_rail(o1, e["fn"], e["site"]), "v": e["reg"]})
        else:
            rotations.append(dict(e, nmeas=len(measured)))   # the measurements before it (cq-459d)
    return RunResult(side="c", sample=sr.sample,
                     outputs={"ret": _typed_ret(spec, sr), "end": sr.outcome, "loops": list(sr.loops),
                              "stdout": sr.stdout, "effects": _effects_of(sr),
                              "mem": list(sr.mem), "objects": list(sr.objects), "regions": list(sr.regions),
                              "k2": list(sr.k2), "reads": reads, "skips": skips,
                              "entered": sorted({e["fn"] for e in sr.events if e.get("ev") == "enter"}),
                              **({"fenv_flags": sr.fenv} if sr.fenv is not None and _touches_fenv(o1) else {}),
                              **({"exit_status": status} if status is not None else {})},
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
