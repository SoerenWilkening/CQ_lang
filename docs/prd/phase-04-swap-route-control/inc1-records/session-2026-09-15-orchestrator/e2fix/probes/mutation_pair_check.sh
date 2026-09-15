#!/bin/bash
# mutation_pair_check.sh — mutation validation for the F-E2-1 fixture PAIR
# (`lowering_measure_undef_operand_after_taint_fold.ll` and its one-token
# control `lowering_measure_taint_fold_control.ll`).
#
# Rule 12: a fixture is validated by MUTATION, never by re-reading its prefixes.
# The two modules differ in exactly ONE token — the measure operand, `undef` vs
# `%1` — so each IS the other's mutant, and this script runs each fixture's own
# prefixes (with the same FileCheck command line lit uses) against the OTHER
# module.
#
# ⚠ TWO CONTROLS RUN ON EVERY INVOCATION, and they are here because the FIRST
# spelling of this check LIED IN THE PASS DIRECTION (CLAUDE.md L10, an
# instrument's failure mode is to report a PASS):
#   * the first spelling put the FileCheck call inside an `if ...; then CMD >log;
#     lbl=CHECK; fi` and then read `$?` — which is the exit status of the
#     ASSIGNMENT, always 0. It reported 7 of 7 green, including for mutants that
#     in fact fail. `$?` must be read IMMEDIATELY after the command.
#   * BOUNDARY CONTROL: each fixture against its OWN module must be GREEN. A
#     harness whose base case is red is measuring itself, not the fixtures.
# The script EXITS NON-ZERO unless every expectation below holds, and refuses to
# run if a file or a binary is missing (a check that prints "0 mutations" is a
# HOLE, not a pass).
#
# usage:  mutation_pair_check.sh <build-dir>          # e.g. build
set -u
BUILD="${1:-}"
[ -n "$BUILD" ] || { echo "ERROR: no build dir given (a vacuous run is a HOLE, not a pass)"; exit 2; }
FC="${FILECHECK:-/usr/local/opt/llvm@19/bin/FileCheck}"
OPT="$BUILD/ir-pass/cq-opt"
PASS="$BUILD/ir-pass/libCQPass.so"
A=ir-pass/test/lowering_measure_undef_operand_after_taint_fold.ll
B=ir-pass/test/lowering_measure_taint_fold_control.ll
for f in "$FC" "$OPT" "$PASS" "$A" "$B"; do
  [ -e "$f" ] || { echo "ERROR: missing $f"; exit 2; }
done
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fails=0

lower() { "$OPT" -load-pass-plugin "$PASS" -passes=cq-lowering -S "$1" > "$2" 2>"$2.err"; echo $?; }
check() { # $1 fixture  $2 prefix ("" = CHECK)  $3 input  -> prints exit code
  if [ -z "$2" ]; then "$FC" "$1" < "$3" >/dev/null 2>&1; else
    "$FC" "$1" --check-prefix="$2" < "$3" >/dev/null 2>&1; fi
  echo $?; }                       # ⚠ read $? IMMEDIATELY; never after an assignment

ra=$(lower "$A" "$TMP/a.ll"); rb=$(lower "$B" "$TMP/b.ll")
echo "lower: A exit=$ra ($(wc -c <"$TMP/a.ll"|tr -d ' ')B)  B exit=$rb ($(wc -c <"$TMP/b.ll"|tr -d ' ')B)"
[ "$ra" = 0 ] && [ "$rb" = 0 ] || { echo "ERROR: a fixture module did not accept"; exit 2; }
[ -s "$TMP/a.ll" ] && [ -s "$TMP/b.ll" ] || { echo "ERROR: empty lowered module"; exit 2; }

echo "-- BOUNDARY CONTROL: each fixture against its OWN module (expect all 0)"
for p in "" COUNT NOMEASURE NOINTR; do
  r=$(check "$A" "$p" "$TMP/a.ll"); printf '   A/%-10s %s\n' "${p:-CHECK}" "$r"; [ "$r" = 0 ] || fails=$((fails+1)); done
for p in "" COUNT NOINTR; do
  r=$(check "$B" "$p" "$TMP/b.ll"); printf '   B/%-10s %s\n' "${p:-CHECK}" "$r"; [ "$r" = 0 ] || fails=$((fails+1)); done

echo "-- MUTANT of A (operand undef -> %1): A's prefixes vs B's module (expect CHECK and NOMEASURE RED)"
mA=0
for p in "" COUNT NOMEASURE NOINTR; do
  r=$(check "$A" "$p" "$TMP/b.ll"); printf '   A/%-10s %s\n' "${p:-CHECK}" "$r"; [ "$r" = 0 ] || mA=$((mA+1)); done
[ "$mA" -ge 2 ] || { echo "   ERROR: the mutant did not flip the fixture (expected >=2 red prefixes, got $mA)"; fails=$((fails+1)); }

echo "-- MUTANT of B (operand %1 -> undef): B's prefixes vs A's module (expect CHECK and COUNT RED)"
mB=0
for p in "" COUNT NOINTR; do
  r=$(check "$B" "$p" "$TMP/a.ll"); printf '   B/%-10s %s\n' "${p:-CHECK}" "$r"; [ "$r" = 0 ] || mB=$((mB+1)); done
[ "$mB" -ge 2 ] || { echo "   ERROR: the mutant did not flip the control (expected >=2 red prefixes, got $mB)"; fails=$((fails+1)); }

if [ "$fails" = 0 ]; then
  echo "mutation pair check: 2 mutants, both CAUGHT, 0 MISSED; boundary controls green"
else
  echo "mutation pair check: $fails EXPECTATION(S) VIOLATED"; exit 1
fi
