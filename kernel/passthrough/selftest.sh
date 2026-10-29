#!/bin/bash
# selftest.sh: the harness's failure modes (cq-ls7l) on throwaway kernel trees, never the real one.
#   empty      no TUs: tus.py, check.sh and report.py each exit non-zero
#   identity   one plain TU: check.sh and report.py exit 0 (the positive case the others are against)
#   stale      the same result under another plugin hash, and in the old 5-field format: report.py
#              exit 1 and report.py --pending lists the TU again
#   differ     a TU with quantum data (CQ_spec 01): check.sh and report.py exit 1
#   noplugin   PLUGIN missing: check.sh exits 1
# check.sh runs its control and batch under heavy.sh itself; run this script plainly.
set -u; KEEP=${KEEP:-}
here=$(cd "$(dirname "$0")" && pwd)
. "$here/env.sh"
[ -f "$PLUGIN" ] || { echo "selftest: no plugin at $PLUGIN (set PLUGIN or build first)" >&2; exit 1; }
fails=0
t=$(mktemp -d "${TMPDIR:-/tmp}/cqkst.XXXXXX"); [ -n "$KEEP" ] && echo "keeping $t" || trap 'rm -rf "$t"' EXIT
expect() {  # expect <want: 0|nonzero> <name> <cmd...>
  local want=$1 name=$2; shift 2
  "$@" >"$t/out" 2>&1; local st=$?
  if { [ "$want" = 0 ] && [ $st -eq 0 ]; } || { [ "$want" = nonzero ] && [ $st -ne 0 ]; }; then
    echo "ok    $name (exit $st)"
  else echo "FAIL  $name (exit $st, wanted $want)"; sed 's/^/      /' "$t/out"; fails=$((fails+1)); fi
}
tree() {  # tree <dir> [<name> <source .ll>]...: a fake KSRC whose KOUT holds the given TUs as bitcode
  local d=$1; shift
  mkdir -p "$d/mnt/build/t" "$d/mnt/linux/t" "$d/logs"
  while [ $# -gt 0 ]; do
    "$LLVM_BIN/llvm-as" "$2" -o "$d/mnt/build/t/$1.o"; : > "$d/mnt/linux/t/$1.c"
    echo "savedcmd_t/$1.o := /gone/wt/x/kernel/passthrough/kcc -c -O1 -o t/$1.o $d/mnt/linux/t/$1.c" \
      > "$d/mnt/build/t/.$1.o.cmd"
    shift 2
  done
}
cat > "$t/plain.ll" <<'LL'
target triple = "x86_64-unknown-linux-gnu"
define i32 @f(i32 %x) {
  %y = add i32 %x, 1
  ret i32 %y
}
LL
q=$(cd "$PASSTHROUGH/../.." && pwd)/../CQ_spec/examples/01_add_classical_const/add_classical_const.O1.ll
[ -f "$q" ] || q=$WT/CQ_spec/examples/01_add_classical_const/add_classical_const.O1.ll

tree "$t/empty"
expect nonzero "empty: tus.py"    env KSRC="$t/empty" bash -c ". '$here/env.sh'; python3 '$here/tus.py'"
expect nonzero "empty: check.sh"  env KSRC="$t/empty" "$here/check.sh"
expect nonzero "empty: report.py" env KSRC="$t/empty" REPORT_DIR="$t/empty" python3 "$here/report.py"

tree "$t/id" a "$t/plain.ll"
expect 0 "identity: check.sh"  env KSRC="$t/id" "$here/check.sh"
expect 0 "identity: report.py" env KSRC="$t/id" REPORT_DIR="$t/id" python3 "$here/report.py"
cp "$PLUGIN" "$t/other.so"; printf x >> "$t/other.so"
expect nonzero "stale plugin: report.py" env KSRC="$t/id" PLUGIN="$t/other.so" REPORT_DIR="$t/id" python3 "$here/report.py"
expect 0 "stale plugin: --pending lists it" env KSRC="$t/id" PLUGIN="$t/other.so" \
  bash -c "python3 '$here/report.py' --pending | grep -qx t/a.o"
r="$t/id/check/res/t%a.o"; cut -f1-4,6 "$r" > "$r.old"; touch -r "$r" "$r.old"; mv "$r.old" "$r"
expect nonzero "stale format: report.py" env KSRC="$t/id" REPORT_DIR="$t/id" python3 "$here/report.py"
expect 0 "stale format: --pending lists it" env KSRC="$t/id" \
  bash -c "python3 '$here/report.py' --pending | grep -qx t/a.o"

tree "$t/q" a "$t/plain.ll" q "$q"
expect nonzero "differ: check.sh"  env KSRC="$t/q" "$here/check.sh"
expect 0 "differ: recorded" grep -q $'\tdiffer\t' "$t/q/check/res/t%q.o"
expect nonzero "differ: report.py" env KSRC="$t/q" REPORT_DIR="$t/q" python3 "$here/report.py"

expect nonzero "noplugin: check.sh" env KSRC="$t/id" PLUGIN="$t/none.so" "$here/check.sh"

[ $fails -eq 0 ] && echo "selftest: all ok" || { echo "selftest: $fails FAILED"; exit 1; }
