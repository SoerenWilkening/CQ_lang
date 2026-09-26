import pathlib
V = pathlib.Path(__file__).parent
s = (V / 'mkgold3.py').read_text()
i = s.index('SL = [')
j = s.index(']\n', s.index("('slice_volatile_arm_fold_repropagate_twin', None)")) + 2
s = s[:i] + "SL = [('slice_volatile_arm_fold_cascade', None), ('slice_volatile_arm_fold_cascade_twin', None)]\n" + s[j:]
s = s.replace("for a in ('slice_spec_dropped_arg_volatile_global', 'slice_volatile_arm_fold_repropagate'):",
              "for a in ('slice_volatile_arm_fold_cascade',):")
s = s.replace("D = V / 'e2e3'", "D = V / 'e2e4'")
(V / 'mkgold4.py').write_text(s)
print('ok')
