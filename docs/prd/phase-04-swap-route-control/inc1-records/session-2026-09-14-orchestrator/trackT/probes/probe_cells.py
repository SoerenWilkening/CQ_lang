import os, subprocess, sys, tempfile
sys.path.insert(0, "/Users/sorenwilkening/Desktop/CQ_twinbool/tools")
os.chdir("/Users/sorenwilkening/Desktop/CQ_twinbool")
import loop_twin_matrix as M
LLVM = "/usr/local/opt/llvm@19/bin"
B = "/Users/sorenwilkening/Desktop/CQ_twinbool/build"

class Cfg: pass
cfg = Cfg()
cfg.clang = LLVM + "/clang"
cfg.opt = B + "/ir-pass/cq-opt"
cfg.plugin = B + "/ir-pass/libCQPass.so"
cfg.include = "/Users/sorenwilkening/Desktop/CQ_twinbool/include"
cfg.runtime = B + "/runtime/libcq_runtime.a"
cfg.templates = B + "/runtime/libcq_templates.a"
cfg.ld = B + "/tests/e2e/cq_link.sh"
cfg.phi_surface = "void"

def measure(label, body, second="none", bcond=True):
    r, u = M._wrap(body, second, M.RECORD["none"], "void", bcond=bcond)
    w = tempfile.mkdtemp(prefix="probe_")
    try:
        R = M.build_side(cfg, w, "r", r)
        U = M.build_side(cfg, w, "u", u)
    finally:
        pass
    v, rep = M.verdict(label, R, U)
    print("=== %s" % label)
    print("  verdict: %s" % v.replace("\t", " | "))
    if R.trace:
        print("  ROLLED trace (%d lines):" % len(R.trace.splitlines()))
        for l in R.trace.splitlines(): print("     " + l)
    if U.trace and U.trace != R.trace:
        print("  UNROLLED trace (%d lines):" % len(U.trace.splitlines()))
        for l in U.trace.splitlines(): print("     " + l)
    if R.error: print("  rolled harness error: " + R.error[:400])
    if U.error: print("  unrolled harness error: " + U.error[:400])
    print("  workdir", w)
    return v

# (0) the SHIPPED bare-rail phase cell — is it actually emitting anything?
measure("bphi_binv", "        if (b) { a = cq_phi(a, M_PI); }\n")
# (1..4) the compound-condition spellings
for lbl, txt in (("and_opaque_shortcircuit", "        if (b && a == off) { a = cq_phi(a, M_PI); }\n"),
                 ("and_literal_shortcircuit", "        if (b && a == 5) { a = cq_phi(a, M_PI); }\n"),
                 ("and_opaque_bitwise", "        if (b & (a == off)) { a = cq_phi(a, M_PI); }\n"),
                 ("and_literal_bitwise", "        if (b & (a == 5)) { a = cq_phi(a, M_PI); }\n")):
    measure(lbl, txt)
