#!/bin/bash
# One row of the PROMOTER-FIRE differential. $1 = module.
# Row: "<name>|<oracle fires>|<subject fires>[|<oracle dump-sha16> <subject dump-sha16>]"
# The dump sha256 is taken ONLY when either binary fires — capturing a whole module
# dump into a shell variable for every module of a 2000-file corpus is what made the
# first spelling of this script too slow to finish (and a sweep that does not finish
# reports nothing, which is worse than a slow one).
SUBJ=${SUBJ:-/Users/sorenwilkening/Desktop/CQ_A/build}
ORAC=${ORAC:-/Users/sorenwilkening/Desktop/CQ_lang/build}
n() { CQ_RAILBANK_DBG=1 "$1/ir-pass/cq-opt" -passes=cq-lowering -S "$2" -o /dev/null 2>&1 \
        | grep -c 'CQ_RAILBANK_DBG: promote bank'; }
d() { CQ_RAILBANK_DBG=1 "$1/ir-pass/cq-opt" -passes=cq-lowering -S "$2" -o /dev/null 2>&1 \
        | sed -n '/=== CQ_RAILBANK_DBG: module after/,$p' | shasum -a 256 | cut -c1-16; }
O=$(n "$ORAC" "$1"); S=$(n "$SUBJ" "$1")
if [ "$O" != "0" ] || [ "$S" != "0" ]; then
  echo "$(basename "$1")|$O|$S|$(d "$ORAC" "$1") $(d "$SUBJ" "$1")"
else
  echo "$(basename "$1")|$O|$S"
fi
