# Reversible lowering ground truth

Owner direction, 2026-10-07: consult BennettVM.jl alongside Bennett.jl for precise
compilation. The standing requirement lives in NORTHSTAR goal 2 and CLAUDE R12.
CQ emits gates and mechanically derived adjoints at compile time. The references
inform that compiler; their execution models and capability counts are not CQ's.

## Audited revisions

Source inspection used complete public checkouts at:

- [Bennett.jl, `824458d10e879c3fef673c231a02e5461dac667f`](https://github.com/tobiasosborne/Bennett.jl/tree/824458d10e879c3fef673c231a02e5461dac667f).
- [BennettVM.jl, `23d28e6471f9cf5d8a22177d08260ca86adfe841`](https://github.com/tobiasosborne/BennettVM.jl/tree/23d28e6471f9cf5d8a22177d08260ca86adfe841).

These are evidence pins, not dependency changes. BennettVM's
`BENNETT_JL_PIN.md` records its last validated upstream revision as `f904d0d`,
not the Bennett.jl HEAD inspected here. No Julia tests, cross-repository build,
CQ lowering probe or census rerun was performed for this documentation change.
The cited tests are inspected upstream evidence, not tests run in this session.

## CFG, PHIs and loops

Bennett.jl's [path predicates and PHI merges](https://github.com/tobiasosborne/Bennett.jl/blob/824458d10e879c3fef673c231a02e5461dac667f/src/lowering/phi.jl)
compute an edge predicate from the predecessor's block predicate and branch polarity.
Incoming edge predicates select the PHI value. Its
[CFG lowering](https://github.com/tobiasosborne/Bennett.jl/blob/824458d10e879c3fef673c231a02e5461dac667f/src/lowering/cfg.jl)
checks the canonical CFG and natural-loop assumptions; it rejects irreducible CFGs
and nested loops. Those rejects do not define CQ's permitted language.

BennettVM's [PHI ingest](https://github.com/tobiasosborne/BennettVM.jl/blob/23d28e6471f9cf5d8a22177d08260ca86adfe841/src/ir/ingest_phi.jl)
and [CFG ingest](https://github.com/tobiasosborne/BennettVM.jl/blob/23d28e6471f9cf5d8a22177d08260ca86adfe841/src/ir/ingest.jl)
use block parameters and a trampoline per edge to preserve the correct incoming tuple.
This is useful source semantics for CQ control and loop lowering, including the
[nested-loop witness](https://github.com/tobiasosborne/BennettVM.jl/blob/23d28e6471f9cf5d8a22177d08260ca86adfe841/test/test_matrix_sum_roundtrip.jl).
It does not establish a compile-time bound or a coherent circuit for those loops.

[ADR 0022](https://github.com/tobiasosborne/BennettVM.jl/blob/23d28e6471f9cf5d8a22177d08260ca86adfe841/docs/adr/0022-phi-edge-binding.md)
records a concrete SSA transfer bug: deleting a PHI incoming at the edge destroyed a
value that had a later use. `_bind_args_to_params!` captures all inputs before assigning
any parameter and preserves the source bindings. The
[multi-use PHI test](https://github.com/tobiasosborne/BennettVM.jl/blob/23d28e6471f9cf5d8a22177d08260ca86adfe841/test/test_rnhv_phi_multiuse.jl)
is relevant to CQ's borrowed handles and cross-iteration ownership. Simultaneous
transfer and later-use preservation must survive translation to controlled copies.

These references inform `dm7f.15`, `dm7f.16`, `p3kd.7.3`--`p3kd.7.5`, `8h7d` and
`wrwo`. For `p3kd.7.9`, they supply CFG semantics; the exact existing scope remains
a path-independent gate stream through classical multi-block control. BennettVM's
path-dependent execution does not prove that stream property. The compiler must
establish it and preserve gate literals for the mechanically emitted reverse.

## Calls, aggregate ABI and memory

BennettVM's [call ingest](https://github.com/tobiasosborne/BennettVM.jl/blob/23d28e6471f9cf5d8a22177d08260ca86adfe841/src/ir/ingest_body.jl)
resolves a closed-world function table and handles void, scalar and field-wise
multi-return landing. Its current CFG ingest decomposes heterogeneous
`IRInsertBits` chains into field slots and returns the slot family from inner callees.
The [insert-bits and consumed-sret test](https://github.com/tobiasosborne/BennettVM.jl/blob/23d28e6471f9cf5d8a22177d08260ca86adfe841/test/test_416r15_insertbits.jl)
shows the source-extraction/ABI reconciliation across the sibling repositories.
Entry multi-return remains rejected; support for a callee shape is not all-ABI parity.

The [duplicate-call-argument regression](https://github.com/tobiasosborne/BennettVM.jl/blob/23d28e6471f9cf5d8a22177d08260ca86adfe841/test/test_0fw7_dup_call_args.jl)
pins passing the same SSA source to multiple parameters while preserving its caller
binding. CQ's borrowed quantum handles need corresponding alias and ownership checks.
An Int64 VM cell is not CQ's i32 runtime handle or proof of FP80 copying.

For memory, compare Bennett.jl's
[guarded shadow stores and pointer-origin predicates](https://github.com/tobiasosborne/Bennett.jl/blob/824458d10e879c3fef673c231a02e5461dac667f/src/lowering/memory.jl)
with BennettVM's
[memory floor](https://github.com/tobiasosborne/BennettVM.jl/blob/23d28e6471f9cf5d8a22177d08260ca86adfe841/src/ir/memory_floor.jl),
[heap intrinsics](https://github.com/tobiasosborne/BennettVM.jl/blob/23d28e6471f9cf5d8a22177d08260ca86adfe841/src/ir/intrinsics.jl)
and [C frontend contract](https://github.com/tobiasosborne/BennettVM.jl/blob/23d28e6471f9cf5d8a22177d08260ca86adfe841/docs/adr/0020-c-track-frontend-contract.md).
DataLayout-derived GEP offsets, pointer-valued loads/stores and explicit closed-world
calls are useful compiler references. Adapt the byte/cell representation to CQ's LLVM
types and reversible memory model. Destructive-store history in the VM does not prove
a CQ scratch register is zero and may be freed.

These references inform `p3kd`, `p3kd.5`, `p3kd.6`, `p3kd.9`, `p3kd.4` and `01po`.
They supply mechanisms and regression shapes, not a measured census gain.

## Poison, constants and primitive eligibility

Bennett.jl's
[undef-PHI fixture](https://github.com/tobiasosborne/Bennett.jl/blob/824458d10e879c3fef673c231a02e5461dac667f/test/test_yd4f_undef_phi_cells.jl)
distinguishes integer `undef` at a PHI incoming under `ptr_cells` from poison,
non-integer undef and undef returns. Its mode-specific refinement is not a general
proof that an undef edge is unreachable. Its `freeze` extraction is an identity in
the bit model. CQ's speculated LLVM literals require a non-poison proof or one stable
freeze shared by forward and inverse uses (`p3kd.7.7`); `p3kd.8` still needs its
return-value semantics established. Neither issue is fixed by copying the bit model.

BennettVM's
[literal-certification regression](https://github.com/tobiasosborne/BennettVM.jl/blob/23d28e6471f9cf5d8a22177d08260ca86adfe841/test/test_hsm3_literal_certification_vm.jl)
records a zero-blob substitution that returned wrong answers while reversing cleanly.
Forward agreement with the intended implementation is a separate obligation from
successful reversal. CQ keeps its analytic/trace review and golden evidence under R2.

BennettVM's [Float32 ingest guard](https://github.com/tobiasosborne/BennettVM.jl/blob/23d28e6471f9cf5d8a22177d08260ca86adfe841/src/ir/ingest_body.jl)
rejects f32-touching soft operations. Its
[SoftCall](https://github.com/tobiasosborne/BennettVM.jl/blob/23d28e6471f9cf5d8a22177d08260ca86adfe841/src/ir/softcall_instruction.jl)
uses inherited Float64 routines and checkpoint/replay reversal; that alone supplies no
gate circuit for a direct CQ primitive. Bennett.jl's native `frem` remains unsupported.
Thus `3c6m.68` and `3c6m.79` still require real source lifting or an eligible circuit at
the exact widths and numerical contract. The VM reference does not grant f32/f80
intrinsic credit or change NORTHSTAR goal 2's direct-route requirements.

The repository-level coverage/status documents contain historical claims. In particular,
BennettVM's `docs/coverage-matrix.md` still calls `IRInsertBits` inapplicable and aggregate
returns deferred, while current source and tests implement inner multi-return paths.
Use the pinned implementation and relevant tests when making a capability claim.
