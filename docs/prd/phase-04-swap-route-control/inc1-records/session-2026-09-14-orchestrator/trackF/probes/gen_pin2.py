#!/usr/bin/env python3
"""Track F round 2 — TEST W, the decisive ONE-EDGE test, plus two repairs.

TEST W: change the BRANCH's constant so the PINNED edge's collider value is no
longer the seed, while the OTHER edge's fact stays MATERIALLY THE SAME (a
co-singleton `full \\ {K}` stays a co-singleton `full \\ {K'}`; a half-range
stays a half-range of the same shape).  ConstantRange is monotone, so any fold
to a singleton that the OTHER edge's fact supported before is still supported
after.  Therefore  F2 GONE under W  ==>  the other edge never folded to the seed
==>  THE PIN IS ONE-EDGE.  (This is DIAG_2026-09-14's S1 surgery, generalised.)
"""
import os, subprocess
ROOT="/Users/sorenwilkening/Desktop/CQ_lang"; T=ROOT+"/ir-pass/test"
OUT=os.path.dirname(os.path.abspath(__file__))+"/pin"; os.makedirs(OUT,exist_ok=True)
P="control_inplace_ry_reject_stateprep_"
SPEC={
 # ---- TEST W over the `icmp eq %q, K` family: move K.
 P+"cast_zext_live":        {"W":[("icmp eq i32 %q, 5","icmp eq i32 %q, 4")]},
 P+"cast_sext_live":        {"W":[("icmp eq i32 %q, 5","icmp eq i32 %q, 4")]},
 P+"cast_trunc_live":       {"W":[("icmp eq i32 %q, 5","icmp eq i32 %q, 4")]},
 P+"fp_seed_sitofp":        {"W":[("icmp eq i32 %q, 5","icmp eq i32 %q, 4")]},
 P+"intrinsic_bswap":       {"W":[("icmp eq i32 %q, 83886080","icmp eq i32 %q, 83886081")]},
 P+"intrinsic_bitreverse":  {"W":[("icmp eq i32 %q, -1610612736","icmp eq i32 %q, -1610612735")]},
 P+"intrinsic_fshl":        {"W":[("icmp eq i32 %q, 83886080","icmp eq i32 %q, 83886081")]},
 P+"intrinsic_fshr":        {"W":[("icmp eq i32 %q, 1280","icmp eq i32 %q, 1281")]},
 P+"nonwire_still_collides":{"W":[("icmp eq i32 %q, 3","icmp eq i32 %q, -3")],
                             "B2":[("lshr i32 %q, 31","lshr i32 %q, 1")]},
 P+"sideways_sdiv":         {"W":[("icmp eq i32 %m, 20","icmp eq i32 %m, 24")]},
 P+"merge_edge_sideways":   {"W":[("icmp eq i32 %m, 20","icmp eq i32 %m, 24")]},
 P+"offwire_sideways_min":  {"W":[("icmp eq i32 %o, 20","icmp eq i32 %o, 24")]},
 P+"sideways_offset":       {"W":[("%o = add i32 %q, -15","%o = add i32 %q, -30")]},
 P+"second_flag_i1":        {"W":[("%c = icmp sgt i32 %q, 100","%c = icmp sgt i32 %q, 5")]},
 P+"fcmp_oeq_derived":      {"W":[("fcmp oeq double %t, 5.000000e+00","fcmp oeq double %t, 6.000000e+00")]},
 # ---- repairs of the two round-1 probes that mis-substituted.
 P+"zext_flag_i32seed":     {"S2":[("%4 = tail call i32 @cq_theta_si32(i32 noundef 0,","%4 = tail call i32 @cq_theta_si32(i32 noundef 77,"),
                                   ("[ 0, %0 ]","[ 77, %0 ]")],
                             "A2":[("%4 = tail call i32 @cq_theta_si32(i32 noundef 0,","%4 = tail call i32 @cq_theta_si32(i32 noundef 1,"),
                                   ("[ 0, %0 ]","[ 1, %0 ]")]},
 # ---- TEST W for the range_forward family too (belt and braces beside TEST A).
 P+"range_forward_add":     {"W":[("%fwd = add nuw nsw i32 %t, 5","%fwd = add nuw nsw i32 %t, 50")]},
}
def run(p):
    e=dict(os.environ); e["CQ_CTRL_DBG"]="1"
    r=subprocess.run([ROOT+"/build/ir-pass/cq-opt","-load-pass-plugin",ROOT+"/build/ir-pass/libCQPass.so",
                      "-passes=cq-lowering","-S",p,"-o","/dev/null"],capture_output=True,text=True,env=e)
    if "state prep seed is proven equal" in r.stderr: return "F2"
    if r.returncode==0: return "ACCEPT"
    i=r.stderr.find("lowering: ")
    return "D:"+(r.stderr[i+10:i+56].split("\n")[0] if i>=0 else "?")
for stem,vs in SPEC.items():
    src=open(os.path.join(T,stem+".ll")).read()
    for v,subs in vs.items():
        txt=src; miss=None
        for o,n in subs:
            if o not in txt: miss=o; break
            txt=txt.replace(o,n)
        if miss: print(f"{stem[len(P):]:<30} {v}  SUBST-MISS {miss[:40]}"); continue
        p=os.path.join(OUT,stem+"."+v+".ll"); open(p,"w").write(txt)
        print(f"{stem[len(P):] if stem.startswith(P) else stem:<30} {v:<3} -> {run(p)}")
