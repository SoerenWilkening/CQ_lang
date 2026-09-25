HDR = '#include <stdlib.h>\nint h(int a, int k);\nint g(int a, int k);\n'
LIBC = 'int h(int a, int k) { return k + 1; }\nint g(int a, int k) { return a + k; }\n'
LIBQ = 'int h(int a, int k) { return a + k; }\nint g(int a, int k) { return a + k; }\n'
PRE = 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); '
P = {
 'la': 'int r=t; if (m>3) r=cq_theta(t,.2); int u=g(r,n); return cq_measure(u);',
 'lb': 'int q2=cq_theta(n,.3); int t2=h(q2,n); int r=q2; if (m>3) r=cq_theta(q2,(double)t*0.1); return cq_measure(r)+t2;',
 'lc': 'int r=t; if (m>3) r=cq_theta(t,.2); if (r>5) cq_phi(.3); return cq_measure(r);',
 'ld': 'int r=t; if (m>3) r=cq_theta(t,.2); int s=r; if (n>3) s=cq_theta(r,.4); int x = h(s, n); return cq_measure(s) + x;',
 'le': 'int r=t; if (m>3) r=cq_theta(t,.2); int w=cq_theta(n,.1); int z=(r>5)?w:cq_theta(w,.3); return cq_measure(z)+cq_measure(r);',
}
for k, b in P.items():
    for var, lib in (('C', LIBC), ('Q', LIBQ)):
        open(k+var+'.c','w').write(HDR + 'int main(int c, char **v) { ' + PRE + b + ' }\n')
        open(k+var+'.lib.c','w').write(lib)
    tb = (PRE + b).replace('h(q,m)','(m+1)').replace('h(q2,n)','(n+1)').replace('h(s, n)','(n+1)')
    open(k+'T.c','w').write('#include <stdlib.h>\nint g(int a, int k);\nint main(int c, char **v) { ' + tb + ' }\n')
    open(k+'T.lib.c','w').write('int g(int a, int k) { return a + k; }\n')
open('list5.txt','w').write(' '.join(f'{k}{v}' for k in P for v in 'CQT'))
