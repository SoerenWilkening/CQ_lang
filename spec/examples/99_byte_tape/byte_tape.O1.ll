; ModuleID = 'byte_tape.c'
source_filename = "byte_tape.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__stdoutp = external local_unnamed_addr global ptr, align 8
@.str = private unnamed_addr constant [4 x i8] c"hi\0A\00", align 1

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 256) i32 @byte_tape(i8 noundef zeroext %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [3 x i8], align 1    ; C: unsigned char buf[3]
  %5 = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %0, double noundef %1) #3    ; C: cq_theta(&x, th);
  call void @llvm.lifetime.start.p0(i64 3, ptr nonnull %4) #4    ; C: (buf comes into scope)
  store i8 %5, ptr %4, align 1, !tbaa !6    ; C: buf[0] = x
  %6 = getelementptr inbounds i8, ptr %4, i64 1    ; C: &buf[1]
  %7 = zext i8 %5 to i32    ; C: x (as int, for x > k)
  %8 = add i8 %5, 1    ; C: (unsigned char)(x + 1)
  store i8 %8, ptr %6, align 1, !tbaa !6    ; C: buf[1] = x + 1
  %9 = getelementptr inbounds i8, ptr %4, i64 2    ; C: &buf[2]
  store i8 122, ptr %9, align 1, !tbaa !6    ; C: buf[2] = 'z'
  %10 = load ptr, ptr @__stdoutp, align 8, !tbaa !9    ; C: stdout
  %11 = call i64 @"\01_fwrite"(ptr noundef nonnull %4, i64 noundef 1, i64 noundef 3, ptr noundef %10) #4    ; C: fwrite(buf, 1, 3, stdout);
  %12 = icmp sgt i32 %7, %2    ; C: if (x > k)
  br i1 %12, label %13, label %16    ; C: if (x > k)

13:                                               ; preds = %3
  %14 = load ptr, ptr @__stdoutp, align 8, !tbaa !9    ; C: stdout
  %15 = call i32 @"\01_fputs"(ptr noundef nonnull @.str, ptr noundef %14) #4    ; C: fputs("hi\n", stdout);
  br label %16    ; C: end of if

16:                                               ; preds = %13, %3
  %17 = call zeroext i8 @cq_measure_ui8(i8 noundef zeroext %5) #4    ; C: cq_measure(x)
  %18 = zext i8 %17 to i32    ; C: (int)
  call void @llvm.lifetime.end.p0(i64 3, ptr nonnull %4) #4    ; C: (buf goes out of scope)
  ret i32 %18    ; C: return
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef) local_unnamed_addr #2

declare i64 @"\01_fwrite"(ptr noundef, i64 noundef, i64 noundef, ptr noundef) local_unnamed_addr #2

declare i32 @"\01_fputs"(ptr noundef, ptr noundef) local_unnamed_addr #2

declare zeroext i8 @cq_measure_ui8(i8 noundef zeroext) local_unnamed_addr #2

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
!9 = !{!10, !10, i64 0}
!10 = !{!"any pointer", !7, i64 0}
