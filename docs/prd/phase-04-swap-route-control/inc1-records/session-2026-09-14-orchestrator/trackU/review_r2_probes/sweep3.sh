#!/bin/bash
# THE DECISIVE ROUND-2 INSTRUMENT.  Three verdicts per fixture:
#   O_u = ORACLE  on the UNDEF-seed mutant   (what HEAD does with an undef seed)
#   S_u = SUBJECT on the UNDEF-seed mutant   (what bd z9t1 does with it)
#   O_z = ORACLE  on the ZERO-seed mutant    (what "the seed IS zero" means at HEAD)
# The rule's claim is S_u == O_z, exactly and everywhere.  Any row where they
# differ is the rule doing something other than substituting a zero.
# Row: <fixture>|<O_u>|<S_u>|<O_z>|<S_u vs O_z>|<O_u vs S_u>
ORC=/Users/sorenwilkening/Desktop/CQ_lang
SUBJ=/Users/sorenwilkening/Desktop/CQ_undef
D="$(cd "$(dirname "$0")" && pwd)"
MU=$1; MZ=$2; OUT=$3; JOBS=${4:-5}
: > "$OUT"; mkdir -p "$D/sweep3all_diff"
one() {
  rel="$1"; T=$(mktemp -d)
  v() { local root=$1 f=$2 tag=$3 rc
    "$root/build/ir-pass/cq-opt" -load-pass-plugin "$root/build/ir-pass/libCQPass.so" \
        -passes=cq-lowering -S "$f" -o "$T/$tag.ll" 2>"$T/$tag.err"; rc=$?
    if [ $rc -eq 0 ]; then echo "A:$(md5 -q "$T/$tag.ll" | cut -c1-8)"
    else echo "D$rc:$(shasum -a 256 "$T/$tag.err" | cut -c1-8)"; fi; }
  OU=$(v $ORC  "$MU/$rel" ou); SU=$(v $SUBJ "$MU/$rel" su); OZ=$(v $ORC "$MZ/$rel" oz)
  # S_u vs O_z
  if [[ "$SU" == A:* && "$OZ" == A:* ]]; then
    if cmp -s "$T/su.ll" "$T/oz.ll"; then EQ=EQ; else EQ=DIFF; diff "$T/oz.ll" "$T/su.ll" > "$D/sweep3all_diff/$rel.szdiff"; fi
  elif [[ "$SU" == D* && "$OZ" == D* ]]; then
    if cmp -s "$T/su.err" "$T/oz.err"; then EQ=EQ; else EQ=DIFFMSG; cp -f "$T/su.err" "$D/sweep3all_diff/$rel.su.err"; cp -f "$T/oz.err" "$D/sweep3all_diff/$rel.oz.err"; fi
  else EQ=CLASS; cp -f "$T/su.err" "$D/sweep3all_diff/$rel.su.err" 2>/dev/null; cp -f "$T/oz.err" "$D/sweep3all_diff/$rel.oz.err" 2>/dev/null; fi
  # O_u vs S_u (blast radius)
  if [ "$OU" = "$SU" ]; then BR=SAME; else BR="${OU:0:1}->${SU:0:1}"; fi
  # does the SUBJECT's accepted output put an `undef` into any emitted gate slot?
  U=""
  if [[ "$SU" == A:* ]]; then
    if grep -E '@(cqrt_|cq_template_)' "$T/su.ll" | grep -q 'undef\|poison'; then U=UNDEF_IN_GATE; fi
  fi
  echo "$rel|$OU|$SU|$OZ|$EQ|$BR|$U"; rm -rf "$T"
}
export -f one; export ORC SUBJ D MU MZ
ls "$MU" | sort | xargs -P "$JOBS" -I{} bash -c 'one "$@"' _ {} >> "$OUT"
echo DONE >> "$OUT"
