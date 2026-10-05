; loop_caseA_postloop_region_handoff.ll — ACCEPT (bd test_C_libtooling-wt8u).
; `clang -O1` output (attributes and metadata dropped) of
;
;     int slice(int n) {
;       int q = 0; cq_theta(&q, .5);
;       int r = 0; cq_theta(&r, .25);
;       cq_theta(&r, q == 5 ? .9 : .3);                  // T: the angle select
;       for (int i = 0; i < n; i++) cq_theta(&r, .1);    // Case-A writer loop
;       if (q == 3) cq_theta(&r, .2);                    // post-loop controlled Ry
;       return cq_measure(q) + cq_measure(r);
;     }
;
; `@slice_plain` is the same without `T`.
;
; THE DEFECT (main 7b4e6359, both declined `control flow under quantum
; control`). `tryCaseA`'s fixpoint grew the loop's rail over the WHOLE function:
; (a) absorbed the arm's in-place gate `theta(%exit, .2)` and (b) the region's
; merge φ `phi [%arm, %then], [%exit, %pred]` (both incomings peel to the root
; mint), and the accept then RAUW'd that merge φ to the root. Detection saw a
; tainted diamond with no merge φ and `classifyArms` declined at its first line.
; The hazard behind the over-decline is a VALUE arm's: (a) also absorbed an arm
; `xor` and the accept MARKED it in place (`markInPlaceRailOp`), i.e. an
; unconditional `cqrt_xorc` on r's handle for an op the source runs only when
; q == 3. Only the missing merge φ stood between that mark and the backend
; (`loop_caseA_postloop_region_handoff_reject_value_arm.ll`).
;
; THE FIX. A rail value's consumer that is under tainted control
; (`instUnderTaintedControl`, outside `L`) or a φ merging tainted control is
; the CONTROL CHAIN's, not the loop's: the fixpoint does not absorb it and the
; CLOSURE accepts it as a hand-off. The loop collapses as before (header φ and
; the zero-trip exit φ onto the root mint), so the region reads r's ONE handle
; at its own position, exactly as the no-loop spelling does. The record-
; liveness fence still asks every hand-off read positionally (a hand-off is a
; non-member reader), which is what keeps the stale-alias neighbour loud:
; `loop_caseA_postloop_region_handoff_reject_stale_alias.ll`.
;
; TRACE ARGUMENT for `@slice`, hand-derived (h_q, h_r the two registers):
;   Ry(h_q,.5); Ry(h_r,.25)                               — the two mints
;   Ry(h_r,.3); f1 = [q==5]; CRy(f1,h_r,.6); unc f1; free — T by difference
;   loop: Ry(h_r,.1) x n                                   — rolled in place
;   f = [q==3]; CRy(f,h_r,.2); unc f; free f               — the region, after
;   measure(h_q); measure(h_r)                               the loop, on h_r
; Every rotation is about Y on h_r, so the state is Ry(.25+.3+.6[q==5]+.1n
; +.2[q==3]) on h_r controlled by h_q's basis value — the source's semantics.
; The flag is computed from h_q, which no gate touches after its mint, so each
; `_unc` returns its flag to |0> before the free (R5). Linked and run from C
; (n = 3): the trace is exactly that stream, stage 2b `0 violation(s)`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @slice(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01)
  %4 = icmp eq i32 %2, 5
  %5 = select i1 %4, double 9.000000e-01, double 3.000000e-01
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef %5)
  %7 = icmp sgt i32 %0, 0
  br i1 %7, label %11, label %8

8:
  %9 = phi i32 [ %6, %1 ], [ %14, %11 ]
  %10 = icmp eq i32 %2, 3
  br i1 %10, label %17, label %19

11:
  %12 = phi i32 [ %15, %11 ], [ 0, %1 ]
  %13 = phi i32 [ %14, %11 ], [ %6, %1 ]
  %14 = tail call i32 @cq_theta_si32(i32 noundef %13, double noundef 1.000000e-01)
  %15 = add nuw nsw i32 %12, 1
  %16 = icmp eq i32 %15, %0
  br i1 %16, label %8, label %11

17:
  %18 = tail call i32 @cq_theta_si32(i32 noundef %9, double noundef 2.000000e-01)
  br label %19

19:
  %20 = phi i32 [ %18, %17 ], [ %9, %8 ]
  %21 = tail call i32 @cq_measure_si32(i32 noundef %2)
  %22 = tail call i32 @cq_measure_si32(i32 noundef %20)
  %23 = add nsw i32 %22, %21
  ret i32 %23
}

define i32 @slice_plain(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01)
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 2.500000e-01)
  %4 = icmp sgt i32 %0, 0
  br i1 %4, label %8, label %5

5:
  %6 = phi i32 [ %3, %1 ], [ %11, %8 ]
  %7 = icmp eq i32 %2, 3
  br i1 %7, label %14, label %16

8:
  %9 = phi i32 [ %12, %8 ], [ 0, %1 ]
  %10 = phi i32 [ %11, %8 ], [ %3, %1 ]
  %11 = tail call i32 @cq_theta_si32(i32 noundef %10, double noundef 1.000000e-01)
  %12 = add nuw nsw i32 %9, 1
  %13 = icmp eq i32 %12, %0
  br i1 %13, label %5, label %8

14:
  %15 = tail call i32 @cq_theta_si32(i32 noundef %6, double noundef 2.000000e-01)
  br label %16

16:
  %17 = phi i32 [ %15, %14 ], [ %6, %5 ]
  %18 = tail call i32 @cq_measure_si32(i32 noundef %2)
  %19 = tail call i32 @cq_measure_si32(i32 noundef %17)
  %20 = add nsw i32 %19, %18
  ret i32 %20
}


; CHECK-LABEL: define i32 @slice(
; CHECK-NEXT: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 2.500000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 3.000000e-01)
; CHECK-NEXT: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F1]], i32 %[[R]], double 0x3FE3333333333334)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = icmp sgt i32 %0, 0
; CHECK-NEXT: br i1 %[[G]], label %[[LOOP:[a-zA-Z0-9_.]+]], label %[[EXIT:[a-zA-Z0-9_.]+]]
; CHECK: {{^}}[[EXIT]]:
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 2.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NOT: cqrt_ry
; CHECK: call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK: {{^}}[[LOOP]]:
; CHECK-NEXT: phi i32
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[R]], double 1.000000e-01)
; CHECK-NEXT: add nuw nsw i32
; CHECK-NEXT: icmp eq i32
; CHECK-NEXT: br i1
; CHECK-NEXT: {{^}}}
;
; CHECK-LABEL: define i32 @slice_plain(
; CHECK-NEXT: %[[PQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[PQ]], double 5.000000e-01)
; CHECK-NEXT: %[[PR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[PR]], double 2.500000e-01)
; CHECK-NEXT: %[[PG:[a-zA-Z0-9_.]+]] = icmp sgt i32 %0, 0
; CHECK-NEXT: br i1 %[[PG]], label %[[PLOOP:[a-zA-Z0-9_.]+]], label %[[PEXIT:[a-zA-Z0-9_.]+]]
; CHECK: {{^}}[[PEXIT]]:
; CHECK-NEXT: %[[PF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[PQ]], i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[PF]], i32 %[[PR]], double 2.000000e-01)
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[PF]], i32 %[[PQ]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[PF]])
; CHECK-NOT: cqrt_ry
; CHECK: call i32 @cqrt_measure_i32(i32 %[[PQ]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[PR]])
; CHECK: {{^}}[[PLOOP]]:
; CHECK-NEXT: phi i32
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[PR]], double 1.000000e-01)
; CHECK-NEXT: add nuw nsw i32
; CHECK-NEXT: icmp eq i32
; CHECK-NEXT: br i1
; CHECK-NEXT: {{^}}}
