; tests/aggr probe (cq-qasj, CR rules 6, 25, 26): x is inserted into a struct field or a vector lane, then updated
; (x + 5); the field or lane is read after the update. A lane or field move emits no gate, so that reader reads x's
; rail: x is not dead at the update and rule 6 must not clean it (it did: a free of a rail in no known basis state).
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @a_field(i32 %c, double %th) {
  %x0 = call i32 @cq_theta_si32(i32 %c, double %th)
  %x = mul i32 %x0, 3
  %s = insertvalue {i32, i32} poison, i32 %x, 0
  %a = add i32 %x, 5
  %b = extractvalue {i32,i32} %s, 0
  %ma = call i32 @cq_measure_si32(i32 %a)
  %mb = call i32 @cq_measure_si32(i32 %b)
  %r = add i32 %ma, %mb
  ret i32 %r
}

define i32 @a_lane(i32 %c, double %th) {
  %x0 = call i32 @cq_theta_si32(i32 %c, double %th)
  %x = mul i32 %x0, 3
  %v = insertelement <2 x i32> poison, i32 %x, i64 0
  %v2 = insertelement <2 x i32> %v, i32 7, i64 1
  %e = extractelement <2 x i32> %v2, i64 0
  %y = add i32 %e, 5
  %my = call i32 @cq_measure_si32(i32 %y)
  %e2 = extractelement <2 x i32> %v2, i64 0
  %w = xor i32 %e2, 12345
  %m2 = call i32 @cq_measure_si32(i32 %e2)
  %r = add i32 %my, %m2
  ret i32 %r
}
