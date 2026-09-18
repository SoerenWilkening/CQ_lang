# PROTOCOL — session 2026-09-22 (a DELTA)

**The binding protocol remains
[`../session-2026-09-19-orchestrator/PROTOCOL.md`](../session-2026-09-19-orchestrator/PROTOCOL.md)**,
carried through the 2026-09-20 and 2026-09-21 deltas. ⚠ Every ORACLE BLOCK in
those files is STALE. This session's binaries:

```
ORACLE  (main e107a177)  cq-opt 3368af1262695d7e4c573d3958f0a9aa48e604bf5248e1b85a52362ac76f69dc
                         libCQPass.so 48b8b4db61777082e98bf9f15da7d50ebe386a7d5342b1292c9f05b72260ffaf
SUBJECT (increment 1)    cq-opt 3497126f3528e8ea4727c39be5e4d7cec610afc3c0853c43e101b17ed496513f
                         libCQPass.so fb28f4f644641a4363a3b09636d2b225fb08b7248e1ffb7cebeb5b21680024e7
```
⚠ The ORACLE was rebuilt from scratch in a clean worktree and came out
**BIT-IDENTICAL** to the hashes recorded at the 2026-09-21 close. The build is
reproducible; a hash mismatch is a real difference, not nondeterminism.

## THE 2026-09-21 ADDITIONS, CARRIED — and which ones PAID AGAIN

* **(1) null control before the first real measurement.** Paid: the corpus A/B ran
  ORACLE-vs-ORACLE over all 2117 fixtures (**0 movers**) before the real sweep, and
  a positive control after it.
* **(2) capture `$?` immediately, never after a pipe.** Paid in an unexpected
  place — see addition (14).
* **(11) a control-flow probe must be checked at STAGE 1 for the shape it claims.**
  ⚠ **PAID IMMEDIATELY AND IT CAUGHT A REAL ONE.** The rolled half of this
  session's protocol-item-5 probe accumulated a loop-INVARIANT value, so `-O1`
  rewrote the accumulation to a closed form and **deleted the loop entirely**
  (`!llvm.loop` count 0). A verdict read off it would have been a verdict about a
  straight-line program. Making the cone index-dependent restored the loop.
* **(12) an e2e slice whose `main` returns nonzero fails with zero output.** Paid:
  the new slice is `int main(void) { (void)slice(); return 0; }`.

## ADDITIONS THIS SESSION EARNED

14. **⚠ A BEAD'S BISECTION IS DATA, NOT EVIDENCE, UNLESS ITS PROBES ARE COMMITTED
    AND ITS BINARY IS NAMED.** bd `fn1q` recorded a three-row bisection in prose.
    Re-measured on a bit-identical rebuild of the binary it named, **three of its
    claims are false**: the "condition wall" accepts; the two declines are not one
    per axis; and "hand-unroll it and it COMPILES" is an artefact of `-O1`
    const-folding a local `int p[]={3,2,1}` at a now-constant index and
    if-converting the result. The session opened by re-deriving the bisection
    instead of building on it, which is the only reason the increment is aimed at a
    fence that exists. **Convention adopted: a bead that reports a bisection commits
    its probe sources under the session record and names the binary hash**
    (bd `test_C_libtooling-5zwz`). This session's are in `probes/`.

15. **⚠ WHEN A DECLINE STRING HAS MANY CALL SITES, MEASURE THE SITE — DO NOT
    REASON ABOUT IT.** `CQ_CTRL_DBG` names the offending INSTRUCTION, not the
    PREDICATE, and `LLVMContext::diagnose` EXITS on the first `DS_Error`, so the
    usual method is one rebuild per hypothesis. The new `CQ_CTRL_BT` lever prints a
    backtrace beside it. **Measured payoff: three probes sharing two decline strings
    resolved to THREE DIFFERENT predicates**, and the attribution the brief told
    this session to trust (`ArmClassify.cpp:6193`, the out-of-arm hoisted base) was
    not the site for the shape it named either. Both the hypothesis the brief
    refuted AND the replacement question it offered were wrong; only the backtrace
    settled it.

16. **⚠ THE TOOL THAT REPORTS A COMPILER DECLINE MUST SAY IT IS A DECLINE.**
    `tools/show_pipeline.sh` ran under `set -euo pipefail` with no failure banner,
    so a loud `DiagnosticInfoUnsupported` — the Prime Directive's whole mechanism —
    killed the script after a full IR dump and left one bare `error:` line. It was
    reported as "the script fails again", and the decline itself went unexamined for
    days. **A gate whose failure mode is indistinguishable from a bug in the gate
    trains people to stop reading it** (the 2026-09-21 addition (12), in a new
    place). Stage 2 now traps and prints `STAGE 2 · DECLINED` with the diagnostic
    and, in words, that this is a compiler verdict. ⚠ And the fix itself hit
    addition (2): `if ! cmd; then rc=$?` captures the NEGATED COMPOUND's status (0),
    not the command's. `set +e` / command / `rc=$?` / `set -e`.

17. **⚠ AN INCREMENT OWES THE L1 QUESTION ABOUT ITSELF, NOT ONLY ABOUT ITS
    NEIGHBOURS.** The cone's admission conjunct (K1) "classical" is asked at
    ROUND-1 taint, and `repropagateControlMerges` can falsify it — which would leave
    a region already hoisted, merged and FLATTENED on a Q+C premise while `lowerOps`
    sees Q+Q, a shape `classifyArms` DEFERS by design. The construction was found by
    asking the standing L1 question of the new code, not by a probe, and it is fenced
    (`declineRound2TaintedArmCone`) rather than argued empty. ⚠ **Say "not claimed
    reachable" and mean it**: no probe in this increment produced the shape.
