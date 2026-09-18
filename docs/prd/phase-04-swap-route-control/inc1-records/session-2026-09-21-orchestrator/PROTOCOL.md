# PROTOCOL — session 2026-09-21 (a DELTA; the binding protocol is the one it cites)

**The binding protocol remains
[`../session-2026-09-19-orchestrator/PROTOCOL.md`](../session-2026-09-19-orchestrator/PROTOCOL.md)**,
carried through 2026-09-20's delta. ⚠ **Every ORACLE BLOCK in those files is STALE.
This session's binaries:**

```
PRE-LANDING (the "oracle")  cq-opt 8280ea8d86bcaf4ed82cae92f65733fe8ae601086dfb721d58feeda55d8d9da2
                            libCQPass.so 01fbe0c125ead5b40a77178e78278df8a43e1b0133f903c9f2d5bdd81a8d575f   (main 78b6bf64)
COMPOSED (what landed)      cq-opt 3368af1262695d7e4c573d3958f0a9aa48e604bf5248e1b85a52362ac76f69dc
                            libCQPass.so 48b8b4db61777082e98bf9f15da7d50ebe386a7d5342b1292c9f05b72260ffaf
```

⚠ The F-1/F-6 source edits are **comment-only and the binary is BIT-IDENTICAL
across them** — verified, and worth keeping as a habit: it is the cheapest possible
proof that a documentation fix is a documentation fix.

## THE 2026-09-20 ADDITIONS, ALL EIGHT CARRIED — and three of them PAID AGAIN HERE

* **(1) null-tag boundary control before the first real measurement.** Paid twice:
  the corpus A/B ran MAIN-vs-MAIN over 120 fixtures (0 movers) and a positive
  control before its real sweep; the trace instrument shipped nine controls.
  ⚠ **AND NINE CONTROLS WERE NOT ENOUGH — see addition (9).**
* **(6) run the bead's literal subject on both binaries.** Paid: the owner's own
  cascade was the null control and is byte-identical on both.
* **(8) ask the question you mean, not a proxy.** Paid, in the reviewer's hands:
  round 5's P2 is exactly a predicate asked **of the wrong loop** while its comment
  claims otherwise.

## ADDITIONS THIS SESSION EARNED

9. **⚠ BOUNDARY CONTROLS WRITTEN BY THE AGENT THAT WANTS THE ANSWER ARE NOT
   ENOUGH. AN INSTRUMENT'S BLIND SPOT IS SHAPED LIKE ITS AUTHOR'S MODEL.**
   `dephase.py` shipped **nine** boundary controls and killed **four** real-trace
   mutants, and it was still unsound on its main axis: its ancestry graph was built
   from `cq_template_*` mint operands, so every permutation gate
   (`cqrt_cnot`/`toffoli`/`cswap`/`copy_controlled`) created **no edge** — and those
   are how every value-merge rail in the subject programs is built. It reported OK
   on all three canonical Rule-8 violations and on a real program **the compiler
   itself warns about**. Every control it had tested the part its author had
   thought about. **The cure is not more controls, it is an instrument built by
   someone else** — which is what the Rule-13 round is for, and it is now also
   what the round is for *about instruments*, not only about code. **State the
   instrument's edge model explicitly in its header so a reviewer can attack the
   model rather than the output.**

10. **A MUTANT THAT A FIX MAKES PASS IS NOT A VALIDATION UNTIL IT IS RE-RUN
    AGAINST THE OTHER MUTANTS.** `dephase.py`'s first fix (for the dirty-free
    miss) introduced a FALSE POSITIVE on the flat twin's Ry-additivity discharge,
    which would have been filed as a compiler defect had the trace not been read by
    hand. Re-run the WHOLE control set and the WHOLE mutant set after every fix,
    never just the mutant that failed.

11. **⚠ A PROBE FOR A CONTROL-FLOW SHAPE MUST BE CHECKED AT STAGE 1 FOR THE SHAPE
    IT CLAIMS, NOT ONLY AT STAGE 2 FOR ITS VERDICT** (bd `46oo`). Every round-3
    probe ends `main(){ return slice(4); }`; `-O1` const-propagates the argument, so
    a `break` or guard written in terms of it is **deleted before the pass sees
    it**. Round 3 recorded "multi-exit … all decline at earlier walls" from probes
    that had no multi-exit — and multi-exit is precisely where round 5 then found
    its P2, by **hand-writing the IR instead**. Cheap forms: an `argc`-dependent
    argument, `noinline`, or grep the stage-1 `.ll` for the expected number of
    exiting blocks before believing the probe.

12. **A GATE THAT CAN FAIL FOR A REASON IT CANNOT REPORT TRAINS PEOPLE TO DISCOUNT
    IT** (bd memory `e2e-slice-main-return-value-trap`). An e2e slice whose `main`
    returns nonzero fails under `set -o pipefail` with **zero bytes of output and no
    diff**, even with a perfect trace. It happens the moment one measured value is
    never quantum (bd `21mg` lowers that to the value itself), which is invisible in
    the source. Convention: `int main(void) { (void)slice(); return 0; }`.
    ⚠ Diagnosing it was itself blocked by addition (1)'s trap — `bash run_slice.sh … | grep -v` reported exit 0 while the real exit was 2.

13. **WHEN A LANDING RETIRES A FIXTURE THAT IS A FENCE'S ONLY PIN, TRY TO BUILD THE
    REPLACEMENT BEFORE REPORTING THE COST.** `loop_pairing_reject_round2_falsified.ll`
    was the only pin of a still-live L1 fence; **one post-loop read** of the rail
    restored it on both binaries. The cost was recoverable and would have been filed
    as a debt by anyone who stopped at measuring it. **Check the retired fixture's
    accept conjuncts for one you can falsify cheaply** — here it was (ii-d)'s own
    `allUsersInside`.
