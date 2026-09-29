#!/usr/bin/env python3
"""r1B Q1: the dead-argument drop at a `musttail` site under each LLVM-19 musttail rule.
For each variant V writes V.ll (musttail), VN.ll (plain `tail`), VT.ll (hand-inlined twin:
the call replaced by h2's live computation `k + 1`)."""
import os
H = os.path.dirname(os.path.abspath(__file__))
HDR = '''target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"
@K = internal global i32 7, align 4
declare i32 @cq_theta_si32(i32, double)
declare void @cq_phi(double)
declare i32 @atoi(ptr)
'''
def module(cc, pa, extra_param, extra_arg, main_extra, pre_call, dead_op, kind, twin):
    # cc: calling conv string ('' / 'tailcc ' / 'swifttailcc '); pa: attr on param 0
    w = f'''define {cc}i32 @w(i32 {pa}%m, i32 %k{extra_param}) noinline {{
  %a = and i32 %m, 7
  %q = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)
  %p = mul nsw i32 %q, 3
  %u = xor i32 %p, %q
  %c = icmp eq i32 %u, 10
  br i1 %c, label %t, label %j
t:
  call void @cq_phi(double 3.141590e+00)
  br label %j
j:
{pre_call}'''
    if twin:
        w += '''  %r = add nsw i32 %k, 1
  ret i32 %r
}
'''
    else:
        w += f'''  %r = {kind}call {cc}i32 @h2(i32 {pa}{dead_op}, i32 %k{extra_arg})
  ret i32 %r
}}
'''
    h2 = f'''define {cc}i32 @h2(i32 {pa}%x, i32 %k{extra_param.replace('%s','%s2')}) noinline {{
  %c = icmp sgt i32 %x, 3
  br i1 %c, label %t, label %j
t:
  %v = load volatile i32, ptr @K
  br label %j
j:
  %r = add nsw i32 %k, 1
  ret i32 %r
}}
'''
    main = f'''define i32 @main(i32 %argc, ptr %argv) {{
  %g = getelementptr inbounds i8, ptr %argv, i64 8
  %s = load ptr, ptr %g
  %m = call i32 @atoi(ptr %s)
{main_extra}  %r = call {cc}i32 @w(i32 {pa}%m, i32 %m{extra_arg.replace('%s','%bv')})
  %d = sub i32 %r, %m
  ret i32 %d
}}
'''
    return HDR + w + h2 + main

DIAMOND = '''  %c2 = icmp sgt i32 %k, 4
  br i1 %c2, label %a1, label %a2
a1:
  %x1 = mul i32 %p, 5
  br label %mm
a2:
  %x2 = mul i32 %p, 7
  br label %mm
mm:
  %x = phi i32 [ %x1, %a1 ], [ %x2, %a2 ]
'''
QDIAMOND = DIAMOND.replace('icmp sgt i32 %k, 4', 'icmp sgt i32 %q, 4')
V = {
  'q1_plain':    dict(cc='', pa='', extra_param='', extra_arg='', main_extra='', pre_call='', dead_op='%p'),
  'q1_inreg':    dict(cc='', pa='inreg ', extra_param='', extra_arg='', main_extra='', pre_call='', dead_op='%p'),
  'q1_tailcc':   dict(cc='tailcc ', pa='', extra_param='', extra_arg='', main_extra='', pre_call='', dead_op='%p'),
  'q1_swtailcc': dict(cc='swifttailcc ', pa='', extra_param='', extra_arg='', main_extra='', pre_call='', dead_op='%p'),
  'q1_byval':    dict(cc='', pa='', extra_param=', ptr byval(i32) %s', extra_arg=', ptr byval(i32) %s',
                      main_extra='  %bv = alloca i32\n  store i32 3, ptr %bv\n', pre_call='', dead_op='%p'),
  'q1_diamond':  dict(cc='', pa='', extra_param='', extra_arg='', main_extra='', pre_call=DIAMOND, dead_op='%x'),
  'q1_qdiamond': dict(cc='', pa='', extra_param='', extra_arg='', main_extra='', pre_call=QDIAMOND, dead_op='%x'),
}
for n, kw in V.items():
    for suf, kind, twin in (('', 'musttail ', False), ('N', 'tail ', False), ('T', '', True)):
        kw2 = dict(kw, pre_call='') if twin else kw
        open(os.path.join(H, n + suf + '.ll'), 'w').write(module(kind=kind, twin=twin, **kw2))
print('wrote', len(V) * 3)
