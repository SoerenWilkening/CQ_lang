#!/bin/bash
SUBJ=/Users/sorenwilkening/Desktop/CQ_VERIFY
{ ls $SUBJ/ir-pass/test/*.ll
  find $SUBJ/docs/prd/phase-04-swap-route-control/inc1-records \
       \( -path '*/probes/*' -o -path '*review_*_probes/*' \) \
       \( -name '*.c' -o -name '*.ll' \) ;
} | sort -u
