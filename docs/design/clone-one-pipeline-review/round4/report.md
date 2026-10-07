# p3kd.7.8 adversarial review, round 4

Verdict: **ACCEPT** for the two assigned round-2 specialization hypotheses. Both fresh probes reach the intended path and emit the complete shared-stage clone machinery. No introduced miscompile or additional compiler gap was found in this focused round.

Scope: a 6.5 classical-call arm creates a merge rail whose source phi was data-untainted, followed by (1) a newly discovered helper specialization and (2) a helper whose previously planned mask grows. The two helper bodies use compound compare conditions, quantum arithmetic, a controlled-copy select and a nested helper call. These are new subjects; the existing switch fixture was read only to confirm the 6.5 owner shape. Its body and its lowering were not rerun.

Reviewed implementation remains `bae428e83b20eab2c68a9481e6fe4b6131c09957` with coordinator comment fixes only. Ordinary cq-opt SHA-256: `578879a5c958ea019d7cde1b2e2704ef6dcd79144c04c39f660a8b2c74392eef`. All primitives in the probes use the correct `cq_theta_si32`/`cq_measure_si32` spelling.

## Invocation count and results

**2/2 new cq-opt executions**, each once, with stdout/stderr and output IR saved beside its source in `/tmp/p3kd78-review-r4`. No lit, ctest, repository fixture/corpus lowering, rebuild, source edit, additional lowering probe, or runtime execution was performed.

Commands:

```
build/ir-pass/cq-opt -passes=cq-lowering -S /tmp/p3kd78-review-r4/p1_new_candidate.ll -o /tmp/p3kd78-review-r4/p1_new_candidate.lowered.ll
build/ir-pass/cq-opt -passes=cq-lowering -S /tmp/p3kd78-review-r4/p2_grown_mask.ll -o /tmp/p3kd78-review-r4/p2_grown_mask.lowered.ll
```

Both exit 0 with empty stderr. Acceptance is based on the following basis-state and dependency arguments, not on verifier success.

## P1: a newly discovered round-2 helper runs the shared control stages

The source caller computes `choice = q > 7 ? (k xor 90) : 17`, then calls `new_helper(choice)`. Both phi incoming values are classical, so ordinary forward SSA taint cannot reach the phi or helper call before emission: the quantum branch condition is not a data operand of the phi. The arm call is visible, pure and total (wrapping XOR, with nounwind/willreturn/memory(none)); unconditional hoisting is sound.

The lowered caller materializes the two classical branch values, writes a fresh i32 `%out` under the appropriate condition, strips the condition flag, and passes `%out` to `__cq_q_new_helper_1` (`p1_new_candidate.lowered.ll:33-44`). The helper was not a round-1 candidate and could only become quantum after the merge rail's reseed. The caller measures the clone result (`:45`); no source measurement was added.

On a basis label v, the helper computes

```
d = [signed(v) > -11] AND [unsigned(v) < 37]
s = d ? (v xor 255) : v
result = 5*s + 2  (mod 2^32)
```

The clone emits the XOR rail, both exact compare predicates/constants, a zero-initialized i1 ancilla and Toffoli conjunction (`:66-70`), then controlled copies of XOR or v (`:71-74`). After the second copy its conjunction rail holds NOT d. It calls the nested `finish_value_1` with this i32 merge rail (`:75`), copies the nested result into its fresh escaping out (`:76-77`), and invokes the nested twin before disturbing the merge rail (`:78`).

The mirror first clears the NOT-d branch copy, restores d with X, then clears the d branch copy (`:79-81`). Toffoli clears the conjunction ancilla; the two compare adjoints then clear their flags, followed by XOR's adjoint (`:82-85`). Thus all six scratch rails freed at `:86-91` are zero. None of those frees or gate write targets names borrowed `%v`; the escaping `%cqq.out` is never reversed or freed.

The nested forward and twin compute the same `5*s+2`, using unchanged s and the same runtime-template literals, and each reverses add before multiply (`:104-114`, `:126-135`). The twin XOR-copy clears the existing nested result; the outer reverse therefore frees that result safely after clearing its inputs. This is concrete dynamic evidence that a round-2-created clone uses the shared condition-network/control-copy machinery and the full mechanical reverse.

## P2: a round-1 mask grows from 10 to 11

The second caller computes `choice = q > 13 ? (k+9) : -4` and calls `growing_helper(choice, second)`, where second is an independent `cq_theta_si32` result. Before merge emission, only argument 1 is data-tainted, so the planned mask is 10. The visible arm call is wrapping addition and total; the same 6.5 source-untainted phi argument applies.

The final caller passes its new merge `%out` and the independent `%h2` to `__cq_q_growing_helper_11` (`p2_grown_mask.lowered.ll:34-45`). The lowered module contains no `_10` version. Crucially, the helper computes its mixed arm with `cq_template_xor_i32(i32 %a, i32 %b)` (`:67`): both inputs are quantum handles. No `%out` handle reaches a classical `_hl` slot, which is the silent-miscompile hazard a stale mask would cause.

For basis labels a,b, the helper computes

```
d = [signed(a) < 64] AND [unsigned(b) < 11]
s = d ? (a xor b) : b
result = s xor 682
```

The two flag mints read a and b with their specified predicates, the Toffoli creates d, and controlled copies form s (`:68-75`). The nested forward result is copied out and cleared by its twin before s changes (`:76-79`). The reverse then clears both branch copies in the proper polarity, clears the conjunction, clears the flags, and finally zeroes the QQ XOR scratch (`:80-86`). Each free at `:87-92` names scratch. Borrowed `%a` and `%b` remain unchanged even though b is used both by its compare and by the false-arm copy.

The nested `finish_pair_1` and twin apply the same XOR-682 template and reverse it after their copy (`:109-116`, `:124-130`). Every data rail and copy in these helpers has logical width i32; only condition ancillas use i1 allocation. No i32 handle is mistaken for a classical value.

## Why both round-2 paths enter the same stage driver

`ClassicalCallArmEmit.cpp:214-233` inserts each merge out into Tainted, ControlOwnedRails and UntaintedMergeRails and records its logical width. `repropagateControlMerges` seeds the shared propagation worklist from those out rails (`TaintPropagation.cpp:2740-2744`), then collects the full reseed domain after onward control (`:2777-2781`) and calls `adjudicateTaintDelta` (`:2819`). That function replans existing candidates and detects new ones in the same persistent plan (`:2658-2659`).

For the grow case, `replanReseedSpecialization` recomputes the call mask from current taint, reclassifies the grown mask and updates the candidate (`:2512-2525`). New detection skips already-pending sites and admits a newly tainted visible-body call through the ordinary candidate classifier (`SpecializeDetect.cpp:284-363`). The subsequent module `specialize` occurs after `runControlChain` (`CQLoweringPass.cpp:612`, `:736`), so both records are complete before cloning begins.

Every cache miss uses the one `buildClone`, which calls `lowerCloneControl` unconditionally before data lowering (`Specialization.cpp:552-573`). That driver runs the shared loop prepasses (`:246`), followed by the shared control chain (`:284`); the latter includes the onward-taint fixpoint and re-asks. There is no alternative stage list chosen by whether a candidate was initially present, newly discovered, or replanned. The emitted compare/Toffoli/select networks in both probes witness this for these two round-2 populations. Nested helpers use the same build path and resolve their twins before the outer reverse.

## Limits

This round closes the dynamic evidence gap for round-2 new candidates and grown masks reached through the 6.5 emitter. Neither probe contains a loop or floating-point slot, so they do not add evidence about rolled clone reversal, f80 signature replacement or allocator reuse; those remain the other rounds' scopes. Caller-side control-owned merge rails and classical materialization rails remain allocated under the existing main policy. This report does not clear main's known dirty-rail leak population or claim every shared stage did nontrivial work in these loop-free bodies.

Final focused verdict: **ACCEPT**. No earlier main-stage blocker was encountered, no new issue was found, and the exact count is **2 cq-opt invocations**.
