; lowering_reject_live_record_qram_store_no_readback.ll — DECLINE: a record
; written into a QRAM cell that is NEVER READ BACK is not observed (M-A, bd
; test_C_libtooling-6uqc; the F1 ruling, 2026-08-28).
;
; SOURCE:
;     int arr[8] = {0};
;     a = cq_theta(a, 0.5);
;     int w = a * 2;                     // THE WIRE
;     int c = a * 3;                     // a SIBLING of the wire
;     p = cq_theta(p, 0.25);             // an independent superposed INDEX
;     w = cq_theta(w, 0.5);              // T — chained, in-place Ry on the wire
;     arr[p] = c;                        // the sibling's only post-gate fate
;     int y  = a * 5;                    //  (the ancestor's OWN observed read)
;     return cq_measure(y) + cq_measure(w);
;
; WHAT STANDS AT THE GATE. `%h_op3` (`c`) is allocated, entangled with the wire,
; and never discharged before `T`. Its single post-gate use is the 7.5 Shadow
; store `cqrt_qram_store_i32(%arr, %idx, %h_op3)` in the VALUE slot. A store is a
; HOP, not a sink: the walk follows it THROUGH the array to every later
; `cqrt_qram_load_*` on the same array handle — and there are none. Nothing the
; user can ever read depends on `c`, so the record is dead at the gate and the
; module declines.
;
; MEASURED at the pre-fix tree: `opt` exit 0 — the store counted as a "data use"
; on the retired reading of clause 3 ("mentioned later" ⇒ "the program's own
; data"). Writing a value into memory nobody reads is precisely the case where
; those two are not the same thing.
;
; DISCRIMINATION, and it is the read-back and nothing else: add
;     int v = arr[p];  int mv = cq_measure(v);
; and the module LOWERS — that is
; lowering_live_record_sibling_qram_store_load_measure_accept.ll, byte-identical
; here apart from those two lines. This is the ONLY fixture that exercises the
; store→array→load hop in its FALSE direction.
;
; WHY THE OTHER TWO RAILS DO NOT CARRY IT (so the pair really discriminates the
; store hop): `%h` is exempt because its post-gate read `y` flows to a measure —
; a template read that itself reaches a sink is the ruling's own wording; and
; `%h_op4` (`y`) is minted after the gate, so the F2 existence test skips it.
; The QRAM ARRAY handle itself is the ruled-DEFERRED record class (owner
; 2026-08-27, second round, point 4) and is never a record in either direction —
; that deferral is about what counts AGAINST the gate, whereas the hop here is
; about whether a user can still SEE the value.
;
; `mul` is the vehicle at every hop (information-losing ⇒ never M-C-converted in
; place), so each sibling is a separate rail.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare void @llvm.memset.p0.i64(ptr nocapture writeonly, i8, i64, i1 immarg)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0, i32 %u1) {
entry:
  %arr = alloca [8 x i32], align 16
  call void @llvm.memset.p0.i64(ptr align 16 %arr, i8 0, i64 32, i1 false)
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %w   = mul i32 %q, 2                                          ; THE WIRE
  %c   = mul i32 %q, 3                                          ; DEAD sibling record
  %p   = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)  ; independent index wire
  %q2  = call i32 @cq_theta_si32(i32 %w, double 5.000000e-01)   ; T
  %is  = sext i32 %p to i64
  %gs  = getelementptr inbounds [8 x i32], ptr %arr, i64 0, i64 %is
  store i32 %c, ptr %gs, align 4                                ; write-only cell
  %y   = mul i32 %q, 5                                          ; ancestor's observed read
  %my  = call i32 @cq_measure_si32(i32 %y)
  %m   = call i32 @cq_measure_si32(i32 %q2)
  %r   = add nsw i32 %my, %m
  ret i32 %r
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
