#!/usr/bin/env python3
# Dump the census-pipeline PRE-LOWERING module for one cell at the -O1 ship
# floor, exactly as wprobe.probe() builds it, plus the cq-lowering diagnostic.
# Measurement only; no pass change. Originally bd 8zj2; committed for bd 19v3.
#
# Faithfulness: every command below is copied from wprobe.probe() (lines 497-536),
# with CENSUS_OPTLEVEL forced to O1 (the ship floor) instead of the O2 default.
# If wprobe.probe() changes, THIS MUST BE RE-SYNCED — there is nothing mechanical
# holding the two together.
#
#   BC=<bc-dir> OPENLIBM=<src-dir> CQ_DUMP_OUT=<outdir> python3 dump_cell.py [cell...]
#
# NOTE for ld80 cells: inl.ll is NOT the module the pass analyses —
# CQLoweringPass.cpp:170 runs promoteFp80Union to fixpoint first. Use
# CQ_FP80_DBG=1 on the cq-lowering run to dump the post-promotion module.
import os, sys, subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]                      # tools/library_coverage/loop_bounds -> repo root

os.environ.setdefault("BC", "/private/tmp/bc")
os.environ.setdefault("OPENLIBM", "/private/tmp/openlibm")
os.environ["CENSUS_OPTLEVEL"] = "O1"
sys.path.insert(0, str(REPO / "tools/library_coverage/full_surface"))
sys.path.insert(0, str(REPO / "tools/library_coverage"))
import wprobe as W

OUT = Path(os.environ.get("CQ_DUMP_OUT", "/private/tmp/cq_loop_bounds/cells"))

# cell -> (fn, retW, args)  — the census cell definitions (full_census.py cell_args
# over probe.MATHH_SPEC: ilogb has ret="int" => si32; logb/logbl return their fp width).
CELLS = {
    "ilogb.f64":  ("ilogb",  "si32", [("q", "f64")]),
    "ilogbf.f32": ("ilogbf", "si32", [("q", "f32")]),
    "ilogbl.f80": ("ilogbl", "si32", [("q", "f80")]),
    "logbl.f80":  ("logbl",  "f80",  [("q", "f80")]),
    # controls: the two siblings that COMPILE today
    "logb.f64":   ("logb",   "f64",  [("q", "f64")]),
    "logbf.f32":  ("logbf",  "f32",  [("q", "f32")]),
    # control: the cell the L3 memo's "constant max i32 32" was ACTUALLY measured
    # on (e_fmod.c:54,56). The transfer claim under test is measured against this.
    # 2-arg census convention (bd 3c6m.62): arg1 pinned to the literal 0.5.
    "fmod.f64":   ("fmod",   "f64",  [("q", "f64"), ("c:double:0.5",)]),
    # the memo's TRAP-1 signedness example was measured on the f32 fmod cell
    # ("the formula says 128 while LLVM's own answer on the SAME SCEV is
    # 4294967294"). Included to validate this apparatus against the record.
    "fmodf.f32":  ("fmodf",  "f32",  [("q", "f32"), ("c:float:0.5f",)]),
}


def dump(cell):
    fn, retW, args = CELLS[cell]
    defmap = W.build_defmap()
    src = W.make_src(fn, retW, args, 0)
    td = OUT / cell
    td.mkdir(parents=True, exist_ok=True)
    (td / "probe.c").write_text(src)
    pbc = td / "probe.bc"
    r = subprocess.run([W.CLANG, "-O1", "-g", "-fno-builtin", f"-fno-builtin-{fn}",
                        "-emit-llvm", "-c"] + W.INC.split() +
                       [str(td / "probe.c"), "-o", str(pbc)],
                       capture_output=True, text=True)
    if r.returncode != 0:
        return cell, "build-fail", r.stderr[-300:]
    linked, err = W.closure_link(pbc, defmap, td)
    if linked is None:
        return cell, "link-fail", err
    inl = td / "inl.ll"
    subprocess.run([W.OPT,
                    f"-passes=internalize,always-inline,globaldce,default<{W.CENSUS_OPTLEVEL}>,scalarizer,instcombine,dce",
                    "-internalize-public-api-list=probe", "-inline-threshold=2000000",
                    str(linked), "-S", "-o", str(inl)], capture_output=True, text=True)
    # the cq-lowering run (the census's own status/diag)
    r = subprocess.run([W.OPT, "-load-pass-plugin", str(W.PASS), "-passes=cq-lowering",
                        "-S", str(inl), "-o", str(td / "low.ll")],
                       capture_output=True, text=True)
    (td / "lowering.stderr").write_text(r.stderr)
    status = "lowered-exit0" if r.returncode == 0 else "decline"
    diag = ""
    for line in r.stderr.split("\n"):
        if "error" in line.lower():
            diag = line.strip()[:300]
            break
    return cell, status, diag


if __name__ == "__main__":
    sel = sys.argv[1:] or list(CELLS)
    for c in sel:
        cell, st, diag = dump(c)
        print(f"{cell:12s} {st:14s} {diag}")
