# Full-surface libm injection census (bd 3c6m.49 / 3c6m.50)

The width/by-ref/int-ret widening of `../inject_census.py` (which is hardcoded to
`double`). Injects the **real openlibm** body per cell across every width variant
(f32/f64/f80), runs `cq-lowering`, and records the actual blocking capability.

**⚡ POST-L6 headline (3c6m.14 Inc 4, 2026-07-14):** the L6 CONTROL lever (PredMux)
shipped. Re-running this census with the committed HEAD plugin: real openlibm
math.h = **48/123 injectable cells compile** (was 2), **24 f64 + 24 f32**; f80 all
still held by SHADOW. Of the 48, **8 are VERIFIED** (committed e2e goldens:
`atan cbrt erf exp log lround scalbn tanh.f64`); the other 40 compile+link+run but
need goldens. Two DISJOINT numbers (Rule 2, bd `libm-scoreboard-two-numbers`):
**injection-covered 48/123 (39%), verified 8/123 (6.5%)** — never quote "48 verified".
Deterministic 48/48/48 across 3 runs; census-mode flood reproduces the §4/§5 lever
map exactly. Full delta + per-lever follow-ups: `../FULL_DEPTH_CENSUS.md` §11.

**First-blocker headline (3c6m.49, 2026-07-11 — pre-L6 baseline):** real openlibm
math.h = **2/120 injectable cells compile** (only `fdim` — genuinely branchless);
118 decline. The `inject_census.py` "32/32 COMPLETE" is the **authored branchless
substitutes** (`../branchless/`) that bypass every lever.

**Full-DEPTH peel headline (3c6m.50, 2026-07-11):** the first-blocker bucketing
hid the true capability combinations. The `CQ_PEEL_CENSUS` census-mode plugin
(see below) surfaces the COMPLETE per-cell blocker stack in one run. Over the
reconciled **123-cell** ISO C11 surface: **CONTROL (tainted control flow, L6
3c6m.14 + the swap-route emitter) participates in 108/123 measured, 119/123 after
corpus-masking is inferred away; 51 cells are CONTROL-ALONE; ZERO cells hit a
C-physics wall.** See `FULL_DEPTH_CENSUS.md` and bd memory
`libm-full-depth-peel-census-2026-07-11`.

## Harness files
- `wprobe.py` — width-parametric probe (build + closure-link + inline pipeline).
- `full_census.py` — first-blocker census (imports `probe.py` MATHH_SPEC, one
  blocker/cell). Writes `full_census_results.json`.
- `peel_census.py` — **full-depth** census. In normal mode = first-blocker
  (`first_blocker_refreshed.json`); with `CQ_PEEL_CENSUS=1` + the census-mode
  plugin = the complete blocker stack per cell (`peel_census_results.json`).
  Parallel over cells (defmap built once).
- `synth_census.py` — merges both runs, folds raw blocker classes into campaign
  LEVERS, emits the capability-combination -> function table + the
  cells-unlocked-per-lever ranking (`peel_census_merged.json`).
- `dump_ir.py` / `batch_dump.py` — cache one cell's inlined IR + its diagnostic.

## Census-mode plugin (THROWAWAY — never committed)
The full-depth run needs a throwaway instrumentation of the pass (bd 3c6m.50):
a `CQ_PEEL_CENSUS` env gate in `CQLoweringPass::run` that (1) installs a
non-fatal diagnostic handler — opt normally `exit(1)`s on the first `DS_Error`,
truncating the stack; the handler records every decline as a `cq-peel: <msg> @
<loc>` line and returns *handled*; (2) calls `censusFloodTaint` (an
over-approximate data-dependence closure through memory store->load and call
results) so guards see the whole body; (3) runs only the pure analysis/detection
guards and returns before any mutating stage. The instrumentation lives on a
scratch branch and is `git checkout`-reverted before commit — the committed
harness (`peel_census.py` etc.) is inert without it (falls back to first-blocker).

## Reproduce
```bash
# 1. corpus (one-time source fetch; NOT a runtime dep)
git clone --depth 1 https://github.com/JuliaMath/openlibm <scratch>/openlibm
OLA=<scratch>/openlibm; mkdir <scratch>/bc
for c in $OLA/src/*.c $OLA/bsdsrc/*.c $OLA/ld80/*.c; do   # ld80 = long double bodies
  clang -g -O1 -fno-builtin -emit-llvm -c \
    -I "$OLA/include" -I "$OLA/src" -I "$OLA/amd64" -I "$OLA/bsdsrc" -I "$OLA/ld80" \
    "$c" -o <scratch>/bc/$(basename ${c%.c}).bc 2>/dev/null   # INLINE -I flags: zsh does
done                                                          # NOT word-split unquoted $INC

# 1b. CORPUS-GAP CLOSURES (bd 3c6m.50 Step 0c) — three openlibm public names are
#     minted by the build's symbol aliasing, which the raw -emit-llvm corpus build
#     does not reproduce. Rebuild these so gamma/ldexp cells hit their REAL body
#     (not a spurious "unknown callee"):
#   tgamma double body (b_tgamma.c) needs the BSD M_PI constants:
clang -g -O1 -fno-builtin -DM_PI=3.14159265358979323846 -DM_PI_2=1.57079632679489661923 \
  -DM_PI_4=0.78539816339744830962 -emit-llvm -c \
  -I "$OLA/include" -I "$OLA/src" -I "$OLA/amd64" -I "$OLA/bsdsrc" -I "$OLA/ld80" \
  "$OLA/bsdsrc/b_tgamma.c" -o <scratch>/bc/b_tgamma.bc
#   public non-reentrant lgamma/lgammaf/lgammal wrappers (openlibm aliases them):
cat > /tmp/lgamma_public_shim.c <<'EOF'
extern double lgamma_r(double,int*); extern float lgammaf_r(float,int*);
extern long double lgammal_r(long double,int*); int signgam;
double lgamma(double x){return lgamma_r(x,&signgam);}
float lgammaf(float x){return lgammaf_r(x,&signgam);}
long double lgammal(long double x){return lgammal_r(x,&signgam);}
EOF
clang -g -O1 -fno-builtin -emit-llvm -c /tmp/lgamma_public_shim.c -o <scratch>/bc/lgamma_public_shim.bc
#   ldexp/ldexpf/ldexpl (openlibm strong_reference(scalbn, ldexp)):
cat > /tmp/ldexp_shim.c <<'EOF'
extern double scalbn(double,int); extern float scalbnf(float,int);
extern long double scalbnl(long double,int);
double ldexp(double x,int n){return scalbn(x,n);}
float ldexpf(float x,int n){return scalbnf(x,n);}
long double ldexpl(long double x,int n){return scalbnl(x,n);}
EOF
clang -g -O1 -fno-builtin -emit-llvm -c /tmp/ldexp_shim.c -o <scratch>/bc/ldexp_shim.bc

# 2. point BC / OPENLIBM at <scratch>, then:
BC=<scratch>/bc OPENLIBM=<scratch>/openlibm python3 full_census.py     # first-blocker
BC=<scratch>/bc OPENLIBM=<scratch>/openlibm python3 peel_census.py     # first-blocker (refreshed)
# rebuild the census-mode plugin (throwaway CQ_PEEL_CENSUS instrumentation), then:
BC=<scratch>/bc OPENLIBM=<scratch>/openlibm CQ_PEEL_CENSUS=1 python3 peel_census.py   # full stack
python3 synth_census.py                                               # -> peel_census_merged.json
```
