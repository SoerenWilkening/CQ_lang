#!/usr/bin/env python3
# Dump the census-pipeline inlined IR for a probe fn, plus the cq-lowering
# diagnostic with source line. Reuses full_surface/wprobe.py machinery.
import os, sys, subprocess, tempfile
from pathlib import Path

os.environ.setdefault("BC", "/tmp/bc")
os.environ.setdefault("OPENLIBM", "/tmp/openlibm")
sys.path.insert(0, str(Path(__file__).resolve().parent))
import wprobe as W

LLVM = W.LLVM
CLANG, OPT, LINK, DIS = W.CLANG, W.OPT, W.LINK, W.DIS

def dump(fn, retW, args, ti, outdir):
    defmap = W.build_defmap()
    src = W.make_src(fn, retW, args, ti)
    td = Path(outdir); td.mkdir(parents=True, exist_ok=True)
    (td/f"{fn}_probe.c").write_text(src)
    pbc = td/f"{fn}_probe.bc"
    r = subprocess.run([CLANG,"-O1","-g","-fno-builtin",f"-fno-builtin-{fn}",
                        "-emit-llvm","-c"]+W.INC.split()+[str(td/f"{fn}_probe.c"),"-o",str(pbc)],
                       capture_output=True, text=True)
    if r.returncode != 0:
        print("build-fail", r.stderr[-400:]); return
    linked, err = W.closure_link(pbc, defmap, td)
    if linked is None:
        print("link-fail", err); return
    inl = td/f"{fn}_inl.ll"
    subprocess.run([OPT,"-passes=internalize,always-inline,globaldce,default<O2>,scalarizer,instcombine,dce",
                    "-internalize-public-api-list=probe","-inline-threshold=2000000",
                    str(linked),"-S","-o",str(inl)], capture_output=True, text=True)
    print(f"=== inlined IR -> {inl} ===")
    # run cq-lowering to get the diagnostic
    r = subprocess.run([OPT,"-load-pass-plugin",str(W.PASS),"-passes=cq-lowering","-S",str(inl),"-o","/dev/null"],
                       capture_output=True, text=True)
    print("--- cq-lowering stderr ---")
    print(r.stderr[-2000:])

if __name__ == "__main__":
    fn = sys.argv[1]
    specs = {
        "exp2":  ("exp2",  "f64", [("q","f64")], 0),
        "exp":   ("exp",   "f64", [("q","f64")], 0),
        "fmod":  ("fmod",  "f64", [("q","f64"),("q","f64")], 0),
        "rint":  ("rint",  "f64", [("q","f64")], 0),
    }
    dump(*specs[fn], outdir="/tmp/irdump")
