HDR = '#include <stdlib.h>\nint h(int a, int k);\n'
LIBC = 'int h(int a, int k) { return k + 1; }\n'
PRE = 'int m=atoi(v[1]),n=atoi(v[2]); int q=cq_theta(m,.5); int t=h(q,m); int q2=cq_theta(n,.3); '
P = {
 'za': 'int r=t; if (q2>3) r=cq_theta(t,.2); return cq_measure(r)+cq_measure(q2)+cq_measure(t);',
 'zb': 'int r=t; if (q2>3) r=cq_theta(t,.2); int s=cq_theta(t,.4); return cq_measure(r)+cq_measure(s)+cq_measure(q2);',
 'zc': 'int r=t; if (q2>3) r=cq_theta(t,.2); int u=r+1; return cq_measure(u)+cq_measure(q2);',
 'zd': 'int r=t; if (q2==t) r=cq_theta(q2,.2); return cq_measure(r)+cq_measure(q2);',
 'zf': 'int q3=cq_theta(n+1,.6); int r=t; if (q2>3) r=cq_theta(t,.2); int s=r; if (q3>2) s=cq_theta(r,.4); return cq_measure(s)+cq_measure(q2)+cq_measure(q3);',
 'zg': 'int acc=0; for (int i=0;i<3;i++) { int r=t; if (q2>i) r=cq_theta(t,.2); acc+=cq_measure(r); } return acc+cq_measure(q2);',
 'zi': 'int r; if (q2>3) r=cq_theta(t,.7); else r=cq_theta(t,.2); return cq_measure(r)+cq_measure(q2)+t;',
 'zj': 'int r=t; if (q2>3) r=cq_theta(t,.2); int w=cq_theta(r,.9); return cq_measure(w)+cq_measure(q2);',
 'zk': 'int r=t; if (q2>3) r=cq_theta(t,.2); if (m>2) r=cq_theta(r,.9); return cq_measure(r)+cq_measure(q2);',
 'zl': 'int r=t; if (m>2) r=cq_theta(t,.9); int s=r; if (q2>3) s=cq_theta(r,.2); return cq_measure(s)+cq_measure(q2);',
 'zm': 'int r=t; if (q2>3) r=cq_theta(t,.2); else r=cq_theta(t,.5); int s=r; if (m>1) s=cq_theta(r,.1); return cq_measure(s)+cq_measure(q2);',
}
for k, b in P.items():
    open(k+'C.c','w').write(HDR + 'int main(int c, char **v) { ' + PRE + b + ' }\n')
    open(k+'C.lib.c','w').write(LIBC)
    open(k+'T.c','w').write('#include <stdlib.h>\nint main(int c, char **v) { ' + PRE.replace('h(q,m)','(m+1)') + b + ' }\n')
open('list3.txt','w').write(' '.join(f'{k}{v}' for k in P for v in 'CT'))
