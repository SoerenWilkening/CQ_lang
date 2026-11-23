#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[inline(never)] fn us(b: &Box<i32>) -> i32 { **b + 1 }
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let v = q(x as i16) as i32; if v > 3 { let b = Box::new(v); us(&b) } else { y } }
