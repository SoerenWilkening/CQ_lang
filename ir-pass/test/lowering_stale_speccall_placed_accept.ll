; lowering_stale_speccall_placed_accept.ll — ACCEPT (bd test_C_libtooling-r2j3.6;
; owner ruling bd 57ch (A), the lifted-call slice).
;
; A lifted (Phase-6 specialized) call READS ITS QUANTUM ARGUMENT WHERE IT RUNS: the
; clone copies the argument register's basis label into its own rails at the call
; (Bennett.jl `lower_call!`, src/lowering/call.jl:140-147 @824458d: "Connect caller
; arguments -> callee input wires (CNOT copy)"). Here the call reads `q`, the PRE-Ry
; record, after `cq_theta(&q2, .3)` rotated that same register in place.
;
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(void) {
;     int q = 0; cq_theta(&q, .5);
;     int q2 = q; cq_theta(&q2, .3);   // in-place Ry on q's register
;     int r = f(q);                    // reads the PRE-Ry record
;     return (int)cq_measure(r) + (int)cq_measure(q2);
;   }
;
; Before r2j3.6 this lowered at exit 0 with `__cq_q_f_1(h)` AFTER `ry(h, .3)`: f ran on
; the rotated register, byte-identical to `int r = f(q2)` — a verify-clean silent
; miscompile. The call is movable (its operand dominates the gate, nothing between
; them conflicts with it), so the 57ch(A) placement emits it just BEFORE the gate:
; an entangling basis-label copy, no clone and no measurement. The stream is the one
; the program written in the non-stale order lowers to
; (lowering_stale_speccall_call_before_theta_accept.ll pins that twin with the same
; CHECK chain). The CHECK-NEXT chain is the load-bearing order: the clone call
; between the two Ry.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @main()
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK-NEXT: %[[R:.*]] = tail call i32 @__cq_q_f_1(i32 noundef %[[H]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])

define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main() local_unnamed_addr #1 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %2 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 3.000000e-01) #2
  %3 = tail call i32 @f(i32 noundef %1)
  %4 = tail call i32 @cq_measure_si32(i32 noundef %3) #3
  %5 = tail call i32 @cq_measure_si32(i32 noundef %2) #3
  %6 = add nsw i32 %5, %4
  ret i32 %6
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
