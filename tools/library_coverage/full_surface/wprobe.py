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
# Inline-cleanup opt level for the post-link harness pass. DEFAULT O2 (the
# historical census headline). Set CENSUS_OPTLEVEL=O1 to measure at the actual
# ship floor (`clang -O1 -> cq-lowering`, no extra opt): for ld80 cells the O2
# cleanup instcombine/simplifycfg-threads the isnan/exponent nest into a control
# shape PredMux declines, so O2 UNDER-counts the -O1-favored long-double half
# (README CENSUS METHODOLOGY; bd 3c6m.51 Inc-1 note). O0 is invalid (mem2reg
# must run). Only O1/O2/O3/Os/Oz are accepted.
CENSUS_OPTLEVEL = os.environ.get("CENSUS_OPTLEVEL", "O2")
assert CENSUS_OPTLEVEL in ("O1","O2","O3","Os","Oz"), CENSUS_OPTLEVEL
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

# bd 20xt (2026-07-18): the closure resolves DATA symbols too, not just
# functions. ld80 atanl/asinl/acosl keep their coefficient tables in a
# data-only TU (ld80/invtrig.c: _ItL_atanhi/_ItL_atanlo/_ItL_aT/_ItL_pi_lo);
# a function-only closure left them `external [0 x x86_fp80]` with NO
# initializer, so the harness O1 cleanup could not const-fold the
# constant-address coefficient reads and the pass could not classify the
# tainted-index reads (matchQramAccess requires isConstant+hasInitializer+N>0)
# — the census then reported a fake first blocker (spec-scan "memory access")
# and MASKED the real one. Under-linking under-measures (Rule 18: a library
# function means its SOURCE, injected — the tables ARE the source).
def build_defmap():
    defmap = {}
    for b in sorted(BC.glob("*.bc")):
        try:
            ir = subprocess.run([DIS, str(b), "-o", "-"], capture_output=True, text=True, timeout=30).stdout
        except Exception:
            continue
        for m in re.finditer(r'^define[^@]*@([A-Za-z0-9_.$]+)\b', ir, re.M):
            defmap.setdefault(m.group(1), []).append(b)
        # data definitions: '@sym = <qualifiers> (global|constant) ...' with no
        # 'external' qualifier before the global/constant keyword.
        for m in re.finditer(r'^@([A-Za-z0-9_.$]+) = ([^\n]*)', ir, re.M):
            sym, rest = m.group(1), m.group(2)
            if 'external' not in rest.split('constant')[0].split('global')[0]:
                defmap.setdefault(sym, []).append(b)
    return defmap

def undefined_syms(bc):
    ir = subprocess.run([DIS, str(bc), "-o", "-"], capture_output=True, text=True).stdout
    decl = set(re.findall(r'^declare[^@]*@([A-Za-z0-9_.$]+)\b', ir, re.M))
    dfn  = set(re.findall(r'^define[^@]*@([A-Za-z0-9_.$]+)\b', ir, re.M))
    # undefined data: '@sym = external ...' (a global declaration)
    gdecl = set(m.group(1) for m in re.finditer(r'^@([A-Za-z0-9_.$]+) = external', ir, re.M))
    gdfn  = set(m.group(1) for m in re.finditer(r'^@([A-Za-z0-9_.$]+) = (?!external)', ir, re.M))
    return (decl - dfn) | (gdecl - gdfn)

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
        subprocess.run([OPT,f"-passes=internalize,always-inline,globaldce,default<{CENSUS_OPTLEVEL}>,scalarizer,instcombine,dce",
                        "-internalize-public-api-list=probe","-inline-threshold=2000000",
                        str(linked),"-o",str(inl)], capture_output=True, text=True)
        ir = subprocess.run([DIS,str(inl),"-o","-"], capture_output=True, text=True).stdout
        surv = [m for m in re.findall(r'call[^@\n]*@([A-Za-z0-9_.$]+)', ir)
                if not m.startswith("cq_") and not m.startswith("llvm.")]
        fully = len(surv)==0
        low = td/"low.ll"
        r = subprocess.run([OPT,"-load-pass-plugin",str(PASS),"-passes=cq-lowering","-S",str(inl),"-o",str(low)],
                           capture_output=True, text=True)
        lowered = (r.returncode==0)
        diag=""
        if not lowered:
            for line in r.stderr.split('\n'):
                if 'error' in line.lower():
                    diag = line.split('in function')[-1][:120]; break
        if lowered and fully: st="COMPILES"
        elif lowered and not fully:
            # bd adia: a surviving pre-lowering callee may be HANDLED by
            # Phase-6 clone-on-taint rather than inlining — the LOWERED output
            # then retargets every call to a @__cq_q_* clone (which itself
            # lowered: opt exited 0) and no raw call to the survivor remains
            # reachable from @probe. Report that as its own honest bucket
            # ("COMPILES (spec-clone)"), NEVER merged into plain COMPILES
            # (the two-numbers scoreboard discipline).
            lowir = low.read_text() if low.exists() else ""
            spec_handled = False
            if "@__cq_q_" in lowir:
                raw = [m for m in re.findall(r'call[^@\n]*@([A-Za-z0-9_.$]+)', lowir)
                       if m in set(surv)]
                spec_handled = len(raw) == 0
            st = ("exit0-spec:"+str(sorted(set(surv))[:2])) if spec_handled \
                 else "exit0-uninlined:"+str(sorted(set(surv))[:2])
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
