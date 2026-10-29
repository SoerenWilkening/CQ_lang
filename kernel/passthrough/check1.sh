#!/bin/bash
# check1.sh OBJ: the tier-1 identity check of one TU's bitcode (cq-w1-kernel-t1).
#   A = opt OBJ                         (a plain opt round trip, no passes)
#   B = opt -passes=cq-lower OBJ        (the pass)
# identical iff A and B are byte-identical (owner ruling on cq-arch, 2026-10-27: "passthrough identity
# = byte-identical to a plain opt round trip on the same input"). Writes one line to $CHK/res/<key>:
#   object <TAB> verdict <TAB> sha256(OBJ) <TAB> triple <TAB> detail
# verdict: identical | differ | opt-error | pass-error. Never runs under its own pool: check.sh feeds
# it through heavy.sh with xargs -P 8.
set -u
obj=$1
key=$(printf '%s' "$obj" | tr '/' '%')
t=$(mktemp -d "${TMPDIR:-/tmp}/cqk.XXXXXX"); trap 'rm -rf "$t"' EXIT
sha=$(shasum -a 256 "$KOUT/$obj" | cut -d' ' -f1)
triple=$("$LLVM_BIN/llvm-dis" -o - "$KOUT/$obj" 2>/dev/null | sed -n 's/^target triple = "\(.*\)"/\1/p' | head -1)
v=identical; d=
if ! "$LLVM_BIN/opt" "$KOUT/$obj" -o "$t/a.bc" 2>"$t/a.err"; then v=opt-error; d=$(head -c 300 "$t/a.err" | tr '\t\n' '  ')
elif ! "$LLVM_BIN/opt" -load-pass-plugin="$PLUGIN" -passes=cq-lower "$KOUT/$obj" -o "$t/b.bc" 2>"$t/b.err"; then
  v=pass-error; d=$(head -c 300 "$t/b.err" | tr '\t\n' '  ')
elif ! cmp -s "$t/a.bc" "$t/b.bc"; then v=differ; d=$(cmp "$t/a.bc" "$t/b.bc" 2>&1 | head -1)
fi
printf '%s\t%s\t%s\t%s\t%s\n' "$obj" "$v" "$sha" "$triple" "$d" > "$CHK/res/$key.tmp" && mv "$CHK/res/$key.tmp" "$CHK/res/$key"
