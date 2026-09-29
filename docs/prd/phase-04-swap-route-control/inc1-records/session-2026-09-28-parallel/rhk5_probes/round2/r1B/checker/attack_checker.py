#!/usr/bin/env python3
"""r1B attacks on tools/trace_twin_equiv.py. Each row: (name, subject, twin, want,
why). `want` is the verdict a SOUND checker must give ('DIFF' when the two traces
are NOT the same circuit). A row whose `got` is EQUIV while `want` is DIFF is a
FALSE EQUIV (the L10 failure mode)."""
import os, sys
sys.path.insert(0, os.environ.get('CQ_TOOLS', 'tools'))
import trace_twin_equiv as T

def t(*lines): return '\n'.join(lines) + '\n'

ROWS = []
def row(name, s, tw, want, why): ROWS.append((name, s, tw, want, why))

# --- 0. null control first (must be EQUIV) and a no-op mutant
base = t('cqrt_alloc_i32(5) -> h0', 'cqrt_alloc_i32(0) -> h1', 'cqrt_ry_i32(h0, 0x1p-1)',
         'cqrt_cnot(h0, h1)', 'cqrt_measure_i32(h1) -> 0', 'cqrt_measure_i32(h0) -> 0')
row('N0-null', base, base, 'EQUIV', 'identical')
# --- 1. Ry then CNOT on shared rail, swapped
row('A1-ry-cnot-swap', base, t('cqrt_alloc_i32(5) -> h0', 'cqrt_alloc_i32(0) -> h1',
    'cqrt_cnot(h0, h1)', 'cqrt_ry_i32(h0, 0x1p-1)', 'cqrt_measure_i32(h1) -> 0',
    'cqrt_measure_i32(h0) -> 0'), 'DIFF', 'Ry(h0) and CNOT(h0->h1) do not commute')
# --- 2. control/target swapped on a distinguishable pair
row('A2-cnot-ctl-tgt', base, base.replace('cqrt_cnot(h0, h1)', 'cqrt_cnot(h1, h0)'), 'DIFF',
    'CNOT direction')
# --- 3. free before the last reader
s3 = t('cqrt_alloc_i32(5) -> h0', 'cq_template_add_i32_hl(h0, 1) -> h1',
       'cq_template_mul_i32_hl(h1, 3) -> h2', 'cq_template_add_i32_hl_unc(h1, h0, 1)',
       'cqrt_free(h1)', 'cqrt_measure_i32(h2) -> 0')
row('A3-free-before-reader', s3, t('cqrt_alloc_i32(5) -> h0', 'cq_template_add_i32_hl(h0, 1) -> h1',
    'cq_template_add_i32_hl_unc(h1, h0, 1)', 'cqrt_free(h1)',
    'cq_template_mul_i32_hl(h1, 3) -> h2', 'cqrt_measure_i32(h2) -> 0'), 'DIFF', 'read after free')
# --- 4. a measurement moved across a non-diagonal gate on its rail
row('A4-measure-moved', base, t('cqrt_alloc_i32(5) -> h0', 'cqrt_alloc_i32(0) -> h1',
    'cqrt_measure_i32(h0) -> 0', 'cqrt_ry_i32(h0, 0x1p-1)', 'cqrt_cnot(h0, h1)',
    'cqrt_measure_i32(h1) -> 0'), 'DIFF', 'measure before Ry')
# --- 5. angle change
row('A5-angle', base, base.replace('0x1p-1', '0x1p-2'), 'DIFF', 'angle')
# --- 6. dropped _unc
row('A6-drop-unc', s3, t('cqrt_alloc_i32(5) -> h0', 'cq_template_add_i32_hl(h0, 1) -> h1',
    'cq_template_mul_i32_hl(h1, 3) -> h2', 'cqrt_free(h1)', 'cqrt_measure_i32(h2) -> 0'),
    'DIFF', 'dirty free')
# --- 7. an extra DIRTY scratch explained away as copy-out: no _unc, no free on `a`
s7 = t('cqrt_alloc_i32(5) -> h0', 'cqrt_ry_i32(h0, 0x1p-1)', 'cq_template_add_i32_hl(h0, 1) -> h1',
       'cqrt_alloc_i32(0) -> h2', 'cqrt_copy_i32(h1, h2)', 'cqrt_measure_i32(h2) -> 0',
       'cqrt_ry_i32(h0, 0x1p-2)', 'cqrt_measure_i32(h0) -> 0')
t7 = t('cqrt_alloc_i32(5) -> h0', 'cqrt_ry_i32(h0, 0x1p-1)', 'cq_template_add_i32_hl(h0, 1) -> h1',
       'cqrt_measure_i32(h1) -> 0', 'cqrt_ry_i32(h0, 0x1p-2)', 'cqrt_measure_i32(h0) -> 0')
row('A7-dirty-scratch', s7, t7, 'DIFF', 'scratch h1 left entangled with h0 across Ry')
# --- 7b. scratch uncomputed but NOT freed (leak of a clean rail): still a different trace
s7b = s7.replace('cqrt_measure_i32(h2) -> 0\n', 'cq_template_add_i32_hl_unc(h1, h0, 1)\ncqrt_measure_i32(h2) -> 0\n')
row('A7b-unc-no-free', s7b, t7, 'DIFF', 'no free (conservative; a clean leak)')
# --- 8. a copy-out whose adjoint follows a Ry on the operand (clobbered)
s8 = t('cqrt_alloc_i32(5) -> h0', 'cq_template_add_i32_hl(h0, 1) -> h1', 'cqrt_alloc_i32(0) -> h2',
       'cqrt_copy_i32(h1, h2)', 'cqrt_ry_i32(h0, 0x1p-1)', 'cq_template_add_i32_hl_unc(h1, h0, 1)',
       'cqrt_free(h1)', 'cqrt_measure_i32(h2) -> 0')
t8 = t('cqrt_alloc_i32(5) -> h0', 'cq_template_add_i32_hl(h0, 1) -> h1', 'cqrt_ry_i32(h0, 0x1p-1)',
       'cqrt_measure_i32(h1) -> 0')
row('A8-clobbered-copyout', s8, t8, 'DIFF', 'adjoint on relabelled operand -> dirty free')
# --- 9. WIDTH: a Bennett block whose copy width is the SOURCE width of a cast, not
#        the producer's result width. copy_i32 of an i64 rail copies 32 bits, but the
#        contraction renames the i64 result onto the i32 rail.
s9 = t('cqrt_alloc_i32(5) -> h0', 'cqrt_ry_i32(h0, 0x1p-1)',
       'cq_template_sext_i32_to_i64(h0) -> h1', 'cqrt_alloc_i32(0) -> h2', 'cqrt_copy_i32(h1, h2)',
       'cq_template_sext_i32_to_i64_unc(h1, h0)', 'cqrt_free(h1)', 'cqrt_x(h2)', 'cqrt_free(h2)')
t9 = t('cqrt_alloc_i32(5) -> h0', 'cqrt_ry_i32(h0, 0x1p-1)',
       'cq_template_sext_i32_to_i64(h0) -> h1', 'cqrt_x(h1)', 'cqrt_free(h1)')
row('A9-width-cast-substring', s9, t9, 'DIFF',
    'subject: 32-bit copy of sext then X on an i32 rail; twin: X on the i64 sext rail')
# --- 10. Rz vs read: physically commute, checker conservative (DIFF ok)
# --- 11. controlled copy with ctl/src swapped where both are distinguishable
s11 = t('cqrt_alloc_i1(1) -> h0', 'cqrt_alloc_i32(7) -> h1', 'cqrt_alloc_i32(0) -> h2',
        'cqrt_copy_i32_controlled(h0, h1, h2)', 'cqrt_measure_i32(h2) -> 0')
row('A11-ccopy-ctl-src-swap', s11, s11.replace('controlled(h0, h1, h2)', 'controlled(h1, h0, h2)'),
    'DIFF', 'ctl and src roles swapped')
# --- 12. commutative swap on a NON-commutative Q+Q template that the regex could
#         accidentally cover: `cq_template_or_i32` is fine; try `sub` and `icmp`.
s12 = t('cqrt_alloc_i32(5) -> h0', 'cqrt_alloc_i32(3) -> h1', 'cq_template_icmp_ult_i32(h0, h1) -> h2',
        'cqrt_measure_i1(h2) -> 0')
row('A12-icmp-operand-swap', s12, s12.replace('ult_i32(h0, h1)', 'ult_i32(h1, h0)'), 'DIFF',
    'ult is not symmetric')
# --- 13. identity renaming between two rails with DIFFERENT init values
s13 = t('cqrt_alloc_i32(5) -> h0', 'cqrt_alloc_i32(6) -> h1', 'cqrt_ry_i32(h0, 0x1p-1)',
        'cqrt_measure_i32(h0) -> 0', 'cqrt_measure_i32(h1) -> 0')
row('A13-rename-across-init', s13, s13.replace('cqrt_ry_i32(h0', 'cqrt_ry_i32(h1'), 'DIFF',
    'Ry on the 5-rail vs Ry on the 6-rail')
# --- 14. two measures on disjoint rails reordered: same CIRCUIT (EQUIV is correct);
#         recorded because the classical post-processing is invisible.
row('A14-measure-order-disjoint', s13, t('cqrt_alloc_i32(5) -> h0', 'cqrt_alloc_i32(6) -> h1',
    'cqrt_ry_i32(h0, 0x1p-1)', 'cqrt_measure_i32(h1) -> 0', 'cqrt_measure_i32(h0) -> 0'),
    'EQUIV', 'disjoint measurements commute (classical use of results is not in the trace)')
# --- 15. rule 2 with x == an arg of T (x ^= f(x) is not an out-first adjoint)
s15 = t('cqrt_alloc_i32(5) -> h0', 'cq_template_mul_i32_hl(h0, 5) -> h1', 'cqrt_copy_i32(h1, h0)',
        'cq_template_mul_i32_hl_unc(h1, h0, 5)', 'cqrt_free(h1)', 'cqrt_measure_i32(h0) -> 0')
t15 = t('cqrt_alloc_i32(5) -> h0', 'cq_template_mul_i32_hl_unc(h0, h0, 5)', 'cqrt_measure_i32(h0) -> 0')
row('A15-rule2-x-is-arg', s15, t15, 'DIFF', 'x among args must not contract')
# --- 16. Rule 1 where the scratch `a`'s adjoint is a DIFFERENT template with the same
#         prefix (T + "_unc" string equality guards this)
# --- 17. Rule 1 where T's operand is FREED between T and T_unc (free = write) 
s17 = t('cqrt_alloc_i32(5) -> h0', 'cqrt_alloc_i32(1) -> h9', 'cq_template_add_i32(h0, h9) -> h1',
        'cqrt_alloc_i32(0) -> h2', 'cqrt_copy_i32(h1, h2)', 'cqrt_x(h9)',
        'cq_template_add_i32_unc(h1, h0, h9)', 'cqrt_free(h1)', 'cqrt_measure_i32(h2) -> 0')
t17 = t('cqrt_alloc_i32(5) -> h0', 'cqrt_alloc_i32(1) -> h9', 'cq_template_add_i32(h0, h9) -> h1',
        'cqrt_x(h9)', 'cqrt_measure_i32(h2) -> 0'.replace('h2', 'h1'))
row('A17-x-on-operand-in-window', s17, t17, 'DIFF', 'operand relabelled before adjoint')
# --- 18. Rule 1: the copy-out block's alloc is NOT |0> (alloc(1)).
s18 = s7b.replace('cqrt_alloc_i32(0) -> h2', 'cqrt_alloc_i32(1) -> h2') + 'cqrt_free(h1)\n'
row('A18-copyout-nonzero-alloc', s18, t7, 'DIFF', 'b starts at 1')
# --- 19. same gates, one extra free on the subject side (double free)
row('A19-extra-free', s3 + 'cqrt_free(h1)\n', s3, 'DIFF', 'double free')
# --- 20. commutative forward swapped but the adjoint's OUT slot is still the xor result
s20 = t('cqrt_alloc_i32(5) -> h0', 'cqrt_alloc_i32(3) -> h1', 'cq_template_xor_i32(h0, h1) -> h2',
        'cq_template_xor_i32_unc(h2, h0, h1)', 'cqrt_free(h2)', 'cqrt_measure_i32(h0) -> 0')
row('A20-xor-unc-out-moved', s20, s20.replace('xor_i32_unc(h2, h0, h1)', 'xor_i32_unc(h1, h0, h2)'),
    'DIFF', 'unc zeroes h1 instead of h2')
# --- 21. Rz vs Ry on a controlled rotation: ctl rail vs target rail swapped
s21 = t('cqrt_alloc_i1(1) -> h0', 'cqrt_alloc_i32(5) -> h1', 'cqrt_ry_i32_controlled(h0, h1, 0x1p-1)',
        'cqrt_measure_i32(h1) -> 0')
row('A21-cry-roles', s21, s21.replace('controlled(h0, h1,', 'controlled(h1, h0,'), 'DIFF', 'roles')

# --- 22..28: a WRITE slot of each classification row no shipped control exercises,
#     reordered across a READ of the same rail (each must be DIFF)
PRE = ['cqrt_alloc_i1(1) -> h0', 'cqrt_alloc_i32(5) -> h1', 'cqrt_alloc_i32(3) -> h2']
def rd(h): return f'cq_template_add_i32_hl({h}, 1) -> h9'
def pair(g, h):
    a = t(*PRE, g, rd(h), 'cqrt_measure_i32(h9) -> 0')
    b = t(*PRE, rd(h), g, 'cqrt_measure_i32(h9) -> 0')
    return a, b
for nm, g, h in [('A22-cnot-target', 'cqrt_cnot(h0, h1)', 'h1'),
                 ('A23-toffoli-target', 'cqrt_toffoli(h0, h2, h1)', 'h1'),
                 ('A24-cswap-target', 'cqrt_cswap(h0, h1, h2)', 'h1'),
                 ('A25-ccopy-dst', 'cqrt_copy_i32_controlled(h0, h2, h1)', 'h1'),
                 ('A26-cry-target', 'cqrt_ry_i32_controlled(h0, h1, 0x1p-1)', 'h1'),
                 ('A27-addc', 'cqrt_addc_i32(h1, 4)', 'h1'),
                 ('A28-xorc', 'cqrt_xorc_i32(h1, 4)', 'h1')]:
    a, b = pair(g, h)
    row(nm, a, b, 'DIFF', 'a write slot moved across a read of the same rail')

def main():
    false_equiv = 0
    for name, s, tw, want, why in ROWS:
        try:
            got, ka, kb = T.compare_text(s, tw)
        except T.Refused as e:
            got, ka, kb = 'REFUSED', 0, 0
        flag = ''
        if want == 'DIFF' and got == 'EQUIV':
            flag = '  <== FALSE EQUIV'; false_equiv += 1
        elif want != got and not (want == 'DIFF' and got == 'REFUSED'):
            flag = '  <== mismatch (' + want + ')'
        print(f"{name:32s} {got:8s} contracted {ka}/{kb}  [{why}]{flag}")
    print(f"FALSE EQUIV: {false_equiv} of {len(ROWS)}")

main()
