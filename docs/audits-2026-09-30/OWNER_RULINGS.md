# Owner decisions after the Northstar recheck — 2026-09-30

The owner retains the current CQ-provided sin approximation, asks for both census
figures, and adopts semantic review before decline-to-accept twin expectations change.
These decisions are recorded in NORTHSTAR.md and CLAUDE.md. The numerical and
classification evidence in the original audit snapshots remains unchanged.

## Published census

Calculated from `runtime_census.json`, retaining its provider choices:

| Measure | Accepted cells | Total cells |
| --- | ---: | ---: |
| Scalar-input C/Q coverage | 131 | 180 |
| Classical-only nan constructors | 3 | 3 |
| Broader API coverage, including those constructors | 134 | 183 |

Composition: 76/120 source-injected,
39/42 intrinsic-lowered,
6/6 CQ-provided and
10/12 macros. Each scalar cell requires every runtime C/Q mixture.
These figures measure build, lowering, linking and trace execution. They do not
establish numerical or unitary correctness. The macro scope remains historical f64.

## Native fmod clarification

A fresh run of the unchanged harness accepted 12/12 native-fmod probes,
with 12/12 structural free checks. Its complete JSON matches the committed
`native_fmod.json` byte for byte after JSON parsing. The command was:

```sh
BC=/private/tmp/cq-northstar-bc OPENLIBM=/private/tmp/cq-northstar-openlibm python3 tools/library_coverage/runtime_census.py --native-fmod --output /private/tmp/cq-owner-native-fmod.json --evidence-dir /private/tmp/cq-owner-fmod-evidence
```

The quantum double/double probe emits `cq_template_frem_f64`. Its generated runtime
body allocates a handle and prints a trace; it does not expand a reversible circuit.
The injected OpenLibm fmod bodies still decline on loop/control shapes. The old
Bennett frem failure concerns the missing backend route, not the audited CQ
opcode lowering. The subsequent owner ruling excludes unsupported placeholder primitives
from direct lowering and coverage: require an approved plausible hardware route without
intrinsic implementation source to inject, or an implementation provided by Bennett.jl.
Available library source is lifted when that direct route is absent. Native fmod earns
no credit in the figures above. The former recognizer and exact source-lowering
work are tracked by bd 3c6m.68. This recheck removes tainted `frem` from direct
lowering and its generated runtime template inventory; the exact source-lifting
work remains open. The prior native-fmod JSON is historical evidence of the
placeholder behavior, not a current acceptance claim.

The current compiler source contains 31 curated LLVM intrinsic IDs. The source inventory
in `intrinsic_policy_recheck.json` maps the floating-point candidates to named Bennett
primitives where present and records fabs/copysign as bitmask candidates. It is not a
width-by-width semantics certification. Bennett was checked at commit
`3e2a3c7f6fd13db2a6e8f979202500a29c8adca6`; frem appears only in its error-name table,
with no corresponding implementation. Missing backend support must remain separate from
the source-injection loop/control gaps and from physics-forbidden programs.

The authored branchless `fmod` substitute is also not exact: at finite inputs
`x=1.0, y=0.1`, a compiled probe returned zero for `x-trunc(x/y)*y`, whereas
host `fmod(x,y)` returned about 0.1. Its fixtures witness lowering of that
expression, not correctness or coverage of the math.h function. This numerical
gap is recorded on bd 3c6m.68.

## Approximation and authored implementations

The owner accepts the reported accuracy of the current CQ-provided sin approximation
and retains it. Its header's approximate accuracy range is |x| below about 1.65e6;
the measured double leaf disagrees with host sin at 1e20, infinity, NaN and negative
zero. `sin_classical_domain.tsv` records those examples. Retention does not establish
an accuracy proof throughout the stated range or a new gate-level proof.

Hand-authored math bodies can earn CQ-provided coverage when their accepted numerical
contract and all runtime C/Q mixtures are satisfied. Their origin does not disqualify
them, and successful lifting of the upstream implementation remains separately
measured. The six qualified trig cells are already included in the composition above;
additional bodies need per-cell measurement before any further credit is added.

The owner regards the authored substitute slices as low-value tests. The recalled
43 is not a complete current inventory: the tree has 50 branchless slices and one
hybrid slice. No exact deletion set was specified and no slice was deleted. The
current CQ-provider qualification checks depend on matching slices and goldens;
changing test retention must preserve or explicitly replace that evidence. This
scope remains with the recheck issue zxor and census issue 3c6m.49.

## Twin transitions

A decline-to-accept transition remains red until its semantic evidence is reviewed.
The reviewed capability change then updates the expected verdict. Historical declines
do not prohibit valid new capabilities, and twin disagreements remain failures to
investigate. This decision is in CLAUDE.md R10; no matrix expectation was regenerated.
