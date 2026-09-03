; control_angle_select_reject_inplace_alias_base.ll — DECLINE (S8, and it is a
; TRUE POSITIVE rather than an over-decline): base and condition share a rail
; through an M-C IN-PLACE `xor` (bd drbq Inc 2b; the select form of
; `control_inplace_ry_reject_inplace_alias_base.ll`).
;
;     int b = q ^ 2;
;     b = cq_theta(b, q > 5 ? .9 : .3);
;
; `q ^ 2` has an in-place ABI (`cqrt_xorc_<W>`) and the M-C fence in `lowerOps`
; really does take it in place here, so `%b` and `%q` end up as ONE physical
; rail. The in-place Ry therefore relabels the very register the flag was minted
; from, and the strip is invalid — a dirty free of an entangled ancilla.
;
; THIS IS THE FIXTURE THAT MAKES S8 NON-VACUOUS. `railWireClosure` crosses
; `add`/`sub`/`xor` with one tainted operand in BOTH directions because whether
; the op lowers in place is decided by M-C in `lowerOps`, long after detection —
; so the closure is deliberately conservative. Most shapes it catches on that hop
; are over-declines; THIS one is not, and the message it fires is S8's own
; (`rotation arm on a condition wire`), not gate 2c's — the `xor` is not a
; rotation, so `findNonDiagonalWireGate` does not see it and prong (a) passes.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation arm on a condition wire under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %b = xor i32 %q, 2
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %b, double %ang)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
