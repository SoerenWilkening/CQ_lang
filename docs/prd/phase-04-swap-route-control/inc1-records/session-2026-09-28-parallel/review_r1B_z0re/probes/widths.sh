#!/bin/bash
for p in "b 1" "i8 -3" "u8 200" "i16 -3" "u16 65000" "i64 -5000000000" "u64 18000000000000000000" "f32 0.1" "f64 -0.0" "f16 0.1" "f80 0.1"; do set -- $p; echo "== w_$1 SUBJ ($2)"; ./run.sh S src/w_$1.c -- $2 4 | grep -E 'DECLINE|error|alloc|ry_i|ry_f|controlled|violation' ; echo "== wu_$1 ORA ($2)"; ./run.sh O src/wu_$1.c -- $2 4 | grep -E 'DECLINE|error|alloc|violation'; done
