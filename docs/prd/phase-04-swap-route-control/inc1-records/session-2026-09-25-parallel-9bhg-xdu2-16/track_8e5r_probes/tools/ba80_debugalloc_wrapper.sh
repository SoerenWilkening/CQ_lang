#!/bin/bash
# A `%debugalloc-cq-opt` for the FROZEN, UNMODIFIED main ba80bda1 cq-opt: maps the
# test driver's CQ_OPT_DEBUG_ALLOC=lifo|nofree onto r1B's INDEPENDENT interposer
# (rb8_interpose.dylib, RB8_ALLOC), so the pins can be run RED against the oracle
# with an allocator the subject did not write.
T=/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/t8e5r
export DYLD_INSERT_LIBRARIES="$T/rb8_interpose.dylib"
export RB8_ALLOC="${CQ_OPT_DEBUG_ALLOC:-}"
unset CQ_OPT_DEBUG_ALLOC
exec "$T/cq-opt.oracle_ba80" "$@"
