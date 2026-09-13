# SCOPING brief — Track L: the LOOP form of the controlled-operation cascade — bd `wx8g`, `boi6.a`, `3qlq.6`, the bool-array / 7.5 wall. SCOPE ONLY this session.

Written 2026-09-13 by the orchestrator. Model: opus. **READ-ONLY, measure-first; no worktree, no build, no
suite.** The per-probe pipeline on the ORACLE only. Protocol: `../PROTOCOL.md` ("scoping" row). Record:
`SCOPE_loop.md` beside this file; probes under `probes/` with `README.md` + runner; the ready-to-land pins
under `ready/`. Final message ≤40 lines. This record becomes the SPINE of the next session's prompt.

## 0. The owner's goal, verbatim (2026-09-13)

*"the grover script might be implemented with a large loop, where MANY of those controlled operations are
applied"* — and (2026-09-11) *"our end-goal is to not decline any code that will lead to a valid quantum
circuit"*. The flat cascade (`../probes/owner_file_2026-09-13.c`, N=2; `../probes/vd.c`, N=3) is Tracks M and R.
The LOOP form compiles in NO spelling today; `../probes/ve.c` (`bool b[3]` in a `for`) declines
`ve.c:7:26: … cq taint escape: tainted value stored to memory`.

**Owner question Q2 is OPEN** (asked 2026-09-13; answer may arrive mid-session — the orchestrator will forward
it): which C is the target — (i) `bool b[N]`: every iteration a FRESH qubit (the flat file's semantics; needs
the 7.5 QRAM memory path for a tainted bool array), or (ii) a scalar `bool b` re-prepared each trip (a CHAINED
rotation on ONE qubit — a different circuit; only the last `b` is measurable). Scope BOTH until told otherwise.

## 1. What to measure and write (SCOPE_loop.md)

**§0 The canonical customers.** Write `grover_cascade_loop_array.c` (spelling i) and
`grover_cascade_loop_scalar.c` (spelling ii), each the loop form of the owner's cascade (`if (a >= 3) b =
cq_theta(b, .5); if (b) a -= 3;` per trip, N = 2, 3, 8), PLUS their hand-unrolled twins (the flat N=2 twin of (i)
IS the owner's file; N=3 IS `vd.c`). For EACH: the state vector the loop denotes (write it — the owner must be
able to answer Q2 with the circuits in front of them), and the trace the unrolled twin prints on the ORACLE
where it compiles (it does not today for N≥2 — say which wall; Track M/R's target streams are in their SCOPE
records, cite them once they exist, do not wait for them).

**§1 Every wall IN ORDER, per spelling, on the ORACLE**, with the string, the `!dbg`, the firing site (`CQ_CTRL_DBG=1`,
lldb on `diagnoseUnderControl` if needed) and the bd that owns it. Then PEEL THE WALLS: for each wall, the
minimal source edit (or hand-IR edit) that removes ONLY that wall, and what fires next — until you reach either
an ACCEPT or a wall with no owner. Expected order (VERIFY, do not assume): (i) `taint escape: tainted value
stored to memory` (the array; is it the `-O1` SROA/mem2reg failing to scalarise `b[i]` with a run-time `i`? at
N=2/3 with full unrolling does `-O1` scalarise it, and does the file then become the FLAT file? — measure: this
may make (i) FREE at small constant N and impossible at large/dynamic N); (ii) the loop layer
(`lowerLoops`, `CQLoweringPass.cpp:373` — `loop-carried tainted value crosses iterations` / Q1 / the 7.3
bounded-trip proof), then `control flow inside a loop body` (l4x4.c carve-out, `ArmClassify.cpp` rail-only
scope fence, bd `wx8g`), then `branch phase on a bare i1 condition` on the header φ (`boi6.a`), then the in-loop
VALUE arm / data select on a carried register (`3qlq.6`; `p6` in SCOPE_boi6: `cq loop lowering: loop-carried
tainted value crosses iterations`). Say which fires FIRST and prove the order.

**§2 The increment plan** — which bd first and why, what each needs from the drbq Inc-3 in-loop machinery
(`collapseRailPhisIn`, `railPhiRootMint` `LoopLowering.cpp:360`, `staleRailRecordRead` `:1042`, `markIfRailLocal`,
`invariantRegisterRoots`, `recordLivePerActivation`, M-β under a loop, the structural freeze of a LOOP-CARRIED
rotated register), the `_Bool` axis the twin matrix lacks (`tools/loop_twin_matrix.py` — `grep -c bool` = 2,
both in `phi_surface_of_header`; 288 cells blind), and the C-1 in-loop entangled-rail family (eight instances
over six rounds — budget three review rounds per increment). Read `../../session-boi6/SCOPE_boi6.md` §2.1
(D-A's design, rung 0 via `railPhiRootMint` + the lifted `railPhiSelfCycleClosed`), §3 H-1 (the
`reverifyRailCondReads`-vs-collapse slot — owner question Q1 is open; assume option (a) "ask rung (iii) BEFORE
the collapse and record the verdict" unless told otherwise, and cost the other two), and `bd show wx8g`.
For spelling (i) at dynamic N: what the 7.5 memory ABI would have to provide (a tainted `i1` array as a rail
VECTOR? per-element `cq_theta` on a `getelementptr`?) — is it in Phase 7.5's shipped accept-shape, and if not,
what is the smallest shape that is.

**§3 The H-10 pins, READY TO LAND** (SCOPE_boi6 §0.4: `p2`/`p9` — a carried `_Bool` whose region condition is
the in-body chained theta — lower ROLLED, twin-identical, K-independent, and NO fixture or slice pins them).
Write under `ready/`: `ir-pass/test/control_phase_kickback_rail_inloop_carried_theta_first{,_negated}.ll` with
`CHECK` lines derived from the ORACLE's actual output (whole-file count prefixes, `NOX-NOT: cqrt_x(i32 %h`,
`NOROUTE-NOT: cqrt_cswap`), `tests/e2e/slice_control_phase_bool_carried_theta_first{,_unrolled}.c` + the
`.expected.log` you measured, and the `CMakeLists.txt` lines (a `compare_files` gate rolled = unrolled, the
`twin-identical` pattern). You may NOT run `lit` (scoping row) — say so; the landing agent validates. Include
the K-independence measurement (lowered IR line count at K=3 and K=1000).

**§4 The wall that is NOT a loop wall**: `if (b) a -= 3` once `a` is quantum is an in-loop VALUE arm (3qlq.6),
but `-O1` folds it to a `select` — so is it the 4.4 select IN A LOOP (`p6`: declined by the LOOP LAYER before
detection)? Measure which; the answer decides whether 3qlq.6 or the loop layer's carried-select handling is the
customer's third wall.

**§5 Cost** per increment (lines, fixtures, goldens, matrix cells, rounds) and the ORDER recommended to the
owner, with the one-sentence reason each.

Style models: `../../session-boi6/SCOPE_boi6.md`; `../../session-l4x4/SCOPE_l4x4.md` §2.4 (the in-loop form
with no twin). Every number measured with its command in `probes/README.md`. Line numbers dated to 86c0d25.
Probe files carry RETIREMENT TRIGGERS in their headers (L8): *"when bd X lands, this declines no longer and the
stream is …"*.
