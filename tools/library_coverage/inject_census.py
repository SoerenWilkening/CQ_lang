#!/usr/bin/env python3
"""Source-injection census: inject openlibm bodies, inline to opcodes, run cq-lowering.

Reproducible harness for the OPCODE-lowering strategy documented in
INJECTION-CENSUS.md (previously a MANUAL investigation — this script fills that
gap). It measures how many math.h functions compile when the function INTERNALS
are lowered (not just the intrinsic NAME, which is COVERAGE.md's separate
template-recognition strategy). Per-function ITERATIVE dependency-closure link
(pull each undefined symbol's defining .bc until fixpoint) avoids the corpus-wide
complex-number multiple-definition conflict a single llvm-link hits.

A function COMPILES iff its body is FULLY inlined (no surviving @fn call — an
exit-0 on an un-inlined call is meaningless, INJECTION-CENSUS.md "Over-accept")
AND cq-lowering exits 0. A loud decline is a correct (uncovered) outcome.

REPRODUCE (openlibm is NOT a runtime dependency — a one-time source fetch to a
scratch dir; set BC below to where you build the bitcode corpus):
    git clone --depth 1 https://github.com/JuliaMath/openlibm <scratch>/openlibm
    mkdir <scratch>/bc
    for c in <scratch>/openlibm/src/*.c <scratch>/openlibm/bsdsrc/*.c; do
      clang -O1 -emit-llvm -c -I openlibm/include -I openlibm/src \
            -I openlibm/amd64 -I openlibm/bsdsrc "$c" -o bc/$(basename ${c%.c}).bc
    done   # ~217/242 compile; arch-asm/dup files fail-skip (expected)
    BC=<scratch>/bc  python3 inject_census.py     # -> inject_results.json

CAVEATS (same as the manual census): fenv-dependent bodies (nearbyint) and a few
self-referential/link-closure gaps (lgamma, sqrt/scalbn kernels) surface as
"exit0-but-uninlined"/"unknown callee" — harness limitations, not real compiles."""
import os, re, subprocess, sys, json, tempfile
from pathlib import Path

LLVM = Path("/usr/local/opt/llvm@19/bin")
CLANG, OPT, LINK, DIS = LLVM/"clang", LLVM/"opt", LLVM/"llvm-link", LLVM/"llvm-dis"
HERE = Path(__file__).resolve().parent
BC = Path(os.environ.get("BC", HERE/"bc"))   # openlibm bitcode corpus (built to scratch)
PASS = Path(__file__).resolve().parents[2]/"build/ir-pass/libCQPass.so"

# Map: which bc file(s) DEFINE each symbol (built once).
def build_symbol_index():
    defmap = {}   # symbol -> list of bc files defining it
    for b in sorted(BC.glob("*.bc")):
        try:
            ir = subprocess.run([DIS, str(b), "-o", "-"], capture_output=True, text=True, timeout=30).stdout
        except Exception:
            continue
        for m in re.finditer(r'^define[^@]*@([A-Za-z0-9_.$]+)\b', ir, re.M):
            defmap.setdefault(m.group(1), []).append(b)
    return defmap

def undefined_syms(bcfile):
    ir = subprocess.run([DIS, str(bcfile), "-o", "-"], capture_output=True, text=True).stdout
    declared = set(re.findall(r'^declare[^@]*@([A-Za-z0-9_.$]+)\b', ir, re.M))
    defined  = set(re.findall(r'^define[^@]*@([A-Za-z0-9_.$]+)\b', ir, re.M))
    return declared - defined

# Closure-link: pull defining bc files for undefined syms until fixpoint.
def closure_link(probe_bc, defmap, workdir):
    linkset = [probe_bc]
    seen_files = {probe_bc}
    for _ in range(40):
        cur = workdir/"cur.bc"
        r = subprocess.run([LINK]+[str(x) for x in linkset]+["-o", str(cur)],
                           capture_output=True, text=True)
        if r.returncode != 0:
            return None, "link-conflict: "+r.stderr.strip().split('\n')[0][:80]
        undef = undefined_syms(cur)
        added = False
        for s in undef:
            for f in defmap.get(s, []):
                if f not in seen_files:
                    linkset.append(f); seen_files.add(f); added = True
                    break
        if not added:
            return cur, None
    return None, "closure-did-not-converge"

def run_one(fn, argc, defmap):
    with tempfile.TemporaryDirectory() as td:
        td = Path(td)
        # Probe: taint argc doubles, call fn, measure. Extra args are classical consts.
        args = ", ".join(["q"]+["0.5"]*(argc-1))
        proto_args = ", ".join(["double"]*argc)
        src = f'''extern double {fn}({proto_args});
double cq_theta_f64(double, double);
double cq_measure_f64(double);
double probe(void){{
    double q = cq_theta_f64(0.5, 0.5);
    double r = {fn}({args});
    return cq_measure_f64(r);
}}'''
        (td/"probe.c").write_text(src)
        pbc = td/"probe.bc"
        r = subprocess.run([CLANG, "-O1", f"-fno-builtin-{fn}", "-emit-llvm", "-c",
                            str(td/"probe.c"), "-o", str(pbc)], capture_output=True, text=True)
        if r.returncode != 0:
            return ("build-fail", r.stderr.strip().split('\n')[-1][:80])
        linked, err = closure_link(pbc, defmap, td)
        if linked is None:
            return ("link-fail", err)
        inl = td/"inl.bc"
        subprocess.run([OPT, "-passes=internalize,always-inline,globaldce,default<O2>",
                        "-internalize-public-api-list=probe", "-inline-threshold=2000000",
                        str(linked), "-o", str(inl)], capture_output=True, text=True)
        ir = subprocess.run([DIS, str(inl), "-o", "-"], capture_output=True, text=True).stdout
        # surviving non-cq, non-intrinsic call = not fully inlined
        surv = [m for m in re.findall(r'call[^@]*@([A-Za-z0-9_.$]+)', ir)
                if not m.startswith("cq_") and not m.startswith("llvm.")]
        fully_inlined = len(surv) == 0
        r = subprocess.run([OPT, "-load-pass-plugin", str(PASS), "-passes=cq-lowering",
                            "-S", str(inl), "-o", "/dev/null"], capture_output=True, text=True)
        lowered = (r.returncode == 0)
        diag = ""
        if not lowered:
            for line in r.stderr.split('\n'):
                if 'error' in line.lower(): diag = line.split('in function')[-1][:90]; break
        # census rule: COMPILES iff fully inlined AND cq-lowering exit 0
        if lowered and fully_inlined:
            status = "COMPILES"
        elif lowered and not fully_inlined:
            status = "exit0-but-uninlined"   # meaningless per census
        else:
            status = "decline"
        return (status, (diag or f"surviving:{sorted(set(surv))[:3]}").strip())

# The census's 44 double functions (INJECTION-CENSUS.md).
FUNCS = {  # fn: argc
 "fabs":1,"nearbyint":1,"copysign":2,"sqrt":1,"fma":3,
 "sin":1,"cos":1,"tan":1,"exp":1,"exp2":1,"log":1,"log2":1,"log10":1,
 "asin":1,"acos":1,"atan":1,"sinh":1,"cosh":1,"tanh":1,"asinh":1,"acosh":1,"atanh":1,
 "expm1":1,"log1p":1,"logb":1,"cbrt":1,"floor":1,"trunc":1,"round":1,"ceil":1,"rint":1,
 "atan2":2,"pow":2,"remainder":2,"fdim":2,"scalbn":2,"hypot":2,"fmod":2,"fmax":2,"fmin":2,
 "nextafter":2,"erf":1,"erfc":1,"lgamma":1,
}

if __name__ == "__main__":
    print("building symbol index...", file=sys.stderr)
    defmap = build_symbol_index()
    print(f"indexed {len(defmap)} symbols across bc/", file=sys.stderr)
    results = {}
    for fn, argc in FUNCS.items():
        status, detail = run_one(fn, argc, defmap)
        results[fn] = {"status": status, "detail": detail}
        print(f"  {fn:12s} {status:22s} {detail}", file=sys.stderr)
    Path("inject_results.json").write_text(json.dumps(results, indent=2))
    from collections import Counter
    c = Counter(r["status"] for r in results.values())
    print("\n=== TALLY ===", file=sys.stderr)
    for k,v in c.most_common(): print(f"  {k:22s} {v}", file=sys.stderr)
