; control_classical_call_arm_accept_frozen_nsw_add_arg.ll — ACCEPT (bd 9hea).
; ARM: the exact shape bd 9hea was filed for — `if (q > 5) y = ext_f(u + 1);`,
; ordinary C, which DECLINED before the `freeze` remedy.
;
; WHY IT DECLINED, AND WHY THAT WAS A REAL COST RATHER THAN A CORNER. `clang -O1`
; stamps `nsw` on the `add`, which makes it POISON-CAPABLE, and stamps `noundef` on the
; callee's parameter as a matter of course for a scalar. So the bd wve8 argument clause
; refused it: passing poison to a `noundef` parameter is immediate UB, and the 6.5
; hoist manufactures that UB on a program whose quantum guard excluded the call.
;
; *** THE COST WAS INVISIBLE TO THE CORPUS THAT CLEARED THAT CLAUSE, WHICH IS THE PART
; WORTH REMEMBERING. *** Every 6.5 call site in the entire corpus — 12 e2e sites, 25+
; fixtures — passes a CONSTANT argument, so "zero corpus cost" was TRUE AND
; UNINFORMATIVE: the corpus was invariant on the exact axis the gate reads. The cost
; took one probe to find. Before quoting a zero, ask what the corpus VARIES.
;
; This row differs from `..._accept_frozen_poison_arg.ll` in the poison SOURCE: there
; a `shl` by a register (inherent poison, no flag to drop), here an `add nsw` (poison
; by ANNOTATION). Both are discharged the same way and neither is discharged by
; dropping the flag — commit 9dc909e established that flag drops have a live
; decline->ACCEPT inverter in `Fp80Union.cpp`'s `PaddingWalk`, which reads
; `nsw`/`nuw`/`exact` as blockers. `freeze` ADDS a fact; a drop REMOVES one.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; `ext_f` stands in for the other-TU callee of the 9hea report; the e2e layer
; llvm-links every TU before the single cq-lowering run, so a real slice sees a body
; exactly like this one.
define internal i32 @ext_f(i32 noundef %a) #0 {
  %t = mul i32 %a, 3
  ret i32 %t
}

define i32 @example(i32 noundef %u0, i32 noundef %u) {
entry:
  %arg = add nsw i32 %u, 1          ; clang -O1's `u + 1`: poison-capable via nsw
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @ext_f(i32 noundef %arg)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}

attributes #0 = { nounwind willreturn memory(none) }

; The `nsw` add is left ALONE (no flag drop) and the hoisted call reads a FROZEN copy:
; CHECK: add nsw i32 %u, 1
; CHECK: %[[FR:[a-zA-Z0-9_.]+]] = freeze i32 %arg
; CHECK: call i32 @ext_f(i32 noundef %[[FR]])

; ...and the region lowers as an ordinary 6.5 classical-call arm:
; CHECK: cq_template_icmp_sgt_i32_hl
; CHECK: cqrt_copy_i32_controlled
; CHECK: cqrt_free
