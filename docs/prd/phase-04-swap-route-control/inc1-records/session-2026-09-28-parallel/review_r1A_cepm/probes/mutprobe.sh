#!/bin/bash
# mutprobe.sh BIN name... : rc | first error | sha of lowered IR, per C-side probe
S=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad
B="$1"; shift; cd "$S/r1A_cepm/p"
for b in "$@"; do "$B" -passes=cq-lowering -S "${b}C.s1.ll" -o /tmp/mp.$$.ll 2> /tmp/mp.$$.err; rc=$?
  printf '%-5s rc=%s %s %s\n' "$b" "$rc" "$(shasum -a 256 /tmp/mp.$$.ll | cut -c1-12)" "$(grep -m1 'error:' /tmp/mp.$$.err | sed 's/.*error: //' | cut -c1-90)"; done
rm -f /tmp/mp.$$.*
