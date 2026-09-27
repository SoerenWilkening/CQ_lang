W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/'

# ---- header: declare the ONE rewrite
p = W + 'ir-pass/include/DeadValueLiveness.h'
s = open(p).read()
old = '''bool isRecordedDeadSlot(const llvm::CallBase &CB, unsigned ArgNo,
                        const TaintSet &taint);
'''
new = '''bool isRecordedDeadSlot(const llvm::CallBase &CB, unsigned ArgNo,
                        const TaintSet &taint);

// THE ONE REWRITE of a recorded-dead slot (bd vsfp round 4; Rule 14 — three sites
// used to spell it): if `U` is an argument operand of a call in a slot
// `isRecordedDeadSlot` names, and it is not already a constant, set it to the null
// constant of the CALLEE PARAMETER's type (bd f061: after retargeting, an fp slot
// is an `i32` handle — never the operand's type) and strip `range`/`nofpclass` from
// the parameter and the call site (a null may violate them — the constraint DAE
// strips too). Returns true iff it rewrote. Callers: `resolvePhantomCloneArgReads`
// (a module-level call), `buildClone` (an inner clone call reading a dead
// PARAMETER directly) and `deleteDeadCones` step 3 (an inner clone call reading a
// dead INSTRUCTION) — so a nested clone call inherits the dead slot (bd sqjq).
bool rewriteRecordedDeadSlotUse(llvm::Use &U, const TaintSet &taint);
'''
assert s.count(old) == 1
s = s.replace(old, new)
if 'class Use;' not in s:
    s = s.replace('class Instruction;\n', 'class Instruction;\nclass Use;\n', 1)
open(p, 'w').write(s)

# ---- definition + step 3 uses it
p = W + 'ir-pass/src/DeadValueLiveness.cpp'
s = open(p).read()
old = '''  return (It->second >> ArgNo) & 1;
}
'''
new = '''  return (It->second >> ArgNo) & 1;
}

bool rewriteRecordedDeadSlotUse(Use &U, const TaintSet &taint) {
  auto *CB = dyn_cast<CallBase>(U.getUser());
  if (!CB || !CB->isArgOperand(&U) || isa<Constant>(U.get()))
    return false;
  unsigned A = CB->getArgOperandNo(&U);
  if (!isRecordedDeadSlot(*CB, A, taint))
    return false;
  FunctionType *FT = CB->getFunctionType();
  Type *SlotTy = A < FT->getNumParams() ? FT->getParamType(A) : U.get()->getType();
  if (Function *Callee = CB->getCalledFunction(); Callee && A < Callee->arg_size())
    for (Attribute::AttrKind K : {Attribute::Range, Attribute::NoFPClass}) {
      Callee->removeParamAttr(A, K);
      CB->removeParamAttr(A, K);
    }
  U.set(Constant::getNullValue(SlotTy));
  return true;
}
'''
assert s.count(old) == 1
s = s.replace(old, new)
old = '''  for (Instruction *I : Del)
    for (Use &U : make_early_inc_range(I->uses())) {
      auto *CB = dyn_cast<CallBase>(U.getUser());
      if (!CB || Del.count(CB) || !CB->isArgOperand(&U))
        continue;
      unsigned A = CB->getArgOperandNo(&U);
      if (!isRecordedDeadSlot(*CB, A, taint))
        continue;  // cannot happen for a dead `I`: a live reader would make it live.
      FunctionType *FT = CB->getFunctionType();
      Type *SlotTy = A < FT->getNumParams() ? FT->getParamType(A) : I->getType();
      if (Function *Callee = CB->getCalledFunction(); Callee && A < Callee->arg_size())
        for (Attribute::AttrKind K : {Attribute::Range, Attribute::NoFPClass}) {
          Callee->removeParamAttr(A, K);
          CB->removeParamAttr(A, K);
        }
      U.set(Constant::getNullValue(SlotTy));
    }'''
new = '''  for (Instruction *I : Del)
    for (Use &U : make_early_inc_range(I->uses()))
      if (auto *CB = dyn_cast<CallBase>(U.getUser()); CB && !Del.count(CB))
        rewriteRecordedDeadSlotUse(U, taint);  // a live reader of a dead `I` can
                                                // only be such a slot.'''
assert s.count(old) == 1
s = s.replace(old, new)
open(p, 'w').write(s)

# ---- Specialization.cpp: the resolution and buildClone call the helper
p = W + 'ir-pass/src/Specialization.cpp'
s = open(p).read()
old_start = s.index('          Value *Op = CB->getArgOperand(A);\n          if (isa<Constant>(Op))\n            continue;\n          if (A < Callee->arg_size())')
old_end = s.index('          Done.push_back({&F, CB, Op});', old_start)
new = '''          Value *Op = CB->getArgOperand(A);
          // The ONE rewrite (`rewriteRecordedDeadSlotUse`): a null of the CLONE
          // PARAMETER's type, never the caller operand's (bd `f061`, bd vsfp Rule-13
          // r3A F-XA-1 — a verifier ABORT, exit 134: after `retargetSite` a tainted
          // fp slot of an fp-ABI clone is an `i32` HANDLE parameter while the
          // caller's operand is still the stock `float`/`double`/`x86_fp80` value,
          // which `lowerRotations`/`lowerOps` RAUW later — a constant never is).
          if (!rewriteRecordedDeadSlotUse(CB->getArgOperandUse(A), taint))
            continue;  // already a constant.
'''
s = s[:old_start] + new + s[old_end:]
old = '''    if (!DeadUsers.empty())
      deleteDeadCones(*Clone, DeadUsers, taint, "clone-dead-slot");
  }'''
new = '''    if (!DeadUsers.empty())
      deleteDeadCones(*Clone, DeadUsers, taint, "clone-dead-slot");
    // A dead PARAMETER passed straight into an inner clone call's dead slot (the
    // instruction case is `deleteDeadCones` step 3): the inner call inherits it.
    for (Argument &Arg : Clone->args())
      if (Arg.getArgNo() < 64 && ((DeadSlots >> Arg.getArgNo()) & 1))
        for (Use &U : make_early_inc_range(Arg.uses()))
          rewriteRecordedDeadSlotUse(U, taint);
  }'''
assert s.count(old) == 1
s = s.replace(old, new)
open(p, 'w').write(s)
print('ok')
