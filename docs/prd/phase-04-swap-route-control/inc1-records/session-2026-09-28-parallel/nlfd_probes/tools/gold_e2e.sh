#!/bin/bash
# gold_e2e.sh [--write] : the e2e slices this track adds or re-witnesses, run on the SUBJECT
# and the ORACLE with the harness recipe (mkgold.sh); prints status lines, twin identity, and
# (with --write) writes the SUBJECT traces as the goldens.
set -u
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a333a1777db2f2295
H=$(cd "$(dirname "$0")" && pwd)
OR=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/frozen/cq-opt.main_9a230646
S=$W/build/ir-pass/cq-opt
O=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/nlfd/gold
mkdir -p $O
E=$W/tests/e2e
run() {  # name cq lib
  for tag in S O; do
    b=$S; [ $tag = O ] && b=$OR
    printf '%-44s %s: ' "$1" "$tag"; "$H/mkgold.sh" "$b" "$2" "$3" "$O/$1.$tag.trace"
  done
}
run musttail_return      $E/slice_spec_dropped_arg_musttail_return.c $E/spec_dropped_arg_musttail_return_lib.c
run musttail_return_twin $E/slice_spec_dropped_arg_musttail_return_twin.c -
run musttail_inner       $E/slice_spec_dropped_arg_musttail_inner.c $E/spec_dropped_arg_musttail_lib.c
run musttail_inner_twin  $E/slice_spec_dropped_arg_musttail_inner_twin.c -
for p in musttail_return musttail_inner; do
  cmp -s $O/$p.S.trace $O/${p}_twin.S.trace && echo "$p: SUBJECT TWIN-IDENT" || echo "$p: SUBJECT TWIN-DIFF"
  cmp -s $O/$p.O.trace $O/${p}_twin.O.trace && echo "$p: ORACLE TWIN-IDENT" || echo "$p: ORACLE TWIN-DIFF"
done
cmp -s $O/musttail_inner.S.trace $E/slice_spec_dropped_arg_musttail_inner.expected.log && echo "musttail_inner: SUBJECT == committed golden"
if [ "${1:-}" = "--write" ]; then
  cp -f $O/musttail_return.S.trace $E/slice_spec_dropped_arg_musttail_return.expected.log
  cp -f $O/musttail_return_twin.S.trace $E/slice_spec_dropped_arg_musttail_return_twin.expected.log
  echo wrote goldens
fi
