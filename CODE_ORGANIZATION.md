# CQ_lang Code Organization Audit

This audit records the initial 400-line inventory and cleanup candidates. The
machine-readable function index is [`CODE_MAP.md`](CODE_MAP.md); regenerate it
with `python3 tools/update_code_map.py` whenever functions move.

## Scope

The maintained source surface is `include/`, `ir-pass/`, `runtime/`, `tools/`,
`tests/`, `example/`, and `demo/`. Build trees, scratch probes, archived
implementations, documentation corpora, and generated build output are not
treated as refactor targets.

## Findings

The largest maintained files are concentrated in three categories:

- `ir-pass/src/ArmClassify.cpp`, `LoopLowering.cpp`, and `PredMuxFlatten.cpp`
  contain several semantic phases and are the highest-risk candidates for
  decomposition. Split by cohesive analysis/emission concern, preserving
  detection-before-mutation ordering and keeping shared predicates in one
  header/source pair.
- `runtime/cq_templates.c` and `runtime/cq_templates.h` are generated from
  `tools/opcode_table.yaml`. They should be split by generated family only by
  changing the generator and CMake together; editing generated output directly
  is prohibited by the project rules.
- `tools/loop_twin_matrix.py`, `free_pairing_check.py`, and their tests are
  large executable specifications. They need staged extraction of shared
  parsing, model, and reporting helpers, with golden-output tests after each
  move.

The complete per-file physical-line inventory and function locations are in
`CODE_MAP.md`. The map intentionally makes generated, test, and tooling
violations visible instead of hiding them behind the application-code count.

## Cleanup candidates

The low-risk cleanup completed in this audit removed an unused
`ControlledSymbols.h` include from `SwitchRouteEmit.cpp` and corrected stale
runtime-header comments that described `cqrt_free` as unused even though the
lowering emits it. No semantic lowering code was deleted. In this compiler,
apparently redundant guards often encode a previously found silent-miscompile
fence, and apparently dead bookkeeping can protect pointer-identity or
uncompute invariants. Candidates therefore need evidence before removal:

1. generated runtime split and stale-artifact cleanup (`runtime/cq_templates.*`);
2. extraction of `ArmClassify.cpp` into analysis-only and arm classification
   units;
3. extraction of `LoopLowering.cpp` by loop shape (discovery, rail promotion,
   emission, and reverse-play bookkeeping);
4. extraction of Python matrix harness infrastructure from individual matrix
   definitions; and
5. a repository gate for the 400-line budget, with explicit generated/test
   policy.

These are follow-up refactors rather than opportunistic edits: each must retain
the full relevant `ctest`/lit/e2e gates and must not widen an acceptance shape.
