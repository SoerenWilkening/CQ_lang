; Rule 22 (90's memcpy_quantum_src shape, cq-w2a-mem-qram): a quantum-length memcpy into a slot array
; from a quantum source pointer s = q ? s1 : s2 over two classical parameters, its length selected on the
; same condition (4 on the s2 path, 8 on the s1 path). Cell 0 is the select on tag == 2 of the host loads
; s1[0], s2[0]; cell 1 is reached only on the s1 path, so only s1[1] is loaded (never a host byte past
; the length's bound for the object, rule 22). Each cell is select(n >u 4j+3, new, old).
; CHECK fat_src_int: %{{t}} = call i32 @cq_template_select_i32_ll(i32 %{{c}}, i32 2, i32 1)
; CHECK fat_src_int: %{{l0}} = load i32, ptr %2, align 4
; CHECK fat_src_int: %{{l1}} = load i32, ptr %3, align 4
; CHECK fat_src_int: %{{e}} = call i32 @cq_template_icmp_eq_i32_hl(i32 %{{t}}, i32 2)
; CHECK fat_src_int: %{{m}} = call i32 @cq_template_select_i32_ll(i32 %{{e}}, i32 %{{l1}}, i32 %{{l0}})
; CHECK fat_src_int: %{{p}} = getelementptr inbounds i8, ptr %2, i64 4
; CHECK-COUNT fat_src_int: getelementptr inbounds i8, ptr %3, 0
; CHECK fat_src_int: @cq_template_icmp_ugt_i64_hl(i32 %{{n}}, i64 3)
; CHECK fat_src_int: @cq_template_icmp_ugt_i64_hl(i32 %{{n}}, i64 7)
; CHECK-COUNT fat_src_int: @cq_template_select_i32_lh( 1
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @fat_src_int(i32 noundef %0, double noundef %1, ptr nocapture noundef readonly %2, ptr nocapture noundef readonly %3) local_unnamed_addr #0 {
  %5 = alloca i64, align 8
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5)
  store i32 9, ptr %5, align 8
  %7 = getelementptr inbounds i8, ptr %5, i64 4
  store i32 %0, ptr %7, align 4
  %8 = and i32 %6, 1
  %9 = icmp eq i32 %8, 0
  %10 = select i1 %9, ptr %3, ptr %2
  %11 = select i1 %9, i64 4, i64 8
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull align 8 dereferenceable(4) %5, ptr noundef nonnull align 4 dereferenceable(4) %10, i64 %11, i1 false)
  %12 = load i32, ptr %5, align 8
  %13 = getelementptr inbounds i8, ptr %5, i64 4
  %14 = load i32, ptr %13, align 4
  %15 = add nsw i32 %14, %12
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #5
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5)
  ret i32 %16
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }


!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
