#!/usr/bin/env python3
# r2B: NON-equivalent trace pairs aimed at trace_twin_equiv.py's width logic +
# the U12 (measure) / U13 (injectivity) conjuncts. Each pair MUST report DIFF on
# the SHIPPED checker. Any EQUIV is a finding (false-equiv). Run from worktree root.
import subprocess, sys, os
TOOL = os.path.join(os.getcwd(), 'tools/trace_twin_equiv.py')
def cmp(a, b):
    import tempfile
    da, db = tempfile.mkstemp(suffix='.log')[1], tempfile.mkstemp(suffix='.log')[1]
    open(da,'w').write(a); open(db,'w').write(b)
    r = subprocess.run(['python3', TOOL, '--quiet-controls', da, db],
                       capture_output=True, text=True)
    m = [l for l in r.stdout.splitlines() if ' vs ' in l and ': ' in l]
    if not m: return 'EXIT%d'%r.returncode, r.returncode
    return m[-1].split(': ',1)[1].split()[0], r.returncode
def t(*L): return '\n'.join(L)+'\n'

PAIRS = {}
# W1 — zext i8->i32 producer (result i32), scratch COPY at i8 (narrow copy of a
# wide result). Must NOT contract in S; T is the out-first form. Expect DIFF.
PAIRS['W1_zext_narrow_copy'] = (
 t('cqrt_alloc_i8(5) -> h0','cqrt_ry_i8(h0, 0x1p-1)',
   'cq_template_zext_i8_to_i32(h0) -> h1','cqrt_alloc_i8(0) -> h2',
   'cqrt_copy_i8(h1, h2)','cq_template_zext_i8_to_i32_unc(h1, h0)','cqrt_free(h1)',
   'cqrt_x(h2)','cqrt_free(h2)'),
 t('cqrt_alloc_i8(5) -> h0','cqrt_ry_i8(h0, 0x1p-1)',
   'cq_template_zext_i8_to_i32(h0) -> h1','cqrt_x(h1)','cqrt_free(h1)'))
# W2 — trunc i64->i32 (result i32), scratch COPY at i64 (wide copy of narrow result).
PAIRS['W2_trunc_wide_copy'] = (
 t('cqrt_alloc_i64(5) -> h0','cqrt_ry_i64(h0, 0x1p-1)',
   'cq_template_trunc_i64_to_i32(h0) -> h1','cqrt_alloc_i64(0) -> h2',
   'cqrt_copy_i64(h1, h2)','cq_template_trunc_i64_to_i32_unc(h1, h0)','cqrt_free(h1)',
   'cqrt_x(h2)','cqrt_free(h2)'),
 t('cqrt_alloc_i64(5) -> h0','cqrt_ry_i64(h0, 0x1p-1)',
   'cq_template_trunc_i64_to_i32(h0) -> h1','cqrt_x(h1)','cqrt_free(h1)'))
# W3 — compare rail (result i1), scratch COPY at i32.
PAIRS['W3_cmp_i1_copy_i32'] = (
 t('cqrt_alloc_i32(5) -> h0','cqrt_alloc_i32(3) -> h1',
   'cq_template_icmp_eq_i32(h0, h1) -> h2','cqrt_alloc_i32(0) -> h3',
   'cqrt_copy_i32(h2, h3)','cq_template_icmp_eq_i32_unc(h2, h0, h1)','cqrt_free(h2)',
   'cqrt_measure_i1(h3) -> 0'),
 t('cqrt_alloc_i32(5) -> h0','cqrt_alloc_i32(3) -> h1',
   'cq_template_icmp_eq_i32(h0, h1) -> h2','cqrt_measure_i1(h2) -> 0'))
# W4 — RULE 2 recompute whose XOR-copy is WIDER than the recomputed rail.
PAIRS['W4_recompute_wide_copy'] = (
 t('cqrt_alloc_i64(1) -> h0','cq_template_trunc_i64_to_i32(h0) -> h1',
   'cq_template_trunc_i64_to_i32(h0) -> h2','cqrt_copy_i64(h2, h1)',
   'cq_template_trunc_i64_to_i32_unc(h2, h0)','cqrt_free(h2)','cqrt_free(h1)'),
 t('cqrt_alloc_i64(1) -> h0','cq_template_trunc_i64_to_i32(h0) -> h1',
   'cq_template_trunc_i64_to_i32_unc(h1, h0)','cqrt_free(h1)'))
# W5 — fp copy width mismatch (f32 producer result vs f64 copy).
PAIRS['W5_fp_width_mismatch'] = (
 t('cqrt_alloc_f32(5) -> h0','cqrt_ry_f32(h0, 0x1p-1)',
   'cq_template_fptrunc_f64_to_f32(h0) -> h1','cqrt_alloc_f64(0) -> h2',
   'cqrt_copy_f64(h1, h2)','cq_template_fptrunc_f64_to_f32_unc(h1, h0)','cqrt_free(h1)',
   'cqrt_x(h2)','cqrt_free(h2)'),
 t('cqrt_alloc_f32(5) -> h0','cqrt_ry_f32(h0, 0x1p-1)',
   'cq_template_fptrunc_f64_to_f32(h0) -> h1','cqrt_x(h1)','cqrt_free(h1)'))
# W6 — same widths, different cast op (sext vs zext): label differs.
PAIRS['W6_sext_vs_zext'] = (
 t('cqrt_alloc_i8(5) -> h0','cqrt_ry_i8(h0, 0x1p-1)',
   'cq_template_sext_i8_to_i32(h0) -> h1','cqrt_measure_i32(h1) -> 0'),
 t('cqrt_alloc_i8(5) -> h0','cqrt_ry_i8(h0, 0x1p-1)',
   'cq_template_zext_i8_to_i32(h0) -> h1','cqrt_measure_i32(h1) -> 0'))
# U12 — a measure reordered PAST a copy-source read of the same rail. measure is a
# COLLAPSE (a write/barrier); if it were a read the two would commute -> false EQUIV.
PAIRS['U12_measure_past_copysrc'] = (
 t('cqrt_alloc_i32(5) -> h0','cqrt_alloc_i32(0) -> h1',
   'cqrt_copy_i32(h0, h1)','cqrt_measure_i32(h0) -> 0','cqrt_free(h1)'),
 t('cqrt_alloc_i32(5) -> h0','cqrt_alloc_i32(0) -> h1',
   'cqrt_measure_i32(h0) -> 0','cqrt_copy_i32(h0, h1)','cqrt_free(h1)'))
# U13 — injectivity: A measures two DISTINCT rails; B measures ONE rail twice.
PAIRS['U13_injectivity'] = (
 t('cqrt_alloc_i32(0) -> h0','cqrt_alloc_i32(0) -> h1',
   'cqrt_measure_i32(h0) -> 0','cqrt_measure_i32(h1) -> 0'),
 t('cqrt_alloc_i32(0) -> h0','cqrt_alloc_i32(0) -> h1',
   'cqrt_measure_i32(h0) -> 0','cqrt_measure_i32(h0) -> 0'))

rc = 0
for name,(a,b) in PAIRS.items():
    v, code = cmp(a,b)
    ok = (v == 'DIFF')
    if not ok: rc = 1
    print(f"{name:28s} -> {v:8s} {'OK(DIFF)' if ok else '*** FINDING: not DIFF ***'}")
sys.exit(rc)
