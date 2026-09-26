#!/bin/bash
# k65_e2e_repeat.sh <R2 scratch dir with bin/ and corp/e2e/> : 20 runs per binary/allocator of the
# e2e k65 stage-1 module; reference = the subject's own output (same relative input path, so the
# ModuleID line matches); counts non-reference outputs and outputs containing cq_template_mul.
cd "$1"
M=corp/e2e/m_e2e-spec-scrub-dangling-key.ll; ref=ab/e2eSubjA/m_e2e-spec-scrub-dangling-key.ll.out
run() { local tag=$1; shift; local bad=0 mul=0; for i in $(seq 1 20); do "$@" -passes=cq-lowering -S $M -o k65e.x.ll 2>/dev/null; cmp -s k65e.x.ll $ref || bad=$((bad+1)); grep -q cq_template_mul k65e.x.ll && mul=$((mul+1)); done; echo "$tag: non-reference $bad/20, emits cq_template_mul $mul/20"; }
run "oracle system" bin/cq-opt.ora
CQ_OPT_DEBUG_ALLOC=lifo run "oracle rb8-lifo" ./ora_wrap.sh
CQ_OPT_DEBUG_ALLOC=nofree run "oracle rb8-nofree" ./ora_wrap.sh
run "subject system" bin/cq-opt.subj
CQ_OPT_DEBUG_ALLOC=lifo run "subject debugalloc-lifo" bin/cq-opt-debugalloc.subj
