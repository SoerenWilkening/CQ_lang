# Rule-13 review brief, round 1 — bd `test_C_libtooling-b6ap`: the MULTI-PHI MERGE PEEL

Branch `merge-phi-peel` (off `main` 0c7380c), worktree `/Users/sorenwilkening/Desktop/CQ_b6ap`, `build/` current
(DO NOT rebuild; DO NOT edit `ir-pass/`, `include/`, `tests/`, `tools/`). Tree under review: `IMPL_b6ap.md`
beside this file. ORACLE: `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` + `libCQPass.so`
(main 0c7380c, read-only). The implementation's full `ctest -j6` was `100% tests passed, 0 tests failed out
of 389` (2088 s under load) — you do not need to re-run it; run `ir-pass-lit` and any e2e entry you touch.

## What changed (`git diff main --stat`; read `git diff main -- ir-pass/src ir-pass/include` first)

* NEW `ir-pass/src/MergePhiPeel.cpp` + header (168 non-comment lines): `peelIndependentMergePhis`, an
  accept-only normalisation that rewrites a tainted-condition diamond's merge phis whose incomings are all
  AVAILABLE AT THE PRED into `select`s in the merge block (own compare clone; rail conditions use the rail),
  leaving the region with its single own merge phi. Called immediately before EVERY `detectControlRegions`:
  `CQLoweringPass.cpp:416`, `:887` (second entry point) and `TaintPropagation.cpp:1409` INSIDE
  `detectAndLowerOnwardControl`'s fixpoint loop (3 detect sites, 3 peel calls — grep-checkable).
* Predicate P1–P8 from `SCOPE_b6ap.md` §3 with three DECLINE-KEEPING deviations: **D1** a `>=2`-phi entry
  gate (a ONE-phi merge is never peeled — because a one-phi merge can hold `classifyPhaseKickback`'s
  ANGLE-TAIL phi, and peeling it would re-lower a shipped Rule-13-cleared accept); **D2** no in-loop peel
  (P9); **D3** no `undef` incoming (P3b).
* Rule-14 shares: `isMuxableType` de-anonymised from `PredMuxFlatten`; new `propagateFromSeeds` in
  `TaintPropagation`.
* **The implementation's own first spelling was a CONFIRMED silent miscompile and was fixed before hand-off**
  (IMPL §2): a peeled `select` was left CLASSICAL ("taint follows the phi" is false — `propagateWorklist`
  taints USERS of tainted values, so a source-written select with a tainted condition IS tainted while the
  equivalent phi is not), and `add nsw i32 %m, %out` over a 4.4 merge out-rail reached the backend
  un-lowered — it added the runtime HANDLE TAG (the bd `afmv` class) at exit 0, verify-clean, 2b-clean
  (probes `z08`/`z18`/`z19`). Fix: taint the peeled select unconditionally + re-run the one shipped walk;
  the peeled module is now byte-identical to the hand peel.
* `e2e-loop-twin-matrix`: 5 cells `m_rz_{der,eq0,eq,gt,range}_rz` moved on the UNROLLED side only
  (DECLINE→ACCEPT): `-O1` sinks the second repetition's `cq_phi` calls, leaving TWO `double` ANGLE phis; the
  peel makes both selects and `classifyAngleSelect`'s Rz stem claims them (no `cqrt_alloc_f64` anywhere).
  The implementer re-derived the unitary by hand (`a==5` → `2π`, else `0`) and HAND-EDITED 5 rows of
  `tools/loop_twin_matrix.expected.txt` to `UNROLLED-ONLY` (IMPL §7 Q10 gives the conservative one-clause
  alternative). **This is a change to a gate's expected output made by the implementer — re-take it.**
* Counts: lit 1776→1801, goldens 341→343, ctest 387→389; corpus diff over 1776 pre-existing fixtures
  `0 RCDIFF · 0 DIAGDIFF · 0 OUTDIFF`; probe movers 16, all in `session-b6ap/probes/`.
* Owner's file (`/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/owner_file_2026-09-11.c`):
  next string `bare i1 register condition` (bd `l4x4`); with `int b0`+`int b1` it compiles, 22 lines,
  shipped as `slice_control_fused_regions_int.c`.

## Where to look for a silent miscompile (over-accept is the only unforgivable bug)

1. **ANGLE phis peeled into selects — the P7 / F-L3-1 class.** CLAUDE.md: "a floating-point merge φ is an
   ANGLE, not data — do not cross these wires"; Inc 1's F-L3-1 was an orphaned angle `select` re-classified
   as fp DATA and materialised on a quantum f64 rail. The peel now MANUFACTURES fp selects. For every fp phi
   the predicate admits, establish which consumer decides angle-vs-data (a `cq_theta`/`cq_phi` angle operand
   ⇒ angle select; a data use ⇒ kjd1 fp select merge) and attack the boundary: a phi with BOTH an angle use
   and a data use; an angle phi whose consumer is in a LATER region (round 2), or is deleted as a global
   phase (D2) BEFORE the select is classified (then the select is an orphan fp value — what lowers it?); an
   angle phi feeding a `cq_theta` whose register is the condition's wire; two angle phis feeding ONE
   rotation; the Ry stem (run-time arms decline by the Inc-2b clearance — do the peeled selects arrive as
   CONSTANT arms, and what if one incoming is a pre-region tainted-derived value?). Re-derive the 5 matrix
   cells' unitaries yourself from the traces, rolled vs unrolled, and say whether UNROLLED-ONLY is the right
   verdict or whether the conservative clause (Q10) is owed.
2. **D1 is a COUNT, not a semantic test.** A one-phi merge holding the angle-tail phi is protected by
   "count == 1", while a two-phi merge holding the SAME angle-tail phi plus a data mux peels BOTH (accept
   `z03`). What is the semantic property that makes peeling the angle-tail phi sound in the two-phi case
   and unsound (a re-lowering of a cleared shape) in the one-phi case? If there is none, construct the
   two-phi program whose angle-tail peel changes the emitted unitary vs the one-phi shipped stream.
3. **The taint fix.** "taint unconditionally + re-run the one shipped walk": is there a taint-growth event
   AFTER the peel that the single re-walk misses (a round-2 `%out` the peeled select's ARM reads; a peeled
   select whose condition is round-2 tainted — the `p80` pin covers one shape; a select whose incoming is a
   6.5 arm's hoisted call result)? Reproduce the `afmv` handle-tag class with every peelable incoming kind:
   constant, argument, pre-region tainted value, pre-region CLASSICAL value that becomes tainted at round 2,
   a QROM load, a `zext` of the condition register.
4. **Placement + flatten (SCOPE H-1, hcrg).** The select sits in the merge block; the region's flatten
   erases the arm and MERGES blocks. Confirm by reading `RegionFlatten` that the merge block survives or
   the select is moved with it; attack with the hcrg sequential chain (`z04` accepts; oracle said `nested
   control flow`): region 2's branch in region 1's merge with a peeled select between — emission ORDER
   between region 1's stream, the peeled select's mint/copies/strip, and region 2's mint (does region 2's
   compare read the condition register AFTER region 1's peeled select stripped its clone? is the clone's
   strip emitted before region 2's mint in program order?). Byte-diff against the manually-sequenced twin.
5. **Round 2 and the fixpoint site.** Site 3 is INSIDE `detectAndLowerOnwardControl`'s loop; deleting it
   reds exactly the two round-2 fixtures. Construct a THIRD-iteration customer (a peelable merge whose
   condition becomes tainted only after a round-2 region's `%out`), and a round-2 region whose peeled select
   is then itself a round-3 customer. Also: the peel runs before `detectControlRegions` — does anything
   between them (the guards: `declineTaintEscapes`, `declineClassicalMuxes`, the stale-record guard) now see
   a tainted `select` it did not see before and DECLINE it (over-decline) or PASS it (a select the classifier
   later refuses — is it then left neither lowered nor declined? Rule 1's "no third path").
6. **Unprobed by the implementer (IMPL §7 Q7):** Phase-6 clone bodies (`@__cq_q_*`: is the peel run inside
   a clone? should it be? a clone with a 2-phi merge on a tainted argument); `classifyGuardedStoreArm` + an
   all-peelable merge (the implementer says this would flip decline→accept, unprobed — probe it and grade
   it); the 7.5 QRAM/Shadow guarded-store shapes; `switch`-terminated merges; a phi over a POINTER; a phi
   whose incomings are `undef`/`poison` (D3 refuses `undef` — and `poison`? `freeze`?).
7. **In-loop (D2/P9).** The rolled side never peels; the unrolled side does. That creates
   rolled≠unrolled disposition splits (the 5 matrix cells). Is there a rolled loop shape where the peel
   DOES fire (a diamond in the loop body whose merge phis' incomings are loop-invariant — P9 refuses by
   `LoopInfo`; an irreducible cycle invisible to `LoopInfo` — the drbq S7 lesson)?
8. **`-O1` reachability.** For every accept fixture, the plain-C spelling or "none exists" with the reason
   (SCOPE §0.1: `-O1` re-phi-ifies selects, so most are hand IR — that is fine, but say which accepts have
   a C customer; the owner's int file is one).
9. **The fixture with `%S`/`sed`/`diff` RUN lines (Q8):** confirm it is portable under lit's `not`/pipes
   and actually FAILS when the two `%t.ll`s differ (inject a difference and run it).

## Method

Read `SCOPE_b6ap.md`, `IMPL_b6ap.md`, `probes/README.md`; run the probe family and every new/moved fixture
on BOTH binaries; write your own corpus under
`/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/b6ap_review/`
(plain C at `-O1` first — recipe `/usr/local/opt/llvm@19/bin/clang -Iinclude -include CQ.h -O1 -emit-llvm
-S`, then `build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S`, link
`libcq_templates.a` then `libcq_runtime.a`, run, `tools/free_pairing_check.py`; hand IR second). Every
accept argued from the state vector (Rule 2). Grade CONFIRMED-MISCOMPILE / OVER-ACCEPT-ARGUED /
OVER-DECLINE / LEAK / DOC with program, both outputs, analytic reason. Verdict BLOCK / CLEAR-WITH-ITEMS /
CLEAR. Report to `session-b6ap/review_b6ap_r1.md`, probes to `session-b6ap/review_b6ap_r1_probes/` with a
runner. Final message ≤30 lines: verdict, each finding in one line with grade, and your ruling on the 5
matrix rows (keep UNROLLED-ONLY / apply Q10's conservative clause).
