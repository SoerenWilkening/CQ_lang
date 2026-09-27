W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/ir-pass/test/'
old = '''; one rewrite applies the pre-`specialize()` drop's own eligibility (`dropEligibleSlot`: an int/fp
; scalar, no `byval`/`inalloca`/`preallocated`/`returned`/`swifterror`, allowlisted attributes
; only), so a pointer slot is never rewritten'''
new = '''; one rewrite asks NULL-SOUNDNESS (`nullSafeSlot` since round 6 — round 5 asked the drop's whole
; eligibility `dropEligibleSlot`, whose `musttail` policy was a P1, bd w7nm: an int/fp scalar, no
; `byval`/`inalloca`/`preallocated`/`returned`/`swifterror`, allowlisted attributes only), so a
; pointer slot is never rewritten'''
for f in ('spec_accept_phantom_arg_read_byval_slot_kept.ll', 'spec_accept_phantom_arg_read_byval_inner_slot_kept.ll',
          'spec_accept_phantom_arg_read_pointer_slot_kept.ll'):
    s = open(W + f).read()
    assert s.count(old) == 1, f
    open(W + f, 'w').write(s.replace(old, new))
print('ok')
