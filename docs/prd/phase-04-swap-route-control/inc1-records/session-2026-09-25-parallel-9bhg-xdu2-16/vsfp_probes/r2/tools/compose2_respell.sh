#!/bin/bash
# compose2_respell.sh : in compwt2 (vsfp round 2 merged with bd 9bhg f2148d0a) resolve the
# two conflicted fixtures by taking bd 9bhg's version, then apply the round-2 re-spell
# (a BRANCH-ONLY read in @h, env-armed census, CHECK-NOT: CQ_DEADARG_DBG, a note) to
# them and to bd 9bhg's other fixtures whose callee ignores `a`.
set -e
V=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp
C=$V/compwt2
cd "$C"
git checkout --theirs ir-pass/test/taint_reject_scrubbed_handle_clone_arg.ll ir-pass/test/taint_reject_scrubbed_handle_clone_arg_mixed.ll
FIX="taint_reject_scrubbed_handle_clone_arg taint_reject_scrubbed_handle_clone_arg_mixed taint_accept_spec_classical_return taint_accept_spec_classical_return_arith taint_accept_spec_classical_return_branch taint_accept_spec_classical_return_clone_arg taint_reject_scrubbed_handle_clone_arg_layout"
for f in $FIX; do
  python3 "$V/respell_compose.py" "ir-pass/test/$f.ll" h 0
  python3 "$V/respell2.py" "ir-pass/test/$f.ll"
  python3 - "ir-pass/test/$f.ll" <<'EOF'
import sys
p = sys.argv[1]
s = open(p).read()
old = "; file's subject would be gone. The dead read `%vsfp.read` keeps the parameter used; the\n; `CHECK-NOT: CQ_DEADARG_DBG` pins that the drop does not fire (CLAUDE.md L8)."
new = ("; file's subject would be gone. A BRANCH-ONLY read (`%vsfp.c` and an EMPTY diamond on it)\n"
       "; keeps the parameter LIVE — round 2's drop asks liveness, so a dead `mul` read no longer\n"
       "; does; a branch condition is a liveness root (no control dependence). The clone's own\n"
       "; flatten then removes the read. `CHECK-NOT: CQ_DEADARG_DBG` pins that the drop does not\n"
       "; fire (CLAUDE.md L8).")
assert old in s, p
open(p, "w").write(s.replace(old, new))
EOF
done
git add ir-pass/test/taint_reject_scrubbed_handle_clone_arg.ll ir-pass/test/taint_reject_scrubbed_handle_clone_arg_mixed.ll
echo resolved
