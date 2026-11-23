#![allow(unused_imports, dead_code)]
include!("../cq.rs");
fn comp(f: Box<dyn Fn(i32) -> i32>, g: Box<dyn Fn(i32) -> i32>) -> Box<dyn Fn(i32) -> i32> { Box::new(move |v| g(f(v))) }
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { comp(Box::new(move |v| v.wrapping_add(y)), Box::new(|v| v.wrapping_mul(2)))(q(x)) }
