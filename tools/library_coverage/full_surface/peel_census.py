#!/usr/bin/env python3
# Full-DEPTH peel census (bd 3c6m.NN) — the width/by-ref/int-ret widening of
# full_census.py, extended to capture the ORDERED BLOCKER STACK per cell rather
# than only the first blocker. Two modes:
#
#   * normal plugin (CQ_PEEL_CENSUS unset): the pass bails on the first blocker,
#     so this records the single first-blocker (identical to full_census.py, but
#     over the reconciled 123-cell surface and refreshed against the current
#     plugin).
#   * census-mode plugin (built with the throwaway CQ_PEEL_CENSUS instrumentation,
#     run with CQ_PEEL_CENSUS=1): every analysis/detection guard logs ALL its
#     blockers as `cq-peel: <classtag> @ file:line` remarks WITHOUT bailing, so a
#     single run per cell surfaces the COMPLETE blocker set. This driver collects
#     every such line -> the full per-cell capability set.
#
# Parallel across cells (defmap built once, multiprocessing pool). Reuses
# wprobe.py's probe pipeline verbatim for the build/closure-link/inline stages;
# only the pass invocation + stderr parse differ (collect-all vs first-error).
import sys, os, re, json, subprocess, tempfile, time
from pathlib import Path
from collections import defaultdict
from multiprocessing import Pool

sys.path.insert(0, str(Path(__file__).resolve().parent))          # wprobe
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))   # probe
import wprobe as W
import probe as P

VAR = {"f": ("f32", "float", "f", "0.5f"), "": ("f64", "double", "", "0.5"),
       "l": ("f80", "long double", "l", "0.5L")}
KEEP = set(P.HARDWARE_KEEP_SET.split())
CENSUS = os.environ.get("CQ_PEEL_CENSUS", "") not in ("", "0")

# ---- cell enumeration (mirrors full_census.py, + the ldbl arg-kind) ----
def cell_args(spec, width, ctype, lit):
    out = []
    for i, a in enumerate(spec["args"]):
        if a == "fp":
            out.append(("q", width) if i == 0 else (f"c:{ctype}:{lit}",))
        elif a == "int":   out.append(("c:int:2",))
        elif a == "long":  out.append(("c:long:2",))
        elif a == "ldbl":  out.append(("c:long double:0.5L",))
        elif a == "int*":  out.append(("ref:int",))
        elif a == "fp*":   out.append((f"ref:{ctype}",))
        elif a == "str":   return None
        else: return None
    return out

def ret_width(spec, width):
    r = spec["ret"]
    if r == "fp":   return width
    if r == "long": return "sl"
    return None   # int-return (ilogb) — skipped

def enumerate_cells():
    cells = []
    for spec in P.MATHH_SPEC:
        base = spec["base"]
        if base in KEEP: continue
        if "macro" in spec["flags"]: continue
        if spec["backend"] == "n/a": continue
        for v in spec["variants"]:
            width, ctype, suf, lit = VAR[v]
            spelling = base + suf
            args = cell_args(spec, width, ctype, lit)
            if args is None: continue
            rw = ret_width(spec, width)
            if rw is None: continue
            cells.append((spelling, width, rw, args))
    return cells

# ---- blocker extraction ----
# census-mode line:  cq-peel: <file>:<line>:<col>: in function <fn> (): cq <message>
# normal-mode line:  error:   <file>:<line>:<col>: in function <fn> (): cq <message>
PEEL_RE = re.compile(r'cq-peel:\s*(.*?):\s*in function.*?:\s*cq\s+(.*)')
ERR_RE  = re.compile(r'(?:error|warning):\s*(.*?):\s*in function.*?:\s*cq\s+(.*)')

# class fragment -> raw blocker tag. Order matters (first match wins): more
# specific fragments precede the generic ones. Lever folding is done in analysis.
CLASS_KEYS = [
    ("nested control",                 "L6-nested-control"),
    ("control flow inside a loop",     "in-loop-control"),
    ("tainted-index memory access inside a loop", "qram-in-loop"),
    ("arm rewrites a condition",       "clobber-3c"),
    ("const-global table read",        "qram-read-under-control"),
    ("array has no compile-time shape","shadow-dynamic"),
    ("aliasing fan-out",               "shadow-alias"),
    ("QRAM access",                    "qram-other"),
    ("stored to memory",               "shadow-store"),
    ("muxed by a classical-condition", "classical-mux"),
    ("classical-condition",            "classical-mux"),
    ("control flow under quantum",     "control-flat-diamond"),
    ("under quantum control",          "control-flat-diamond"),
    ("floating-point quantum",         "fp-specialization"),
    ("specialization",                 "fp-specialization"),
    ("reversible copy",                "fp-copy"),
    ("unknown callee",                 "unknown-callee"),
    ("unsupported instruction",        "unsupported-opcode"),
    ("consumed by",                    "taint-escape-consume"),
    ("non-i32 return",                 "escape-return"),
    ("angle",                          "angle-fence"),
    ("loop",                           "loop-carried"),
    ("store",                          "shadow-store"),
    ("taint escape",                   "taint-escape"),
]

def classify(msg):
    m = msg.lower()
    for frag, tag in CLASS_KEYS:
        if frag in m:
            return tag
    return "other:" + m[:40].strip()

def probe_stack(fn, retW, args, defmap):
    """Run the full pipeline; return (fully_inlined, exit0, [ (classtag, loc, rawmsg) ... ])."""
    src = W.make_src(fn, retW, args, 0)
    with tempfile.TemporaryDirectory() as td:
        td = Path(td)
        (td / "probe.c").write_text(src)
        pbc = td / "probe.bc"
        r = subprocess.run([W.CLANG, "-O1", "-g", "-fno-builtin", f"-fno-builtin-{fn}",
                            "-emit-llvm", "-c"] + W.INC.split() + [str(td / "probe.c"), "-o", str(pbc)],
                           capture_output=True, text=True)
        if r.returncode != 0:
            return (False, False, [("build-fail", "", r.stderr.strip().split("\n")[-1][:80])])
        linked, err = W.closure_link(pbc, defmap, td)
        if linked is None:
            return (False, False, [("link-fail", "", err)])
        inl = td / "inl.bc"
        subprocess.run([W.OPT, "-passes=internalize,always-inline,globaldce,default<O2>,scalarizer,instcombine,dce",
                        "-internalize-public-api-list=probe", "-inline-threshold=2000000",
                        str(linked), "-o", str(inl)], capture_output=True, text=True)
        ir = subprocess.run([W.DIS, str(inl), "-o", "-"], capture_output=True, text=True).stdout
        surv = sorted(set(m for m in re.findall(r'call[^@\n]*@([A-Za-z0-9_.$]+)', ir)
                          if not m.startswith("cq_") and not m.startswith("llvm.")))
        fully = len(surv) == 0
        r = subprocess.run([W.OPT, "-load-pass-plugin", str(W.PASS), "-passes=cq-lowering",
                            "-S", str(inl), "-o", "/dev/null"], capture_output=True, text=True)
        exit0 = (r.returncode == 0)
        blockers = []
        seen = set()
        for line in r.stderr.split("\n"):
            m = PEEL_RE.search(line) or ERR_RE.search(line)
            if not m:
                continue
            loc, msg = m.group(1).strip(), m.group(2).strip()
            tag = classify(msg)
            key = (tag, loc)
            if key not in seen:
                seen.add(key); blockers.append((tag, loc, msg[:120]))
        return (fully, exit0, blockers)

_DEFMAP = None
def _worker(cell):
    fn, width, rw, args = cell
    fully, exit0, blockers = probe_stack(fn, rw, args, _DEFMAP)
    if exit0 and fully and not blockers:
        status = "COMPILES"
    elif exit0 and not fully:
        status = "exit0-uninlined"
    elif exit0 and blockers:
        status = "census-blockers"     # census mode: exit0 but logged blockers
    else:
        status = "decline"
    return f"{fn}.{width}", {
        "fn": fn, "width": width, "status": status, "fully_inlined": fully,
        "exit0": exit0, "n_blockers": len(blockers),
        "blockers": [{"class": t, "loc": l, "msg": m} for t, l, m in blockers],
    }

def _init(dm):
    global _DEFMAP
    _DEFMAP = dm

def main():
    t0 = time.time()
    print("indexing openlibm corpus...", file=sys.stderr)
    defmap = W.build_defmap()
    print(f"  {len(defmap)} syms / {len(list(W.BC.glob('*.bc')))} bc  ({time.time()-t0:.0f}s)", file=sys.stderr)
    cells = enumerate_cells()
    print(f"  {len(cells)} census-runnable cells; mode={'CENSUS' if CENSUS else 'first-blocker'}", file=sys.stderr)
    nproc = min(10, os.cpu_count() or 4)
    results = {}
    with Pool(nproc, initializer=_init, initargs=(defmap,)) as pool:
        for key, rec in pool.imap_unordered(_worker, cells):
            results[key] = rec
            b = rec["blockers"]
            tags = ",".join(sorted(set(x["class"] for x in b))) or rec["status"]
            print(f"  {key:16s} {rec['status']:16s} [{rec['n_blockers']}] {tags}", file=sys.stderr)
    out = "peel_census_results.json" if CENSUS else "first_blocker_refreshed.json"
    json.dump(results, open(Path(__file__).resolve().parent / out, "w"), indent=1)
    # summary
    comp = [k for k, v in results.items() if v["status"] == "COMPILES"]
    print(f"\n=== {'CENSUS(full-stack)' if CENSUS else 'FIRST-BLOCKER'}: {len(cells)} cells ===")
    print(f"COMPILES: {len(comp)}  -> {sorted(comp)}")
    bc = defaultdict(int)
    for v in results.values():
        for t in sorted(set(x["class"] for x in v["blockers"])):
            bc[t] += 1
    print("cells touching each blocker class:")
    for t, n in sorted(bc.items(), key=lambda x: -x[1]):
        print(f"  {n:3d}  {t}")
    print(f"wrote {out}  ({time.time()-t0:.0f}s total)", file=sys.stderr)

if __name__ == "__main__":
    main()
