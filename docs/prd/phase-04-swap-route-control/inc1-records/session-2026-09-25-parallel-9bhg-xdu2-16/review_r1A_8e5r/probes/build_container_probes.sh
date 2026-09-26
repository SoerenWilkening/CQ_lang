#!/bin/bash
set -e
cd $R1A/f1
/usr/bin/c++ -std=c++17 -O1 -I/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2/ir-pass/include $(/usr/local/opt/llvm@19/bin/llvm-config --cxxflags | sed 's/-std=c++[0-9]*//') -c round1_snapshot_asym.cpp -o a.o
/usr/bin/c++ -std=c++17 -c /Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a2cf1f874e5ec99d2/ir-pass/tools/cq_debug_alloc.cpp -o alloc.o
/usr/bin/c++ a.o alloc.o $(/usr/local/opt/llvm@19/bin/llvm-config --ldflags --libs core support --system-libs) -o asym 2>&1 | grep -v "duplicate\|warning" || true
