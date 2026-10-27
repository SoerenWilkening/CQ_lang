"""Checker core, Python side (cq-w0-chk-core): build a lowered module with the evaluator runtime and a
driver, run one sample, return a RunResult.

    run_sample(lowered: Path, spec: DriverSpec, sample: dict, side: str) -> RunResult   (cq-zew)

Build. driver.c (generated from the DriverSpec) is compiled to IR with clang-19 for the lowered
module's triple, llvm-link joins it to the lowered module, checker/rt/stubgen.py defines every
cqrt_*/cq_template_* the linked module declares, and clang links that with every checker/rt/*.c
compiled as objects (never an archive, so each family's registering constructor is linked, cf.
cq-f69). A build is cached under $CQE_CACHE (default <repo>/build/cqcheck-cache) by a hash of
everything that goes into it, so the samples of one example share one build.

Run. One process per sample: `prog <call> <arg>...`, with the trace (JSONL, cq-arch) written to
$CQE_TRACE. A sample that cannot be built or run is a RunResult whose violations say why; it is
never dropped.

Sample values ({call, args}; call is an index into spec.calls, or a function name occurring there
once; args has one entry per argument of that call):
  int                  an integer ctype's value (wrapped to its width); for an fp ctype, that value
  float                an fp ctype's value (long double: the exact double)
  {"bits": "0x..."}    the raw bit pattern of the ctype (long double: the 80-bit x87 pattern)
  "bits:0x..."         the same
  string               for an fp ctype, anything Python's float() or float.fromhex() reads
                       ("nan", "-inf", "-0.0", "0x1p-1074"); otherwise a C expression pasted into
                       the driver (pointers: "coef", "&hostv", names defined by spec.setup)

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

_DRIVER_PRELUDE = r"""
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
void cqe_log(const char *json_object);
__attribute__((unused)) static const double coef[4] = {1, 2, 3, 4};
__attribute__((unused)) static const int icoef[4] = {1, 2, 3, 4};
static int cqd_arg(void *dst, size_t n, const char *a) {
  if (a[0] == 'e') return atoi(a + 2);
  unsigned long long w[2] = {0, 0};
  const char *p = a + 2; char *e;
  w[0] = strtoull(p, &e, 16);
  if (*e == ':') w[1] = strtoull(e + 1, 0, 16);
  memset(dst, 0, n);
  memcpy(dst, w, n < sizeof w ? n : sizeof w);
  return -1;
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
  char line[256];
  snprintf(line, sizeof line, "{\"ev\":\"ret\",\"v\":\"%s\",\"w\":\"%s\",\"call\":%d,\"fn\":\"%s\"}", hex, w, call, fn);
  cqe_log(line);
}
"""


def _parse_proto(p: str) -> Tuple[str, str, List[str]]:
    m = re.match(r"\s*(.*?)\b([A-Za-z_]\w*)\s*\((.*)\)\s*;?\s*$", p, re.S)
    if not m:
        raise BuildError(f"prototype {p!r} not understood")
    params = [x.strip() for x in m.group(3).split(",") if x.strip() and x.strip() != "void"]
    return m.group(1).strip(), m.group(2), params


def driver_c(spec: DriverSpec, exprs: Dict[Tuple[int, int], List[str]]) -> str:
    """The driver C source: main(argc, argv) runs call argv[1] with arguments argv[2:] ("b:<lo>:<hi>"
    bit patterns or "e:<n>", the n-th expression of exprs[(call, arg)]) and logs its return value."""
    protos = {}
    for p in spec.protos:
        rt, name, params = _parse_proto(p)
        protos.setdefault(name, (rt, params))
    out = [_DRIVER_PRELUDE]
    out += [p.strip().rstrip(";") + ";" for p in spec.protos]
    out.append("int main(int argc, char **argv) {")
    out.append("  if (argc < 2) return 2;")
    out.append("  int cqd_call = atoi(argv[1]); (void)cqd_call;")
    out.append("  " + (spec.setup or ""))
    out.append("  switch (cqd_call) {")
    for ci, call in enumerate(spec.calls):
        fn = call["fn"]
        args = call.get("args", [])
        rt = protos.get(fn, ("int", []))[0]
        out.append(f"  case {ci}: {{")
        out.append(f"    if (argc != {2 + len(args)}) return 3;")
        names = []
        for ai, a in enumerate(args):
            ct = norm_ctype(a["ctype"]) if ctype_kind(a["ctype"])[0] != "ptr" else a["ctype"].replace("static", "")
            nm = f"a{ai}"
            names.append(nm)
            out.append(f"    {ct} {nm};")
            out.append(f"    switch (cqd_arg(&{nm}, sizeof {nm}, argv[{2 + ai}])) {{")
            for ei, e in enumerate(exprs.get((ci, ai), [])):
                out.append(f"      case {ei}: {nm} = ({ct})({e}); break;")
            out.append("      default: break;")
            out.append("    }")
        callexpr = f"{fn}({', '.join(names)})"
        kind, bits = ctype_kind(rt)
        nrt = norm_ctype(rt)
        if nrt == "void" or kind == "ptr":
            out.append(f"    (void){callexpr};")
        else:
            if kind == "fp":
                rbits, w = bits, f"f{bits}"
            elif kind == "int":
                rbits, w = bits, f"i{bits}"
            else:
                rbits, w = 0, ""   # an aggregate return: raw bytes, untyped
            out.append(f"    {nrt} r = {callexpr};")
            out.append(f"    cqd_ret({ci}, \"{fn}\", \"{w}\", &r, sizeof r, {rbits} ? {rbits} : (unsigned)(8 * sizeof r));")
        out.append("    break; }")
    out.append("  default: return 4;")
    out.append("  }")
    out.append("  return 0;")
    out.append("}")
    return "\n".join(out) + "\n"


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
    h.update((RT_DIR / "cqe.h").read_bytes())
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


def build(lowered: Path, spec: DriverSpec, exprs: Dict[Tuple[int, int], List[str]],
          rt_sources: Optional[Sequence[Path]] = None, extra_sources: Sequence[Path] = ()) -> Path:
    """The executable for (lowered, spec, exprs); cached."""
    text = Path(lowered).read_text()
    triple = _triple(text)
    objs = runtime_objects(triple, rt_sources)
    drv = driver_c(spec, exprs)
    h = hashlib.sha256()
    for part in (_VERSION, text, drv, (RT_DIR / "stubgen.py").read_text(), Path(__file__).read_text(),
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
    _sh([sys.executable, str(RT_DIR / "stubgen.py"), "linked.ll", "-o", "stubs.ll"], cwd=tmp)
    extra_objs = []
    for i, e in enumerate(extra_sources):
        o = tmp / f"extra{i}.o"
        _sh([CLANG, "-std=c17", "-O1", "-w", "-target", triple, "-I", str(RT_DIR), "-c", str(e), "-o", str(o)])
        extra_objs.append(str(o))
    _sh([CLANG, "-O0", "-w", "-target", triple, *[str(o) for o in objs], *extra_objs, "linked.ll", "stubs.ll",
         "-lm", "-o", "prog"], cwd=tmp)
    # First launch of a fresh binary can be slow (the host scans it); pay that here, not inside a
    # sample's timeout. With no arguments the driver returns 2 at once.
    try:
        subprocess.run([str(tmp / "prog")], cwd=tmp, capture_output=True, timeout=300,
                       env=dict(os.environ, CQE_TRACE=os.devnull))
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
               rt_sources: Optional[Sequence[Path]] = None, extra_sources: Sequence[Path] = ()) -> RunResult:
    """Run one sample of spec against the lowered module in the evaluator (cq-zew)."""
    try:
        ci = _resolve_call(spec, sample.get("call"))
        cargs = spec.calls[ci].get("args", [])
        vals = sample.get("args", [])
        if len(vals) != len(cargs):
            raise SampleError(f"call {ci} takes {len(cargs)} arguments, the sample gives {len(vals)}")
        argv, exprs = [str(ci)], {}
        for ai, (a, v) in enumerate(zip(cargs, vals)):
            kind, x = encode_arg(a["ctype"], v)
            if kind == "bits":
                argv.append(f"b:{x & (2**64 - 1):x}:{x >> 64:x}")
            else:
                exprs[(ci, ai)] = [x]
                argv.append("e:0")
    except (SampleError, KeyError, TypeError, ValueError) as e:
        return _result(side, sample, [], "", None, [{"what": "sample", "h": None, "msg": str(e)}])
    try:
        prog = build(Path(lowered), spec, exprs, rt_sources, extra_sources)
    except (BuildError, OSError) as e:
        return _result(side, sample, [], "", None, [{"what": "build", "h": None, "msg": str(e)}])
    with tempfile.TemporaryDirectory(prefix="cqe-run.") as wd:
        trace = Path(wd) / "trace.jsonl"
        env = dict(os.environ, CQE_TRACE=str(trace))
        try:
            p = subprocess.run([str(prog), *argv[0:1], *argv[1:]], cwd=wd, env=env, capture_output=True,
                               timeout=timeout)
            code, stdout, extra = p.returncode, p.stdout.decode(errors="replace"), []
            if code < 0:
                extra.append({"what": "signal", "h": None,
                              "msg": f"killed by signal {-code}: {p.stderr.decode(errors='replace')[-500:]}"})
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
    with ThreadPoolExecutor(max_workers=jobs or os.cpu_count() or 4) as ex:
        return list(ex.map(lambda s: run_sample(lowered, spec, s, side, **kw), samples))
