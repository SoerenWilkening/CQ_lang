#!/usr/bin/env python3
"""Headers for the round-2 F-1 fixtures, then mkfix.py for each."""
import pathlib, subprocess
SP = pathlib.Path(__file__).parent
MSG = "cq loop lowering: rail record read past an in-place gate on the same rail"

COMMON = """;
; bd `xdu2.1` (Track B), Rule-13 round-2 finding F-1 (2026-09-24) — a P1
; OVER-ACCEPT, the bd `3d8q` class through memory for the THIRD time. A rail
; PARKED in a rail bank, then relabelled by an in-place `xor` the ROLLED in-loop
; collapse (`collapseRailPhisIn`) commits via `markInPlaceRailOp`, then read back
; from the bank. Pre-fix (`cq-opt` c6f61f80a5d524c6 / main e36d9df4): exit 0,
; STRICT 2b clean, trace `ry(h0); …; cqrt_xorc_i32(h0,3) per trip; measure(h0)`
; — the bank measures observe `q ^ 3` where the source says `q`. The REGISTER
; spelling (`c = q; …; cq_measure(c)`) declines with this string on the same
; binary. MECHANISM: `LoopLowering::staleReadOfValue` enumerated the parked
; value's SSA users, found the bank STORE (before the loop, so no gate between
; def and "read") and never saw the cell LOADS; the reader fence's memory hop
; walks for `cq_theta_` gates only and runs before the collapse commits the
; in-place op. FIX: `staleReadOfValue` asks every cell load of every bank the
; value is parked in (`railBankCellReadsOf`, the forward hop read backwards).
; RED on the pre-fix binary (it ACCEPTS); GREEN after (declines with the
; register twin's string). The property is pinned by the `not` inversion and
; the verbatim string (Rule 12 (b)).
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, verbatim:
@@SOURCE@@
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \\
; RUN:   | %filecheck %s
; CHECK: """ + MSG + "\n"

FIX = {
  "railbank_stale_reject_inloop_xor_runtime_bank.ll": ("probes2/P1_bank.bank",
    "; railbank_stale_reject_inloop_xor_runtime_bank.ll — the reviewer's P1_bank.c:\n"
    "; runtime `int b[n]`, the relabel loop's condition reads `q` itself (a kickback\n"
    "; on `q > k`), runtime trip count.\n"),
  "railbank_stale_reject_inloop_xor_fixed_bank.ll": ("probes2/P1_bank_fixed.bank",
    "; railbank_stale_reject_inloop_xor_fixed_bank.ll — the reviewer's P1_bank_fixed.c:\n"
    "; FIXED `int b[3]`, the relabel loop's condition reads a DIFFERENT register `r`\n"
    "; (so the relabelled rail is not the condition's), runtime trip count.\n"),
  "railbank_stale_reject_inloop_xor_const_trip.ll": ("probes2/r_qx33_bank.bank",
    "; railbank_stale_reject_inloop_xor_const_trip.ll — the reviewer's r_qx33_bank.c:\n"
    "; runtime bank, CONSTANT trip count (3) on the relabel loop, outside `main`.\n"),
}
for name, (stem, head) in FIX.items():
    h = SP / ("hdr_" + name + ".txt")
    h.write_text(head + COMMON)
    subprocess.run(["python3", str(SP / "mkfix.py"), stem, name, str(h)], check=True)

LEGIT = """; railbank_stale_accept_inloop_xor_legit_order.ll — bd `xdu2.1` (Track B),
; Rule-13 round-2 finding F-1's GREEN half (the reviewer's P1_legit.c).
;
; The F-1 program with the bank measure loop moved ABOVE the in-place `xor` loop:
; every cell is read before any relabel, so the circuit is valid and the rolled
; collapse may convert `q ^= 3` in place. The fix (`staleReadOfValue` asking
; every bank cell LOAD) must NOT decline it: from the parked value's def, no
; path reaches a load through the xor loop (it has no back edge into the
; measure loop). Pre-fix and post-fix binaries emit this module BYTE-IDENTICALLY
; (measured, `TRACK_B.md` §6b).
;
; What is pinned, so the accept is not the fence never looking: the in-place
; `cqrt_xorc_i32(%h, 3)` IS emitted (the collapse converted the relabel), the
; bank loads feed the measures, and the measure loop's EXIT block is the one
; that enters the xor loop — i.e. every cell read precedes every relabel.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, verbatim:
@@SOURCE@@
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=IR    --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CXOR  --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CMEAS --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOTS  --input-file=%t.ll %s
;
; IR: %h = call i32 @cqrt_alloc_i32(
; IR: alloca i32, i64 %{{[0-9]+}}, align 16, !cq.railbank
; IR: store i32 %h, ptr
; IR: [[MEXIT:[0-9]+]]: ; preds = %[[MLOOP:[0-9]+]]{{$}}
; IR-NEXT: = tail call i32 @llvm.smax.i32(
; IR-NEXT: br label %[[XLOOP:[0-9]+]]
; IR: [[MLOOP]]:
; IR: [[CELL:%[0-9]+]] = load i32, ptr
; IR-NEXT: call i32 @cqrt_measure_i32(i32 [[CELL]])
; IR: br i1 %{{[0-9]+}}, label %[[MEXIT]], label %[[MLOOP]]
; IR: [[XLOOP]]:
; IR: call void @cqrt_xorc_i32(i32 %h, i32 3)
;
; ⚠ One whole-file prefix per count (Rule 12 (a)).
; CXOR-COUNT-1: call void @cqrt_xorc_i32(
; CMEAS-COUNT-2: call i32 @cqrt_measure_i32(
;
; NOTS-NOT: cqrt_qram_
; NOTS-NOT: cqrt_free(i32 %h)
"""
h = SP / "hdr_legit.txt"
h.write_text(LEGIT)
subprocess.run(["python3", str(SP / "mkfix.py"), "probes2/P1_legit.bank",
                "railbank_stale_accept_inloop_xor_legit_order.ll", str(h)], check=True)
