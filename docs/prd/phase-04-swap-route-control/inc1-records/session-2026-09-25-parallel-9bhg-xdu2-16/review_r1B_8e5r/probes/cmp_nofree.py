import json, sys
o=json.load(open(sys.argv[1])); s=json.load(open(sys.argv[2]))
mods=sorted({k.split('|')[1] for k in o})
same=0; diff=[]
for m in mods:
    a=o['ORA|%s|nofree'%m][0]; b=s['SUB|%s|sys'%m][0]
    if (a[0],a[1])==(b[0],b[1]): same+=1
    else: diff.append((m.split('/')[-1],a[0],a[1],b[0],b[1]))
print(f"frozen oracle under rb8 'nofree' (independent allocator) vs subject cq-opt 8ab548b7 (system allocator, 1st of 3 runs): denominator {len(mods)}; identical (rc,stdout) {same}; different {len(diff)}")
for d in diff: print('  ',*d)
