; cq-dcw0i (CR rules 8, 9): a block whose classical condition is a disjunction (`!(ce == 0 && cm == 0)`, no literal
; conjunct) is guarded by it. %c118 (both zero) joins the walk at %zero, an arm head of the quantum `a == 0`; from there
; the walk ran %c215, whose operand %y only the other classical side minted: its template read a poison handle
; (SoftFloat f16_mulAdd with c classical, experiments/arrangements/partial/fma_q1.linked.ll).
; USERCHECK f
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @f(i8 noundef zeroext %qa, i8 noundef zeroext %cc) {
  %t = tail call zeroext i8 @cq_theta_ui8(i8 noundef zeroext %qa, double noundef 3.000000e-01)
  %a = zext i8 %t to i32
  %c = zext i8 %cc to i32
  %r = tail call i32 @h(i32 %a, i32 %c)
  %m = tail call i32 @cq_measure_ui32(i32 %r)
  ret i32 %m
}

define internal i32 @h(i32 %a, i32 %c) noinline {
entry:
  %az = icmp eq i32 %a, 0
  br i1 %az, label %azero, label %main
azero:
  %cbig = icmp ugt i32 %c, 100
  br i1 %cbig, label %ret, label %zero
main:
  %x = mul i32 %a, 3
  %ce = lshr i32 %c, 4
  %ce0 = icmp eq i32 %ce, 0
  br i1 %ce0, label %c116, label %c135
c116:
  %cm = and i32 %c, 15
  %cm0 = icmp eq i32 %cm, 0
  br i1 %cm0, label %c118, label %c126
c118:
  %r118 = add i32 %x, -1
  br label %join
c126:
  %cm5 = mul i32 %cm, 5
  br label %c135
c135:
  %cmp = phi i32 [ %cm5, %c126 ], [ %c, %main ]
  %d = shl i32 %cmp, 4
  %x2 = and i32 %x, 2
  %q = icmp eq i32 %x2, 0
  br i1 %q, label %c190, label %c142
c190:
  %y = sub i32 %x, %d
  %y7 = icmp eq i32 %y, 7
  br i1 %y7, label %zero, label %c215
c215:
  %pos = icmp sgt i32 %y, -1
  br i1 %pos, label %join, label %c217
c217:
  %ny = sub i32 0, %y
  br label %join
c142:
  %s = add i32 %x, %d
  br label %join
join:
  %rr = phi i32 [ %r118, %c118 ], [ %y, %c215 ], [ %ny, %c217 ], [ %s, %c142 ]
  %r5 = add i32 %rr, 5
  br label %ret
zero:
  br label %ret
ret:
  %v = phi i32 [ %c, %azero ], [ 0, %zero ], [ %r5, %join ]
  ret i32 %v
}

declare zeroext i8 @cq_theta_ui8(i8 noundef zeroext, double noundef)
declare i32 @cq_measure_ui32(i32)
