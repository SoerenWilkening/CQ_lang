# Increment-3 (E2) scouting probe — measured 2026-09-23 at the increment-2 close

```
ORACLE/SUBJECT  cq-opt a0e31e0316496f71a6843cf8c31aebb81bcfbdc6fea162b5d34c0d32cc4d000b
```

| probe | what it exhibits |
|---|---|
| `e2_only_subject.c` | ⚠ **E2's standalone red-green subject, and it exists only BECAUSE increment 2 landed.** An in-loop, SCALAR rail-leaf condition (`bool b = cq_theta(…)` declared inside the body, so no rail BANK and no φ), four carried variables so `-O1` refuses to if-convert, and **no memory in the arm at all**. Measured: `gate=E2-cycle` and nothing else. Before increment 2 the same program died at `E6-condtree` first, so E2 had no isolable subject. |

Stage-1 shape, checked (bd `46oo` — a control-flow probe must be verified at stage 1
for the shape it claims): `llvm.loop` × 3, `select i32` × **0** (the arm really is a
`br`), 9 `phi i32`.

⚠ **This probe does NOT exercise the rail bank, the merge-φ rail, or any load.** It is
deliberately the minimum that isolates E2, and it is therefore NOT evidence about the
owner's program, which additionally needs E6's rail-φ half and E4.
