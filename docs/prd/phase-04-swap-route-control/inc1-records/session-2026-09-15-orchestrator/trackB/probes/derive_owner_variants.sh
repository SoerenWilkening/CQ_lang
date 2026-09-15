#!/bin/sh
# derive_owner_variants.sh — regenerate the `derived/*.ll` probes from the
# OWNER'S file.  Run from the repo root.  The committed `derived/*.ll` are the
# output of this script on the frozen 2026-09-15 ORACLE and are kept because
# `example/` is in `.git/info/exclude` (bd `zwtm`) — without them the B-probes
# would be unreproducible by anyone who does not have the owner's local file.
#
#   usage: ./…/trackB/probes/derive_owner_variants.sh [path/to/grover_oracle_uncompute.c]
#
# Each variant hand-emulates a piece of the DEFERRED second half on top of the
# promoter's OWN output (CQ_RAILBANK_DBG), so the input to every measurement is
# the shipped stage's real emission and not a hand construction.
set -u
LLVM=/usr/local/opt/llvm@19/bin; BUILD=${BUILD:-build}
SRC=${1:-example/grover/grover_oracle_uncompute.c}
OUT=$(dirname "$0")/derived; mkdir -p "$OUT"; T=$(mktemp -d)
"$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S "$SRC" -o "$T/s1.ll" || exit 9
CQ_RAILBANK_DBG=1 "$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" \
    -passes=cq-lowering -S "$T/s1.ll" -o /dev/null 2> "$T/rb.txt"
awk '/^=== CQ_RAILBANK_DBG: module after/{f=1;next} f' "$T/rb.txt" \
  | grep -v '^error: \|^\^$' > "$OUT/B0_owner_promoted.ll"
python3 - "$OUT" <<'PY'
import sys,re
O=sys.argv[1]; base=open(O+"/B0_owner_promoted.ll").read()
def w(n,s): open(O+"/"+n+".ll","w").write(s)
NOSTORE=lambda s: re.sub(r"  store i8 %cq\.bank, ptr %cq\.bank\.addr[^\n]*\n","",s)
w("B2_nostore", NOSTORE(base))
def i1cell(s):
    s=re.sub(r"  %27 = zext i1 %26 to i8[^\n]*\n","",s)
    s=s.replace("%cq.bank = phi i8 [ %27, %25 ], [ 0, %21 ]",
                "%cq.bank = phi i1 [ %26, %25 ], [ false, %21 ]")
    s=re.sub(r"  %29 = trunc nuw i8 %cq\.bank to i1[^\n]*\n","",s)
    return s.replace("select i1 %29,","select i1 %cq.bank,")
b3=NOSTORE(i1cell(base))
b3=re.sub(r"  %cq\.bank\.addr = getelementptr[^\n]*\n","",b3)
w("B3_i1cell_nostore", b3)
w("B6_i1cell_nostore_noAmeasure",
  b3.replace("%19 = tail call i32 @cq_measure_si32(i32 noundef %31) #3, !dbg !39",
             "%19 = add i32 0, 0, !dbg !39"))
w("B7_i1phi_zextsunk_store",
  i1cell(base).replace("  store i8 %cq.bank, ptr %cq.bank.addr, align 1, !dbg !50, !tbaa !29\n",
    "  %cq.bank.i8 = zext i1 %cq.bank to i8, !dbg !50\n"
    "  store i8 %cq.bank.i8, ptr %cq.bank.addr, align 1, !dbg !50, !tbaa !29\n"))
s=i1cell(base).replace("store i8 %cq.bank, ptr %cq.bank.addr","store i1 %cq.bank, ptr %cq.bank.addr")
for ld,tr in (("%3","%4"),("%8","%9"),("%14","%15")):
    s=s.replace("%s = load i8, "%ld,"%s = load i1, "%ld)
    s=re.sub(r"  %s = trunc nuw i8 %s to i1[^\n]*\n"%(re.escape(tr),re.escape(ld)),"",s)
    s=s.replace("@cq_measure_i1(i1 noundef zeroext %s)"%tr,"@cq_measure_i1(i1 noundef zeroext %s)"%ld)
w("B8_2a_normalised", s.replace(", !range !33, !noundef !34",""))
PY
echo "derived -> $OUT"
