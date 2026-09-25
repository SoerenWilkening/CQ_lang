#!/bin/bash
# one.sh BIN FILE -> prints "FILE<TAB>rc<TAB>sha(stdout)<TAB>sha(stderr minus path)<TAB>first error line"
BIN="$1"; F="$2"; T=$(mktemp -d)
"$BIN" -passes=cq-lowering -S "$F" -o "$T/o.ll" 2> "$T/e.txt"; rc=$?
so=$( [ -f "$T/o.ll" ] && shasum -a 256 "$T/o.ll" | cut -c1-16 || echo none)
se=$(sed "s#$F#FILE#g" "$T/e.txt" | shasum -a 256 | cut -c1-16)
fe=$(grep -m1 'error:' "$T/e.txt" | sed "s#$F#FILE#g; s/^[^ ]* error: //" | cut -c1-150)
printf '%s\t%s\t%s\t%s\t%s\n' "$(basename "$F")" "$rc" "$so" "$se" "$fe"
rm -rf "$T"
