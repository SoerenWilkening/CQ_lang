#!/usr/bin/env python3
"""Track F: the SEED-PERTURBATION matrix over every fixture that declines with
F2's string.  READ-ONLY on the tree: variants are written into trackF/probes/pin/
and run on the frozen ORACLE.  Never patches the pass.

Per fixture:
  S = seed -> a WILD value nothing in the module folds to.  F2 gone => the decline
      is the PIN half.  F2 stays => the decline is the TRUNCATED half (R-2' is
      inert on it, because `Truncated` is a separate disjunct at the call site).
  A = seed -> the value the SAME collider takes on the OTHER edge.  F2 present
      => the collider's two edge values DIFFER => the pin is ONE-EDGE.
  B = the collider neutralised.  F2 gone => that value is THE collider.
"""
import os, subprocess, sys

ROOT = "/Users/sorenwilkening/Desktop/CQ_lang"
T    = os.path.join(ROOT, "ir-pass/test")
OUT  = os.path.dirname(os.path.abspath(__file__)) + "/pin"
os.makedirs(OUT, exist_ok=True)

P = "control_inplace_ry_reject_stateprep_"
# fixture-stem : { variant : [(old, new), ...] }
SPEC = {
 P+"range_forward_add":  {"S":[("i32 6, double 9","i32 77, double 9"),("[ 6, %entry ]","[ 77, %entry ]")],
                          "A":[("i32 6, double 9","i32 5, double 9"),("[ 6, %entry ]","[ 5, %entry ]")],
                          "B":[("add nuw nsw i32 %t, 5","add nuw nsw i32 %t, 50")]},
 P+"range_forward_sub":  {"S":[("i32 -3, double 9","i32 77, double 9"),("[ -3, %entry ]","[ 77, %entry ]")],
                          "A":[("i32 -3, double 9","i32 -4, double 9"),("[ -3, %entry ]","[ -4, %entry ]")],
                          "B":[("or disjoint i32 %t, -4","or disjoint i32 %t, -40")]},
 P+"range_forward_or":   {"S":[("i32 9, double 9","i32 77, double 9"),("[ 9, %entry ]","[ 77, %entry ]")],
                          "A":[("i32 9, double 9","i32 8, double 9"),("[ 9, %entry ]","[ 8, %entry ]")],
                          "B":[("or disjoint i32 %t, 8","or disjoint i32 %t, 80")]},
 P+"range_forward_xor":  {"S":[("i32 6, double 9","i32 77, double 9"),("[ 6, %entry ]","[ 77, %entry ]")],
                          "A":[("i32 6, double 9","i32 7, double 9"),("[ 6, %entry ]","[ 7, %entry ]")],
                          "B":[("xor i32 %t, 7","xor i32 %t, 70")]},
 P+"range_forward_ashr": {"S":[("i32 -1, double 9","i32 77, double 9"),("[ -1, %entry ]","[ 77, %entry ]")],
                          "A":[("i32 -1, double 9","i32 0, double 9"),("[ -1, %entry ]","[ 0, %entry ]")],
                          "B":[("ashr i32 %q, 31","ashr i32 %q, 3")]},
 P+"range_forward_lshr": {"S":[("i32 1, double 9","i32 77, double 9"),("[ 1, %entry ]","[ 77, %entry ]")],
                          "A":[("i32 1, double 9","i32 0, double 9"),("[ 1, %entry ]","[ 0, %entry ]")],
                          "B":[("lshr i32 %q, 31","lshr i32 %q, 3")]},
 P+"sideways_offset":    {"S":[("i32 5, double 9","i32 77, double 9"),("[ 5, %entry ]","[ 77, %entry ]")],
                          "B":[("udiv i32 %q, 3","udiv i32 %q, 7")]},
 P+"sideways_sdiv":      {"S":[("i32 5, double 9","i32 77, double 9"),("[ 5, %entry ]","[ 77, %entry ]")],
                          "B":[("sdiv i32 %q, 4","sdiv i32 %q, 7")]},
 P+"merge_edge_sideways":{"S":[("i32 5, double 9","i32 77, double 9"),("[ 5, %entry ]","[ 77, %entry ]")],
                          "B":[("sdiv i32 %q, 4","sdiv i32 %q, 7")]},
 P+"offwire_sideways_min":{"S":[("i32 5, double 9","i32 77, double 9"),("[ 5, %entry ]","[ 77, %entry ]")],
                          "B":[("sdiv i32 %q, 4","sdiv i32 %q, 7")]},
 P+"nonwire_still_collides":{"S":[("i32 0, double 9","i32 77, double 9"),("[ 0, %entry ]","[ 77, %entry ]")],
                          "B":[("lshr i32 %q, 31","lshr i32 %q, 3")]},
 P+"cast_zext_live":     {"S":[("i64 5, double 9","i64 77, double 9"),("[ 5, %entry ]","[ 77, %entry ]")],
                          "B":[("zext i32 %q to i64","zext i32 %u0 to i64")]},
 P+"cast_sext_live":     {"S":[("i64 5, double 9","i64 77, double 9"),("[ 5, %entry ]","[ 77, %entry ]")],
                          "B":[("sext i32 %q to i64","sext i32 %u0 to i64")]},
 P+"cast_trunc_live":    {"S":[("i16 5, double 9","i16 77, double 9"),("[ 5, %entry ]","[ 77, %entry ]")],
                          "B":[("trunc i32 %q to i16","trunc i32 %u0 to i16")]},
 P+"fp_seed_sitofp":     {"S":[("double 5.000000e+00, double 9","double 7.000000e+00, double 9"),
                               ("[ 5.000000e+00, %entry ]","[ 7.000000e+00, %entry ]")],
                          "B":[("sitofp i32 %q to double","sitofp i32 %u0 to double")]},
 P+"fcmp_oeq_derived":   {"S":[("double 1.500000e+01, double 9","double 7.000000e+00, double 9"),
                               ("[ 1.500000e+01, %entry ]","[ 7.000000e+00, %entry ]")],
                          "A":[("double 1.500000e+01, double 9","double 5.000000e+00, double 9"),
                               ("[ 1.500000e+01, %entry ]","[ 5.000000e+00, %entry ]")],
                          "B":[("%d = fmul double %t, 3.000000e+00","%d = fmul double %q, 3.000000e+00")]},
 P+"intrinsic_bswap":    {"S":[("i32 5, double 9","i32 77, double 9"),("[ 5, %entry ]","[ 77, %entry ]")],
                          "B":[("llvm.bswap.i32(i32 %q)","llvm.bswap.i32(i32 %u0)")]},
 P+"intrinsic_bitreverse":{"S":[("i32 5, double 9","i32 77, double 9"),("[ 5, %entry ]","[ 77, %entry ]")],
                          "B":[("llvm.bitreverse.i32(i32 %q)","llvm.bitreverse.i32(i32 %u0)")]},
 P+"intrinsic_fshl":     {"S":[("i32 5, double 9","i32 77, double 9"),("[ 5, %entry ]","[ 77, %entry ]")],
                          "B":[("llvm.fshl.i32(i32 %q, i32 %q, i32 8)","llvm.fshl.i32(i32 %u0, i32 %u0, i32 8)")]},
 P+"intrinsic_fshr":     {"S":[("i32 5, double 9","i32 77, double 9"),("[ 5, %entry ]","[ 77, %entry ]")],
                          "B":[("llvm.fshr.i32(i32 %q, i32 %q, i32 8)","llvm.fshr.i32(i32 %u0, i32 %u0, i32 8)")]},
 P+"second_flag_i1":     {"S":[("i1 true, double 9","i1 false, double 9"),("[ true, %entry ]","[ false, %entry ]")],
                          "B":[("%d = icmp sgt i32 %q, 7","%d = icmp sgt i32 %q, 700")]},
 P+"second_cmp_onwire_merge":{"A":[("i1 noundef zeroext false, double noundef 5","i1 noundef zeroext true, double noundef 5"),
                                   ("[ false, %0 ]","[ true, %0 ]")],
                          "B":[("%clone = icmp eq i32 %1, 1","%clone = icmp eq i32 %u, 1")]},
 P+"second_cmp_onwire_pred":{"A":[("i1 noundef zeroext false, double noundef 5","i1 noundef zeroext true, double noundef 5"),
                                   ("[ false, %0 ]","[ true, %0 ]")],
                          "B":[("%clone = icmp eq i32 %1, 1","%clone = icmp eq i32 %1, %1")]},
 P+"zext_flag_i32seed":  {"S":[("i32 noundef 0, double noundef 5.000000e-01) \n  br label","i32 noundef 77, double noundef 5.000000e-01) \n  br label")],
                          "A":[("[ 0, %0 ]","[ 1, %0 ]")],
                          "B":[("%clone = icmp eq i32 %1, 1","%clone = icmp eq i32 %1, %1")]},
 P+"step_cap_over":      {"S":[("i32 7, double 9","i32 77, double 9"),("[ 7, %entry ]","[ 77, %entry ]")]},
 P+"unfoldable_curated_call":{"S":[("i32 83886080, double 9","i32 77, double 9"),("[ 83886080, %entry ]","[ 77, %entry ]")]},
 P+"unevaluable_pinned_operand":{"S":[("i32 7, double 9","i32 77, double 9"),("[ 7, %entry ]","[ 77, %entry ]")]},
 "control_peel_reject_fp_stateprep":{"S":[("[ 0, %0 ]","[ 77, %0 ]"),
                                          ("%6 = tail call i32 @cq_theta_si32(i32 noundef 0,","%6 = tail call i32 @cq_theta_si32(i32 noundef 77,")]},
 "control_peel_reject_stateprep_handwritten_clone_i1":{
     "A":[("i1 noundef zeroext false, double noundef 5","i1 noundef zeroext true, double noundef 5"),("[ false, %0 ]","[ true, %0 ]")],
     "B":[("%clone = icmp eq i32 %1, 1","%clone = icmp eq i32 %1, %1")]},
}

def run(path):
    e = dict(os.environ); e["CQ_CTRL_DBG"]="1"
    r = subprocess.run([ROOT+"/build/ir-pass/cq-opt","-load-pass-plugin",
                        ROOT+"/build/ir-pass/libCQPass.so","-passes=cq-lowering",
                        "-S",path,"-o","/dev/null"], capture_output=True, text=True, env=e)
    err = r.stderr
    if "state prep seed is proven equal" in err: return "F2"
    if r.returncode == 0: return "ACCEPT"
    i = err.find("lowering: ")
    return "D:" + (err[i+10:i+58].split("\n")[0] if i>=0 else err[:40].replace("\n"," "))

rows=[]
for stem, variants in SPEC.items():
    src = open(os.path.join(T, stem+".ll")).read()
    base = run(os.path.join(T, stem+".ll"))
    for v, subs in variants.items():
        txt = src; ok=True
        for old,new in subs:
            if old not in txt: ok=False; rows.append((stem,v,"SUBST-MISS: "+old[:40],"")); break
            txt = txt.replace(old,new)
        if not ok: continue
        p = os.path.join(OUT, stem+"."+v+".ll")
        open(p,"w").write(txt)
        rows.append((stem, v, base, run(p)))

w = max(len(r[0]) for r in rows)
for stem,v,base,res in rows:
    print(f"{stem[len(P):] if stem.startswith(P) else stem:<34} {v}  base={base:<7} -> {res}")
