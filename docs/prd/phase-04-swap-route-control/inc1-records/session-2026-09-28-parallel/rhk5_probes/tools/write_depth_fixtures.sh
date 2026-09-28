#!/bin/bash
# write_depth_fixtures.sh : the two nesting-cap fixtures (bd rhk5 round 2; r1A F-r1A-5).
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a7712272d6ca568e9
G="$W/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/rhk5_probes/tools/gen_depth_fixture.py"
T=$W/ir-pass/test
TMP=$(mktemp -d)
python3 "$G" 15 "$TMP/d15.ll"
python3 "$G" 16 "$TMP/d16.ll"
{
cat <<'EOF'
; spec_accept_clone_read_depth_at_cap.ll — ACCEPT, DISCHARGED (bd rhk5 round 2; r1A
; F-r1A-5). The d4 caller with its clone call nesting FIFTEEN `noinline` helpers
; (h -> g1 -> … -> g15): proving the outer call read-only walks 16 (function, formal)
; pairs, exactly the nesting cap `kMaxCloneNesting` admits. Pinned beside
; spec_leak_clone_read_depth_cap.ll (sixteen helpers, 17 pairs, refused) so the cap
; is fixed at its value from BOTH sides: lowering it turns THIS file red, raising or
; deleting it turns the other red.
;
; ⚠ The cap is a CONSERVATIVE bound, not a physics fence: every body in the 17-pair
; chain is read-only too, and the refusal there is an over-leak. It exists because
; the proof recurses on the native stack. RETIREMENT TRIGGER (L8): if the walk is
; made iterative, retire the cap and turn the other file into an accept.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=SILENT --allow-empty < %t.err
; RUN: %filecheck %s --check-prefix=LOWER < %t.cqd0.ll

EOF
cat "$TMP/d15.ll"
cat <<'EOF'

; SILENT-NOT: warning
; SILENT-NOT: error
; LOWER-LABEL: define i32 @slice(
; LOWER: %s = call i32 @__cq_q_h_10(i32 0, i32 %h)
; LOWER: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)
; LOWER-NEXT: call void @cq_template_xor_i32_unc(i32 %h_op1, i32 %h, i32 %h_op)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op1)
; LOWER-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; LOWER-NEXT: call void @cqrt_free(i32 %h_op)
; LOWER: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
EOF
} > "$T/spec_accept_clone_read_depth_at_cap.ll"
{
cat <<'EOF'
; spec_leak_clone_read_depth_cap.ll — LEAK + WARNING (bd rhk5 round 2; r1A F-r1A-5).
; The d4 caller with its clone call nesting SIXTEEN `noinline` helpers: 17
; (function, formal) pairs, one more than `kMaxCloneNesting`, so the proof refuses and
; the caller's chain leaks with the lyyf-(B) warning — the oracle's disposition. See
; spec_accept_clone_read_depth_at_cap.ll for why this is an over-leak, pinned
; deliberately, and its retirement trigger.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll 2> %t.err
; RUN: %filecheck %s --check-prefix=WARN < %t.err
; RUN: %filecheck %s --check-prefix=LEAK < %t.cqd0.ll

EOF
cat "$TMP/d16.ll"
cat <<'EOF'

; WARN: warning: {{.*}}cq rotation lowering: non-diagonal gate over a live derived record
; LEAK-LABEL: define i32 @slice(
; LEAK: %s = call i32 @__cq_q_h_10(i32 0, i32 %h)
; LEAK: call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h_op1, i32 10)
; LEAK-NOT: call void @cq_template_xor_i32_unc(
; LEAK-NOT: call void @cq_template_mul_i32_hl_unc(i32 %h_op, i32 %h, i32 3)
; LEAK: call void @cqrt_ry_i32(i32 %h, double 0x3FE6666666666666)
EOF
} > "$T/spec_leak_clone_read_depth_cap.ll"
rm -rf "$TMP"
echo wrote
