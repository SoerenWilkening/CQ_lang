# Full-surface libm injection census (bd 3c6m.49)

The width/by-ref/int-ret widening of `../inject_census.py` (which is hardcoded to
`double`). Injects the **real openlibm** body per cell across every width variant
(f32/f64/f80), runs `cq-lowering`, and records the actual blocking capability.

**Headline (2026-07-11):** real openlibm math.h = **2/120 injectable cells compile**
(only `fdim` — genuinely branchless); 118 decline. The `inject_census.py` "32/32
COMPLETE" is the **authored branchless substitutes** (`../branchless/`) that bypass
every lever. Decline buckets map to existing levers (L2 3c6m.11 / L5 3c6m.13 / L6
3c6m.14 / Shadow iw81.13,u9pl / loops 7.3 / specialization 5po2). See bd memory
`libm-full-surface-empirical-decline-2026-07-11`.

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
# 2. point wprobe.BC / .OL at <scratch>, then:
python3 full_census.py            # -> full_census_results.json
```
`wprobe.py` = width-parametric probe (reuses inject_census closure-link machinery);
`full_census.py` = imports `probe.py`'s MATHH_SPEC, expands variants, skips the
hardware keep-set + macros + by-design.
