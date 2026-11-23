#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let mut v = Vec::new(); for i in 0..5 { v.push(y.wrapping_mul(i)); } v[2] = q(x); let mut s = 0i32; for e in &v { s = s.wrapping_add(if *e > 3 { *e } else { e.wrapping_neg() }); } s }
