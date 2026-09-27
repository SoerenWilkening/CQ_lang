import os
os.chdir('/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/ir-pass/test')
NOTE = ('; (bd vsfp round 3, bd tzfa: slot 0 is one the specializer RECORDED dead — the clone never\n'
        '; reads it — so `resolvePhantomCloneArgReads` NEUTRALISES it to `0` after `specialize()`;\n'
        '; the operand is a `cq_theta` result, which the twin keeps, so nothing is declined.)\n')
edits = {
 'spec_result_classical.ll': ('; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_double_classical_01(i32 %{{[a-zA-Z0-9_.]+}}, i32 7)',
                              '; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_double_classical_01(i32 0, i32 7)'),
 'spec_reseed_theta_source.ll': ('; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_cls_01(i32 %{{[a-zA-Z0-9_.]+}}, i32 7)',
                                 '; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_cls_01(i32 0, i32 7)'),
 'lowering_classical_mux_phi_onereg_spec_scrubbed_base_degenerate.ll': ('; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef [[Q]], i32 noundef %5)',
                                 '; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef 0, i32 noundef %5)'),
 'lowering_classical_mux_phi_onereg_spec_scrubbed_elsewhere.ll': ('; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef [[Q]], i32 noundef %5)',
                                 '; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef 0, i32 noundef %5)'),
}
for f, (a, b) in edits.items():
    s = open(f).read()
    assert s.count(a) == 1, f
    s = s.replace(a, NOTE + b)
    open(f, 'w').write(s)
    print('edited', f)
