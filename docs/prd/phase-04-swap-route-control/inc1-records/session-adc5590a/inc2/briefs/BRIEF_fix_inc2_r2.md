# BRIEF_fix_inc2_r2 — Inc 2 ROUND-2 FIX (fixture truth + record), small, on the rebased branch
Read `$SP/briefs/BRIEF_common.md` (MAIN = `main` at a3c1513, built), `$SP/progress/rebase_inc2.md`, then
`$SP/progress/review_inc2_r2.md` IN FULL (findings F-I2-1..F-I2-10; reproducers under
`$SP/progress/review_inc2_r2_work/`), then `RETIRE_SWAP_ROUTE_INC2_NOTES.md` §1 on the branch.
Agent name: `fix_inc2_r2`. Model: opus. Worktree `$SP0/wt/inc2`, branch `3qlq-inc2` at 6ee3ea3 (build current).
Save the current binary first (`cp -f build/ir-pass/cq-opt $SP/progress/fix_inc2_r2_work/cq-opt.r2base` etc.).

## SCOPE — Inc 2's own record; NO change to Inc-1-landed code
F-I2-1 (the `hasOneUse` leak on a merge out-rail) is PRE-EXISTING on main, filed as bd `test_C_libtooling-7yd0`,
and will be fixed as a separate C-1 round 4 on `main` AFTER Inc 2 lands — do NOT touch `LoopLowering.cpp` here.
What you do:
1. **F-I2-3** — `lowering_switch_value_nonI32_cast.ll`: its output moved (route → preload + XOR-delta) but it was
   not re-derived and its header documents the retired route in the present tense. RE-DERIVE its CHECKs from the
   rebased binary's output (the p119.8 width-recording property it pins must stay pinned — say which directive
   does that), rewrite the header truthfully, NOROUTE whole-file negatives (`cqrt_cswap`, non-`i1` `cqrt_rz`),
   counts in their own prefixes; red-green vs INC-1-ONLY (main's binary must FAIL the re-derived file on the
   mechanism assertions).
2. **F-I2-4** — `isPhiCall` (`isCallToPrefix(V, "cq_phi_")`, 7 identical definitions in 7 files) is DEAD since Inc 1
   (the shipped intrinsic is `@cq_phi` with no suffix), so gate 5's PHASE half and gate 6's `operandsAlias` closure
   in `SelectClassify` have no subject. Do NOT delete code (Inc-1-landed, freeze-time dead-code list); add ONE
   comment at each of the two gates and one line in the notes saying they are vacuous since a3c1513 and why that
   is safe (the `cq_theta`-shaped alias declines at gate 2c on all three binaries — cite the lens's measurement).
3. **F-I2-2** — record the reviewer-flag resolution in the notes §2: the asymmetry is a SEEDING artifact of
   `rotationAncestry(Op)` (walks only when `Op` IS a rotation call), the diamond's accept is sound (a permutation
   into a fresh |0⟩ ancilla; the fork spellings decline `operand predates a non-diagonal gate` on all three
   binaries), and the 4.4 refusal is an over-decline that could be widened (owner item, not this round).
4. **F-I2-6 / F-I2-7** — the `&&` byte-identity item has no subject (both spellings decline on both binaries);
   the OPPOSITE asymmetry `int p = q + 11; if (q>3) p = R(p);` declines `non-routable value multiplexer` on all
   three binaries while its select twin accepts — pin BOTH as fixtures (a decline fixture for the diamond with the
   string mirrored + an accept fixture for the twin), and record as an over-decline owner item (a bd issue is the
   orchestrator's; give it a name in the notes).
5. **F-I2-1** — copy the lens's reproducers (`q5sel_preadd_{rolled,unrolled}.c`, `q7_k32_*.c`, `q4b*.c`) into
   `docs/prd/phase-04-swap-route-control/inc2-records/` (the branch already has that dir) with a README naming the
   bd issue; add a paragraph to notes §2 and to PRD §0 (a dated E11 line under Inc 2's E1) saying Inc 2 adds a
   fourth producer of the rail shape and where the fix lives. Do NOT add a fixture that pins the LEAK as an accept
   (that would bless it); the round-4 fix pins the discharge.
6. Notes `RETIRE_SWAP_ROUTE_INC2_NOTES.md` **§2 — round 2** (the lens's findings and their dispositions, the
   rebase's conflict table in one paragraph, the 4 twin gates + injection + census numbers, what you ran); PRD §7
   status + the PRD status header: "Inc 2 rebased onto a3c1513, round 2 CLEAR on the mechanism, clearance
   pending"; `CLAUDE.md`'s Inc-2 status sentences likewise (do not say landed).
Verification: red-green per fixture (INC-1-ONLY vs yours); `ctest -R ir-pass-lit` background → green but the
XFAIL; the 4 value twin gates + `e2e-slice-control-switch-value`; the injection matrix over the re-derived
fixture; STRICT 2b. Commit per step (`wip(3qlq): Inc 2 round 2 — …`). Hand back per BRIEF_common.
