#![allow(unused_imports, dead_code)]
include!("../cq.rs");
use std::collections::BTreeMap;
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let mut m = BTreeMap::new(); m.insert(1, 10); m.insert(5, 20); m.insert(3, y); m.get(&q(x)).copied().unwrap_or(-1) }
