#!/usr/bin/env python3
# r1B_vsfp PROTOTYPE (evidence only, never to be committed): qjoc's candidate fix
# (delete the erased volatile store's dead non-call value cone) + run the erasure
# BEFORE bd vsfp's dropDeadCallArguments, so the drop sees the post-fenv callee.
import sys, re, pathlib
wt = pathlib.Path(sys.argv[1])
q = wt / "ir-pass/src/QramLowering.cpp"
s = q.read_text()
s = s.replace('#include "llvm/Transforms/Utils/PromoteMemToReg.h"',
              '#include "llvm/Transforms/Utils/PromoteMemToReg.h"\n#include "llvm/Transforms/Utils/Local.h"  // r1B proto', 1)
old = """      for (StoreInst *SI : Stores)
        SI->eraseFromParent();
      for (IntrinsicInst *II : Lifetimes)
        II->eraseFromParent();
      A->eraseFromParent();
      Changed = true;
    }
  }
  return Changed;
}
"""
new = """      SmallVector<Instruction *, 4> ProtoVals;  // r1B proto
      for (StoreInst *SI : Stores)
        if (auto *VI = dyn_cast<Instruction>(SI->getValueOperand()))
          ProtoVals.push_back(VI);
      for (StoreInst *SI : Stores)
        SI->eraseFromParent();
      for (IntrinsicInst *II : Lifetimes)
        II->eraseFromParent();
      A->eraseFromParent();
      // r1B proto: the stored value's now-dead NON-CALL cone dies with the store.
      SmallVector<Instruction *, 16> Dead;
      auto del = [](Instruction *I) { return I->use_empty() && !isa<CallBase>(I) && isInstructionTriviallyDead(I); };
      for (Instruction *VI : ProtoVals) if (del(VI)) Dead.push_back(VI);
      while (!Dead.empty()) {
        Instruction *I = Dead.pop_back_val();
        for (Use &OpU : I->operands()) {
          Value *OpV = OpU.get(); OpU.set(nullptr);
          if (auto *OpI = dyn_cast_or_null<Instruction>(OpV)) if (del(OpI)) Dead.push_back(OpI);
        }
        I->eraseFromParent();
      }
      Changed = true;
    }
  }
  return Changed;
}
"""
assert s.count(old) == 1, s.count(old)
s = s.replace(old, new, 1)
q.write_text(s)
c = wt / "ir-pass/src/CQLoweringPass.cpp"
t = c.read_text()
old1 = "  if (dropDeadCallArguments(M, taint))\n    taint = propagate(M, wd);\n"
assert t.count(old1) == 1, t.count(old1)
t = t.replace(old1, "  eraseDeadVolatileScalarStores(M, taint);  // r1B proto: fenv erasure BEFORE the drop\n" + old1, 1)
c.write_text(t)
print("patched")
