; M5 under a quantum predicate (rules 8, 20, CR 1.3): realloc's new logical size is the merge
; select(p, 6, 4), a quantum size, allocated at its upper bound max(6, 4) = 6. Its _unc restores 4.
declare i32 @cq_theta_ui32(i32, double)
declare i8 @cq_measure_ui8(i8)
declare noalias ptr @malloc(i64) allockind("alloc,uninitialized") allocsize(0)
declare ptr @realloc(ptr allocptr, i64) allockind("realloc") allocsize(1)

define i8 @reap(i32 %k0, double %tk, i8 %v) {
  br label %start
start:
  %a = call ptr @malloc(i64 4)
  %k = call i32 @cq_theta_ui32(i32 %k0, double %tk)
  %k3 = and i32 %k, 3
  %kz = zext nneg i32 %k3 to i64
  %p = getelementptr inbounds i8, ptr %a, i64 %kz
  store i8 %v, ptr %p, align 1
  %c = icmp ugt i32 %k, 7
  br i1 %c, label %grow, label %done
grow:
  %b = call ptr @realloc(ptr %a, i64 6)
  %q = getelementptr inbounds i8, ptr %b, i64 5
  %r = load i8, ptr %q, align 1
  br label %done
done:
  %s = phi i8 [ %r, %grow ], [ 0, %start ]
  %m = call i8 @cq_measure_ui8(i8 %s)
  ret i8 %m
}
; CHECK reap: %{{b}} = call i32 @cqrt_qram_realloc_i8(i32 %{{a}}, i32 6)
; CHECK reap: call i32 @cqrt_qram_load_i8_hl(i32 %{{b}}, i32 5)
; CHECK reap: call void @cqrt_qram_realloc_i8_unc(i32 %{{b}}, i32 4)
