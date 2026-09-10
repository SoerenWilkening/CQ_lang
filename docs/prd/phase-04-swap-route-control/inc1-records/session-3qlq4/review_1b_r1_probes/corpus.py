import os, subprocess, sys
NEW="/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt"
OLD="/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/399370cc-11ea-43ff-bc2d-6a55cc78fdb2/scratchpad/review_1b/wt-main/build/ir-pass/cq-opt"
D="/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/399370cc-11ea-43ff-bc2d-6a55cc78fdb2/scratchpad/review_1b/wt-main/ir-pass/test"
files=sorted(f for f in os.listdir(D) if f.endswith(".ll"))
rc=diag=out=0; movers=[]
for f in files:
    p=os.path.join(D,f)
    a=subprocess.run([OLD,"-passes=cq-lowering","-S",p,"-o","-"],capture_output=True,text=True)
    b=subprocess.run([NEW,"-passes=cq-lowering","-S",p,"-o","-"],capture_output=True,text=True)
    tags=[]
    if a.returncode!=b.returncode: tags.append("RCDIFF"); rc+=1
    if a.stderr!=b.stderr: tags.append("DIAGDIFF"); diag+=1
    if a.stdout!=b.stdout: tags.append("OUTDIFF"); out+=1
    if tags: movers.append((f,tags,a.returncode,b.returncode))
print(f"{len(files)} fixtures (main's set): {rc} RCDIFF, {diag} DIAGDIFF, {out} OUTDIFF")
for m in movers[:60]: print("  ",m)
