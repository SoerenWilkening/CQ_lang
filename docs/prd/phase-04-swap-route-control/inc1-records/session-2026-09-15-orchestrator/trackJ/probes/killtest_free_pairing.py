"""Kill-test: mutate the CHECKER, confirm free_pairing_check_test goes RED.
A rule nobody has deleted is a rule nobody has validated."""
import os, shutil, subprocess, sys, tempfile
R='/Users/sorenwilkening/Desktop/CQ_J'
SRC=open(R+'/tools/free_pairing_check.py').read()

KILLS = [
 ("K1 delete the T1a/T1b undef refusal",
  ('        und = [a for a in fwd_args if carries_undef(a)]',
   '        und = []  # KILLED')),
 ("K2 delete the adjoint_matches undef refusal",
  ('        if a.sym == b.sym and len(a.args) == len(b.args) and \\\n                any(carries_undef(x) for x in a.args + b.args):',
   '        if False:')),
 ("K3 census counts every function (pre-rixk)",
  ('        if fn.name not in live:\n            continue',
   '        if False:\n            continue')),
 ("K4 census counts only cqrt_alloc (pre-19vy/1739h1)",
  ('            else:                              # template / qram_load / tape',
   '            elif False:                        # KILLED')),
 ("K5 drop the tape-kept-by-design exclusion",
  ('                if _TAPE_MINT.fullmatch(sym):\n                    continue',
   '                if False:\n                    continue')),
 ("K6a a measured template rail counts as dirty",
  ('                if not (res in freed or res in uncd or res in measured\n                        or res in returned or res in escaped):',
   '                if not (res in freed or res in uncd\n                        or res in returned or res in escaped):')),
 ("K6b a reversed template rail counts as dirty",
  ('                if not (res in freed or res in uncd or res in measured\n                        or res in returned or res in escaped):',
   '                if not (res in freed or res in measured\n                        or res in returned or res in escaped):')),
 ("K6c a returned template rail counts as dirty",
  ('                if not (res in freed or res in uncd or res in measured\n                        or res in returned or res in escaped):',
   '                if not (res in freed or res in uncd or res in measured\n                        or res in escaped):')),
 ("K6d a freed template rail counts as dirty",
  ('                if not (res in freed or res in uncd or res in measured\n                        or res in returned or res in escaped):',
   '                if not (res in uncd or res in measured\n                        or res in returned or res in escaped):')),
 ("K7 drop the indirect-call fallback",
  ('    if INDIRECT_CALL_RE.search(text):',
   '    if False:')),
 ("K8 drop address-taken roots",
  ('    roots = {"main"} | address_taken(text, defined)',
   '    roots = {"main"}')),
 ("K6e an escaped template rail counts as dirty",
  ('                if not (res in freed or res in uncd or res in measured\n                        or res in returned or res in escaped):',
   '                if not (res in freed or res in uncd or res in measured\n                        or res in returned):')),
 ("K9 no-main module narrowed by defined-called instead of counted whole",
  ('    if "main" not in defined:',
   '    if False:')),
 ("K10 census reports the alloc half only (pre-19vy census line)",
  ('        tmpl_total += cen.tmpl_minted',
   '        tmpl_total += 0')),
]

def run(tmp):
    r=subprocess.run([sys.executable, tmp+'/free_pairing_check_test.py'],
                     capture_output=True, text=True)
    return r.returncode, (r.stdout+r.stderr)

base=tempfile.mkdtemp()
for f in ('free_pairing_check.py','free_pairing_check_test.py'):
    shutil.copy(R+'/tools/'+f, base+'/'+f)
rc,out = run(base)
print(f"BASELINE (unmutated copy): rc={rc}  {out.strip().splitlines()[0][:110]}")
assert rc==0, "baseline must be green"

fails=[]
for name,(old,new) in KILLS:
    if SRC.count(old)!=1:
        print(f"  ??  {name}: anchor not unique ({SRC.count(old)}) — kill test INVALID")
        fails.append(name); continue
    tmp=tempfile.mkdtemp()
    open(tmp+'/free_pairing_check.py','w').write(SRC.replace(old,new,1))
    shutil.copy(R+'/tools/free_pairing_check_test.py', tmp+'/free_pairing_check_test.py')
    rc,out = run(tmp)
    line=[l for l in out.splitlines() if 'FAIL' in l]
    print(f"  {'RED ' if rc else 'GREEN'}  {name}: rc={rc}, {len(line)} failure line(s)")
    if line: print(f"          first: {line[0][:150]}")
    if rc==0:
        fails.append(name)
print("\nKILL TESTS THAT DID NOT GO RED:", fails if fails else "none")
