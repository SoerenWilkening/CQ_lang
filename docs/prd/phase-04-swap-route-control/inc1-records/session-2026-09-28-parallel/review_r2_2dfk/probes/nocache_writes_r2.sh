#!/bin/bash
# r2 probe: CQ_E2E_NO_CACHE=1 into an EMPTY cache dir writes nothing (S1, 2b, run; bash + python).
. "$(dirname "$0")/env.sh"
E=$SP/rev_r2_cache_empty; rm -rf "$E"; mkdir -p "$E"
D "$T1|$T4|^e2e-railbank-dynamic-admission-matrix$" "$E" --nocache | tail -1
echo "files written under NO_CACHE: $(find "$E" -type f | wc -l)"
D "$T1|$T4|^e2e-railbank-dynamic-admission-matrix$" "$E" | tail -1
echo "files written with cache on:   $(find "$E" -type f | wc -l)"
rm -rf "$E"
