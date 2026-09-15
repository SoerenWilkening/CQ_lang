#!/usr/bin/env python3
"""relabel.py — apply E3's SAME-BLOCK relabel to a .ll and print the result.

Exactly the DEFINITE subset of `post_measure_ir_scan.py`: for `%m = call @cq_measure_X(%q)`,
every LATER use of `%q` in the SAME basic block becomes `%m`.  Same-block lexical order IS
dominance, so this is a SUBSET of what E3's `DT.dominates(M, Use)` would rewrite — it can
UNDER-state E3's blast radius and can never over-state it.  Debug records are not uses.
"""
import re,sys
MEAS=re.compile(r'^\s*(%[\w.]+)\s*=\s*(?:tail\s+|musttail\s+|notail\s+)?call[^@]*@(cq_measure_[a-z0-9]+)\((.*)\)\s*(?:#\d+)?\s*(?:,\s*!.*)?$')
REG=re.compile(r'%[\w.]+')
def run(text):
    lines=text.splitlines(); out=list(lines)
    # block boundaries
    infn=False; bstart=0; blocks=[]
    for i,L in enumerate(lines):
        if L.startswith('define'): infn=True; bstart=i+1; continue
        if not infn: continue
        if L.startswith('}'): blocks.append((bstart,i)); infn=False; continue
        if re.match(r'^[\w.$-]+:',L): blocks.append((bstart,i)); bstart=i+1
    nrw=0
    for (a,b) in blocks:
        for i in range(a,b):
            m=MEAS.match(lines[i])
            if not m: continue
            mres=m.group(1); ops=REG.findall(m.group(3))
            if not ops: continue
            q=ops[-1]
            for j in range(i+1,b):
                L=out[j]
                if '#dbg_' in L or '@llvm.dbg.' in L or L.strip().startswith(';'): continue
                if re.match(r'^\s*%[\w.]+\s*=',L):
                    lhs,rhs=L.split('=',1)
                    new=lhs+'='+re.sub(r'(?<![%\w])'+re.escape(q)+r'(?![0-9A-Za-z_.])',mres,rhs)
                else:
                    new=re.sub(r'(?<![%\w])'+re.escape(q)+r'(?![0-9A-Za-z_.])',mres,L)
                if new!=out[j]: nrw+=1; out[j]=new
    return "\n".join(out)+"\n", nrw
if __name__=='__main__':
    t,n=run(open(sys.argv[1]).read())
    sys.stderr.write(f"relabelled {n} line(s)\n")
    sys.stdout.write(t)
