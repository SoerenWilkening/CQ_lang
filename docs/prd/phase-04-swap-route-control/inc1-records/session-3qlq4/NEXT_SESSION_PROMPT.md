# Next session — after bd `test_C_libtooling-3qlq.4` (Inc 1b, the bare `_Bool` condition) landed

Read first: `CLAUDE.md` (the CORRECTNESS-RISK paragraph "INCREMENT 1b — THE BARE `_Bool`
CONDITION"), PRD `retire-swap-route-PRD.md` §13 (§13.6/§13.7 are the two Rule-13 rounds),
this directory's `README.md`, `review_1b_r1.md` and `review_1b_r2.md`.

## Owner questions on the desk (from the two rounds)

1. **bd `test_C_libtooling-3d8q` (P1, PRE-EXISTING on `main`)** — a `cq_theta` or
   `cq_measure` READER of a stale rail name is never asked the wire question
   (`declineStaleRecordOps` sweeps pure ops only): `int b = cq_theta(q,.5); int c =
   cq_theta(q,.9); return cq_measure(b) + cq_measure(c);` lowers as a chain. The reviewer's
   fix sketch is in the issue (sweep theta arg-0 / measure readers with `checkStaleOp`,
   excluding the reader itself). It is a Rule-13-core widening with its own adversarial
   round. Fix next, or hold? (OQ-1b-R2-1)
2. **The `thetaOnPathTo` parity gap (bd `r903`)** — its closure keeps the narrow ancestry
   because `phiTracksWire` GRANTS on it (accept direction). Thread taint with its own round,
   or leave? (OQ-1b-R2-2)
3. **HANDOFF Q4/Q6 (dead state-prep arm; F2 on an `i1` seed)** — both still block the
   owner's cascade when written with `bool` PREPS under control; unchanged by Inc 1b.

## The next increment, if the owner says "bool everywhere" still

**1b-B, bd `test_C_libtooling-r9e5`**: the 4.4 data select / Inc-2 value arm / 6.5 arm on a
rail condition (`int a = 5; if (b) a -= 3;`). The rail is the flag; the copy merge is two
`cqrt_copy_<W>_controlled(h_b, …)`; the `¬`-copy needs a bracket on the CONTROL — decide
between the CNOT identity and re-arguing a bracket on the register (the diagonal-only
invariant of Inc 1b applies to PHASE gates; a controlled copy is a different question).
Then 1b-C (`l4x4`), 1b-D (`boi6`).

## Instruments to run before widening anything here

* the `session-3qlq4/probes/` family and both review probe corpora (`rc.sh`/`rh.sh`/
  `corpus.py` in `review_1b_r2_probes/` diff a candidate binary against a reference);
* `e2e-loop-twin-matrix` and the `phase-bool` ctest subset; `cq-opt-equivalence-full`.
