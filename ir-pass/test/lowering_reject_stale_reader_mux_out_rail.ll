; lowering_reject_stale_reader_mux_out_rail.ll — DECLINE (bd
; test_C_libtooling-3d8q, P1). THE `MergePhiPeel` / MUX OUT-RAIL CUSTOMER: two
; sibling in-place Ry on one DERIVED rail, both measured.
;
;   int q=0; q=cq_theta(q,0.3); int m=q+1;
;   int r1=cq_theta(m,0.2); int r2=cq_theta(m,0.6);
;   printf("%d\n", cq_measure(r1)+cq_measure(r2));
;
; That is `review_b6ap_r2_probes/S04_sibling_plain_oracle.c` — the CONTROL that
; says the class is PRE-EXISTING and not the peel's: it reproduces on plain `main`
; with NO peel at all, at 8 trace lines on the frozen session ORACLE. Its peeled
; sibling `S03_stale_mux_sibling.c` is the same two rotations on a peeled mux
; out-rail (35 lines, ORACLE), and both decline here. bd b6ap's round-2 finding
; F-B6R2-2 filed them against 3d8q rather than against the peel for exactly this
; reason.
;
; `%m` is a `cq_template_add_i32_hl` rail; `%r1` and `%r2` are two in-place Ry on
; IT, so the source names two different states of one register (Rule 8) and the
; emitted stream can only be one of them. Reduced to hand IR here, with the
; `printf` dropped so the 7.6 I/O tape is not also in the picture — the readers
; and the verdict are unchanged (measured on the .c probe).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: rotation/measure operand predates a non-diagonal gate

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q  = call i32 @cq_theta_si32(i32 0, double 3.000000e-01)
  %m  = add i32 %q, 1
  %r1 = call i32 @cq_theta_si32(i32 %m, double 2.000000e-01)
  %r2 = call i32 @cq_theta_si32(i32 %m, double 6.000000e-01)
  %a  = call i32 @cq_measure_si32(i32 %r1)
  %b  = call i32 @cq_measure_si32(i32 %r2)
  %s  = add i32 %a, %b
  ret i32 %s
}
