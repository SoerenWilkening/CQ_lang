#!/usr/bin/env python3
# Batch-generate census-pipeline inlined IR for a list of (fn,retW,args) probes,
# building the openlibm defmap ONCE. Saves each inlined .ll to /tmp/irdump/.
import os, sys, subprocess
from pathlib import Path
os.environ.setdefault("BC", "/tmp/bc")
os.environ.setdefault("OPENLIBM", "/tmp/openlibm")
sys.path.insert(0, str(Path(__file__).resolve().parent))
import wprobe as W

OUT = Path("/tmp/irdump"); OUT.mkdir(exist_ok=True)
# the 18-cell "unsupported instruction" cluster + representatives
PROBES = [
    ("exp",   "f64", [("q","f64")]),
    ("exp2",  "f64", [("q","f64")]),
    ("expf",  "f32", [("q","f32")]),
    ("exp2f", "f32", [("q","f32")]),
    ("cosh",  "f64", [("q","f64")]),
    ("sinh",  "f64", [("q","f64")]),
    ("coshf", "f32", [("q","f32")]),
    ("sinhf", "f32", [("q","f32")]),
    ("erf",   "f64", [("q","f64")]),
    ("erfc",  "f64", [("q","f64")]),
    ("erff",  "f32", [("q","f32")]),
    ("erfcf", "f32", [("q","f32")]),
    ("fmod",  "f64", [("q","f64"),("q","f64")]),
    ("fmodf", "f32", [("q","f32"),("q","f32")]),
    ("remainder",  "f64", [("q","f64"),("q","f64")]),
    ("remainderf", "f32", [("q","f32"),("q","f32")]),
]

def gen(fn, rw, args, defmap):
    import tempfile
    src = W.make_src(fn, rw, args, 0)
    with tempfile.TemporaryDirectory() as td:
        td = Path(td)
        (td/"probe.c").write_text(src)
        pbc = td/"probe.bc"
        r = subprocess.run([W.CLANG,"-O1","-g","-fno-builtin",f"-fno-builtin-{fn}",
                            "-emit-llvm","-c"]+W.INC.split()+[str(td/"probe.c"),"-o",str(pbc)],
                           capture_output=True, text=True)
        if r.returncode != 0:
            return f"build-fail: {r.stderr.strip().splitlines()[-1][:60]}"
        linked, err = W.closure_link(pbc, defmap, td)
        if linked is None:
            return f"link-fail: {err}"
        inl = OUT/f"{fn}_inl.ll"
        subprocess.run([W.OPT,"-passes=internalize,always-inline,globaldce,default<O2>,scalarizer,instcombine,dce",
                        "-internalize-public-api-list=probe","-inline-threshold=2000000",
                        str(linked),"-S","-o",str(inl)], capture_output=True, text=True)
        return f"ok -> {inl}"

if __name__ == "__main__":
    print("building defmap...", file=sys.stderr)
    defmap = W.build_defmap()
    print(f"indexed {len(defmap)} symbols", file=sys.stderr)
    for fn, rw, args in PROBES:
        print(f"{fn:12s} {gen(fn, rw, args, defmap)}")
