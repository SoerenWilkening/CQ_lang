# Spec-QUANTUM (Q) and spec-CLASSICAL (C) lift family across widths and shapes.
# T = hand-inlined twin of the CLASSICAL verdict; U = hand-inlined twin of the QUANTUM verdict.
widths = {
 'i': ('int', 'a + k', 'k + 1', 'atoi(v[1])', '(m+1)', '(q + m)'),
 'b': ('_Bool', 'a ^ k', '!k', '(atoi(v[1])&1)', '!m', 'q ^ m'),
 'c': ('signed char', 'a + k', 'k + 1', '(signed char)atoi(v[1])', '(signed char)(m+1)', '(signed char)(q + m)'),
 's': ('short', 'a + k', 'k + 1', '(short)atoi(v[1])', '(short)(m+1)', '(short)(q + m)'),
 'l': ('long long', 'a + k', 'k + 1', 'atoll(v[1])', '(m+1)', '(q + m)'),
 'd': ('double', 'a + k', 'k + 1.0', 'atof(v[1])', '(m+1.0)', '(q + m)'),
}
shapes = {
 # base lift
 '1': '{T} r = t; if (m2 > 3) r = cq_theta(t, .2); return (int)cq_measure(r);',
 # base used after merge (classical read of t)
 '2': '{T} r = t; if (m2 > 3) r = cq_theta(t, .2); return (int)cq_measure(r) + (int)(t != 0);',
 # base measured on the untaken path only
 '3': '{T} r = t; int x = 0; if (m2 > 3) r = cq_theta(t, .2); else x = (int)cq_measure(t); return (int)cq_measure(r) + x;',
 # chained lifts
 '4': '{T} r = t; if (m2 > 3) r = cq_theta(t, .2); {T} s = r; if (m2 > 5) s = cq_theta(r, .4); return (int)cq_measure(s);',
 # N-way switch lift
 '5': '{T} r = t; switch (m2) {{ case 1: r = cq_theta(t, .1); break; case 4: r = cq_theta(t, .4); break; case 7: r = cq_theta(t, .7); break; }} return (int)cq_measure(r);',
 # lift in a loop body (fresh per trip)
 '6': 'int acc = 0; for (int i = 0; i < m2; i++) {{ {T} r = t; if ((i & 1) == 0) r = cq_theta(t, .2); acc += (int)cq_measure(r); }} return acc;',
 # base + measured q afterwards
 '7': '{T} r = t; if (m2 > 3) r = cq_theta(t, .2); return (int)cq_measure(r) + (int)cq_measure(q);',
}
LIBS = {}
for w,(T,qexpr,cexpr,minit,twinC,twinQ) in widths.items():
    for s, body in shapes.items():
        b = body.format(T=T)
        pre_spec = f'{T} m = {minit}; int m2 = atoi(v[2]); {T} q = cq_theta(m, .5); {T} t = h(q, m); '
        for var, lib in (('Q', f'{T} h({T} a, {T} k) {{ return {qexpr}; }}\n'), ('C', f'{T} h({T} a, {T} k) {{ return {cexpr}; }}\n')):
            name = f'sq{w}{s}{var}'
            open(name + '.c', 'w').write(f'#include <stdlib.h>\n{T} h({T} a, {T} k);\nint main(int c, char **v) {{ {pre_spec}{b} }}\n')
            open(name + '.lib.c', 'w').write(lib)
        # twins
        for var, tw in (('T', twinC), ('U', twinQ)):
            name = f'sq{w}{s}{var}'
            pre = f'{T} m = {minit}; int m2 = atoi(v[2]); {T} q = cq_theta(m, .5); {T} t = {tw}; '
            open(name + '.c', 'w').write(f'#include <stdlib.h>\nint main(int c, char **v) {{ {pre}{b} }}\n')
names = [f'sq{w}{s}{v}' for w in widths for s in shapes for v in 'CTQU']
open('list2.txt','w').write(' '.join(names))
print(len(names))
