; tests/aggr probes (cq-oa67, owner 2026-11-02 no stops), written by hand: rules 9, 25 and 26 constructions
; over their whole class, past the first witnesses. Each entry is checked §6 against its own program.
;  - w_vselect: a vector select under per-lane quantum conditions, one lane condition classical (rule 9 per lane)
;  - w_sselect: a struct select under a quantum condition, one field the same classical value on both arms
;  - w_join / w_split / w_regroup: bitcasts regrouping bits across lanes (rule 3; little-endian lanes)
;  - w_index: lanes read and written at a quantum and at a classical run-time index (rule 9 over the lanes)
;  - w_phi: a vector phi and a struct phi under a quantum branch (rule 9 field by field)
;  - w_empty: an empty struct carried through insert/extract next to a rail
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%P = type { i32, i32, i32 }

define i32 @w_vselect(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i1 %k) {
  %x = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1)
  %v0 = insertelement <2 x i32> poison, i32 %x, i64 0
  %v = insertelement <2 x i32> %v0, i32 %2, i64 1
  %w0 = insertelement <2 x i32> poison, i32 %3, i64 0
  %w = insertelement <2 x i32> %w0, i32 %x, i64 1
  %c = icmp ugt <2 x i32> %v, %w
  %s = select <2 x i1> %c, <2 x i32> %v, <2 x i32> %w
  %k0 = insertelement <2 x i1> poison, i1 %k, i64 0
  %kk = insertelement <2 x i1> %k0, i1 %k, i64 1
  %t = select <2 x i1> %kk, <2 x i32> %s, <2 x i32> %v
  %a = extractelement <2 x i32> %t, i64 0
  %b = extractelement <2 x i32> %t, i64 1
  %r = add i32 %a, %b
  %m = tail call i32 @cq_measure_ui32(i32 noundef %r)
  ret i32 %m
}

define i32 @w_sselect(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %x = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1)
  %x1 = add i32 %x, 1
  %p0 = insertvalue %P poison, i32 %x, 0
  %p1 = insertvalue %P %p0, i32 %2, 1
  %p = insertvalue %P %p1, i32 9, 2
  %q0 = insertvalue %P poison, i32 %2, 0
  %q1 = insertvalue %P %q0, i32 %x1, 1
  %q = insertvalue %P %q1, i32 9, 2
  %lo = and i32 %x, 1
  %f = icmp ne i32 %lo, 0
  %r = select i1 %f, %P %p, %P %q
  %a = extractvalue %P %r, 0
  %b = extractvalue %P %r, 1
  %c = extractvalue %P %r, 2
  %b2 = shl i32 %b, 1
  %ab = xor i32 %a, %b2
  %abc = add i32 %ab, %c
  %m = tail call i32 @cq_measure_ui32(i32 noundef %abc)
  ret i32 %m
}

define i64 @w_join(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %x = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1)
  %v0 = insertelement <2 x i32> poison, i32 %x, i64 0
  %v = insertelement <2 x i32> %v0, i32 %2, i64 1
  %l = bitcast <2 x i32> %v to i64
  %r = add i64 %l, 3
  %m = tail call i64 @cq_measure_ull(i64 noundef %r)
  ret i64 %m
}

define i32 @w_split(i32 noundef %0, double noundef %1) {
  %x = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1)
  %y = mul i32 %x, 3
  %b = bitcast i32 %y to <4 x i8>
  %s = bitcast <4 x i8> %b to <2 x i16>
  %b1 = extractelement <4 x i8> %b, i64 1
  %s1 = extractelement <2 x i16> %s, i64 1
  %e1 = zext i8 %b1 to i32
  %e2 = zext i16 %s1 to i32
  %r = add i32 %e1, %e2
  %m = tail call i32 @cq_measure_ui32(i32 noundef %r)
  ret i32 %m
}

define i32 @w_regroup(i32 noundef %0, double noundef %1, i16 noundef %2) {
  %x = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1)
  %t = trunc i32 %x to i16
  %v0 = insertelement <3 x i16> poison, i16 %t, i64 0
  %v1 = insertelement <3 x i16> %v0, i16 %2, i64 1
  %v = insertelement <3 x i16> %v1, i16 %t, i64 2
  %g = bitcast <3 x i16> %v to <2 x i24>
  %g0 = extractelement <2 x i24> %g, i64 0
  %g1 = extractelement <2 x i24> %g, i64 1
  %z0 = zext i24 %g0 to i32
  %z1 = zext i24 %g1 to i32
  %r = xor i32 %z0, %z1
  %m = tail call i32 @cq_measure_ui32(i32 noundef %r)
  ret i32 %m
}

define i32 @w_index(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %x = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1)
  %xc = add i32 %x, %2
  %v0 = insertelement <2 x i32> poison, i32 %2, i64 0
  %v = insertelement <2 x i32> %v0, i32 %xc, i64 1
  %w = insertelement <2 x i32> <i32 poison, i32 7>, i32 %x, i64 0
  %qi = and i32 %x, 1
  %ci = and i32 %3, 1
  %a = extractelement <2 x i32> %v, i32 %qi
  %b = extractelement <2 x i32> %w, i32 %ci
  %w2 = insertelement <2 x i32> %w, i32 %2, i32 %qi
  %w3 = insertelement <2 x i32> %w2, i32 %b, i32 %ci
  %e0 = extractelement <2 x i32> %w3, i64 0
  %e1 = extractelement <2 x i32> %w3, i64 1
  %ab = add i32 %a, %b
  %abe = add i32 %ab, %e0
  %r = xor i32 %abe, %e1
  %m = tail call i32 @cq_measure_ui32(i32 noundef %r)
  ret i32 %m
}

define i32 @w_phi(i32 noundef %0, double noundef %1, i32 noundef %2) {
  br label %start
start:
  %x = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1)
  %v0 = insertelement <2 x i32> poison, i32 %x, i64 0
  %v = insertelement <2 x i32> %v0, i32 %2, i64 1
  %p0 = insertvalue %P poison, i32 %2, 0
  %p1 = insertvalue %P %p0, i32 %x, 1
  %p = insertvalue %P %p1, i32 5, 2
  %f = icmp ugt i32 %x, %2
  br i1 %f, label %then, label %join
then:
  %vv = mul <2 x i32> %v, <i32 3, i32 5>
  %q = insertvalue %P %p, i32 %2, 1
  br label %join
join:
  %pv = phi <2 x i32> [ %vv, %then ], [ %v, %start ]
  %pp = phi %P [ %q, %then ], [ %p, %start ]
  %a = extractelement <2 x i32> %pv, i64 0
  %b = extractelement <2 x i32> %pv, i64 1
  %c = extractvalue %P %pp, 1
  %d = extractvalue %P %pp, 2
  %ab = add i32 %a, %b
  %abc = xor i32 %ab, %c
  %r = add i32 %abc, %d
  %m = tail call i32 @cq_measure_ui32(i32 noundef %r)
  ret i32 %m
}

define i32 @w_empty(i32 noundef %0, double noundef %1) {
  %x = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1)
  %a = insertvalue { i32, {} } poison, i32 %x, 0
  %b = insertvalue { i32, {} } %a, {} zeroinitializer, 1
  %e = extractvalue { i32, {} } %b, 1
  %c = insertvalue { i32, {} } %b, {} %e, 1
  %y = extractvalue { i32, {} } %c, 0
  %z = add i32 %y, 2
  %m = tail call i32 @cq_measure_ui32(i32 noundef %z)
  ret i32 %m
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef)
declare i32 @cq_measure_ui32(i32 noundef)
declare i64 @cq_measure_ull(i64 noundef)
