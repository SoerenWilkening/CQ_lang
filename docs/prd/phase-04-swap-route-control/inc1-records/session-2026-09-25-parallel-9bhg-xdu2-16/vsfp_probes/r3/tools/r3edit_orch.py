import pathlib, re
p = pathlib.Path('/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/ir-pass/src/CQLoweringPass.cpp')
s = p.read_text()

# ---- run(): the three fenv calls
old = '''  // loads are classical, so taint is unaffected (the bitcast-fold precedent —
  // no re-propagate needed).
  foldVolatileConstGlobalLoads(M);'''
new = '''  // loads are classical. ⚠ But since bd vsfp round 3 (bd stl3) the stage also
  // folds an arm it EMPTIES (`deleteDeadCones`), which can turn a two-entry φ
  // under a quantum condition into a NEW tainted `select` — so it re-propagates
  // when it changed anything, like every other pre-pass in this window (bd otam;
  // the old "no re-propagate needed" was the bug, see QramLowering.h).
  if (foldVolatileConstGlobalLoads(M, taint))
    taint = propagate(M, wd);'''
assert s.count(old) == 1, 'g1'
s = s.replace(old, new)
old = '''  // loads only; the fold erases the loads, store, lifetime markers, and
  // alloca. Folded values are classical — same no-re-propagate rationale.
  foldVolatileConstAllocaLoads(M, taint);'''
new = '''  // loads only; the fold erases the loads, store, lifetime markers, and
  // alloca. Folded values are classical, but the arm fold behind it is not taint-
  // neutral (bd otam, r2A `stale4`: a `(void)k` arm emptied under a quantum
  // condition became a tainted `select` nobody re-propagated, and a user
  // `cq_measure` vanished) — so: re-propagate when it changed anything.
  if (foldVolatileConstAllocaLoads(M, taint))
    taint = propagate(M, wd);'''
assert s.count(old) == 1, 'a1'
s = s.replace(old, new)
old = '''  // for a dead 4.4 select (a silent which-path rail) and a dead template product
  // whose source is later rotated (a dirty rail); see QramLowering.h.
  eraseDeadVolatileScalarStores(M, taint);'''
new = '''  // for a dead 4.4 select (a silent which-path rail) and a dead template product
  // whose source is later rotated (a dirty rail); see QramLowering.h. The same
  // cone deletion can fold an emptied arm into a tainted `select` (bd otam, r2A
  // `stale3a/b/c`, `loop2`), so: re-propagate when it changed anything.
  if (eraseDeadVolatileScalarStores(M, taint))
    taint = propagate(M, wd);'''
assert s.count(old) == 2, 'e1'
s = s.replace(old, new, 1)

# ---- runOnFunction(): same three calls
old = '''  foldVolatileConstGlobalLoads(M);
'''
idx = s.index(old)
assert s.count(old) == 1, 'g2'
new = '''  if (foldVolatileConstGlobalLoads(M, taint)) {  // bd otam/stl3 — see run().
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.PhaseCalls);
    onlyInF(taint.MeasureCalls);
  }
'''
s = s.replace(old, new)
old = '''  foldVolatileConstAllocaLoads(M, taint);
'''
assert s.count(old) == 1, 'a2'
new = '''  if (foldVolatileConstAllocaLoads(M, taint)) {  // bd otam — see run().
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.PhaseCalls);
    onlyInF(taint.MeasureCalls);
  }
'''
s = s.replace(old, new)
old = '''  eraseDeadVolatileScalarStores(M, taint);
'''
assert s.count(old) == 1, 'e2'  # run()'s call was rewritten above
new = '''  if (eraseDeadVolatileScalarStores(M, taint)) {  // bd otam — see run().
    taint = propagate(M, wd);
    onlyInF(taint.ThetaCalls);
    onlyInF(taint.PhiCalls);
    onlyInF(taint.PhaseCalls);
    onlyInF(taint.MeasureCalls);
  }
'''
s = s.replace(old, new)

# ---- the freshness postcondition before detectSpecializations, both entry points
old = '''  SpecPlan plan6;
  detectSpecializations(M, taint, wd, plan6);'''
assert s.count(old) == 2, 'd'
parts = s.split(old)
run_new = '''  // bd `test_C_libtooling-otam` (bd vsfp round 3) — THE PRE-PASS WINDOW'S
  // TAINT-FRESHNESS POSTCONDITION. Every stage above that changes the IR
  // re-propagates itself; this re-derives the set once more and declines LOUDLY
  // if it differs, so the NEXT stage that grows taint and forgets (the three
  // volatile folds did, round 2) is a decline, not a silent miscompile. See
  // TaintPropagation.h for what it can and cannot see.
  if (declineStaleTaintSet(M, wd, taint))
    return PreservedAnalyses::none();
  SpecPlan plan6;
  detectSpecializations(M, taint, wd, plan6);'''
fn_new = '''  if (declineStaleTaintSet(M, wd, taint))  // bd otam — see run().
    return false;
  SpecPlan plan6;
  detectSpecializations(M, taint, wd, plan6);'''
s = parts[0] + run_new + parts[1] + fn_new + parts[2]

# ---- slot A comment (F-WA-2 #3)
i = s.index('  // bd `test_C_libtooling-vsfp` (P1) / bd `hgwx` — THE DEAD CALL-ARGUMENT DROP')
j = s.index('  if (dropDeadCallArguments(M, taint))', i)
blk = s[i:j]
m = re.search(r'SHRINKS the taint set and grows nothing[^\n]*\n(//[^\n]*\n)*?', blk)
print('slotA-match', bool(m))
p.write_text(s)
print(blk[-1600:])
