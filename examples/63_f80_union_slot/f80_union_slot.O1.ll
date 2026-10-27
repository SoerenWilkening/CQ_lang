; ModuleID = 'f80_union_slot.c'
source_filename = "f80_union_slot.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define x86_fp80 @f80_union_slot(x86_fp80 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [12 x i8], align 16    ; C: union ieee_l2bits u;  (the union survives SROA: 16-byte bit-field view over a 10-byte long double)
  %5 = tail call x86_fp80 @cq_theta_f80(x86_fp80 noundef %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 12, ptr nonnull %4)    ; C: (u comes into scope)
  store x86_fp80 %5, ptr %4, align 16, !tbaa !6    ; C: u.e = x;
  %6 = getelementptr inbounds i8, ptr %4, i64 8    ; C: &u.bits.exp  (word at byte 8: exp:15 | sign:1 | junk:16)
  %7 = load i32, ptr %6, align 8    ; C: the word holding u.bits.exp
  %8 = sub i32 %7, %2    ; C: (int)u.bits.exp - k  (only the low 15 bits are kept, so the mask is dropped)
  %9 = and i32 %8, 32767    ; C: (unsigned)e & 0x7fff
  %10 = and i32 %7, -32768    ; C: the other bit-fields of the word (sign, junk) are preserved
  %11 = or disjoint i32 %9, %10    ; C: the new word
  %12 = getelementptr inbounds i8, ptr %4, i64 8    ; C: &u.bits.exp
  store i32 %11, ptr %12, align 8    ; C: u.bits.exp = ...;
  %13 = load x86_fp80, ptr %4, align 16, !tbaa !6    ; C: u.e
  %14 = tail call x86_fp80 @cq_measure_f80(x86_fp80 noundef %13) #4    ; C: cq_measure(u.e)
  call void @llvm.lifetime.end.p0(i64 12, ptr nonnull %4)    ; C: (u goes out of scope)
  ret x86_fp80 %14    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare x86_fp80 @cq_theta_f80(x86_fp80 noundef, double noundef) local_unnamed_addr #2

declare x86_fp80 @cq_measure_f80(x86_fp80 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{!7, !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
