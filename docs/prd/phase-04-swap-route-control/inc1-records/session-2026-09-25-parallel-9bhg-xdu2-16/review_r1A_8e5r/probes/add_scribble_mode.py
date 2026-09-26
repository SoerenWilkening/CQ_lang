#!/usr/bin/env python3
"""REVIEW-ONLY: add CQ_OPT_DEBUG_ALLOC=scribble to the private copy of cq_debug_alloc.cpp:
nothing is ever freed (no reuse, like nofree) AND every freed block is overwritten with
0xA5 bytes, so ANY later read through a pointer to a deleted object reads 0xA5A5... and
crashes deterministically (a dead-pointer dereference detector; also catches a CallbackVH
registered on an already-deleted Value)."""
import sys
p = sys.argv[1]
s = open(p).read()
def sub(a, b):
    global s
    assert s.count(a) == 1, a[:60]
    s = s.replace(a, b)
sub('enum CqAllocMode : int { CAM_Unset = -1, CAM_System = 0, CAM_NoFree = 1, CAM_Lifo = 2 };',
    'enum CqAllocMode : int { CAM_Unset = -1, CAM_System = 0, CAM_NoFree = 1, CAM_Lifo = 2, CAM_Scribble = 3 };')
sub('''    if (E && !std::strcmp(E, "nofree"))
      CqAllocModeV = CAM_NoFree;''', '''    if (E && !std::strcmp(E, "nofree"))
      CqAllocModeV = CAM_NoFree;
    if (E && !std::strcmp(E, "scribble"))
      CqAllocModeV = CAM_Scribble;''')
sub('''  case CAM_NoFree:
    return;''', '''  case CAM_NoFree:
    return;
#if defined(__APPLE__)
  case CAM_Scribble:
    std::memset(P, 0xA5, malloc_size(P));
    return;
#endif''')
open(p, 'w').write(s)
print("ok")
