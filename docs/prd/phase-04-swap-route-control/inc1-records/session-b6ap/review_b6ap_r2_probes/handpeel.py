#!/usr/bin/env python3
"""handpeel.py <name> — mechanically apply the peel to <name>.s1.ll -> <name>t_handpeel.s1.ll.
Step 1: NAME every unnamed value and block in every function (so numbering never
constrains the edit).  Step 2: in each merge block of a tainted diamond, replace
every CONSTANT-incoming 2-value phi with an `icmp` clone + `select`."""
import re, sys

name = sys.argv[1]
src = open(name + ".s1.ll").read()

# ---- step 1: name everything -------------------------------------------------
out = []
for fn in re.split(r"(?m)^(?=define )", src):
    if not fn.startswith("define"):
        out.append(fn); continue
    lines = fn.split("\n")
    explicit = set(re.findall(r"(?m)^(\d+):", fn))
    refd = set(re.findall(r"label %(\d+)", fn)) | set(re.findall(r"\], \[ [^,]+, %(\d+) \]", fn)) | set(re.findall(r"%(\d+) \]", fn))
    entry = sorted(int(x) for x in (refd - explicit)) if (refd - explicit) else []
    entry = str(entry[0]) if entry else None
    ren = {}
    newl = []
    for l in lines:
        if l.startswith("define"):
            newl.append(l)
            if entry is not None:
                ren["%" + entry] = "%entryblk"
                newl.append("entryblk:")
            continue
        m = re.match(r"^(\d+):(.*)$", l)
        if m:
            ren["%" + m.group(1)] = "%b" + m.group(1)
            newl.append("b" + m.group(1) + ":" + m.group(2)); continue
        m = re.match(r"^\s*%(\d+) = (.*)$", l)
        if m:
            ren["%" + m.group(1)] = "%v" + m.group(1)
            newl.append("  %v" + m.group(1) + " = " + m.group(2)); continue
        newl.append(l)
    body = "\n".join(newl)
    body = re.sub(r"%(\d+)\b", lambda mo: ren.get("%" + mo.group(1), "%" + mo.group(1)), body)
    out.append(body)
src = "".join(out)

# ---- step 2: the peel --------------------------------------------------------
lines = src.split("\n")
blocks = {}; cur=None; start=None
for i,l in enumerate(lines):
    m = re.match(r"^([\w.]+):", l)
    if m:
        if cur: blocks[cur]=(start,i)
        cur=m.group(1); start=i
    elif l.startswith("define"):
        if cur: blocks[cur]=(start,i)
        cur=None; start=None
if cur: blocks[cur]=(start,len(lines))

bi=None
for i,l in enumerate(lines):
    m=re.search(r"br i1 %([\w.]+), label %([\w.]+), label %([\w.]+)", l)
    if m: bi=(i,m.group(1),m.group(2),m.group(3)); break
assert bi, "no conditional br"
i_br, cond, s0, s1 = bi
cmpsrc=None
for l in lines:
    m=re.match(r"\s*%"+re.escape(cond)+r" = ((icmp|fcmp) .*)$", l)
    if m: cmpsrc=m.group(1); break
assert cmpsrc, "cond not a cmp"
predlbl=[lbl for lbl,(s,e) in blocks.items() if s<=i_br<e][0]
def usucc(lbl):
    s,e=blocks[lbl]
    for l in lines[s:e]:
        m=re.match(r"\s*br label %([\w.]+)\s*$",l)
        if m: return m.group(1)
    return None
if usucc(s0)==s1: merge,tp,fp = s1,s0,predlbl
elif usucc(s1)==s0: merge,tp,fp = s0,predlbl,s1
else: sys.exit("not a diamond")

ms,me = blocks[merge]
ins=[]; drop=set(); k=0
for i in range(ms,me):
    m=re.match(r"\s*%([\w.]+) = phi (\S+) \[ (.+?), %([\w.]+) \], \[ (.+?), %([\w.]+) \]\s*$", lines[i])
    if not m: continue
    res,ty,v1,b1,v2,b2 = m.groups()
    vals={b1:v1,b2:v2}
    tv,fv = vals.get(tp), vals.get(fp)
    if tv is None or fv is None: continue
    if tv.startswith("%") or fv.startswith("%"): continue   # not a constant mux
    cname = "cq.peel.cond" if k==0 else "cq.peel.cond%d"%k
    ins.append("  %%%s = %s"%(cname,cmpsrc))
    ins.append("  %%%s = select i1 %%%s, %s %s, %s %s"%(res,cname,ty,tv,ty,fv))
    drop.add(i); k+=1
assert ins, "nothing peelable"
fnp=None
for i in range(ms+1,me):
    if i in drop: continue
    if " = phi " in lines[i]: continue
    if lines[i].strip()=="": continue
    fnp=i; break
newlines=[l for i,l in enumerate(lines) if i not in drop]
fnp2 = newlines.index(lines[fnp])
newlines[fnp2] = "\n".join(ins)+"\n"+newlines[fnp2]
open(name+"t_handpeel.s1.ll","w").write("\n".join(newlines))
print("wrote",name+"t_handpeel.s1.ll","peeled",k,"phi(s)")
