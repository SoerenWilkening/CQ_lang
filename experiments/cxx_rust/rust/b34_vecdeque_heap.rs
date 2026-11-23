#![allow(unused_imports, dead_code)]
include!("../cq.rs");
use std::collections::*;
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let mut d = VecDeque::new(); for i in 0..3 { d.push_front(y.wrapping_add(i)); } d[1] = q(x); let s: i32 = d.iter().fold(0, |a, b| a ^ b); let mut h = BinaryHeap::new(); h.push(5); h.push(s); h.push(y); h.pop().unwrap_or(0) }
