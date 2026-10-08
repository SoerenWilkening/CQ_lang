# R11 analytic follow-up — early scalar raw-constant stabilization

Disposition: no new correctness blocker found in the narrow correction. Zero tests, builds, mutations, cq-opt executions or targeted probes. This report reviews the intended `slotCarriesUndef(K)` predicate; the deliberately disabled mutation is not the reviewed implementation.

## Findings first

No new finding. Retain the existing cross-function undef duplication fence: one freeze in a function is not a proof that separate clone and uncompute-twin invocations select the same arbitrary value. `ensureTwin` uses `findUndefOperandInBody`, which still sees a poison/undef operand of a FreezeInst. This correction does not remove that fence or close the full p3kd.7.7 issue.

## Correctness argument

The old late scan could lose a raw constant when its marked quantum consumer was replaced by an emitted call. The new marker visits scalar source operand Uses before that replacement. An undef/poison-bearing scalar constant is replaced in that particular Use with a defined freeze value. This includes the new main fixture where the merged result escapes and the one unconditional xor literal has no guaranteed inverse slot; fixing it does not depend on there being two emitted slots.

`stableConstant` creates an entry-block freeze of the typed constant. Entry insertion dominates moved scalar consumers and surviving source uses. Caching is confined to the function and compares the actual typed Constant pointer on compiler-created freeze instructions; one constant can therefore serve multiple moved operands in that function, while another function receives its own SSA definition. No Constant RAUW reaches unrelated functions, constant expressions or global initializers. The existing slot owner intentionally ignores undef in a global object's initializer when the value being used is its defined address.

Sharing one arbitrary defined choice for separate undef uses restricts the behavior allowed by undef and is an LLVM refinement. A poison source constant on an unselected edge cannot reach the fixed script as a raw gate operand. On source-defined selected paths, defined operands remain unchanged. The emitted script uses an ordinary scalar SSA value; no runtime execution log, interpreter or reversal mechanism is introduced.

The private cache tag prevents walking into the compiler-created freeze and recursively replacing its own poison operand. Final stabilization clears that tag without replacing the freeze. `definedWithoutContext` already treats FreezeInst as a defined leaf, so the late phase does not create a second freeze. Forward/adjoint uses emitted into that same function receive the same SSA operand. The dependency marker's existing source-domain traversal and taint owners continue to determine whether an operand is a scalar literal or a quantum source; no emitted i32 handle guessing is added.

## Fixture and scope

Read the intended source diff and `spec_predmux_stable_raw_constant.ll` only. Its two functions share LLVM's typed poison constant but require distinct local freezes; checks pin one freeze, the xor gate operand and absence of raw poison at emitted calls. No fixture execution was performed. Existing dirty/live graph ownership and absence of an inverse for an escaping main result are not broadened by this constant correction. Clone/twin raw-constant duplication retains its separate loud fence. No census gain is inferred.
