# Independent analytic follow-up: raw scalar constants

No correctness blocker found in the proposed `stableConstant` / `markSpeculatedValue` changes. Reviewed the intended `slotCarriesUndef(K)` condition; the temporarily disabled mutation condition is not part of this assessment. Executions: **0 tests, 0 builds, 0 lowering probes, 0 mutations**.

`stableConstant` creates an exact-type freeze in the owning function's entry block before its first ordinary instruction. Its only operand is a constant, so insertion has no dependency-order requirement and the freeze dominates the moved source uses and later forward/inverse calls. Reuse requires both the private tag and exact constant identity in this same function. LLVM's module-uniqued constant therefore receives separate local SSA definitions in the two functions of the fixture.

The dependency walk changes the particular source operand `Use`, not all users of the constant. This avoids rewriting other functions, constant expressions or global initializers. Replacing the raw source operand before quantum data lowering also avoids relying on metadata surviving erasure of the original quantum instruction. The tagged freeze is excluded from subsequent dependency traversal, preserving its raw constant operand and preventing recursive normalization.

The inserted freeze remains classical: its constant operand has no taint source. Its LLVM type preserves the literal's exact source width. Clearing the private tags after lowering does not delete or replace the freeze. Main's adjoints retain the same SSA literal; the clone capture skips the non-call freeze while mechanically emitted inverse gates use its dominating SSA result.

This assessment concerns the within-function gate stream and the proposed raw-constant normalization. It does not claim general cross-invocation stability: the existing `findUndefOperandInBody` / `ensureTwin` fence still detects a raw poison/undef operand inside a freeze before duplicating it into a synthesized external uncompute twin, producing a loud compiler gap instead of granting unsupported twin semantics.

The new fixture pins an escaping raw-literal gate in main and function-local isolation for a second function sharing LLVM's typed poison constant. It is not an adjoint-pairing or clone-twin acceptance witness. No implementer test or completed p3kd.7.8 validation was repeated.
