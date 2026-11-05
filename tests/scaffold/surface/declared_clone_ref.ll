; Rulings Q2 (c): no CQ.h call, but a reference to a declared clone of a linked lowered library.
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.15.0"

declare i32 @__cq_q_ext_0(i32)

define ptr @get() {
  ret ptr @__cq_q_ext_0
}
