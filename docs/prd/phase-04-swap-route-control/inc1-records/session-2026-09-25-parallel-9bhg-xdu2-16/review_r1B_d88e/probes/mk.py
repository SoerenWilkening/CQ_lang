import sys, os
# body uses H(...) for the spec call; T twin replaces H(q, k) by (k + 1) textually via TWIN expression.
HDR = '#include <stdlib.h>\n#include <stdio.h>\nint h(int a, int k);\n'
HDR_T = '#include <stdlib.h>\n#include <stdio.h>\n'
LIBC = 'int h(int a, int k) { return k + 1; }\n'
LIBQ = 'int h(int a, int k) { return a + k; }\n'
probes = {}
def P(name, body):
    probes[name] = body
# --- stage probes (C=classical verdict, Q=quantum verdict, T=twin with h(q,k) -> (k+1))
P('rb01', 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int q2=cq_theta(n,.3); int r=0; if (q2>3) r=h(q,m); return cq_measure(r)+cq_measure(q2);')
P('rb02', 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int q2=cq_theta(n,.3); int r=t; if (q2>3) r=t+5; return cq_measure(r)+cq_measure(q2);')
P('rb03', 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int q2=cq_theta(n,.3); int r=(q2>3)?t:m*3; return cq_measure(r)+cq_measure(q2);')
P('rb04', 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int q2=cq_theta(n,.3); int r=m; switch(q2){case 1: r=t; break; case 2: r=t+1; break; case 5: r=t+2; break;} return cq_measure(r)+cq_measure(q2);')
P('rb05', 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); printf("%d\\n", t); return cq_measure(q);')
P('rb06', 'static const int tab[8]={3,1,4,1,5,9,2,6}; int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int r=tab[t&7]; return cq_measure(q)+r;')
P('rb07', 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int b[4]={0,0,0,0}; b[n&3]=t; int r=b[m&3]; return cq_measure(q)+r;')
P('rb08', 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int r=cq_theta(q,(double)t*0.1); return cq_measure(r);')
P('rb09', 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int q2=cq_theta(n,.3); if (q2>3) cq_phi((double)t); return cq_measure(q2);')
P('rb10', 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int q2=cq_theta(n,.3); int r=q2; if (m>3) r=cq_theta(q2,.2); return cq_measure(r)+t;')
P('rb11', 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int acc=0; for (int i=0;i<n;i++) acc+=t; return cq_measure(q)+acc;')
P('rb12', 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int x=t; while (x>>1) { x>>=1; n++; } return cq_measure(q)+n;')
P('rb13', 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int r=t; for (int i=0;i<4;i++) r=cq_theta(r,.1); return cq_measure(r);')
P('rb14', 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int r=cq_theta(t,.1); for (int i=0;i<n;i++) r=cq_theta(r,.2); return cq_measure(r);')
P('rb15', 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int q2=cq_theta(n,.3); int r=q2; if (q2>3) r=q2+t; return cq_measure(r);')
P('rb16', 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int q2=cq_theta(n,.3); int r=q2; if (m>3) r=cq_theta(q2,.2); int s=r+t; return cq_measure(s);')
P('rb17', 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int q2=cq_theta(n,.3); int r=q2+t; return cq_measure(r)+cq_measure(q);')
P('rb18', 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); volatile int vt=t; int r=cq_theta(m,.4); if (m>3) r=cq_theta(r,.2); return cq_measure(r)+vt;')
for name, body in probes.items():
    for var, lib in (('C', LIBC), ('Q', LIBQ)):
        open(f'{name}{var}.c','w').write(HDR + 'int main(int c, char **v) { ' + body + ' }\n')
        open(f'{name}{var}.lib.c','w').write(lib)
    tb = body.replace('h(q,m)', '(m+1)')
    open(f'{name}T.c','w').write(HDR_T + 'int main(int c, char **v) { ' + tb + ' }\n')
print(' '.join(f'{n}{v}' for n in probes for v in 'CQT'))
