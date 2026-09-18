; control_predmux_reject_classical_table_qrom_laundering.ll — DECLINE, and ⚠ THIS
; IS A P1 REGRESSION PIN (bd fn1q increment 4, Rule-13 round 1 finding R4-P1-1).
;
; THE DEFECT IT PINS. E4's classical-table admission is reached EXACTLY when
; `classifyQromReadUnderControl` returned `No`. The first version of that
; admission claimed its own taint test made the two "disjoint by construction".
; FALSE: QROM says `No` for SIX reasons, and one is the `coherentlyEscapesToReturn`
; NO-CLONING fence — where the load IS a genuine QROM read, refused because its
; value escapes coherently to a `ret` with no measurement. Such a read's index is
; UNTAINTED AT ROUND-1 TAINT and becomes tainted only once the flatten rewrites the
; region-internal `%idx` phi into a select. So the classical arm admitted it, the
; region was flattened, and `cqrt_qram_load_i32` was emitted on a SUPERPOSED index
; rail that is never uncomputed and never freed.
;
; MEASURED on the defective binary, from a plain-`CQ.h` C program:
;     ORACLE   exit 1, `nested control flow under quantum control`
;     SUBJECT  exit 0, 0 BYTES of stderr, links and runs
; and in the emitted stream: two `cqrt_copy_i64_controlled` under the tainted flag
; building the index rail, then `cqrt_qram_load_i32` on it, then the value to `ret`.
; `opt -verify` clean. `free_pairing_check.py` reported `0 violation(s)` because it
; is structurally blind to a leaked template-minted rail. That is the
; verify-clean silent-miscompile class this project exists to prevent, and NOTHING
; in the tree could have caught it — the corpus had no instance of the shape,
; because until this increment it declined.
;
; ⚠ THE EMITTER-SIDE BACKSTOP DOES NOT COVER IT, which is why the fix is at claim
; time. By the time `lowerQramReads` runs, the select merge is already
; `cqrt_copy_*_controlled` VOID calls, so `coherentlyEscapesToReturn`'s forward SSA
; walk stops at the merge and never reaches the `ret`.
;
; NON-VACUITY, MEASURED BY MUTATION rather than argued: with the fence disabled
; (`if (false && qromShapedReadTaintsIndexAfterFlatten(...))`) and the tree rebuilt,
; THIS MODULE EXITS 0. With the fence restored it declines. Both directions run.
;
; ⚠ THE FIX IS SURGICAL, NOT A BLANKET REFUSAL, and the control that shows it is
; the same program with `cq_measure` on the results: QROM claims that one normally
; and it ACCEPTS on all three binaries. Only the COHERENT ESCAPE differs.
;
; STANDING LESSON — CLAUDE.md L1, the PREDICATE species: a fence asked at ROUND-1
; taint while the lowering decides at FINAL taint. The cure is to CALL the owner's
; predicate (`indexWillTaintAfterFlatten`, via
; `qromShapedReadTaintsIndexAfterFlatten`) rather than re-derive a proxy for it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck --check-prefix=DBG %s
;
; DBG: gate=E4-gep
; CHECK: error{{.*}}cq controlled lowering: nested control flow under quantum control
; (No IR-text negatives: a decline writes 0 bytes to stdout — Rule 12 (b).)
@c = internal constant [4 x i32] [i32 11, i32 22, i32 33, i32 44], align 16

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i64 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %Z = call i32 @cq_theta_si32(i32 5, double 2.500000e-01)
  %P = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %c0 = icmp sgt i32 %q, 2
  br i1 %c0, label %outer, label %merge
outer:
  %c1 = icmp sgt i32 %q, 7
  br i1 %c1, label %armA, label %armB
armA:
  %a1 = mul i64 %n, 3
  %a2 = xor i64 %a1, 5
  %ia = and i64 %a2, 3
  br label %join
armB:
  %b1 = mul i64 %n, 13
  %b2 = xor i64 %b1, 7
  %ib = and i64 %b2, 3
  br label %join
join:
  %idx = phi i64 [ %ia, %armA ], [ %ib, %armB ]
  %gz = getelementptr inbounds [4 x i32], ptr @c, i64 0, i64 %idx
  %z = load i32, ptr %gz, align 4
  %Z1 = sub i32 %Z, %z
  %P1 = add i32 %P, %z
  br label %merge
merge:
  %Zn = phi i32 [ %Z, %entry ], [ %Z1, %join ]
  %Pn = phi i32 [ %P, %entry ], [ %P1, %join ]
  %s = add i32 %Zn, %Pn
  ret i32 %s
}
