import pathlib
V = pathlib.Path(__file__).parent
s = (V / 'stage_r3.py').read_text()
s = s.replace("'g9A', 'k19']", "'g9A', 'k19', 'eqphi']").replace("TWINS = ['k19F'", "TWINS = ['eqphiT', 'k19F'")
(V / 'stage_r3.py').write_text(s)
b = (V / 'mkfix3_body.py').read_text()
if 'lowering_volatile_globalfold_equal_phi.ll' not in b:
    b += '''
E("lowering_volatile_globalfold_equal_phi.ll", V / "fx/r3_eqphi.s1.ll", "main",
  """; lowering_volatile_globalfold_equal_phi.ll — ACCEPT with the fenv-intended twin's stream (bd
; test_C_libtooling-stl3; bd vsfp round 3 — the condition seed after a φ of EQUAL incomings).
; Single TU, no call.
;
; `int r = (q > 3) ? K : 0;` with `K` a never-stored internal volatile global whose initializer is
; 0. `-O1` keeps a diamond (a volatile load cannot be speculated). The volatile GLOBAL fold folds
; the load to 0 and, since round 3, folds the emptied arm: the φ's two incomings are EQUAL, so it
; becomes its value — and the tainted compare `q > 3` is dead. Round 2's `deleteDeadCones` seeded
; the condition only when NO φ remained, so the compare survived and was lowered as a forward
; template never uncomputed: a DIRTY which-path flag across `Ry(0.7)` on `q` (measured on mutant S2:
; TRACE-DIFF, 1 dirty template rail, a lyyf warning). The condition is now seeded after every fold,
; and the stream is the program `r = 0`: alloc; Ry(.5); Ry(.7); measure. The ORACLE and round 2
; declined (`condition predates a non-diagonal gate`) — an over-decline, not a hazard.
{src}""", twin="eqphiT", src="r3_eqphi")
'''
    (V / 'mkfix3_body.py').write_text(b)
(V / 'mkfix3.py').write_text((V / 'mkfix3_head.py').read_text() + (V / 'mkfix3_body.py').read_text() + (V / 'mkfix3_tail.py').read_text())
print('ok')
