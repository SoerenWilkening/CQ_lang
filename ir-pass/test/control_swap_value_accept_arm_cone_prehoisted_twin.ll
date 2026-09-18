; control_swap_value_accept_arm_cone_prehoisted_twin.ll — the PRE-HOISTED TWIN of
; control_swap_value_accept_arm_cone.ll (bd test_C_libtooling-fn1q, increment 1).
;
; THE SAME PROGRAM with the classical cone written in the PRED instead of the arm.
; It accepted BEFORE the increment and accepts after it, and the two files' lowered
; streams are BYTE-IDENTICAL — which is why the `CHECK` block below is a verbatim
; copy of its twin's.
;
; ⚠ THIS PAIR IS THE INCREMENT'S CORRECTNESS INSTRUMENT, and it is the RIGHT one
; precisely because the cone emits NO GATE. A hoist that reordered, duplicated or
; dropped a cone member would be invisible to a trace (classical IR prints
; nothing) and invisible to `free_pairing_check.py` (no rail is minted for it);
; identity against a form the compiler ALREADY lowered, through the same cleared
; 4.4 `SelectMergeEmit`, is what can see it.
;
; ⚠ AND IT IS NOT AN IDLE COPY: the twin is the file that goes RED if the hoist
; ever changes the stream for the pre-existing population. Its `CHECK` block must
; be kept character-for-character equal to its twin's — if a future change makes
; them diverge, that divergence IS the finding, not a fixture to re-derive.
;
; ⚠ RETIREMENT TRIGGER: if `clang -O1` ever stops SINKING a pred-computed
; classical value into a tainted-condition arm, this twin stops being reachable
; from C and becomes an IR-only control. It stays either way — do not delete it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; ⚠ THE IDENTITY IS ASSERTED MECHANICALLY, NOT BY TWO `CHECK` BLOCKS THAT HAPPEN
; TO AGREE. Two copies of a prefix can both go green on two DIFFERENT streams
; (each prefix only pins what it names); a `diff` of the two lowered FUNCTION
; BODIES cannot. This is the one extra `cq-opt` spawn in the pair and it is what
; the pair is for. It also means a future divergence shows up as a diff, with the
; offending line, rather than as "the twin's CHECK block needs re-deriving".
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %S/control_swap_value_accept_arm_cone.ll > %t.subject.ll
; RUN: sed -n '/^define/,/^}/p' %t.cqd0.ll > %t.twin.body
; RUN: sed -n '/^define/,/^}/p' %t.subject.ll > %t.subject.body
; RUN: diff %t.twin.body %t.subject.body
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; Counts live in their own whole-file prefixes — a positive COUNT inside a
; negative prefix WINDOWS every negative after it (the bd drbq Inc-4 lens).
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CONECNT < %t.cqd0.ll
@k = global i32 0
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %kk = load i32, ptr @k, align 4   ; the cone, written in the PRED by hand
  %k1 = mul i32 %kk, 3
  %k2 = add i32 %k1, 7
  %k3 = xor i32 %k2, 5
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = add i32 %p, %k3             ; the Q+C CHAIN link — the cone is ALREADY
                                    ; in the pred, so this arm needs no hoist
  br label %merge
merge:
  %pm = phi i32 [ %v1, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; THE WHOLE STREAM, CONTIGUOUS. `CHECK-NEXT` adjacency from the first alloc to the
; measure is the contract, not decoration: symbol ORDER cannot see an insertion,
; adjacency can (the Inc-2 round-1 review's finding F-V2-5, and it applies with
; extra force here because the cone lines are the ones a regression would move).
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double 2.500000e-01)
; THE CONE, HOISTED INTO THE PRED IN BLOCK ORDER, still ORDINARY CLASSICAL IR.
; It mints no handle, allocates no rail and emits no gate — pinning it here is
; what says the hoist happened rather than the ops having been dropped (Rule 5:
; a silently dropped arm op is the stray rule's original hazard).
; CHECK-NEXT: %[[KK:[a-zA-Z0-9_.]+]] = load i32, ptr @k
; CHECK-NEXT: %[[K1:[a-zA-Z0-9_.]+]] = mul i32 %[[KK]], 3
; CHECK-NEXT: %[[K2:[a-zA-Z0-9_.]+]] = add i32 %[[K1]], 7
; CHECK-NEXT: %[[K3:[a-zA-Z0-9_.]+]] = xor i32 %[[K2]], 5
; the hoisted chain link, reading the hoisted cone value as its CLASSICAL operand
; — `_hl`, so the classical side stays a plain i32 and is never allocated a rail
; (the "do NOT promote a classical operand to a qubit handle" prohibition).
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[P]], i32 %[[K3]])
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[V]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[P]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK-NEXT: ret i32 %[[M]]

; NO ROUTE, NO CONTROLLED TWIN OF THE ARM'S OWN GATE, and no rail minted for the
; classical cone — the merge is a controlled BASIS COPY into a fresh |0> rail.
; This prefix is PURE: no positive directive may be added to it.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cq_template_add_i32_hl_controlled
; NOROUTE-NOT: cqrt_alloc_i32(i32 %k3
; NOROUTE-NOT: cqrt_alloc_i32(i32 %kk
; NOROUTE-NOT: cqrt_rz

; EXACT COUNTS, one symbol per whole-file prefix.
; ⚠ THE `call ` PREFIX IS LOAD-BEARING: a bare symbol name also matches the
; module's `declare` line, which made the first spelling of this prefix fail on a
; correct stream.
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT: call void @cqrt_free(
; CCNT-COUNT-2: call void @cqrt_copy_i32_controlled(
; CCNT-NOT: call void @cqrt_copy_i32_controlled(
; The cone is hoisted ONCE and not duplicated per copy slot — a cone cloned into
; both merge arms would be invisible to every prefix above (both would still
; match) and is exactly the shape a careless hoist produces.
; CONECNT-COUNT-1: load i32, ptr @k
; CONECNT-NOT: load i32, ptr @k
