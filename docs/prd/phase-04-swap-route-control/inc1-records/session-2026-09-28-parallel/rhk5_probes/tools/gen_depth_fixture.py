#!/usr/bin/env python3
"""gen_depth_fixture.py N OUT — hand IR: the d4 caller (chain p = 3q, u = p ^ q, clone
call h(m, q) inside the discharge window, kickback on u, Ry on q) whose callee h
nests N `noinline` helpers: h(a,k) = g1(k) + 1, g_i(k) = g_{i+1}(k) + 1, g_N(k) = k*5.
The specializer builds one clone per level; `cloneCallPreservesArg` must walk
1 + N (function, formal) pairs to prove the outer call read-only."""
import sys

N = int(sys.argv[1])
out = sys.argv[2]
L = ['declare i32 @cq_theta_si32(i32, double)', 'declare i32 @cq_measure_si32(i32)',
     'declare void @cq_phi(double)', '',
     'define i32 @slice(i32 %m) {', 'entry:', '  %a = and i32 %m, 7',
     '  %q = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)',
     '  %p = mul nsw i32 %q, 3', '  %u = xor i32 %p, %q',
     '  %s = call i32 @h(i32 %m, i32 %q)', '  %c = icmp eq i32 %u, 10',
     '  br i1 %c, label %arm, label %merge', '', 'arm:',
     '  call void @cq_phi(double 3.141590e+00)', '  br label %merge', '', 'merge:',
     '  %ms = call i32 @cq_measure_si32(i32 %s)',
     '  %q2 = call i32 @cq_theta_si32(i32 %q, double 0x3FE6666666666666)',
     '  %mq = call i32 @cq_measure_si32(i32 %q2)', '  %r = add nsw i32 %mq, %ms',
     '  ret i32 %r', '}', '',
     'define i32 @h(i32 %a, i32 %k) {', '  %t = call i32 @g1(i32 %k)',
     '  %r = add nsw i32 %t, 1', '  ret i32 %r', '}', '']
for i in range(1, N + 1):
    L.append(f'define i32 @g{i}(i32 %k) noinline {{')
    if i < N:
        L += [f'  %t = call i32 @g{i + 1}(i32 %k)', '  %r = add nsw i32 %t, 1']
    else:
        L += ['  %r = mul nsw i32 %k, 5']
    L += ['  ret i32 %r', '}', '']
open(out, 'w').write('\n'.join(L))
