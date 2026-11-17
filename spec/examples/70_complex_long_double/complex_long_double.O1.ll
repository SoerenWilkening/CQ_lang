; ModuleID = 'complex_long_double.c'
source_filename = "complex_long_double.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define x86_fp80 @complex_long_double(x86_fp80 noundef %0, double noundef %1, x86_fp80 noundef %2) local_unnamed_addr #0 {
  %4 = alloca { x86_fp80, x86_fp80 }, align 16    ; C: long double complex z  (the by-value copy handed to scale2)
  %5 = tail call x86_fp80 @cq_theta_f80(x86_fp80 noundef %0, double noundef %1) #4    ; C: cq_theta(&re, th);
  %6 = fmul x86_fp80 %2, 0xK00000000000000000000    ; C: im * I  (real part im*0)
  %7 = fadd x86_fp80 %6, %5    ; C: long double complex z = re + im * I;  (real part)
  call void @llvm.lifetime.start.p0(i64 32, ptr nonnull %4) #5    ; C: (z comes into scope)
  %8 = getelementptr inbounds i8, ptr %4, i64 16    ; C: &z.imag
  store x86_fp80 %7, ptr %4, align 16    ; C: z.real = re + im*0
  store x86_fp80 %2, ptr %8, align 16    ; C: z.imag = im
  %9 = tail call fastcc { x86_fp80, x86_fp80 } @scale2(ptr noundef nonnull byval({ x86_fp80, x86_fp80 }) align 16 %4)    ; C: long double complex q = scale2(z);
  %10 = extractvalue { x86_fp80, x86_fp80 } %9, 0    ; C: creall(q)
  %11 = extractvalue { x86_fp80, x86_fp80 } %9, 1    ; C: cimagl(q)
  call void @llvm.lifetime.end.p0(i64 32, ptr nonnull %4) #5    ; C: (z goes out of scope)
  %12 = fadd x86_fp80 %10, %11    ; C: creall(q) + cimagl(q)
  %13 = tail call x86_fp80 @cq_measure_f80(x86_fp80 noundef %12) #5    ; C: cq_measure(creall(q) + cimagl(q))
  ret x86_fp80 %13    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare x86_fp80 @cq_theta_f80(x86_fp80 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable
define internal fastcc { x86_fp80, x86_fp80 } @scale2(ptr nocapture noundef readonly byval({ x86_fp80, x86_fp80 }) align 16 %0) unnamed_addr #3 {
  %2 = load x86_fp80, ptr %0, align 16    ; C: z.real
  %3 = getelementptr inbounds i8, ptr %0, i64 16    ; C: &z.imag
  %4 = load x86_fp80, ptr %3, align 16    ; C: z.imag
  %5 = fadd x86_fp80 %2, %2    ; C: z + z  (real)
  %6 = fadd x86_fp80 %4, %4    ; C: z + z  (imaginary)
  %7 = insertvalue { x86_fp80, x86_fp80 } poison, x86_fp80 %5, 0    ; C: return z + z;
  %8 = insertvalue { x86_fp80, x86_fp80 } %7, x86_fp80 %6, 1    ; C: return z + z;
  ret { x86_fp80, x86_fp80 } %8    ; C: return z + z;
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

declare x86_fp80 @cq_measure_f80(x86_fp80 noundef) local_unnamed_addr #2

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
