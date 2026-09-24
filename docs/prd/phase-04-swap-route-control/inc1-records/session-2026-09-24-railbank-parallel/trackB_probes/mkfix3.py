#!/usr/bin/env python3
"""Round-3 F-R3-1 fixtures, matrix rows and twin pairs."""
import pathlib, subprocess, shutil
SP = pathlib.Path(__file__).parent
WT = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a784cc15f4136a8dc")
MSG = "cq loop lowering: rail record read past an in-place gate on the same rail"

COMMON = """;
; bd `xdu2.1` (Track B), Rule-13 round-3 finding F-R3-1 (2026-09-24) — a P1
; OVER-ACCEPT, PRE-EXISTING on main (preA/preD) and NOT closed by the round-2 fix.
; The value parked in the bank is the IN-PLACE op's own result, INSIDE the loop
; that relabels it: cell k holds the wire after k+1 ops, the next trip's op
; relabels the SAME wire, and the cells are read after the loop. Round-2 binary
; (`cq-opt` 427492b12c4162e2): exit 0, STRICT 2b clean, every bank measure reads
; the FINAL wire. MECHANISM: the round-2 bank-load hop in `staleReadOfValue`
; reused the SSA `Refreshes` cut — "re-running Def makes the NAME denote the new
; value" — which is FALSE for a memory cell (cell k keeps activation k's value),
; so every `Def → back edge → gate` path was cut and `Def → exit → load` was
; gate-free. FIX: the bank hop passes `DefRefreshes=false`. RED on 427492b1
; (accepts), GREEN after (declines with the register fence's string). The
; hand-unrolled register twin ACCEPTS with a correct out-of-place stream, so
; this decline is an OVER-DECLINE of a realizable circuit (filed in
; `TRACK_B.md` §6c) — the Prime-Directive answer until a bank-aware copy-out
; lowering exists. Pinned by the `not` inversion + the verbatim string.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, verbatim:
@@SOURCE@@
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \\
; RUN:   | %filecheck %s
; CHECK: """ + MSG + "\n"

FIX = {
  "railbank_stale_reject_inloop_xor_park_after_op.ll": ("probes4/a1_park_after_xor.bank",
    "; railbank_stale_reject_inloop_xor_park_after_op.ll — reviewer a1: `q ^= 3; b[k] = q;`\n"),
  "railbank_stale_reject_inloop_add_park_after_op_slice.ll": ("probes4/e2_slice.bank",
    "; railbank_stale_reject_inloop_add_park_after_op_slice.ll — reviewer e2_slice: `q += 1;\n"
    "; b[k] = q;` outside `main`; the source says cells hold q+1, q+2, q+3.\n"),
  "railbank_stale_reject_inloop_sub_park_after_op.ll": ("probes4/b5_park_after_sub.bank",
    "; railbank_stale_reject_inloop_sub_park_after_op.ll — reviewer b5: `q -= 5; b[k] = q;`\n"),
}
for name, (stem, head) in FIX.items():
    h = SP / ("hdr3_" + name + ".txt")
    h.write_text(head + COMMON)
    subprocess.run(["python3", str(SP / "mkfix.py"), stem, name, str(h)], check=True)

ACC = """; railbank_stale_accept_inloop_xor_park_outofplace.ll — bd `xdu2.1` (Track B),
; Rule-13 round-3 GREEN control (the reviewer's g4 shape, with a trip-invariant
; condition so the stream is IV-free).
;
; `for(k){ if(q>5) cq_phi(.3); q ^= 3; b[k] = q; q ^= 5; }` — the parked value is
; `q^3`, which `-O1` keeps as its own value because `q ^= 5` follows and the two
; xors fold to `q ^= 6` on the rail. So the collapse leaves the parked `q^3`
; OUT OF PLACE (`cq_template_xor_i32_hl` → a fresh rail per trip) and only the
; `^6` in place. The fresh rail is never relabelled, so the cell is not stale and
; the round-3 fix (`DefRefreshes=false` for bank reads) must NOT decline it.
; Measured correct by hand against the unrolled register program (cell k =
; q0 ^ (6k) ^ 3); the register twin is NOT byte-comparable (-O1 folds the
; unrolled xors across iterations — `TRACK_B.md` §6c), so the order is pinned
; here: per trip an out-of-place template xor BEFORE the in-place `xorc 6`,
; the template result stored, and every bank measure reading a cell load.
;
; SOURCE — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, verbatim:
@@SOURCE@@
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=IR    --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CXORC --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=CMEAS --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOTS  --input-file=%t.ll %s
;
; IR: %h = call i32 @cqrt_alloc_i32(
; IR: alloca i32, i64 %{{[0-9]+}}, align 16, !cq.railbank
; IR: [[T:%h_op[0-9]*]] = call i32 @cq_template_xor_i32_hl(i32 %h, i32 3)
; IR: store i32 [[T]], ptr
; IR: call void @cqrt_xorc_i32(i32 %h, i32 6)
; IR: [[CELL:%[0-9]+]] = load i32, ptr
; IR-NEXT: call i32 @cqrt_measure_i32(i32 [[CELL]])
;
; ⚠ One whole-file prefix per count (Rule 12 (a)).
; CXORC-COUNT-1: call void @cqrt_xorc_i32(
; CMEAS-COUNT-2: call i32 @cqrt_measure_i32(
;
; NOTS-NOT: cqrt_qram_
; NOTS-NOT: cqrt_free(i32 %h)
"""
h = SP / "hdr3_acc.txt"; h.write_text(ACC)
subprocess.run(["python3", str(SP / "mkfix.py"), "probes6/w1_xor_park_outofplace.bank",
                "railbank_stale_accept_inloop_xor_park_outofplace.ll", str(h)], check=True)

T = WT / "tools/railbank_twin_pairs"
(T / "p17_inloop_xor_park_after_op.bank.c").write_text(
    "/* Rule-13 round-3 F-R3-1: the IN-PLACE op's result parked inside the relabel loop\n"
    "   (`q ^= 3; b[k] = q;`). Pre-fix VIOLATION? No — the register twin ACCEPTS with a\n"
    "   correct out-of-place stream, so after the fix this row is an OVER-DECLINE\n"
    "   (printed, not failed). It is here so the verdict is visible and so a future\n"
    "   bank-aware lowering that accepts it is byte-compared. */\n#include \"CQ.h\"\n"
    + (SP / "probes6/w2_xor_park_inplace.bank.c").read_text())
(T / "p17_inloop_xor_park_after_op.reg.c").write_text(
    "/* the hand-unrolled n=3 twin of p17. */\n#include \"CQ.h\"\n"
    + (SP / "probes6/w2_xor_park_inplace.reg.c").read_text())
print("ok")
