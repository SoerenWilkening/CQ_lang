#!/usr/bin/env python3
"""post_measure_ir_scan.py — the E3 POPULATION over stage-1 / fixture .ll modules.

For every `%m = call ... @cq_measure_<sfx>(<ty> ... %q)` it reports uses of `%q`
OTHER THAN that call's own operand, split into:

  DEFINITE : a later instruction in the SAME basic block.  Lexical order inside a
             block IS dominance, so E3's `DT.dominates(M, U)` holds for certain.
  POSSIBLE : any other use in the same function.  An UPPER BOUND — E3 relabels only
             the dominated subset, and this scanner computes no dominator tree.

⚠ A crude scan is a LOWER BOUND for DEFINITE and an UPPER BOUND for POSSIBLE, never a
census (Rule 11).  `--selftest` runs it over the m14 family and the e3 twins with the
verdicts this track measured by hand on the ORACLE, and FAILS LOUDLY on a miscount.
"""
import re, sys, glob, os

MEAS = re.compile(r'^\s*(%[\w.]+)\s*=\s*(?:tail\s+|musttail\s+|notail\s+)?call[^@]*@(cq_measure_[a-z0-9]+)\((.*)\)\s*(?:#\d+)?\s*(?:,\s*!.*)?$')
REG  = re.compile(r'%[\w.]+')

def parse_funcs(text):
    """-> list of (fname, [ (blockname,[lines]) ])"""
    out=[]; cur=None
    for L in text.splitlines():
        if L.startswith('define'):
            m=re.search(r'@([\w.$]+)\(',L); cur=(m.group(1) if m else '?',[('entry',[])]); out.append(cur); continue
        if cur is None: continue
        if L.startswith('}'): cur=None; continue
        mb=re.match(r'^([\w.$-]+):',L)
        if mb: cur[1].append((mb.group(1),[])); continue
        # DEBUG RECORDS AND DEBUG INTRINSICS ARE NOT USES.  `#dbg_value(i32 %1, ...)`
        # (LLVM 19 debug records) and `call void @llvm.dbg.*` name a value without
        # reading it; counting them made every self-test case over-report (measured:
        # 7 of 7 FAIL before this filter).  Rule 12 (c) on an instrument.
        if '#dbg_' in L or '@llvm.dbg.' in L or L.strip().startswith(';'):
            continue
        cur[1][-1][1].append(L)
    return out

def scan_module(text):
    res=[]   # (fname, measure-result, operand, n_definite, n_possible)
    for fname, blocks in parse_funcs(text):
        flat=[(bi,li,L) for bi,(bn,ls) in enumerate(blocks) for li,L in enumerate(ls)]
        for bi,li,L in flat:
            m=MEAS.match(L)
            if not m: continue
            mres, sym, args = m.group(1), m.group(2), m.group(3)
            ops=REG.findall(args)
            if not ops: continue
            q=ops[-1]
            definite=possible=0
            for bj,lj,L2 in flat:
                if (bj,lj)==(bi,li): continue
                # operand occurrences only: strip a leading "%x = "
                rhs=L2.split('=',1)[1] if re.match(r'^\s*%[\w.]+\s*=',L2) else L2
                n=len([r for r in REG.findall(rhs) if r==q])
                if n==0: continue
                if bj==bi:
                    # SAME BLOCK: lexical order IS dominance.  A use BEFORE the
                    # measure is not a post-measure use at all and must count as
                    # NEITHER (measured: counting it made m14b, which measures one
                    # name twice, report possible=2 for two uses that precede the
                    # second measure).
                    if lj > li: definite += n
                else:
                    possible += n
            if definite or possible:
                res.append((fname,mres,q,definite,possible))
    return res

def selftest():
    base=os.path.dirname(os.path.abspath(__file__))+'/out'
    want={  # file -> (definite, possible)  hand-verified on the ORACLE by track M
      'm14a_measure_then_theta.s1.ll':(1,0),
      'm14b_measure_theta_measure_parent.s1.ll':(2,0),
      'm14d_measure_then_two_siblings.s1.ll':(2,0),
      'm14f_measure_then_pureop.s1.ll':(2,0),
      'm14c_measure_then_inloop_reuse.s1.ll':(0,1),   # the read is in the LOOP block
      'e3a_twin_reseed_from_m.s1.ll':(0,0),           # already re-seeded: nothing to do
      'e3j_inloop_measure_only.s1.ll':(0,0),          # the brief's back-edge case
    }
    bad=0
    for f,(wd,wp) in want.items():
        p=os.path.join(base,f)
        if not os.path.exists(p): print(f"  selftest {f}: MISSING -> HOLE"); bad+=1; continue
        r=scan_module(open(p).read())
        gd=sum(x[3] for x in r); gp=sum(x[4] for x in r)
        ok = (gd,gp)==(wd,wp)
        print(f"  selftest {f}: want=({wd},{wp}) got=({gd},{gp}) {'ok' if ok else 'FAIL'}")
        if not ok: bad+=1
    if bad: print(f"SELFTEST FAILED ({bad})"); sys.exit(2)
    print(f"SELFTEST PASSED ({len(want)} modules, 5 known positives, 2 known negatives)")

if __name__=='__main__':
    if '--selftest' in sys.argv: selftest(); sys.exit(0)
    pats=sys.argv[1:] or ['ir-pass/test/*.ll']
    files=[f for p in pats for f in sorted(glob.glob(p))]
    nd=np=0; fd=set(); fp=set()
    for f in files:
        try: r=scan_module(open(f, errors='replace').read())
        except Exception as e: print(f"{f}: PARSE ERROR {e}"); continue
        for fn,mres,q,d,p in r:
            if d: nd+=d; fd.add(f)
            if p: np+=p; fp.add(f)
            print(f"{os.path.basename(f)} | {fn} | {mres}=measure({q}) | definite={d} possible={p}")
    print(f"--- {len(files)} modules scanned: DEFINITE {nd} use(s) in {len(fd)} module(s); "
          f"POSSIBLE(upper bound) {np} use(s) in {len(fp)} module(s) ---")
