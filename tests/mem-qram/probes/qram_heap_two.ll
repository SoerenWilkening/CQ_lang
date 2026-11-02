; cq-k65d: green under cqcheck user (300 samples). C source:
; | #include <stdlib.h>
; | /* a heap QRAM accessed as two types */
; | int qram_heap_two(int x, double th) {
; |     static const unsigned char init[8] = {0, 1, 2, 3, 4, 5, 6, 7};
; |     unsigned char *p = malloc(8);
; |     __builtin_memcpy(p, init, 8);
; |     cq_theta(&x, th);
; |     p[x & 7] = 0xff;
; |     int w;
; |     __builtin_memcpy(&w, p + 4, 4);
; |     int r = cq_measure(w + p[x & 3]);
; |     free(p);
; |     return r;
; | }

; Function Attrs: nounwind ssp uwtable
define i32 @qram_heap_two(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call dereferenceable_or_null(8) ptr @malloc(i64 noundef 8) #4
  store i64 506097522914230528, ptr %3, align 1
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %5 = and i32 %4, 7
  %6 = zext nneg i32 %5 to i64
  %7 = getelementptr inbounds i8, ptr %3, i64 %6
  store i8 -1, ptr %7, align 1
  %8 = getelementptr inbounds i8, ptr %3, i64 4
  %9 = load i32, ptr %8, align 1
  %10 = and i32 %4, 3
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds i8, ptr %3, i64 %11
  %13 = load i8, ptr %12, align 1
  %14 = zext i8 %13 to i32
  %15 = add nsw i32 %9, %14
  %16 = tail call i32 @cq_measure_si32(i32 noundef %15) #6
  tail call void @free(ptr noundef %3)
  ret i32 %16
}

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite)
declare void @free(ptr allocptr nocapture noundef) local_unnamed_addr #3

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { allocsize(0) }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }


; CHECK qram_heap_two: cqrt_qram_
