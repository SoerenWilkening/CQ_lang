; HAND-WRITTEN. Rules: 2, 3, 4, 5, 6, 16, 18, 20, 21, 26; §1.3 (the bus, __cq_mem, __cq_alloc), §1.4.
; Checked: lo + hi (the add rail %10, measured -> %12) = ((x >> k) + (x & ((1 << k) - 1))) mod 2^32, the shift
; arithmetic and k taken mod 32 (§2); the cell hi on the bus at exit = x >> k.
; Clean: pointer_out_param: the clone's result rail lo (%8, rule 6: lo + hi is a bijection in lo and lo is dead), the
; inverse t = sum - hi (%11) and the load copy of hi (%9, un-copied: its last reader precedes every memory version
; change). __cq_q_split_100: the masked rail (%9), uncomputed after its copy-out and freed.
; Kept: x (%6, the rotated register), the sum rail %10 (measured); by rule 5 sentence 3 the tape slot of the store
; cqrt_qram_store_i32_hl(%4, %5, %6) in __cq_q_split_100 (source `*hi = v >> k`) and its value rail, the shifted
; rail %6 (x >> k). Nothing else.
; Rotations: (Ry, x, th, 1).
; Expected for the driver pointer_out_param(0, .5, 3): Ry(.5) flips each of the 32 bits of x independently with
; probability s = sin^2(.25) = 0.0612087; the measured value is (x >> 3) + (x & 7): x unchanged (= 0, probability
; (1 - s)^32 = 0.132498) gives 0, as do x = -7m, m = 1..7 (dozens of flipped bits each, negligible).
; A POINTER IS ONE SCALAR (§1.4, rules 18, 21, 26). &hi is a classical ptr: split(x, k, &hi) is the clone of mask 100
; (v a rail, k classical, the out-parameter a classical ptr), __cq_q_split_100(i32, i32, ptr); nothing about the pointee
; appears in the name or the parameter list, and no handle crosses the call through memory. The out-parameter is an
; ordinary pointer formal: the clone stores through it and the caller loads it (as rule 26 says for sret).
; THE ALLOCA IS BUS-RESIDENT (rule 20 b): hi is a call argument, so it is __cq_alloc(4, 4) at the alloca's program
; point, no alloca remains and the lifetime markers are dropped (rule 16). The clone's store is a bus store at the
; classical address (qram_store_i32_hl), the caller's load a bus load whose result is a rail (rule 3).
; WHAT THE CLONE STORES IS KEPT (rules 5, 18). The store `*hi = v >> k` is a kept store: its tape slot stays for the
; shot and so does its value rail, the ashr result, which is therefore not uncomputed in the clone. split writes
; memory, so __cq_q_split_100 has NO twin: its result lo is KEPT by rule 18 in the sense that no twin is called, and is
; cleaned by rule 6 like any other rail (rule 6, Dead: a call result that rule 18 keeps). lo + hi has both operands
; dead: the load copy of hi is garbage that rule 5 sentence 1 un-copies (no memory version change follows the load), so
; rule 6 cleans lo first (t = sum - hi reads the copy), then the copy is un-copied and freed, then the sum is measured.
; SPEC GAP: rule 5 sentence 1 asks for the last consumer's uncompute; the consumer (the add) is measured and has none.
; The load copy is un-copied after rule 6's clean, before the measurement, as in 195 and 200.
; SPEC GAP: CR fixes no calling convention, linkage or attributes for a clone called by name; it keeps the callee's
; (internal fastcc, unnamed_addr) as 195 and 200 do, and the memory, capture and purity facts of split (nocapture,
; writeonly, memory(argmem: write), nofree, willreturn) are dropped (§1.4).
source_filename = "pointer_out_param.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @pointer_out_param(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %5 = call ptr @__cq_alloc(i64 4, i64 4)    ; IR: %4 = alloca i32, align 4: hi is bus-resident (a call argument, rule 20 b): one zeroed block, no alloca remains
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %5 = cq_theta_si32(%0, %1)  [Ry]
  %7 = ptrtoint ptr %5 to i64    ; IR: the run-time address of hi (classical; llvm.lifetime.start dropped)
  %8 = call fastcc i32 @__cq_q_split_100(i32 %6, i32 %2, ptr %5)    ; IR: %6 = call fastcc i32 @split(%5, %2, ptr %4): the clone of mask 100 (rail, classical int, classical ptr); it stores, so it has no twin (rule 18)
  %9 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %7)    ; IR: %7 = load i32, ptr %4  [hi, written by the clone: a bus load, a rail]
  %10 = call i32 @cq_template_add_i32(i32 %9, i32 %8)    ; IR: %8 = add nsw i32 %7, %6
  %11 = call i32 @cq_template_sub_i32(i32 %10, i32 %9)    ; IR: rule 6: t = sum - hi recomputes lo (the clone's result has no twin; lo is dead)
  call void @cqrt_copy_i32(i32 %11, i32 %8)    ; IR: rule 6: lo ^= t: the dead lo rail is now |0>
  call void @cq_template_sub_i32_unc(i32 %11, i32 %10, i32 %9)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %11)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0> after the copy)
  call void @cqrt_qram_load_i32_hl_unc(i32 %9, i32 %4, i64 %7)    ; IR: un-copy %7 (rule 5 sentence 1: no memory version change since the load)
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  %12 = call i32 @cqrt_measure_i32(i32 %10)    ; IR: %9 = cq_measure_si32(%8)  [the sum rail stays allocated]
  ret i32 %12    ; IR: ret i32 %9  (llvm.lifetime.end dropped)
}

define internal fastcc i32 @__cq_q_split_100(i32 %0, i32 %1, ptr %2) unnamed_addr {
  %4 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %5 = ptrtoint ptr %2 to i64    ; IR: %2 as its run-time address (mask digit 0: the formal is the C ptr)
  %6 = call i32 @cq_template_ashr_i32_hl(i32 %0, i32 %1)    ; IR: %4 = ashr i32 %0, %1
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %5, i32 %6)    ; IR: store i32 %4, ptr %2  [kept store at a classical address: no _unc; its value rail %4 is kept with it]
  %7 = shl nsw i32 -1, %1    ; IR: %5 = shl nsw i32 -1, %1  (classical)
  %8 = xor i32 %7, -1    ; IR: %6 = xor i32 %5, -1  (classical)
  %9 = call i32 @cq_template_and_i32_hl(i32 %0, i32 %8)    ; IR: %7 = and i32 %6, %0  (commutative: classical operand moved to the _hl slot)
  %10 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %7  [result rail of the call]
  call void @cqrt_copy_i32(i32 %9, i32 %10)    ; IR: ret i32 %7  [copy the result out]
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %0, i32 %8)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  ret i32 %10    ; IR: ret i32 %7
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_ashr_i32_hl(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cq_template_sub_i32(i32, i32)
declare void @cq_template_sub_i32_unc(i32, i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
