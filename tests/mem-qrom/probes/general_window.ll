; cq-k65d: rule 20's general QROM window (clang -O1 of the C below; green under cqcheck user, entries
; qrom_row, qrom_view, qrom_heap). A classical row beside the quantum column is the table's base;
; a 4-byte view of a byte table is the strided form at stride 1; a signed index into a heap block reads
; the window of its range facts.
; | #include <stdlib.h>
; | static const int T[4][8] = {{1,2,3,4,5,6,7,8},{11,12,13,14,15,16,17,18},{21,22,23,24,25,26,27,28},{31,32,33,34,35,36,37,38}};
; | static const unsigned char B[16] = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};
; | 
; | /* a classical row next to the quantum column (rule 20: the classical term is the table's base) */
; | int qrom_row(int x, int r, double th) {
; |     cq_theta(&x, th);
; |     return cq_measure(T[r & 3][x & 7]);
; | }
; | /* a 4-byte view of a byte table at a byte stride (stride below the element) */
; | int qrom_view(int x, double th) {
; |     cq_theta(&x, th);
; |     int v;
; |     __builtin_memcpy(&v, B + (x & 7), 4);
; |     return cq_measure(v);
; | }
; | /* a signed index into a heap block (memory of unknown extent): the window of range facts */
; | int qrom_heap(int x, double th) {
; |     int *t = malloc(16 * sizeof(int));
; |     for (int i = 0; i < 16; i++) t[i] = 3 * i + 1;
; |     cq_theta(&x, th);
; |     int r = cq_measure(t[8 + x % 8]);
; |     free(t);
; |     return r;
; | }

@T = internal unnamed_addr constant [4 x [8 x i32]] [[8 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8], [8 x i32] [i32 11, i32 12, i32 13, i32 14, i32 15, i32 16, i32 17, i32 18], [8 x i32] [i32 21, i32 22, i32 23, i32 24, i32 25, i32 26, i32 27, i32 28], [8 x i32] [i32 31, i32 32, i32 33, i32 34, i32 35, i32 36, i32 37, i32 38]], align 16
@B = internal unnamed_addr constant [16 x i8] c"\01\02\03\04\05\06\07\08\09\0A\0B\0C\0D\0E\0F\10", align 16

; Function Attrs: nounwind ssp uwtable
define i32 @qrom_row(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr {
  %4 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %2)
  %5 = and i32 %1, 3
  %6 = zext nneg i32 %5 to i64
  %7 = and i32 %4, 7
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds [4 x [8 x i32]], ptr @T, i64 0, i64 %6, i64 %8
  %10 = load i32, ptr %9, align 4
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10)
  ret i32 %11
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

; Function Attrs: nounwind ssp uwtable
define i32 @qrom_view(i32 noundef %0, double noundef %1) local_unnamed_addr {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %4 = and i32 %3, 7
  %5 = zext nneg i32 %4 to i64
  %6 = getelementptr inbounds i8, ptr @B, i64 %5
  %7 = load i32, ptr %6, align 1
  %8 = tail call i32 @cq_measure_si32(i32 noundef %7)
  ret i32 %8
}

; Function Attrs: nounwind ssp uwtable
define i32 @qrom_heap(i32 noundef %0, double noundef %1) local_unnamed_addr {
  %3 = tail call dereferenceable_or_null(64) ptr @malloc(i64 noundef 64)
  br label %12

4:                                                ; preds = %12
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1)
  %6 = srem i32 %5, 8
  %7 = sext i32 %6 to i64
  %8 = getelementptr i32, ptr %3, i64 %7
  %9 = getelementptr i8, ptr %8, i64 32
  %10 = load i32, ptr %9, align 4
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10)
  tail call void @free(ptr noundef %3)
  ret i32 %11

12:                                               ; preds = %2, %12
  %13 = phi i64 [ 0, %2 ], [ %18, %12 ]
  %14 = getelementptr inbounds i32, ptr %3, i64 %13
  %15 = trunc i64 %13 to i32
  %16 = mul i32 %15, 3
  %17 = add i32 %16, 1
  store i32 %17, ptr %14, align 4
  %18 = add nuw nsw i64 %13, 1
  %19 = icmp eq i64 %18, 16
  br i1 %19, label %4, label %12
}

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr

; Function Attrs: mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite)
declare void @free(ptr allocptr nocapture noundef) local_unnamed_addr



; CHECK qrom_row: call i32 @cq_template_add_i32_hl(i32 %{{a}}, i32 %{{b}})
; CHECK qrom_row: = getelementptr i8, ptr @T, i64 %{{o}}
; CHECK qrom_row: call i32 @cq_template_qrom_load_i32(ptr %{{b}}, i64 %{{n}}, i32 %{{i}})
; CHECK qrom_view: call i32 @cq_template_qrom_load_i32_s(ptr @B, i64 13, i64 1, i32 %{{i}})
; CHECK qrom_heap: %{{i}} = call i32 @cq_template_add_i32_hl(i32 %{{r}}, i32 7)
; CHECK qrom_heap: call i32 @cq_template_qrom_load_i32(ptr %{{b}}, i64 15, i32 %{{i}})
