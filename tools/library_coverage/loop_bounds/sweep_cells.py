#!/usr/bin/env python3
# sweep_cells.py — bd 19v3: the WHOLE-CENSUS loop-bound population sweep.
#
# dump_cell.py dumps ONE cell (bd 8zj2's 8-cell hand list). This drives the SAME
# instrument (build/LoopBoundProbe.so) over EVERY census cell, enumerated the way
# full_census.main() enumerates them, so the population number is measured off the
# census's own surface rather than a hand list. It is measurement only: no pass
# change, and the shipped plugin is NEVER rebuilt by this script.
#
# MEASURES EACH CELL AT THREE MODULE POINTS, because "the module the pass sees" is
# not one module (trap 4 in the README, widened here):
#
#   inl   pre-lowering, the census's own stage-1 output at CENSUS_OPTLEVEL=O1
#   fp80  CQ_FP80_DBG — after `promoteFp80Union` fixpoint (CQLoweringPass.cpp:174)
#   spec  CQ_SPEC_DBG — before `detectSpecializations` (CQLoweringPass.cpp:223),
#         i.e. AFTER flattenPredMuxRegions AND unrollConstTripLoops
#
# `spec` is the closest shipped observation point to `lowerLoops` (line 279) and is
# the one that answers "what loops does the loop lowerer actually get". 8zj2 used
# `fp80` only; PredMux and the static-K unroll prepass both run between them, and
# both delete loops, so measuring `fp80` alone OVER-counts (measured: 14 cells drop
# to ZERO loops between the two points, and `tgammal.f80` 17 -> 4).
#
# WHAT SITS BETWEEN THE `spec` DUMP AND `lowerLoops`, stated exactly — an earlier
# draft of this header claimed "nothing creates or destroys a loop in an inlined
# census cell", which is stronger than the evidence. Four stages run in between and
# TWO of them can mutate:
#   detectSpecializations   (:235) pure analysis
#   declineTaintEscapes     (:244) MUTATES — RAUWs/erases a proven-foldable TAINTED
#                                 local-integer `freeze` (TaintPropagation.cpp:812).
#                                 No CFG change, so it cannot move the loop COUNT,
#                                 but it CAN move a SCEV bound.
#   declineStaleRecordOps   (:251) pure analysis
#   lowerControlledIOSinks  (:263) MUTATES THE CFG — flattens a tainted-condition
#                                 diamond whose arm calls extern `printf`/`putchar`.
# So the honest claim is a MEASUREMENT about this population, not a guarantee:
#   * `lowerControlledIOSinks` cannot fire here — 0 of 125 cells contain `@printf`
#     or `@putchar`, at any of the three module points.
#   * only 3 cells contain a `freeze` at all (cosf/sinf/tanf.f32, one `i32` each),
#     its operand measures UNTAINTED in all three so the fold does not fire, and
#     folding it by hand moves exactly one bound — `k_rem_pio2.c:404`, 4 -> unknown,
#     i.e. `spec` would OVER-state that bound, and that loop is excluded anyway.
#   * cross-checked end to end where it is checkable: for all 103 exit-0 cells the
#     FINAL lowered module's loop count equals `spec`'s, 0 mismatches.
# Re-check all four if the orchestrator order changes.
#
# Both ScalarEvolution flavours are run at every point (`cq-spike-scev` = the pass
# manager's SE; `cq-spike-scev-passstyle` = the one LoopLowering hand-constructs
# with a conservative TLI), because if they disagree every number measured through
# the first one is the wrong number for the question being asked.
#
#   BC=/private/tmp/bc OPENLIBM=/private/tmp/openlibm \
#     CQ_SWEEP_OUT=/private/tmp/cq19v3 python3 sweep_cells.py [-j N] [cell...]
#
# Output: <out>/sweep.json + <out>/cells/<cell>/{probe.c,inl.ll,fp80.ll,spec.ll,
#         lowering.stderr,scev_<point>_<flavour>.txt}
import os, sys, json, re, argparse, subprocess
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
os.environ.setdefault("BC", "/private/tmp/bc")
os.environ.setdefault("OPENLIBM", "/private/tmp/openlibm")
os.environ["CENSUS_OPTLEVEL"] = "O1"          # the ship floor, per 19v3
sys.path.insert(0, str(REPO / "tools/library_coverage/full_surface"))
sys.path.insert(0, str(REPO / "tools/library_coverage"))
import wprobe as W
import probe as P
import full_census as FC

PROBE_SO = HERE / "build/LoopBoundProbe.so"
OUT = Path(os.environ.get("CQ_SWEEP_OUT", "/private/tmp/cq19v3"))

FP80_BANNER = "=== CQ_FP80_DBG: module after promoteFp80Union fixpoint ==="
SPEC_BANNER = "=== CQ_SPEC_DBG: module before detectSpecializations ==="


def enumerate_cells():
    """EXACTLY full_census.main()'s cell loop — same skips, same widths, same
    arg conventions. Returns [(key, spelling, retwidth, args, provider)]."""
    cells = []
    for spec in P.MATHH_SPEC:
        base = spec["base"]
        if base in FC.KEEP:                continue   # hardware keep-set
        if "macro" in spec["flags"]:       continue   # not a real call
        if spec["backend"] == "n/a":       continue   # by-design (nan)
        for v in spec["variants"]:
            width, ctype, suf, lit = FC.VAR[v]
            spelling = base + suf
            args = FC.cell_args(spec, width, ctype, lit)
            if args is None:               continue   # str arg — no taintable input
            rw = FC.ret_width(spec, width)
            provider = "cq" if spelling in FC.CQPROV else "openlibm"
            cells.append((f"{spelling}.{width}", spelling, rw, args, provider))
    return cells


def _extract_module(text, banner, nxt_banner=None):
    """Carve one M.print() dump out of the pass's stderr.

    The dump is followed by whatever the pass printed next — the other dump, or
    the DS_Error diagnostics. An LLVM module print always ends in its metadata
    block, so cut at the LAST line that is metadata / a closing brace / an
    attribute group, and refuse (return None) if no plausible end is found rather
    than hand a truncated module to the reporter."""
    i = text.find(banner)
    if i < 0:
        return None
    body = text[i + len(banner):]
    if nxt_banner:
        j = body.find(nxt_banner)
        if j >= 0:
            body = body[:j]
    lines = body.split("\n")
    end = None
    for n, ln in enumerate(lines):
        if re.match(r'^(![-A-Za-z0-9_.]+ = |!\d+ = |attributes #|\}$)', ln):
            end = n
    if end is None:
        return None
    return "\n".join(lines[:end + 1]) + "\n"


def _scev(mod_path, passname, out_path):
    r = subprocess.run([str(W.OPT), "-load-pass-plugin", str(PROBE_SO),
                        f"-passes={passname}", "-disable-output", str(mod_path)],
                       capture_output=True, text=True, timeout=600)
    out_path.write_text(r.stdout + ("\n--- stderr ---\n" + r.stderr if r.stderr else ""))
    return r.stdout


def parse_scev(txt):
    """Structure the reporter's output. Reads the reporter's own lines only — no
    re-derivation of any SCEV fact here (the instrument is the authority)."""
    loops, cur, fn = [], None, None
    for ln in txt.split("\n"):
        m = re.match(r'^=== (?:\[PASS-STYLE SE\] )?function @(\S+) ===', ln)
        if m:
            fn = m.group(1); continue
        m = re.match(r'^LOOP #(\d+) depth=(\d+) innermost=(\S+)', ln)
        if m:
            cur = {"fn": fn, "idx": int(m.group(1)), "depth": int(m.group(2)),
                   "innermost": m.group(3) == "yes", "exit_conds": []}
            loops.append(cur); continue
        if cur is None:
            continue
        for key, pat in (("header",   r'^  header      = (\S+)'),
                         ("dbg",      r'^  header      = \S+  @ (\S+)'),
                         ("latch",    r'^  latch       = (\S+)'),
                         ("btc_exact",  r'^  BTC exact              = (.*)$'),
                         ("btc_cmax",   r'^  BTC constant-max       = (.*)$'),
                         ("btc_smax",   r'^  BTC symbolic-max       = (.*)$'),
                         ("verdict",  r'^  VERDICT bound-kind = (.*)$'),
                         ("unsound",  r'^  UNSOUND formula getSignedRange\(symbolicMax\)\.getSignedMax\(\) = (.*)$')):
            m = re.match(pat, ln)
            if m:
                cur[key] = m.group(1).strip()
        m = re.match(r'^  exiting     =(.*)\s+\(count (\d+)\)', ln)
        if m:
            cur["n_exiting"] = int(m.group(2)); cur["exiting"] = m.group(1).split()
        m = re.match(r'^  exit blocks =(.*)\s+\(count (\d+)\)', ln)
        if m:
            cur["n_exits"] = int(m.group(2))
        m = re.match(r'^  header-is-exiting = (\S+)', ln)
        if m:
            cur["header_exiting"] = m.group(1) == "yes"
        m = re.match(r'^  exit-cond   @(\S+) : (.*)$', ln)
        if m:
            cur["exit_conds"].append({"bb": m.group(1), "cond": m.group(2)})
        m = re.match(r'^  SOUND trip bound \(getSmallConstantMaxTripCount\) = (\d+)', ln)
        if m:
            cur["trip_max"] = int(m.group(1))
        m = re.match(r'^  exact trip \(getSmallConstantTripCount\)          = (\d+)', ln)
        if m:
            cur["trip_exact"] = int(m.group(1))
        m = re.match(r'^    isKnownNonNegative\(symbolicMax\) = (\S+)', ln)
        if m:
            cur["smax_nonneg"] = m.group(1) == "yes"
    return loops


def run_cell(job):
    key, fn, retW, args, provider, defmap = job
    td = OUT / "cells" / key
    td.mkdir(parents=True, exist_ok=True)
    rec = {"cell": key, "fn": fn, "provider": provider}

    if fn not in defmap:
        rec["status"] = "no-body"
        rec["note"] = "no definition in the corpus defmap — NOT PROBED (bd keol)"
        return rec

    # ---- stage 1: the census's own pre-lowering module ---------------------
    src = W.make_src(fn, retW, args, 0)
    (td / "probe.c").write_text(src)
    pbc = td / "probe.bc"
    r = subprocess.run([str(W.CLANG), "-O1", "-g", "-fno-builtin", f"-fno-builtin-{fn}",
                        "-emit-llvm", "-c"] + W.INC.split() + [str(td / "probe.c"),
                        "-o", str(pbc)], capture_output=True, text=True)
    if r.returncode != 0:
        rec["status"] = "build-fail"; rec["note"] = r.stderr[-200:]; return rec
    linked, err = W.closure_link(pbc, defmap, td)
    if linked is None:
        rec["status"] = "link-fail"; rec["note"] = str(err)[:200]; return rec
    inl = td / "inl.ll"
    subprocess.run([str(W.OPT),
                    f"-passes=internalize,always-inline,globaldce,default<{W.CENSUS_OPTLEVEL}>,"
                    f"scalarizer,instcombine,dce",
                    "-internalize-public-api-list=probe", "-inline-threshold=2000000",
                    str(linked), "-S", "-o", str(inl)], capture_output=True, text=True)

    # ---- stage 2: cq-lowering, clean (reproduces the census status/diag) ----
    r = subprocess.run([str(W.OPT), "-load-pass-plugin", str(W.PASS),
                        "-passes=cq-lowering", "-S", str(inl), "-o", str(td / "low.ll")],
                       capture_output=True, text=True)
    (td / "lowering.stderr").write_text(r.stderr)
    rec["exit0"] = (r.returncode == 0)
    rec["diag_full"] = ""
    for line in r.stderr.split("\n"):
        if "error" in line.lower():
            rec["diag_full"] = line.strip()[:400]; break
    # census-identical status computation (wprobe.probe): COMPILES needs BOTH a
    # zero exit AND no surviving non-cq/llvm callee in the PRE-lowering module.
    ir = inl.read_text()
    surv = [m for m in re.findall(r'call[^@\n]*@([A-Za-z0-9_.$]+)', ir)
            if not m.startswith("cq_") and not m.startswith("llvm.")]
    if rec["exit0"] and not surv:
        rec["status"] = "COMPILES"
    elif rec["exit0"]:
        low = (td / "low.ll").read_text() if (td / "low.ll").exists() else ""
        rec["status"] = f"exit0-spec:{sorted(set(surv))}" if "__cq_q_" in low else f"exit0:{sorted(set(surv))}"
    else:
        rec["status"] = "decline"
    rec["bucket"] = FC.bucket(rec["status"], rec["diag_full"])

    # ---- stage 3: the two in-pass module dumps -----------------------------
    env = dict(os.environ, CQ_FP80_DBG="1", CQ_SPEC_DBG="1")
    r2 = subprocess.run([str(W.OPT), "-load-pass-plugin", str(W.PASS),
                         "-passes=cq-lowering", "-S", str(inl), "-o", "/dev/null"],
                        capture_output=True, text=True, env=env)
    points = {"inl": inl}
    for name, banner, nxt in (("fp80", FP80_BANNER, SPEC_BANNER),
                              ("spec", SPEC_BANNER, None)):
        mod = _extract_module(r2.stderr, banner, nxt)
        if mod is not None:
            p = td / f"{name}.ll"
            p.write_text(mod)
            # A dump the reporter cannot parse is a carving bug, not a result —
            # verify it round-trips before trusting any loop count read off it.
            chk = subprocess.run([str(W.OPT), "-passes=verify", "-disable-output", str(p)],
                                 capture_output=True, text=True)
            if chk.returncode == 0:
                points[name] = p
            else:
                rec.setdefault("dump_broken", []).append(name)

    # ---- stage 4: SCEV, every point x both SE flavours ---------------------
    rec["loops"] = {}
    for pname, ppath in points.items():
        for flav, passname in (("pm", "cq-spike-scev"),
                               ("passstyle", "cq-spike-scev-passstyle")):
            try:
                txt = _scev(ppath, passname, td / f"scev_{pname}_{flav}.txt")
            except subprocess.TimeoutExpired:
                rec["loops"][f"{pname}/{flav}"] = "TIMEOUT"; continue
            rec["loops"][f"{pname}/{flav}"] = parse_scev(txt)
    rec["points"] = sorted(points)
    return rec


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-j", type=int, default=6)
    ap.add_argument("cells", nargs="*")
    a = ap.parse_args()

    if not PROBE_SO.exists():
        sys.exit(f"missing {PROBE_SO} — build it per the README (standalone)")
    print("indexing openlibm corpus...", file=sys.stderr)
    defmap = W.build_defmap()
    print(f"  {len(defmap)} syms / {len(list(W.BC.glob('*.bc')))} bc", file=sys.stderr)
    if len(defmap) != 409:
        print(f"  *** FINGERPRINT {len(defmap)}, EXPECTED 409 — an under-linked "
              f"corpus UNDER-MEASURES. Fix step 1b before trusting this run. ***",
              file=sys.stderr)

    cells = enumerate_cells()
    if a.cells:
        cells = [c for c in cells if c[0] in set(a.cells)]
    print(f"  {len(cells)} cells", file=sys.stderr)
    OUT.mkdir(parents=True, exist_ok=True)

    jobs = [(k, f, rw, ar, pr, defmap) for (k, f, rw, ar, pr) in cells]
    out = {}
    with ProcessPoolExecutor(max_workers=a.j) as ex:
        for n, rec in enumerate(ex.map(run_cell, jobs), 1):
            out[rec["cell"]] = rec
            nl = len(rec.get("loops", {}).get("spec/passstyle", []) or [])
            print(f"  [{n:3d}/{len(cells)}] {rec['cell']:18s} {rec.get('status','?'):22s} "
                  f"loops(spec)={nl}", file=sys.stderr)
    (OUT / "sweep.json").write_text(json.dumps(out, indent=1, default=str))
    print(f"wrote {OUT/'sweep.json'}", file=sys.stderr)


if __name__ == "__main__":
    main()
