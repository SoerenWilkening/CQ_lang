from pathlib import Path
import collections,json,re
before=json.load(open('/tmp/p3kd78-census-before.json'))
after=json.load(open('tools/library_coverage/runtime_census.json'))
old={(r['cell'],r['mix']):r for r in before['results']}
new={(r['cell'],r['mix']):r for r in after['results']}
changes=[]
for key,r in new.items():
 if r['status']!=old[key]['status']:
  changes.append({'cell':key[0],'mix':key[1],'before':old[key]['status'],'after':r['status']})
print('score',after['score'])
print('status',dict(collections.Counter(r['status'] for r in after['results'])))
print('changes',json.dumps(changes,indent=2))
print('free_check_failures',[(r['cell'],r['mix'],r.get('free_check_exit'),r.get('free_check')) for r in after['results'] if r['status']=='COMPILES' and r.get('free_check_exit')!=0])
bydiag=collections.defaultdict(list)
for r in after['results']:
 if r['status']=='COMPILES':continue
 diag=next((s.strip() for s in r['diagnostic'].splitlines() if 'error' in s),r['diagnostic'])
 diag=re.sub(r'^.*?error: ','',diag)
 bydiag[diag].append(r['cell']+' '+r['mix'])
for diag,cells in sorted(bydiag.items(),key=lambda x:-len(x[1])):
 print('BLOCKER',len(cells),diag,'; '.join(cells))
# Inspect saved successful IR without any lowering rerun. Attribute each clone's
# borrowed FP parameters by its original function signature. Check direct copies
# of those parameters and every free of a parameter in all clone bodies/twins.
fp={'half':'f16','float':'f32','double':'f64','x86_fp80':'f80','fp128':'f128'}
issues=[]; checked=collections.Counter();seen_cells=set();copy_records=[]
bundle=Path('/tmp/p3kd78-libm-bundle.ll').read_text()
original_defs={m.group(1):(m.group(2),m.group(3)) for m in re.finditer(r'^define[^@\n]*@([\w.$]+)\(([^\n]*)\)[^\n]*\{\n(.*?)^\}',bundle,re.M|re.S)}
for path in sorted(Path('/tmp/p3kd78-census-evidence').glob('*/low.ll')):
 ir=path.read_text()
 defs={m.group(1):(m.group(2),m.group(3)) for m in re.finditer(r'^define[^@\n]*@([\w.$]+)\(([^\n]*)\)[^\n]*\{\n(.*?)^\}',ir,re.M|re.S)}
 for name,(params,body) in defs.items():
  if not name.startswith('__cq_q_'):continue
  args=re.findall(r'(half|float|double|x86_fp80|fp128|i\d+|ptr)\b[^,]*?([%][\w.$]+)(?=,|$)',params)
  argnames={n for _,n in args}
  for m in re.finditer(r'call void @cqrt_free\(i32 ([%][\w.$]+)\)',body):
   checked['clone_frees']+=1
   if m.group(1) in argnames:issues.append((str(path),name,'parameter free',m.group(0)))
  checked['clone_bodies_and_twins']+=1
  match=re.fullmatch(r'__cq_q_(.*)_([01]+)(_unc)?',name)
  if not match:continue
  originals={**original_defs,**defs}
  if match.group(1) not in originals:continue
  orig_params=originals[match.group(1)][0]
  orig_args=re.findall(r'(half|float|double|x86_fp80|fp128|i\d+|ptr)\b[^,]*?([%][\w.$]+)(?=,|$)',orig_params)
  # Twin prepends its escaping out parameter.
  clone_args=args[1:] if match.group(3) else args
  if len(clone_args)!=len(orig_args):
   issues.append((str(path),name,'cannot attribute signature',params,orig_params));continue
  expected={newname:fp[oldtype] for (oldtype,_),(newtype,newname) in zip(orig_args,clone_args) if oldtype in fp and newtype=='i32'}
  if expected:seen_cells.add(path.parent.name)
  checked['borrowed_fp_parameters']+=len(expected)
  for m in re.finditer(r'call void @cqrt_copy_(\w+?)(_controlled)?\(([^\n]*)\)',body):
   operands=re.findall(r'i32 ([%][\w.$]+)',m.group(3))
   if len(operands)<2:continue
   source=operands[1] if m.group(2) else operands[0]
   if source in expected:
    checked['copies_from_borrowed_fp']+=1
    row=(path.parent.name,name,expected[source],m.group(1),m.group(0))
    copy_records.append(row)
    if m.group(1)!=expected[source]:issues.append((str(path),name,'copy width',row))
print('WIDTH_PARAM_AUDIT',dict(checked),'cells',len(seen_cells),'issues',issues)
result={'commit':after['metadata']['cq_commit'],'score':after['score'],'status_counts':dict(collections.Counter(r['status'] for r in after['results'])),'changes':changes,'blockers':[{'diagnostic':d,'probes':p} for d,p in sorted(bydiag.items(),key=lambda x:-len(x[1]))],'width_param_audit':dict(checked),'fp_probe_count':len(seen_cells),'issues':issues,'copy_records':copy_records}
Path('/tmp/p3kd78-census-audit.json').write_text(json.dumps(result,indent=2)+'\n')
