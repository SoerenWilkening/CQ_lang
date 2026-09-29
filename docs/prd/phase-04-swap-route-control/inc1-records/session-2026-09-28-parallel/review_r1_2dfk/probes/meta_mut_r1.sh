#!/bin/bash
# r1 2dfk: meta-mutation of e2e-stage-cache-selftest over key components the
# implementer's M1-M5 did NOT delete. Each mutant removes ONE key component from
# BOTH spellings where both exist (bash stage_cache.sh + python run_manifest), so
# the key-PARITY row (I) cannot catch it by construction; the question is whether
# any row catches the key IGNORING that input. Run in the reviewer's PRIVATE
# worktree only. Usage: meta_mut_r1.sh <worktree> <selftest command...>
set -u
R=$1; shift
SC=$R/tests/e2e/stage_cache.sh; PYC=$R/tools/cq_stage_cache.py; RS=$R/tests/e2e/run_slice.sh
cp -f $SC $SC.orig; cp -f $PYC $PYC.orig; cp -f $RS $RS.orig
restore() { cp -f $SC.orig $SC; cp -f $PYC.orig $PYC; cp -f $RS.orig $RS; }
CMD=("$@")
m_null()  { :; }
m_tpl()   { sed -i '' 's|"\$CQ_RUN_BASE" "\$s2d" "\$tpld" "\$rtd" "\$ldd"|"$CQ_RUN_BASE" "$s2d" "T" "$rtd" "$ldd"|' $SC;
            sed -i '' 's|lines = \[RUN_VERSION, run_base, s2_digest, tpl_digest, rt_digest, ld_digest\]|lines = [RUN_VERSION, run_base, s2_digest, "T", rt_digest, ld_digest]|' $PYC; }
m_ld()    { sed -i '' 's|"\$CQ_RUN_BASE" "\$s2d" "\$tpld" "\$rtd" "\$ldd"|"$CQ_RUN_BASE" "$s2d" "$tpld" "$rtd" "L"|' $SC;
            sed -i '' 's|lines = \[RUN_VERSION, run_base, s2_digest, tpl_digest, rt_digest, ld_digest\]|lines = [RUN_VERSION, run_base, s2_digest, tpl_digest, rt_digest, "L"]|' $PYC; }
m_base()  { sed -i '' 's|"\$CQ_RUN_BASE" "\$s2d" "\$tpld" "\$rtd" "\$ldd"|"B" "$s2d" "$tpld" "$rtd" "$ldd"|' $SC;
            sed -i '' 's|lines = \[RUN_VERSION, run_base, s2_digest, tpl_digest, rt_digest, ld_digest\]|lines = [RUN_VERSION, "B", s2_digest, tpl_digest, rt_digest, ld_digest]|' $PYC; }
m_2bfpc() { sed -i '' 's|"\$s2d" "\$fpd" "\$2" "\$PY"|"$s2d" "F" "$2" "$PY"|' $SC; }
m_2bflg() { sed -i '' 's|"\$s2d" "\$fpd" "\$2" "\$PY"|"$s2d" "$fpd" "" "$PY"|' $SC; }
m_s1src() { sed -i '' 's|printf .%s\\0%s\\0. "\$CQ_S1_BASE" "\$SRC"; cat "\$SRC"; }|printf "%s\\0%s\\0" "$CQ_S1_BASE" "$SRC"; }|' $RS; }
for m in m_null m_tpl m_ld m_base m_2bfpc m_2bflg m_s1src; do
  $m
  # prove the mutant was planted (a sed that matched nothing is a null mutant)
  if [ $m != m_null ] && cmp -s $SC $SC.orig && cmp -s $PYC $PYC.orig && cmp -s $RS $RS.orig; then
    echo "$m: NOT PLANTED (sed matched nothing)"; restore; continue; fi
  out=$("${CMD[@]}" 2>&1); rc=$?
  fails=$(printf '%s\n' "$out" | grep -E '^  FAIL' | sed 's/^  FAIL //' | cut -c1-60 | tr '\n' ';')
  printf '%-9s selftest rc=%d  %s\n' "$m" "$rc" "${fails:-(all rows ok)}"
  restore
done
rm -f $SC.orig $PYC.orig $RS.orig
