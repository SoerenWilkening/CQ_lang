W = '/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8/'
RUL = 'owner ruling 2026-09-26, bd memory `owner-ruling-volatile-unreachable-object-2026-09-26`'

p = W + 'ir-pass/include/QramLowering.h'
s = open(p).read()
old = '''// loaded constant from the initializer. This is the openlibm anti-const-fold
// idiom (`static volatile double twom1000`, `*(volatile double *)&atanlo[3]`):
// the volatile qualifier exists purely to defeat classical FP folding /
// raise-inexact elision, and fenv is out of scope project-wide. The proof makes
// load == initializer on every execution, so the fold is exact; anything short of
// the proof (external linkage, any store, any escaping user, atomic, a type the
// initializer cannot produce at that offset) is left untouched — the existing
// loud declines own it.'''
new = '''// loaded constant from the initializer. This is the openlibm anti-const-fold
// idiom (`static volatile double twom1000`, `*(volatile double *)&atanlo[3]`).
// GROUND (''' + RUL + '''):
// a volatile access to an object NOTHING OUTSIDE THE PROGRAM CAN REACH is not
// observable in CQ's model — internal linkage (or function-local), never written,
// address never escaping, no atomic access, and NOT in a named section or at an
// absolute/fixed address (that is how MMIO is declared). Every conjunct is a gate
// here; the section / absolute-address one was MISSING until bd vsfp round 4 (a
// `static volatile … __attribute__((section("…")))` global folded like any other,
// `lowering_reject_volatile_global_section.ll`). ⚠ The sentence that stood here —
// "the volatile qualifier exists purely to defeat classical FP folding …, and fenv
// is out of scope project-wide" — was an agent-authored over-generalisation (L7):
// the 2026-08-10 fenv ruling spoke of FUNCTION-LOCAL objects, and "why the author
// wrote `volatile`" is not a licence. The proof makes load == initializer on every
// execution, so the fold is exact; anything short of the proof (external linkage,
// any store, any escaping user, atomic, a named section or absolute symbol, a type
// the initializer cannot produce at that offset) is left untouched — the existing
// loud declines own it.'''
assert s.count(old) == 1
s = s.replace(old, new)
open(p, 'w').write(s)

p = W + 'ir-pass/src/QramLowering.cpp'
s = open(p).read()
old = '''  for (GlobalVariable &G : M.globals()) {
    if (!G.hasLocalLinkage() || !G.hasDefinitiveInitializer())
      continue;
    // Never-stored / address-never-escaping proof: every transitive user'''
new = '''  for (GlobalVariable &G : M.globals()) {
    if (!G.hasLocalLinkage() || !G.hasDefinitiveInitializer())
      continue;
    // Not in a NAMED SECTION and not at an ABSOLUTE / fixed address: that is how
    // MMIO is declared, and the owner's reachability ruling (2026-09-26, bd memory
    // `owner-ruling-volatile-unreachable-object-2026-09-26`) requires both. A
    // pointer built from an integer (`*(volatile int *)0x40000000`) never strips to
    // a `GlobalVariable`, so it never reaches this loop.
    if (G.hasSection() || G.isAbsoluteSymbolRef() ||
        G.getMetadata(LLVMContext::MD_absolute_symbol))
      continue;
    // Never-stored / address-never-escaping proof: every transitive user'''
assert s.count(old) == 1
s = s.replace(old, new)
open(p, 'w').write(s)

for f, old, new in [
    ('ir-pass/test/lowering_qram_volatile_fold.ll',
     '; const-folding (fenv is out of scope project-wide). The curation folds each',
     '; const-folding. GROUND: the owner\'s reachability ruling (2026-09-26 — a volatile\n'
     '; access to an internal, never-written, non-escaping, non-section object is not\n'
     '; observable), NOT "fenv is out of scope project-wide", which was an agent-authored\n'
     '; over-generalisation (L7, bd vsfp round 4). The curation folds each'),
    ('ir-pass/test/lowering_volatile_local_fold.ll',
     '; defeat classical FP const-folding (fenv is out of scope project-wide) —',
     '; defeat classical FP const-folding (the ground is the owner\'s reachability ruling\n'
     '; of 2026-09-26, not "fenv is out of scope project-wide" — L7, bd vsfp round 4) —'),
]:
    q = W + f
    t = open(q).read()
    assert t.count(old) == 1, f
    t = t.replace(old, new)
    open(q, 'w').write(t)
print('ok')
