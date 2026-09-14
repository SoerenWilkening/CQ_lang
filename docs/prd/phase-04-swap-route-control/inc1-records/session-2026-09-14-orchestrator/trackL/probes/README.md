# Track L probes — session 2026-09-14 (READ-ONLY scoping)

Driver: `./run.sh <probe>.c` from the REPO ROOT. It runs the `PROTOCOL.md` per-probe pipeline against
the FROZEN ORACLE (`build/ir-pass/cq-opt` f7b65d8c…, `libCQPass.so` f9e898ba…, built from 59ac5b7),
prints the opt exit code + the first diagnostic, and — for accepts — the lowered line count, STRICT
stage 2b, the trace line count, and writes `<probe>.trace` beside the source.

`a_*`, `s_*`, `t_*`, `w*`, `p*` are copied verbatim from `$PREV/trackL/probes/` and RE-MEASURED here on
the new ORACLE; their in-file VERDICT headers quote the OLD oracle (fbbe0820…, e96f89c) and several have
MOVED — see `GATES.md` and `../SCOPE_L1a.md` §9. `a_flat_n2` in particular flipped DECLINE → ACCEPT
when Track M landed, exactly as its own L8 retirement trigger predicted.

`L*` and `N*` are new this session:

| probe | what it isolates |
|---|---|
| `L1_promoted_nostore` | the cascade body AFTER the per-activation cell promotion, with NO store — peels W1 away and exposes **W2** (bd `wx8g`) |
| `L1_promoted_store` | the same WITH the single trailing store — its `clang -O1` IR is the carve's TARGET shape |
| `L2_prep_only`, `L5_prep_only_phase` | ⚠ DEGENERATE (`a` never modified ⇒ `-O1` folds the condition ⇒ no region). Kept as a warning |
| `L3_uncond_prep_value`, `L6_good_prep_value_arm` | **W3** (bd `ej5w`), two independent spellings |
| `L4_uncond_prep_phase`, `L11_promoted_phase_classcond` | the in-loop ACCEPT controls |
| `L7_array_uninit` | the Track U (`z9t1`) composition |
| `L8_array_int_cells` | the ABI-width axis (clause C3) |
| `L9_array_phase_arm`, `L10_promoted_phase_nostore` | a phase arm is strictly harder than the value arm |
| `L12`–`L15` | the opaque-seed twin question, discriminated |
| `N1`–`N3` | clause C1 negatives (VLA / escaping address / global) |
| `N4` | clause C2 negative — must keep 7.5's own string |
| `N5` | ⚠ DEGENERATE clause-2' probe (constant index ⇒ SROA) |
| `N5b` | the REAL clause-2' (injectivity) negative |
