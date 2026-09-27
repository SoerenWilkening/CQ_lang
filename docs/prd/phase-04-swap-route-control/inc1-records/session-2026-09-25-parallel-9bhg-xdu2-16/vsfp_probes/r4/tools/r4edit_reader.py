p = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/ir-pass/src/Specialization.cpp'
s = open(p).read()

old_helpers = s[s.index('// A rail a CONTROL EMITTER minted (a 4.4/6.5/4.5 `%out`, a loop rail): the'):s.index('// Does the USER PROGRAM read `V`')]
new_helpers = '''bool isRuntimeCall(const CallBase &CB) {
  const Function *Callee = CB.getCalledFunction();
  if (!Callee)
    return false;
  StringRef N = Callee->getName();
  return N.starts_with("cqrt_") || N.starts_with("cq_template_");
}

// Is use `U` the DESTINATION operand of a basis copy — the one slot a control
// emitter writes while it BUILDS its own `%out` rail? `cqrt_copy_<W>(src, dst)`
// and `cqrt_copy_<W>_controlled(ctl, src, dst)` both write their LAST argument
// and read every other one (`tools/free_pairing_check.py`'s `classify()`:
// `writes=(1,)` / `writes=(2,)`). bd `test_C_libtooling-xh17` (Rule-13 r3A
// F-XA-3): round 3 skipped EVERY runtime call on an emitter rail as
// "construction", so a 4.4 `%out` read in the SOURCE slot of a later select's
// controlled copy counted as unread and a correct program declined (the oracle
// compiles it trace-identical to its twin).
bool isCopyDestination(const Use &U) {
  const auto *CB = dyn_cast<CallBase>(U.getUser());
  if (!CB || !CB->isArgOperand(&U))
    return false;
  const Function *Callee = CB->getCalledFunction();
  if (!Callee || !Callee->getName().starts_with("cqrt_copy_"))
    return false;
  return CB->getArgOperandNo(&U) + 1 == CB->arg_size();
}

'''
s = s.replace(old_helpers, new_helpers)

old = '''// A READER is: a front-end `cq_measure`, or a `cq_theta` taking `V` as arg-0 (by
// membership — the user reads it); a READ slot of a clone call; a `ret`; a
// control-emitted runtime call reading a USER value (`V` not itself an emitter's
// rail — the compare a tainted condition mints, which the twin mints too); or a
// LIVE instruction under the liveness predicate. ⚠ NOT a reader: a runtime call
// on a rail a control emitter minted (the emitter's own copies INTO its `%out` —
// telling a read from a write there needs the runtime ABI's slot semantics, so
// every such call is treated as construction; a `%out` a later control-emitted
// compare genuinely reads is therefore an over-decline, named, not constructed).'''
new = '''// A READER is: a front-end `cq_measure`, or a `cq_theta` taking `V` as arg-0 (by
// membership — the user reads it); a READ slot of a clone call; a `ret`; any
// control-emitted runtime call that READS `V` (a compare a tainted condition
// mints, or the SOURCE/control slot of a controlled copy — the twin has the same
// emitter calls, because the user wrote the same regions); or a LIVE instruction
// under the liveness predicate. ⚠ NOT a reader: the DESTINATION slot of a basis
// copy (`isCopyDestination`), which is how an emitter builds its own `%out`. That
// slot-exact rule replaced round 3's "every runtime call on an emitter rail is
// construction", which declined a `%out` read by a later select's copy (bd
// `xh17`).'''
assert s.count(old) == 1
s = s.replace(old, new)

old = '''bool userProgramReads(const Value *V, const FunctionLiveness &L,
                      const TaintSet &taint) {
  const bool EmitterRail = isControlEmittedRail(V, taint);
  for (const Use &U : V->uses()) {'''
new = '''bool userProgramReads(const Value *V, const FunctionLiveness &L,
                      const TaintSet &taint) {
  for (const Use &U : V->uses()) {'''
assert s.count(old) == 1
s = s.replace(old, new)
old = '''      if (isRuntimeCall(*CB)) {
        if (EmitterRail)
          continue;  // the emitter's own traffic on its rail: construction.
        return true;
      }'''
new = '''      if (isRuntimeCall(*CB)) {
        if (isCopyDestination(U))
          continue;  // an emitter building its own rail: construction.
        return true;  // any other runtime slot reads `V`.
      }'''
assert s.count(old) == 1
s = s.replace(old, new)
open(p, 'w').write(s)
print('ok')
