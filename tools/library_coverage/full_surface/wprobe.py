#!/usr/bin/env python3
# Width-parametric injection probe — reuses the census pipeline but supports
# float / long double / by-ref / int-return, which inject_census.py (double-only)
# cannot. For each (fn, ret, args, tainted-width) it: generates a probe.c with the
# right cq_theta_<W>/cq_measure_<W> intrinsics, compiles -fno-builtin[-fn],
# closure-links the REAL openlibm body, inlines to opcodes, runs cq-lowering, and
# captures the actual decline diagnostic. Empirical, real-source (Rule 18).
import os, re, subprocess, sys, tempfile
from pathlib import Path

# CQ_LLVM_BIN: the build passes its configured LLVM (tools/libm_bundle.py).
LLVM = Path(os.environ.get("CQ_LLVM_BIN", "/usr/local/opt/llvm@19/bin"))
CLANG, OPT, LINK, DIS = LLVM/"clang", LLVM/"opt", LLVM/"llvm-link", LLVM/"llvm-dis"
AS = LLVM/"llvm-as"   # bd vuy6: assemble the synthesized .set-alias forwarding shims
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
# `si32` is the RETURN width of the one int-returning math.h FUNCTION, `ilogb`
# (bd bcv4). Every other int-return row in probe.MATHH_SPEC is a macro and is
# filtered before it reaches here, which is exactly how ilogb's 3 cells stayed
# unprobed — and were then read as failures — for the whole campaign. The
# spelling is CQ.h's `_Generic` row for plain `int` (include/CQ.h:124/164), not
# a name invented here.
W = {
    "f32":  ("float",       "cq_theta_f32",   "cq_measure_f32",   "0.5f"),
    "f64":  ("double",      "cq_theta_f64",   "cq_measure_f64",   "0.5"),
    "f80":  ("long double", "cq_theta_f80",   "cq_measure_f80",   "0.5L"),
    "si32": ("int",         "cq_theta_si32",  "cq_measure_si32",  "2"),
    "sl":   ("long",        "cq_theta_sl",    "cq_measure_sl",    "2"),
    "sll":  ("long long",   "cq_theta_sll",   "cq_measure_sll",   "2"),
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
# bd vuy6 (2026-07-25): module-asm '.set alias, definer' strong_reference support.
# openlibm ships some public names ONLY as an assembler alias — e.g. s_scalbnl.c's
# `openlibm_strong_reference(scalbnl, ldexpl)` survives in the bitcode as
#   module asm ".set ldexpl, scalbnl"
# and NOTHING else. llvm-link/opt treat module asm as opaque text, so `ldexpl`
# never acquires an IR body: a caller's `call @ldexpl` survives inlining as an
# "unknown callee", which MASKS the cell's real first blocker (log10l.f80 declined
# at the ldexpl site e_log10l.c:177 instead of its true __isnanl early-exit). The
# durable fix (survives every corpus reclone, and closes EVERY strong_reference at
# once — the README Step-1b hand shims did not persist) is to SYNTHESIZE, per pair,
# the exact forwarding thunk clang emits for `T alias(...){ return definer(...); }`
# and register it in the defmap so the closure links + inlines it like a real body.
_ALIAS_SHIM_DIR = None
def _alias_shim_dir():
    global _ALIAS_SHIM_DIR
    if _ALIAS_SHIM_DIR is None:
        _ALIAS_SHIM_DIR = Path(tempfile.mkdtemp(prefix="cq_alias_shims_"))
    return _ALIAS_SHIM_DIR

# ---------------------------------------------------------------------------
# bd 3c6m.60 (2026-07-25): HARDWARE KEEP-SET SHIMS — the census must see, for an
# INNER keep-set call, the construct the SHIP FLOOR sees.
#
# THE BUG THIS FIXES. The corpus recipe (README "Reproduce" step 1) builds every
# openlibm .c with a BLANKET `-fno-builtin`, so `sqrt`/`floor`/`fabs`/… resolve to
# openlibm's SOFTWARE bodies and the closure links them in. But Rule 18's
# hardware KEEP-SET says those names are *not* library functions on this target:
# at the real ship floor (`clang -O1`, builtins ON — `tests/e2e/run_slice.sh`)
# clang folds each of them to an `@llvm.<fn>` intrinsic BEFORE codegen, and
# cq-lowering recognizes it (`IntrinsicLowering.cpp` `isCuratedFpIntrinsic` +
# `isCrossWidthLibmIntrinsic`). So the census was measuring a program the ship
# floor never compiles: `e_acos.c` has ZERO loops, yet `acos.f64` declined on
# "loop under quantum control" — the subnormal normalize loop of the *injected*
# software `__ieee754_sqrt` (`src/e_sqrt.c:118`). Rule 18 itself specifies a
# per-function `-fno-builtin-<fn>` ON THE CALLER, never a blanket flag on the
# corpus; probe.py already SKIPS the keep-set as census CELLS ("recognition-
# covered, no injectable body") while the corpus was injecting their bodies
# INSIDE every other cell — self-inconsistent.
#
# THE FIX (harness only — no compiler change). Register, at the FRONT of the
# defmap, a forwarding shim per keep name that clang itself compiles, so the
# closure resolves e.g. `sqrt` to `@llvm.sqrt.f64` instead of the soft body.
# Same mechanism as the vuy6 `.set`-alias shims above, and reclone-proof.
#
# FAITHFULNESS (Rule 11 — measure, never guess). The shim body is not authored:
# it is whatever `clang -O1` (builtins ON, i.e. ship-floor conditions) emits for
# `T s(T x){ return <name>(x); }`. If that output still contains a NON-intrinsic
# call — i.e. clang emits a libcall for this name/width on this target, so the
# name is NOT a keep here — we DECLINE to shim and the soft body keeps winning,
# exactly as before (a wrong shim would make the census over-report, which is the
# one unforgivable direction). Measured on this host (LLVM 19, x86-64+SSE4.1):
# all 14 stems × {f,,l} fold, with the C99 spellings mapping to
# minnum/maxnum (fmin/fmax) and to `@llvm.{l,ll}rint.i64.f<W>`.
HARDWARE_KEEPS = ("sqrt fabs copysign floor ceil trunc round rint nearbyint "
                  "fmin fmax fma lrint llrint").split()   # == probe.HARDWARE_KEEP_SET
_KEEP_NARGS = {"copysign": 2, "fmin": 2, "fmax": 2, "fma": 3}
_KEEP_RET   = {"lrint": "long", "llrint": "long long"}    # cross-width fp->int
_KEEP_VARIANTS = (("f", "float"), ("", "double"), ("l", "long double"))
_KEEP_SHIM_DIR = None
_KEEP_SHIMS = None      # name -> .bc path  (built once, memoized)
_KEEP_SKIPPED = []      # names that did NOT fold at -O1 (no shim; soft body wins)

def _keep_shim_dir():
    global _KEEP_SHIM_DIR
    if _KEEP_SHIM_DIR is None:
        _KEEP_SHIM_DIR = Path(tempfile.mkdtemp(prefix="cq_keep_shims_"))
    return _KEEP_SHIM_DIR

def _synth_keep_shim(name, ret, ctype, nargs, outdir):
    """Compile `<ret> __cq_keep_shim(<ctype> a0, …) { return <name>(a0, …); }` at
    clang -O1 with builtins ON (ship-floor conditions), then rename the definition
    to @<name>. Returns the .bc path, or None if the call did NOT fold to an
    intrinsic (then this name is a real libcall here and must keep its soft body).
    """
    params = ", ".join("%s a%d" % (ctype, i) for i in range(nargs))
    args   = ", ".join("a%d" % i for i in range(nargs))
    src = ('#include <math.h>\n'
           '__attribute__((always_inline)) %s __cq_keep_shim(%s) { return %s(%s); }\n'
           % (ret, params, name, args))
    c  = outdir / ("_keep_%s.c"  % name)
    ll = outdir / ("_keep_%s.ll" % name)
    bc = outdir / ("_keep_%s.bc" % name)
    c.write_text(src)
    # NO -fno-builtin here: folding the named call to its in-grid construct is the
    # entire point, and it is exactly what the ship floor does.
    r = subprocess.run([CLANG, "-O1", "-emit-llvm", "-S", str(c), "-o", str(ll)],
                       capture_output=True, text=True)
    if r.returncode != 0:
        return None
    ir = ll.read_text()
    m = re.search(r'^define[^@\n]*@__cq_keep_shim\(.*?\n\}', ir, re.M | re.S)
    if m is None:
        return None
    # Any surviving non-intrinsic callee means clang did NOT fold => not a keep on
    # this target/width => decline to shim (renaming would also self-recurse).
    if [x for x in re.findall(r'call[^@\n]*@([A-Za-z0-9_.$]+)', m.group(0))
        if not x.startswith("llvm.")]:
        return None
    ll.write_text(ir.replace("@__cq_keep_shim", "@" + name))
    r = subprocess.run([AS, str(ll), "-o", str(bc)], capture_output=True, text=True)
    return bc if r.returncode == 0 else None

def keep_shims():
    """name -> forwarding-shim .bc for every hardware-keep-set name that folds."""
    global _KEEP_SHIMS
    if _KEEP_SHIMS is not None:
        return _KEEP_SHIMS
    _KEEP_SHIMS = {}
    outdir = _keep_shim_dir()
    for stem in HARDWARE_KEEPS:
        for suf, ctype in _KEEP_VARIANTS:
            name = stem + suf
            ret  = _KEEP_RET.get(stem, ctype)
            bc = _synth_keep_shim(name, ret, ctype, _KEEP_NARGS.get(stem, 1), outdir)
            if bc is None:
                _KEEP_SKIPPED.append(name)
            else:
                _KEEP_SHIMS[name] = bc
    return _KEEP_SHIMS

# ---------------------------------------------------------------------------
# bd guwr (2026-07-31): CQ-PROVIDED LEAF INJECTION — the Rule 18 AMENDMENT.
#
# For an owner-ruled, condition-(ii)-verified spelling, the pipeline injects CQ's
# OWN reversible leaf (`tools/library_coverage/branchless/<spelling>.c`) INSTEAD
# OF upstream openlibm's body. Structurally this is the SAME MOVE as
# `keep_shims()` above — a defmap registration that changes WHICH SOURCE resolves
# a name — and that identity is the whole argument for it: the hardware keep-set
# is already never injected, and an injected body that CALLS a keep-set fn still
# counts as injection-covered (which is exactly why `ceil` does not block
# `tgamma`). Rule 18's two conditions are independent; for the trig family only
# condition (1) fails, while Bennett backs sin/cos/tan with a CONCRETE BRANCHLESS
# gate sequence (rev e15ea23, fsin.jl:468/683/739, ftan.jl:200) so condition (2)
# holds robustly. What is ruled out is openlibm's SOURCE FORM (k_rem_pio2.c's
# nested data-dependent-trip loops), never the function.
#
# *** TWO THINGS THIS IS NOT. *** It is NOT a name recognizer — Rule 18 calls
# that path fiction and explicitly retires it (the old 3c6m.2 direct-libm
# matcher): no pass change, no per-fn `cq_template_<fn>`, no new frozen symbol,
# ONLY a different source on the injection side. And it does NOT make the cell
# injection-covered: `full_census.py` records these cells under their own
# PROVIDER and the scoreboard carries a THIRD row (amendment condition (iii),
# bd `libm-scoreboard-two-numbers`). Merging them into the injection number is
# the retired 165/174 overclaim recurring, and is treated as a bug.
#
# WHICH SPELLINGS: NOT a list here. `probe.cq_provided_cells()` owns the gate and
# MEASURES condition (ii) on disk (leaf + e2e slice + committed golden + ctest
# registration). Day one that is exactly 6 (sin/cos/tan.f64 + sinl/cosl/tanl.f80)
# and it REJECTS sinf/cosf/tanf, which have no f32 leaf (bd `eur4`).
#
# COMPILE FLAGS — `-fno-builtin-<spelling>` ONLY, deliberately NOT the corpus's
# blanket `-fno-builtin`. A CQ leaf is not "one more corpus body": its VERIFICATION
# ARTIFACT is the committed e2e golden, which `tests/e2e/run_slice.sh:26` produces
# at plain `clang -O1` with builtins ON. Matching that is what makes condition (ii)
# mean anything, and Rule 18's own prescription is per-fn (`-fno-builtin-<fn>` on
# the caller), never blanket. The per-fn flag is still needed: it is the standard
# guard against a definition of `sin` being folded into a self-call.
#
# MEASURED 2026-07-31, and the measurement is why the choice is free rather than a
# trade-off: for all six leaves the emitted INSTRUCTION STREAM is BYTE-IDENTICAL
# across `-fno-builtin-<fn>` / blanket `-fno-builtin` / no flag at all — the only
# delta is the fn attribute (`"no-builtin-sin"` vs `"no-builtins"` vs none). The
# leaves reach their hardware-keep-set leaves through EXPLICIT `__builtin_rint` /
# `__builtin_floor` / `__builtin_fmin` / `__builtin_fmax` spellings, which no
# `-fno-builtin` variant touches. So today the flag cannot change the measurement.
#
# WHAT IT BUYS IS TOMORROW. If a future leaf edit ever spells a bare `floor(...)`
# instead of `__builtin_floor(...)`, blanket `-fno-builtin` would silently split
# the two paths — the golden's slice folding it to `@llvm.floor.f64` while the
# census emitted `call @floor` and closure-linked openlibm's BRANCHY soft body —
# i.e. the census would measure a program no golden has ever verified, with every
# ctest still green. The per-fn flag closes that at the root, and it is the one
# drift the body-text sync check in `probe._leaf_in_sync` structurally cannot see
# (both files would agree; only the FLAGS differ).
#
# INLINING IS NOT A HAZARD EITHER WAY (measured, full 2x3 matrix). The constraint
# documented at `probe()` below is ONE-DIRECTIONAL: a `"no-builtins"` CALLEE needs
# a `"no-builtins"` CALLER. Our callee now carries only `"no-builtin-<fn>"`, whose
# veto set is a strict subset of the blanket-vetoed @probe scaffold's, so it
# inlines — verified `inlined_away=True, surv=[]` for all six at O1 and O2.
_CQ_SHIM_DIR = None
_CQ_SHIMS = None        # spelling -> .bc path (built once, memoized)
_CQ_SKIPPED = []        # spellings whose leaf did NOT compile (no shim; upstream wins)

def _cq_shim_dir():
    global _CQ_SHIM_DIR
    if _CQ_SHIM_DIR is None:
        _CQ_SHIM_DIR = Path(tempfile.mkdtemp(prefix="cq_provided_"))
    return _CQ_SHIM_DIR

def _synth_cq_shim(spelling, leaf, outdir):
    """Compile ONE CQ leaf to bitcode under corpus conditions. Returns the .bc
    path, or None if it did not compile or did not define @<spelling> — in which
    case we DECLINE to shim and upstream's body keeps winning, exactly as before.
    (A shim that silently failed would make the census UNDER-report here, which is
    the safe direction; a shim that defined the wrong symbol would make it
    over-report, which is why the define check below is not optional.)"""
    bc = outdir / ("_cq_%s.bc" % spelling)
    r = subprocess.run([CLANG, "-O1", "-g", f"-fno-builtin-{spelling}", "-emit-llvm", "-c"]
                       + INC.split() + [str(leaf), "-o", str(bc)],
                       capture_output=True, text=True)
    if r.returncode != 0 or not bc.exists():
        return None
    ir = subprocess.run([DIS, str(bc), "-o", "-"], capture_output=True, text=True).stdout
    if not re.search(r'^define[^@\n]*@%s\(' % re.escape(spelling), ir, re.M):
        return None
    return bc

def cq_provided_shims():
    """spelling -> CQ-leaf .bc, for every cell `probe.cq_provided_cells()` admits."""
    global _CQ_SHIMS
    if _CQ_SHIMS is not None:
        return _CQ_SHIMS
    _CQ_SHIMS = {}
    # A broken gate must NOT quietly revert the amendment to upstream bodies: that
    # would silently answer the CQ-provided row with 0/6 and hand every dependent
    # cell (tgamma, j0/j1, the ld80 gammas) a different first blocker, with no
    # signal but a missing stderr line. Swallowing the exception is the SAFE
    # direction for the numbers (it under-reports), but a census whose methodology
    # changed under it is exactly the artifact drift bd o22d/eyfm exist to prevent.
    # So: raise. `full_census.py` imports `probe` directly anyway, so an unusable
    # gate cannot get past this point in any case.
    sys.path.insert(0, str(HERE.parent))
    import probe as _P
    cells = _P.cq_provided_cells()
    outdir = _cq_shim_dir()
    for spelling, leaf in sorted(cells.items()):
        bc = _synth_cq_shim(spelling, leaf, outdir)
        if bc is None:
            _CQ_SKIPPED.append(spelling)
        else:
            _CQ_SHIMS[spelling] = bc
    return _CQ_SHIMS

def _parse_define_sig(line, name):
    """Parse a `define ... @name(...)` header into (ret_type, [param_types]).
    Returns None unless it is a clean by-value scalar/pointer signature (the only
    shape we can faithfully forward) — an aggregate/vector/array/vararg return or
    param makes us DECLINE to synthesize (leaving the alias unresolved exactly as
    before: no regression, and no risk of a wrong-signature shim distorting the
    census)."""
    head, sep, tail = line.partition('@' + name + '(')
    if not sep:
        return None
    htoks = head.split()
    if not htoks:
        return None
    ret = htoks[-1]           # return ATTRS (signext / range(i32 0,2)) precede the
                              # type, so the final pre-'@name(' token IS the type.
    buf, depth = [], 0        # params = balanced content up to the matching ')'.
    for ch in tail:
        if ch == '(':
            depth += 1; buf.append(ch)
        elif ch == ')':
            if depth == 0:
                break
            depth -= 1; buf.append(ch)
        else:
            buf.append(ch)
    params = ''.join(buf).strip()
    ptypes = []
    if params and params != 'void':
        for p in params.split(','):
            p = p.strip()
            if not p or p == '...':      # vararg / malformed — not forwardable
                return None
            ptypes.append(p.split()[0])  # a param's TYPE is its first token.
    for t in [ret] + ptypes:             # scalar/ptr only (opaque `ptr`): reject
        if not t or any(c in t for c in '{}<>[]'):  # aggregate/vector/array types.
            return None
    return ret, ptypes

def _synth_alias_shim(alias, definer, ret, ptypes, dl_triple, outdir):
    """Write + assemble a forwarding-thunk .bc: `define @alias(...) = tail call
    @definer(...)`. Returns the .bc path, or None if llvm-as rejects it."""
    typed = ", ".join("%s %%a%d" % (t, i) for i, t in enumerate(ptypes))
    L = list(dl_triple)   # carry the target datalayout/triple to avoid link warns.
    L.append("declare %s @%s(%s)" % (ret, definer, ", ".join(ptypes)))
    if ret == "void":
        L += ["define void @%s(%s) {" % (alias, typed),
              "  tail call void @%s(%s)" % (definer, typed),
              "  ret void", "}"]
    else:
        L += ["define %s @%s(%s) {" % (ret, alias, typed),
              "  %%r = tail call %s @%s(%s)" % (ret, definer, typed),
              "  ret %s %%r" % ret, "}"]
    ll = outdir / ("_alias_%s.ll" % alias)
    bc = outdir / ("_alias_%s.bc" % alias)
    ll.write_text("\n".join(L) + "\n")
    r = subprocess.run([AS, str(ll), "-o", str(bc)], capture_output=True, text=True)
    return bc if r.returncode == 0 else None

def build_defmap(cq_provided=True):
    """`cq_provided=False` builds the UPSTREAM-ONLY defmap (no CQ leaves). Used
    by full_census.py's A/B: a cell whose closure merely LINKED a CQ leaf has not
    thereby come to REST on it, and the linkset alone cannot tell those apart
    (measured: lgamma.f64 links sinl/cosl and its status is identical either
    way). Re-probing against this defmap is the decisive test, and "which
    injection-covered cells rest on a CQ-provided leaf" is precisely the audit
    question amendment condition (iii) exists to keep answerable."""
    defmap = {}
    sig_lines = {}         # fn name -> its full `define ...` header (for aliases)
    set_pairs = []         # module-asm (alias, definer) strong_reference pairs
    dl_triple = []         # target datalayout/triple lines (shims inherit them)
    for b in sorted(BC.glob("*.bc")):
        try:
            ir = subprocess.run([DIS, str(b), "-o", "-"], capture_output=True, text=True, timeout=30).stdout
        except Exception:
            continue
        for m in re.finditer(r'^(define[^@\n]*@([A-Za-z0-9_.$]+)\([^\n]*)', ir, re.M):
            defmap.setdefault(m.group(2), []).append(b)
            sig_lines.setdefault(m.group(2), m.group(1))
        # data definitions: '@sym = <qualifiers> (global|constant) ...' with no
        # 'external' qualifier before the global/constant keyword.
        for m in re.finditer(r'^@([A-Za-z0-9_.$]+) = ([^\n]*)', ir, re.M):
            sym, rest = m.group(1), m.group(2)
            if 'external' not in rest.split('constant')[0].split('global')[0]:
                defmap.setdefault(sym, []).append(b)
        for m in re.finditer(r'^module asm "\.set ([A-Za-z0-9_.$]+), ([A-Za-z0-9_.$]+)"', ir, re.M):
            set_pairs.append((m.group(1), m.group(2)))
        if not dl_triple:
            dl_triple = re.findall(r'^target (?:datalayout|triple) = "[^"]*"', ir, re.M)
    # Resolve the module-asm '.set' aliases into real forwarding-shim bodies.
    shimdir = _alias_shim_dir()
    for alias, definer in dict.fromkeys(set_pairs):   # de-dup, order-stable
        if alias in defmap:            # a real IR definition already wins
            continue
        if definer not in sig_lines:   # alias to data / unresolved definer — skip
            continue
        sig = _parse_define_sig(sig_lines[definer], definer)
        if sig is None:                # non-scalar / vararg signature — decline
            continue
        bc = _synth_alias_shim(alias, definer, sig[0], sig[1], dl_triple, shimdir)
        if bc is not None:
            defmap.setdefault(alias, []).append(bc)
    # bd 3c6m.60: hardware keep-set shims go at the FRONT of each entry, so
    # closure_link (which takes the first not-yet-linked definer) resolves an
    # inner `sqrt`/`floor`/… to the `@llvm.<fn>` intrinsic the ship floor emits
    # instead of openlibm's software body. No link conflict is possible: every
    # corpus file that defines a keep name defines ONLY keep names (verified over
    # all 245 .bc — the s_fma/s_fmal helpers `fesetround`/`add_and_denormalize`/
    # `add_adjusted` are `internal` and called from their own TU only), so a
    # shimmed file is never pulled in for some other symbol it also defines.
    for name, bc in keep_shims().items():
        defmap[name] = [bc] + defmap.get(name, [])
    # bd guwr: CQ-PROVIDED leaves REPLACE the entry outright rather than merely
    # sitting in front of it. The keep-set prepend is enough for a keep (the soft
    # body is a legitimate fallback if the shim failed), but "CQ ships its own
    # reversible sin" means upstream's body must not be reachable for that name
    # by ANY route — a fallback here would silently answer the injection question
    # with the CQ row's cell, which is the one merge condition (iii) forbids.
    # Failure stays loud-by-absence: `_synth_cq_shim` returning None leaves the
    # upstream entry untouched and the spelling in `_CQ_SKIPPED`.
    if cq_provided:
        for name, bc in cq_provided_shims().items():
            defmap[name] = [bc]
    return defmap

def undefined_syms(bc):
    ir = subprocess.run([DIS, str(bc), "-o", "-"], capture_output=True, text=True).stdout
    decl = set(re.findall(r'^declare[^@]*@([A-Za-z0-9_.$]+)\b', ir, re.M))
    dfn  = set(re.findall(r'^define[^@]*@([A-Za-z0-9_.$]+)\b', ir, re.M))
    # undefined data: '@sym = external ...' (a global declaration)
    gdecl = set(m.group(1) for m in re.finditer(r'^@([A-Za-z0-9_.$]+) = external', ir, re.M))
    gdfn  = set(m.group(1) for m in re.finditer(r'^@([A-Za-z0-9_.$]+) = (?!external)', ir, re.M))
    return (decl - dfn) | (gdecl - gdfn)

def closure_link(probe_bc, defmap, wd, linkset_out=None):
    """`linkset_out`, if given, is EXTENDED with every .bc actually linked (bd
    guwr). Optional so the four existing callers keep their 2-tuple contract."""
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
            if linkset_out is not None:
                linkset_out.extend(linkset)
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

def probe(fn, retW, args, ti, defmap, deps_out=None):
    """`deps_out`, if given, is EXTENDED with the sorted spellings of every
    CQ-PROVIDED leaf this cell's closure actually linked (bd guwr). That is the
    honesty artifact the third scoreboard row needs: after the amendment an
    INJECTION-covered cell may rest on a CQ-provided leaf (`tgamma` calls `sin`),
    exactly as it may already rest on a hardware-keep-set shim, and a number
    whose dependencies are invisible is a number nobody can audit. Optional, so
    the three existing callers keep their 3-tuple contract."""
    src = make_src(fn, retW, args, ti)
    with tempfile.TemporaryDirectory() as td:
        td = Path(td)
        (td/"probe.c").write_text(src)
        pbc = td/"probe.bc"
        # The blanket `-fno-builtin` on the PROBE SCAFFOLD is LOAD-BEARING and must
        # stay (bd 3c6m.60, measured A/B): it stamps `"no-builtins"` on @probe, and
        # LLVM only inlines a `"no-builtins"` callee (every corpus body is one — the
        # corpus recipe builds with -fno-builtin) into a `"no-builtins"` caller.
        # Dropping it left `@acos` OUTLINED, which re-routed 10 baseline-COMPILES
        # cells through Phase-6 specialization and broke them. It costs no fidelity:
        # the probe TU contains no library call other than `fn` itself, and a real
        # ship-floor slice renames every vendored helper to `olm_*` (not a library
        # name), so libcall simplification has nothing to act on there either. The
        # keep-set fidelity gap is closed by `keep_shims()` above — at the DEFMAP,
        # which is where the inner calls actually resolve — not by this flag.
        r = subprocess.run([CLANG,"-O1","-g","-fno-builtin",f"-fno-builtin-{fn}",
                            "-emit-llvm","-c"]+INC.split()+[str(td/"probe.c"),"-o",str(pbc)],
                           capture_output=True, text=True)
        if r.returncode != 0:
            return ("build-fail", r.stderr.strip().split('\n')[-1][:80], src)
        linkset = []
        linked, err = closure_link(pbc, defmap, td, linkset_out=linkset)
        if linked is None:
            return ("link-fail", err, src)
        if deps_out is not None:
            cqbc = {str(v): k for k, v in cq_provided_shims().items()}
            deps_out.extend(sorted({cqbc[str(f)] for f in linkset if str(f) in cqbc}))
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
                    # THE CUT MUST NOT LAND INSIDE A DIAGNOSTIC PHRASE. `bucket()`
                    # classifies by substring match, so a truncation that clips a
                    # phrase silently re-buckets the cell. Measured (2026-07-28):
                    # at the old [:120] the ld80 gamma pair's 139-char diagnostic
                    # "…under quantum lift (unsupported instruction)" was cut to
                    # "…(unsup", so `bucket()` fell past its "unsupported
                    # instruction" arm into the "specialization" arm — and the
                    # census's whole "fp-copy/specialization 2" bucket was that
                    # string race, resurrecting a label bd 3c6m.54 had EMPTIED.
                    # Blast radius of widening it was exactly those 2 cells (every
                    # other decline diagnostic measured < 115 chars).
                    diag = line.split('in function')[-1][:400]; break
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
