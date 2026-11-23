#![allow(unused_imports, dead_code)]
include!("../cq.rs");
use std::collections::BTreeMap;
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let mut m = BTreeMap::new(); m.insert(1, 10); m.insert(5, q(x)); m.insert(3, y); let mut s = 0i32; for (k, v) in &m { s = s.wrapping_mul(3).wrapping_add((*v).wrapping_mul(*k)); } s }
