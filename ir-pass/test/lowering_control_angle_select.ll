; lowering_control_angle_select.ll — Family B1 (WP9), negative. `-O1` sinks a
; tainted `if (u > 5) { u = rz(u, a); } else { u = rz(u, b); }` into
; `rz(u, select(u>5, a, b))` — a tainted-condition `select` over the CLASSICAL
; `double` rotation angle. The SelectRegion admission gate used to exclude only
; `i1`-typed selects, so it admitted this fp select as a data mux;
; `dissolveSelect` then emitted an integer `sub`/`add` on the `double` value and
; rewrote the `cq_phi` angle to an i32 handle → a broken module (verifier
; abort). WP9 excludes a select whose value type is not an integer HANDLE width
; (`double` is a valid f64 ABI width but never a handle) and diagnoses loudly;
; WP10 lowers it as controlled-rotation-by-difference. No data-mux symbol is
; emitted for the fp select (the region is skipped before dissolution).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %u, 5
  %ang = select i1 %c, double %a, double %b      ; angle under quantum control
  %r = call i32 @cq_phi_si32(i32 %u, double %ang)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
