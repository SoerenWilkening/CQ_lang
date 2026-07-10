#!/usr/bin/env python3
"""Source-injection census: inject libm bodies, inline to opcodes, run cq-lowering.

Bodies come from TWO corpora, authored-first (L1 spine, bd 3c6m.10): a fn with a
hand-authored BRANCHLESS soft-body in branchless/<fn>.c is measured with THAT body
(recorded as body_source="authored-branchless"); every other fn injects its stock
openlibm body. Both are Rule-18 source injection — real C bodies inlined to stock
opcodes before cq-lowering, never name-recognition.

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
      clang -g -O1 -emit-llvm -c -I openlibm/include -I openlibm/src \
            -I openlibm/amd64 -I openlibm/bsdsrc "$c" -o bc/$(basename ${c%.c}).bc
    done   # ~217/242 compile; arch-asm/dup files fail-skip (expected)
           # `-g` (3c6m.9): line tables so a body blocker's decline diagnostic
           # carries a REAL openlibm !dbg <file>:<line>:<col> (the ticket bridge's
           # "blocking source line"). Metadata-only at -O1 -> scoreboard unchanged.
    BC=<scratch>/bc  python3 inject_census.py                  # -> inject_results.json
    BC=<scratch>/bc  python3 inject_census.py --file-tickets   # + burn declines to bd (3c6m.9)

CAVEATS (same as the manual census): fenv-dependent bodies (nearbyint) and a few
self-referential/link-closure gaps (lgamma, sqrt/scalbn kernels) surface as
"exit0-but-uninlined"/"unknown callee" — harness limitations, not real compiles."""
import os, re, subprocess, sys, json, tempfile, itertools
from pathlib import Path

LLVM = Path("/usr/local/opt/llvm@19/bin")
CLANG, OPT, LINK, DIS = LLVM/"clang", LLVM/"opt", LLVM/"llvm-link", LLVM/"llvm-dis"
HERE = Path(__file__).resolve().parent
BC = Path(os.environ.get("BC", HERE/"bc"))   # openlibm bitcode corpus (built to scratch)
BRANCHLESS = HERE/"branchless"               # L1 (3c6m.10): authored branchless soft-bodies
PASS = Path(__file__).resolve().parents[2]/"build/ir-pass/libCQPass.so"

# L1 spine (3c6m.10): compile the AUTHORED branchless bodies (branchless/<fn>.c),
# indexed BEFORE the openlibm corpus so an authored body SHADOWS the branchy
# openlibm one — per-fn provenance is recorded honestly as `body_source`.
#
# BLANKET `-fno-builtin` on BOTH the bodies AND the probe (3c6m.10 L2-closure).
# The reason is the ERRNO-FREE-LEAF closure hazard: a COMPOUND authored body
# (atan2 -> atan, the L2-closure spine) calls a sibling leaf by its libm name, and
# clang -O1 rewrites an errno-FREE transcendental call (`atan`, total domain, never
# sets errno) into the `@llvm.atan.f64` INTRINSIC — which closure_link cannot
# resolve to branchless/atan.c (that defines `@atan`, not the intrinsic), so atan2
# falsely declined with a surviving `@llvm.atan`. (Errno-SETTING leaves — expm1,
# log1p, sqrt — stay named calls under the default -fmath-errno, which is why the
# tanh->expm1 closure worked plain.) `-fno-builtin` keeps EVERY libm-named leaf a
# named call so closure_link always resolves it. NOTE this REVISES the old
# "bodies MUST compile plain" rule (bd branchless-log-3c6m10 fact #2): that gotcha
# was that a -fno-builtin BODY ("no-builtins" attr) won't inline into a
# `-fno-builtin-<fn>` (targeted) probe because the caller's no-builtin set is not a
# SUPERSET of the callee's. The fix is to make BOTH blanket: probe "no-builtins" is
# then a superset of the body's "no-builtins" (and of an openlibm body's empty set),
# so every body still inlines. `__builtin_*` calls (fabs/sqrt/copysign/memcpy) are
# explicit and unaffected by -fno-builtin, so the hardware keep-set leaves still
# lower. Verified surgical: only the intended fns flip, no other census churn.
def build_authored_bc(workdir):
    out = []
    for c in sorted(BRANCHLESS.glob("*.c")):
        b = workdir/f"branchless_{c.stem}.bc"
        r = subprocess.run([CLANG, "-O1", "-g", "-fno-builtin", "-emit-llvm", "-c",
                            str(c), "-o", str(b)],
                           capture_output=True, text=True)
        if r.returncode == 0:
            out.append(b)
        else:
            print(f"  authored {c.name}: BUILD-FAIL "
                  f"{r.stderr.strip().splitlines()[-1][:80]}", file=sys.stderr)
    return out

# Map: which bc file(s) DEFINE each symbol (built once). `authored` bc files are
# indexed FIRST — closure_link resolves an undefined symbol to the first indexed
# definer, so an authored branchless body wins over the openlibm one (L1 spine).
def build_symbol_index(authored=()):
    defmap = {}   # symbol -> list of bc files defining it
    for b in list(authored) + sorted(BC.glob("*.bc")):
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

# A classical constant literal for each non-tainted probe arg, keyed by C type.
# arg0 is ALWAYS the tainted `double q`; the rest are classical consts of the
# CORRECT type. p119 (3c6m.8): scalbn/ldexp/scalbln take an INT 2nd arg — probing
# it as a double left the call unresolvable (signature mismatch -> the openlibm
# body never links -> a FALSE "unknown callee" decline that masked the real
# blocker). Probe each arg with its true type.
CONST_FOR = {"double": "0.5", "int": "2", "long": "2", "float": "0.5f"}

def run_one(fn, argtypes, defmap, mask=None):
    # `mask` = the set of DOUBLE-arg positions to TAINT this probe (3c6m.48). A
    # multi-arg fn has 2^k-1 non-empty tainted combinations over its k double args,
    # each a DISTINCT lowering path (distinct _hl/_lh/_qq templates + distinct taint
    # propagation) that emits a DIFFERENT unitary — so "COMPILES" must certify ALL of
    # them, not just (arg0-tainted, rest-classical). `mask=None` defaults to the
    # legacy arg0-only shape (the sole tainted double is the FIRST double position),
    # keeping every single-double-arg census entry byte-identical to the pre-3c6m.48
    # snapshot. Each TAINTED double arg gets its OWN cq_theta source (distinct qubits
    # — the general atan2(q0,q1) case, not an aliased single-qubit special case);
    # every untainted arg (a non-masked double, or any int/long) is a classical const.
    dpos = [i for i, t in enumerate(argtypes) if t == "double"]
    if mask is None:
        mask = {dpos[0]}
    with tempfile.TemporaryDirectory() as td:
        td = Path(td)
        # Build the call args + one `double qN = cq_theta_f64(...)` decl per tainted arg.
        decls, callargs, qi = [], [], 0
        for i, t in enumerate(argtypes):
            if t == "double" and i in mask:
                callargs.append(f"q{qi}")
                decls.append(f"    double q{qi} = cq_theta_f64(0.5, 0.5);")
                qi += 1
            else:
                callargs.append(CONST_FOR[t])
        proto_args = ", ".join(argtypes)
        decl_block = "\n".join(decls)
        args = ", ".join(callargs)
        src = f'''extern double {fn}({proto_args});
double cq_theta_f64(double, double);
double cq_measure_f64(double);
double probe(void){{
{decl_block}
    double r = {fn}({args});
    return cq_measure_f64(r);
}}'''
        (td/"probe.c").write_text(src)
        pbc = td/"probe.bc"
        # `-g`: probe.c carries line tables so the decline diagnostic's !dbg
        # `<file>:<line>:<col>` is real for a probe-side blocker. For an openlibm
        # BODY blocker the source line comes from the CORPUS's debug info — build
        # bc/ with `clang -g -O1 …` (see REPRODUCE above) to populate it; without a
        # -g corpus the inlined blocker prints `<unknown>:0:0` (captured honestly by
        # census_to_tickets.py as "no !dbg source location"). `-g` is metadata-only
        # at -O1 and does not perturb codegen / the scoreboard (3c6m.9).
        # `-fno-builtin` (blanket) on the probe too (3c6m.10 L2-closure): required
        # so the probe's "no-builtins" set is a SUPERSET of every authored body's
        # (also built -fno-builtin) — else the O2 inliner refuses to inline the body
        # (InlineCallerSupersetNoBuiltin; see build_authored_bc). Inert for the
        # probe's own IR (it makes exactly one libm call, `fn`, already disabled by
        # `-fno-builtin-{fn}`); it only relaxes the inliner's superset check.
        r = subprocess.run([CLANG, "-O1", "-g", "-fno-builtin", f"-fno-builtin-{fn}",
                            "-emit-llvm", "-c",
                            str(td/"probe.c"), "-o", str(pbc)], capture_output=True, text=True)
        if r.returncode != 0:
            # 3c6m.9: the early-return arity MUST match the 5-tuple normal path —
            # a probe build-fail / link-fail (the docstring's expected fail-skips)
            # would otherwise ValueError-unpack and abort the whole census.
            return ("build-fail", r.stderr.strip().split('\n')[-1][:80], [], "", "")
        linked, err = closure_link(pbc, defmap, td)
        if linked is None:
            return ("link-fail", err, [], "", "")
        inl = td/"inl.bc"
        # p119 (3c6m.8): a `scalarizer` pass AFTER default<O2> de-vectorizes the
        # SLP output (fmuladd.v2f64 / reduce.or) so a surviving <2 x double> op
        # stops MASKING the real blocker as a bogus "unsupported instruction".
        # The p119 blocker-audit proved this RECLASSIFIES (log2/log10 -> nested
        # control flow, erf/erfc -> nested exp() unknown-callee) and COMPILES 0
        # extra functions — it only makes the categorization honest.
        subprocess.run([OPT, "-passes=internalize,always-inline,globaldce,"
                        "default<O2>,scalarizer,instcombine,dce",
                        "-internalize-public-api-list=probe", "-inline-threshold=2000000",
                        str(linked), "-o", str(inl)], capture_output=True, text=True)
        ir = subprocess.run([DIS, str(inl), "-o", "-"], capture_output=True, text=True).stdout
        # surviving non-cq, non-intrinsic call = not fully inlined. `[^@\n]` (3c6m.10):
        # the character class must NOT cross lines — `[^@]*` matched from a "call"
        # inside an ATTRIBUTE COMMENT line (`; ... nocallback nofree ...`) through the
        # newline into the next line's dead `declare @llvm.*`, false-reporting
        # call-site-free declares as survivors (scalarizer leaves the dead declare;
        # dce does not remove declarations).
        surv = [m for m in re.findall(r'call[^@\n]*@([A-Za-z0-9_.$]+)', ir)
                if not m.startswith("cq_") and not m.startswith("llvm.")]
        fully_inlined = len(surv) == 0
        # p119: report the surviving `@llvm.*` intrinsics separately — these are the
        # HARDWARE-BACKED leaves an injected body bottoms out in (sqrt/fabs/copysign/
        # roundsd family/fma/…). They are the ONLY math intrinsics the pass still
        # recognizes (Rule 18); their presence confirms the keep-set empirically
        # under injection. A surviving @llvm.<transcendental> would be a keep-set
        # violation (a transcendental should have inlined to opcodes, not stayed an
        # intrinsic) — flag it.
        surv_llvm = sorted(set(re.findall(r'call[^@\n]*@(llvm\.[A-Za-z0-9_.]+)', ir)))
        r = subprocess.run([OPT, "-load-pass-plugin", str(PASS), "-passes=cq-lowering",
                            "-S", str(inl), "-o", "/dev/null"], capture_output=True, text=True)
        lowered = (r.returncode == 0)
        diag = ""; diag_full = ""; blocking_loc = ""
        if not lowered:
            for line in r.stderr.split('\n'):
                if 'error' in line.lower():
                    diag = line.split('in function')[-1][:90]   # UNCHANGED: keeps
                    # `detail`/lever byte-identical to the pre-3c6m.9 census.
                    # 3c6m.9: ALSO keep the full diagnostic line and parse its !dbg
                    # `<file>:<line>:<col>` (the token between `error: ` and
                    # `: in function`) as the blocking source line for the ticket
                    # bridge. `<unknown>:0:0` (no debug info at all) -> left empty.
                    # 3c6m.10: a body compiled WITHOUT `-g` does not print
                    # `<unknown>` — inlining attaches the PROBE CALL-SITE debugloc
                    # (…/probe.c:6:16) to the inlined blocker, a misleading
                    # "blocking source line". A probe.c loc is kept ONLY when the
                    # body genuinely did not inline (a real probe-side blocker,
                    # e.g. the harness-gap fns); for a FULLY-INLINED body it is
                    # dropped like `<unknown>` (census_to_tickets then honestly
                    # reports "no source location — rebuild the corpus with -g").
                    # Strip the EPHEMERAL probe tempdir prefix (…/T/tmpXXXX/probe.c
                    # -> probe.c) so the committed snapshot is DETERMINISTIC across
                    # census runs (3c6m.10; only the probe lives there — corpus
                    # paths are real and untouched).
                    diag_full = line.strip().replace(str(td) + "/", "")
                    m = re.search(r'error:\s*(.*?):\s*in function', diag_full)
                    if m and not m.group(1).strip().startswith('<unknown>'):
                        loc = m.group(1).strip()
                        if not (fully_inlined and "probe.c" in loc):
                            blocking_loc = loc
                    break
        # census rule: COMPILES iff fully inlined AND cq-lowering exit 0
        if lowered and fully_inlined:
            status = "COMPILES"
        elif lowered and not fully_inlined:
            status = "exit0-but-uninlined"   # meaningless per census
        else:
            status = "decline"
        detail = (diag or f"surviving:{sorted(set(surv))[:3]}").strip()
        return (status, detail, surv_llvm, diag_full, blocking_loc)

def _mask_label(argtypes, mask):
    """A stable per-combination key: 'q' for a tainted double, 'c' for any classical
    operand (an untainted double OR an int/long that can never be tainted). E.g. for
    atan2(double,double): 'qc' (arg0 tainted) / 'cq' (arg1 tainted) / 'qq' (both)."""
    return "".join("q" if (t == "double" and i in mask) else "c"
                   for i, t in enumerate(argtypes))

def run_fn(fn, argtypes, defmap):
    """3c6m.48: probe EVERY non-empty tainted-double combination and aggregate honestly.
    Returns the same 5-tuple as run_one PLUS a `combinations` dict {label: 5-tuple}
    (None for a single-double-arg fn — its lone mask IS run_one, so no extra field is
    emitted and its census entry stays byte-identical to the pre-3c6m.48 snapshot).

    AGGREGATION (Prime Directive, scoreboard honesty bd libm-scoreboard-two-numbers):
    a multi-arg fn is COMPILES *only if EVERY* combination COMPILES — each taint mask
    is a distinct unitary, so certifying one (the weakest, arg0-only, where classical
    consts const-fold body logic) never certifies the rest. If ANY combination is not
    COMPILES, the fn reports that combination's (decline) verdict — never a silent
    'COMPILES' that hides an unlowered mask. Every accepted combination must still be
    Rule-13-cleared separately (the emitted unitary differs per mask)."""
    dpos = [i for i, t in enumerate(argtypes) if t == "double"]
    if len(dpos) <= 1:                       # single tainted-double surface: legacy path
        return run_one(fn, argtypes, defmap) + (None,)
    masks = [set(m) for k in range(1, len(dpos) + 1)
             for m in itertools.combinations(dpos, k)]
    combos = {_mask_label(argtypes, m): run_one(fn, argtypes, defmap, mask=m) for m in masks}
    # COMPILES iff all masks COMPILE; surviving_llvm = union across masks. Otherwise
    # surface the FIRST non-COMPILES combination's verdict (a definite loud outcome).
    if all(v[0] == "COMPILES" for v in combos.values()):
        surv_union = sorted({s for v in combos.values() for s in v[2]})
        return ("COMPILES", "surviving:[] (all %d taint masks)" % len(combos),
                surv_union, "", "", combos)
    fail_label, fail = next((l, v) for l, v in combos.items() if v[0] != "COMPILES")
    st, detail, surv_llvm, diag_full, blocking_loc = fail
    return (st, f"[mask {fail_label}] {detail}", surv_llvm, diag_full, blocking_loc, combos)

# The census's double functions (INJECTION-CENSUS.md). Each maps to its C arg-type
# list. 3c6m.48: every DOUBLE arg is a maskable taint position — run_fn probes all
# 2^k-1 non-empty tainted-double combinations and a fn is COMPILES only if ALL of them
# are (single-double-arg fns keep the legacy arg0-only mask). Int/long args are never
# tainted (cq_theta_f64 only makes doubles). p119 note: the f/l variants (sinf/sinl/…)
# inject IDENTICALLY (same body shape, same blockers), so this double set is
# representative of the full ~174 surface for the injection question.
#
# COMMITTED-SNAPSHOT NOTE (3c6m.48): a full run here needs the openlibm bitcode corpus
# ($BC); without it the multi-double DECLINERS resolve as "unknown callee" instead of
# their real body blockers, so the committed inject_results.json splices the per-mask
# `combinations` for `atan2` ONLY (the sole COMPILES multi-arg, re-measured on this box).
# The multi-double decliner entries keep pre-3c6m.48 single-line formatting until the
# next full corpus run repopulates them — a formatting lag with NO scoreboard impact
# (they stay declines). See INJECTION-CENSUS.md "Methodology 2026-07-10 (3c6m.48 …)".
FUNCS = {  # fn: [C arg types]  (arg0 tainted by default; all doubles are maskable)
 "fabs":["double"], "nearbyint":["double"], "copysign":["double","double"],
 "sqrt":["double"], "fma":["double","double","double"],
 "sin":["double"],"cos":["double"],"tan":["double"],"exp":["double"],"exp2":["double"],
 "log":["double"],"log2":["double"],"log10":["double"],
 "asin":["double"],"acos":["double"],"atan":["double"],"sinh":["double"],"cosh":["double"],
 "tanh":["double"],"asinh":["double"],"acosh":["double"],"atanh":["double"],
 "expm1":["double"],"log1p":["double"],"logb":["double"],"cbrt":["double"],
 "floor":["double"],"trunc":["double"],"round":["double"],"ceil":["double"],"rint":["double"],
 "atan2":["double","double"],"pow":["double","double"],"remainder":["double","double"],
 "fdim":["double","double"],"hypot":["double","double"],"fmod":["double","double"],
 "fmax":["double","double"],"fmin":["double","double"],"nextafter":["double","double"],
 # p119 (3c6m.8): 2nd arg is INT/long, NOT double — probing it as double left the
 # openlibm body unresolvable (signature mismatch -> false "unknown callee").
 "scalbn":["double","int"],"ldexp":["double","int"],"scalbln":["double","long"],
 "erf":["double"],"erfc":["double"],"lgamma":["double"],"tgamma":["double"],
}

# ── The hardware-backed RECOGNITION keep-set (Rule 18 / bd libm-scoreboard-two-numbers).
# These lower by RECOGNITION (probe.py's codegen path) — they codegen to a HW instr
# and have NO injectable transcendental body, so they are NOT injection candidates.
# Their soft-body injection decline is MOOT (covered by recognition). Reported as a
# SEPARATE, DISJOINT scoreboard from the injection number (owner, emphatic 2026-07-09).
HARDWARE_KEPT_CORE = {"sqrt","fma","floor","trunc","round","ceil","rint",
                      "nearbyint","fmax","fmin"}
# fabs/copysign are ALSO hardware-kept (@llvm.fabs/@llvm.copysign). They "COMPILE" in
# the raw census ONLY because clang -O1 folds their bit-tricks to those recognized
# intrinsics — they never exercise a raw injected opcode (bd
# p119-phase1-bitcast-masked-blocker). Under the DISJOINT two-scoreboard rule they
# belong to RECOGNITION, making the honest GENUINE-injection count 0 today.
#   True  (recommended, honest-disjoint): fabs/copysign = recognition -> injection genuine = 0.
#   False: fabs/copysign = injection COMPILES = 2 (overlaps recognition; needs a footnote).
# NOTE: this toggle is the ONLY thing gated on the owner's pending 0-vs-2 call (3c6m.8);
# everything else in this census is decision-independent. Default = honest disjoint.
BITOPS_ARE_RECOGNITION = True
HARDWARE_KEPT = HARDWARE_KEPT_CORE | ({"fabs","copysign"}
                                      if BITOPS_ARE_RECOGNITION else set())

# Harness link-gaps found by the p119 blocker-audit — NOT real blockers, so excluded
# from the genuine-injection decline tally (they cannot be honestly measured here):
#  tgamma: openlibm ships no double body (only s_tgammaf.c);
#  lgamma: wrapper link-closure gap;
#  ldexp:  an ASM-level alias `.set ldexp, scalbn` (module asm, invisible to llvm-link) —
#          it has no distinct @ldexp IR body, so it cannot link. Its TRUE injection
#          result is identical to scalbn (L4 control flow); the int-arg fix is validated
#          by scalbn + scalbln, which do resolve and reclassify.
HARNESS_GAP = {"tgamma": "openlibm ships no double tgamma body (only s_tgammaf.c)",
               "lgamma": "lgamma wrapper link-closure gap",
               "ldexp":  "asm alias '.set ldexp, scalbn' — no distinct IR body; == scalbn (L4)"}

def lever_of(detail):
    """Map a genuine-injection decline reason to its campaign lever (bd libm-campaign-pivot)."""
    d = (detail or "").lower()
    if "stored to memory" in d:            return "L5-shadow"       # tainted scratch store
    if "unsupported instruction" in d:     return "L5-qrom"         # tainted-index table read
    if "unknown callee" in d:              return "L2-closure"      # nested transcendental
    if "nested control flow" in d:         return "L6-nested-ctrl"  # multi-level range-reduction br
    if "control flow" in d:                return "L4-fp-select"    # single-level select/diamond
    if "no template for opcode" in d:      return "opcode-gap"      # would be a real gap (none expected)
    return "other"

def bucket_of(fn):
    if fn in HARDWARE_KEPT: return "moot-hardware-kept"
    if fn in HARNESS_GAP:   return "harness-gap"
    return "injection"

if __name__ == "__main__":
    # L1 (3c6m.10): the authored-body scratch must outlive the whole census loop —
    # defmap holds paths into it.
    authored_td = tempfile.TemporaryDirectory()
    authored = build_authored_bc(Path(authored_td.name))
    authored_set = set(authored)
    print(f"authored branchless bodies: {[b.stem.replace('branchless_','') for b in authored]}",
          file=sys.stderr)
    print("building symbol index...", file=sys.stderr)
    defmap = build_symbol_index(authored)
    print(f"indexed {len(defmap)} symbols across branchless/ + bc/", file=sys.stderr)
    results = {}
    for fn, argtypes in FUNCS.items():
        # 3c6m.48: run_fn probes EVERY tainted-double combination; `combinations` is a
        # per-mask {label: 5-tuple} for multi-double-arg fns (None otherwise — those
        # stay single-mask and byte-identical). status is COMPILES only if ALL masks are.
        status, detail, surv_llvm, diag_full, blocking_loc, combinations = run_fn(fn, argtypes, defmap)
        bucket = bucket_of(fn)
        lever = lever_of(detail) if (bucket == "injection" and status == "decline") else ""
        if bucket == "harness-gap":
            detail = f"{HARNESS_GAP[fn]} [{detail}]"
        # Body PROVENANCE (two-scoreboard honesty): closure_link resolves `fn` to the
        # FIRST indexed definer, so defmap[fn][0] names the body actually injected —
        # "authored-branchless" (the L1 corpus) vs "openlibm".
        definer = defmap.get(fn, [None])[0]
        body_source = ("authored-branchless" if definer in authored_set
                       else "openlibm" if definer is not None else "")
        results[fn] = {"status": status, "detail": detail, "surviving_llvm": surv_llvm,
                       "bucket": bucket, "lever": lever, "body_source": body_source,
                       # 3c6m.9 ticket-bridge fields: the full diagnostic line + its
                       # parsed !dbg source location (empty when the corpus lacks -g).
                       "diag_full": diag_full, "blocking_loc": blocking_loc}
        if combinations is not None:
            # 3c6m.48 per-combination breakdown (only for multi-double-arg fns): each
            # taint mask's own verdict, so a fn's "COMPILES" is auditably ALL-masks.
            results[fn]["combinations"] = {
                lbl: {"status": v[0], "detail": v[1], "surviving_llvm": v[2],
                      "blocking_loc": v[4]}
                for lbl, v in combinations.items()}
        note = f"  [llvm survivors: {surv_llvm}]" if surv_llvm else ""
        src = f" ⟪{body_source}⟫" if body_source == "authored-branchless" else ""
        tag = f" ⟨{bucket}{('/'+lever) if lever else ''}⟩"
        print(f"  {fn:12s} {status:22s}{tag}{src}  {detail}{note}", file=sys.stderr)
    Path("inject_results.json").write_text(json.dumps(results, indent=2))

    # ── TWO DISJOINT SCOREBOARDS (owner, emphatic 2026-07-09; bd libm-scoreboard-two-numbers).
    # NEVER a merged headline. (1) INJECTION = genuine library bodies that COMPILE here.
    # (2) RECOGNITION = the hardware keep-set (measured by probe.py, not this census) —
    # shown here only for disjointness bookkeeping; it is a FIXED FLOOR, not injection progress.
    from collections import Counter
    inj = {fn: r for fn, r in results.items() if r["bucket"] == "injection"}
    inj_compiles = sorted(fn for fn, r in inj.items() if r["status"] == "COMPILES")
    print("\n" + "=" * 68, file=sys.stderr)
    print("SCOREBOARD 1 — INJECTION-covered (genuine library bodies; the campaign number)",
          file=sys.stderr)
    print(f"  {len(inj_compiles)}/{len(inj)} COMPILE  (fully inlined + cq-lowering exit 0)",
          file=sys.stderr)
    print(f"  COMPILES: {inj_compiles or '(none — honest floor)'}", file=sys.stderr)
    print("SCOREBOARD 2 — RECOGNITION-covered (hardware keep-set; DISJOINT, fixed floor)",
          file=sys.stderr)
    print(f"  {len(HARDWARE_KEPT)} stems in this census, moot for injection: "
          f"{sorted(HARDWARE_KEPT)}", file=sys.stderr)
    print("  (recognition's TRUE coverage number is probe.py's, not measured here)",
          file=sys.stderr)
    print("=" * 68, file=sys.stderr)

    print("\n=== INJECTION declines by lever (3c6m.9 ticket feed) ===", file=sys.stderr)
    lev = Counter(r["lever"] for r in inj.values() if r["status"] == "decline")
    levers = {}
    for k, v in lev.most_common():
        fns = sorted(fn for fn, r in inj.items()
                     if r["status"] == "decline" and r["lever"] == k)
        levers[k] = fns
        print(f"  {k:16s} {v:2d}  {fns}", file=sys.stderr)

    # ── The committed, machine-readable INJECTION scoreboard. probe.py reads this to
    # print the injection number DISJOINT from its own recognition number (the
    # two-scoreboard rule; bd libm-scoreboard-two-numbers) — keeping the two artifacts
    # in sync without probe.py having to re-run the (corpus-dependent) census.
    Path("injection_summary.json").write_text(json.dumps({
        "injection_compiles": len(inj_compiles),
        "injection_candidates": len(inj),
        "injection_compiles_fns": inj_compiles,
        # L1 (3c6m.10) provenance: which of the compiling fns rode an AUTHORED
        # branchless body (vs stock openlibm). Kept visible so the injection number
        # can never silently morph into an "openlibm compiles" claim.
        "authored_branchless_fns": sorted(
            fn for fn in inj_compiles
            if inj[fn].get("body_source") == "authored-branchless"),
        "declines_by_lever": levers,
        "hardware_kept_stems": sorted(HARDWARE_KEPT),
        "harness_gap": sorted(HARNESS_GAP),
        "bitops_are_recognition": BITOPS_ARE_RECOGNITION,
        "note": "Injection-covered = genuine library bodies (source injection, Rule 18); "
                "DISJOINT from recognition-covered (hardware keep-set, measured by probe.py). "
                "Bodies are openlibm's, except authored_branchless_fns: hand-authored "
                "branchless soft-bodies (tools/library_coverage/branchless/, bd 3c6m.10 L1).",
    }, indent=2))

    print("\n=== per-bucket status tally ===", file=sys.stderr)
    for b in ("injection", "moot-hardware-kept", "harness-gap"):
        c = Counter(r["status"] for r in results.values() if r["bucket"] == b)
        print(f"  [{b}] " + ", ".join(f"{k}:{v}" for k, v in c.most_common()),
              file=sys.stderr)

    # p119: which functions leave a surviving @llvm.* intrinsic (the hardware-backed
    # keep-set, confirmed under injection). A transcendental appearing here would be
    # a keep-set violation (it should inline to opcodes).
    surv = {fn: r["surviving_llvm"] for fn, r in results.items() if r["surviving_llvm"]}
    print(f"\n=== SURVIVING @llvm.* (hardware keep-set under injection) ===", file=sys.stderr)
    for fn, s in surv.items(): print(f"  {fn:12s} {s}", file=sys.stderr)

    # 3c6m.9 — the census→tickets bridge. `--file-tickets` burns every genuine-
    # injection decline into a bd work-queue ticket (owner rule: a decline BECOMES A
    # BUG TICKET). Off by default so a plain census run stays read-only (writes only
    # the JSON scoreboards); opt in explicitly to mutate the tracker.
    if "--file-tickets" in sys.argv:
        print("\n=== filing/refreshing bd tickets (3c6m.9 bridge) ===", file=sys.stderr)
        subprocess.run([sys.executable, str(HERE / "census_to_tickets.py"), "--apply"])
