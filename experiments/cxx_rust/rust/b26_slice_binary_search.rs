#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { static T: [i32; 7] = [1, 3, 5, 9, 12, 40, 77]; match T.binary_search(&q(x)) { Ok(i) => i as i32, Err(i) => -(i as i32) - y } }
