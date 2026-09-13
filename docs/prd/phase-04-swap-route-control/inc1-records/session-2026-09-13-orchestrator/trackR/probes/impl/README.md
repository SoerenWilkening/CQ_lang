# Track R — R-1 IMPLEMENTATION probe artifacts

Everything here was produced on the **SUBJECT** binary
`221c1caa465db61e3e96ce530fbd51afd25b9cd257b25ceb7966d6d747ee3577`
(`/Users/sorenwilkening/Desktop/CQ_rb9x/build/ir-pass/cq-opt`, branch
`rb9x-f2-clones`), against the frozen session **ORACLE**
`fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661`
(`/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`, read-only).

| file | what it is | how to re-run |
|---|---|---|
| `subject_probes.txt` | the 36 scoping probes re-measured on the SUBJECT | `CQR=<repo> CQP=../ BUILD=<repo>/build ./run2.sh` from the repo root |
| `run2.sh` | `probes/run.sh` with `BUILD` as a parameter and the ORACLE hash check replaced by PRINTING the hash it measured (the scoping runner refuses any binary but the ORACLE, which is correct for scoping and useless for A/B) | — |
| `injection_matrix.txt` | Rule 12(c) mutation matrix over the two new ACCEPT fixtures: 5 mutations × 2 fixtures, every declared FileCheck prefix re-run per mutant | `python3 inject.py <fixture>.ll …` |
| `inject.py` | that matrix's generator | — |
| `corpus_221c1caa.txt` | the ORACLE-vs-SUBJECT sweep; a row is `<rel>\|<oracle>\|<subject>` with `A:<md5-8 of the lowered IR>` or `D:<diagnostic>` | `./corpus.sh <out>` |
| `corpus.sh` | that sweep. Corpora: `ir-pass/test/*.ll` + every `session-2026-09-13-orchestrator/track*/probes` + the 2026-09-11 session dirs' `probes/` and `review_*_probes/` (PROTOCOL.md's list) | — |
| `td1.ll`, `td_aonly.ll`, `td_bonly.ll` | the §3b TWO-DIAMOND bisect: the composition (`td1`) declines `control flow` on BOTH binaries at `br i1 %g`, while region A alone (`td_aonly`) and region B alone (`td_bonly`) each ACCEPT on both. Committed as the fixture `control_peel_reject_stateprep_two_region_foreign_clone.ll` | `cq-opt … -S <f>.ll` on each binary |

⚠ The ORACLE column of `subject_probes.txt` is **not** re-measured here: the
worktree's UNMODIFIED build came out **byte-identical** to the session ORACLE
(`fbbe0820ef4b176a` on both `cq-opt` and `libCQPass.so`), so the scoping agent's
36-row table in `../README.md` is a fact about *this* binary too and is CITED
rather than re-run (PROTOCOL.md's non-redundancy rule). `IMPL_R1.md` §0 records
that measurement and the command.
