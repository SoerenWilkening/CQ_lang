; p6 — a rail BANK is present, and a load's pointer arrives from a formal
; parameter, so this file cannot resolve which object it reads. Under the
; premise that no rail ever reaches memory, "unresolvable" was harmless; with a
; bank in the module it is the difference between a classical immediate and a
; rail. Undecidable => refuse to render a verdict.
define i32 @slice(ptr %p) local_unnamed_addr {
entry:
  %bank = alloca [1 x i32], align 4, !cq.railbank !0
  %hb = call i32 @cqrt_alloc_i1(i1 false)
  %cell = getelementptr inbounds [1 x i32], ptr %bank, i64 0, i64 0
  store i32 %hb, ptr %cell, align 4
  %r = call i32 @cqrt_alloc_i32(i32 7)
  %v = load i32, ptr %p, align 4
  call void @cqrt_xorc_i32(i32 %r, i32 %v)
  call void @cqrt_free(i32 %r)
  ret i32 0
}
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_xorc_i32(i32, i32)
declare void @cqrt_free(i32)
!0 = !{!"i1"}
