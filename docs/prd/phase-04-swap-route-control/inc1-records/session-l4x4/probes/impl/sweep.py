import subprocess, sys, glob, os, re, json
from concurrent.futures import ProcessPoolExecutor
SC="/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/60377191-fd09-487c-94e9-06dc4f78248f/scratchpad/l4x4"
BINS={
 "ORACLE":("/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt","/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/libCQPass.so"),
 "F2":("/Users/sorenwilkening/Desktop/CQ_f2/build/ir-pass/cq-opt","/Users/sorenwilkening/Desktop/CQ_f2/build/ir-pass/libCQPass.so"),
 "SUBJ":(SC+"/cq-opt.subj",SC+"/libCQPass.subj.so"),
}
RE=re.compile(r'cq [a-z ]*lowering: (.*?) under quantum control')
def run(a):
    f,tag=a
    b,p=BINS[tag]
    try:
        r=subprocess.run([b,"-load-pass-plugin",p,"-passes=cq-lowering","-S",f,"-o","-"],capture_output=True,timeout=120)
    except Exception as e:
        return (f,tag,-9,"TIMEOUT","")
    m=RE.search(r.stderr.decode(errors="replace"))
    return (f,tag,r.returncode,m.group(1) if m else "",r.stdout.decode(errors="replace"))
def main():
  files=sorted(glob.glob("/Users/sorenwilkening/Desktop/CQ_l4x4/ir-pass/test/*.ll"))
  jobs=[(f,t) for f in files for t in ("ORACLE","F2","SUBJ")]
  res={}
  with ProcessPoolExecutor(max_workers=6) as ex:
      for f,tag,rc,msg,out in ex.map(run,jobs,chunksize=8):
          res.setdefault(f,{})[tag]=(rc,msg,out)
  rc_of=lambda d,t: d[t][0]
  movers_f2=[];movers_subj=[];diagdiff=[];outdiff=[]
  for f,d in sorted(res.items()):
      o,f2,s=d["ORACLE"],d["F2"],d["SUBJ"]
      if (o[0]!=0)!=(f2[0]!=0) or o[1]!=f2[1]: movers_f2.append((os.path.basename(f),o[0],o[1],f2[0],f2[1]))
      if (f2[0]!=0)!=(s[0]!=0): movers_subj.append((os.path.basename(f),f2[0],f2[1],s[0],s[1]))
      elif f2[1]!=s[1]: diagdiff.append((os.path.basename(f),f2[1],s[1]))
      elif f2[0]==0 and s[0]==0 and f2[2]!=s[2]: outdiff.append(os.path.basename(f))
  print("files=%d"%len(res))
  print("ORACLE->F2 rc/diag movers: %d"%len(movers_f2))
  for m in movers_f2: print("   F2MOVE",m)
  print("F2->SUBJ rc movers: %d"%len(movers_subj))
  for m in movers_subj: print("   SUBJMOVE %-64s rc=%d %-46s -> rc=%d %s"%m)
  print("F2->SUBJ DIAGDIFF (same rc, different string): %d"%len(diagdiff))
  for m in diagdiff: print("   DIAG",m)
  print("F2->SUBJ OUTDIFF (both accept, different lowered IR): %d"%len(outdiff))
  for m in outdiff: print("   OUT",m)


if __name__=="__main__":
  main()
