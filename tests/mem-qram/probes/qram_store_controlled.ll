; A QRAM store under a quantum predicate is the _controlled form under the block's flag (rule 20, §1.3).
declare i32 @cq_theta_ui32(i32, double)
declare i32 @cq_measure_ui32(i32)

define i32 @qram_ctl(i32 %x0, double %t, i32 %v) {
entry:
  %a = alloca [4 x i32], align 16
  %x = call i32 @cq_theta_ui32(i32 %x0, double %t)
  %c = icmp ugt i32 %x, 9
  br i1 %c, label %then, label %join
then:
  %i = and i32 %x, 3
  %iz = zext nneg i32 %i to i64
  %p = getelementptr inbounds [4 x i32], ptr %a, i64 0, i64 %iz
  store i32 %v, ptr %p, align 4
  br label %join
join:
  %r = load i32, ptr %a, align 16
  %m = call i32 @cq_measure_ui32(i32 %r)
  ret i32 %m
}
; CHECK qram_ctl: call void @cqrt_qram_store_i32_controlled(i32 %{{f}}, i32 %{{a}}, i32 %{{i}}, i32 %{{s}})
; CHECK qram_ctl: call void @cqrt_qram_store_i32_controlled_unc(i32 %{{f}}, i32 %{{a}}, i32 %{{i}}, i32 %{{s}})
; CHECK qram_ctl: call void @cqrt_qram_free(i32 %{{a}})
