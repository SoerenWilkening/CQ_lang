// USERCHECK pp
// cq-0hhk (gate 2a review pred-h1 #1, pp): HAND-WRITTEN IR in switch_rotated_case_arm.O1.ll, no C
// source: clang -O1 folds the scrutinee to the case constant inside a case arm, so a case arm (not the
// default) rotating the scrutinee's rail in place, then falling through into a shared block with phases,
// has no C spelling. The shape:
//   x = cq_theta(x0, 0.5); switch (x) { case 1: x = cq_theta(x, 0.7); /* fallthrough */
//                                       case 2: cq_phi(0.3); cq_phi(0.1); default: ; } return x;
