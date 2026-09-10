# Next session — the owner's adjusted `grover_oracle_uncompute.c` still DECLINES (2026-09-10, session close)

**Start here.** The owner adjusted `example/grover/grover_oracle_uncompute.c` after bd `3qlq.4`
(Inc 1b) landed on `main` (b00fdc2) and it still declines. The file is git-excluded, so the
ONLY committed copy is `user_file_as_of_2026-09-10_close.c` beside this prompt — work from
that, not from memory. Its `main()`:

```c
int a = 5;  bool b0 = 0;  bool b1 = 0;
if (a >= 3) { b0 = cq_theta(b0, 0.5); }
if (b0 == 1) a -= 3;
return cq_measure(b0) + cq_measure(a);
```

**Measured at close on `main` b00fdc2 (`clang -O1` → `cq-lowering`), nothing else was done:**

```
cq controlled lowering: bare i1 register condition under quantum control
```

That string is `kBareRailCondReason` (`SelectClassify.h`): a `_Bool` REGISTER driving a
consumer Inc 1b did not lower. It was not investigated in the closing session on the
owner's instruction ("do not investigate the problem here"); the next session's first job
is to do so. Do it in this order:

1. **Measure the shape.** `clang -O1` the committed copy, read the IR, and name which
   consumer refuses the rail: with `a` the classical constant 5, `if (b0 == 1) a -= 3` is
   expected to arrive as a DATA select `select i1 %b0, i32 2, i32 5` (the 4.4 select with a
   rail condition — bd `test_C_libtooling-r9e5`, follow-on 1b-B, whose fixture is
   `control_swap_reject_select_rail_cond.ll`), and `cq_measure(a)` makes `a` live. Confirm
   or refute that reading from the IR before touching anything; also check whether the
   classical guard `if (a >= 3)` folds away (it did on the session-start version).
2. **If it is 1b-B, build 1b-B** (bd `r9e5`): the copy merge controlled on the register
   itself — `SelectClassify::classifySelectRegion` admits a single rail leaf on the data
   path, `SelectMergeEmit` uses `Flag = rail`, no mint/strip/free; the `¬`-copy needs a
   bracket on the CONTROL, so decide between (a) the CNOT identity / an extra ancilla and
   (b) re-arguing a `cqrt_x` bracket on the register for a CONTROLLED COPY (Inc 1b's
   diagonal-only invariant was argued for PHASE gates via `preservesBorrowedParent` — a
   copy controlled on the register is a different question; measure the spine's
   dispositions on the probes before choosing). Re-argue gate 2c and the gate-5 walks for a
   borrowed flag. Rule 12 red-green from the owner's file as the flagship slice, plus a
   probe family; Rule 13 review; note the value-arm and 6.5 callers share the emitter.
3. **Then re-run the owner's file** and the `session-3qlq4/probes/` family; anything still
   declining gets its wall named against 1b-C (`l4x4`), 1b-D (`boi6`), `r903`, or the
   HANDOFF's Q4/Q6.

Everything below is the state of the record at close.

## Background — after bd `test_C_libtooling-3qlq.4` (Inc 1b, the bare `_Bool` condition) landed

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
