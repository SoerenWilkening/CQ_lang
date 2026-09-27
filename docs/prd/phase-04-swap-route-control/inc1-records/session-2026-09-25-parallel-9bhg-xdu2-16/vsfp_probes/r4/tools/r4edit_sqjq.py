W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/'

# ---- deleteDeadCones step 3: a dead value used in a RECORDED-DEAD call slot
p = W + 'ir-pass/src/DeadValueLiveness.cpp'
s = open(p).read()
old = '''  SmallPtrSet<BasicBlock *, 8> Touched(CallerTouched.begin(), CallerTouched.end());
  for (Instruction *I : Del) {
    Touched.insert(I->getParent());
    salvageDebugInfo(*I);
  }'''
new = '''  SmallPtrSet<BasicBlock *, 8> Touched(CallerTouched.begin(), CallerTouched.end());
  for (Instruction *I : Del) {
    Touched.insert(I->getParent());
    salvageDebugInfo(*I);
  }
  // A dead value may still be an operand of a LIVE call — exactly when that call's
  // slot is one the specializer RECORDED dead (the call-slot rule is the one place
  // liveness does not follow an operand). Such a slot gets the null constant of the
  // CALLEE PARAMETER's type (bd `f061`'s lesson: after retargeting, an fp slot is an
  // `i32` handle), with `range`/`nofpclass` stripped — the drop's own rewrite. Only
  // reachable after `specialize()` has written a record, i.e. inside a clone body
  // (bd `sqjq`: a nested clone call INHERITS the dead slot, r3A `n5_nested.ll`); the
  // pre-`specialize()` callers see an empty record and never take this branch.
  for (Instruction *I : Del)
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
assert s.count(old) == 1
s = s.replace(old, new)
open(p, 'w').write(s)

# ---- buildClone: delete the dead cone of every recorded-dead parameter
p = W + 'ir-pass/src/Specialization.cpp'
s = open(p).read()
old = '''  taint.SpecDeadArgMask[Clone] = deadParamMask(*Clone, taint);
'''
new = '''  const uint64_t DeadSlots = deadParamMask(*Clone, taint);
  taint.SpecDeadArgMask[Clone] = DeadSlots;
  // …AND MAKE THE RECORD EXACT FOR THE BUILT CLONE (bd `test_C_libtooling-sqjq`,
  // Rule-13 r3A F-XA-2). "Dead" means no live root reads the parameter — not that
  // no instruction does. A dead instruction still standing here (the chain of a
  // compare the clone's own flatten deleted, `t = a*3; if (t > 3) {}`; or `a+1`
  // passed into an inner clone's dead slot) would be lowered by `lowerOps` below
  // and so READ the parameter at run time — and once `resolvePhantomCloneArgReads`
  // neutralises the caller's slot to `0`, that read addresses runtime handle h0, a
  // register the caller never passed (at the wrong width when h0 is a `_Bool`).
  // Delete that dead cone now, with the same predicate that took the record: the
  // parameter is then genuinely unread, and an inner clone call inherits the dead
  // slot (its operand becomes a constant, `deleteDeadCones` step 3). Deleting
  // rather than recording later (after `lowerOps`) keeps the record on the
  // stock-opcode body, where every read is still visible as a stock use.
  if (DeadSlots) {
    SmallVector<Value *, 8> DeadUsers;
    for (Argument &Arg : Clone->args())
      if (Arg.getArgNo() < 64 && ((DeadSlots >> Arg.getArgNo()) & 1))
        for (User *U : Arg.users())
          if (isa<Instruction>(U))
            DeadUsers.push_back(U);
    if (!DeadUsers.empty())
      deleteDeadCones(*Clone, DeadUsers, taint, "clone-dead-slot");
  }
'''
assert s.count(old) == 1
s = s.replace(old, new)
open(p, 'w').write(s)
print('ok')
