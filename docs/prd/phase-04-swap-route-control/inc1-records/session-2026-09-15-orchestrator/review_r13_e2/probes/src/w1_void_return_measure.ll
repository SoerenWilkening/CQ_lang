; R13 ATTACK: clause (1a) sits ABOVE the `Handle->getType() != Measure->getType()`
; guard. If a `cq_measure_<sfx>` decl could ever return void, `Constant::getNullValue(void)`
; is `llvm_unreachable` -> UB in a Release build. Is the prototype validator the only fence?
declare void @cq_measure_si32(i32)
define void @f() {
  call void @cq_measure_si32(i32 undef)
  ret void
}
