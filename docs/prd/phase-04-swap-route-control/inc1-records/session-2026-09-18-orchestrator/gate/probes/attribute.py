#!/usr/bin/env python3
"""Attribute every D->A mover by RE-MEASURING the ORACLE's full diagnostic.

The sweep row stores `cut -c1-200` of the whole error LINE, so a long path can eat
the message and leave an ambiguous fragment (`condi` is a prefix of THREE real
strings). Rather than trust the fragment, this re-runs the ORACLE on each D->A
module and reads the message in full.
"""
import sys, os, subprocess, tempfile, shutil, collections

LLVM = "/usr/local/opt/llvm@19/bin"
ORC = "/Users/sorenwilkening/Desktop/Projects/CQ_lang"
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-ac2acfdde3461becc"
R = "docs/prd/phase-04-swap-route-control/inc1-records"

def resolve(label):
    if label.startswith("fixture:"):
        return os.path.join(W, label[len("fixture:"):])
    if label.startswith("wt:"):
        return os.path.join(W, R, label[len("wt:"):])
    if label.startswith("main:"):
        return os.path.join(ORC, R, label[len("main:"):])
    return None

def oracle_message(path):
    T = tempfile.mkdtemp(prefix="attr_")
    try:
        s1 = os.path.join(T, "s1.ll")
        if path.endswith(".c"):
            r = subprocess.run([os.path.join(LLVM, "clang"), "-I", os.path.join(ORC, "include"),
                                "-include", "CQ.h", "-O1", "-g", "-emit-llvm", "-S", path, "-o", s1],
                               capture_output=True, text=True)
            if r.returncode:
                return "CLANGERR"
        else:
            shutil.copy(path, s1)
        r = subprocess.run([os.path.join(ORC, "build/ir-pass/cq-opt"),
                            "-load-pass-plugin", os.path.join(ORC, "build/ir-pass/libCQPass.so"),
                            "-passes=cq-lowering", "-S", s1, "-o", os.path.join(T, "s2.ll")],
                           capture_output=True, text=True)
        if r.returncode == 0:
            return "ACCEPTS-NOW?"
        for l in r.stderr.splitlines():
            if "error:" in l:
                i = l.find("cq ")
                return l[i:].strip() if i >= 0 else l.strip()
        return "NO-ERROR-LINE"
    finally:
        shutil.rmtree(T, ignore_errors=True)

def main():
    labels = []
    for line in open(sys.argv[1]):
        f = line.rstrip("\n").split("|")
        if len(f) != 3:
            continue
        rel, o, s = f
        if o.startswith("O:") and s.startswith("S:"):
            ok = o.split(":")[2] if len(o.split(":")) > 2 else ""
            sk = s.split(":")[2] if len(s.split(":")) > 2 else ""
            if ok == "D" and sk == "A":
                labels.append(rel)
    print(f"D->A movers: {len(labels)}")
    tally = collections.Counter()
    unattr = []
    for lab in labels:
        p = resolve(lab)
        msg = oracle_message(p) if p and os.path.exists(p) else "MISSING-FILE"
        msg = msg.replace(" under quantum control", "")
        tally[msg] += 1
        if "condition predates a non-diagonal gate" not in msg and "control flow" not in msg:
            unattr.append((lab, msg))
    print("\n=== ORACLE decline string, re-measured in full ===")
    for k, v in tally.most_common():
        print(f"  {v:4d}  {k}")
    print(f"\nUNATTRIBUTABLE to Track D's two expected strings: {len(unattr)}")
    for lab, msg in unattr:
        print(f"  {lab}\n        {msg}")

if __name__ == "__main__":
    main()
