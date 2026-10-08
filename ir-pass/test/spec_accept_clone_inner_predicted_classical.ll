; spec_accept_clone_inner_predicted_classical.ll — ACCEPT (bd test_C_libtooling-r2j3.19).
; A NESTED lift: the outer clone `__cq_q_h2_01` / `__cq_q_h3_01` calls the inner lift
; `h`, which READS its quantum argument (through `g`) and returns the CLASSICAL `k + 1`.
; `predictReturnTainted(h, 01)` is false, so the inner call's RESULT is classical in
; the outer clone, exactly as `specCallResultPredictedClassical` leaves it at module
; level (bd cepm).
;
; THE MISCOMPILE THIS PINS (2026-10-08 review of bae428e8, bd p3kd.7.8). The clone
; ran main's control chain on a taint set built by a plain def-use closure, which
; tainted every inner call result; the inner-call drain scrubbed the classical
; result only AFTER the chain had emitted gates on it. Measured on e0af16ed:
;   h2: %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %3, i32 3)
;   h3: call void @cqrt_copy_i32_controlled(i32 %h_cmp, i32 %3, i32 %out)
; where %3 is the inner clone's classical `k + 1` read as a qubit handle. opt rc=0,
; stage 2b clean, and the linked trace read an already-freed handle (h8).
; The clone's taint is now derived by main's propagation (call-result prediction,
; settle step), so the chain reads the result as an integer.
;
; Separate TUs, each `clang -O1`, llvm-linked (tests/e2e/run_slice_multi.sh):
;   int h2(int a,int k){int u=h(a,k); return u>3 ? a+5 : a;}   /* classical condition */
;   int h3(int a,int k){int u=h(a,k); return a>3 ? u : a+5;}   /* classical arm */
;   int h(int a,int k){g(a); return k+1;}  void g(int a){f2(a);}
;   int f2(int a){return f3(a)+1;}         int f3(int a){return a*3;}
;   int hm(int a,int k){return h(a,k);}  int h4(int a,int k){int u=hm(a,k); return u>3 ? a+5 : a;}
;   main: q = atoi(v[1]); cq_theta(&q,.5);
;         return cq_measure(h2(q,m)) + cq_measure(h3(q,m)) + cq_measure(h4(q,m));
; h4 is the review-round-1 probe (F2): `hm` returns `h`'s result, so its own prediction
; is classical only if the predictor asks the INNER site's prediction
; (`predictReturnTaintedImpl`); before that, the clone fence declined it loudly.
; h3's classical arm is loaded into a fresh rail (`cqrt_alloc_i32(%3)`) that is never
; freed: it holds an unentangled basis value, an accepted R5 leak (stage 2b clean).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=NOHANDLE < %t.ll
;
; h2: the classical condition stays a stock compare; the quantum arms are chosen by
; a rail select (bd p3kd.7.2).
; CHECK-LABEL: define internal i32 @__cq_q_h2_01(
; CHECK:       %[[U:[0-9]+]] = tail call i32 @__cq_q_h_01(
; CHECK:       icmp sgt i32 %[[U]], 3
; CHECK:       ret i32
; h3: the classical arm is loaded into a fresh register before its controlled copy.
; CHECK-LABEL: define internal i32 @__cq_q_h3_01(
; CHECK:       %[[V:[0-9]+]] = tail call i32 @__cq_q_h_01(
; CHECK:       %[[VR:[A-Za-z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %[[V]])
; CHECK:       call void @cqrt_copy_i32_controlled(i32 %{{[A-Za-z0-9_.]+}}, i32 %[[VR]],
; CHECK:       ret i32
;
; No runtime call reads an inner clone's classical result as a handle: the result may
; appear only as an `_hl` literal never, and as a `cqrt_alloc_<W>` seed (h3's arm).
; Nor may it be renamed first: a `freeze` alias (`stabilizeSpeculatedValues`' `.stable`)
; would carry a handle read past the literal-name NOT lines (review round 3 F6), so
; any freeze of it fails here and must be read.
; NOHANDLE-LABEL: define internal i32 @__cq_q_h2_01(
; NOHANDLE:       %[[U:[0-9]+]] = tail call i32 @__cq_q_h_01(
; NOHANDLE-NOT:   @cq{{(rt|_template)}}_{{[a-z0-9_]+}}({{.*}}i32 %[[U]]{{[,)]}}
; NOHANDLE-NOT:   freeze i32 %[[U]]{{($|,)}}
; NOHANDLE:       ret i32
; NOHANDLE-LABEL: define internal i32 @__cq_q_h3_01(
; NOHANDLE:       %[[V:[0-9]+]] = tail call i32 @__cq_q_h_01(
; NOHANDLE-NOT:   @cq_template_{{[a-z0-9_]+}}({{.*}}i32 %[[V]]{{[,)]}}
; NOHANDLE-NOT:   @cqrt_{{(copy|x|free|cswap|toffoli)[a-z0-9_]*}}({{.*}}i32 %[[V]]{{[,)]}}
; NOHANDLE-NOT:   freeze i32 %[[V]]{{($|,)}}
; NOHANDLE:       ret i32
; NOHANDLE-LABEL: define internal i32 @__cq_q_h4_01(
; NOHANDLE:       %[[W:[0-9]+]] = tail call i32 @__cq_q_hm_01(
; NOHANDLE-NOT:   @cq{{(rt|_template)}}_{{[a-z0-9_]+}}({{.*}}i32 %[[W]]{{[,)]}}
; NOHANDLE-NOT:   freeze i32 %[[W]]{{($|,)}}
; NOHANDLE:       ret i32
; h4 (two levels): the classical condition stays a stock compare, as in h2.
; CHECK-LABEL: define internal i32 @__cq_q_h4_01(
; CHECK:       %[[X:[0-9]+]] = tail call i32 @__cq_q_hm_01(
; CHECK:       icmp sgt i32 %[[X]], 3
; CHECK:       ret i32

target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %7 = tail call i32 @h2(i32 noundef %6, i32 noundef %5) #4
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7) #4
  %9 = tail call i32 @h3(i32 noundef %6, i32 noundef %5) #4
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9) #4
  %11 = add nsw i32 %10, %8
  %12 = tail call i32 @h4(i32 noundef %6, i32 noundef %5) #4
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #4
  %14 = add nsw i32 %11, %13
  ret i32 %14
}

declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

define range(i32 -2147483647, -2147483648) i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  tail call void @g(i32 noundef %0) #4
  %3 = add nsw i32 %1, 1
  ret i32 %3
}

define void @g(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @f2(i32 noundef %0) #4
  ret void
}

define range(i32 -2147483647, -2147483648) i32 @f2(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 @f3(i32 noundef %0) #4
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @f3(i32 noundef %0) local_unnamed_addr #3 {
  %2 = mul nsw i32 %0, 3
  ret i32 %2
}

define i32 @h2(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @h(i32 noundef %0, i32 noundef %1) #4
  %4 = icmp sgt i32 %3, 3
  %5 = add nsw i32 %0, 5
  %6 = select i1 %4, i32 %5, i32 %0
  ret i32 %6
}

define i32 @h3(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @h(i32 noundef %0, i32 noundef %1) #4
  %4 = icmp sgt i32 %0, 3
  %5 = add nsw i32 %0, 5
  %6 = select i1 %4, i32 %3, i32 %5
  ret i32 %6
}

define i32 @hm(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @h(i32 noundef %0, i32 noundef %1) #4
  ret i32 %3
}

define i32 @h4(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @hm(i32 noundef %0, i32 noundef %1) #4
  %4 = icmp sgt i32 %3, 3
  %5 = add nsw i32 %0, 5
  %6 = select i1 %4, i32 %5, i32 %0
  ret i32 %6
}

attributes #0 = { nounwind ssp uwtable }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) }
attributes #2 = { "no-trapping-math"="true" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable }
attributes #4 = { nounwind }
