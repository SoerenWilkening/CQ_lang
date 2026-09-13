# SCOPING brief — Track R increment R-2: the RIVAL AUDIT for "a pinned value that is the condition of a conditional `br` is not an F2 collider" (`vd`'s collider) — decision material for the owner, NO code

Written 2026-09-13 by the orchestrator after `SCOPE_R.md` §1.2/§2 R-2. Model: opus. **READ-ONLY,
measure-first; no build, no suite; ORACLE only** (`../PROTOCOL.md`, row "scoping"). Record: `SCOPE_R2.md`
beside this file; probes under `probes/r2/` with `README.md` + runner. Final message ≤30 lines.

## 0. What is known

`SCOPE_R.md` §1.2: `../probes/vd.c` declines F2 because the THIRD region's guard `%9 = icmp sgt i32 %8, 2`
(`vd.c:19`, `a >= 3`), defined in the merge block, is pinned to `i1 false` on the TRUE edge of the fused
diamond `br i1 %1` (b0's bare rail) and collides with the b1 prep's seed `false`. No peel is involved. R-1
does not touch it. The candidate spelling (§2 R-2): *a pinned value that is used as the condition of a
conditional `br` in this function is not a collider* — because the rival that would rotate it in place
puts a non-diagonal gate between a compare and its own branch, which `condWireDisposition`'s 2c prong
declines unconditionally (the 2026-09-11 α-form argument: where the rival has no lowering, there is nothing
for F2 to protect). Its RETIREMENT TRIGGER is live: the day bd `xqgx` A.2 admits a non-diagonal gate between
a compare and its branch, R-2 becomes an over-accept. The nearest shipped decline is
`ir-pass/test/control_inplace_ry_reject_stateprep_second_flag_i1.ll` (a pre-branch, off-wire, measured `i1`
— must KEEP declining under R-2).

## 1. What to measure and write

**§0 The rival audit — the 2026-09-11 "32/32" shape.** Enumerate EVERY spelling of "rotate a value that is
later (or earlier) a branch condition" that plain C at `-O1` and hand IR can produce, and for each record
the ORACLE's verdict string and firing site (`CQ_CTRL_DBG=1`): the rival in the arm (`if (b0) b1 =
cq_theta(flag, θ)` where `flag` is a later guard); the rival before the branch; the rival on the flag's
`zext`; the flag branched on AND read as data; the flag branched on in a DIFFERENT function/after inlining;
a flag whose branch is inside a loop; a flag that is a `switch` scrutinee; a flag that is a `select`
condition (is a select condition "a conditional br"? — decide, and measure what 2c does for it); a flag
consumed by TWO branches; a flag that is the condition of the SAME region (i.e. `CondWire`'s own member —
already excluded); a flag whose `br` is UNREACHABLE/dead after `-O1`; and the three-bool `vd` family
(`v_vd*`, `r_R6a/b`) re-run. The claim to test: **for every spelling where R-2 would remove F2's decline, a
DIFFERENT shipped fence declines the rival** — name that fence and its string per row. Any row where R-2
removes the ONLY decline of a rival is a HOLE, and R-2 cannot be built as spelled.

**§1 The 2c argument, read from the source.** Quote `condWireDisposition`'s prongs (`ArmClassify.cpp`) that
refuse a non-diagonal gate between a compare and its branch; state exactly which prong, whether it is
position-aware (`provablyBeforePerActivation`) or position-free, and what bd `xqgx` A.2 (1)/(2)/(3) would
change about it — so the retirement trigger can be written as a `file:line` condition, not prose.

**§2 The spelling.** Where the conjunct sits (`ArmClassify.cpp:1616`, at the TEST like R-1), how "is a
conditional br's condition" is computed (users of `V` that are `BranchInst` with `V` as condition — in THIS
function; what about a `br` in a block `-O1` will delete? what about round 2?), the L1 record obligation if
the answer can change between rounds, and the interaction with R-1 (both conjuncts at one site — order
irrelevant? say why).

**§3 Fixtures the increment would owe** (accept: `vd`'s hand-IR and the `r_R6b` shape; kept declines:
`…_second_flag_i1.ll`, `r_R6a` (DATA use only), every `range_forward_*`/`sideways_*`), the e2e slice
(`slice_control_cascade_three_bools.c` = `vd.c` — AFTER Track M; compose its golden by extension of Track M's
29-line stream and say what it will be), cost, rounds (budget 2).

**§4 Recommendation to the owner**, one paragraph: build R-2 now / build after `xqgx` A.2 is decided /
do not build — with the measured trade (what compiles that does not today; what the retirement trigger
costs; how many rows of the audit rest on ONE fence).

Style: `../../session-f2-i1/` (the F2 audit's own rival table), `SCOPE_R.md`. Line numbers dated to the
current `main` (re-grep).
