import pathlib
W = pathlib.Path('/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8')

p = W / 'ir-pass/src/QramLowering.cpp'
s = p.read_text()
old = '''bool foldVolatileConstGlobalLoads(Module &M) {
  bool Changed = false;
  const DataLayout &DL = M.getDataLayout();'''
new = '''bool foldVolatileConstGlobalLoads(Module &M, const TaintSet &taint) {
  bool Changed = false;
  const DataLayout &DL = M.getDataLayout();
  // bd stl3 (bd vsfp round 3, Rule-13 r2B F-WB-2): the blocks this fold empties,
  // per function, for the SAME empty-arm fold its three siblings run — `if (a >
  // 3) (void)K;` otherwise leaves an empty diamond (or a two-entry φ of EQUAL
  // incomings, `(a > 3) ? K : 0` with `K == 0`) that keeps `a` branch-live, so the
  // dead-argument drop's slot B cannot predict the slot the clone's own flatten
  // then kills. After the global loop: the fold changes the CFG.
  MapVector<Function *, SmallVector<BasicBlock *, 4>> Emptied;'''
assert s.count(old) == 1
s = s.replace(old, new)
old = '''      if (!C)
        continue;  // offset/type the initializer cannot produce — leave.
      LI->replaceAllUsesWith(C);
      LI->eraseFromParent();
      Changed = true;
    }
  }
  return Changed;
}'''
new = '''      if (!C)
        continue;  // offset/type the initializer cannot produce — leave.
      Emptied[LI->getFunction()].push_back(LI->getParent());
      LI->replaceAllUsesWith(C);
      LI->eraseFromParent();
      Changed = true;
    }
  }
  // ⚠ The fold may create a TAINTED `select` (a two-entry φ under a quantum
  // condition) — the caller owes a re-`propagate` whenever this returns true
  // (bd otam; `deleteDeadCones`' contract).
  for (auto &[F, Blocks] : Emptied)
    deleteDeadCones(*F, {}, taint, "volatile-globalfold", Blocks);
  return Changed;
}'''
assert s.count(old) == 1
s = s.replace(old, new)
if '#include "llvm/ADT/MapVector.h"' not in s:
    s = s.replace('#include "llvm/ADT/SmallPtrSet.h"', '#include "llvm/ADT/MapVector.h"\n#include "llvm/ADT/SmallPtrSet.h"', 1)
p.write_text(s)

h = W / 'ir-pass/include/QramLowering.h'
t = h.read_text()
old = '''// loud declines own it. Folded loads are CLASSICAL (constant address), so taint
// is unaffected and no re-propagate is needed (the foldIdentityBitcasts
// precedent). Returns true if anything folded.
bool foldVolatileConstGlobalLoads(llvm::Module &M);'''
new = '''// loud declines own it. Folded loads are CLASSICAL (constant address). ⚠ But the
// stage does not leave taint unaffected (bd vsfp round 3, bd otam / stl3): an arm
// the fold EMPTIES is folded by `deleteDeadCones` (the empty-arm fold its three
// siblings run), and a two-entry φ under a QUANTUM condition becomes
// `select %taintedCond, …` — a NEW tainted value. The caller re-`propagate`s
// whenever this returns true (both entry points). Returns true if anything
// folded.
bool foldVolatileConstGlobalLoads(llvm::Module &M, const TaintSet &taint);'''
assert t.count(old) == 1
t = t.replace(old, new)
old = '''// type-punned or offset view is off-idiom and forfeits). The single-Constant
// store gate structurally excludes tainted (shadow-QRAM) allocas; folded
// values are CLASSICAL, so taint is unaffected and no re-propagate is needed
// (the foldVolatileConstGlobalLoads precedent). Anything short of the proof is
// left untouched for the existing loud declines. Returns true if anything
// folded.'''
new = '''// type-punned or offset view is off-idiom and forfeits). The single-Constant
// store gate structurally excludes tainted (shadow-QRAM) allocas; folded
// values are CLASSICAL. ⚠ FALSE SINCE bd vsfp ROUND 2, and the source of bd otam
// (Rule-13 r2A F-WA-1/F-WA-2): this used to read "taint is unaffected and no
// re-propagate is needed". Round 2 gave the stage `deleteDeadCones(…, Emptied)`,
// whose empty-arm fold turns a two-entry φ under a QUANTUM condition into
// `select %taintedCond, …` — a NEW tainted value — and both call sites ignored
// the return. A classical consumer then computed with a `%out` rail handle and a
// user `cq_measure` vanished (r2A `stale4`). The caller now re-`propagate`s
// whenever this returns true. Anything short of the proof is left untouched for
// the existing loud declines. Returns true if anything folded.'''
assert t.count(old) == 1
t = t.replace(old, new)
h.write_text(t)
print('ok')
