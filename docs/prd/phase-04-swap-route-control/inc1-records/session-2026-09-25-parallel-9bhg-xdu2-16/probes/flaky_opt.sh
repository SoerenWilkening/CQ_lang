#!/bin/bash
# POSITIVE CONTROL for ab_sweep.py --null: a deliberately FLAKY "cq-opt". It
# behaves like the merged binary except that on every other invocation for the
# file whose name contains FLAKY_TARGET it appends a comment line, i.e. its
# stdout differs from run to run.
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad
out=$("$S/frozen/cq-opt.merged" "$@")
rc=$?
printf '%s\n' "$out"
case "$*" in
  *taint_accept_spec_classical_return.ll*)
    c=$S/p9/.flaky_count; n=$(( $(cat "$c" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$c"
    [ $((n % 2)) -eq 0 ] && echo "; flaky" ;;
esac
exit $rc
