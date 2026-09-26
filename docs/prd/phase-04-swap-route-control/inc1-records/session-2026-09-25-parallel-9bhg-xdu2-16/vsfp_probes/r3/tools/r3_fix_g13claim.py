W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/'
p = W + 'ir-pass/src/DeadValueLiveness.cpp'
s = open(p).read()
old = '''    // The condition is a seed whenever the fold leaves it dead: no φ, or every φ
    // had EQUAL incomings (`(a > 3) ? K : 0` with `K == 0` once the volatile
    // global fold read `K`; r2B `g13`, bd stl3). A condition a new `select`
    // reads is live and the recursive call deletes nothing.'''
new = '''    // The condition is a seed whenever the fold leaves it dead: no φ, or every φ
    // had EQUAL incomings (`int r = (q > 3) ? K : 0;` with `K == 0` once the
    // volatile global fold read `K`). For a CLASSICAL condition that is cleanup
    // only (a dead compare keeps no parameter live under liveness); for a TAINTED
    // one it is load-bearing: the dead compare would be lowered as a forward
    // template never uncomputed — a dirty flag (bd vsfp round 3, mutant S2,
    // `lowering_volatile_globalfold_equal_phi.ll`). A condition a new `select`
    // reads is live and the recursive call deletes nothing.'''
assert s.count(old) == 1
s = s.replace(old, new)
open(p, 'w').write(s)

p = W + 'docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/TRACK_VSFP.md'
s = open(p).read()
old = '''"volatile-globalfold", Blocks)`, and re-`propagate`s on a true return (the otam rule). A second defect
surfaced under `g13` (`(a > 3) ? K : 0` with `K == 0`): the fold turned the two-entry φ into its
common value, but `deleteDeadCones` seeded the condition's cone only when NO φ was left, so `a > 3`
stayed live. The condition is now seeded after every fold (a condition a new `select` reads is live,
and the recursive call deletes nothing).'''
new = '''"volatile-globalfold", Blocks)`, and re-`propagate`s on a true return (the otam rule). A second defect
is in `deleteDeadCones`: after a fold whose φs all had EQUAL incomings (`(a > 3) ? K : 0` with
`K == 0`) it seeded the condition's cone only when NO φ was left. ⚠ For `g13` (a CLASSICAL condition
in the callee) that is cleanup only — a dead compare keeps no parameter live under liveness, and
mutant S2 passes `g13`'s fixture — and the first draft of this paragraph, and of the source comment,
said otherwise (L7, caught before commit by reading S2's result). Where it is load-bearing is a
TAINTED condition: `int r = (q > 3) ? K : 0;` in `main` leaves a dead tainted compare that is lowered
as a forward template and never uncomputed — a dirty flag across the later Ry (S2 was MISSED by the
whole suite until `lowering_volatile_globalfold_equal_phi.ll` pinned it, §R3.10). The condition is
now seeded after every fold (a condition a new `select` reads is live, and the recursive call deletes
nothing).'''
assert s.count(old) == 1
s = s.replace(old, new)
old = '''| F-WB-2 (stl3) | P2 | `foldVolatileConstGlobalLoads` gets the empty-arm fold (+ the otam re-propagate); `deleteDeadCones` seeds the condition after every fold (a φ of EQUAL incomings left it live) (§R3.4) |'''
new = '''| F-WB-2 (stl3) | P2 | `foldVolatileConstGlobalLoads` gets the empty-arm fold (+ the otam re-propagate); `deleteDeadCones` seeds the condition after every fold (a φ of EQUAL incomings left a dead TAINTED compare lowered as a dirty flag) (§R3.4) |'''
assert s.count(old) == 1
s = s.replace(old, new)
open(p, 'w').write(s)
print('ok')
