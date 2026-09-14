# Merge-gate raw measurements — session 2026-09-14c

Committed so the numbers in `../MERGE_REPORT.md` and `../GATES.md` are re-derivable rather than quoted.
Paths inside the data files are repo-relative.

| file | what it is |
|---|---|
| `sweep_row.sh` | ONE corpus row: ORACLE vs SUBJECT on the **same** stage-1 module. A decline row is compared by exit code + **sha256 of the FULL stderr** (PROTOCOL S3 — the shared `corpus.sh` tag regex collapses a whole decline family to an empty `D:`); an accept row additionally by lowered-IR md5, **within the row only** (md5s are NOT comparable across sweeps — the temp `ModuleID` moves). Refuses a 0-byte module (`EMPTY`) rather than letting the passthrough early-out score it ACCEPT. Emits a per-row `!dbg` bit: `1` = the diagnostic carries a real source location, `0` = `<unknown>:0:0`, `-` = accept |
| `corpus_0e280fc6.txt` | the 6311-row sweep on the gated binary. `6236 SAME · 38 STRMOVE · 14 VERDICTMOVE · 23 CLANGERR · 0 IRDIFF · 0 DECLINE→ACCEPT` |
| `ab_differential_9885fcee.txt` | the A×B differential: Track A's **real** `railBankCarveVerdict` vs Track B's **shim**, both called at every call site from a TEMPORARY audit build (reverted; `GATES.md` records the residue grep at 0). 130 rows: 63 `AB_SAME Bank` (verdict + all 7 shape fields), 47 `AB_SAME` non-Bank, 20 `AB_DIFF`, **0 rows where real=`Bank` and shim≠`Bank`** |
| `twincell.sh` | Track S's four requested twin cells, run through `loop_twin_matrix.py`'s own per-side stages on the merged binary. ⚠ Hardened against the three lies Track S measured on its own harness: a stale trace, a 0-byte `.c`, and an empty count printed as a result. It also failed LOUDLY (`unbound variable`) on its first invocation rather than printing a verdict — which is the property to keep |
| `dupscan.py` | the L8 duplicate-body scan: sha256 over each fixture's non-comment lines, with each duplicate's CLAIMED verdict read off its own RUN lines (`not %cq-opt` ⇒ DECLINE) and groups that MIX verdicts flagged |

⚠ **The A×B differential's one un-exercised arm.** Its `AB_DIFF shape on Bank` branch never fired, for
the good reason that no shape ever differed — but its equality test DID run, 63 times, which is what
`AB_SAME Bank` reports. The arm is live code on a population that is empty, not dead code.
