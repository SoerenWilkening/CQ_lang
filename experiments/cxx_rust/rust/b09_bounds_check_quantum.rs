#![allow(unused_imports, dead_code)]
include!("../cq.rs");
// the index can be out of range: a panic under a quantum condition
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let v = [1, y, 3, 4]; let i = q(x as u8) as usize; v[i] }
