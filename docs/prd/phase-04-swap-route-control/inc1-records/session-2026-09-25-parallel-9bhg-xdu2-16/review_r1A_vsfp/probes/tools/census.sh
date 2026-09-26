#!/usr/bin/env bash
# census.sh <bin> <outfile> <files...>: run bin with CQ_DEADARG_DBG=1 on each file; record DBG lines per file
# INSTRUMENT NOTE: v1 used `timeout`, absent on this box -> every run exited 127 and FIRED=0 over the full
# denominator. v2 uses perl alarm, counts rc>=126 as TOOLFAIL, and requires a positive control.
bin=$1; out=$2; shift 2
: > $out
n=0; fired=0; bad=0; toolfail=0
for f in "$@"; do
  n=$((n+1))
  if [ ! -r "$f" ]; then echo "UNREADABLE $f" >> $out; bad=$((bad+1)); continue; fi
  CQ_DEADARG_DBG=1 perl -e 'alarm 60; exec @ARGV' $bin -passes=cq-lowering -S "$f" -o /dev/null 2> $out.tmp.err
  rc=$?
  if [ $rc -ge 126 ] && [ $rc -ne 134 ]; then toolfail=$((toolfail+1)); echo "TOOLFAIL rc=$rc $f" >> $out; fi
  c=$(grep -c '^CQ_DEADARG_DBG' $out.tmp.err)
  if [ "$c" -gt 0 ]; then fired=$((fired+1)); echo "FIRE rc=$rc n=$c $f" >> $out; grep '^CQ_DEADARG_DBG' $out.tmp.err | sed 's/^/    /' >> $out; fi
done
rm -f $out.tmp.err
echo "DENOM=$n FIRED=$fired UNREADABLE=$bad TOOLFAIL=$toolfail" >> $out
tail -1 $out
