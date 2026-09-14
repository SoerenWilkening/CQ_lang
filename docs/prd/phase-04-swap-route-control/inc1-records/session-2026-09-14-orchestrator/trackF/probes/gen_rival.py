#!/usr/bin/env python3
"""Track F — THE RIVAL AUDIT.  For every fixture R-2' flips, build the UNFOLDED
rival: the source module `-O1` could have folded INTO the fixture, with the
COLLIDER REGISTER written where the fixture shows the seed LITERAL.

Polarity decides which slot the register goes in (this is the whole R-2' case
analysis):
  ARM-edge pin  -> the register can only have been the ARM theta's arg-0
                   (on the straight-through edge it is NOT the seed, so the phi's
                   pred incoming must already have been the literal).
  ST-edge  pin  -> the register can only have been the phi's PRED incoming
                   (on the arm edge it is NOT the seed).
A register defined in the merge block is HOISTED before the branch: that is what
`-O1` sinking undid, and a rival must be a well-formed module.
"""
import os, subprocess
ROOT="/Users/sorenwilkening/Desktop/CQ_lang"; T=ROOT+"/ir-pass/test"
OUT=os.path.dirname(os.path.abspath(__file__))+"/rival"; os.makedirs(OUT,exist_ok=True)
P="control_inplace_ry_reject_stateprep_"
# stem : (polarity, [lines-to-hoist-before-the-br], (old,new) slot edit)
R={
 P+"range_forward_add":  ("ARM",["%fwd = add nuw nsw i32 %t, 5"],("i32 6, double 9.000000e-01","i32 %fwd, double 9.000000e-01")),
 P+"range_forward_sub":  ("ARM",["%fwd = or disjoint i32 %t, -4"],("i32 -3, double 9.000000e-01","i32 %fwd, double 9.000000e-01")),
 P+"range_forward_or":   ("ARM",["%fwd = or disjoint i32 %t, 8"],("i32 9, double 9.000000e-01","i32 %fwd, double 9.000000e-01")),
 P+"range_forward_xor":  ("ARM",["%fwd = xor i32 %t, 7"],("i32 6, double 9.000000e-01","i32 %fwd, double 9.000000e-01")),
 P+"range_forward_ashr": ("ARM",["%fwd = ashr i32 %q, 31"],("i32 -1, double 9.000000e-01","i32 %fwd, double 9.000000e-01")),
 P+"range_forward_lshr": ("ARM",["%fwd = lshr i32 %q, 31"],("i32 1, double 9.000000e-01","i32 %fwd, double 9.000000e-01")),
 P+"sideways_offset":    ("ARM",["%t  = udiv i32 %q, 3"],("i32 5, double 9.000000e-01","i32 %t, double 9.000000e-01")),
 P+"sideways_sdiv":      ("ARM",["%t  = sdiv i32 %q, 4"],("i32 5, double 9.000000e-01","i32 %t, double 9.000000e-01")),
 P+"merge_edge_sideways":("ST", ["%t  = sdiv i32 %q, 4"],("[ 5, %entry ]","[ %t, %entry ]")),
 P+"offwire_sideways_min":("ARM",[],("i32 5, double 9.000000e-01","i32 %t, double 9.000000e-01")),
 P+"nonwire_still_collides":("ARM",[],("i32 0, double 9.000000e-01","i32 %t, double 9.000000e-01")),
 P+"cast_zext_live":     ("ARM",["%t  = zext i32 %q to i64"],("i64 5, double 9.000000e-01","i64 %t, double 9.000000e-01")),
 P+"cast_sext_live":     ("ARM",["%t  = sext i32 %q to i64"],("i64 5, double 9.000000e-01","i64 %t, double 9.000000e-01")),
 P+"cast_trunc_live":    ("ARM",["%t  = trunc i32 %q to i16"],("i16 5, double 9.000000e-01","i16 %t, double 9.000000e-01")),
 P+"fp_seed_sitofp":     ("ARM",["%t  = sitofp i32 %q to double"],("double 5.000000e+00, double 9.000000e-01","double %t, double 9.000000e-01")),
 P+"fcmp_oeq_derived":   ("ARM",["%d = fmul double %t, 3.000000e+00"],("double 1.500000e+01, double 9.000000e-01","double %d, double 9.000000e-01")),
 P+"intrinsic_bswap":    ("ARM",["%t = call i32 @llvm.bswap.i32(i32 %q)"],("i32 5, double 9.000000e-01","i32 %t, double 9.000000e-01")),
 P+"intrinsic_bitreverse":("ARM",["%t = call i32 @llvm.bitreverse.i32(i32 %q)"],("i32 5, double 9.000000e-01","i32 %t, double 9.000000e-01")),
 P+"intrinsic_fshl":     ("ARM",["%t = call i32 @llvm.fshl.i32(i32 %q, i32 %q, i32 8)"],("i32 5, double 9.000000e-01","i32 %t, double 9.000000e-01")),
 P+"intrinsic_fshr":     ("ARM",["%t = call i32 @llvm.fshr.i32(i32 %q, i32 %q, i32 8)"],("i32 5, double 9.000000e-01","i32 %t, double 9.000000e-01")),
 P+"second_flag_i1":     ("ARM",[],("i1 true, double 9.000000e-01","i1 %d, double 9.000000e-01")),
 P+"second_cmp_onwire_merge":("ST",["%clone = icmp eq i32 %1, 1"],("[ false, %0 ]","[ %clone, %0 ]")),
 P+"second_cmp_onwire_pred": ("ST",[],("[ false, %0 ]","[ %clone, %0 ]")),
 P+"zext_flag_i32seed":  ("ST",["%clone = icmp eq i32 %1, 1","%cz = zext i1 %clone to i32"],("[ 0, %0 ]","[ %cz, %0 ]")),
 "control_peel_reject_stateprep_handwritten_clone_i1":("ST",["%clone = icmp eq i32 %1, 1"],("[ false, %0 ]","[ %clone, %0 ]")),
}
def run(p):
    e=dict(os.environ); e["CQ_CTRL_DBG"]="1"
    r=subprocess.run([ROOT+"/build/ir-pass/cq-opt","-load-pass-plugin",ROOT+"/build/ir-pass/libCQPass.so",
                      "-passes=cq-lowering","-S",p,"-o","/dev/null"],capture_output=True,text=True,env=e)
    if r.returncode==0: return "ACCEPT  <<<< HOLE"
    i=r.stderr.find("lowering: ")
    return (r.stderr[i+10:i+70].split("\n")[0] if i>=0 else "?")
for stem,(pol,hoist,(o,n)) in R.items():
    lines=open(os.path.join(T,stem+".ll")).read().split("\n")
    moved=[]
    for h in hoist:
        idx=[i for i,l in enumerate(lines) if h in l]
        assert len(idx)==1, (stem,h,idx)
        moved.append(lines.pop(idx[0]))
    if moved:
        b=[i for i,l in enumerate(lines) if l.strip().startswith("br i1")][0]
        lines[b:b]=moved
    txt="\n".join(lines)
    assert o in txt, (stem,o)
    txt=txt.replace(o,n,1)
    p=os.path.join(OUT,stem+".RIVAL.ll"); open(p,"w").write(txt)
    print(f"{(stem[len(P):] if stem.startswith(P) else stem):<36} {pol:<3} rival -> {run(p)}")
