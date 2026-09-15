# Track D's number, carried with BOTH caveats (the brief's trap 5)

**`warnLiveRecordRotations` is SILENT on ZERO of the programs `declineDephasingUnmarkedLoopRails`
declines.** Measured by Track D (`trackD/MEASUREMENT.md` §2) on SUBJECT `libCQPass.so`
`d4bf79c1473ea26d…`, at two scopes taken from two different corpora:

| scope | rows | distinct programs | WARNED | **SILENT** | PREEMPTED | CRASH | INSTRUMENT-BROKEN | CONTROL-BROKEN |
|---|---|---|---|---|---|---|---|---|
| brief's minimum (`ir-pass/test` + this session's probes) | 17 | **12** | 17 | **0** | 0 | 0 | 0 | 0 |
| full corpus (5289 rows swept) | 21 | **14** | 21 | **0** | 0 | 0 | 0 | 0 |

⚠ The brief handed this to the gate as *"0 of 14"*. That is the **full-corpus** figure; the
minimum-scope figure is **0 of 12**. Both are printed above because they come from different
corpora and neither derives the other.

**The two things that make the number worth anything, and they are not the number:**

* **`marker=1` on every row.** The marker can only be printed by `emitDeferredDephasingDecline`,
  which runs AFTER the warn stage — so every row proves the warn stage EXECUTED. **Not one figure
  is 0-by-preemption**, which is the exact defect the pre-instrument table had to live with.
* **Five ORACLE controls.** Five of the 12 ACCEPT on the frozen ORACLE — no fence in front of the
  warn stage at all — and their ORACLE warn counts **1 · 1 · 2 · 1 · 2** are identical to what the
  deferred run reports. Empirical evidence that deferring the decline does not perturb what the
  warn stage sees, against the "pure analysis ⇒ fence-deleted pipeline" argument that would
  otherwise be the only ground.

## THE TWO CAVEATS, and the number must not be quoted without them

1. **It is 0 over 12 (or 14) PROGRAMS, not a proof over the class.** Track D says so itself and did
   not construct a counter-example, and explicitly does not claim none exists.
2. ⚠ **Track S′'s own candidate shape is NOT REPRESENTED IN THAT POPULATION AT ALL** — a rail minted
   **inside a region** by `cqrt_alloc`, whose record set `RecordSet::push` clause 5 leaves EMPTY.
   The population is self-selected: it is *the set of programs some track already wrote a probe
   for*, not a sample of the shapes the fence can refuse. **A zero over a population that excludes
   the one shape anybody suspected is a weaker fact than a zero over an arbitrary one.**

**What it does NOT say** (`trackD/MEASUREMENT.md` §2.2, and owner ruling E6): it does **not** say the
warning subsumes the fence. E6 already records why the populations nest — *divergence ⇒ hazard,
hazard ⇏ divergence* — and this measurement tests only the first implication. **A/B/C remain open and
this track rules none of them.**
