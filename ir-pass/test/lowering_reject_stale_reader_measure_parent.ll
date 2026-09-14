; lowering_reject_stale_reader_measure_parent.ll — DECLINE (bd
; test_C_libtooling-3d8q, P1). THE `cq_measure` HALF, in its smallest form:
;
;   int q=cq_theta(0,0.3); int a=cq_theta(q,0.5); return cq_measure(q)+a;
;
; `%a` CONSUMES the name `%q` (`docs/frontend.md` §3.2), so `cq_measure(%q)`
; scheduled after it names the pre-Ry record while the register holds the post-Ry
; one. This is the PARITY fixture: the pure-op spelling of the identical program
; — `int d=q+1;` in place of the measurement — has declined since Phase 5 at
; `declineStaleRecordOps` with `cq opcode lowering: operand predates a
; non-diagonal gate` (`lowering_reject_stale_record_add.ll`), and the whole of bd
; 3d8q is that one word of difference deciding a silent miscompile.
;
; ⚠ THE MEASUREMENT IS NOT EXEMPT, and the old argument that it was ("a measure
; reads the wire in place, so there is no stale-record hazard") is retired with
; `lowering_bitcast_measure_after_rerotate.ll` — read that file's header before
; re-opening this.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq opcode lowering: rotation/measure operand predates a non-diagonal gate

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 3.000000e-01)
  %a = call i32 @cq_theta_si32(i32 %q, double 5.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %m, %a
  ret i32 %s
}
