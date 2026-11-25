; cq-wbboy, cq-23ovm (llvm-reduce of SQLite's sqlite3_strnicmp): the access at the phi %6 announces its address rail with
; __cq_unbound right after the rail's phi, in a block that holds only phis while it is built. Placing the call at a
; dereferenced end() read the list sentinel's bytes as the call's !dbg: opt crashed in the verifier or in CloneFunctionInto.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @unbound_phi(ptr %0, i1 %1) {
  br i1 false, label %3, label %5

3:                                                ; preds = %2
  %4 = getelementptr i8, ptr %0, i64 0
  %spec.select = select i1 %1, ptr null, ptr %4
  br label %5

5:                                                ; preds = %3, %2
  %6 = phi ptr [ null, %2 ], [ %spec.select, %3 ]
  %7 = phi ptr [ null, %2 ], [ null, %3 ]
  %8 = load i8, ptr %6, align 1
  ret i32 0
}
