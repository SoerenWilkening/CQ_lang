import os, sys, tempfile
sys.path.insert(0, "/Users/sorenwilkening/Desktop/CQ_twinbool/tools")
os.chdir("/Users/sorenwilkening/Desktop/CQ_twinbool")
import loop_twin_matrix as M
LLVM = "/usr/local/opt/llvm@19/bin"; B = "/Users/sorenwilkening/Desktop/CQ_twinbool/build"
class Cfg: pass
cfg = Cfg(); cfg.clang = LLVM+"/clang"; cfg.opt = B+"/ir-pass/cq-opt"
cfg.plugin = B+"/ir-pass/libCQPass.so"; cfg.include = "include"
cfg.runtime = B+"/runtime/libcq_runtime.a"; cfg.templates = B+"/runtime/libcq_templates.a"
cfg.ld = B+"/tests/e2e/cq_link.sh"; cfg.phi_surface = "void"
names = {M.cell_name(c): c for c in M.cells_of_matrix()}
for n in ("m_none_bry_none_none_binv", "m_none_bprep_none_none_binv"):
    r, u = M.sources(*names[n], surface="void")
    w = tempfile.mkdtemp(prefix="wx_")
    R = M.build_side(cfg, w, "r", r); U = M.build_side(cfg, w, "u", u)
    print("=== %s" % n)
    print("  ROLLED  : exit=%s  %s" % (R.exit, R.diag))
    print("  UNROLLED: exit=%s  %s" % (U.exit, U.diag))
    for l in (U.trace or "").splitlines(): print("     " + l)
