#!/bin/bash
# control.sh: negative control for check1.sh's comparison (cq-w1-kernel-t1). A module with quantum
# data (CQ_spec examples/01_add_classical_const, which the pass lowers) must come out of cq-lower
# different from the plain opt round trip, through the same commands check1.sh uses; otherwise the
# identity the kernel run reports would be vacuous. Exits 0 iff the control differs.
set -u
here=$(cd "$(dirname "$0")" && pwd)
. "$here/env.sh"
ex=$(cd "$PASSTHROUGH/../.." && pwd)/spec/examples/01_add_classical_const/add_classical_const.O1.ll
[ -f "$ex" ] || ex=$WT/CQ_spec/examples/01_add_classical_const/add_classical_const.O1.ll
t=$(mktemp -d "${TMPDIR:-/tmp}/cqkc.XXXXXX"); trap 'rm -rf "$t"' EXIT
"$LLVM_BIN/llvm-as" "$ex" -o "$t/in.bc" || exit 1
"$LLVM_BIN/opt" "$t/in.bc" -o "$t/a.bc" || exit 1
"$LLVM_BIN/opt" -load-pass-plugin="$PLUGIN" -passes=cq-lower "$t/in.bc" -o "$t/b.bc" || { echo "control: cq-lower failed on $ex" >&2; exit 1; }
if cmp -s "$t/a.bc" "$t/b.bc"; then echo "control: FAILED, cq-lower left $ex unchanged" >&2; exit 1; fi
echo "control: ok, cq-lower rewrites $(basename "$ex") (the comparison can see a change)"
