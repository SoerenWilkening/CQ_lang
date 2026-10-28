"""Checker core, Python side (cq-w0-chk-core): build a lowered module with the evaluator runtime and a
driver, run one sample, return a RunResult.

    run_sample(lowered: Path, spec: DriverSpec, sample: dict, side: str) -> RunResult   (cq-zew)

Build. driver.c (drivers.driver_source, the one renderer of samples, cq-arch Z1/Z2) is compiled to IR with clang-19 for the lowered
module's triple, llvm-link joins it to the lowered module, checker/rt/stubgen.py defines every
cqrt_*/cq_template_* the linked module declares and every rule 27 declared clone nothing links (the
checker's stand-in, typed by the example's .O1.ll: c_module_of, cq-rft), and clang links that with every checker/rt/*.c
compiled as objects (never an archive, so each family's registering constructor is linked, cf.
cq-f69). A build is cached under $CQE_CACHE (default <repo>/build/cqcheck-cache) by a hash of
everything that goes into it. The driver reads its sample at run time (cq-arch Z2), so the samples of
one example share one build.

Run. One process per sample: `prog` with $CQD_SAMPLES naming a one-record drivers.sample_file and
the trace (JSONL, cq-arch) written to $CQE_TRACE. A sample that cannot be built or run is a RunResult whose violations say why; it is
never dropped.

Sample values ({call, args}; call is an index into spec.calls, or a function name occurring there
once; args has one entry per argument of that call). canonical_sample turns each into the sampling
encoding (scalars "0x" + bit pattern, pointers a C expression) that drivers renders:
  int                  an integer ctype's value (wrapped to its width); for an fp ctype, that value
  float                an fp ctype's value (long double: the exact double)
  {"bits": "0x..."}    the raw bit pattern of the ctype (long double: the 80-bit x87 pattern)
  "bits:0x..."         the same
  "0x<hex digits>"     for an arithmetic ctype, its exact bit pattern: the sampling encoding that
                       drivers.c_value renders for the C oracle (cq-arch Z1, cq-a4mf), so both
                       sides receive the same value
  string               for an fp ctype, anything else Python's float() or float.fromhex() reads
                       ("nan", "-inf", "-0.0", "0x1p-1074"); for a pointer ctype, its C expression
                       ("coef", "&hostv", names defined by spec.setup)

RunResult fields (JSON-serializable):
  side        the side argument ('ours' or 'ref')
  sample      the sample dict as given
  outputs     {"ret": [{"call", "fn", "v"}], "stdout": str, "exit": int}; "v" is the typed
              scalar {"w": rail type, "v": hex bit pattern} of an arithmetic return (cq-pq3:
              integers "i<N>" at their C width, two's complement; float "f32", double "f64",
              long double "f80" as the x87 80-bit pattern), the bare hex of an aggregate return;
              void and pointer returns log nothing
  measured    [{"h", "w", "v"}] per cqrt_measure call, in order
  rotations   the rotation and phase trace events in order, as written (the shape compare.py
              reads): ry {ev, h, theta, ctl, ctlv, w, v}, ry_qangle {ev, h, a, aval, ctl, ctlv, w, v},
              phase {ev, f, fv, theta}, phase_qangle {ev, a, aval, ctl, ctlv}; theta is the hex bit
              pattern of the double; w and v are the Ry target's type and value at the gate
  kept        the exit event's live rails [{"h", "w", "v", "role"}], followed by the live QRAM cells
              and slots of rt-mem's {"ev":"qram","op":"exit"} event (roles qram_cell, qram_slot)
  clean       the free events [{"h", "v", "known", "w"}]
  violations  the trace's violation events [{"what", "h", "msg"}] plus run failures:
              build, sample, timeout, no_exit (the process ended without the exit event)
"""
from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import struct
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Sequence, Tuple

from cqcheck.contracts import DriverSpec, RunResult

REPO = Path(__file__).resolve().parents[2]
RT_DIR = REPO / "checker" / "rt"
LLVM_BIN = Path(os.environ.get("CQ_LLVM_BIN", "/usr/local/opt/llvm@19/bin"))
CLANG = str(LLVM_BIN / "clang")
LLVM_LINK = str(LLVM_BIN / "llvm-link")
DEFAULT_TIMEOUT = 30.0
_VERSION = "chk-core-1"


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


def norm_ctype(ct: str) -> str:
    ct = re.sub(r"\b(const|volatile|static|restrict|register)\b", " ", ct)
    ct = re.sub(r"\s*\*\s*", "*", ct)
    return " ".join(ct.split())


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
        # drivers.c_value's encoding: a bare 0x-hex sample value is the exact bit pattern.
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
  char line[256];
  snprintf(line, sizeof line, "{\"ev\":\"ret\",\"v\":\"%s\",\"w\":\"%s\",\"call\":%d,\"fn\":\"%s\"}", hex, w, call, fn);
  cqe_log(line);
}
#define CQD_RESULT(call, fn, w, p, n, bits) \
  cqd_ret(call, fn, (w)[0] == 'a' ? "" : (w), p, n, (bits) ? (bits) : (unsigned)(8 * (n)))
"""


def driver_c(spec: DriverSpec, samples: Sequence[dict]) -> str:
    """The driver C source: drivers.driver_source (cq-arch Z1/Z2: the one renderer of samples) with
    the result hook. It reads its samples from $CQD_SAMPLES at run time."""
    from cqcheck import drivers
    return _RESULT_PRELUDE + drivers.driver_source(spec, list(samples))


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


def _sh(cmd: Sequence[str], cwd: Optional[Path] = None) -> None:
    p = subprocess.run(list(cmd), cwd=cwd, capture_output=True, text=True)
    if p.returncode:
        raise BuildError(f"{Path(cmd[0]).name} failed ({p.returncode}): {p.stderr.strip()[-2000:]}")


def _triple(lowered_text: str) -> str:
    m = re.search(r'^target triple = "(.*)"', lowered_text, re.M)
    return m.group(1) if m else "x86_64-apple-macosx"


def runtime_objects(triple: str, rt_sources: Optional[Sequence[Path]] = None) -> List[Path]:
    """Every runtime source compiled to an object (cached by content)."""
    srcs = sorted(Path(s) for s in (rt_sources if rt_sources is not None else RT_DIR.glob("*.c")))
    h = hashlib.sha256((_VERSION + triple).encode())
    for s in srcs:
        h.update(str(s).encode())
        h.update(s.read_bytes())
    for hdr in sorted(RT_DIR.glob("*.h")):  # cqe.h, cq_standin.h
        h.update(hdr.read_bytes())
    d = _cache_root() / "rt" / h.hexdigest()[:24]
    objs = [d / (s.stem + ".o") for s in srcs]
    if all(o.exists() for o in objs):
        return objs
    tmp = Path(tempfile.mkdtemp(prefix="rt.", dir=_ensure(_cache_root() / "rt")))
    for s in srcs:
        _sh([CLANG, "-std=c17", "-O1", "-w", "-target", triple, "-I", str(RT_DIR), "-c", str(s), "-o",
             str(tmp / (s.stem + ".o"))])
    _publish(tmp, d)
    return objs


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
        return final / "prog"
    tmp = Path(tempfile.mkdtemp(prefix="prog.", dir=_ensure(_cache_root() / "prog")))
    (tmp / "driver.c").write_text(drv)
    shutil.copy(lowered, tmp / "lowered.ll")
    _sh([CLANG, "-O1", "-w", "-target", triple, "-S", "-emit-llvm", "driver.c", "-o", "driver.ll"], cwd=tmp)
    _sh([LLVM_LINK, "-S", "lowered.ll", "driver.ll", "-o", "linked.ll"], cwd=tmp)
    cargs = []
    if c_module:
        (tmp / "c_module.ll").write_text(ctext)
        cargs = ["--c-module", "c_module.ll"]
    _sh([sys.executable, str(RT_DIR / "stubgen.py"), "linked.ll", *cargs, "-o", "stubs.ll"], cwd=tmp)
    extra_objs = []
    for i, e in enumerate(extra_sources):
        o = tmp / f"extra{i}.o"
        _sh([CLANG, "-std=c17", "-O1", "-w", "-target", triple, "-I", str(RT_DIR), "-c", str(e), "-o", str(o)])
        extra_objs.append(str(o))
    _sh([CLANG, "-O0", "-w", "-target", triple, *[str(o) for o in objs], *extra_objs, "linked.ll", "stubs.ll",
         "-lm", "-o", "prog"], cwd=tmp)
    # First launch of a fresh binary can be slow (the host scans it); pay that here, not inside a
    # sample's timeout. With an empty sample file the driver runs the setup only.
    (tmp / "empty.samples").write_text("")
    try:
        subprocess.run([str(tmp / "prog")], cwd=tmp, capture_output=True, timeout=300,
                       env=dict(os.environ, CQE_TRACE=os.devnull, CQD_SAMPLES=str(tmp / "empty.samples")))
    except subprocess.TimeoutExpired as e:
        raise BuildError(f"the built program did not start within 300s: {e}")
    _publish(tmp, final)
    return final / "prog"


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


def _result(side: str, sample: Any, events: List[dict], stdout: str, code: Optional[int],
            extra: List[dict]) -> RunResult:
    rets = [{"call": e.get("call"), "fn": e.get("fn"),
             "v": {"w": e["w"], "v": e.get("v")} if e.get("w") else e.get("v")}
            for e in events if e.get("ev") == "ret"]
    measured = [{"h": e["h"], "w": e.get("w"), "v": e["v"]} for e in events if e.get("ev") == "measure"]
    rots = []
    for e in events:
        if e.get("ev") in ("ry", "ry_qangle", "phase", "phase_qangle"):
            rots.append(dict(e))
    exits = [e for e in events if e.get("ev") == "exit"]
    kept = list(exits[-1]["live"]) if exits else []
    # rt-mem's QRAM cells and unpopped slots live outside core's rail table; its exit event lists
    # them (roles qram_cell, qram_slot) and they are Kept items too (cq-lxv)
    for e in events:
        if e.get("ev") == "qram" and e.get("op") == "exit":
            kept.extend(e.get("live", []))
    clean = [{k: e.get(k) for k in ("h", "v", "known", "w")} for e in events if e.get("ev") == "free"]
    viol = [{k: e.get(k) for k in ("what", "h", "msg")} for e in events if e.get("ev") == "violation"]
    viol += extra
    if not exits and code is not None and not any(v["what"] in ("build", "sample", "timeout") for v in extra):
        viol.append({"what": "no_exit", "h": None, "msg": f"process ended (status {code}) without the exit event"})
    return RunResult(side=side, sample=sample, outputs={"ret": rets, "stdout": stdout, "exit": code},
                     measured=measured, rotations=rots, kept=kept, clean=clean, violations=viol)


def _parse_trace(text: str) -> Tuple[List[dict], List[dict]]:
    events, bad = [], []
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            bad.append({"what": "trace", "h": None, "msg": f"unparsable trace line: {line[:200]}"})
    return events, bad


def run_sample(lowered: Path, spec: DriverSpec, sample: dict, side: str, *, timeout: float = DEFAULT_TIMEOUT,
               rt_sources: Optional[Sequence[Path]] = None, extra_sources: Sequence[Path] = (),
               c_module: Optional[Path] = None) -> RunResult:
    """Run one sample of spec against the lowered module in the evaluator (cq-zew)."""
    from cqcheck import drivers
    try:
        canon = canonical_sample(spec, sample)
        record = drivers.sample_file(spec, [canon])
    except (SampleError, KeyError, TypeError, ValueError, RuntimeError) as e:
        return _result(side, sample, [], "", None, [{"what": "sample", "h": None, "msg": str(e)}])
    try:
        prog = build(Path(lowered), spec, [canon], rt_sources, extra_sources, c_module)
    except (BuildError, OSError, RuntimeError) as e:
        return _result(side, sample, [], "", None, [{"what": "build", "h": None, "msg": str(e)}])
    with tempfile.TemporaryDirectory(prefix="cqe-run.") as wd:
        trace = Path(wd) / "trace.jsonl"
        (Path(wd) / "sample").write_text(record)
        env = dict(os.environ, CQE_TRACE=str(trace), CQD_SAMPLES=str(Path(wd) / "sample"))
        try:
            p = subprocess.run([str(prog)], cwd=wd, env=env, capture_output=True, timeout=timeout)
            code, stdout, extra = p.returncode, p.stdout.decode(errors="replace"), []
            err = p.stderr.decode(errors="replace")
            if code < 0:
                extra.append({"what": "signal", "h": None, "msg": f"killed by signal {-code}: {err[-500:]}"})
            elif code == 3 and "cqd: sample" in err:
                extra.append({"what": "sample", "h": None, "msg": err.strip()[-500:]})
        except subprocess.TimeoutExpired as e:
            code, stdout = None, (e.stdout or b"").decode(errors="replace")
            extra = [{"what": "timeout", "h": None, "msg": f"no exit within {timeout}s"}]
        events, bad = _parse_trace(trace.read_text(errors="replace") if trace.exists() else "")
    return _result(side, sample, events, stdout, code, extra + bad)


def run_samples(lowered: Path, spec: DriverSpec, samples: Iterable[dict], side: str, jobs: int = 0,
                **kw) -> List[RunResult]:
    """run_sample over many samples, in order, jobs processes at a time (0: the CPU count)."""
    from concurrent.futures import ThreadPoolExecutor
    samples = list(samples)
    try:  # one build for all (each sample would find it in the cache; this avoids racing builds)
        canon = [canonical_sample(spec, s) for s in samples]
        build(Path(lowered), spec, canon, kw.get("rt_sources"), kw.get("extra_sources", ()), kw.get("c_module"))
    except (SampleError, BuildError, OSError, KeyError, TypeError, ValueError, RuntimeError):
        pass  # run_sample reports it per sample
    with ThreadPoolExecutor(max_workers=jobs or os.cpu_count() or 4) as ex:
        return list(ex.map(lambda s: run_sample(lowered, spec, s, side, **kw), samples))
