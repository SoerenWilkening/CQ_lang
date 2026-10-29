#!/bin/bash
# check.sh [N]: run check1.sh on up to N (default 800) bitcode TUs with no current result (none, older
# than the object, another plugin hash, old format: report.py --pending) in one heavy.sh run (xargs -P 8),
# after the negative control (control.sh) in its own heavy.sh run. Resumable: rerun until 0 pending.
# PLUGIN selects the pass (default: this checkout's build, env.sh); every result records its sha256.
# Exit: 0 when the batch ran and every TU it checked is identical (or nothing was pending); 1 when there
# are no TUs, the control fails, the plugin is missing or changed during the batch, or any TU of the
# batch is not identical; 124 when heavy.sh killed the batch (its finished results stay; rerun).
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
. "$here/env.sh"
N=${1:-800}
mkdir -p "$CHK/res"
[ -f "$PLUGIN" ] || { echo "check: FAILED, no plugin at $PLUGIN (build first)" >&2; exit 1; }
PLUGIN_SHA=$(shasum -a 256 "$PLUGIN" | cut -d' ' -f1); export PLUGIN_SHA
echo "check: plugin $PLUGIN sha256 $PLUGIN_SHA"
"$HEAVY" "$here/control.sh" || { echo "check: FAILED, control" >&2; exit 1; }
list=$CHK/pending.txt
python3 "$here/report.py" --pending > "$list" || { echo "check: FAILED, no TU list" >&2; exit 1; }
total=$(wc -l < "$list" | tr -d ' ')
echo "check: $total pending, running $(( total < N ? total : N ))"
[ "$total" -eq 0 ] && exit 0
head -n "$N" "$list" > "$list.batch"
# a batch TU's old result (stale) goes first, so every result after the batch is the batch's own
while read -r o; do rm -f "$CHK/res/$(printf '%s' "$o" | tr '/' '%')"; done < "$list.batch"
"$HEAVY" -t 600 sh -c 'xargs -P 8 -n 1 "$2" < "$1"' check "$list.batch" "$here/check1.sh"; st=$?
now=$(shasum -a 256 "$PLUGIN" | cut -d' ' -f1)
[ "$now" = "$PLUGIN_SHA" ] || { echo "check: FAILED, plugin changed during the batch" >&2; exit 1; }
# the batch's verdicts: every TU of the batch must have a result under this plugin, and be identical
bad=0; done_=0
while read -r o; do
  r="$CHK/res/$(printf '%s' "$o" | tr '/' '%')"
  [ -f "$r" ] || continue
  IFS=$'\t' read -r _ v _ _ p _ < "$r"
  [ "$p" = "$PLUGIN_SHA" ] || { bad=$((bad+1)); echo "check: $o result under plugin $p" >&2; continue; }
  done_=$((done_+1))
  [ "$v" = identical ] || { bad=$((bad+1)); echo "check: $o $v" >&2; }
done < "$list.batch"
echo "check: batch checked $done_ of $(wc -l < "$list.batch" | tr -d ' '), $bad not identical"
[ $bad -eq 0 ] || { echo "check: FAILED, $bad TUs not identical" >&2; exit 1; }
[ $st -eq 0 ] || { echo "check: batch exit $st (heavy.sh 124 = killed; rerun to resume)" >&2; exit $st; }
n=$(wc -l < "$list.batch" | tr -d ' ')
[ "$done_" -eq "$n" ] || { echo "check: FAILED, $((n-done_)) TUs of the batch recorded no result" >&2; exit 1; }
