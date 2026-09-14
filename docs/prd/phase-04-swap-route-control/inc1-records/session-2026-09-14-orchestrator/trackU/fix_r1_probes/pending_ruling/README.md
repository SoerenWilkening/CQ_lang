# WITHDRAWN fixtures — NOT live, pending an owner ruling on F-U1-1

**These two `.ll` files are NOT in `ir-pass/test/` and must not be moved there without the ruling.**
They are the decline fixtures for review-round-1 finding **F-U1-1**, written and then withdrawn on the
coordinator's hold of 2026-09-14. `ir-pass/test/` is at **1936** fixtures — the count `GATES.md`
row 36 records for binary `a5773be142835fb8` — and adding either of these changes that count and
invalidates every cited gate line.

| file | pins |
|---|---|
| `lowering_reject_undef_theta_seed_with_undef_angle.ll` | the f64 composition the review found (`double d; d = cq_theta(d,d);`) — seed and angle are ONE uniqued `double undef` |
| `lowering_reject_undef_theta_seed_crosswidth_undef_angle.ll` | **the anti-identity row**: seed `i1 undef` + angle `double undef`, two DIFFERENT uniqued constants. A "same `UndefValue` object" conjunct — the fix the brief spelled — leaves this one ACCEPTING. The f64 row cannot tell the two predicates apart |

**State when withdrawn.** Both measured RED on `a5773be142835fb8` (`cq-opt` exit 0, 0 B of stderr, so
the `not … | FileCheck` RUN line fails). ⚠ Neither was FileCheck'd on the build that carried the
conjunct (`dedb3d53836771f4`) — what was measured there were the C probes they transcribe (`r14`,
`r21`), restored to DECLINE with byte-identical full stderr. **The green half is still owed.**

**If the ruling restores the decline**, the landing is: re-apply the arg-1 conjunct in
`normalizeUndefRotationSeed` (`slotCarriesUndef(Theta->getArgOperand(1))` — GUARD 1's own predicate,
Rule 14, NOT constant identity), move both files into `ir-pass/test/`, re-derive the source comments
in `RotationLowering.cpp` / `RotationLowering.h` / `TaintPropagation.cpp` from "OPEN" to the shipped
argument, and **re-run every gate** — none of the five `a5773be1` lines cited in `GATES.md` may be
cited for a different binary. Note also that the conjunct closes `r14`/`r15`/`r21` and **does not
close `r22`** (the survivor on a different theta), which no conjunct local to the call can see.

**If the ruling is that the ORACLE's decline was itself an over-decline**, delete this directory and
record the disposition in `IMPL_U.md` §2(f), whose correction block stands either way.

Full evidence: `../../FIX_U_R1.md` §1–§2.
