HDR = '#include <stdlib.h>\nint h(int a, int k);\n'
LIBC = 'int h(int a, int k) { return k + 1; }\n'
PRE = 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); '
P = {
 'ba': 'int b[4]; for (int i=0;i<4;i++) b[i] = (n > 2) ? h(q,i) : cq_theta(i,.1); int s=0; for (int i=0;i<4;i++) s += cq_measure(b[i]); return s;',
 'bb': 'int b[4]; for (int i=0;i<4;i++) b[i] = cq_theta(h(q,i),.1); int s=0; for (int i=0;i<4;i++) s += cq_measure(b[i]); return s;',
 'bc': 'int b[4]; for (int i=0;i<4;i++) b[i] = cq_theta(i,.1); b[n&3] = h(q,m); int s=0; for (int i=0;i<4;i++) s += cq_measure(b[i]); return s;',
 'bd': 'int b[4]; for (int i=0;i<4;i++) b[i] = cq_theta(i,.1); int t=h(q,m); if (m > 2) b[n&3] = cq_theta(t,.3); int s=0; for (int i=0;i<4;i++) s += cq_measure(b[i]); return s;',
 'be': 'int b[4]; for (int i=0;i<4;i++) b[i] = cq_theta(i,.1); int t=h(q,m); int r=t; if (m > 2) r = cq_theta(t,.3); b[n&3] = r; int s=0; for (int i=0;i<4;i++) s += cq_measure(b[i]); return s;',
}
for k, b in P.items():
    open(k+'C.c','w').write(HDR + 'int main(int c, char **v) { ' + PRE + b + ' }\n')
    open(k+'C.lib.c','w').write(LIBC)
    open(k+'T.c','w').write('#include <stdlib.h>\nint main(int c, char **v) { ' + PRE + b.replace('h(q,i)','(i+1)').replace('h(q,m)','(m+1)') + ' }\n')
open('list4.txt','w').write(' '.join(f'{k}{v}' for k in P for v in 'CT'))
