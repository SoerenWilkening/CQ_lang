import subprocess
W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8"
title = ("PRE-EXISTING twin divergence: the volatile-const folds replace a load by a constant but do not "
         "constant-fold its users, so `K - 7` survives as an instruction and a callee the -O1 twin sees as "
         "ignoring its parameter still reads it (r2B g12A/B)")
desc = """Found by the bd vsfp round-3 battery (every Rule-13 r2B probe against its twin); r2B recorded the rows (probes/results/adversarial_g1-g13.txt) without discussing them.

PROBE (r2B g12A/g12B, 2-TU): lib `static volatile const int K = 7; int h(int a, int k) { int r = k + 1; if (a > 3) r += K - 7; return r; }`; caller A passes a 4.4 bool-select (`p = b ? 9 : 4`), caller B a template rail (`p = q * 3`). Twin gTA/gTB: `t = m + 1` (K - 7 == 0, -O1 folds the arm away).

MECHANISM (argued from the IR, not bisected): foldVolatileConstGlobalLoads RAUWs the volatile load with the initializer constant 7 but never constant-folds its users, so `%x = sub nsw i32 7, 7` (or the add of it) stays an INSTRUCTION; the arm is not empty, the merge phi keeps `a` live, the clone genuinely reads `a` (a select on `a > 3`), and the program is lifted spec-QUANTUM where the twin never computes `p`'s read.

MEASURED, identical on ORACLE aee8f4f8, round 1 (5e56060b), round 2 (0a485382) and round 3: g12A TRACE-DIFF vs gTA (0 dirty template rails, extra alloc rails left allocated), g12B TRACE-DIFF vs gTB with 1 dirty template rail and a lyyf-(B) warning. PRE-EXISTING; not introduced or widened by bd vsfp (the same stream on all four binaries).

FIX DIRECTION: after the RAUW, constant-fold the users (ConstantFoldInstruction / simplifyInstruction to a fixpoint, deleting what dies) before the arm fold asks whether the arm is empty — the same for foldVolatileConstAllocaLoads. Owes red-green (g12A/B) and a Rule-13 look (it widens what the arm fold removes)."""
r = subprocess.run(["bd", "create", title, "-t", "bug", "-p", "2", "-d", desc,
                    "--deps", "discovered-from:test_C_libtooling-vsfp"], cwd=W, capture_output=True, text=True)
print(r.returncode, (r.stdout + r.stderr).strip()[-400:])
