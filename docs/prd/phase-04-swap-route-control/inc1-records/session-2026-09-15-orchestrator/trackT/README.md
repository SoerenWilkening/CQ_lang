# Track T — bd `test_C_libtooling-tu9q`, the IN-LOOP PAIRING

| file | what it is |
|---|---|
| `IMPL_T2.md` | the implementation record: what landed, the measurements, the Rule-13 rounds, the Track-S′ interaction, the bd `s82e` population split, and what is NOT built |
| `GATES.md` | every gate result, hash-keyed to the binary it is a fact about (PROTOCOL's non-redundancy rule) |
| `probes/src/` | the bd `tu9q` probes (`s1`/`s2`/`s3` carried from Track S and re-measured here) and Track T's own (`t1`–`t3`), each with a hand-unrolled twin |
| `probes/adv/` | the Rule-13 adversarial probe families: round 1 (`a*`, the accept boundary and the spine inside a newly-marked body), the (ii-c) boundary controls (`b*`), round 2 (`r*`, the stages and records the grant touches), and the two hand-written L1-window modules (`l1`/`l2`) |
| `probes/out/`, `probes/adv/out/` | stage-1 IR, lowered IR, stderr and traces for every probe on BOTH binaries (`.ora.*` = ORACLE, `.sub.*` = subject). Executables deleted; everything else committed. |
| `probes/corpus_T.sh` | the ORACLE-vs-SUBJECT corpus sweep. Decline rows are keyed on a sha1 of the FULL stderr, not on the shared `corpus.sh` tag regex — that regex renders the whole `cq_measure_<sfx>` family as an empty `D:` and hides a D→D string change (PROTOCOL S3). |
| `probes/inject_T.py` | the Rule-12 MUTATION matrix. It parses each fixture's own `; RUN:` lines and re-runs them verbatim against a mutated lowered IR — a harness that runs a WEAKER command than lit measures itself, not the fixtures (L10). Exits non-zero on MISSED > 0 **or on zero mutations applied**. |
| `probes/corpus_<hash16>.txt` | the sweep output, named for the subject binary it measured |
