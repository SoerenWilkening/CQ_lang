#!/bin/bash
# blast_one.sh <absfile> <label>
# Emits ONE tab-separated row for the g8 blast-radius sweep, or nothing.
#
#   label <TAB> dirty <TAB> total_template_mints <TAB> VERDICT <TAB> detail
#
# VERDICT is one of:
#   DECLINE / CLANGERR / LINKERR / CLEAN(0 dirty) / DIRTY-NO-TRAILING-GATE / **G8-SHAPE**
#
# G8-SHAPE means: a TEMPLATE rail that is never `_unc`'d and never freed (DIRTY) copies a
# register S, and a NON-DIAGONAL gate (cqrt_ry_<w> on S, or cqrt_ry_<w>_controlled targeting S)
# executes on S LATER in the trace. That is Rule 8 dephasing: the live which-path record is
# still entangled when the interference happens.
LLVM=/usr/local/opt/llvm@19/bin
W=/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-ac2acfdde3461becc
f="$1"; label="$2"
base=$(basename "$f")
case "$base" in *_lib.c|lib*.c) exit 0 ;; esac
T=$(mktemp -d) || exit 1
trap 'rm -rf "$T"' EXIT

"$LLVM/clang" -I"$W/include" -include CQ.h -O1 -g -emit-llvm -S "$f" -o "$T/s1.ll" 2>/dev/null \
  || { printf '%s\t-\t-\tCLANGERR\t-\n' "$label"; exit 0; }
"$W/build/ir-pass/cq-opt" -load-pass-plugin "$W/build/ir-pass/libCQPass.so" \
    -passes=cq-lowering -S "$T/s1.ll" -o "$T/s2.ll" 2>/dev/null \
  || { printf '%s\t-\t-\tDECLINE\t-\n' "$label"; exit 0; }

census=$(python3 "$W/tools/free_pairing_check.py" "$T/s2.ll" 2>&1 | grep '^free_pairing_check:')
# A MISSING census must NEVER default to "clean" -- that is the exact false-pass this
# sweep was already caught by once (`-q` suppresses the line on a clean exit, so every
# module parsed as 0 dirty). Report it as its own verdict and let it be counted.
if [ -z "$census" ]; then
  printf '%s\t?\t?\tNOCENSUS\t-\n' "$label"; exit 0
fi
dirty=$(printf '%s' "$census" | sed -n 's/.*template rail mint(s) of which \([0-9][0-9]*\) left dirty.*/\1/p')
total=$(printf '%s' "$census" | sed -n 's/.*, \([0-9][0-9]*\) template rail mint(s).*/\1/p')
if [ -z "$dirty" ] || [ -z "$total" ]; then
  printf '%s\t?\t?\tUNPARSED-CENSUS\t-\n' "$label"; exit 0
fi
if [ "$dirty" -eq 0 ] 2>/dev/null; then
  printf '%s\t0\t%s\tCLEAN\t-\n' "$label" "$total"; exit 0
fi

# dirty > 0: link and run, then look for the g8 shape in the trace
"$LLVM/clang" "$T/s2.ll" "$W/build/runtime/libcq_templates.a" "$W/build/runtime/libcq_runtime.a" \
    -o "$T/a" 2>/dev/null || { printf '%s\t%s\t%s\tLINKERR\t-\n' "$label" "$dirty" "$total"; exit 0; }
"$T/a" > "$T/trace" 2>/dev/null || { printf '%s\t%s\t%s\tRUNERR\t-\n' "$label" "$dirty" "$total"; exit 0; }

python3 - "$T/trace" "$label" "$dirty" "$total" <<'PY'
import sys, re
trace = open(sys.argv[1]).read().splitlines()
label, dirty, total = sys.argv[2], sys.argv[3], sys.argv[4]

mint = re.compile(r'^(cq_template_\w+)\(([^)]*)\)\s*->\s*(h\d+)')
unc  = re.compile(r'^(cq_template_\w+_unc)\(([^)]*)\)')
free = re.compile(r'^cqrt_free\((h\d+)\)')
ry   = re.compile(r'^(cqrt_ry_\w+?)(_controlled)?\(([^)]*)\)')

mints, discharged = [], set()
for i, l in enumerate(trace):
    m = unc.match(l)
    if m:
        for a in m.group(2).split(','):
            a = a.strip()
            if a.startswith('h'): discharged.add(a)
        continue
    m = free.match(l)
    if m:
        discharged.add(m.group(1)); continue
    m = mint.match(l)
    if m:
        args = [a.strip() for a in m.group(2).split(',')]
        src = next((a for a in args if a.startswith('h')), None)
        mints.append((i, m.group(3), src, m.group(1)))

hits = []
for idx, rail, src, sym in mints:
    if rail in discharged or src is None:
        continue
    for j in range(idx + 1, len(trace)):
        m = ry.match(trace[j])
        if not m: continue
        args = [a.strip() for a in m.group(3).split(',')]
        target = args[1] if m.group(2) else args[0]   # _controlled: arg1 is the target
        if target == src:
            hits.append(f"{sym}->{rail} copies {src}; later {trace[j].split('(')[0]} on {src} @line{j+1}")
            break

if hits:
    print(f"{label}\t{dirty}\t{total}\t**G8-SHAPE**\t{' | '.join(hits[:3])}")
else:
    print(f"{label}\t{dirty}\t{total}\tDIRTY-NO-TRAILING-GATE\t-")
PY
