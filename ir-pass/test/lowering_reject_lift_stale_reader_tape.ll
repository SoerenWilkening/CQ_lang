; lowering_reject_lift_stale_reader_tape.ll — DECLINE (bd test_C_libtooling-r2j3.12,
; P1 silent miscompile on main 7b4e6359). `clang -O1` of
;
;     int q = 7; cq_theta(&q, .5);
;     int r = q;
;     if (c) { cq_theta(&q, .125); r = q; cq_theta(&q, .25); }
;     printf("%d\n", r);
;     return cq_measure(q);
;
; The output-tape twin of lowering_reject_lift_stale_reader_measure.ll. `r` names
; the record between the two arm gates; on the arm path the tape write records a
; wire `Ry(.25)` has moved past. Main emitted `ry .5; ry .125; ry .25;
; tape_write(h); measure(h)` at rc 0, empty stderr: the IOSinkLowering lineage
; fence runs before the one-register lift and sees only the phi. Since bd r2j3.12
; the post-lift reader re-ask asks an emitted `cqrt_tape_write_<W>`'s source slot
; as a reader too, under the same per-use exemption (`r`'s record holds `%6`;
; `%7` is evidence). Accept twin: lowering_lift_reader_tape_accept.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: output-tape operand predates a non-diagonal gate

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

define i32 @f(i32 noundef %0, i32 %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 5.000000e-01)
  %4 = icmp eq i32 %0, 0
  br i1 %4, label %8, label %5

5:                                                ; preds = %2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 1.250000e-01)
  %7 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.500000e-01)
  br label %8

8:                                                ; preds = %5, %2
  %9 = phi i32 [ %7, %5 ], [ %3, %2 ]
  %10 = phi i32 [ %6, %5 ], [ %3, %2 ]
  %11 = tail call i32 (ptr, ...) @printf(ptr noundef nonnull dereferenceable(1) @.str, i32 noundef %10)
  %12 = tail call i32 @cq_measure_si32(i32 noundef %9)
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare noundef i32 @printf(ptr nocapture noundef readonly, ...)

declare i32 @cq_measure_si32(i32 noundef)
