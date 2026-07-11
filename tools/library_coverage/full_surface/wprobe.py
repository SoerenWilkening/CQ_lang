#!/usr/bin/env python3
# Width-parametric injection probe — reuses the census pipeline but supports
# float / long double / by-ref / int-return, which inject_census.py (double-only)
# cannot. For each (fn, ret, args, tainted-width) it: generates a probe.c with the
# right cq_theta_<W>/cq_measure_<W> intrinsics, compiles -fno-builtin[-fn],
# closure-links the REAL openlibm body, inlines to opcodes, runs cq-lowering, and
# captures the actual decline diagnostic. Empirical, real-source (Rule 18).
import os, re, subprocess, sys, tempfile
from pathlib import Path

LLVM = Path("/usr/local/opt/llvm@19/bin")
CLANG, OPT, LINK, DIS = LLVM/"clang", LLVM/"opt", LLVM/"llvm-link", LLVM/"llvm-dis"
HERE = Path(__file__).resolve().parent
# Corpus location — set BC (openlibm bitcode dir) and OPENLIBM (source tree) to
# your scratch build (see README REPRODUCE); defaults to HERE for a self-hosted run.
BC = Path(os.environ.get("BC", HERE/"bc"))
OL = Path(os.environ.get("OPENLIBM", HERE/"openlibm"))
PASS = Path(os.environ.get("CQ_PASS",
            Path(__file__).resolve().parents[3]/"build/ir-pass/libCQPass.so"))
INC = "-I%s -I%s -I%s -I%s" % (OL/"include", OL/"src", OL/"amd64", OL/"bsdsrc")

# width -> (c_type, theta_name, measure_name, theta_zero_literal)
W = {
    "f32": ("float",       "cq_theta_f32", "cq_measure_f32", "0.5f"),
    "f64": ("double",      "cq_theta_f64", "cq_measure_f64", "0.5"),
    "f80": ("long double", "cq_theta_f80", "cq_measure_f80", "0.5L"),
    "sl":  ("long",        "cq_theta_sl",  "cq_measure_sl",  "2"),
    "sll": ("long long",   "cq_theta_sll", "cq_measure_sll", "2"),
}

def build_defmap():
    defmap = {}
    for b in sorted(BC.glob("*.bc")):
        try:
            ir = subprocess.run([DIS, str(b), "-o", "-"], capture_output=True, text=True, timeout=30).stdout
        except Exception:
            continue
        for m in re.finditer(r'^define[^@]*@([A-Za-z0-9_.$]+)\b', ir, re.M):
            defmap.setdefault(m.group(1), []).append(b)
    return defmap

def undefined_syms(bc):
    ir = subprocess.run([DIS, str(bc), "-o", "-"], capture_output=True, text=True).stdout
    decl = set(re.findall(r'^declare[^@]*@([A-Za-z0-9_.$]+)\b', ir, re.M))
    dfn  = set(re.findall(r'^define[^@]*@([A-Za-z0-9_.$]+)\b', ir, re.M))
    return decl - dfn

def closure_link(probe_bc, defmap, wd):
    linkset, seen = [probe_bc], {probe_bc}
    for _ in range(60):
        cur = wd/"cur.bc"
        r = subprocess.run([LINK]+[str(x) for x in linkset]+["-o", str(cur)], capture_output=True, text=True)
        if r.returncode != 0:
            return None, "link-conflict:"+r.stderr.strip().split('\n')[0][:70]
        added = False
        for s in undefined_syms(cur):
            for f in defmap.get(s, []):
                if f not in seen:
                    linkset.append(f); seen.add(f); added = True; break
        if not added:
            return cur, None
    return None, "closure-did-not-converge"

# probe spec: (fn, retW, [ (argkind, width_or_type) ...], tainted_arg_index)
#   argkind: 'q'  -> tainted fp of `width`;  'c:<ctype>:<lit>' -> classical const;
#            'ref:<ctype>' -> by-ref out-param (address of a local)
def make_src(fn, retW, args, ti):
    rc, _, rmeas, _ = W[retW]
    lines_decl, callargs, extras = [], [], []
    seen_w = set([retW])
    for i, a in enumerate(args):
        if a[0] == 'q':
            w = a[1]; ct, th, _, zero = W[w]; seen_w.add(w)
            lines_decl.append(f"  {ct} q{i} = {th}({zero}, 0.5);")
            callargs.append(f"q{i}")
        elif a[0].startswith('c:'):
            _, ct, lit = a[0].split(':'); callargs.append(lit)
        elif a[0].startswith('ref:'):
            ct = a[0].split(':')[1]
            extras.append(f"  {ct} outp{i};")
            callargs.append(f"&outp{i}")
    # prototype: infer from args/ret
    def proto_t(a):
        if a[0]=='q': return W[a[1]][0]
        if a[0].startswith('c:'): return a[0].split(':')[1]
        if a[0].startswith('ref:'): return a[0].split(':')[1]+" *"
        return "double"
    proto = ", ".join(proto_t(a) for a in args)
    # emit theta/measure decls for every width touched
    idecls = []
    for w in seen_w:
        ct, th, meas, _ = W[w]
        idecls.append(f"{ct} {th}({ct}, double);")
        idecls.append(f"{ct} {meas}({ct});")
    idecls = "\n".join(sorted(set(idecls)))
    body_extras = "\n".join(extras)
    decl_block = "\n".join(lines_decl)
    call = f"{fn}(" + ", ".join(callargs) + ")"
    return f'''extern {rc} {fn}({proto});
{idecls}
{rc} probe(void){{
{body_extras}
{decl_block}
  {rc} r = {call};
  return {rmeas}(r);
}}'''

def probe(fn, retW, args, ti, defmap):
    src = make_src(fn, retW, args, ti)
    with tempfile.TemporaryDirectory() as td:
        td = Path(td)
        (td/"probe.c").write_text(src)
        pbc = td/"probe.bc"
        r = subprocess.run([CLANG,"-O1","-g","-fno-builtin",f"-fno-builtin-{fn}",
                            "-emit-llvm","-c"]+INC.split()+[str(td/"probe.c"),"-o",str(pbc)],
                           capture_output=True, text=True)
        if r.returncode != 0:
            return ("build-fail", r.stderr.strip().split('\n')[-1][:80], src)
        linked, err = closure_link(pbc, defmap, td)
        if linked is None:
            return ("link-fail", err, src)
        inl = td/"inl.bc"
        subprocess.run([OPT,"-passes=internalize,always-inline,globaldce,default<O2>,scalarizer,instcombine,dce",
                        "-internalize-public-api-list=probe","-inline-threshold=2000000",
                        str(linked),"-o",str(inl)], capture_output=True, text=True)
        ir = subprocess.run([DIS,str(inl),"-o","-"], capture_output=True, text=True).stdout
        surv = [m for m in re.findall(r'call[^@\n]*@([A-Za-z0-9_.$]+)', ir)
                if not m.startswith("cq_") and not m.startswith("llvm.")]
        fully = len(surv)==0
        r = subprocess.run([OPT,"-load-pass-plugin",str(PASS),"-passes=cq-lowering","-S",str(inl),"-o","/dev/null"],
                           capture_output=True, text=True)
        lowered = (r.returncode==0)
        diag=""
        if not lowered:
            for line in r.stderr.split('\n'):
                if 'error' in line.lower():
                    diag = line.split('in function')[-1][:120]; break
        if lowered and fully: st="COMPILES"
        elif lowered and not fully: st="exit0-uninlined:"+str(sorted(set(surv))[:2])
        else: st="decline"
        return (st, diag.strip() if diag else f"surv:{sorted(set(surv))[:2]}", src)

# ---- Representative sample across the four gap families ----
SAMPLE = [
    # float variants of injected doubles
    ("expf",  "f32", [("q","f32")], 0),
    ("sinf",  "f32", [("q","f32")], 0),
    ("logf",  "f32", [("q","f32")], 0),
    ("cbrtf", "f32", [("q","f32")], 0),
    ("atanf", "f32", [("q","f32")], 0),
    ("powf",  "f32", [("q","f32"),("q","f32")], 0),
    # long double variants
    ("expl",  "f80", [("q","f80")], 0),
    ("sinl",  "f80", [("q","f80")], 0),
    ("logl",  "f80", [("q","f80")], 0),
    # by-ref (double + float)
    ("frexp",  "f64", [("q","f64"),("ref:int",)], 0),
    ("frexpf", "f32", [("q","f32"),("ref:int",)], 0),
    ("modf",   "f64", [("q","f64"),("ref:double",)], 0),
    # integer-return
    ("lround",  "sl",  [("q","f64")], 0),
    ("lroundf", "sl",  [("q","f32")], 0),
    ("llround", "sll", [("q","f64")], 0),
]

if __name__ == "__main__":
    print("building openlibm symbol index...", file=sys.stderr)
    defmap = build_defmap()
    print(f"indexed {len(defmap)} symbols over {len(list(BC.glob('*.bc')))} bc files", file=sys.stderr)
    print(f"{'fn':10s} {'W':4s} {'status':10s} diagnostic")
    print("-"*100)
    for fn, rw, args, ti in SAMPLE:
        st, diag, src = probe(fn, rw, args, ti, defmap)
        short = st if st in ("COMPILES","decline","link-fail","build-fail") else st
        print(f"{fn:10s} {rw:4s} {short:10s} {diag[:80]}")
