; HAND-WRITTEN. Rules: 17, 6, 5, 2, 3, 7, 8, 10, 12, 20; §1.3 (the bus), BACKEND_ABI §1.13, §1.15.
; Checked: invert_prepare: rem (%7, measured -> %24) = r0 and profit (%8, measured -> %26) = p0 on every basis input: the
;            region is the adjoint of the PREP before it; x0 (%10 -> %29), x1 (%14 -> %32).
;          invert_old_value: a (%7, measured -> %13) = a - w, a the basis value after the Ry.
;          invert_cell: r (%7, measured -> %9) = r ^ x; x (%6, measured -> %10); the cell g = g - x (read from the bus at exit).
; Clean: invert_prepare: every compare flag and every select, uncomputed and freed where they are made (inside the region
;          too); nothing of rem's or profit's chain: each update is one gate on the register's rail.
;        invert_old_value: the copy of a's old value (%8: cleaned from the image by rule 6 inside the region), the product
;          %9, the flags %10 and %12, the inverse t %11.
;        invert_cell: the swap rail %8 (|0> after the swap-in).
; Kept: invert_prepare: rem (%7) and profit (%8), the registers the region updates in place (rotated, measured); x0
;         (%10) and x1 (%14), the rotated seeds (rule 10, measured).
;       invert_old_value: a (%7, rotated, the register the region updates in place, measured).
;       invert_cell: x (%6), r (%7) (rotated, measured). The cell keeps nothing (rule 5's in-place form).
; Rotations: invert_prepare: (Ry, rem, tr, 1); (Ry, profit, tp, 1); (Ry, x0, t, r0 > 4); (Ry, x1, t, r0 - 5*x0 > 8);
;              (P, flag, p, p0 + 18*x0 + 27*x1 > 40); then, as the backend emits the region:
;              (Ry, x1, -t, r0 - 5*x0 > 8); (Ry, x0, -t, r0 > 4).
;            invert_old_value: (Ry, a, ta, 1); then, as the backend emits the region: (P, flag, -p, a * (a - w) == k);
;              after it: (P, flag, q, a - w == k).
;            invert_cell: (Ry, x, tx, 1); (Ry, r, tr, 1).
; (x0, x1, a, x, r: the basis values the rotations leave, §6 item 1.)
; RULE 17 WITH RULE 6 (owner 2026-11-26). Inside a cq_invert region an in-place add or xor of a register (a rail live at
; the begin, or its in-place image made in the region) is ONE core gate on the register's rail, as rule 6's in-place
; clause has it, whatever reads the old value later; the backend records it and replays it inverted at the end (add by
; sub, addc by addc of the negated literal, copy and xorc by themselves, BACKEND_ABI §1.13, §1.15). The image is the
; register: it is never uncomputed inside the region and nothing is recomputed for it after the end. Every SSA name of
; the register (the value at the begin and each image) is that rail after the end.
; invert_prepare. PREP before the region is rule 6's in-place form as anywhere: four gates on rem's and profit's rails,
; each operand a select of the item's bit, computed, read and uncomputed around its gate. The region is the same code
; on the same rails, recorded. Reversed, it is PREP's adjoint: profit -= 27*x1, rem += 9*x1, profit -= 18*x0 (that one
; -O1 sank past x1's Ry; the two commute), the flag rem > 8 is computed on rem as it was before PREP's second item, the
; Ry on x1 by -t, rem += 5*x0, the flag rem > 4 on r0, the Ry on x0 by -t. rem and profit leave the region at r0 and p0
; on every basis input. The compiler reverses and negates nothing; the frees inside the region follow the replay.
; invert_old_value. t and a are one SSA value (%7). The update %8 = a + w is in place on a's rail although the product
; %9 reads the old value after it: the old value is copied to a fresh rail right before the gate, the product reads the
; copy, and the copy is cleaned from the image inside the region by rule 6 (t = a' - w, copy, t's uncompute). Replayed,
; the inverse t gives the copy a - w first, the product and its flag read a - w and a, and the copy's compute returns
; it to |0>: the phase's predicate is the C program's, run from the value the region leaves (a - w). After the end t
; and a are the register: the compare t == k reads a - w, and a is measured. No copy crosses the end.
; invert_cell. g += x is rule 5's in-place form (swap-out, add, swap-in), r ^= x rule 6's in-place xor, copy_i32(x, r).
; Replayed: copy (its own inverse), swap, sub, swap: the cell reads g - x and r reads r ^ x after the region.
source_filename = "invert_inplace_register.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@g = local_unnamed_addr global i32 0, align 4

define i32 @invert_prepare(i8 noundef zeroext %0, double noundef %1, i8 noundef zeroext %2, double noundef %3, double noundef %4, double noundef %5) {
  %7 = call i32 @cqrt_alloc_i8(i8 %0)    ; IR: %7 = cq_theta_ui8(%0, %1)  [register rem]
  call void @cqrt_ry_i8(i32 %7, double %1)    ; IR: %7 = cq_theta_ui8(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_i8(i8 %2)    ; IR: %8 = cq_theta_ui8(%2, %3)  [register profit]
  call void @cqrt_ry_i8(i32 %8, double %3)    ; IR: %8 = cq_theta_ui8(%2, %3)  [Ry]
  %9 = call i32 @cq_template_icmp_ugt_i8_hl(i32 %7, i8 4)    ; IR: %9 = icmp ugt i8 %7, 4  [path predicate of block %10]
  %10 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %11 = cq_theta_i1(false, %4): the seed x0 = 0 (rule 7); %12/%14/%15 are its i8 view (rule 3)
  call void @cqrt_ry_i1_controlled(i32 %9, i32 %10, double %4)    ; IR: %11 under %9, merged with 0 by %14: the controlled Ry on the seed (rule 10)
  call void @cq_template_icmp_ugt_i8_hl_unc(i32 %9, i32 %7, i8 4)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  %11 = call i32 @cq_template_select_i8_ll(i32 %10, i8 -5, i8 0)    ; IR: %16 = select i1 %15, i8 -5, i8 0
  call void @cqrt_add_i8(i32 %11, i32 %7)    ; IR: %17 = add i8 %16, %7  [rule 6, in-place update: rem's rail]
  call void @cq_template_select_i8_ll_unc(i32 %11, i32 %10, i8 -5, i8 0)    ; IR: uncompute %16
  call void @cqrt_free(i32 %11)    ; IR: release the %16 rail (|0>)
  %12 = call i32 @cq_template_select_i8_ll(i32 %10, i8 18, i8 0)    ; IR: %18 = select i1 %15, i8 18, i8 0
  call void @cqrt_add_i8(i32 %12, i32 %8)    ; IR: %19 = add i8 %18, %8  [rule 6, in-place update: profit's rail]
  call void @cq_template_select_i8_ll_unc(i32 %12, i32 %10, i8 18, i8 0)    ; IR: uncompute %18
  call void @cqrt_free(i32 %12)    ; IR: release the %18 rail (|0>)
  %13 = call i32 @cq_template_icmp_ugt_i8_hl(i32 %7, i8 8)    ; IR: %20 = icmp ugt i8 %17, 8  [path predicate of block %21]
  %14 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %22 = cq_theta_i1(false, %4): the seed x1 = 0 (rule 7); %23/%25/%26 its i8 view
  call void @cqrt_ry_i1_controlled(i32 %13, i32 %14, double %4)    ; IR: %22 under %20, merged with 0 by %25 (rule 10)
  call void @cq_template_icmp_ugt_i8_hl_unc(i32 %13, i32 %7, i8 8)    ; IR: uncompute %20
  call void @cqrt_free(i32 %13)    ; IR: release the %20 rail (|0>)
  %15 = call i32 @cq_template_select_i8_ll(i32 %14, i8 -9, i8 0)    ; IR: %27 = select i1 %26, i8 -9, i8 0
  call void @cqrt_add_i8(i32 %15, i32 %7)    ; IR: %28 = add i8 %27, %17  [rule 6, in-place update: rem's rail]
  call void @cq_template_select_i8_ll_unc(i32 %15, i32 %14, i8 -9, i8 0)    ; IR: uncompute %27
  call void @cqrt_free(i32 %15)    ; IR: release the %27 rail (|0>)
  %16 = call i32 @cq_template_select_i8_ll(i32 %14, i8 27, i8 0)    ; IR: %29 = select i1 %26, i8 27, i8 0
  call void @cqrt_add_i8(i32 %16, i32 %8)    ; IR: %30 = add i8 %19, %29  [rule 6, in-place update: profit's rail]
  call void @cq_template_select_i8_ll_unc(i32 %16, i32 %14, i8 27, i8 0)    ; IR: uncompute %29
  call void @cqrt_free(i32 %16)    ; IR: release the %29 rail (|0>)
  %17 = call i32 @cq_template_icmp_ugt_i8_hl(i32 %8, i8 40)    ; IR: %31 = icmp ugt i8 %30, 40  [path predicate of block %32]
  call void @cqrt_rz_i1(i32 %17, double %5)    ; IR: block %32: cq_phi(%5)  (kickback on the flag)
  call void @cq_template_icmp_ugt_i8_hl_unc(i32 %17, i32 %8, i8 40)    ; IR: uncompute %31
  call void @cqrt_free(i32 %17)    ; IR: release the %31 rail (|0>)
  call void @cqrt_invert_begin()    ; IR: call @__cq_invert_begin(); its asm fence is consumed (rule 17)
  %18 = call i32 @cq_template_icmp_ugt_i8_hl(i32 %7, i8 4)    ; IR: %34 = icmp ugt i8 %28, 4  [path predicate of block %35]
  call void @cqrt_ry_i1_controlled(i32 %18, i32 %10, double %4)    ; IR: %36 = cq_theta_i1(%15, %4) under %34, merged by %39: the controlled Ry in place on x0
  call void @cq_template_icmp_ugt_i8_hl_unc(i32 %18, i32 %7, i8 4)    ; IR: uncompute %34
  call void @cqrt_free(i32 %18)    ; IR: release the %34 rail (after the replay)
  %19 = call i32 @cq_template_select_i8_ll(i32 %10, i8 -5, i8 0)    ; IR: %41 = select i1 %40, i8 -5, i8 0
  call void @cqrt_add_i8(i32 %19, i32 %7)    ; IR: %42 = add i8 %41, %28  [rule 17 with rule 6: in place on rem's rail, a register; replayed as sub_i8]
  call void @cq_template_select_i8_ll_unc(i32 %19, i32 %10, i8 -5, i8 0)    ; IR: uncompute %41
  call void @cqrt_free(i32 %19)    ; IR: release the %41 rail (after the replay)
  %20 = call i32 @cq_template_icmp_ugt_i8_hl(i32 %7, i8 8)    ; IR: %43 = icmp ugt i8 %42, 8  [path predicate of block %44]
  call void @cqrt_ry_i1_controlled(i32 %20, i32 %14, double %4)    ; IR: %45 = cq_theta_i1(%26, %4) under %43, merged by %48: the controlled Ry in place on x1
  call void @cq_template_icmp_ugt_i8_hl_unc(i32 %20, i32 %7, i8 8)    ; IR: uncompute %43
  call void @cqrt_free(i32 %20)    ; IR: release the %43 rail (after the replay)
  %21 = call i32 @cq_template_select_i8_ll(i32 %10, i8 18, i8 0)    ; IR: %49 = select i1 %40, i8 18, i8 0
  call void @cqrt_add_i8(i32 %21, i32 %8)    ; IR: %50 = add i8 %49, %30  [rule 17 with rule 6: in place on profit's rail]
  call void @cq_template_select_i8_ll_unc(i32 %21, i32 %10, i8 18, i8 0)    ; IR: uncompute %49
  call void @cqrt_free(i32 %21)    ; IR: release the %49 rail (after the replay)
  %22 = call i32 @cq_template_select_i8_ll(i32 %14, i8 -9, i8 0)    ; IR: %52 = select i1 %51, i8 -9, i8 0
  call void @cqrt_add_i8(i32 %22, i32 %7)    ; IR: %53 = add i8 %52, %42  [rule 17 with rule 6: in place on rem's rail]
  call void @cq_template_select_i8_ll_unc(i32 %22, i32 %14, i8 -9, i8 0)    ; IR: uncompute %52
  call void @cqrt_free(i32 %22)    ; IR: release the %52 rail (after the replay)
  %23 = call i32 @cq_template_select_i8_ll(i32 %14, i8 27, i8 0)    ; IR: %54 = select i1 %51, i8 27, i8 0
  call void @cqrt_add_i8(i32 %23, i32 %8)    ; IR: %55 = add i8 %50, %54  [rule 17 with rule 6: in place on profit's rail]
  call void @cq_template_select_i8_ll_unc(i32 %23, i32 %14, i8 27, i8 0)    ; IR: uncompute %54
  call void @cqrt_free(i32 %23)    ; IR: release the %54 rail (after the replay)
  call void @cqrt_invert_end()    ; IR: call @__cq_invert_end(); fence consumed: the backend now emits the recorded gates reversed and inverted
  %24 = call i8 @cqrt_measure_i8(i32 %7)    ; IR: %56 = cq_measure_ui8(%53): rem is its rail after the region
  %25 = zext i8 %24 to i32    ; IR: %57 = zext i8 %56 to i32
  %26 = call i8 @cqrt_measure_i8(i32 %8)    ; IR: %58 = cq_measure_ui8(%55): profit is its rail after the region
  %27 = zext i8 %26 to i32    ; IR: %59 = zext i8 %58 to i32
  %28 = add nuw nsw i32 %27, %25    ; IR: %60 = add nuw nsw i32 %59, %57
  %29 = call i1 @cqrt_measure_i1(i32 %10)    ; IR: %61 = cq_measure_i1(%40)
  %30 = zext i1 %29 to i32    ; IR: %62 = zext i1 %61 to i32
  %31 = add nuw nsw i32 %28, %30    ; IR: %63 = add nuw nsw i32 %60, %62
  %32 = call i1 @cqrt_measure_i1(i32 %14)    ; IR: %64 = cq_measure_i1(%51)
  %33 = zext i1 %32 to i32    ; IR: %65 = zext i1 %64 to i32
  %34 = add nuw nsw i32 %31, %33    ; IR: %66 = add nuw nsw i32 %63, %65
  ret i32 %34    ; IR: ret i32 %66
}

define i32 @invert_old_value(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4, double noundef %5) {
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_ui32(%0, %1)  [register a; t is the same SSA value]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %7 = cq_theta_ui32(%0, %1)  [Ry]
  call void @cqrt_invert_begin()    ; IR: call @__cq_invert_begin(); its asm fence is consumed (rule 17)
  %8 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: the copy of %7's old value: %9 reads it after the update (rule 17 with rule 6)
  call void @cqrt_copy_i32(i32 %7, i32 %8)    ; IR: copy %7 -> %8, right before the gate
  call void @cqrt_addc_i32(i32 %7, i32 %2)    ; IR: %8 = add i32 %7, %2  [rule 17 with rule 6: in place on a's rail although the old value is read later; replayed as addc of -w]
  %9 = call i32 @cq_template_mul_i32(i32 %7, i32 %8)    ; IR: %9 = mul i32 %8, %7  (the image on a's rail, the old value from the copy)
  %10 = call i32 @cq_template_icmp_eq_i32_hl(i32 %9, i32 %3)    ; IR: %10 = icmp eq i32 %9, %3  [path predicate of block %11]
  call void @cqrt_rz_i1(i32 %10, double %4)    ; IR: block %11: cq_phi(%4)  (kickback on the flag)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %10, i32 %9, i32 %3)    ; IR: uncompute %10
  call void @cqrt_free(i32 %10)    ; IR: release the %10 rail (after the replay)
  call void @cq_template_mul_i32_unc(i32 %9, i32 %7, i32 %8)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (after the replay)
  %11 = call i32 @cq_template_sub_i32_hl(i32 %7, i32 %2)    ; IR: the copy's last reader is done: rule 6 cleans it from the image, t = a' - w
  call void @cqrt_copy_i32(i32 %11, i32 %8)    ; IR: the copy to |0>
  call void @cq_template_sub_i32_hl_unc(i32 %11, i32 %7, i32 %2)    ; IR: uncompute t
  call void @cqrt_free(i32 %11)    ; IR: release t (after the replay)
  call void @cqrt_free(i32 %8)    ; IR: release the copy (after the replay)
  call void @cqrt_invert_end()    ; IR: call @__cq_invert_end(); fence consumed: the backend now emits the recorded gates reversed and inverted
  %12 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 %3)    ; IR: %13 = icmp eq i32 %7, %3: t after the end is the register (a - w)  [path predicate of block %14]
  call void @cqrt_rz_i1(i32 %12, double %5)    ; IR: block %14: cq_phi(%5)  (kickback on the flag)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %12, i32 %7, i32 %3)    ; IR: uncompute %13
  call void @cqrt_free(i32 %12)    ; IR: release the %13 rail (|0>)
  %13 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %16 = cq_measure_ui32(%8): a is its rail after the region
  ret i32 %13    ; IR: ret i32 %16
}

define i32 @invert_cell(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %6 = cq_theta_ui32(%2, %3)  [register r]
  call void @cqrt_ry_i32(i32 %7, double %3)    ; IR: %6 = cq_theta_ui32(%2, %3)  [Ry]
  call void @cqrt_invert_begin()    ; IR: call @__cq_invert_begin(); its asm fence is consumed (rule 17)
  %8 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %7 = load i32, ptr @g: in-place form, the swap rail (|0>)
  call void @cqrt_qram_swap_i32_hl(i32 %5, i64 ptrtoint (ptr @g to i64), i32 %8)    ; IR: %7 = load i32, ptr @g: swap-out: the rail holds g, the cell |0>
  call void @cqrt_add_i32(i32 %6, i32 %8)    ; IR: %8 = add i32 %7, %5  [rule 6, in-place update on the swap rail]
  call void @cqrt_qram_swap_i32_hl(i32 %5, i64 ptrtoint (ptr @g to i64), i32 %8)    ; IR: store i32 %8, ptr @g: swap-in: the cell holds g + x, the rail the cell's |0>
  call void @cqrt_free(i32 %8)    ; IR: release the swap rail (after the replay)
  call void @cqrt_copy_i32(i32 %6, i32 %7)    ; IR: %9 = xor i32 %6, %5  [rule 17 with rule 6: in place on r's rail]
  call void @cqrt_invert_end()    ; IR: call @__cq_invert_end(); fence consumed: the backend now emits the recorded gates reversed and inverted
  %9 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %10 = cq_measure_ui32(%9): r is its rail after the region
  %10 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %11 = cq_measure_ui32(%5)
  %11 = add i32 %10, %9    ; IR: %12 = add i32 %11, %10
  ret i32 %11    ; IR: ret i32 %12
}

declare i32 @__cq_mem()
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i8(i8)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i8(i32, double)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i1_controlled(i32, i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_invert_begin()
declare void @cqrt_invert_end()
declare void @cqrt_add_i8(i32, i32)
declare void @cqrt_add_i32(i32, i32)
declare void @cqrt_addc_i32(i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)
declare void @cqrt_qram_swap_i32_hl(i32, i64, i32)
declare i8 @cqrt_measure_i8(i32)
declare i1 @cqrt_measure_i1(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cq_template_icmp_ugt_i8_hl(i32, i8)
declare void @cq_template_icmp_ugt_i8_hl_unc(i32, i32, i8)
declare i32 @cq_template_select_i8_ll(i32, i8, i8)
declare void @cq_template_select_i8_ll_unc(i32, i32, i8, i8)
declare i32 @cq_template_mul_i32(i32, i32)
declare void @cq_template_mul_i32_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
