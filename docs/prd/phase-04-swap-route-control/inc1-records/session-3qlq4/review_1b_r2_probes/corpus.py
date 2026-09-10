import os, subprocess, sys, concurrent.futures
NEW="/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt"
OLD=sys.argv[1]
D=sys.argv[2]
files=sorted(f for f in os.listdir(D) if f.endswith(".ll"))
def go(f):
    p=os.path.join(D,f)
    a=subprocess.run([OLD,"-passes=cq-lowering","-S",p,"-o","-"],capture_output=True,text=True)
    b=subprocess.run([NEW,"-passes=cq-lowering","-S",p,"-o","-"],capture_output=True,text=True)
    tags=[]
    if a.returncode!=b.returncode: tags.append("RCDIFF")
    if a.stderr!=b.stderr: tags.append("DIAGDIFF")
    if a.stdout!=b.stdout: tags.append("OUTDIFF")
    return (f,tags,a.returncode,b.returncode,a.stderr.strip().splitlines()[:1],b.stderr.strip().splitlines()[:1])
with concurrent.futures.ThreadPoolExecutor(max_workers=8) as ex:
    res=list(ex.map(go,files))
movers=[r for r in res if r[1]]
rc=sum(1 for r in res if "RCDIFF" in r[1]); dg=sum(1 for r in res if "DIAGDIFF" in r[1]); ot=sum(1 for r in res if "OUTDIFF" in r[1])
print(f"{len(files)} fixtures from {D}: {rc} RCDIFF, {dg} DIAGDIFF, {ot} OUTDIFF")
for m in movers:
    print("  ",m[0],m[1],f"rc {m[2]}->{m[3]}")
    print("      OLD:",m[4]); print("      NEW:",m[5])
