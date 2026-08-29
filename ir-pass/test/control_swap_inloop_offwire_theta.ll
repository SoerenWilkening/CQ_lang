; control_swap_inloop_offwire_theta.ll — ACCEPT (bd test_C_libtooling-8h7d.5,
; Rule-13 round 1, finding OD1). The staleness test that gates the Increment-3
; record-refresh barrier is now PER WIRE.
;
;     q = cq_theta(q0, g);
;     z = cq_theta(0, 0.125);        // a SECOND, UNRELATED register
;     for (...) { if (q > 5) q = cq_phi(q, b); q = cq_theta(q, 0.25); }
;
; This is control_swap_inloop_post_region_theta.ll with one extra register minted
; after the first. It DECLINED at ba35c1f with "condition predates a non-diagonal
; gate under quantum control", because `WireWalk::phiTracksWire` asked
; `isAnyThetaCall` — ANY `cq_theta` between an incoming's definition and its edge
; refused the barrier, regardless of which wire that theta rotates. `%z` rotates
; nothing on `%q`'s wire, so the refusal was pure source ORDER: moving the `%z`
; mint above the `%q` mint made the identical program compile. That also made two
; independent registers, each with its own tainted `if` in one loop, permanently
; unlowerable.
;
; The test now asks whether the theta's arg-0 handle lies in the INCOMING's own
; wire closure (`collectWireValues` — the same backward-ancestry + forward
; in-place-gate closure `findNonDiagonalWireGate` already walks, Rule 14).
;
; THE NEGATIVE TWIN IS lowering_reject_stale_record_loop_nontracking_phi.ll, where
; the theta IS on the phi's wire and must still refuse the barrier. It stays RED.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0, double %a) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %z  = call i32 @cq_theta_si32(i32 0, double 1.250000e-01)   ; unrelated register
  br label %head

head:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %q = phi i32 [ %q0, %entry ], [ %w, %latch ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %latch

arm:
  %g = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %latch

latch:
  %p = phi i32 [ %g, %arm ], [ %q, %head ]
  %w = call i32 @cq_theta_si32(i32 %p, double 2.500000e-01)
  %inext = add nsw i32 %i, 1
  %done = icmp eq i32 %inext, 4
  br i1 %done, label %out, label %head

out:
  %m = call i32 @cq_measure_si32(i32 %w)
  %m2 = call i32 @cq_measure_si32(i32 %z)
  %s = add i32 %m, %m2
  ret i32 %s
}

; Two rails, minted outside; the ROLLED per-iteration stream on the first:
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Z]], double 1.250000e-01)
; CHECK:     head:
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_cswap(i32 %[[F]], i32 %[[H]], i32 %{{.*}})
; CHECK:     call void @cqrt_rz_i32(i32 %{{.*}}, double %a)
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:     out:
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[H]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Z]])
;
; CHECK-NOT: condition predates a non-diagonal gate
