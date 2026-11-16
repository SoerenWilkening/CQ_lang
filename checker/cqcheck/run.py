"""Checker core, Python side (cq-w0-chk-core): build a lowered module with the evaluator runtime and a
driver, run one sample, return a RunResult.

    run_sample(lowered: Path, spec: DriverSpec, sample: dict, side: str) -> RunResult   (cq-zew)

Build. driver.c (drivers.driver_source, the one renderer of samples, cq-arch Z1/Z2) is compiled to IR with clang-19 for the lowered
module's triple, the lowered module's classical CR §2 rows are rewritten to the table (totalize_module,
cq-ltoq) and, in a module that touches the fp environment, its plain fp operations run in the default
one (default_env_module, cq-6ady), llvm-link joins it to the lowered module, checker/rt/stubgen.py defines every
cqrt_*/cq_template_* the linked module declares and every rule 27 declared clone nothing links (the
checker's stand-in, typed by the example's .O1.ll: c_module_of, cq-rft), and clang links that with every checker/rt/*.c
compiled as objects (never an archive, so each family's registering constructor is linked, cf.
cq-f69). A build is cached under $CQE_CACHE (default <repo>/build/cqcheck-cache) by a hash of
everything that goes into it, and so is a failed one (its BuildError text, cq-3ebz). The driver reads its sample at run time (cq-arch Z2), so the samples of
one example share one build.

Run (cq-e2i9). One runner process per part of a batch (run_samples: $CQCHECK_JOBS parts, default the
CPU count): `prog` with $CQD_SAMPLES naming the part's drivers.sample_file and the trace (JSONL, cq-arch)
written to $CQE_TRACE. The runner runs the setup once and forks one worker, which runs the records
in-process and between two samples puts back everything a sample can change (core.c, shots: the
executable's writable data, the heap, the setup's stack, fenv, signal handlers), so nothing of one
sample (rails, handles, known flags, logs, violations, the theta schedule, the families' tables, the
program's globals and heap) reaches the next; a sample that raises a signal or times out ends its
worker and the runner forks a fresh one. The trace frames each sample between shot markers that run.py
strips; the trace is parsed with one json.loads per runner, and each sample's events become its
RunResult in one pass. A sample that cannot be built or run is a RunResult whose violations say why;
it is never dropped: a sample that raises a signal is a 'signal' result (and 'no_exit'), one that runs
too long a 'timeout' result, and one that ends the runner itself (a malformed record) a 'sample' or
'runner' result, after which a fresh runner takes the rest.

cq_theta substitution (cq-arch Z4, cq-6m2; CR §6 item 1). A sample may carry "subst":
{"<fn>:<site>": hex | [hex, ...]}, the chosen value of each reach of a cq_theta site of the C program
(T1 ordinals; oracle.py). The evaluator does not know which lowered Ry is which C site, so run.py runs
the sample under the C oracle (oracle.run_samples on the example's .O1.ll, c_module_of; cached) and
hands the evaluator the C program's theta reaches in execution order (theta_schedule; one $CQE_THETA_ALL
file per runner holds every sample's, core.c):
each firing Ry takes the earliest reach not yet taken with its width and angle and its target takes that
reach's value (dispatch.c). A sample without "subst" substitutes nothing.

Sample values ({call, args}; call is an index into spec.calls, or a function name occurring there
once; args has one entry per argument of that call). canonical_sample turns each into the sampling
encoding (scalars "0x" + bit pattern, pointers a C expression) that drivers renders:
  int                  an integer ctype's value (wrapped to its width); for an fp ctype, that value
  float                an fp ctype's value (long double: the exact double)
  {"bits": "0x..."}    the raw bit pattern of the ctype (long double: the 80-bit x87 pattern)
  "bits:0x..."         the same
  "0x<hex digits>"     for an arithmetic ctype, its exact bit pattern: the sampling encoding that
                       the driver renders for the C oracle (cq-arch Z1, cq-a4mf), so both
                       sides receive the same value
  string               for an fp ctype, anything else Python's float() or float.fromhex() reads
                       ("nan", "-inf", "-0.0", "0x1p-1074"); for a pointer ctype, its C expression
                       ("coef", "&hostv", names defined by spec.setup)

RunResult fields (JSON-serializable):
  side        the side argument ('ours' or 'ref')
  sample      the sample dict as given
  outputs     {"ret": [{"call", "fn", "v"}], "stdout": str, "exit": int, "effects": [...], "tape": {...},
              "mem": [...], "objects": [...], "regions": [...]}; "tape" is the shot's event
              sequence (rt_tape.c, _tape_entry) as compared, packed: {"n","sha","z"} (compare.tape_pack, cq-92sw6); "q2" the host calls given a pointer into an object holding a QUANTUM cell (rulings Q2, rt_bus.c cqe__q2_check; it only narrows the C side's decision, compare.py); "deferred_r" the names of the entries deferred with a result rail, predicate 1 (ruling cq-dbtpi, _deferred_read; it only narrows the C side's decision); "host_end", present only when the sample ended in the program's own
              exit, _exit or _Exit, its status (rule 16's ordinary host call of a noreturn callee); "abort_end", present only when
              the shot ended at cqrt_abort_i1 of a classical-valued 1 (owner ruling 2026-11-14 Q1, core.c cqe__abort_end); "mem" is the named outputs in memory, read from the bus
              after the driver call (CR §6 item 1, drivers.py "Driver objects"; rt_bus.c's {"ev":"out_mem",
              "name","addr","w","v"[,"off"]}); "objects" the address table of the module's globals and
              functions ({"ev":"out_mem","table":"object","name","addr","size"}) and "regions" the host ranges a pointer may
              lie in ({"ev":"out_mem","table":"region","name","lo","hi"}), which read pointer values relationally (CR §6,
              compare.py "Pointers"); "v" is the typed
              scalar {"w": rail type, "v": hex bit pattern} of an arithmetic return (cq-pq3:
              integers "i<N>" at their C width, two's complement; float "f32", double "f64",
              long double "f80" as the x87 80-bit pattern), the bare hex of an aggregate return;
              void and pointer returns log nothing. An entry whose lowered return is a rail handle
              (CR §1.1) reports that rail's value at exit instead (resolve_handle_rets, cq-n6a0).
              "stdout" and "effects" are the host output of the run (cq-e4jk, compare.py "Host
              output"): stdout is what the process printed (the driver's setup, then the sample)
              followed by the tape's end-of-shot text (rt_tape.c's {"ev":"tape","op":"shot"} event,
              "stdout": the format entries it performed); effects is what the C program would do at
              each call: the {"ev":"effect"} lines (rt_tape.c, host_fx.c, fx_call.h) in sequence order
              (_effects_in_order), each {"name", "args"} with args [{"w": "i<N>", "v": hex[, "cap": str]
              [, "p": 1]}] (a field's value at its width and the bytes captured for it)
  measured    [{"h", "w", "v"}] per cqrt_measure call, in order
  rotations   the rotation and phase trace events in order, as written, each with "nmeas", the number
              of measurements before it (cq-459d) (the shape compare.py
              reads): ry {ev, h, theta, ctl, ctlv, w, v}, ry_qangle {ev, h, a, aval, ctl, ctlv, w, v},
              phase {ev, f, fv, theta}, phase_qangle {ev, a, aval, ctl, ctlv}; theta is the hex bit
              pattern of the double; w and v are the Ry target's type and value at the gate
  kept        the exit event's live rails [{"h", "w", "v", "role"}] as rows: a row with "n" and "step" stands
              for n rails of one width, value, role and known flag (cqcheck.kept, cq-pckdl), the tape slots of bus stores
              (role tape_slot) and overtaken load copies (role overtaken) among them; each also has
              "known" (classical-valued, BACKEND_ABI §0) and the roles of rt/core.c's header (store_kept,
              fenv_flags, fenv_mode among them, cq-tt2j; a_K, kept_ak_module, cq-1leyz; n>K2, kept_k2_module, cq-0ldab, cq-dl7da); a rail a handle-returning function returns
              also has "result": true (cq-tt2j)
  clean       the free events [{"h", "v", "known", "w"}]
  violations  the trace's violation events [{"what", "h", "msg"}] plus run failures:
              build, sample, timeout, signal, no_exit (the process ended without the exit event),
              trace_cap and violation_cap (core.c: a sample past a disk cap or $CQE_SHOT_VIOL_MAX
              violations, default 256, ends there),
              runner (the runner process ended inside this sample), trace (an unparsable line)
"""
from __future__ import annotations

import bisect
import functools
import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import tempfile
import threading
from pathlib import Path
from typing import Any, Callable, Dict, FrozenSet, Iterable, List, Optional, Sequence, Set, Tuple

from cqcheck.compare import HOST_EFFECTS
from cqcheck import cachegc
from cqcheck import kept as kept_mod
from cqcheck.contracts import DriverSpec, RunResult

REPO = Path(__file__).resolve().parents[2]
RT_DIR = REPO / "checker" / "rt"
HOST_DIR = REPO / "bundle" / "host"     # the injection-bundle host symbols, linked after the pass (rulings Q7)
FX_LOWERED = REPO / "checker" / "oracle" / "fx_lowered.c"  # direct host calls (drivers.py, rulings Q8)
LLVM_BIN = Path(os.environ.get("CQ_LLVM_BIN", "/usr/local/opt/llvm@19/bin"))
CLANG = str(LLVM_BIN / "clang")
LLVM_LINK = str(LLVM_BIN / "llvm-link")
OPT = str(LLVM_BIN / "opt")
DEFAULT_TIMEOUT = float(os.environ.get("CQCHECK_SAMPLE_TIMEOUT") or 30.0)
# The step budget (cq-o4ul): a sample that enters more than this many basic blocks of the lowered
# module is a 'timeout', deterministically (core.c, shots). `timeout` (seconds) is only a backstop and
# counts the worker's CPU time, never wall time: no result depends on the machine's load.
STEP_BUDGET = int(os.environ.get("CQCHECK_STEP_BUDGET") or 1 << 28)   # both overrides: for one heavy row at a time
_VERSION = "chk-core-7"


class BuildError(Exception):
    pass


class SampleError(Exception):
    pass


# ---- C types ---------------------------------------------------------------------------------

_INTS = {
    "_Bool": (1, False), "bool": (1, False), "char": (8, True), "signed char": (8, True), "unsigned char": (8, False),
    "short": (16, True), "short int": (16, True), "signed short": (16, True), "unsigned short": (16, False),
    "unsigned short int": (16, False), "int": (32, True), "signed": (32, True), "signed int": (32, True),
    "unsigned": (32, False), "unsigned int": (32, False), "long": (64, True), "long int": (64, True),
    "unsigned long": (64, False), "unsigned long int": (64, False), "long long": (64, True),
    "long long int": (64, True), "unsigned long long": (64, False), "unsigned long long int": (64, False),
    "int8_t": (8, True), "uint8_t": (8, False), "int16_t": (16, True), "uint16_t": (16, False),
    "int32_t": (32, True), "uint32_t": (32, False), "int64_t": (64, True), "uint64_t": (64, False),
    "size_t": (64, False), "ssize_t": (64, True), "ptrdiff_t": (64, True), "intptr_t": (64, True),
    "uintptr_t": (64, False), "__int128": (128, True), "unsigned __int128": (128, False),
}
_FPS = {"float": 32, "double": 64, "long double": 80, "_Float16": 16}


@functools.lru_cache(maxsize=None)
def norm_ctype(ct: str) -> str:
    ct = re.sub(r"\b(const|volatile|static|restrict|register)\b", " ", ct)
    ct = re.sub(r"\s*\*\s*", "*", ct)
    return " ".join(ct.split())


@functools.lru_cache(maxsize=None)
def ctype_kind(ct: str) -> Tuple[str, int]:
    """('int'|'fp'|'ptr'|'other', bits) of a C type."""
    c = norm_ctype(ct)
    if "*" in c or "[" in c:
        return "ptr", 64
    if c in _INTS:
        return "int", _INTS[c][0]
    if c in _FPS:
        return "fp", _FPS[c]
    return "other", 0


def _f80_bits(x: float) -> int:
    """The x87 80-bit pattern of a double (exact)."""
    b = struct.unpack("<Q", struct.pack("<d", x))[0]
    sign, exp, frac = b >> 63, (b >> 52) & 0x7FF, b & ((1 << 52) - 1)
    if exp == 0x7FF:
        mant = (1 << 63) | (frac << 11)
        return (sign << 79) | (0x7FFF << 64) | mant
    if exp == 0:
        if frac == 0:
            return sign << 79
        e = 1 - 1023
        while not frac & (1 << 52):
            frac <<= 1
            e -= 1
        return (sign << 79) | ((e + 16383) << 64) | (frac << 11)
    return (sign << 79) | ((exp - 1023 + 16383) << 64) | (((1 << 52) | frac) << 11)


def _fp_bits(x: float, bits: int) -> int:
    if bits == 64:
        return struct.unpack("<Q", struct.pack("<d", x))[0]
    if bits == 32:
        return struct.unpack("<I", struct.pack("<f", x))[0]
    if bits == 16:
        return struct.unpack("<H", struct.pack("<e", x))[0]
    if bits == 80:
        return _f80_bits(x)
    raise SampleError(f"no fp encoding at {bits} bits")


_BITS_RE = re.compile(r"0x[0-9a-fA-F]+")


def encode_arg(ctype: str, value: Any) -> Tuple[str, Any]:
    """('bits', int) or ('expr', str) for one argument value."""
    kind, bits = ctype_kind(ctype)
    if isinstance(value, dict):
        if set(value) != {"bits"}:
            raise SampleError(f"argument {value!r}: a dict value must be {{'bits': ...}}")
        value = "bits:" + str(value["bits"])
    if isinstance(value, str) and value.startswith("bits:"):
        if kind not in ("int", "fp"):
            raise SampleError(f"bit pattern for non-arithmetic ctype {ctype}")
        return "bits", int(value[5:], 0) & ((1 << bits) - 1)
    if isinstance(value, str) and kind in ("int", "fp") and _BITS_RE.fullmatch(value):
        # the sample file's encoding: a bare 0x-hex sample value is the exact bit pattern.
        n = int(value, 16) & ((1 << bits) - 1)
        return "bits", (n & 1) if bits == 1 else n
    if isinstance(value, bool):
        value = int(value)
    if kind == "int":
        if isinstance(value, int):
            v = value & ((1 << bits) - 1)
            return "bits", (1 if v else 0) if bits == 1 else v
        if isinstance(value, str):
            return "expr", value
        raise SampleError(f"value {value!r} for integer ctype {ctype}")
    if kind == "fp":
        if isinstance(value, (int, float)):
            return "bits", _fp_bits(float(value), bits)
        if isinstance(value, str):
            try:
                x = float(value)
            except ValueError:
                try:
                    x = float.fromhex(value)
                except ValueError:
                    return "expr", value
            return "bits", _fp_bits(x, bits)
        raise SampleError(f"value {value!r} for fp ctype {ctype}")
    if isinstance(value, str):
        return "expr", value
    if kind == "ptr" and isinstance(value, int) and value == 0:
        return "expr", "0"
    raise SampleError(f"value {value!r} for ctype {ctype}: give a C expression string")


# ---- driver ----------------------------------------------------------------------------------

# Ahead of drivers.driver_source: the driver logs each call's result as the trace's ret event through
# the CQD_RESULT hook (cq-arch Z2).
_RESULT_PRELUDE = r"""
#include <stdio.h>
#include <string.h>
void cqe_log(const char *json_object);
#include <setjmp.h>
sigjmp_buf *cqe__shot_jb(void);   /* core.c, shots (cq-e2i9) */
int cqe__shot_enter(int idx);
void cqe__shot_end(void);
void cqe__shot_resume(void);
__attribute__((weak)) long long cqe__hname(int h);   /* core.c: a handle's rail name (owner 2026-11-09) */
/* The functions whose result is a rail handle (handle_returning_fns), each name NUL-terminated, the list ended by an
   empty name: the module defines it when there is one (_build_into, hret_names_ir); this empty default otherwise. */
__attribute__((weak)) const char __cqe_hret_names[1] = {0};
static int cqd_hret(const char *fn) {
  for (const char *s = __cqe_hret_names; *s; s += strlen(s) + 1)
    if (!strcmp(s, fn)) return 1;
  return 0;
}
static void cqd_ret(int call, const char *fn, const char *w, const void *p, size_t n, unsigned bits) {
  unsigned char b[64] = {0};
  memcpy(b, p, n < sizeof b ? n : sizeof b);
  if (bits % 8) b[bits / 8] &= (unsigned char)((1u << (bits % 8)) - 1);
  char hex[2 * sizeof b + 3]; char *q = hex; *q++ = '0'; *q++ = 'x';
  int started = 0;
  for (int i = (int)((bits + 7) / 8) - 1; i >= 0; --i) {
    if (!started && b[i] == 0 && i > 0) continue;
    q += sprintf(q, started ? "%02x" : "%x", b[i]); started = 1;
  }
  *q = 0;
  char line[320], hn[40] = "";
  /* a handle result's rail name (resolve_handle_rets); only for a function that returns a handle: any other i32
     result is a value, and the name of the rail whose real handle equals it varies with replay (cq-r4nh-hn) */
  if (cqe__hname && n == 4 && cqd_hret(fn)) {
    int h; memcpy(&h, p, 4);
    snprintf(hn, sizeof hn, ",\"hn\":%lld", cqe__hname(h));
  }
  snprintf(line, sizeof line, "{\"ev\":\"ret\",\"v\":\"%s\",\"w\":\"%s\",\"call\":%d,\"fn\":\"%s\"%s}", hex, w, call, fn, hn);
  cqe_log(line);
}
#define CQD_RESULT(call, fn, w, p, n, bits) \
  cqd_ret(call, fn, (w)[0] == 'a' ? "" : (w), p, n, (bits) ? (bits) : (unsigned)(8 * (n)))
"""


# The named outputs in memory (drivers.py "Driver objects"). rt_bus.c's reader takes the bytes off the
# bus; a test's restricted runtime has none, and then no memory output exists on this side, which
# compare.py reports against any oracle that has one. The lowered module's generated __cqe_out_globals
# (drivers.out_globals_ir) calls these too, so a module-internal global is reachable.
_OUT_PRELUDE = r"""
__attribute__((weak)) void __cqe_out_mem(const char *, unsigned long long, unsigned long long);
void __cqe_out_globals(void);
void __cqe_out_globals_tls(void);
void cqd_out_object(const char *name, const void *addr, unsigned long long bytes) {
  char b[512];
  snprintf(b, sizeof b, "{\"ev\":\"out_mem\",\"table\":\"object\",\"name\":\"%s\",\"addr\":\"0x%llx\",\"size\":%llu}", name,
           (unsigned long long)addr, bytes);
  cqe_log(b);
}
void cqd_out_mem(const char *name, const void *addr, unsigned long long bytes) {
  if (__cqe_out_mem) __cqe_out_mem(name, (unsigned long long)addr, bytes);
  cqd_out_object(name, addr, bytes);
}
void cqd_out_ctl_measure(int h) {
  char b[80];
  snprintf(b, sizeof b, "{\"ev\":\"out_mem\",\"table\":\"ctl_measure\",\"h\":%d}", h);
  cqe_log(b);
}
void cqd_out_meas_fn(const char *fn, int site) {
  char b[400];
  snprintf(b, sizeof b, "{\"ev\":\"out_mem\",\"table\":\"meas_fn\",\"fn\":\"%s\",\"site\":%d}", fn, site);
  cqe_log(b);
}
/* rulings Q8: a three-rail select some measurement's register is read through: whether its condition rail reads 0 at the
   select (cqd_out_sel), and, before the measurement, the selects its register is read through in order with whether each
   is a carried advance (cqd_out_meas_chain) */
__attribute__((weak)) const void *cqe_rail(int h);
__attribute__((weak)) int cqe__val_iszero(const void *v);
__attribute__((weak)) int cqe__exists(int h);
void cqd_out_sel(int id, int h) {
  char b[120];
  int z = !(cqe_rail && cqe__val_iszero && cqe__exists && cqe__exists(h)) || cqe__val_iszero(cqe_rail(h));
  snprintf(b, sizeof b, "{\"ev\":\"out_mem\",\"table\":\"sel\",\"id\":%d,\"z\":%d}", id, z);
  cqe_log(b);
}
void cqd_out_meas_chain(int id, int chained) {
  char b[120];
  snprintf(b, sizeof b, "{\"ev\":\"out_mem\",\"table\":\"meas_chain\",\"id\":%d,\"c\":%d}", id, chained);
  cqe_log(b);
}
/* cq-2pdir (rulings Q8, cq-47f8h: a rolled trip's one site measures the carried rail of each trip): a classical select or
   join (an LLVM select or phi of handles) some measurement's register is read through: which operand it took (cqd_out_lsel),
   and, before the measurement, the tree of such choices down to the registers (cqd_out_meas_tree) */
void cqd_out_lsel(int id, int k) {
  char b[120];
  snprintf(b, sizeof b, "{\"ev\":\"out_mem\",\"table\":\"lsel\",\"id\":%d,\"k\":%d}", id, k);
  cqe_log(b);
}
void cqd_out_meas_tree(const char *t) {
  char b[1024];
  snprintf(b, sizeof b, "{\"ev\":\"out_mem\",\"table\":\"meas_tree\",\"t\":\"%s\"}", t);
  cqe_log(b);
}
static void cqd_out_regions(void) {
  char b[160];
  unsigned long long sp = (unsigned long long)__builtin_frame_address(0);
  snprintf(b, sizeof b, "{\"ev\":\"out_mem\",\"table\":\"region\",\"name\":\"stack\",\"lo\":\"0x%llx\",\"hi\":\"0x%llx\"}",
           sp - (8ULL << 20), sp + (1ULL << 16));
  cqe_log(b);
  /* bundle/host/cq_host.c: __cq_alloc's chunks from its fixed hint on */
  cqe_log("{\"ev\":\"out_mem\",\"table\":\"region\",\"name\":\"heap\",\"lo\":\"0x200000000000\",\"hi\":\"0x300000000000\"}");
}
static void cqd_out_all(void) { __cqe_out_globals(); cqd_out_regions(); }
"""


def driver_c(spec: DriverSpec, samples: Sequence[dict]) -> str:
    """The driver C source: drivers.driver_source (cq-arch Z1/Z2: the one renderer of samples) with
    the result hook. It reads its samples from $CQD_SAMPLES at run time and runs them in one worker
    process, each from the same post-setup state (core.c, shots; cq-e2i9)."""
    from cqcheck import drivers
    return _RESULT_PRELUDE + _OUT_PRELUDE + drivers.driver_source(
        spec, list(samples), before_call=SHOT_BEFORE, after_call=SHOT_AFTER, out_mem="cqd_out_mem", out_globals="cqd_out_all",
        reset_globals="__cqe_out_globals_tls")


# core.c, shots: the worker runs each record's call in-process from the post-setup state.
SHOT_BEFORE = ("if (sigsetjmp(*cqe__shot_jb(), 1) != 0) cqe__shot_resume(); "
               "else if (cqe__shot_enter(CQD_SAMPLE)) {")
SHOT_AFTER = "cqe__shot_end(); }"


def canonical_sample(spec: DriverSpec, sample: dict) -> dict:
    """{call: index, args: [...]} in the sampling encoding drivers renders (scalars "0x" + the bit
    pattern, pointers their C expression), from any value form the module docstring lists."""
    ci = _resolve_call(spec, sample.get("call"))
    cargs = spec.calls[ci].get("args", [])
    vals = sample.get("args", [])
    if len(vals) != len(cargs):
        raise SampleError(f"call {ci} takes {len(cargs)} arguments, the sample gives {len(vals)}")
    out = []
    for a, v in zip(cargs, vals):
        kind, x = encode_arg(a["ctype"], v)
        if kind == "bits":
            out.append(f"0x{x:x}")
        elif ctype_kind(a["ctype"])[0] == "ptr":
            out.append(x)
        else:
            raise SampleError(f"value {v!r} for {a['ctype']}: not a value of that type")
    return {"call": ci, "args": out}


# ---- build -----------------------------------------------------------------------------------

def _cache_root() -> Path:
    return Path(os.environ.get("CQE_CACHE", str(REPO / "build" / "cqcheck-cache")))


def tool_root() -> Path:
    """The checker's tool cache (cq-8m6v): what serves every example and depends only on checker
    sources and the toolchain (the evaluator runtime objects, the probe runtime object). $CQ_TOOL_CACHE,
    default <build>/cqcheck-tools; `cmake --build` fills it (target cqcheck_tools, cqcheck.prebuild).
    Content-keyed like every other cache: a stale or empty one only costs a rebuild."""
    return Path(os.environ.get("CQ_TOOL_CACHE",
                               str(Path(os.environ.get("CQ_BUILD_DIR", str(REPO / "build"))) / "cqcheck-tools")))


_KEY_LOCKS: Dict[str, Any] = {}
_KEY_LOCKS_LOCK = threading.Lock()


def key_lock(key: Any):
    """One lock per cache entry within this process (cq-8m6v): a second builder of the same entry
    waits for the first and then finds it, instead of building it again beside it."""
    with _KEY_LOCKS_LOCK:
        lk = _KEY_LOCKS.get(str(key))
        if lk is None:
            lk = _KEY_LOCKS[str(key)] = threading.Lock()
        return lk


def _sh(cmd: Sequence[str], cwd: Optional[Path] = None) -> None:
    p = subprocess.run(list(cmd), cwd=cwd, capture_output=True, text=True)
    if p.returncode:
        raise BuildError(f"{Path(cmd[0]).name} failed ({p.returncode}): {p.stderr.strip()[-2000:]}")


def _triple(lowered_text: str) -> str:
    m = re.search(r'^target triple = "(.*)"', lowered_text, re.M)
    return m.group(1) if m else "x86_64-apple-macosx"


def runtime_objects(triple: str, rt_sources: Optional[Sequence[Path]] = None) -> List[Path]:
    """Every runtime source compiled to an object (cached by content)."""
    srcs = sorted(Path(s) for s in (rt_sources if rt_sources is not None
                                    else [*RT_DIR.glob("*.c"), *HOST_DIR.glob("*.c"), FX_LOWERED]))
    h = hashlib.sha256((_VERSION + triple).encode())
    for s in srcs:
        h.update(str(s).encode())
        h.update(s.read_bytes())
    for hdr in [*sorted(RT_DIR.glob("*.h")), FX_LOWERED.with_name("fx_call.h")]:  # cqe.h, cq_standin.h, fx_*.h
        h.update(hdr.read_bytes())
    d = tool_root() / "rt" / h.hexdigest()[:24]
    objs = [d / (s.stem + ".o") for s in srcs]
    if all(o.exists() for o in objs):
        return objs
    with key_lock(d):
        if all(o.exists() for o in objs):
            return objs
        tmp = Path(tempfile.mkdtemp(prefix="rt.", dir=_ensure(tool_root() / "rt")))
        _parallel([[CLANG, "-std=c17", "-O1", "-w", "-target", triple, "-I", str(RT_DIR), "-c", str(s), "-o",
                    str(tmp / (s.stem + ".o"))] for s in srcs])
        _publish(tmp, d)
    return objs


def _parallel(cmds: Sequence[Sequence[str]], cwd: Optional[Path] = None) -> None:
    """_sh over independent commands, up to $CQCHECK_JOBS (at least 2) at a time; the first failure
    in command order is raised, as running them in order would raise it."""
    if len(cmds) <= 1:
        for c in cmds:
            _sh(c, cwd)
        return
    from concurrent.futures import ThreadPoolExecutor
    n = max(2, min(len(cmds), default_jobs()))
    with ThreadPoolExecutor(max_workers=n) as ex:
        futs = [ex.submit(_sh, c, cwd) for c in cmds]
    for f in futs:
        f.result()


def _ensure(p: Path) -> Path:
    p.mkdir(parents=True, exist_ok=True)
    return p


def _publish(tmp: Path, final: Path) -> None:
    try:
        os.replace(tmp, final)
    except OSError:
        shutil.rmtree(tmp, ignore_errors=True)   # another process published the same build


def c_module_of(lowered: Path, spec: DriverSpec) -> Optional[Path]:
    """The C-level module whose declarations type the callees of rule 27 declared clones (cq-rft):
    the one .O1.ll beside `lowered` (a CQ_spec reference), else the example's .O1.ll in CQ_spec."""
    for d in (Path(lowered).resolve().parent, None):
        if d is None:
            from . import drivers
            d = drivers.example_dir(spec.example)
        found = sorted(d.glob("*.O1.ll")) if d.is_dir() else []
        if len(found) == 1:
            return found[0]
    return None


def build(lowered: Path, spec: DriverSpec, samples: Sequence[dict] = (),
          rt_sources: Optional[Sequence[Path]] = None, extra_sources: Sequence[Path] = (),
          c_module: Optional[Path] = None) -> Path:
    """The executable for (lowered, spec); cached. It reads its samples at run time (drivers'
    sample file in $CQD_SAMPLES), so every sample of an example shares it; `samples` (canonical,
    see canonical_sample) only supply the pointer expressions the driver accepts. c_module: see
    c_module_of (its default)."""
    from cqcheck import drivers
    text = Path(lowered).read_text()
    triple = _triple(text)
    objs = runtime_objects(triple, rt_sources)
    drv = driver_c(spec, samples)
    if c_module is None:
        c_module = c_module_of(Path(lowered), spec)
    ctext = Path(c_module).read_text() if c_module else ""
    h = hashlib.sha256()
    for part in (_VERSION, text, drv, (RT_DIR / "stubgen.py").read_text(), Path(__file__).read_text(),
                 Path(drivers.__file__).read_text(), ctext,
                 *[str(o) for o in objs], *[Path(e).read_text() for e in extra_sources]):
        h.update(part.encode())
        h.update(b"\0")
    final = _cache_root() / "prog" / h.hexdigest()[:24]
    if (final / "prog").exists():
        cachegc.used(final)
        return final / "prog"
    with key_lock(final):
        return _build_locked(final, lowered, drv, triple, objs, ctext if c_module else None, extra_sources,
                             sorted(drivers.proto_definitions(spec)))


def _build_locked(final: Path, lowered: Path, drv: str, triple: str, objs: Sequence[Path],
                  ctext: Optional[str], extra_sources: Sequence[Path], defined: Sequence[str] = ()) -> Path:
    if (final / "prog").exists():
        return final / "prog"
    # A failed build is cached too (cq-3ebz): the same inputs fail the same way, so every later call
    # raises the recorded BuildError without rerunning clang, llvm-link and stubgen.
    failed = final.with_name(final.name + ".build_error")
    if failed.exists():
        cachegc.used(failed)
        raise BuildError(failed.read_text())
    tmp = Path(tempfile.mkdtemp(prefix="prog.", dir=_ensure(_cache_root() / "prog")))
    try:
        _build_into(tmp, lowered, drv, triple, objs, ctext, extra_sources, defined)
    except BuildError as e:
        shutil.rmtree(tmp, ignore_errors=True)
        ftmp = failed.with_name(f"{failed.name}.{os.getpid()}.tmp")
        ftmp.write_text(str(e))
        os.replace(ftmp, failed)
        raise
    # First launch of a fresh binary can be slow (the host scans it); pay that here, not inside a
    # sample's timeout. With an empty sample file the driver runs the setup only. Not a cached
    # failure: a slow host is not a property of the inputs.
    (tmp / "empty.samples").write_text("")
    try:
        subprocess.run([str(tmp / "prog")], cwd=tmp, capture_output=True, timeout=300,
                       env=dict(os.environ, CQE_TRACE=os.devnull, CQD_SAMPLES=str(tmp / "empty.samples")))
    except subprocess.TimeoutExpired as e:
        shutil.rmtree(tmp, ignore_errors=True)
        raise BuildError(f"the built program did not start within 300s: {e}")
    _publish(tmp, final)
    return final / "prog"


def _build_into(tmp: Path, lowered: Path, drv: str, triple: str, objs: Sequence[Path],
                ctext: Optional[str], extra_sources: Sequence[Path], defined: Sequence[str] = ()) -> None:
    """The toolchain steps of build: tmp/prog from the lowered module and the driver source."""
    shutil.copy(lowered, tmp / "lowered.ll")
    dll = driver_ll(drv, triple)
    shutil.copy(dll, tmp / "driver.ll")
    # the lowered module in canonical text, then its classical CR §2 rows rewritten (cq-ltoq)
    _sh([LLVM_LINK, "-S", "lowered.ll", "-o", "lowered.canon.ll"], cwd=tmp)
    try:
        canon = (tmp / "lowered.canon.ll").read_text()
        # cq-8bq66 (CR rule 16, BACKEND_ABI §1.11): the backend performs an entry with the host C library, never with a
        # lowered symbol; a stream function's own body the module keeps would interpose on the host's for the whole
        # evaluator (its own trace writes included), so it is a declaration here, as in the C oracle
        from cqcheck import oracle as _oracle
        canon = _oracle.host_streams(canon)
        tot = totalize_module(canon)
        if touches_fenv(canon):  # cq-6ady
            tot = default_env_module(tot)
        if any(Path(o).name == "host_fx.o" for o in objs):  # cq-e4jk; a test's restricted runtime may omit it
            tot = host_effects_module(tot, defined)
        tot = host_end_module(tot)   # cq-yd85w: after the effect wrappers (no effect entry of its own)
        tot = kept_k2_module(kept_ak_module(ctl_measures_module(overtaken_twin_module(kept_results_module(kept_copies_module(tot), handle_returning_fns(canon))))))
        tot = replay_module(tot, handle_returning_fns(canon))  # cq-kcn5i
        from cqcheck import drivers
        tot += drivers.out_globals_ir(ctext if ctext is not None else canon, canon, "__cqe_out_globals",
                                      "cqd_out_mem", "cqd_out_object")
        tot += hret_names_ir(handle_returning_fns(canon))   # before the write: lowered.steps.ll is built from the file (cq-xazgw)
        (tmp / "lowered.tot.ll").write_text(tot)
        (tmp / "handle_rets.json").write_text(json.dumps(handle_returning_fns(canon)))  # cq-n6a0
    except _Unimpl as e:
        raise BuildError(f"cq: unimplemented: {e}")
    # the step budget (cq-o4ul): every basic block of the lowered module counts one step
    _sh([OPT, "-S", "-passes=sancov-module", "-sanitizer-coverage-level=2", "-sanitizer-coverage-trace-pc",
         "-sanitizer-coverage-prune-blocks=0", "lowered.tot.ll", "-o", "lowered.steps.ll"], cwd=tmp)
    steps = (tmp / "lowered.steps.ll").read_text()
    # sancov declares its whole callback family; only trace_pc is called (core.c defines it)
    steps = re.sub(r"(?m)^declare [^\n]*@__sanitizer_cov_(?!trace_pc\()\w+\([^\n]*\n", "", steps)
    (tmp / "lowered.steps.ll").write_text(steps)
    # the driver is linked as its object, compiled once per content (driver_obj, cq-8m6v), not
    # linked into the module and compiled again with it; stubgen reads both modules, in link order
    if ctext is not None:
        (tmp / "c_module.ll").write_text(ctext)
    _stubgen([tmp / "lowered.steps.ll", tmp / "driver.ll"], tmp / "c_module.ll" if ctext is not None else None,
             tmp / "stubs.ll")
    extra_objs = []
    for i, e in enumerate(extra_sources):
        o = tmp / f"extra{i}.o"
        _sh([CLANG, "-std=c17", "-O1", "-w", "-target", triple, "-I", str(RT_DIR), "-c", str(e), "-o", str(o)])
        extra_objs.append(str(o))
    _sh([CLANG, "-O0", "-w", "-target", triple, *[str(o) for o in objs], *extra_objs, "lowered.steps.ll", str(driver_obj(dll, triple)), "stubs.ll",
         "-Wl,-U,___cqe_out_mem", "-lm", "-o", "prog"], cwd=tmp)


def driver_ll(drv: str, triple: str) -> Path:
    """The driver source compiled to IR, cached by its content (cq-8m6v): the driver depends on the
    DriverSpec only, so both sides of an example (ours, the reference) share one compile."""
    h = hashlib.sha256("\0".join([_VERSION, CLANG, triple, drv]).encode()).hexdigest()[:24]
    out = _cache_root() / "drv" / f"{h}.ll"
    if out.exists():
        cachegc.used(out)
        return out
    with key_lock(out):
        if not out.exists():
            tmp = Path(tempfile.mkdtemp(prefix="drv.", dir=_ensure(_cache_root() / "drv")))
            try:
                (tmp / "driver.c").write_text(drv)
                _sh([CLANG, "-O1", "-w", "-target", triple, "-S", "-emit-llvm", "driver.c", "-o", "driver.ll"],
                    cwd=tmp)
                os.replace(tmp / "driver.ll", out)
            finally:
                shutil.rmtree(tmp, ignore_errors=True)
    return out


_STUBGEN = None


def driver_obj(dll: Path, triple: str) -> Path:
    """driver_ll's module compiled at -O0, as the program's link compiled it (cached beside it)."""
    out = dll.with_suffix(".o")
    if out.exists():
        cachegc.used(out)
        return out
    with key_lock(out):
        if not out.exists():
            tmp = out.with_name(f"{out.stem}.{os.getpid()}.{threading.get_ident()}.tmp.o")
            _sh([CLANG, "-O0", "-w", "-target", triple, "-c", str(dll), "-o", str(tmp)])
            os.replace(tmp, out)
    return out


def _stubgen(modules: Sequence[Path], c_module: Optional[Path], out: Path) -> None:
    """checker/rt/stubgen.py, in this process (cq-8m6v: no interpreter start per build); a failure is
    the BuildError its command line gave: `stubgen.py failed (1): cq: stubgen: <why>`."""
    global _STUBGEN
    if _STUBGEN is None:
        import importlib.util
        spec_ = importlib.util.spec_from_file_location("cqcheck_stubgen", RT_DIR / "stubgen.py")
        mod = importlib.util.module_from_spec(spec_)
        spec_.loader.exec_module(mod)
        _STUBGEN = mod
    try:
        text, _ = _STUBGEN.generate([m.read_text() for m in modules], [c_module.read_text()] if c_module else [])
    except (_STUBGEN.StubError, OSError) as e:
        raise BuildError("stubgen.py failed (1): " + f"cq: stubgen: {e}"[-2000:])
    out.write_text(text)


# ---- CR §2 on the lowered module's classical instructions (cq-ltoq) ----------------------------
#
# CR §2: "The classical reference evaluator (§6) and every backend use the same table." The template
# families compute the table for quantum operations; a classical instruction of the lowered module is
# compiled as it stands, so x86 would trap on urem by 0 (SIGFPE) or give its own answer for a shift by
# W or more, while the C oracle (checker/oracle/OracleInstr.cpp, totalize) rewrites the same rows of
# the C program. totalize_module applies the same rewrite, row for row, to the lowered module's text
# (canonical llvm-link -S output) before it is linked with the driver:
#   udiv/urem/sdiv/srem with a divisor not a safe constant  -> @__cqe_tot.<op>.<T>: by 0 udiv 2^W-1,
#       urem a, sdiv a >= 0 ? -1 : 1, srem a; INT_MIN / -1 divides by 1 (sdiv INT_MIN, srem 0);
#   shl/lshr/ashr with an amount not a constant below W   -> @__cqe_tot.<op>.<T>: amount mod W;
#   fptosi/fptoui to i8/i16/i32/i64                         -> core.c __cqe_fpto64 / __cqe_fpto80
#       (the CR §2 rows; f16/bf16/f32 widen to f64 exactly, as the oracle does);
#   llvm.abs/ctlz/cttz                                      -> the poison flag false (abs(INT_MIN) =
#       INT_MIN, ctlz/cttz(0) = W);
#   llvm.maxnum/minnum                                      -> isnan(a) ? b : isnan(b) ? a :
#       (b > a ? b : a) (min with <), the measured x86 formula;
#   llvm.fmuladd                                            -> fmul then fadd, unfused.
# A vector form of any of these, or an fp -> int width the table does not tabulate, is a BuildError
# "unimplemented" (the oracle stops there too), never left native.

_FPT = {"half": "f16", "bfloat": "bf16", "float": "f32", "double": "f64", "x86_fp80": "f80", "fp128": "f128"}
_FPT_OF = {v: k for k, v in _FPT.items()}
_FN_START = re.compile(r"^define\b")
_INT_OP = re.compile(r"^(?P<ind>\s+)(?P<lhs>%\S+) = (?P<op>udiv|urem|sdiv|srem|shl|lshr|ashr)"
                     r"(?P<fl>(?: (?:nuw|nsw|exact))*) (?P<rest>.*)$")
_FPTOI = re.compile(r"^(?P<ind>\s+)(?P<lhs>%\S+) = (?P<op>fptosi|fptoui) (?P<rest>.*)$")
_ZPOISON = re.compile(r"(@llvm\.(?:abs|ctlz|cttz)\.[\w.]+\((?:[^()]|\([^()]*\))*), i1 true\)")
_FPINTR = re.compile(r"@llvm\.(maxnum|minnum|fmuladd)\.([\w.]+)\(")


class _Unimpl(Exception):
    pass


def _split_top(s: str) -> List[str]:
    """s split at the commas outside (), [], {} and <>."""
    out, depth, cur = [], 0, []
    for ch in s:
        if ch in "([{<":
            depth += 1
        elif ch in ")]}>":
            depth -= 1
        if ch == "," and depth == 0:
            out.append("".join(cur).strip())
            cur = []
        else:
            cur.append(ch)
    out.append("".join(cur).strip())
    return out


def _int_lit(s: str, w: int) -> Optional[int]:
    """The unsigned value of an integer literal operand of width w, or None if it is not one."""
    if s in ("true", "false"):
        return 1 if s == "true" else 0
    if re.fullmatch(r"-?[0-9]+", s):
        return int(s) % (1 << w)
    return None


def _tot_helper(op: str, t: str) -> str:
    w = int(t[1:])
    name = f"@__cqe_tot.{op}.{t}"
    b = [f"define internal {t} {name}({t} %a, {t} %b) {{"]
    if op in ("shl", "lshr", "ashr"):
        b += [f"  %m = urem {t} %b, {w}", f"  %r = {op} {t} %a, %m"]
    elif op in ("udiv", "urem"):
        b += [f"  %z = icmp eq {t} %b, 0", f"  %s = select i1 %z, {t} 1, {t} %b", f"  %q = {op} {t} %a, %s",
              f"  %r = select i1 %z, {t} {'-1' if op == 'udiv' else '%a'}, {t} %q"]
    else:  # sdiv, srem
        b += [f"  %z = icmp eq {t} %b, 0", f"  %mn = shl {t} 1, {w - 1}", f"  %am = icmp eq {t} %a, %mn",
              f"  %bm = icmp eq {t} %b, -1", f"  %o = and i1 %am, %bm", f"  %zo = or i1 %z, %o",
              f"  %s = select i1 %zo, {t} 1, {t} %b", f"  %q = {op} {t} %a, %s"]
        if op == "sdiv":
            b += [f"  %ge = icmp sge {t} %a, 0", f"  %bz = select i1 %ge, {t} -1, {t} 1",
                  f"  %r = select i1 %z, {t} %bz, {t} %q"]
        else:
            b += [f"  %r = select i1 %z, {t} %a, {t} %q"]
    b += [f"  ret {t} %r", "}"]
    return "\n".join(b)


def _fpto_helper(op: str, src: str, dst: str) -> str:
    w, sgn = int(dst[1:]), int(op == "fptosi")
    name = f"@__cqe_tot.{op}.{_FPT[src]}.{dst}"
    b = [f"define internal {dst} {name}({src} %x) {{"]
    if src == "x86_fp80":
        b.append(f"  %r = call i64 @__cqe_fpto80(x86_fp80 %x, i32 {w}, i32 {sgn})")
    else:
        x = "%x"
        if src != "double":
            b.append(f"  %d = fpext {src} %x to double")
            x = "%d"
        b.append(f"  %r = call i64 @__cqe_fpto64(double {x}, i32 {w}, i32 {sgn})")
    if w == 64:
        b.append("  ret i64 %r")
    else:
        b += [f"  %t = trunc i64 %r to {dst}", f"  ret {dst} %t"]
    b.append("}")
    return "\n".join(b)


def _fpintr_helper(op: str, sfx: str) -> str:
    t = _FPT_OF[sfx]
    name = f"@__cqe_tot.{op}.{sfx}"
    if op == "fmuladd":
        return "\n".join([f"define internal {t} {name}({t} %a, {t} %b, {t} %c) {{", f"  %p = fmul {t} %a, %b",
                          f"  %r = fadd {t} %p, %c", f"  ret {t} %r", "}"])
    cmp = "ogt" if op == "maxnum" else "olt"
    return "\n".join([f"define internal {t} {name}({t} %a, {t} %b) {{", f"  %pk = fcmp {cmp} {t} %b, %a",
                      f"  %in = select i1 %pk, {t} %b, {t} %a", f"  %nb = fcmp uno {t} %b, %b",
                      f"  %v = select i1 %nb, {t} %a, {t} %in", f"  %na = fcmp uno {t} %a, %a",
                      f"  %r = select i1 %na, {t} %b, {t} %v", f"  ret {t} %r", "}"])


def totalize_module(text: str) -> str:
    """text (canonical llvm-link -S output) with the CR §2 rows above rewritten; see the comment."""
    helpers: Dict[str, str] = {}
    out: List[str] = []
    in_fn = False
    for line in text.splitlines():
        if not in_fn:
            in_fn = bool(_FN_START.match(line)) and line.rstrip().endswith("{")
            out.append(line)
            continue
        if line.startswith("}"):
            in_fn = False
            out.append(line)
            continue
        m = _INT_OP.match(line)
        if m:
            parts = m.group("rest").split(" ", 1)
            t = parts[0]
            if not re.fullmatch(r"i[0-9]+", t) or len(parts) < 2:
                raise _Unimpl(f"CR §2 rewrite of '{line.strip()}' (vector or unparsed operand type)")
            ops = _split_top(parts[1])
            if len(ops) < 2 or any(not o.startswith("!") for o in ops[2:]):
                raise _Unimpl(f"CR §2 rewrite of '{line.strip()}' (operands)")
            a, bb, w, op = ops[0], ops[1], int(t[1:]), m.group("op")
            lit = _int_lit(bb, w)
            if op in ("shl", "lshr", "ashr"):
                safe = lit is not None and lit < w
            elif op in ("udiv", "urem"):
                safe = lit is not None and lit != 0
            else:
                safe = lit is not None and lit != 0 and lit != (1 << w) - 1
            if safe:
                out.append(line)
                continue
            key = f"{op}.{t}"
            helpers.setdefault(key, _tot_helper(op, t))
            out.append(f"{m.group('ind')}{m.group('lhs')} = call {t} @__cqe_tot.{key}({t} {a}, {t} {bb})")
            continue
        m = _FPTOI.match(line)
        if m:
            mm = re.fullmatch(r"(\S+) (.+?) to (\S+)((?:, !.*)?)", m.group("rest"))
            if not mm or mm.group(1) not in _FPT:
                raise _Unimpl(f"CR §2 rewrite of '{line.strip()}' (vector or unparsed fp type)")
            src, v, dst = mm.group(1), mm.group(2), mm.group(3)
            if dst not in ("i8", "i16", "i32", "i64") or src == "fp128":
                raise _Unimpl(f"CR §2 rewrite of '{line.strip()}' (fptosi/fptoui width the table does not "
                              f"tabulate)")
            key = f"{m.group('op')}.{_FPT[src]}.{dst}"
            helpers.setdefault(key, _fpto_helper(m.group("op"), src, dst))
            out.append(f"{m.group('ind')}{m.group('lhs')} = call {dst} @__cqe_tot.{key}({src} {v})")
            continue
        if "@llvm." in line:
            line = _ZPOISON.sub(r"\1, i1 false)", line)

            def fpintr(mm: "re.Match[str]") -> str:
                op, sfx = mm.group(1), mm.group(2)
                if sfx not in _FPT_OF or sfx == "f128":
                    raise _Unimpl(f"CR §2 rewrite of '{line.strip()}' (vector or untabulated type)")
                helpers.setdefault(f"{op}.{sfx}", _fpintr_helper(op, sfx))
                return f"@__cqe_tot.{op}.{sfx}("
            line = _FPINTR.sub(fpintr, line)
        out.append(line)
    if helpers:
        out.append("")
        out.extend(helpers[k] + "\n" for k in sorted(helpers))
        if any(".f80." in k and k.startswith("fpto") for k in helpers):
            out.append("declare i64 @__cqe_fpto80(x86_fp80, i32, i32)")
        if any(k.startswith("fpto") and ".f80." not in k for k in helpers):
            out.append("declare i64 @__cqe_fpto64(double, i32, i32)")
    return "\n".join(out) + "\n"


# ---- the default environment for non-constrained fp operations (cq-6ady) ----------------------
#
# Owner ruling on cq-0r1i: a non-constrained fp operation (plain fadd, fmul, fcmp, the fp casts, the
# non-constrained fp intrinsics) means round-to-nearest with no flags raised, whatever mode the program
# set with fesetround; only constrained intrinsics and the fenv/library calls see the live environment.
# The C oracle brackets each such operation of a program that touches the environment
# (OracleInstr.cpp defaultEnv); default_env_module does the same to the lowered module's classical
# operations, after totalize_module: each runs between core.c's __cqe_fpdfl_enter (save the
# environment, install FE_DFL_ENV) and __cqe_fpdfl_leave (restore it, so the operation's flags
# vanish). The same set as the oracle's: fadd/fsub/fmul/fdiv/frem, fcmp, fp-typed casts but bitcast,
# fp-typed non-constrained intrinsic calls, and the CR §2 fp helpers totalize_module made of
# fptosi/fptoui, maxnum/minnum and fmuladd (bracketed as one call; nothing inside them is bracketed
# again). fneg is left alone (a sign flip). The program is compiled at -O0, so nothing moves an
# operation out of its bracket. A module that does not touch the environment runs in the default one
# throughout (core.c puts fenv back after every sample) and is left alone, as the oracle leaves it.

_FP_TOK = re.compile(r"\b(half|bfloat|float|double|x86_fp80|fp128|ppc_fp128)\b")
_FP_INST = re.compile(r"^\s+%\S+ = (fadd|fsub|fmul|fdiv|frem|fcmp|fptrunc|fpext|sitofp|uitofp|fptosi|fptoui)\b")
_CALLEE = re.compile(r"\bcall\b[^@]*@(\"?)([-\w.$]+)\1\(")
_FENV_DECL = re.compile(r"^declare\b[^@]*@\"?(fe[\w.$]*)\"?\(")
_FENV_DEF = re.compile(r"^define\b[^@]*@\"?(fe[\w.$]*)\"?\(")


def touches_fenv(text: str) -> bool:
    """The oracle's touchesFenv on a module's text: a strictfp function, a constrained intrinsic, or a
    declared fe* function about exceptions, rounding or the environment, or a defined rule-23 fenv function (cq-du1gw:
    the host's for the call, as oracle.host_streams makes it)."""
    for line in text.splitlines():
        if line.startswith(("define", "declare", "attributes")) and re.search(r"\bstrictfp\b", line):
            return True
        if line.startswith("declare") and "@llvm.experimental.constrained." in line:
            return True
        m = _FENV_DECL.match(line)
        if m and any(k in m.group(1) for k in ("except", "round", "env")):
            return True
        # cq-du1gw (CR rule 16, 778-787): a body the module has for one of rule 23's fenv functions is never lifted for
        # the call, which is the host's (oracle.host_streams makes it a declaration on both sides)
        m = _FENV_DEF.match(line)
        if m:
            from cqcheck.oracle import _RULE16_NAMES
            if m.group(1) in _RULE16_NAMES:
                return True
    return False


def _needs_default_env(line: str) -> bool:
    if _FP_INST.match(line):
        return bool(_FP_TOK.search(line))
    m = _CALLEE.search(line)
    if not m or not re.match(r"^\s+(%\S+ = )?(tail |musttail |notail )?call\b", line):
        return False
    callee = m.group(2)
    if callee.startswith("__cqe_tot."):
        return callee.split(".")[1] in ("fptosi", "fptoui", "maxnum", "minnum", "fmuladd")
    if callee.startswith("llvm.") and not callee.startswith("llvm.experimental.constrained."):
        return bool(_FP_TOK.search(line))
    return False


def default_env_module(text: str) -> str:
    """text with its non-constrained fp operations bracketed by the default environment; see above."""
    out: List[str] = []
    fn: Optional[str] = None
    used = False
    for line in text.splitlines():
        if fn is None:
            m = DEFINE_NAME.match(line) if line.startswith("define") else None
            if m and line.rstrip().endswith("{"):
                fn = m.group(2)
            out.append(line)
            continue
        if line.startswith("}"):
            fn = None
            out.append(line)
            continue
        if not fn.startswith("__cqe_tot.") and _needs_default_env(line):
            ind = re.match(r"^\s*", line).group(0)
            out += [f"{ind}call void @__cqe_fpdfl_enter()", line, f"{ind}call void @__cqe_fpdfl_leave()"]
            used = True
            continue
        out.append(line)
    if used:
        out += ["", "declare void @__cqe_fpdfl_enter()", "declare void @__cqe_fpdfl_leave()"]
    return "\n".join(out) + "\n"


DEFINE_NAME = re.compile(r"^define\b[^@]*@(\"?)([-\w.$]+)\1\(")


# ---- entries that return a rail handle (cq-n6a0) -------------------------------------------------
#
# CR §1.1 and 162's header: an entry function keeps its C signature, and an unmeasured quantum value
# it returns is the i32 handle of the rail, which escapes (never freed). The driver logs the call's
# raw result, so for such an entry the logged "ret" is a handle number, which means nothing to the C
# oracle (the value) nor across two lowerings (rail numbering is free). handle_returning_fns finds,
# in the canonical lowered module, the functions whose returned value is a handle: it follows a ret's
# operand through phi, select and integer casts to its definition, which is a handle when it is a
# forward cq_template_* call, cqrt_alloc_*, cqrt_qram_load_*, cqrt_tape_alloc, a declared clone
# __cq_q_* (rule 27: a non-void result is an i32 handle) or a call of a defined function that returns
# a handle. resolve_handle_rets then replaces such a ret's handle by the rail's basis value from the
# exit event (the rail is live there: it escaped), as the typed scalar at the call's C type; a
# handle that names no live rail, or a rail of another type, is a "ret_handle" violation.

_RAIL_CALLS = ("cqrt_alloc_", "cqrt_qram_load_", "cqrt_tape_alloc")
_DEF = re.compile(r"^\s+(%[-\w.$\"]+) = (.*)$")
_RET = re.compile(r"^\s+ret (\S+) (.+?)(?:, !.*)?$")


def hret_names_ir(fns: Sequence[str]) -> str:
    """The driver's list of handle-returning functions (_RESULT_PRELUDE's __cqe_hret_names), overriding its empty weak
    default; nothing when fns is empty."""
    if not fns:
        return ""
    data = b"".join(f.encode() + b"\0" for f in fns) + b"\0"
    esc = "".join(chr(c) if 32 <= c < 127 and c not in (34, 92) else f"\\{c:02X}" for c in data)
    return f'\n@__cqe_hret_names = constant [{len(data)} x i8] c"{esc}"\n'


def handle_returning_fns(text: str) -> List[str]:
    """The defined functions of a canonical lowered module whose returned value is a rail handle."""
    fns: Dict[str, Tuple[Dict[str, str], List[str]]] = {}
    cur: Optional[str] = None
    for line in text.splitlines():
        if cur is None:
            m = DEFINE_NAME.match(line) if line.startswith("define") else None
            if m and line.rstrip().endswith("{"):
                cur = m.group(2)
                fns[cur] = ({}, [])
            continue
        if line.startswith("}"):
            cur = None
            continue
        m = _DEF.match(line)
        if m:
            fns[cur][0][m.group(1)] = m.group(2)
            continue
        m = _RET.match(line)
        if m and m.group(1) != "void":
            fns[cur][1].append(m.group(2).strip())
    memo: Dict[str, bool] = {}

    def value(fn: str, v: str, seen: set) -> bool:
        defs = fns[fn][0]
        if not v.startswith("%") or (fn, v) in seen or v not in defs:
            return False   # a constant or an argument: classical
        seen.add((fn, v))
        rhs = defs[v]
        op = rhs.split(" ", 1)[0]
        if op == "phi":
            return any(value(fn, a.strip(), seen) for a in re.findall(r"\[\s*([^,\]]+),", rhs))
        if op == "select":
            ops = _split_top(rhs.split(" ", 1)[1])
            return any(value(fn, o.split()[-1], seen) for o in ops[1:3] if o)
        if op in ("zext", "sext", "trunc", "bitcast", "freeze"):
            mm = re.match(r"\S+ \S+ (\S+) to ", rhs)
            return bool(mm) and value(fn, mm.group(1), seen)
        m = _CALLEE.search(rhs)
        if m and re.match(r"^(tail |musttail |notail )?call\b", rhs):
            return returns_handle(m.group(2))
        return False

    def returns_handle(callee: str) -> bool:
        if callee.startswith("cq_template_"):
            return not callee.endswith("_unc")
        if callee.startswith("cqrt_"):
            return callee.startswith(_RAIL_CALLS)
        if callee not in fns:
            return callee.startswith("__cq_q_") and not callee.endswith("_unc")
        if callee not in memo:
            memo[callee] = False   # a recursive cycle alone gives no handle
            memo[callee] = any(value(callee, r, set()) for r in fns[callee][1])
        return memo[callee]

    return sorted(f for f in fns if returns_handle(f))


def _drop_hn(r: RunResult) -> RunResult:
    """r without the rail names of its results (the driver logs one with every i32 result: "hn")."""
    if not r.outputs or not any(isinstance(e, dict) and "hn" in e for e in r.outputs.get("ret") or []):
        return r
    rets = [{k: v for k, v in e.items() if k != "hn"} if isinstance(e, dict) else e for e in r.outputs["ret"]]
    return RunResult(side=r.side, sample=r.sample, outputs=dict(r.outputs, ret=rets), measured=r.measured,
                     rotations=r.rotations, kept=r.kept, clean=r.clean, violations=r.violations)


def resolve_handle_rets(r: RunResult, fns: Sequence[str]) -> RunResult:
    """r with each ret of a function in fns resolved from its handle to the rail's value; see above. The kept list
    names a rail by its name, not its handle (rt/core.c, rail names: owner 2026-11-09), so a result is looked up by
    the name the driver logged with it ("hn"); "hn" is dropped from every ret."""
    if not fns or not r.outputs or not r.outputs.get("ret"):
        return _drop_hn(r)
    # a row stands for "n" rails, every "step"-th handle from "h" (cqcheck.kept); looked up, never expanded
    live = kept_mod.KeptIndex(r.kept)
    rets, viol = [], list(r.violations)
    results = set()
    for e in r.outputs["ret"]:
        v = e.get("v")
        if e.get("fn") not in fns or not isinstance(v, dict):
            rets.append(e)
            continue
        if "hn" in e:
            h = e["hn"]
        else:
            h = int(v["v"], 16)
            h = h - (1 << 32) if h >= 1 << 31 else h
        e = {k: x for k, x in e.items() if k != "hn"}
        rail = live.get(h)
        if rail is None or rail.get("w") != v.get("w"):
            what = "names no live rail at exit" if rail is None else f"names a {rail.get('w')} rail"
            viol.append({"what": "ret_handle", "h": h,
                         "msg": f"{e.get('fn')} returns handle {h} (a {v.get('w')}), which {what}"})
            rets.append(e)
            continue
        rets.append(dict(e, v={"w": v["w"], "v": rail["v"]}))
        results.add(h)
    rets = [{k: x for k, x in e.items() if k != "hn"} if isinstance(e, dict) else e for e in rets]
    # cq-tt2j: the returned rail is a result (CR §1.1), kept at exit by design (compare._leaks)
    kept = r.kept
    if results:
        kept = kept_mod.mark_results(r.kept, results)
    return RunResult(side=r.side, sample=r.sample, outputs=dict(r.outputs, ret=rets), measured=r.measured,
                     rotations=r.rotations, kept=kept, clean=r.clean, violations=viol)


# ---- run -------------------------------------------------------------------------------------

def _resolve_call(spec: DriverSpec, call: Any) -> int:
    if isinstance(call, int) and not isinstance(call, bool):
        if 0 <= call < len(spec.calls):
            return call
        raise SampleError(f"call index {call} out of range ({len(spec.calls)} calls)")
    if isinstance(call, str):
        hits = [i for i, c in enumerate(spec.calls) if c["fn"] == call]
        if len(hits) == 1:
            return hits[0]
        raise SampleError(f"call {call!r} names {len(hits)} driver calls; give an index")
    raise SampleError(f"call {call!r}: an index or a function name")


_ROT_EVENTS = frozenset(("ry", "ry_qangle", "phase", "phase_qangle"))
_STOP_WHATS = frozenset(("build", "sample", "timeout"))


_RUN_ROLES = frozenset(("tape_slot", "store_kept"))


def _compact_kept(live: List[dict]) -> List[dict]:
    """The live rails with each run of a store's rails of one role, type and value, at handles in steps
    of `step`, as one row with "n" and "step" (compare._kept_rows expands it): rule 22's K2 copy keeps
    thousands per sample (192), and a batch holds every sample's list."""
    out: List[dict] = []
    tails: Dict[Tuple, dict] = {}
    for e in live:
        key = (e.get("role"), e.get("w"), e.get("v"), e.get("known"))
        if e.get("role") in _RUN_ROLES:
            t = tails.get(key)
            if t is not None:
                step = e["h"] - t["h"] if "n" not in t else t["step"]
                if e["h"] == t["h"] + t.get("n", 1) * step or ("n" not in t and step > 0):
                    t["n"], t["step"] = t.get("n", 1) + 1, step
                    continue
            tails[key] = e = dict(e)
        out.append(e)
    return out


def _kept_of_exit(e: dict) -> List[dict]:
    """The exit event's live list as the run's kept list (cqcheck.kept: rows and patterns, never one entry per rail;
    cq-pckdl). An event read row by row (_exit_event) comes with it built."""
    return e["kept"] if "kept" in e else kept_mod.build(e.get("live") or [])


def _result(side: str, sample: Any, events: List[dict], stdout: str, code: Optional[int],
            extra: List[dict], freed: Optional[dict] = None) -> RunResult:
    """One pass over a sample's trace events into its RunResult. `freed`: the compact trace's summary
    of the sample's frees (_shot_result), the last entry of `clean`."""
    rets: List[dict] = []
    measured: List[dict] = []
    rereads: List[dict] = []
    rots: List[dict] = []
    clean: List[dict] = []
    viol: List[dict] = []
    mem: List[dict] = []
    objects: List[dict] = []
    regions: List[dict] = []
    ctl_measured: List[int] = []
    meas_fn: Optional[str] = None
    meas_site: Optional[int] = None
    meas_chain: List[Tuple[Any, Any]] = []
    sel_z: Dict[Any, int] = {}
    lsel_k: Dict[Any, Any] = {}
    meas_tree: Optional[str] = None
    direct_fx: List[dict] = []
    tape_out, tape_seq, deferred_r = "", [], []
    q2: List[dict] = []
    last_exit: Optional[dict] = None
    host_end: Optional[int] = None
    abort_end = False
    for e in events:
        ev = e.get("ev")
        if ev in _ROT_EVENTS:
            rots.append(dict(e, nmeas=len(measured)))   # the measurements before it (cq-459d)
        elif ev == "free":
            c = {"h": e.get("h"), "v": e.get("v"), "known": e.get("known"), "w": e.get("w")}
            if e.get("shot"):
                c["shot"] = True
            clean.append(c)
        elif ev in ("measure", "reread"):
            # CR rule 2, ABI 1.3: a cqrt_measure of a rail already measured is a classical re-read, no measurement of
            # ours; it is kept apart, with the number of our measurements before it (`at`), for compare._meas_seq
            if ev == "measure":
                measured.append({"h": e["h"], "w": e.get("w"), "v": e["v"]})
            else:
                rereads.append({"h": e["h"], "w": e.get("w"), "v": e["v"], "at": len(measured)})
            cur = measured[-1] if ev == "measure" else rereads[-1]
            if meas_fn is not None:
                cur["fn"], meas_fn = meas_fn, None
                if meas_site is not None:
                    cur["site"], meas_site = meas_site, None
            # rulings Q8: follow the selects the register is read through only while their condition reads 0; at one reading
            # 1 the copy measures that select's own result: the site's carried rail only for a carried advance (`c`)
            for sid, chained in meas_chain:
                if sid not in sel_z:
                    break
                if sel_z[sid]:
                    if not chained:
                        cur["sel_other"] = True
                    break
            meas_chain = []
            if meas_tree is not None:   # cq-2pdir: the register this execution reads, through the classical choices taken
                reg = _walk_meas_tree(meas_tree, lsel_k)
                if reg is not None:
                    cur["reg"] = reg
                meas_tree = None
        elif ev == "ret":
            rets.append({"call": e.get("call"), "fn": e.get("fn"),
                         "v": {"w": e["w"], "v": e.get("v")} if e.get("w") else e.get("v")})
            if "hn" in e:
                rets[-1]["hn"] = e["hn"]     # the result as a handle: its rail's name (resolve_handle_rets drops it)
        elif ev == "violation":
            viol.append({"what": e.get("what"), "h": e.get("h"), "msg": e.get("msg")})
        elif ev == "exit":
            last_exit = e
        elif ev == "host_end":
            host_end = e.get("code")
        elif ev == "abort_end":
            abort_end = True
        elif ev == "out_mem":
            if e.get("table") == "object":      # the driver's lines (_OUT_PRELUDE), kept by the same compact filter
                objects.append({k: e[k] for k in ("name", "addr", "size") if k in e})
            elif e.get("table") == "region":
                regions.append({k: e[k] for k in ("name", "lo", "hi") if k in e})
            elif e.get("table") == "ctl_measure":
                ctl_measured.append(e.get("h"))
            elif e.get("table") == "meas_fn":
                meas_fn, meas_site = e.get("fn"), e.get("site")
            elif e.get("table") == "sel":
                sel_z[e.get("id")] = 0 if e.get("z") else 1
            elif e.get("table") == "meas_chain":
                meas_chain.append((e.get("id"), e.get("c")))
            elif e.get("table") == "lsel":
                lsel_k[e.get("id")] = e.get("k")
            elif e.get("table") == "meas_tree":
                meas_tree = e.get("t")
            elif e.get("table") == "q2":           # rulings Q2: a host callee given a pointer into a QUANTUM object
                q2.append({"name": e.get("name"), "addr": e.get("addr")})
            else:
                mem.append({k: e[k] for k in ("name", "addr", "off", "w", "v") if k in e})
        elif ev == "tape" and e.get("op") == "shot":
            tape_out, tape_seq = _tape_shot(e)
            deferred_r = _deferred_read(e)
        elif ev == "effect":
            direct_fx.append(e)
    kept = _kept_of_exit(last_exit) if last_exit is not None else []
    if freed is not None:
        clean.append(dict(freed))
    viol += extra
    if last_exit is None and code is not None and not any(v["what"] in _STOP_WHATS for v in extra):
        viol.append({"what": "no_exit", "h": None, "msg": f"process ended (status {code}) without the exit event"})
    outputs = {"ret": rets, "stdout": stdout + tape_out, "exit": code, "effects": _effects_in_order(direct_fx),
               "tape": tape_seq, "mem": mem, "objects": objects, "regions": regions, "q2": q2, "deferred_r": deferred_r,
               "ctl_measured": ctl_measured, "host_flags": (last_exit or {}).get("host_flags")}
    if rereads:
        outputs["rereads"] = rereads
    if host_end is not None:
        outputs["host_end"] = host_end
    if abort_end:
        outputs["abort_end"] = True     # owner ruling 2026-11-14 Q1: the shot ended at abort_i1 of a classical 1 (core.c)
    rr = RunResult(side=side, sample=sample, outputs=outputs,
                   measured=measured, rotations=rots, kept=kept, clean=clean, violations=viol)
    if tape_seq:      # cq-92sw6: the sequence as compared, packed (compare.tape_pack); never the entries themselves
        from cqcheck.compare import tape_pack
        outputs["tape"] = tape_pack(rr)
    return rr


_TABLE_RESULT = re.compile(r"^\s+(%[-\w.$\"]+) = (?:tail |notail )?call [^@]*?%[-\w.$\"]+\(")
_COPY_OUT = re.compile(r"^(\s+)call void @cqrt_copy_\w+\(i32 (%[-\w.$\"]+), i32 (%[-\w.$\"]+)\)")
_NULL_EFFECT = re.compile(r"^\s+(%[-\w.$\"]+) = call i32 @cqrt_tape_effect_\w+_controlled\(.*, ptr null, i32 \d+\)")
_SELECT = re.compile(r"^\s+(%[-\w.$\"]+) = call i32 @cq_template_select_\w+\(i32 [^,]+, i32 ([^,]+), i32 [^,)]+\)")
_SELECT_UNC = re.compile(r"^\s+call void @cq_template_select_\w+_unc\(i32 (%[-\w.$\"]+),")
_EXTRACT = re.compile(r"^\s+(%[-\w.$\"]+) = extractvalue \{[^}]*\} (%[-\w.$\"]+), \d+")


def kept_copies_module(text: str) -> str:
    """Rule 19's two copies at a table dispatch, kept rails a rule names (CR §6 item 1): the copy c_i of a
    candidate's result (its result is zeroed by the twin, the call is a memory version change), and the final copy
    of the call's value select_<W>(p_n, r_e, out_n), `r_e` the null-named effect entry's result, taken right before
    that select's uncompute ("copied out where it is measured or kept"). Any other copy of that select, or of any
    other select, stays a leak."""
    lines = text.splitlines()
    out, results, effects, finals = [], set(), set(), set()
    used = False
    for i, line in enumerate(lines):
        out.append(line)
        if line.startswith("}"):
            results, effects, finals = set(), set(), set()
        m = _TABLE_RESULT.match(line)
        if m:
            results.add(m.group(1))
        m = _EXTRACT.match(line)
        if m and m.group(2) in results:
            results.add(m.group(1))
        m = _NULL_EFFECT.match(line)
        if m:
            effects.add(m.group(1))
        m = _SELECT.match(line)
        if m and m.group(2) in effects:
            finals.add(m.group(1))
        m = _COPY_OUT.match(line)
        if m and (m.group(2) in results or (m.group(2) in finals and i + 1 < len(lines)
                                            and (_SELECT_UNC.match(lines[i + 1]) or [0, 0])[1] == m.group(2))):
            out.append(f"{m.group(1)}call void @cqe__set_store_kept(i32 {m.group(3)})")
            used = True
    if used:
        out.append("declare void @cqe__set_store_kept(i32)")
    return "\n".join(out) + "\n"


_HANDLE_CALL = re.compile(r"^(\s+)(%[-\w.$\"]+) = (?:tail |notail )?call [^@]*@(\"?)([-\w.$]+)\3\(")
_FN_BODY = re.compile(r"(?ms)^define\b[^\n]*?@\"?([-\w.$]+)\"?\([^\n]*\{\n(.*?)^\}$")
_TABLE_CLONE = re.compile(r"^__cq_q_.*_t(_ctl)?$")
_TWIN_OF_CLONE = re.compile(r"^__cq_q_.*(_unc|_pure)$")
_CALLED = re.compile(r"\bcall [^@%\n]*@\"?([-\w.$]+)\"?\(")
_INDIRECT = re.compile(r"\bcall [^@\n]*%[-\w.$\"]+\(")
_BACK_LABEL = re.compile(r"\blabel %([-\w.$\"]+)")
_BLOCK = re.compile(r"(?m)^([-\w.$\"]+):")
_CTL_MEASURE = re.compile(r"@cqrt_copy_\w+_controlled\(i32 [^,]+, i32 [^,]+, i32 (%[-\w.$\"]+)\)")
_MEASURED_RAIL = re.compile(r"@cqrt_measure_\w+\(i32 (%[-\w.$\"]+)\)")
# Callees that are none of rule 18's reasons for no twin by themselves (the bus stores and effect entries among
# cqrt_* are read separately); a callee with no body, a declared clone included, is a host call.
_NEUTRAL_CALLEE = re.compile(r"^(cq_template_|cqrt_|__cq_mem$|__cq_mints_push$|__cq_clone_|__cq_free$|llvm\.)")


def _no_twin_clones(bodies: Dict[str, str]) -> Set[str]:
    """Rule 18's list read off the lowered bodies, each a function's own reason or a by-name callee's: it writes
    memory (rule 5: a bus store or swap, a plain store or memory intrinsic to a host-resident object, but the activation
    counter's and the compiler's own frame slots, __cq_alloc, an indirect call, a host call), measures (Q3: tainted, a _ctl clone's or a controlled copy's rail, a classical-path
    measurement leaves the twin), reads an effect entry's result, or (rulings3 F) rotates per trip. A body of
    templates and rotations outside loops is not on it: its result left live is a leak."""
    def own(fn: str, body: str) -> bool:
        ctl = {m.group(1) for m in _CTL_MEASURE.finditer(body)}
        if re.search(r"@cqrt_(qram_(store|swap)|tape_effect)", body):
            return True
        if any("_ctl" in fn or m.group(1) in ctl for m in _MEASURED_RAIL.finditer(body)):
            return True
        if _INDIRECT.search(body):
            return True
        if re.search(r"\bcall void @llvm\.mem(cpy|move|set)\.", body):
            return True
        frames = set(re.findall(r"(?m)^\s+(%\"?cq\.[-\w.$\"]+) = alloca\b", body))
        for m in re.finditer(r"(?m)^\s+store [^\n]*?, ptr ([@%][-\w.$\"]+)", body):
            if m.group(1) not in frames and not m.group(1).startswith("@__cq_act_") and not frame_gep(body, frames, m.group(1)):
                return True
        return any(not _NEUTRAL_CALLEE.match(c) and c not in bodies for c in _CALLED.findall(body))

    def frame_gep(body: str, frames: Set[str], p: str) -> bool:
        m = re.search(rf"(?m)^\s+{re.escape(p)} = getelementptr [^\n]*?, ptr (%[-\w.$\"]+)", body)
        return bool(m) and m.group(1) in frames

    def has_loop(body: str) -> bool:
        seen: Set[str] = set()
        for line in body.splitlines():
            m = _BLOCK.match(line)
            if m:
                seen.add(m.group(1))
            elif re.match(r"\s+(br|switch)\b", line):
                if any(lab in seen for lab in _BACK_LABEL.findall(line)):
                    return True
        return False

    def calls(body: str) -> Set[str]:
        return {c for c in _CALLED.findall(body) if c in bodies and not c.endswith("_unc")}

    # rotation, itself or through a by-name callee; a loop around it mints per trip
    rotates = {f for f, b in bodies.items() if re.search(r"@cqrt_ry_", b) and not f.endswith("_unc")}
    changed = True
    while changed:
        changed = False
        for f, b in bodies.items():
            if f not in rotates and not f.endswith("_unc") and calls(b) & rotates:
                rotates.add(f)
                changed = True
    # A table clone with no predicate keeps its twin for a classical-path measurement of a rail that is not its formal (rule 18), which
    # re-reads the copy it pushed; one of a formal leaves it none (measures_formal_copy). A
    # copy per trip leaves it none, as a rotation per trip does, and so does a measurement under a quantum predicate: every formal of
    # _t is a rail, so its branches are quantum and their merges are select templates.
    measures = {f for f, b in bodies.items() if _MEASURED_RAIL.search(b) and not f.endswith("_unc")}
    changed = True
    while changed:
        changed = False
        for f, b in bodies.items():
            if f not in measures and not f.endswith("_unc") and calls(b) & measures:
                measures.add(f)
                changed = True
    def measures_formal_copy(fn: str, body: str) -> bool:
        """§1.4 (CQ_spec 96c7bc5): a table clone with no predicate measures a formal through a kept copy t, `alloc_<W>(0);
        copy_<W>(h, t); measure_<W>(t)` (or hands t to a by-name callee that measures it); t is not pushed, so no twin can
        re-read it and the clone has no rule-18 twin (211's __cq_q_peek_1_t_unc)."""
        if not re.match(r"^__cq_q_.*_t$", fn):
            return False
        defs = [int(n) for n in re.findall(r"(?m)^\s+%(\d+) = ", body)]
        if not defs:
            return False
        nformals = min(defs) - 1   # unnamed formals %0..%(n-1), then the entry block
        fresh = set(re.findall(r"(?m)^\s+(%\d+) = call i32 @cqrt_alloc_\w+\(i\d+ 0\)", body))
        for m in re.finditer(r"@cqrt_copy_\w+\(i32 %(\d+), i32 (%\d+)\)", body):
            if int(m.group(1)) >= nformals or m.group(2) not in fresh:
                continue
            t = re.escape(m.group(2))
            if re.search(rf"@cqrt_measure_\w+\(i32 {t}\)", body):
                return True
            for c in re.finditer(rf"(?m)\bcall [^@%\n]*@\"?([-\w.$]+)\"?\(([^\n]*)$", body):
                if c.group(1) in measures and re.search(rf"\bi32 {t}[,)]", c.group(2)):
                    return True
        return False

    out = {f for f, b in bodies.items()
           if own(f, b) or (f in rotates and has_loop(b))
           or (_TABLE_CLONE.match(f) and f in measures and (has_loop(b) or "@cq_template_select_" in b))
           or measures_formal_copy(f, b)}
    changed = True
    while changed:
        changed = False
        for f, b in bodies.items():
            if f not in out and calls(b) & out:
                out.add(f)
                changed = True
    return out


def _pop_only(body: str) -> bool:
    """A twin of §1.4's no-twin form: pops what the clone pushed and counts its activation, nothing else."""
    return not re.search(r"@cqrt_(copy|free)|@cq_template_|_unc\(|_pure\(", body)


def _flat_fields(ty: str) -> List[int]:
    """The field indices of a literal struct of i32s; other fields are no handle."""
    inner = ty.strip()[1:-1]
    return [i for i, f in enumerate(_split_top(inner)) if f.strip() == "i32"]


def _ret_handles(body: str, is_rail) -> List[str]:
    """Text lines marking each returned rail of one clone body, inserted before its rets (kept_results_module).
    A classical field of a struct result is left alone (rule 18: the record is per clone, not by type)."""
    defs = dict(m.groups() for m in re.finditer(r"(?m)^\s+(%[-\w.$\"]+) = (.*)$", body))
    out: List[str] = []
    for line in body.splitlines(keepends=True):
        m = _RET.match(line.rstrip("\n"))
        if m and m.group(1) == "i32":
            v = m.group(2).strip()
            if is_rail(v):
                out.append(f"  call void @cqe__set_store_kept(i32 {v})\n")
        else:
            ms = re.match(r"^\s+ret (\{[^}]*\}) (%[-\w.$\"]+)", line)
            if ms:
                fields: Dict[int, str] = {}
                v = ms.group(2)
                while v in defs and defs[v].startswith("insertvalue"):
                    mi = re.match(r"insertvalue \{[^}]*\} (\S+), \S+ (\S+), (\d+)", defs[v])
                    if not mi:
                        break
                    fields.setdefault(int(mi.group(3)), mi.group(2))
                    v = mi.group(1)
                for i in _flat_fields(ms.group(1)):
                    if i in fields and is_rail(fields[i]):
                        out.append(f"  call void @cqe__set_store_kept(i32 {fields[i]})\n")
        out.append(line)
    return out


def kept_results_module(text: str, handle_fns: Sequence[str]) -> str:
    """Kept results a rule names (CR §6 item 1), each marked by its rule, no other:
    - rule 19: the call of an own symbol's rail result (escaped, never freed);
    - rule 18: the results of a by-name clone on rule 18's no-twin list (_no_twin_clones) with no `_unc` in the module,
      its {res, flags} struct included (a clone that loads is kept per call, overtaken_twin_module);
    - §1.4: the results of a table clone on that list whose twin is the pop-only form ("every result stays allocated").
    A callee with a twin is not touched, and neither is a clone off the list with no twin (its twin's call was
    lost): a result that should be zeroed and is not stays a leak, as does anything else the clone left live."""
    bodies = {m.group(1): m.group(2) for m in _FN_BODY.finditer(text)}
    no_twin = _no_twin_clones(bodies)
    keep: Set[str] = set()
    for f, b in bodies.items():
        if _TWIN_OF_CLONE.match(f) or not f.startswith("__cq_q_"):
            continue
        twin = bodies.get(f + "_unc")
        if _TABLE_CLONE.match(f):
            if f in no_twin and twin is not None and _pop_only(twin):
                keep.add(f)
        elif not re.search(rf"(?m)^(?:define|declare)\b[^@\n]*@\"?{re.escape(f)}_unc\"?\(", text) and (
                f in no_twin):
            keep.add(f)
    own = {f for f in handle_fns if not f.startswith("__cq_q_")
           and not re.search(rf"(?m)^(?:define|declare)\b[^@\n]*@\"?{re.escape(f)}_unc\"?\(", text)}
    if not keep and not own:
        return text
    out, used, cur, nkept = [], False, None, 0
    for line in text.splitlines():
        if line.startswith("define"):
            m = DEFINE_NAME.match(line)
            cur = m.group(2) if m and m.group(2) in keep and line.rstrip().endswith("{") else None
            out.append(line)
            if cur:
                out.extend(ln.rstrip("\n") for ln in _ret_handles(bodies[cur], _rail_tester(bodies[cur], handle_fns)))
                used = True
            continue
        if line.startswith("}"):
            cur = None
        if cur:
            continue
        out.append(line)
        m = _HANDLE_CALL.match(line)
        ty = re.match(r"^\s+\S+ = (?:tail |notail )?call (?:[^@]*\s)?i(\d+) @", line) if m and m.group(4) in own else None
        if ty and int(ty.group(1)) == 32:
            out.append(f"{m.group(1)}call void @cqe__set_store_kept(i32 {m.group(2)})")
            used = True
        elif ty and int(ty.group(1)) > 32:
            # rule 19: the C return type when an integer of 32 bits or more, the handle zero-extended (162, 193; strlen's i64)
            nkept += 1
            out.append(f"{m.group(1)}%cqe.own.{nkept} = trunc i{ty.group(1)} {m.group(2)} to i32")
            out.append(f"{m.group(1)}call void @cqe__set_store_kept(i32 %cqe.own.{nkept})")
            used = True
    if used and "declare void @cqe__set_store_kept" not in text:
        out.append("declare void @cqe__set_store_kept(i32)")
    return "\n".join(out) + "\n"


def _loads_bus(f: str, bodies: Dict[str, str]) -> bool:
    seen: Set[str] = set()
    work = [f]
    while work:
        g = work.pop()
        if g in seen or g not in bodies:
            continue
        seen.add(g)
        if "@cqrt_qram_load_" in bodies[g]:
            return True
        work.extend(_CALLED.findall(bodies[g]))
    return False


# ---------------- rule 18: a loading clone's result that a memory version change overtook before its twin (CR §6 item 1)

# a forward clone by §1.4's grammar, its `_b` bounds included (cq-usir7: `__cq_q_strnlen_11_b2147483647_ctl`)
_CLONE_NAME = re.compile(r"^__cq_q_(.+)_[01v]+(?:_b\d+(?:_\d+)*)?(?:_t)?(?:_ctl)?$")
_LOW_VALUE = re.compile(r"%[-\w.$]+|%\"[^\"]*\"")
_I1_GATE = re.compile(r"^\s+(?:(%[-\w.$\"]+) = )?call [^@\n]*@(cqrt_(?:and|or|xor|not|copy|alloc)_i1|cq_template_(?:and|or|xor)_i1)\(([^\n]*)\)")
_CONTROLLED = re.compile(r"@\"?[-\w.$]+_controlled\"?\(i32 (%[-\w.$\"]+),")
_MAX_ATOMS = 16
_LOW_DEF = re.compile(r"^\s+(%[-\w.$\"]+) = ")
_TERMINATOR = re.compile(r"\s+(br|switch|indirectbr|callbr)\b")
_FLOW_DEF = re.compile(r"^\s+\S+ = (phi|extractvalue|select i1) ")
_STORE = re.compile(r"^\s+store ")
_CALL_WORD = re.compile(r"\b(call|invoke)\b")
_RMW_WORD = re.compile(r"\b(atomicrmw|cmpxchg)\b")
_BUS_WRITE = re.compile(r"@cqrt_(qram_(store|swap)|tape_effect)")
_MEM_INTRINSIC = re.compile(r"\bcall void @llvm\.mem(cpy|move|set)\.")


def _writes_memory(bodies: Dict[str, str], text: str) -> Any:
    """The test of one line of a lowered body: is it a memory version change (rule 5)? A call by name asks rule 5's static property,
    the least fixpoint over calls by name. A bus store or in-place form, a plain store or memory
    intrinsic to a host-resident object, but a volatile store to a local nothing loads (rules 19, 24) and the compiler's own frame
    slots; an effect entry; an allocation; a table clone's call; a host call unless LLVM's memory attribute says it writes none."""
    attrs = dict(re.findall(r"(?m)^attributes (#\d+) = \{([^\n]*)\}", text))
    decls = {m.group(1): m.group(0) for m in re.finditer(r"(?m)^declare\b[^\n]*?@\"?([-\w.$]+)\"?\([^\n]*$", text)}

    def reads_only(line: str, callee: str) -> bool:
        for tail in (line.rsplit(")", 1)[-1], decls.get(callee, "").rsplit(")", 1)[-1]):
            for a in re.findall(r"#\d+", tail):
                mem = re.search(r"\bmemory\(([^)]*)\)", attrs.get(a, ""))
                if mem and "write" not in mem.group(1):
                    return True
        return False

    def store_changes(line: str, body: str) -> bool:
        m = re.match(r"^\s+store (?:atomic )?(volatile )?[^\n]*, ptr ([@%][-\w.$\"]+)", line)
        p = m.group(2) if m else ""
        if p.startswith("@__cq_act_"):
            return False
        local = re.search(rf"(?m)^\s+{re.escape(p)} = alloca\b", body) if p else None
        if local and p.startswith(("%cq.", '%"cq.')):
            return False
        gep = re.search(rf"(?m)^\s+{re.escape(p)} = getelementptr [^\n]*?, ptr (%\"?cq\.[-\w.$\"]+)", body) if p else None
        if gep:
            return False
        if m and m.group(1) and local and not re.search(rf"\bload [^\n]*ptr {re.escape(p)}\b", body):
            return False
        return True

    def change(line: str, body: str, writes: Set[str]) -> bool:
        if _STORE.match(line):
            return store_changes(line, body)
        if not _CALL_WORD.search(line):
            return bool(_RMW_WORD.search(line))
        if _BUS_WRITE.search(line) or _MEM_INTRINSIC.search(line):
            return True
        names = _CALLED.findall(line)
        if not names:
            return bool(_INDIRECT.search(line))
        g = names[0]
        if g.endswith("_unc") or _NEUTRAL_CALLEE.match(g) or g.startswith("cqe__"):
            return False
        return g in writes if g in bodies else not reads_only(line, g)

    writes: Set[str] = set()
    grew = True
    while grew:
        grew = False
        for f, b in bodies.items():
            if f not in writes and not f.endswith("_unc") and any(change(ln, b, writes) for ln in b.splitlines()):
                writes.add(f)
                grew = True
    return lambda line, body: change(line, body, writes)


class _Flags:
    """The arm flags of one body as Boolean functions of opaque rails, read in text order: two predicates that are never both
    true are the two arms of a quantum branch, laid one after the other in the lowered code (rule 8). None is a true predicate."""

    def __init__(self) -> None:
        self.now: Dict[str, Any] = {}

    def of(self, v: str) -> Any:
        return self.now.get(v, ("atom", v))

    def read(self, line: str) -> None:
        m = _I1_GATE.match(line)
        if not m:
            return
        out, op, args = m.group(1), m.group(2), _LOW_VALUE.findall(m.group(3))
        if op == "cqrt_alloc_i1":
            self.now[out] = ("const", "true" in m.group(3).split()) if not args else ("atom", args[0])
        elif op == "cqrt_not_i1" and len(args) == 1:
            self.now[args[0]] = ("xor", self.of(args[0]), ("const", True))
        elif op in ("cqrt_xor_i1", "cqrt_copy_i1") and len(args) == 2:
            self.now[args[1]] = ("xor", self.of(args[1]), self.of(args[0]))
        elif op in ("cqrt_and_i1", "cqrt_or_i1") and len(args) == 3:
            self.now[args[2]] = ("xor", self.of(args[2]), (op[5:-3], self.of(args[0]), self.of(args[1])))
        elif op.startswith("cq_template_") and out and len(args) == 2:
            self.now[out] = (op[12:-3], self.of(args[0]), self.of(args[1]))

    @staticmethod
    def disjoint(p: Any, q: Any) -> bool:
        """p and q are never both true; False when the functions read too many rails to tell."""
        if p is None or q is None:
            return False
        atoms: Dict[str, int] = {}
        memo: Dict[int, int] = {}

        def collect(e: Any) -> None:
            if id(e) in memo:
                return
            memo[id(e)] = 0
            if e[0] == "atom":
                atoms.setdefault(e[1], len(atoms))
            elif e[0] != "const":
                for x in e[1:]:
                    collect(x)

        collect(p)
        collect(q)
        if len(atoms) > _MAX_ATOMS:
            return False
        size = 1 << len(atoms)
        full = (1 << size) - 1
        # atom i's truth table: bit s set when bit i of s is, the block of 2^i ones over 2^i zeros repeated (a repunit product)
        table = {i: (((1 << (1 << i)) - 1) << (1 << i)) * (full // ((1 << (2 << i)) - 1)) for i in atoms.values()}
        memo.clear()

        def ev(e: Any) -> int:
            if id(e) in memo:
                return memo[id(e)]
            if e[0] == "atom":
                r = table[atoms[e[1]]]
            elif e[0] == "const":
                r = full if e[1] else 0
            elif e[0] == "xor":
                r = ev(e[1]) ^ ev(e[2])
            elif e[0] == "and":
                r = ev(e[1]) & ev(e[2])
            else:
                r = ev(e[1]) | ev(e[2])
            memo[id(e)] = r
            return r

        return not ev(p) & ev(q)


def _overtaken_sites(body: str, bodies: Dict[str, str], changes: Any, loads_bus: Any = None) -> List[Tuple[str, str]]:
    """The calls of one lowered body whose results rule 18 keeps, each (its line, its result): a call of a clone that loads, no twin
    call on its result, and a memory version change after the call and before a reader of the result. The change is on a path from
    the call that does not run the call again (rule 5 sentence 1), its predicate can hold together with the call's (the other arm of
    a quantum branch is emitted in between and overtakes nothing, cq-xbpw6), and a reader is what names the rail: a consumer and
    that consumer's _unc, so a consumer that is never uncomputed has none to wait for (rule 5 sentence 1).
    The body's def-use and control-flow data are built once; each site is then judged on blocks (cq-mx98w): the lines after the call
    on a path that does not reach the call again are the rest of its block and every block reachable from there, the call's own
    block entered again only up to the call."""
    if loads_bus is None:
        loads_bus = lambda g: _loads_bus(g, bodies)  # noqa: E731
    blocks: List[List[str]] = [[]]
    for line in body.splitlines():
        if _BLOCK.match(line):
            blocks.append([])
        elif line.strip() and not line.lstrip().startswith(";"):
            blocks[-1].append(line)
    labels = {m.group(1).strip('"'): i + 1 for i, m in enumerate(_BLOCK.finditer(body))}
    succ: List[List[int]] = []
    for b in blocks:
        out: List[int] = []
        in_term = False
        for ln in b:
            if _TERMINATOR.match(ln):
                in_term = True
            if in_term:
                out.extend(labels[x.strip('"')] for x in _BACK_LABEL.findall(ln) if x.strip('"') in labels)
        succ.append(out)
    preds: List[List[int]] = [[] for _ in blocks]
    for bi, ss in enumerate(succ):
        for s in ss:
            preds[s].append(bi)

    flags = _Flags()
    pred_at: Dict[Tuple[int, int], Any] = {}
    sites = []
    changing: List[List[int]] = [[] for _ in blocks]      # per block, the indices of its memory version changes
    users: Dict[str, List[Tuple[int, int]]] = {}          # value -> the lines that name it right of their " = "
    flows: Dict[str, List[str]] = {}                      # value -> the phi/extractvalue/select i1 results it flows into
    for bi, b in enumerate(blocks):
        for li, ln in enumerate(b):
            m = _HANDLE_CALL.match(ln)
            if m and _CLONE_NAME.match(m.group(4)) and not _TABLE_CLONE.match(m.group(4)) and loads_bus(m.group(4)):
                sites.append((bi, li, m.group(2), m.group(4)))
                pred_at[(bi, li)] = flags.of(_LOW_VALUE.search(ln.split("(", 1)[1]).group(0)) if m.group(4).endswith("_ctl") else None
                if changes(ln, body):
                    changing[bi].append(li)
            elif changes(ln, body):
                changing[bi].append(li)
                c = _CONTROLLED.search(ln)
                name = _CALLED.findall(ln)
                if c:
                    pred_at[(bi, li)] = flags.of(c.group(1))
                elif name and name[0].endswith("_ctl") and _LOW_VALUE.search(ln.split("(", 1)[1]):
                    pred_at[(bi, li)] = flags.of(_LOW_VALUE.search(ln.split("(", 1)[1]).group(0))
                else:
                    pred_at[(bi, li)] = None
            flags.read(ln)
            vals = set(_LOW_VALUE.findall(ln.split(" = ", 1)[-1]))
            for v in vals:
                users.setdefault(v, []).append((bi, li))
            d = _LOW_DEF.match(ln)
            if d and _FLOW_DEF.match(ln):
                for v in set(_LOW_VALUE.findall(ln.split(" = ", 1)[1])):
                    flows.setdefault(v, []).append(d.group(1))
    if not sites:
        return []
    twins: Dict[str, List[Set[str]]] = {}
    out: List[Tuple[str, str]] = []
    for bi, li, r, g in sites:
        line = blocks[bi][li]
        names = {r}
        work = [r]
        while work:
            for d in flows.get(work.pop(), ()):
                if d not in names:
                    names.add(d)
                    work.append(d)
        if g not in twins:
            twin = re.compile(rf"@\"?{re.escape(g)}_unc\"?\(([^\n]*)\)")
            twins[g] = [set(_LOW_VALUE.findall(t.group(1))) for t in twin.finditer(body)] if f"{g}_unc" in body else []
        if any(names & t for t in twins[g]):
            continue
        # the readers of the result, per block (sorted line indices)
        rd: Dict[int, List[int]] = {}
        for n in names:
            for x, y in users.get(n, ()):
                rd.setdefault(x, []).append(y)
        for v in rd.values():
            v.sort()
        # can: entering the block reaches a reader before reaching the call again; the call's block ends at the call
        can: Set[int] = set()
        work_b = []
        for x, ys in rd.items():
            if x != bi or ys[0] < li:
                can.add(x)
                work_b.append(x)
        while work_b:
            for q in preds[work_b.pop()]:
                if q not in can and q != bi:
                    can.add(q)
                    work_b.append(q)
        # the blocks reachable after the call on a path that does not run it again
        seen: Set[int] = set()
        stack = list(succ[bi])
        while stack:
            s = stack.pop()
            if s not in seen:
                seen.add(s)
                if s != bi:
                    stack.extend(succ[s])
        p = pred_at[(bi, li)]

        def judged(x: int, ys: Sequence[int], before_call: bool = False) -> bool:
            """A change at (x, y) for y in ys whose predicate meets the call's and from which a reader is reached: in its own
            block at or after it (before the call, when it precedes the call in the call's block), or through a successor."""
            ry = rd.get(x, [])
            via = not before_call and any(s in can for s in succ[x])
            for y in ys:
                k = bisect.bisect_left(ry, y)
                if via or (k < len(ry) and (not before_call or ry[k] < li)):
                    if not _Flags.disjoint(p, pred_at.get((x, y))):
                        return True
            return False

        if judged(bi, [y for y in changing[bi] if y > li]) \
                or (bi in seen and judged(bi, [y for y in changing[bi] if y < li], True)) \
                or any(judged(x, changing[x]) for x in sorted(seen) if x != bi and changing[x]):
            out.append((line, r))
    return out


def overtaken_twin_module(text: str) -> str:
    """Rule 18, a kept rail CR §6 item 1 names: "a result of a clone that loads that one overtook before its twin". Each such call is
    judged by itself on the lowered body (_overtaken_sites), and its result marked kept; any other call of a loading clone left
    without its twin stays a leak, whatever the clone's other calls do and whether or not a twin is defined."""
    if "@__cq_q_" not in text:
        return text
    bodies = {m.group(1): m.group(2) for m in _FN_BODY.finditer(text)}
    changes = _writes_memory(bodies, text)
    loads: Dict[str, bool] = {}

    def loads_bus(g: str) -> bool:
        if g not in loads:
            loads[g] = _loads_bus(g, bodies)
        return loads[g]
    marks: Dict[str, List[Tuple[str, str]]] = {}
    for f, b in bodies.items():
        if b and not _TWIN_OF_CLONE.match(f) and "@__cq_q_" in b:
            ss = _overtaken_sites(b, bodies, changes, loads_bus)
            if ss:
                marks[f] = ss
    if not marks:
        return text
    out, cur = [], None
    for line in text.splitlines():
        out.append(line)
        if line.startswith("define"):
            m = DEFINE_NAME.match(line)
            cur = None
            if m and m.group(2) in marks:
                cur = {}
                for site, r in marks[m.group(2)]:
                    cur.setdefault(site, []).append(r)
        elif line.startswith("}"):
            cur = None
        elif cur and line in cur:
            for r in cur[line]:
                ind = re.match(r"\s+", line).group(0)
                head = re.match(r"^\s+\S+ = (?:tail |notail )?call (?:[^@]*\s)?(i32|\{[^}]*\}) @", line)
                tag = r.lstrip("%").strip('"')
                if head and head.group(1) == "i32":
                    out.append(f"{ind}call void @cqe__set_store_kept(i32 {r})")
                elif head:
                    for k in _flat_fields(head.group(1)):
                        out.append(f"{ind}%cqe.ovt.{tag}.{k} = extractvalue {head.group(1)} {r}, {k}")
                        out.append(f"{ind}call void @cqe__set_store_kept(i32 %cqe.ovt.{tag}.{k})")
    if "declare void @cqe__set_store_kept" not in text:
        out.append("declare void @cqe__set_store_kept(i32)")
    return "\n".join(out) + "\n"


_AK_ALLOC = re.compile(r"^\s+(%[-\w.$]+) = (?:tail |notail )?call i32 @cqrt_alloc_i1\(i1 (?:false|0)\)\s*$")
_AK_TOKEN = re.compile(r"%[-\w.$]+")
_AK_PHI = re.compile(r"^\s+(%[-\w.$]+) = phi i32 ")
# the gates that write an i1 rail named last and read only the others: and_i1(a, b, t), copy_i1(a, t), xor_i1(a, t)
_AK_WRITE = re.compile(r"^\s+(?:tail |notail )?call void @cqrt_(?:and_i1\(i32 (%[-\w.$]+), i32 (%[-\w.$]+)|"
                       r"(?:copy|xor)_i1\(i32 (%[-\w.$]+)), i32 (%[-\w.$]+)\)\s*$")


def _ak_allocs(lines: List[str], lo: int, hi: int) -> List[int]:
    """The line indices in lines[lo:hi] (one function body) of the a_K allocs of kept_ak_module. Every line is read
    for uses, a phi before the alloc included (a back edge)."""
    cand: Dict[str, int] = {}
    for i in range(lo, hi):
        m = _AK_ALLOC.match(lines[i])
        if m:
            cand[m.group(1)] = i
    if not cand:
        return []
    at = set(cand.values())
    # The chain's end merged at a classical exit of the chain (CR rule 14: at a classical test "the chain ends there,
    # `a_j` is ... through a classical `phi` of handles"; rule 27 "Cutoff": the received-K cut "is a classical exit of
    # the chain", a_K there the test's predicate, cq-9kcq, cq-wkzu9): an i32 phi that nothing reads but other such phis
    # holds the kept a_K of whichever path ran. Its incomings are no read of an a_K candidate; every other use still is.
    phis: Dict[str, int] = {}
    for i in range(lo, hi):
        m = _AK_PHI.match(lines[i])
        if m:
            phis[m.group(1)] = i
    users: Dict[str, List[int]] = {p: [] for p in phis}
    for i in range(lo, hi):
        for t in _AK_TOKEN.findall(lines[i]):
            if t in users and i != phis[t]:
                users[t].append(i)
    sink = set(phis)
    while True:
        lines_in = {phis[p] for p in sink}
        drop = {p for p in sink if any(i not in lines_in for i in users[p])}
        if not drop:
            break
        sink -= drop
    sink_lines = {phis[p] for p in sink}
    written: Set[str] = set()
    bad: Set[str] = set()
    for i in range(lo, hi):
        line = lines[i]
        if i in at or i in sink_lines:
            continue
        toks = [t for t in _AK_TOKEN.findall(line) if t in cand]
        if not toks:
            continue
        w = _AK_WRITE.match(line)
        tgt = w.group(4) if w else None
        reads = [t for t in (w.groups()[:3] if w else ()) if t]
        for t in toks:
            if w and t == tgt and t not in reads and toks.count(t) == 1:
                written.add(t)
            else:
                bad.add(t)               # read, uncomputed, freed or anything else: no a_K
    return [cand[v] for v in sorted(written - bad, key=cand.get)]


def kept_ak_module(text: str) -> str:
    """Rule 14's kept overflow predicate a_K, a kept rail CR §6 item 1 names (owner 2026-11-09, cq-1leyz: identified
    structurally in the lowered program): a rail alloc_i1(0) whose every use is as the written rail of and_i1(a, b, t),
    copy_i1(a, t) or xor_i1(a, t). Nothing reads it, nothing uncomputes or frees it: the K-th chain predicate
    `a_{K-1} & cond_K` of a K-loop with B > K (pass loops/cutoff andRail, kept as Role::KeptOverflow), the XOR of an
    exit arm's sub-loop chain ends (armKept), a recursion's overflow predicate its first outside caller keeps (cq-ew5z)
    and the copy_i1 of the predicate at an activation counter's cut (calls/Calls.cpp: rule 14's kept overflow predicate
    of a quantum-depth recursion), and rule 22's n > K2 of a memory intrinsic's rail length under a predicate c in scope,
    and_i1(n > K2, c, t) with the raw compare undone (bus/Intrinsics.cpp quantumTrips, cq-cwl9g). The pass's own reading of a kept a_K is the same (calls/Finalize.cpp, keptK). Each such rail gets the exit
    role a_K (rt/core.c cqe__set_kept_ak). A rail anything reads, uncomputes or frees is not one, whatever it reads at
    exit."""
    if "@cqrt_alloc_i1(i1 false)" not in text and "@cqrt_alloc_i1(i1 0)" not in text:
        return text
    lines = text.splitlines()
    marks: Set[int] = set()     # the line indices of the a_K allocs
    start = None
    for i, line in enumerate(lines):
        if line.startswith("define"):
            start = i + 1
        elif line.startswith("}") and start is not None:
            marks.update(_ak_allocs(lines, start, i))
            start = None
    if not marks:
        return text
    out = []
    for i, line in enumerate(lines):
        out.append(line)
        if i in marks:
            ind = re.match(r"\s+", line).group(0)
            out.append(f"{ind}call void @cqe__set_kept_ak(i32 {_AK_ALLOC.match(line).group(1)})")
    out.append("declare void @cqe__set_kept_ak(i32)")
    return "\n".join(out) + "\n"


_K2_CMP = re.compile(r"^\s+(%[-\w.$]+) = (?:tail |notail )?call i32 @cq_template_icmp_ugt_i64_hl\(i32 (%[-\w.$]+), i64 (\d+)\)\s*$")
# the allocation: __cq_alloc, or its recording stand-in cqe__q2_alloc once host_effects_module has run (rulings Q2,
# 2026-11-11: the same call, sent to rt_bus.c so its block is recorded; kept_k2_module runs after that rewrite)
_K2_ALLOC = re.compile(r"^\s+%[-\w.$]+ = (?:tail |notail )?call (?:noalias )?ptr @(?:__cq_alloc|cqe__q2_alloc)\(i64 (\d+), i64 [^)]*\)\s*$")
# what the uncompute spine may emit between the two once the compare was the size's last consumer: its producers' _unc
# (a template's or a twin's) and their frees
_K2_SPINE = re.compile(r"^\s+(?:tail |notail )?call void @(?:[-\w.$]+_unc|cqrt_free)\(")
# rule 22 (cq-dl7da): a memory intrinsic's rail length n takes K2 trips: after the compare (and a memset's seed of its
# classical byte) the host loop's entry branch, its counter from 0, the byte predicate p_j = icmp_ugt_i64_hl(n, j) of the
# same n, and the exit test against K2 (bus/Intrinsics.cpp quantumTrips, emitSet, emitCopyOf, hostLoop)
_K2_SEED = re.compile(r"^\s+%[-\w.$]+ = (?:tail |notail )?call i32 @cqrt_alloc_i8\(i8 -?\d+\)\s*$")
_K2_BR = re.compile(r"^\s+br label %([-\w.$]+)\s*$")
_K2_PHI = re.compile(r"^\s+(%[-\w.$]+) = phi i64 \[ 0, %[-\w.$]+ \], \[ %[-\w.$]+, %([-\w.$]+) \]\s*$")
_K2_LOOP_BR = re.compile(r"^\s+br i1 %[-\w.$]+, label %[-\w.$]+, label %([-\w.$]+)\s*$")


_K2_LABEL = re.compile(r"([-\w.$]+):(?:\s|$)")


def _k2_trips(lines: List[str], j: int, hi: int, labels: Dict[str, int], n: str, k2: str) -> bool:
    """Whether lines[j:] (in a function body ending at hi, its block labels at labels) are rule 22's K2 trips of a rail
    length n right after its n > K2 compare: a memset's seed at most, then the branch into a host loop whose block counts
    j from 0, computes icmp_ugt_i64_hl(n, j) and leaves after K2 trips."""
    while j < hi and _K2_SEED.match(lines[j]):
        j += 1
    b = _K2_BR.match(lines[j]) if j < hi else None
    if not b:
        return False
    head = labels.get(b.group(1))
    if head is None or head + 1 >= hi:
        return False
    phi = _K2_PHI.match(lines[head + 1])
    if not phi or phi.group(2) != b.group(1):
        return False
    pred = re.compile(rf"^\s+%[-\w.$]+ = (?:tail |notail )?call i32 @cq_template_icmp_ugt_i64_hl\(i32 {re.escape(n)}, "
                      rf"i64 {re.escape(phi.group(1))}\)\s*$")
    done = re.compile(rf"^\s+%[-\w.$]+ = icmp eq i64 %[-\w.$]+, {k2}\s*$")
    seen_pred = seen_done = False
    for i in range(head + 2, hi):
        if _K2_LABEL.match(lines[i]) or _K2_BR.match(lines[i]):
            return False
        e = _K2_LOOP_BR.match(lines[i])
        if e:
            return e.group(1) == b.group(1) and seen_pred and seen_done
        seen_pred = seen_pred or bool(pred.match(lines[i]))
        seen_done = seen_done or bool(done.match(lines[i]))
    return False


def _k2_cmps(lines: List[str], lo: int, hi: int) -> List[int]:
    """The line indices in lines[lo:hi] (one function body) of the n > K2 compares of kept_k2_module."""
    cand: Dict[str, int] = {}
    labels: Optional[Dict[str, int]] = None
    for i in range(lo, hi):
        m = _K2_CMP.match(lines[i])
        if not m:
            continue
        j = i + 1
        while j < hi and _K2_SPINE.match(lines[j]) and m.group(1) not in _AK_TOKEN.findall(lines[j]):
            j += 1
        a = _K2_ALLOC.match(lines[j]) if j < hi else None
        if a and a.group(1) == m.group(3):
            cand[m.group(1)] = i
            continue
        if labels is None:               # once per function, only where a constant compare is
            labels = {lb.group(1): k for k in range(lo, hi) for lb in [_K2_LABEL.match(lines[k])] if lb}
        if _k2_trips(lines, i + 1, hi, labels, m.group(2), m.group(3)):
            cand[m.group(1)] = i
    if not cand:
        return []
    at = set(cand.values())
    used: Set[str] = set()               # read, uncomputed, freed or anything else: no n > K2
    for i in range(lo, hi):
        if i not in at:
            used.update(t for t in _AK_TOKEN.findall(lines[i]) if t in cand)
    return sorted(cand[v] for v in cand if v not in used)


# owner ruling 2026-11-12 cq-mrdkr: calloc(n, s) with a rail operand keeps or_i1(overflow, n*s > K2) in a fresh i1 rail
# (bus/Alloc.cpp lowerCalloc): the umul_overflow template o and the compare g, the fresh rail k, or_i1(o, g, k), then o and
# g undone at once (their _unc and frees, among the spine's) right before __cq_alloc(K2, align); nothing else touches k
_K2_FRESH = re.compile(r"^\s+(%[-\w.$]+) = (?:tail |notail )?call i32 @cqrt_alloc_i1\(i1 false\)\s*$")
_K2_OR = re.compile(r"^\s+(?:tail |notail )?call void @cqrt_or_i1\(i32 (%[-\w.$]+), i32 (%[-\w.$]+), i32 (%[-\w.$]+)\)\s*$")
_K2_OVF = re.compile(r"^\s+(%[-\w.$]+) = (?:tail |notail )?call i32 @cq_template_umul_overflow_i64(?:_hl|_lh)?\(")


def _k2_ors(lines: List[str], lo: int, hi: int) -> List[Tuple[int, str]]:
    """(the or_i1 line, k) of every calloc kept predicate k = or_i1(overflow, n*s > K2) in lines[lo:hi] (one function
    body), kept_k2_module: o a umul_overflow template, g = icmp_ugt_i64_hl(n*s, K2), k = cqrt_alloc_i1(false) right
    before or_i1(o, g, k); then only the spine's _unc and frees, among them o's and g's _unc and free, up to
    __cq_alloc(K2, align) of the same K2; and no other line of the body names k."""
    defs: Dict[str, int] = {}
    for i in range(lo, hi):
        d = re.match(r"^\s+(%[-\w.$]+) = ", lines[i])
        if d:
            defs[d.group(1)] = i
    out = []
    for i in range(lo, hi - 1):
        f = _K2_FRESH.match(lines[i])
        o = _K2_OR.match(lines[i + 1]) if f else None
        if not o or o.group(3) != f.group(1):
            continue
        ov, g, k = o.group(1), o.group(2), o.group(3)
        if ov == g or ov == k or g == k or ov not in defs or g not in defs:
            continue
        cmp_ = _K2_CMP.match(lines[defs[g]])
        if not cmp_ or not _K2_OVF.match(lines[defs[ov]]) or cmp_.group(1) != g:
            continue
        j = i + 2
        undone = {ov: [False, False], g: [False, False]}
        while j < hi and _K2_SPINE.match(lines[j]) and k not in _AK_TOKEN.findall(lines[j]):
            toks = _AK_TOKEN.findall(lines[j])
            for r, st in undone.items():
                if toks and toks[0] == r:
                    st[0 if "_unc(" in lines[j] else 1] = True
            j += 1
        a = _K2_ALLOC.match(lines[j]) if j < hi else None
        if not a or a.group(1) != cmp_.group(3) or not all(all(st) for st in undone.values()):
            continue
        if any(k in _AK_TOKEN.findall(lines[x]) for x in range(lo, hi) if x not in (i, i + 1)):
            continue
        out.append((i + 1, k))
    return out


def kept_k2_module(text: str) -> str:
    """Rule 20's kept overflow predicate n > K2 of a rail-sized allocation, a kept rail CR §6 item 1 names (owner
    2026-11-09, cq-0ldab: identified structurally in the lowered program): a rail `icmp_ugt_i64_hl(n, K2)` followed by
    `__cq_alloc(K2, align)` of the same K2 (or `cqe__q2_alloc`, host_effects_module's name for the same call), with nothing between them but the uncompute spine's _unc and frees, and that
    nothing reads, uncomputes or frees. The pass's own emission is the same (bus/Alloc.cpp sizeOperand: the compare,
    Role::KeptOverflow, then the call with K2 as its size; lowerAlloc, lowerRealloc). Likewise rule 22's n > K2 of a
    memory intrinsic whose length is a rail, unpredicated (cq-dl7da): the compare followed by the intrinsic's K2 trips
    (_k2_trips; bus/Intrinsics.cpp quantumTrips with no predicate in scope, Role::KeptOverflow). Each such rail gets the
    exit role n>K2 (rt/core.c cqe__set_kept_k2). A look-alike compare anything reads, or one neither such an allocation
    nor such trips follow, is not one, whatever it reads at exit. Likewise calloc's kept or_i1(overflow, n*s > K2) (owner
    ruling 2026-11-12 cq-mrdkr; _k2_ors): the C side's n > K2 of a calloc is the saturated product's, so overflow reads 1
    there too (oracle.py _k2_sites, cqo_rt.c __cqo_calloc_k2)."""
    if "@cq_template_icmp_ugt_i64_hl(" not in text:
        return text
    lines = text.splitlines()
    marks: Dict[int, str] = {}
    start = None
    for i, line in enumerate(lines):
        if line.startswith("define"):
            start = i + 1
        elif line.startswith("}") and start is not None:
            marks.update((c, _K2_CMP.match(lines[c]).group(1)) for c in _k2_cmps(lines, start, i))
            marks.update(_k2_ors(lines, start, i))
            start = None
    if not marks:
        return text
    out = []
    for i, line in enumerate(lines):
        out.append(line)
        if i in marks:
            ind = re.match(r"\s+", line).group(0)
            out.append(f"{ind}call void @cqe__set_kept_k2(i32 {marks[i]})")
    out.append("declare void @cqe__set_kept_k2(i32)")
    return "\n".join(out) + "\n"


# ---- clone replay (cq-kcn5i; DECISIONS 2026-11-08, owner option (a)) ---------------------------------------
#
# replay_module wraps every eligible clone (DESIGN §4) so that the evaluator runs each distinct call once and replays
# it exactly afterwards (checker/rt/rt_replay.c has the runtime and the key). Eligible: a forward clone
# __cq_q_<fn>_<mask>[_b...][_t][_ctl] (no twin: _unc, _pure) with scalar parameters (iN up to 64, ptr, half, float,
# double; one per ABI argument: the _ctl predicate, then one per mask digit, a 1 an i32 handle) and a void or scalar
# result, whose body and every clone it calls by name hold only templates (no _rm, _rmq, _exc), cqrt_ alloc, free,
# the i1 gates, copy, xorc, bus load/store/swap, push and pop (cq-mxe2q, owner 2026-11-08: the runtime records only a
# window whose pops take only its own pushes and that ends at the depth it began at, dispatch.c), __cq_mem, the module's totalisation helpers, pure llvm
# intrinsics, cqe__set_store_kept and cqe__set_kept_ak; no load, store or other memory instruction, no indirect call, no inline asm.
# The runtime checks again what the text cannot show (a rail outside the call's arguments, a trace line, a
# violation, an argument changed: no record). The wrapper is never instrumented (nosanitize_coverage): steps are
# the real body's, replayed or run.
#
# cq-kcn5i extensions (each argued in its commit):
#   pure helpers   a call of a module function that is not a clone and whose body, and every body it calls, has no
#                  memory instruction (load, store, alloca, ...), no indirect call, no asm and no call but pure llvm
#                  intrinsics and such helpers, and whose definition the link cannot replace (not weak, linkonce,
#                  available_externally or common): its result is a function of its arguments and of link-time addresses
#                  only, and it touches nothing the evaluator holds but the step count, which the record carries
#                  (musl's __errno_location, `ret ptr @__cq_tp + 52`, in mbtowc).
#   counters       a plain i32 or i64 load or store of a whole pass-minted counter (@__cq_act_<f>, rule 14's activation counter,
#                  and @__cq_k) goes through __cqe_rp_gload_iN / __cqe_rp_gstore_iN in every eligible body: a window
#                  logs the value of each counter it read before writing it (the record applies only where each reads
#                  the same) and the final value of each it wrote (a hit stores them); rt_replay.c.
#   twins          a clone that is not wrapped (a twin: _unc, _pure) may be called by name from an eligible body when
#                  its own body meets the same conditions: it then runs inside the caller's window, where the runtime
#                  watches it as it watches the body (rails outside the arguments, the word stack, the bus, counters).
#   table clones   __cq_q_<fn>_<mask>_t[_ctl] (rule 19's dispatch targets) under the same conditions on the body; the
#                  received K, their last parameter, is a classical argument and so part of the key.
#   alloca         a body with an alloca is never eligible: its address is the recording run's stack, and a replay
#                  from another depth would read and write that old address.

_RP_CLONE = re.compile(r"^__cq_q_(.+)_(v|[01]+)(?:_b\d+(?:_\d+)*)?(_t)?(_ctl)?$")
_RP_HEAD = re.compile(r'^define\s+(?P<pre>[^@]*?)\s*@(?P<name>[-\w.$]+)\(')
_RP_CC = re.compile(r"\b(fastcc|coldcc|ccc|tailcc|swiftcc|swifttailcc|cc \d+)\b")
_RP_SCALAR = re.compile(r"^(?:i(\d+)|ptr|half|float|double)$")
_RP_CQRT_OK = re.compile(r"^cqrt_(?:alloc_\w+|free|push|pop|(?:not|and|or|xor)_i1(?:_unc)?|copy_\w+|xorc_\w+|"
                         r"qram_(?:load|store|swap)_\w+)$")
_RP_LLVM_OK = re.compile(r"^llvm\.(?:smax|smin|umax|umin|abs|ctlz|cttz|ctpop|bswap|bitreverse|fshl|fshr|"
                         r"[su](?:add|sub|mul)\.with\.overflow|[su](?:add|sub)\.sat|[su]shl\.sat|assume|expect|"
                         r"lifetime\.(?:start|end))(?:\.|$)")
_RP_HELPER_OK = re.compile(r"^(?:__cqe_rp_g(?:load|store)_i(?:32|64)$|__cqe_tot\.|__cqe_fpto(?:64|80)$|__cqe_fpdfl_(?:enter|leave)$|cqe__set_store_kept$|cqe__set_kept_ak$|__cq_mem$)")
_RP_BAD = re.compile(r"(?m)^\s+(?:%[-\w.$\"]+ = )?(?:load|store|alloca|atomicrmw|cmpxchg|va_arg|fence|invoke|callbr|"
                     r"landingpad|resume|indirectbr)\b|\basm\b")
_RP_GNAME = r"(?:__cq_act_[-\w.$]+|__cq_k)"
_RP_GDEF = re.compile(rf"(?m)^@({_RP_GNAME}) = [^\n]*?\bglobal (i32|i64) ")
_RP_GLOAD = re.compile(rf"(?m)^(\s+%[-\w.$\"]+ = )load (i32|i64), ptr @({_RP_GNAME})(?:, align \d+)?$")
_RP_GSTORE = re.compile(rf"(?m)^(\s+)store (i32|i64) ([^\s,]+), ptr @({_RP_GNAME})(?:, align \d+)?$")


def _rp_counters(body: str, gty: Dict[str, str]) -> str:
    """body with every plain whole-width load and store of a pass-minted counter as a call of the runtime's hook."""
    def ld(m):
        return (f"{m.group(1)}call {m.group(2)} @__cqe_rp_gload_{m.group(2)}(ptr @{m.group(3)})"
                if gty.get(m.group(3)) == m.group(2) else m.group(0))

    def st(m):
        return (f"{m.group(1)}call void @__cqe_rp_gstore_{m.group(2)}(ptr @{m.group(4)}, {m.group(2)} {m.group(3)})"
                if gty.get(m.group(4)) == m.group(2) else m.group(0))
    if "@__cq_" not in body:
        return body
    return _RP_GSTORE.sub(st, _RP_GLOAD.sub(ld, body))


_RP_INTERPOSABLE = re.compile(r"\b(?:weak|weak_odr|linkonce|linkonce_odr|available_externally|extern_weak|common)\b")


def _rp_pure_helpers(bodies: Dict[str, str], pres: Dict[str, str]) -> Set[str]:
    """The module's pure helpers (module comment above): the greatest set closed under 'calls only pure intrinsics
    and members'. pres: per function the text of its define line before the name (its linkage)."""
    calls: Dict[str, Set[str]] = {}
    for f, b in bodies.items():
        if f not in pres or _RP_INTERPOSABLE.search(pres[f]):
            continue   # the link may give the name another body
        if f.startswith(("__cq_q_", "cq_", "cqrt_", "cqe_", "__cqe_", "llvm.")) or _RP_BAD.search(b) or _INDIRECT.search(b):
            continue
        cs = set(_CALLED.findall(b))
        if any(g.startswith("llvm.") and not _RP_LLVM_OK.match(g) for g in cs):
            continue
        calls[f] = {g for g in cs if not g.startswith("llvm.")}
    changed = True
    while changed:
        changed = False
        for f in sorted(calls):
            if any(g not in calls for g in calls[f]):
                del calls[f]
                changed = True
    return set(calls)


def _rp_scalar(t: str) -> bool:
    m = _RP_SCALAR.match(t)
    return bool(m) and (m.group(1) is None or 1 <= int(m.group(1)) <= 64)


def _rp_head(line: str) -> Optional[Tuple[str, str, str]]:
    """A define line with a body: (pre, name, the parameter list's text)."""
    m = _RP_HEAD.match(line)
    if not m or not line.rstrip().endswith("{"):
        return None
    depth, i = 1, m.end()
    while i < len(line) and depth:
        depth += {"(": 1, ")": -1}.get(line[i], 0)
        i += 1
    return (m.group("pre"), m.group("name"), line[m.end():i - 1]) if not depth else None


def _rp_params(params: str) -> Optional[List[Tuple[str, str]]]:
    out = []
    for p in _split_top(params) if params.strip() else []:
        toks = p.split()
        if len(toks) < 2 or not toks[-1].startswith("%"):
            return None
        out.append((toks[0], toks[-1]))
    return out


def replay_clones(text: str, handle_fns: Sequence[str]) -> Dict[str, dict]:
    """The eligible clones of a lowered module: name -> {head, params, kinds, rk, cc, rty} (module comment above)."""
    bodies = {m.group(1): m.group(2) for m in _FN_BODY.finditer(text)}
    heads = {}
    for line in text.splitlines():
        if line.startswith("define"):
            h = _rp_head(line)
            if h:
                heads[h[1]] = h
    gty = dict(_RP_GDEF.findall(text))
    pure = _rp_pure_helpers(bodies, {f: h[0] for f, h in heads.items()})
    # safe: the clones (forward, table, twins) whose body may run inside a window; calls: their by-name clone callees
    calls: Dict[str, Set[str]] = {}
    safe_body: Dict[str, str] = {}
    for f, b in bodies.items():
        if not f.startswith("__cq_q_"):
            continue
        b = _rp_counters(b, gty)
        if _RP_BAD.search(b) or _INDIRECT.search(b):
            continue
        callees = set(_CALLED.findall(b))
        ok = True
        for g in callees:
            if g.startswith("cq_template_"):
                if set(g.split("_")) & {"rm", "rmq", "exc"}:
                    ok = False
            elif g.startswith("cqrt_"):
                ok = ok and bool(_RP_CQRT_OK.match(g))
            elif g.startswith("llvm."):
                ok = ok and bool(_RP_LLVM_OK.match(g))
            elif not (_RP_HELPER_OK.match(g) or g.startswith("__cq_q_") or g in pure):
                ok = False
        if ok:
            calls[f] = {g for g in callees if g.startswith("__cq_q_")}
            safe_body[f] = b
    changed = True
    while changed:
        changed = False
        for f in sorted(calls):
            if any(g not in calls for g in calls[f]):
                del calls[f]
                changed = True
    cand: Dict[str, dict] = {}
    for f in calls:
        b = safe_body[f]
        c = _RP_CLONE.match(f)
        if not c or f not in heads:
            continue
        pre_s, _, ptext = heads[f]
        pre = pre_s.split()
        rty = pre[-1] if pre else ""
        params = _rp_params(ptext)
        if params is None or len(params) > 32 or not (rty == "void" or _rp_scalar(rty)):
            continue
        kinds = (("h" if c.group(4) else "") + "".join("h" if d == "1" else "c" for d in (c.group(2) if c.group(2) != "v" else ""))
                 + ("c" if c.group(3) else ""))   # a table clone's last parameter is the received K (rule 19), classical
        if len(kinds) != len(params) or any(not _rp_scalar(t) or (k == "h" and t != "i32") for (t, _), k in zip(params, kinds)):
            continue
        pnames = [n for _, n in params]
        if rty == "void":
            rk = "v"
        elif rty != "i32":
            rk = "c"
        else:
            is_rail = _rail_tester(b, handle_fns)
            ks = set()
            for r in re.finditer(r"(?m)^\s+ret i32 (%[-\w.$\"]+|-?\d+)", b):
                v = r.group(1)
                if v in pnames:
                    ks.add(kinds[pnames.index(v)])
                elif re.fullmatch(r"-?\d+", v):
                    ks.add("0" if v == "0" else "c")
                else:
                    ks.add("h" if is_rail(v) else "c")
            ks.discard("0")
            if len(ks) > 1:
                continue
            rk = "h" if ks == {"h"} else "i"   # i: a classical i32 (rt_replay.c never records one that names a rail made inside)
        ccm = _RP_CC.search(pre_s)
        cand[f] = {"ptext": ptext, "pre": pre_s, "params": params, "kinds": kinds, "rk": rk, "rty": rty,
                   "cc": ccm.group(1) + " " if ccm else "", "safe": set(calls)}
    return cand


def _rp_to64(t: str, v: str, tag: str, out: List[str]) -> str:
    if t == "i64":
        return v
    if t == "ptr":
        out.append(f"  %cqe.{tag} = ptrtoint ptr {v} to i64")
    elif t == "double":
        out.append(f"  %cqe.{tag} = bitcast double {v} to i64")
    elif t in ("float", "half"):
        w = 32 if t == "float" else 16
        out.append(f"  %cqe.{tag}.b = bitcast {t} {v} to i{w}")
        out.append(f"  %cqe.{tag} = zext i{w} %cqe.{tag}.b to i64")
    else:
        out.append(f"  %cqe.{tag} = zext {t} {v} to i64")
    return f"%cqe.{tag}"


def _rp_from64(t: str, v: str, tag: str, out: List[str]) -> str:
    if t == "i64":
        return v
    if t == "ptr":
        out.append(f"  %cqe.{tag} = inttoptr i64 {v} to ptr")
    elif t == "double":
        out.append(f"  %cqe.{tag} = bitcast i64 {v} to double")
    elif t in ("float", "half"):
        w = 32 if t == "float" else 16
        out.append(f"  %cqe.{tag}.b = trunc i64 {v} to i{w}")
        out.append(f"  %cqe.{tag} = bitcast i{w} %cqe.{tag}.b to {t}")
    else:
        out.append(f"  %cqe.{tag} = trunc i64 {v} to {t}")
    return f"%cqe.{tag}"


def replay_module(text: str, handle_fns: Sequence[str]) -> str:
    """text with every eligible clone S renamed S.real and a wrapper S that asks the runtime for a replay first
    (rt_replay.c __cqe_rp_enter / __cqe_rp_leave). The clone ids are their sorted order: deterministic."""
    cand = replay_clones(text, handle_fns)
    if not cand:
        return text
    lines = text.splitlines()
    ids = {f: i for i, f in enumerate(sorted(cand))}
    gty = dict(_RP_GDEF.findall(text))
    safe = next(iter(cand.values()))["safe"]   # every body that may run inside a window
    inside, hooks = False, False
    for i, line in enumerate(lines):
        if line.startswith("define"):
            m = _RP_HEAD.match(line)
            inside = bool(m and m.group("name") in safe)
            h = _rp_head(line)
            if h and h[1] in cand:
                lines[i] = line.replace(f"@{h[1]}(", f"@{h[1]}.real(", 1)
        elif line == "}":
            inside = False
        elif inside and gty and "@__cq_" in line:   # the counters of such a body through the runtime's hooks
            lines[i] = _rp_counters(line, gty)
            hooks = hooks or lines[i] != line
    out = ["\n".join(lines)]
    if hooks:
        out.append("\n".join(f"declare i{w} @__cqe_rp_gload_i{w}(ptr)\ndeclare void @__cqe_rp_gstore_i{w}(ptr, i{w})"
                             for w in (32, 64)))
    for f in sorted(cand):
        c, k = cand[f], ids[f]
        params, rty = c["params"], c["rty"]
        n = max(len(params), 1)
        desc = f"{f}|{c['kinds']}|{c['rk']}"
        out.append(f'@.cqe.rp.{k} = private unnamed_addr constant [{len(desc) + 1} x i8] c"{desc}\\00"')
        w = [f"define {c['pre']} @{f}({c['ptext']}) nosanitize_coverage {{",
             "cqe.entry:", f"  %cqe.a = alloca [{n} x i64], align 8", "  %cqe.r = alloca i64, align 8",
             "  store i64 0, ptr %cqe.r, align 8"]
        for i, (t, v) in enumerate(params):
            w.append(f"  %cqe.p{i} = getelementptr inbounds [{n} x i64], ptr %cqe.a, i64 0, i64 {i}")
            x = _rp_to64(t, v, f"x{i}", w)
            w.append(f"  store i64 {x}, ptr %cqe.p{i}, align 8")
        w += [f"  %cqe.hit = call i32 @__cqe_rp_enter(i32 {k}, ptr @.cqe.rp.{k}, ptr %cqe.a, ptr %cqe.r)",
              "  %cqe.c = icmp ne i32 %cqe.hit, 0", "  br i1 %cqe.c, label %cqe.replay, label %cqe.run", "cqe.replay:"]
        if rty == "void":
            w.append("  ret void")
        else:
            w.append("  %cqe.v = load i64, ptr %cqe.r, align 8")
            w.append(f"  ret {rty} {_rp_from64(rty, '%cqe.v', 'rv', w)}")
        w.append("cqe.run:")
        call = f"call {c['cc']}{rty} @{f}.real({', '.join(f'{t} {v}' for t, v in params)})"
        if rty == "void":
            w.append(f"  {call}")
        else:
            w.append(f"  %cqe.y = {call}")
            w.append(f"  store i64 {_rp_to64(rty, '%cqe.y', 'y64', w)}, ptr %cqe.r, align 8")
        w.append(f"  call void @__cqe_rp_leave(i32 {k}, ptr %cqe.r)")
        w.append("  ret void" if rty == "void" else f"  ret {rty} %cqe.y")
        w.append("}")
        out.append("\n".join(w))
    out.append("declare i32 @__cqe_rp_enter(i32, ptr, ptr, ptr)\ndeclare void @__cqe_rp_leave(i32, ptr)")
    return "\n".join(out) + "\n"


def _rail_tester(body: str, handle_fns: Sequence[str]):
    """Is this value of one clone body a rail it holds: not a constant, not a classical computation. A formal
    (%0, ...) is a rail only when returned as a handle; a clone returns fresh copies (rule 18), so it is not marked."""
    defs = dict(m.groups() for m in re.finditer(r"(?m)^\s+(%[-\w.$\"]+) = (.*)$", body))
    hf = set(handle_fns)

    def rail(v: str, seen: Set[str]) -> bool:
        if v not in defs or v in seen:
            return False
        seen.add(v)
        rhs = defs[v]
        op = rhs.split(" ", 1)[0]
        if op == "phi":
            return any(rail(a.strip(), seen) for a in re.findall(r"\[\s*([^,\]]+),", rhs))
        if op == "extractvalue":
            mm = re.match(r"extractvalue \{[^}]*\} (\S+), (\d+)", rhs)
            return bool(mm) and rail(mm.group(1), seen)
        m = _CALLEE.search(rhs)
        if not m or not re.match(r"^(tail |musttail |notail )?call\b", rhs):
            return False
        c = m.group(2)
        if c.startswith("cq_template_"):
            return not c.endswith("_unc")
        if c.startswith("cqrt_"):
            return c.startswith(_RAIL_CALLS) or c.startswith("cqrt_tape_effect_")
        return c in hf or (c.startswith("__cq_q_") and not c.endswith("_unc"))
    return lambda v: rail(v, set())


_MEASURE = re.compile(r"^(\s+)%[-\w.$\"]+ = call \S+ @cqrt_measure_\w+\(i32 (%[-\w.$\"]+)\)")
# rule 14's carried advance select_<W>(a_j, next, prev) whose prev is a rail: the bare all-handle form, or `_lh` where next is
# a literal (CR rule 14: "every carried value advances by a select on a_j", a literal next included; since cq-amtcn the next
# value of a measured carried v is computed from the trip's outcome, classical: cq-0xhre). BACKEND_ABI §2 select shapes:
# `hl`/`lh`/`ll` give the arms and the condition is always a handle; `_hl` and `_ll` have no rail prev and carry no register.
# The width word is the rail type (iN, f32, f64, f80). Also a copy_<W> (not the _controlled form): run.measure_site_classes
_SELECT_TMPL = r"@cq_template_select_(?:i\d+|f\d+)(?:_lh)?\("
_SELECT3 = re.compile(r"^\s+(%[-\w.$\"]+) = call \S+ " + _SELECT_TMPL + r"i32 %[-\w.$\"]+, "
                      r"(?:i32 %[-\w.$\"]+|[^%,()\s]+ [^,()\s]+), i32 (%[-\w.$\"]+)\)")
_COPY = re.compile(r"@cqrt_copy_[a-z0-9]+\(i32 (%[-\w.$\"]+), i32 (%[-\w.$\"]+)\)")
_SELECT_COND = re.compile(r"^\s+%[-\w.$\"]+ = call \S+ " + _SELECT_TMPL + r"i32 (%[-\w.$\"]+), ")


# §1.4's clone grammar without its _ctl word, read right to left: the C function a clone is the lowering of.
_CLONE_FN = re.compile(r"^__cq_q_(.+)_(?:v|[01]+)(?:_b\d+(?:_\d+)*)?(?:_t)?(?:_pure)?(?:_unc)?$")
_DEFINE_NAME = re.compile(r'^define [^@]*@"?([-\w.$]+)"?\(')


_MEAS_WINDOW = 6


def _canon(line: str, operand: str = "", result: str = "") -> str:
    """An instruction with its SSA names and metadata erased: callee, constants and types stay; the measured rail
    reads M and the measurement's result R, so the data flow through the measurement is part of the shape."""
    def name(m: "re.Match[str]") -> str:
        return "%M" if m.group(0) == operand else "%R" if m.group(0) == result else "%"
    # cq-jws5r: a block label is an SSA name too (a trip copy with a classical branch has blocks of its own, rule 8)
    line = re.sub(r"^[-\w.$\"]+:(?=\s|$)", "%:", line.strip())
    return re.sub(r"%[-\w.$\"]+", name, re.sub(r", !cq\.measure !\d+", "", line))


def measure_site_classes(text: str, chains: Optional[Dict[int, List[Tuple[int, str, bool]]]] = None,
                         trees: Optional[Dict[int, str]] = None,
                         choices: Optional[Dict[int, Tuple[str, Any]]] = None) -> Dict[int, int]:
    """Line index of each cqrt_measure call of the lowered module -> its call-site class (cq-47f8h, owner 2026-11-07:
    measurements are identified by call site). The pass unrolls a K-loop's body, one measure call per trip (cq-9kcq);
    the copies are one site of the C program. Two calls of one function and one width are copies of one site when
    the six instructions before them, or the six after them, read alike with SSA names erased (the measured rail and
    the result kept apart: the data flow through the measurement is part of the shape) (the first copy has another prologue and the last another epilogue, the middle ones
    both), and they measure one register (cq-v8cn7: `root`, through a kept copy and rule 14's carried select; the
    shape alone does not tell which register is measured); the classes are the closure of that relation.
    `chains` (rulings Q8), when given, receives for each measurement line the three-rail selects `root` reads it through,
    in order: (line, condition operand, carried advance: its result is another three-rail select's previous operand).
    The classes stay static; per sample the trace tells where the select may be followed (ctl_measures_module).
    `trees` (cq-2pdir), when given, receives for each measurement whose register is read through a classical choice (an LLVM
    select or a join phi of handles; a loop header's carried phi, one incoming of which `root` reads back to the phi, is
    the carried register itself, rulings Q8) the tree of those choices down to the registers, in prefix form
    (`S <line> <n> <subtree>...`, `L <register id>`), and `choices` each such choice's line: ("s", condition) or
    ("p", incoming block labels). The rolled trip's one site so names, per execution, the register it measures."""
    lines = text.splitlines()
    parent: Dict[int, int] = {}

    def find(x: int) -> int:
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    fn_start = None
    leaf_ids: Dict[Tuple[int, str], int] = {}
    bodies: List[Tuple[int, int]] = []
    for i, ln in enumerate(lines):
        if ln.startswith("define"):
            fn_start = i
        elif ln.startswith("}") and fn_start is not None:
            bodies.append((fn_start, i))
            fn_start = None
    for a, b in bodies:
        definer: Dict[str, str] = {}
        carried: Dict[str, str] = {}         # a rule-14 carried advance select(a_j, next, prev): its prev
        carried_at: Dict[str, Tuple[int, str]] = {}   # ... its line and condition
        copied: Dict[str, List[Tuple[int, str]]] = {}   # a rail -> (line, source) of each copy_<W> into it
        for i in range(a, b):
            m = re.match(r"^\s+(%[-\w.$\"]+) = (?:call \S+ )?@?(\w+)?", lines[i])
            if m:
                c = re.match(r"^\s+(%[-\w.$\"]+) = call \S+ @([-\w.$]+)", lines[i])
                definer[m.group(1)] = c.group(2) if c else "?"
            s = _SELECT3.match(lines[i])
            if s:
                carried[s.group(1)] = s.group(2)
                cnd = _SELECT_COND.match(lines[i])
                if cnd:
                    carried_at[s.group(1)] = (i, cnd.group(1))
            cp = _COPY.search(lines[i])
            if cp:
                copied.setdefault(cp.group(2), []).append((i, cp.group(1)))

        chained_prev = set(carried.values())

        def root(v: str, at: int, chain: Optional[List[Tuple[int, str, bool]]] = None) -> str:
            """cq-v8cn7: the register a measurement at line `at` reads, through rule 2's / §1.4's kept copy
            (copy_<W>(h, t); measure(t)) and rule 14's carried advance select(a_j, next, prev) (CR rule 14: "every
            carried value advances by a select on a_j"): one register over the trips, a different one for any other."""
            seen = set()
            while v not in seen:
                seen.add(v)
                srcs = [src for ln, src in copied.get(v, ()) if ln < at]
                if srcs:
                    v = srcs[-1]
                elif v in carried:
                    if chain is not None and v in carried_at:
                        chain.append((*carried_at[v], v in chained_prev))
                    v = carried[v]
                else:
                    break
            return v
        keys: Dict[Tuple, int] = {}
        def_line: Dict[str, int] = {}
        for i in range(a, b):
            dm = re.match(r"^\s+(%[-\w.$\"]+) = (select i1 |phi i32 )", lines[i])
            if dm:
                def_line[dm.group(1)] = i

        def tree(v: str, at: int, seen: FrozenSet[str]) -> Tuple[str, bool]:
            """cq-2pdir: (prefix tree, whether any classical choice is in it) of the register(s) v reads at line `at`."""
            r = root(v, at)
            ln = def_line.get(r)
            if ln is not None and r not in seen:
                rhs = lines[ln]
                sm = re.match(r"^\s+%[-\w.$\"]+ = select i1 (\S+), i32 (\S+), i32 (\S+)", rhs)
                if sm:
                    ops, kind = [sm.group(2), sm.group(3)], ("s", sm.group(1))
                else:
                    inc = re.findall(r"\[\s*([^,\]]+?)\s*,\s*(%[-\w.$\"]+)\s*\]", rhs)
                    ops, kind = [x for x, _ in inc], ("p", [lb for _, lb in inc])
                    if any(root(x, ln) == r for x in ops):      # a carried header phi: the register itself
                        ops = []
                if ops:
                    subs = [tree(x, ln, seen | {r}) for x in ops]
                    if len({t for t, _ in subs}) > 1:
                        if choices is not None:
                            choices[ln] = kind
                        return f"S {ln} {len(subs)} " + " ".join(t for t, _ in subs), True
                    return subs[0]
            return f"L {leaf_ids.setdefault((a, r), len(leaf_ids))}", False
        for i in range(a, b):
            m = _MEASURE.match(lines[i])
            if not m:
                continue
            if trees is not None:
                t, chose = tree(m.group(2), i, frozenset())
                if chose:
                    trees[i] = t
            parent[i] = i
            w = re.search(r"@cqrt_measure_(\w+)\(", lines[i]).group(1)
            res = re.match(r"^\s+(%[-\w.$\"]+) =", lines[i]).group(1)
            ch: List[Tuple[int, str, bool]] = []
            d = root(m.group(2), i, ch)
            if chains is not None and ch:
                chains[i] = ch
            pre =tuple(_canon(x, m.group(2), res) for x in lines[max(a + 1, i - _MEAS_WINDOW):i])
            suf = tuple(_canon(x, m.group(2), res) for x in lines[i + 1:min(b, i + 1 + _MEAS_WINDOW)])
            for k in (("pre", w, d, pre) if len(pre) == _MEAS_WINDOW else None,
                      ("suf", w, d, suf) if len(suf) == _MEAS_WINDOW else None):
                if k is None:
                    continue
                if k in keys:
                    parent[find(i)] = find(keys[k])
                else:
                    keys[k] = i
    return {i: find(i) for i in parent}


def _walk_meas_tree(t: str, taken: Dict[Any, Any]) -> Optional[str]:
    """cq-2pdir: the register (`L <n>`) a measurement read, its tree (measure_site_classes `trees`, written in prefix form:
    `S <choice id> <operands> <subtree>...`) walked by the operand each classical choice took last; None where one was not
    seen (unknown: no register is claimed)."""
    tok = t.split()
    pos = 0

    def walk() -> Tuple[Optional[str], bool]:
        nonlocal pos
        kind = tok[pos]
        if kind == "L":
            pos += 2
            return tok[pos - 1], True
        cid, n = int(tok[pos + 1]), int(tok[pos + 2])
        pos += 3
        k = taken.get(cid)
        out: Optional[str] = None
        for x in range(n):
            r, _ = walk()
            if x == k:
                out = r
        return out, True
    try:
        return walk()[0]
    except (IndexError, ValueError):
        return None


def ctl_measures_module(text: str) -> str:
    """Rule 19: inside a _ctl clone a cq_measure is a controlled copy, measured whatever the predicate; where
    it reads 0 the predicate may be 0 and the C program never reached it (compare._meas_options). Each such
    measurement names its rail to the trace. Any other measurement names the C function it lies in: rule 2 runs an
    arm's measurement unconditionally in that function, so the input must enter it (compare._meas_extra)."""
    out = []
    fns: Dict[str, int] = {}
    in_ctl = used = False
    fn = None
    chains: Dict[int, List[Tuple[int, str, bool]]] = {}
    trees: Dict[int, str] = {}
    choices: Dict[int, Tuple[str, Any]] = {}
    sites = measure_site_classes(text, chains, trees, choices)
    sel_cond = {ln: c for ch in chains.values() for ln, c, _ in ch}
    lines = text.splitlines()
    gl: List[str] = []
    pend: List[int] = []
    for ln_i, line in enumerate(lines):
        if line.startswith("define"):
            in_ctl = bool(re.search(r"@\S*_ctl(?:_unc)?\(", line))
            d = _DEFINE_NAME.match(line)
            fn = d.group(1) if d else None
            c = _CLONE_FN.match(fn) if fn else None
            fn = c.group(1) if c else fn
        m = _MEASURE.match(line)
        if m and in_ctl:
            out.append(f"{m.group(1)}call void @cqd_out_ctl_measure(i32 {m.group(2)})")
            used = True
        elif m and fn:
            for ln, _, chained in chains.get(ln_i, ()):
                out.append(f"{m.group(1)}call void @cqd_out_meas_chain(i32 {ln}, i32 {int(chained)})")
            out.append(f"{m.group(1)}call void @cqd_out_meas_fn(ptr @.cqd.fn.{fns.setdefault(fn, len(fns))}, i32 {sites.get(ln_i, -1)})")
        if m and not in_ctl and ln_i in trees:
            out.append(f"{m.group(1)}call void @cqd_out_meas_tree(ptr @.cqd.tree.{ln_i})")
            gl.append(f'@.cqd.tree.{ln_i} = private unnamed_addr constant [{len(trees[ln_i]) + 1} x i8] c"{trees[ln_i]}\\00"')
        out.append(line)
        if ln_i in sel_cond:   # rulings Q8: the select's condition, right after it (the select line's number is its id)
            out.append(f"  call void @cqd_out_sel(i32 {ln_i}, i32 {sel_cond[ln_i]})")
        ch = choices.get(ln_i)
        if ch and ch[0] == "s":    # cq-2pdir: which operand a classical select took (0: the true one)
            out.append(f"  %cq.lk.{ln_i} = select i1 {ch[1]}, i32 0, i32 1")
            out.append(f"  call void @cqd_out_lsel(i32 {ln_i}, i32 %cq.lk.{ln_i})")
        elif ch:                   # ... and a join: an index phi beside it, logged after the block's last phi
            out.append(f"  %cq.lk.{ln_i} = phi i32 " + ", ".join(f"[ {x}, {b} ]" for x, b in enumerate(ch[1])))
            pend.append(ln_i)
        if pend and not re.match(r"^\s+%[-\w.$\"]+ = phi ", lines[ln_i + 1] if ln_i + 1 < len(lines) else ""):
            for p in pend:
                out.append(f"  call void @cqd_out_lsel(i32 {p}, i32 %cq.lk.{p})")
            pend = []
    if used:
        out.append("declare void @cqd_out_ctl_measure(i32)")
    if sel_cond:
        out.append("declare void @cqd_out_sel(i32, i32)")
        out.append("declare void @cqd_out_meas_chain(i32, i32)")
    if fns:
        out.append("declare void @cqd_out_meas_fn(ptr, i32)")
        for name, i in fns.items():
            out.append(f'@.cqd.fn.{i} = private unnamed_addr constant [{len(name) + 1} x i8] c"{name}\\00"')
    if choices:
        out.append("declare void @cqd_out_lsel(i32, i32)")
    if gl:
        out.append("declare void @cqd_out_meas_tree(ptr)")
        out += gl
    return "\n".join(out) + "\n"


def host_end_module(text: str) -> str:
    """cq-yd85w (CR rule 16 noreturn: a classical call with classical arguments is the ordinary host call, the program
    ends there): the lowered program's call of the host's abort and its llvm.trap end the shot by core.c's
    cqe__host_signal_end with the signal the host raises (SIGABRT; SIGILL, x86's ud2), so the evaluator reports the
    shot and its host_end as for exit and _exit; the program's own atexit registers a handler _exit, _Exit and abort
    skip (cqe__user_atexit). A body the module holds for one of them is code like any other."""
    import signal as _sg
    defined = set(re.findall(r'^define [^@]*@([-\w$.]+)\(', text, re.M))
    out = re.sub(r'\bcall void @llvm\.trap\(\)', f"call void @cqe__host_signal_end(i32 {int(_sg.SIGILL)})", text)
    if "abort" not in defined:
        out = re.sub(r'\bcall void @abort\(\)', f"call void @cqe__host_signal_end(i32 {int(_sg.SIGABRT)})", out)
    if "atexit" not in defined:
        out = re.sub(r'\bcall i32 @atexit\(', "call i32 @cqe__user_atexit(", out)
    if out == text:
        return text
    return out + "\ndeclare void @cqe__host_signal_end(i32) noreturn\ndeclare i32 @cqe__user_atexit(ptr)\n"


def host_effects_module(text: str, defined: Sequence[str] = ()) -> str:
    """text with no direct call of a host function left (CR §6, rulings Q8): a declared host-effect
    function (compare.HOST_EFFECTS) goes to its logging stand-in in checker/rt/host_fx.c (cq-e4jk), every
    other drivers.effect_callees to a generated wrapper over checker/oracle/fx_call.h. All are logged as
    {"ev":"effect"} events. A module that defines such a function calls its own; so does a driver's."""
    from cqcheck import drivers
    for name in HOST_EFFECTS:
        if re.search(rf"(?m)^declare\b[^\n]*@{name}\(", text):
            text = re.sub(rf"@{name}(?=\()", f"@__cqe_fx_{name}", text)
    text = drivers.route_scans(text)   # cq-tgl3i: a direct scanf-family call, the host's on the one input stream (fx_call.h, ruling Q5)
    callees = drivers.effect_callees(text, frozenset(defined) | frozenset(HOST_EFFECTS))
    text = drivers.rename_effects(text, callees)
    # rulings Q2 (2026-11-11): every __cq_alloc block is recorded (rt_bus.c cqe__q2_alloc), so a host call's pointer
    # argument is resolved to its object; __cq_alloc is the bundle's (drivers._REAL), never a stand-in
    text = re.sub(r"@__cq_alloc(?=\()", "@cqe__q2_alloc", text)
    # rulings Q2 for CR rule 23's calls with an object operand (a host call by name, rule 16): the host's function behind
    # rt_bus.c's record of a QUANTUM object, as the C side's cqo_rt.c __cqo_fegetenv ... (a module that defines one calls its own)
    for name in _FENV_OBJ_CALLS:
        if name not in defined and re.search(rf"(?m)^declare\b[^\n]*@{name}\(", text):
            text = re.sub(rf"@{name}(?=\()", f"@cqe__q2_{name}", text)
    return text + drivers.effect_wrappers_ir(callees)


_FENV_OBJ_CALLS = ("fegetenv", "feholdexcept", "fesetenv", "feupdateenv", "fegetexceptflag", "fesetexceptflag")


def _fx_arg(f: dict) -> dict:
    """One field of an effect entry as compare reads it: {"s": str} (oracle's raise) or {"w", "v"} with
    "cap" (the bytes captured, rt_tape.c) and "p" (fx_call.h: a pointer argument). A rail's handle goes."""
    if "s" in f:
        return {"s": _bytes_text(f["s"])}
    out = {k: f[k] for k in ("w", "v", "p") if k in f}
    if "cap" in f:
        out["cap"] = _bytes_text(f["cap"])
    return out


def _fx_event(e: dict) -> dict:
    """One {"ev":"effect"} line (rt_tape.c's entry object, host_fx.c's and fx_call.h's direct call) as
    compare reads it: what the C program does at this call."""
    out = {"name": e.get("name"), "args": [_fx_arg(a) for a in e.get("fields", e.get("args", []))]}
    if "in" in e:   # ruling Q5: an INPUT call's stream offset and the bytes it took (fx_standin.h)
        out["in"] = list(e["in"])
    return out


def _effects_in_order(lines: List[dict]) -> List[dict]:
    """The effect lines in the C program's order. rt_tape.c writes "call" lines at the call and "end"
    lines at the end of the shot, each with its sequence number; a direct call (seq -1) stays behind the
    entries already performed at their call. Format entries are compared as stdout, so they go."""
    keyed = []
    last = -1.0
    for i, e in enumerate(lines):
        seq = e.get("seq", -1)
        if seq is None or seq < 0:
            key = last + 0.5
        else:
            key = float(seq)
            if e.get("when") == "call":
                last = key
        if e.get("kind") != "fmt":
            keyed.append((key, i, e))
    return [_fx_event(e) for _, _, e in sorted(keyed, key=lambda t: t[:2])]


def _tape_entry(x: dict) -> dict:
    """One event of the shot's sequence (rulings Q8) as compared against the reference: name or format,
    predicate, fields, order, whether it was performed, its text and result; never handles or the
    evaluator's class."""
    if x.get("kind") == "abort":
        return {"kind": "abort", "seq": x.get("seq"), "fv": x.get("fv")}
    out = {k: x[k] for k in ("seq", "kind", "pred", "performed", "name", "fmt", "in") if k in x}
    out["fields"] = [_fx_arg(f) for f in x.get("fields", [])]
    if "text" in x:
        out["text"] = _bytes_text(x["text"])
    if "r" in x:
        out["r"] = {k: x["r"][k] for k in ("w", "v") if k in x["r"]}
    return out


def _tape_shot(e: dict) -> Tuple[str, List[dict]]:
    """Of rt_tape.c's end-of-shot event: the text it printed and the event sequence. An effect entry's result is the
    stand-in's on both sides (CR 1356-1358; fx_standin.h; the C program's call goes to the same stand-in,
    drivers.effect_callees); a C library output call's and those of ruling cq-dbtpi are musl's values on both sides; a
    deferred result rail the program reads excludes the sample (_deferred_read, compare.py)."""
    return _bytes_text(e.get("stdout", "")), [_tape_entry(x) for x in e.get("events", [])]


def _deferred_read(e: dict) -> List[str]:
    """Owner ruling 2026-11-12 cq-dbtpi (BACKEND_ABI 1.11, "as in Q2"): the names of the effect entries of rt_tape.c's
    end-of-shot event that the backend deferred with a result rail (the `_<W>` form: the compiler emits it where the
    program reads the result, its r |0>) and whose predicate read 1 (the C program made the call). It only narrows the C
    side's decision (oracle.py outputs["hsread"]: the C program read that callee's result), compare.py."""
    return sorted({x["name"] for x in e.get("events", []) if x.get("kind") == "effect" and x.get("class") == "deferred"
                   and "r" in x and x.get("pred") == 1 and isinstance(x.get("name"), str)})


def run_sample(lowered: Path, spec: DriverSpec, sample: dict, side: str, *, timeout: float = DEFAULT_TIMEOUT,
               rt_sources: Optional[Sequence[Path]] = None, extra_sources: Sequence[Path] = (),
               c_module: Optional[Path] = None) -> RunResult:
    """Run one sample of spec against the lowered module in the evaluator (cq-zew)."""
    return run_samples(lowered, spec, [sample], side, 1, timeout=timeout, rt_sources=rt_sources,
                       extra_sources=extra_sources, c_module=c_module)[0]


def _prepare(spec: DriverSpec, sample: dict, side: str):
    """(canonical sample, its sample-file record), or the RunResult of a sample that is malformed."""
    from cqcheck import drivers
    try:
        canon = canonical_sample(spec, sample)
        if "subst" in sample:
            _check_subst(sample["subst"])
        return canon, drivers.sample_file(spec, [canon])
    except (SampleError, KeyError, TypeError, ValueError, RuntimeError) as e:
        return _result(side, sample, [], "", None, [{"what": "sample", "h": None, "msg": str(e)}])


def _check_subst(subst: Any) -> None:
    from cqcheck import oracle
    if not isinstance(subst, dict):
        raise SampleError(f"subst {subst!r}: a {{\"<fn>:<site>\": hex | [hex, ...]}} object")
    for k, v in subst.items():
        if not isinstance(k, str) or not re.fullmatch(r"[^\s:]+(?::[^\s:]+)*:\d+", k):
            raise SampleError(f"subst key {k!r}: <fn>:<site>")
        try:
            oracle.subst_values(v)
        except RuntimeError as e:      # oracle.OracleError
            raise SampleError(str(e))


def theta_schedule(events: Sequence[dict], o1: Path) -> str:
    """The $CQE_THETA file of one sample (dispatch.c): its C program's cq_theta reaches in the circuit's
    emission order, `<angle> <W> <value>` per line; a reach the circuit runs inverted (a cq_invert region
    reversed at its end, CR rule 17) has its angle negated, one a measurement inside the region flushed
    forward first does not (BACKEND_ABI 1.13; compare.region_emission)."""
    from cqcheck import compare, drivers
    widths = drivers.theta_site_widths(o1)
    sites, entries, nmeas = [], [], 0
    for e in events:
        if e.get("ev") != "site":
            continue
        kind = e.get("kind")
        if kind == "measure":
            nmeas += 1
        elif kind in ("theta", "phi", "invert_begin", "invert_end"):
            sites.append(e)
            entries.append((kind, nmeas))
    order, _, _ = compare.region_emission(entries, nmeas, open_end=True)
    lines = []
    for i, neg in order:
        e = sites[i]
        if e.get("kind") != "theta":
            continue
        w = widths.get(f"{e['fn']}:{e['site']}")
        if w is None:
            raise SampleError(f"cq: unimplemented: chk-core: the C oracle's theta site {e['fn']}:{e['site']} "
                              f"is no cq_theta_* call of {o1}")
        a = int(e["angle"], 16) ^ ((1 << 63) if neg else 0)
        lines.append(f"0x{a:x} {w} {e['reg']}\n")
    return "".join(lines)


def _theta_schedules(lowered: Path, spec: DriverSpec, samples: Sequence[dict], preps: Sequence[Any],
                     c_module: Optional[Path]) -> Dict[int, str]:
    """index -> theta_schedule of every well-formed sample that carries "subst", from one batch of the
    C oracle over the .O1.ll (c_module, else c_module_of)."""
    want = [i for i, (s, p) in enumerate(zip(samples, preps)) if not isinstance(p, RunResult) and "subst" in s]
    if not want:
        return {}
    o1 = Path(c_module) if c_module else c_module_of(Path(lowered), spec)
    if o1 is None:
        raise BuildError(f"samples carry cq_theta substitutions but no .O1.ll gives the C program's theta "
                         f"reaches for {lowered}")
    from cqcheck import oracle
    batch = [{"call": preps[i][0]["call"], "args": preps[i][0]["args"], "subst": samples[i]["subst"]}
             for i in want]
    try:
        runs = oracle.run_samples(o1, spec, batch)
    except RuntimeError as e:          # oracle.OracleError: the C program cannot be built or run
        raise BuildError(f"the C oracle's theta schedule: {e}")
    return {i: theta_schedule(r.events, o1) for i, r in zip(want, runs)}


def _build_failure(side: str, sample: dict, e: BaseException) -> RunResult:
    return _result(side, sample, [], "", None, [{"what": "build", "h": None, "msg": str(e)}])


# ---- runner (cq-e2i9) --------------------------------------------------------------------------
#
# One runner process per part of a batch: `prog` reads the part's sample file once and runs every
# record in its worker, each from the post-setup state (core.c, shots). The trace frames every shot
# ({"ev":"shot","k"} ... {"ev":"shot_end","k","code","timeout","stdout","stderr"}); the frames are
# private to chk-core and never reach a RunResult. A runner that ends inside a sample (the driver's
# _exit(3) on a malformed record, a kill) loses no sample: that sample gets a RunResult saying so and
# a fresh runner takes the rest.

_BAD = "__bad_line"
_UNREAD = ('{"ev":"bus"', '{"ev":"cells"')


def _with_bad(events: List[dict], torn: bool = True) -> Tuple[List[dict], List[dict]]:
    """(events, the 'trace' violations of torn lines), as the trace parser gives them; torn False: the
    trace had none."""
    if not torn or not any(e.get("ev") == _BAD for e in events):
        return events, []
    good = [e for e in events if e.get("ev") != _BAD]
    bad = [{"what": "trace", "h": None, "msg": f"unparsable trace line: {e['line'][:200]}"}
           for e in events if e.get("ev") == _BAD]
    return good, bad


_LINE_CHUNK = 1 << 20
_SCAN_ONCE = json.JSONDecoder().scan_once     # json.loads's scanner (json.decoder.JSONDecoder.raw_decode)
_EXIT_HEAD = '{"ev":"exit","live":['


def _line_event(line: str) -> Any:
    """The event of one trace line: json.loads(line), or {"ev": _BAD, "line"} when it does not parse. cq-p9pty: a
    line that is one JSON value and its newline is read by json.loads's own scanner, without loads's Python frames per
    line (a large example's traces have 10^6 lines); any other goes through json.loads as before."""
    try:
        e, end = _SCAN_ONCE(line, 0)
    except (StopIteration, ValueError):
        end = -1
    if end >= 0 and (end == len(line) or (end == len(line) - 1 and line[end] == "\n")):
        return e
    try:
        return json.loads(line)
    except json.JSONDecodeError:
        return {"ev": _BAD, "line": line.strip()}


def _trace_events(f) -> Iterable[Tuple[str, Optional[dict]]]:
    """The lines of a trace as (line, None), and each exit event as ("", the event) read row by row (_exit_event)."""
    while True:
        line = f.readline(_LINE_CHUNK)
        if not line:
            return
        if line.startswith(_EXIT_HEAD) and not line.endswith("\n"):
            yield "", _exit_event(f, line)
            continue
        while not line.endswith("\n"):
            more = f.readline(_LINE_CHUNK)
            if not more:
                break
            line += more
        yield line, None


def _exit_event(f, head: str) -> dict:
    """The exit event whose line starts with `head` (no newline in it yet), read from f one row at a time (cq-pckdl:
    the line is never held whole; a replayed run's once reached 10 GB). A line that does not parse (torn by a kill)
    gives {"ev": _BAD, "line": its first characters}, as a line read whole does."""
    dec = json.JSONDecoder()
    buf, i, ended = head, len(_EXIT_HEAD), False
    live = kept_mod.Builder()

    def more() -> bool:
        nonlocal buf, i, ended
        if ended:
            return False
        chunk = f.readline(_LINE_CHUNK)
        if not chunk:
            ended = True
            return False
        ended = chunk.endswith("\n")
        buf, i = buf[i:] + chunk, 0
        return True

    def bad() -> dict:
        while more():
            buf_cut()
        return {"ev": _BAD, "line": head[:400].strip()}

    def buf_cut() -> None:       # a torn line is drained without holding it
        nonlocal buf, i
        buf, i = buf[-64:], 0

    while True:
        while True:
            while i < len(buf) and buf[i] in " \t\r,":
                i += 1
            if i < len(buf) or not more():
                break
        if i >= len(buf):
            return bad()
        if buf[i] == "]":
            rest = buf[i + 1:]
            buf, i = "", 0
            while more():
                rest += buf
                buf, i = "", 0
            try:
                tail = json.loads("{" + rest.strip().lstrip(","))
            except json.JSONDecodeError:
                return bad()
            if not isinstance(tail, dict):
                return bad()
            return {**tail, "ev": "exit", "kept": live.kept()}
        try:
            row, j = dec.raw_decode(buf, i)
        except json.JSONDecodeError:
            if more():
                continue
            return bad()
        if not isinstance(row, dict) or ("use" in row and row["use"] not in live.pats):
            return bad()
        live.add(row)
        i = j


def _stream_shots(trace: Path, side: str, items: Sequence[Tuple[dict, str, Optional[str]]], setup_out: str,
                  timeout: float) -> Tuple[List[dict], Dict[int, RunResult], Dict[int, List[dict]]]:
    """One pass over a runner's trace, line by line: (the events before its first shot, k -> the
    RunResult of every finished shot k of `items`, k -> the events of a shot with no end). What
    a whole-trace parse gave, with each finished shot turned into its result at once."""
    pre: List[dict] = []
    done: Dict[int, RunResult] = {}
    open_shots: Dict[int, List[dict]] = {}
    cur: Optional[List[dict]] = pre
    if not trace.exists():
        return pre, done, open_shots
    with open(trace, errors="replace") as f:
        for line, e in _trace_events(f):
            if e is None:
                if not line.strip() or line.startswith(_UNREAD):
                    continue
                e = _line_event(line)
            ev = e.get("ev") if isinstance(e, dict) else None
            if ev == "shot":
                cur = open_shots[e["k"]] = []
            elif ev == "shot_end":
                k = e["k"]
                evs = open_shots.pop(k, [])
                done.pop(k, None)
                if 0 <= k < len(items):
                    done[k] = _shot_result(side, items[k][0], pre, evs, e, setup_out, timeout)
                cur = None                     # nothing of a shot follows its end
            elif cur is not None:
                cur.append(e)
    return pre, done, open_shots


def _bytes_text(s: str) -> str:
    """A shot's captured stream: core.c writes each byte as one character; decoded as a pipe was."""
    try:
        return s.encode("latin-1").decode("utf-8", errors="replace")
    except UnicodeEncodeError:
        return s


def _shot_result(side: str, sample: dict, pre: List[dict], evs: List[dict], end: dict, setup_out: str,
                 timeout: float, torn: bool = True) -> RunResult:
    """The RunResult of one finished shot: what a process of its own gave."""
    if "freed" in end:
        # the compact trace (cq-8m6v): the sample's free events are its dirty ones only, tagged as the
        # sample's; the frame sums up all of them (count, digest of the handles in order)
        evs = [dict(e, shot=True) if isinstance(e, dict) and e.get("ev") == "free" else e for e in evs]
    events, bad = _with_bad(pre + evs if pre else evs, torn)
    code = end.get("code")
    stdout = setup_out + _bytes_text(end.get("stdout", ""))
    err = _bytes_text(end.get("stderr", ""))
    extra: List[dict] = []
    if end.get("timeout"):
        code, extra = None, [{"what": "timeout", "h": None,
                              "msg": f"no exit within {STEP_BUDGET} steps or {timeout}s of CPU time"}]
    elif code < 0:
        extra.append({"what": "signal", "h": None, "msg": f"killed by signal {-code}: {err[-500:]}"})
    elif code == 3 and "cqd: sample" in err:
        extra.append({"what": "sample", "h": None, "msg": err.strip()[-500:]})
    return _result(side, sample, events, stdout, code, extra + bad,
                   {"freed": end["freed"], "fdig": end["fdig"]} if "freed" in end else None)


_WORK: Dict[int, Path] = {}


def _work_dir() -> Path:
    """This thread's runner directory (trace, capture files), made once and removed at exit; it names
    this process as its owner (tmpdirs, cq-3fjt: a killed process's is swept)."""
    from cqcheck import tmpdirs
    k = threading.get_ident()
    d = _WORK.get(k)
    if d is None or not d.is_dir():
        d = _WORK[k] = tmpdirs.make_run_dir("cqe-run.")
        (d / "shot").mkdir()
        if len(_WORK) == 1:
            import atexit
            atexit.register(lambda: [shutil.rmtree(x, ignore_errors=True) for x in list(_WORK.values())])
    return d


def _run_part(prog: Path, items: Sequence[Tuple[dict, str, Optional[str]]], side: str,
              timeout: float) -> List[RunResult]:
    """(sample, record, theta) items in runner processes, in order: one runner over all of them, and a
    fresh one after a sample a runner did not finish."""
    out: List[RunResult] = []
    # cq-8m6v: the batch goes in on stdin (the theta schedules, a "%%" line, then the records:
    # core.c, drivers.driver_source), and the trace and capture files live in this thread's
    # work directory, made once per process
    w = _work_dir()
    # the program's own working directory is fresh per batch, as before: what a sample writes there
    # (a host effect's file) never reaches another batch
    wd = tempfile.mkdtemp(prefix="cwd.", dir=w)
    theta_all = None
    if any(th is not None for _, _, th in items):
        theta_all = "".join(f"@{k}\n{th}" for k, (_, _, th) in enumerate(items) if th is not None) + "%%\n"
    pos = 0
    while pos < len(items):
        stdin = (theta_all or "") + "".join(rec for _, rec, _ in items[pos:])
        trace = w / "trace.jsonl"
        # the trace file is reused per thread: a runner that dies before core.c opens it must read as
        # no shots, never as the previous batch's (speed review h2)
        trace.unlink(missing_ok=True)
        env = dict(os.environ, CQE_TRACE=str(trace), CQD_SAMPLES="-",
                   CQE_COMPACT="0" if os.environ.get("CQE_COMPACT") == "0" else "1",   # 0: diagnostics
                   CQE_SHOT_DIR=str(w / "shot"), CQE_SHOT_BASE=str(pos),
                   CQE_SHOT_TIMEOUT=repr(float(timeout)), CQE_SHOT_STEPS=str(int(STEP_BUDGET)))
        env.pop("CQE_THETA", None)
        env.pop("CQE_THETA_ALL", None)
        if theta_all is not None:
            env["CQE_THETA_ALL"] = "-"
        # a backstop only; capped below poll()'s int32 milliseconds (cq-vo6v: 47301 uncached
        # samples in one runner overflowed it, an OverflowError for 56 and 156)
        budget = min((2 * timeout + 2) * (len(items) - pos) + 60, 2_000_000.0)
        try:
            wrap = os.environ.get("CQCHECK_RUN_WRAPPER")   # cq-kcn5i: a diagnostic launcher (the replay proof's no-ASLR one)
            p = subprocess.run([*([wrap] if wrap else []), str(prog)], cwd=wd, env=env, capture_output=True, timeout=budget,
                               input=stdin.encode())
            code, killed = p.returncode, False
            setup_out, err = p.stdout.decode(errors="replace"), p.stderr.decode(errors="replace")
        except subprocess.TimeoutExpired as e:
            code, killed = None, True
            setup_out, err = (e.stdout or b"").decode(errors="replace"), (e.stderr or b"").decode(errors="replace")
        # the trace is read one line and one shot at a time (cq-8m6v): a finished shot becomes its
        # RunResult and its events are dropped, so memory holds one sample's events at a time
        keep = os.environ.get("CQCHECK_KEEP_TRACES")   # cq-kcn5i: a diagnostic copy, named by what the batch ran
        if keep and trace.exists():
            tag = hashlib.sha256(f"{prog.parent.name}\0{side}\0{stdin}".encode()).hexdigest()[:16]
            Path(keep).mkdir(parents=True, exist_ok=True)
            shutil.copyfile(trace, Path(keep) / f"{side}.{tag}.{pos}.jsonl")
        pre, done, open_shots = _stream_shots(trace, side, items, setup_out, timeout)
        while pos < len(items) and pos in done:
            out.append(done.pop(pos))
            pos += 1
        if pos == len(items):
            break
        # cq-3fjt: the trace passed $CQE_TRACE_ROTATE after a finished sample (core.c): the rest run in
        # a fresh runner with a fresh trace, nothing failed
        if (not killed and code == 99 and "cq: chk-core: trace rotation" in err and pos not in open_shots
                and not done):
            continue
        # the runner ended inside sample pos: that sample fails, the rest run in a new runner
        events, bad = _with_bad(pre + open_shots.get(pos, []))
        if killed:
            extra = [{"what": "timeout", "h": None, "msg": f"no exit within {timeout}s"}]
        elif code == 3 and "cqd: sample" in err:
            extra = [{"what": "sample", "h": None, "msg": err.strip()[-500:]}]
        else:
            extra = [{"what": "runner", "h": None,
                      "msg": f"the runner ended (status {code}) inside this sample: {err.strip()[-500:]}"}]
        out.append(_result(side, items[pos][0], events, setup_out, None if killed else code, extra + bad))
        pos += 1
    shutil.rmtree(wd, ignore_errors=True)
    return out


def default_jobs() -> int:
    """Runner processes per batch: $CQCHECK_JOBS, else the CPU count."""
    try:
        return max(1, int(os.environ.get("CQCHECK_JOBS", "")))
    except ValueError:
        return os.cpu_count() or 4


def run_samples(lowered: Path, spec: DriverSpec, samples: Iterable[dict], side: str, jobs: int = 0, *,
                timeout: float = DEFAULT_TIMEOUT, rt_sources: Optional[Sequence[Path]] = None,
                extra_sources: Sequence[Path] = (), c_module: Optional[Path] = None) -> List[RunResult]:
    """run_sample over many samples, in order. Each result equals run_sample's for that sample; the
    program is built once for the batch and its samples run in up to `jobs` runner processes (0:
    default_jobs), each running its samples in one worker process (core.c, shots); a build that fails gives every well-formed
    sample the same 'build' violation without running."""
    samples = list(samples)
    preps = [_prepare(spec, s, side) for s in samples]
    good = [p for p in preps if not isinstance(p, RunResult)]
    prog: Optional[Path] = None
    failure: Optional[BaseException] = None
    theta: Dict[int, str] = {}
    theta_failure: Optional[BaseException] = None
    if good:
        try:
            prog = build(Path(lowered), spec, [c for c, _ in good], rt_sources, extra_sources, c_module)
        except (BuildError, OSError, RuntimeError) as e:
            failure = e
        if failure is None:
            try:
                theta = _theta_schedules(Path(lowered), spec, samples, preps, c_module)
            except (BuildError, SampleError, OSError, RuntimeError) as e:
                theta_failure = e
    out: List[Optional[RunResult]] = []
    for i, p in enumerate(preps):
        if isinstance(p, RunResult):
            out.append(p)
        elif failure is not None:
            out.append(_build_failure(side, samples[i], failure))
        elif theta_failure is not None and "subst" in samples[i]:   # no theta schedule: cannot run
            out.append(_build_failure(side, samples[i], theta_failure))
        else:
            out.append(None)
    todo = [i for i, r in enumerate(out) if r is None]
    if not todo:
        return out  # type: ignore[return-value]
    # cq-8m6v: the results of a batch are a function of the executable (its directory name is its
    # content key), the records, the theta schedules and the limits (cq-o4ul: the step budget, never
    # the machine's load); a batch in which a run hit the CPU-time backstop or lost its runner is
    # not kept
    key = [_RUNS_VERSION, prog.parent.name, side, float(timeout), STEP_BUDGET, os.environ.get("CQE_COMPACT") == "0",
           [[preps[i][1], theta.get(i)] for i in todo]]
    caps = [os.environ.get(v) for v in _CAP_VARS]   # cq-3fjt: a cap the caller set changes results (cq-kcn5i: replay's too)
    if any(caps):
        key.append(caps)
    got = None if os.environ.get("CQCHECK_KEEP_TRACES") else load_runs("eval", key, _interned)   # cq-kcn5i: a kept trace is run
    if got is not None:
        for i, d in zip(todo, got):
            out[i] = RunResult(side=side, sample=samples[i], **d)
        todo = []
    else:
        _run_todo(prog, samples, preps, theta, todo, out, side, jobs, timeout)
        done = [out[i] for i in todo]
        if not any(v.get("what") in ("timeout", "runner") for r in done for v in (r.violations or [])):
            save_runs("eval", key, ({f: getattr(r, f) for f in _RESULT_FIELDS} for r in done))
    hfns = json.loads((prog.parent / "handle_rets.json").read_text())   # cq-n6a0
    out = [resolve_handle_rets(r, hfns) if r.violations is not None else _drop_hn(r) for r in out]
    return out  # type: ignore[return-value]


def _interned(d: dict) -> dict:
    """A cached result with its kept list's rows and row lists shared (kept.intern_kept)."""
    if isinstance(d.get("kept"), list):
        d["kept"] = kept_mod.intern_kept(d["kept"])
    return d


_RUNS_VERSION = "eval-runs-10"   # cq-dbtpi: deferred_r; cq-pckdl: kept rows of any role, merged in core.c; cq-92sw6: tape packed; replayed calls as uses with skip; rails by name (owner 2026-11-09)
_CAP_VARS = ("CQE_SHOT_TRACE_MAX", "CQE_SHOT_OUTPUT_MAX", "CQE_FILE_MAX", "CQE_SHOT_VIOL_MAX",   # core.c's caps
             "CQE_REPLAY", "CQE_REPLAY_CHECK", "CQE_REPLAY_TAMPER", "CQE_REPLAY_MAX_MB")   # rt_replay.c (cq-kcn5i)
_RESULT_FIELDS = ("outputs", "measured", "rotations", "kept", "clean", "violations")


def _runs_path(kind: str, key: Any) -> Path:
    h = hashlib.sha256(json.dumps(key, sort_keys=True, separators=(",", ":")).encode()).hexdigest()[:32]
    return _cache_root() / "runs" / kind / h[:2] / f"{h}.jsonl.z"


_CHUNK = 1 << 20


def load_runs(kind: str, key: Any, post: Optional[Callable[[dict], Any]] = None) -> Optional[List[Any]]:
    """The cached results of one batch (save_runs), or None; each through `post` as it is read (cq-v0u99: one result
    at a time is held as JSON reads it, never the batch)."""
    import zlib
    p = _runs_path(kind, key)
    try:
        f = open(p, "rb")
    except OSError:
        return None
    cachegc.used(p)
    out: List[Any] = []
    z = zlib.decompressobj()
    tail = b""
    with f:
        while True:
            chunk = f.read(_CHUNK)
            data = z.decompress(chunk) if chunk else z.flush()
            lines = (tail + data).split(b"\n")
            tail = lines.pop()
            for line in lines:
                d = json.loads(line)
                out.append(post(d) if post else d)
            if not chunk:
                break
    if tail.strip():
        d = json.loads(tail)
        out.append(post(d) if post else d)
    return out


def save_runs(kind: str, key: Any, results: Iterable[dict]) -> None:
    """One JSON line per result, compressed as it is written (cq-v0u99: never the batch as one string)."""
    import zlib
    p = _runs_path(kind, key)
    p.parent.mkdir(parents=True, exist_ok=True)
    tmp = p.with_name(f"{p.name}.{os.getpid()}.{threading.get_ident()}.tmp")
    z = zlib.compressobj(1)
    with open(tmp, "wb") as f:
        for r in results:
            f.write(z.compress(json.dumps(r, separators=(",", ":")).encode() + b"\n"))
        f.write(z.flush())
    os.replace(tmp, p)


# A program that reaches the file system may let a sample see what an earlier sample of its batch
# left in the working directory: its batch runs in one runner, as one sequence (cq-8m6v; the same
# calls as oracle._FS, declared by the lowered module).
_FS_DECL = re.compile(r"(?m)^declare\b[^@\n]*@(fopen|freopen|fdopen|tmpfile|open|creat|dup2|close|chdir|umask|"
                      r"tmpnam|tempnam|mkstemp|remove|unlink|rename)\(")


def _run_todo(prog: Path, samples, preps, theta, todo, out, side: str, jobs: int, timeout: float) -> None:
    from concurrent.futures import ThreadPoolExecutor
    whole = bool(_FS_DECL.search((prog.parent / "lowered.ll").read_text()))
    n = 1 if whole else max(1, min(jobs or default_jobs(), len(todo) // MIN_PART))
    parts = [todo[k::n] for k in range(n)]     # strided: neighbouring samples are often alike in cost

    def part(ix: List[int]) -> None:
        for i, r in zip(ix, _run_part(prog, [(samples[i], preps[i][1], theta.get(i)) for i in ix], side,
                                      timeout)):
            out[i] = r

    if n == 1:
        part(parts[0])
    else:
        with ThreadPoolExecutor(max_workers=n) as ex:
            list(ex.map(part, parts))


MIN_PART = 32   # a runner gets at least this many samples (fewer runners for a small batch)
