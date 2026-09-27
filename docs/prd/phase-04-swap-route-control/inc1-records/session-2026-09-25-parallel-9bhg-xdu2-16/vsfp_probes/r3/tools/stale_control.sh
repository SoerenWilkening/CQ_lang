#!/bin/bash
# stale_control.sh : the mutation harness's debugalloc boundary controls.
# (1) a STALE debugalloc (older mtime than the cq-opt under test) must make lit FATAL;
# (2) an UNSET VSFP_DEBUGALLOC must make the site config fail (KeyError), never default.
# Each prints its rc and the diagnostic; both must be non-zero.
V=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/vsfp
cd "$V" || exit 1
cp -f bin/cq-opt-debugalloc.N0_null bin/cq-opt-debugalloc.stale
touch -t 202001010000 bin/cq-opt-debugalloc.stale
VSFP_CQ_OPT="$V/bin/cq-opt.N0_null" VSFP_DEBUGALLOC="$V/bin/cq-opt-debugalloc.stale" \
  lit litora --filter 'spec_scrub_dangling' > stale_debugalloc.txt 2>&1
rc1=$?
echo "stale: rc=$rc1" >> stale_debugalloc.txt
VSFP_CQ_OPT="$V/bin/cq-opt.N0_null" env -u VSFP_DEBUGALLOC \
  lit litora --filter 'spec_scrub_dangling' >> stale_debugalloc.txt 2>&1
rc2=$?
echo "unset: rc=$rc2" >> stale_debugalloc.txt
VSFP_CQ_OPT="$V/bin/cq-opt.N0_null" VSFP_DEBUGALLOC="$V/bin/cq-opt-debugalloc.N0_null" \
  lit litora --filter 'spec_scrub_dangling' >> stale_debugalloc.txt 2>&1
rc3=$?
echo "fresh (positive control): rc=$rc3" >> stale_debugalloc.txt
grep -E "fatal|OLDER|KeyError|rc=|Passed|Failed" stale_debugalloc.txt | cut -c1-220
