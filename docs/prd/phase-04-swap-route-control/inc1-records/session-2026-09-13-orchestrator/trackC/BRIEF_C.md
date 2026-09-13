# Brief — Track C: `cq_measure` of a value that never became quantum lowers to the CLASSICAL VALUE, no gate — bd `21mg`

Written 2026-09-13 by the orchestrator. Model: opus. You are the IMPLEMENTATION agent. Worktree
`/Users/sorenwilkening/Desktop/CQ_21mg`, branch `classical-measure` (from `main` 86c0d25), its OWN `build/`
(configure: `cmake -S . -B build -DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release
&& cmake --build build -j8` — BOTH targets, always). Protocol: `../PROTOCOL.md` — your row is
"implementation": inner loop = `lit --filter` + single slices; `ir-pass-lit` ONCE at hand-off; the corpus sweep
ONCE at hand-off → `probes/corpus_<hash16>.txt`; NO `^e2e-`, NO full suite, NO equivalence sweep. Record
`GATES.md` (hash-keyed) and `IMPL_C.md` beside this file IN YOUR WORKTREE. Do not commit, do not push. Never
write outside your worktree. Report only what you ran.

## 0. The customer

The owner's 2026-09-11 22:18 edit of `example/grover/grover_oracle_uncompute.c` — the second region commented
out — leaves `bool b1 = 0;` never assigned and `return cq_measure(b0) + cq_measure(b1) + cq_measure(a);`.
Reconstruct it as `probes/owner_2026-09-11_2218.c`:

```c
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
```

ORACLE verdict (bd `21mg`): `cq_measure_<sfx> operand not recognized; expected a tainted i32 handle` at the
measure of `b1` (`MeasureLowering.cpp:86-92`: `if (!(Handle->getType() == I32 && taint.Tainted.count(Handle)))`).
Dropping only `cq_measure(b1)` compiles (15 lines). Measuring a classical bit is a valid (trivial) circuit —
under the 2026-09-11 expressiveness ruling this is an over-decline to remove. Target: the file compiles, exit 0,
empty stderr, STRICT 2b clean, and its trace is BYTE-IDENTICAL to the 15-line trace of the `cq_measure(b1)`-less
twin (measure both on your binary; the twin is the witness).

## 1. Scope — 21mg ONLY

IN: in `lowerMeasures`, a `cq_measure_<sfx>` whose operand is NOT tainted (a `Constant`, or a classical SSA
value of the call's declared operand type) is replaced by the operand itself — `cq_measure` is type-preserving
(verify in `include/CQ.h`: every `cq_measure_<sfx>` returns its operand type; if any does not, `zext`/`trunc`
to the declared return type and say so) — no runtime symbol, no gate, no trace line, and the call is erased.
KEEP the loud decline, string unchanged, for an operand that is TAINTED but not an `i32` handle (tainted and
unlowerable — the original fence's real subject). OUT: everything else. `MeasureLowering.cpp` is the sole sink
(Rule 3) and the only pass file you edit.

Decide and PIN (Rule 12, with the reason in the fixture header): (a) an `undef`/`poison` operand — recommend a
loud decline (the `LiteralIntegrity` posture: an undef is two values at the `-O0` stage 3); (b) a classical
operand that is a `PHINode`/`select` over classical values — lowers to the value (it is classical; nothing
quantum is touched); (c) a classical measure INSIDE a tainted region's arm (`bool c = 0; if (b0) x =
cq_measure(c)`) — MEASURE what the ORACLE does today (`armBlockIsPureSpine`? the I/O-sink guard? which string)
and keep that verdict unless it is `operand not recognized` — in which case decide with the region emitters in
mind and write the argument; (d) a value that is classical at round 1 and TAINTED at the round-2 fixpoint
(derived from a 6.5/4.5 `%out` — `lowerMeasures` runs AFTER `repropagateControlMerges`, `CQLoweringPass.cpp:489`
vs the `lowerMeasures` call — verify by reading and by a two-TU probe on the `session-9pum` recipe) — must lower
as a MEASURE of the handle, never as the classical value: that is the L1 obligation this change owes, and it is
discharged by ORDER; pin it. (e) `taint.MeasureCalls` consumers OTHER than `lowerMeasures` — grep every reader
(`railMeasuredBeforeReadPoint`, `FreePoint`'s Measured set, `staleRailRecordRead`, `declineTaintEscapes`, the
rail ladders): does any of them assume every `MeasureCalls` entry names a rail? A classical entry must be
ignored there, not crash or mis-fence; enumerate the sites with `file:line` and say what each does with it.

## 2. Rule 12 — red-green, in this order

1. DECLINE fixtures first, each RED for the RIGHT reason on the ORACLE: (i) tainted-but-not-`i32` operand (hand
   IR: a tainted `i64` that never lowered) keeps `operand not recognized` character-for-character; (ii) the
   `undef` operand (your (a) verdict); (iii) the in-arm classical measure (your (c) verdict, whatever string).
2. ACCEPT fixtures: constant `i1`, constant `i32`, a classical SSA `i32` (`n + 3` of a runtime `n`), a classical
   `double`, a classical `phi`, the owner's shape (RED on the ORACLE at `operand not recognized`, GREEN here),
   the round-2 (d) shape as a MEASURE. Whole-file count prefixes: `MCNT` = exact `cqrt_measure_` count;
   `NOMEAS-NOT: cqrt_measure_` in the pure-classical fixtures; `NOALLOC-NOT: cqrt_alloc` (a classical measure
   must never mint — the f64/angle miscompile family is "allocate for classical data").
3. Injection matrix over the accepts (an injected `cqrt_measure_i32(0)`; an injected `cqrt_alloc`; the classical
   value replaced by a tainted handle) — every mutant must redden ≥1 prefix; report MISSED.
4. e2e: `tests/e2e/slice_measure_classical_bool.c` (= the owner's 22:18 file) STRICT 2b + its golden; a
   `compare_files` gate against `slice_measure_classical_bool_twin.c` (the `cq_measure(b1)`-less twin) — 15 = 15.
   Register in `tests/e2e/CMakeLists.txt` after the last `slice_control_*` group; `ctest -R
   '^e2e-slice-measure-classical'` for each.

## 3. Record: `IMPL_C.md`

§0 measured before coding (the ORACLE on every probe); §1 the change (`file:line`, the predicate before/after);
§2 the (a)–(e) verdicts with the reason; §3 red-green log (each fixture RED then GREEN, with the lit line);
§4 injection matrix; §5 e2e + the two traces; §6 corpus sweep ORACLE-vs-SUBJECT over `ir-pass/test/*.ll` + all
session probe dirs (`../PROTOCOL.md` names them) — movers must be DECLINE→ACCEPT on the `operand not recognized`
string only, each listed; §GATES = a copy of `GATES.md`; §7 open questions / found-in-passing (an over-decline
you meet in passing is a bd issue with its measured string — write it down, the orchestrator files it).

Final message ≤30 lines: the change, the (a)–(e) verdicts, the owner-file trace vs the twin (byte-identical or
not), movers, `GATES.md` verbatim, §7.
