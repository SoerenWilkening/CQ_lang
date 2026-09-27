p = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/ir-pass/src/CQLoweringPass.cpp'
s = open(p).read()
old = '''  // Same disposition as the three above: harmless while this entry point has zero
  // callers, and a reviver must scope it to `F` or accept it as module-wide.
  auto onlyInF = [&F](auto &Calls) {'''
new = '''  // Same disposition as the three above: harmless while this entry point has zero
  // callers, and a reviver must scope it to `F` or accept it as module-wide.
  //
  // ⚠ A FIFTH AND SIXTH (bd vsfp, Rule-13 r2A F-WA-4): `dropDeadCallArguments`
  // (both slots) and `resolvePhantomCloneArgReads` rewrite call arguments in EVERY
  // function of M, and the drop's LOAD-BEARING front-end-site skip reads the
  // membership lists AFTER `onlyInF` has filtered them to F — so a reviver would
  // no longer protect another function's `cq_theta` angle in a module that DEFINES
  // the reserved symbol (`spec_accept_dropped_arg_reserved_symbol_angle.ll`'s
  // shape; the liveness ROOT side is still covered by the reserved-name root). The
  // `declineStaleTaintSet` postcondition compares only `Tainted`, which `onlyInF`
  // never filters. Same disposition: a reviver must scope all of these to `F`.
  auto onlyInF = [&F](auto &Calls) {'''
assert s.count(old) == 1
s = s.replace(old, new)
open(p, 'w').write(s)
print('ok')
