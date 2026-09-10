#!/bin/bash
R=/Users/sorenwilkening/Desktop/CQ_lang
$R/build/ir-pass/cq-opt -passes=cq-lowering -S "$1" -o "${1%.ll}.out.ll" 2>&1 | head -20
echo "rc=$?"
