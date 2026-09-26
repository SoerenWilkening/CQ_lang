#!/bin/bash
# fixture_on.sh BINARY FIXTURE [extra FileCheck args]: run the fixture's decline
# check (`not <bin> ... 2>&1 | FileCheck FIXTURE --implicit-check-not=...`) with an
# arbitrary binary; prints PASS/FAIL (the lit verdict that binary would get).
L=/usr/local/opt/llvm@19/bin
B=$1; F=$2; shift 2
out=$("$B" -passes=cq-lowering -S "$F" -o /dev/null 2>&1); rc=$?
if [ "$rc" -eq 0 ]; then echo "FAIL (exit 0, the RUN line's 'not' fails) $(basename "$B")"; exit 1; fi
if printf '%s\n' "$out" | "$L/FileCheck" "$F" "$@" > /dev/null 2>&1; then
  echo "PASS $(basename "$B")"
else
  echo "FAIL (FileCheck) $(basename "$B"): $(printf '%s\n' "$out" | grep -o 'in function.*' | head -1)"
fi
