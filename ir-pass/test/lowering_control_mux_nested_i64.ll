; lowering_control_mux_nested_i64.ll — Family F (WP11), the NESTED-mux-arm case.
; The companion to lowering_control_mux_handles_i64.ll, which only covers a mux
; whose arms are DIRECT `cq_theta` handles. Here the OUTER tainted-condition
; `select`'s arms are the i32-laundered RESULTS of INNER `dissolveSelect`
; reductions of i64 data:
;   r = (p1>0) ? ((p2>0)?qa:qb) : ((p3>0)?qc:qd)   ; qa..qd are i64 cq_theta
; `dissolveSelect` registers each inner reduction's result as tainted but used
; to NEVER record `taint.HandleWidth[Res]` — the only HandleWidth writer was the
; rotation mint (direct theta handles). So for the OUTER mux,
; `taint.HandleWidth.lookup(A/B)` MISSED on the inner results and the width fell
; back to `abiWidthFromType` of the laundered i32 handle type = i32: the outer
; mux emitted `cqrt_alloc_i32(0)` + `cq_template_add_i32_controlled` on i64 data
; — a SILENT width-collapse miscompile (opt -verify clean, no diagnostic; this
; is WP11 reopened for the nested-arm shape). The fix records
; `taint.HandleWidth[Res] = AbiWidth` (the reduction's logical width) on every
; dissolved result, so the OUTER mux recovers i64.
;
; The i32 alloc/compare on the PREDICATE handles (p1/p2/p3 = `cq_theta_si32`) is
; correct — those are genuinely i32 condition values, NOT the i64 data path. The
; CHECK-NOT lines below target only the i64 DATA path: `cqrt_alloc_i32(i32 0)`
; (the fresh both-tainted ancilla seed) and `add_i32_controlled` (the data add),
; neither of which is ever emitted on a correctly-sized i64 mux.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; --- @nested: OUTER mux over two inner i64 reductions (mux.2 → mux.2) ---
; The two inner reductions land first; pin the OUTER mux to i64. The outer is a
; both-tainted mux (both arms are the i32-laundered inner results): fresh i64
; ancilla seeded to 0, then two i64 controlled adds bracketed by `cqrt_x`.
; CHECK-LABEL: @nested
; CHECK:     call i32 @cqrt_alloc_i64(i64 0)
; CHECK:     call i32 @cq_template_add_i64_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cqrt_alloc_i64(i64 0)
; CHECK:     call i32 @cq_template_add_i64_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; The OUTER (third) ancilla + adds are also i64 — the regression point.
; CHECK:     call i32 @cqrt_alloc_i64(i64 0)
; CHECK:     call i32 @cq_template_add_i64_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; No i32 collapse on the i64 DATA path, and the diamond fully dissolves.
; CHECK-NOT: cqrt_alloc_i32(i32 0)
; CHECK-NOT: add_i32_controlled
; CHECK-NOT: select i1
;
; --- @mixed_nested: OUTER mix of a tainted inner reduction + a classical i64
;     arm (mux.2 inner → mux.1 outer). WITHOUT the HandleWidth fix this crashed
;     the verifier ("Broken module": `cq_template_sub_i32_hl(i32 handle, i64 99)`
;     + `cqrt_alloc_i32(i64 99)` type mismatch). With the fix the difference /
;     seed are i64-typed — the second RUN line's `-passes=verify` proves it is
;     verify-clean (no report_fatal_error). ---
; CHECK-LABEL: @mixed_nested
; CHECK:     call i32 @cq_template_sub_i64_hl(i32 %{{[a-zA-Z0-9_.]+}}, i64 99)
; CHECK:     call i32 @cqrt_alloc_i64(i64 99)
; CHECK:     call i32 @cq_template_add_i64_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: select i1

declare i64 @cq_theta_sll(i64, double)
declare i32 @cq_theta_si32(i32, double)
declare i64 @cq_measure_sll(i64)

; long long r = (p1>0) ? ((p2>0)?qa:qb) : ((p3>0)?qc:qd); — all data is i64.
define i64 @nested(i32 %c1, i32 %c2, i32 %c3, i64 %a0, i64 %b0, i64 %cc0, i64 %d0) {
entry:
  %qa = call i64 @cq_theta_sll(i64 %a0, double 1.000000e-01)
  %qb = call i64 @cq_theta_sll(i64 %b0, double 2.000000e-01)
  %qc = call i64 @cq_theta_sll(i64 %cc0, double 3.000000e-01)
  %qd = call i64 @cq_theta_sll(i64 %d0, double 4.000000e-01)
  %p1 = call i32 @cq_theta_si32(i32 %c1, double 5.000000e-01)
  %p2 = call i32 @cq_theta_si32(i32 %c2, double 6.000000e-01)
  %p3 = call i32 @cq_theta_si32(i32 %c3, double 7.000000e-01)
  %cp2 = icmp sgt i32 %p2, 0
  %in1 = select i1 %cp2, i64 %qa, i64 %qb       ; inner mux 1 (both i64 handles)
  %cp3 = icmp sgt i32 %p3, 0
  %in2 = select i1 %cp3, i64 %qc, i64 %qd       ; inner mux 2 (both i64 handles)
  %cp1 = icmp sgt i32 %p1, 0
  %r = select i1 %cp1, i64 %in1, i64 %in2       ; OUTER mux over i64 inner results
  %m = call i64 @cq_measure_sll(i64 %r)
  ret i64 %m
}

; long long r = (p1>0) ? ((p2>0)?qa:qb) : 99; — outer mixes a tainted i64 inner
; result with a classical i64 arm (the verifier-crash repro).
define i64 @mixed_nested(i32 %c1, i32 %c2, i64 %a0, i64 %b0) {
entry:
  %qa = call i64 @cq_theta_sll(i64 %a0, double 1.000000e-01)
  %qb = call i64 @cq_theta_sll(i64 %b0, double 2.000000e-01)
  %p1 = call i32 @cq_theta_si32(i32 %c1, double 5.000000e-01)
  %p2 = call i32 @cq_theta_si32(i32 %c2, double 6.000000e-01)
  %cp2 = icmp sgt i32 %p2, 0
  %in1 = select i1 %cp2, i64 %qa, i64 %qb       ; inner mux -> i64-laundered handle
  %cp1 = icmp sgt i32 %p1, 0
  %r = select i1 %cp1, i64 %in1, i64 99         ; OUTER mixed: tainted + classical i64
  %m = call i64 @cq_measure_sll(i64 %r)
  ret i64 %m
}
