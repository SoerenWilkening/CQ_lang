#![allow(unused_imports, dead_code)]
include!("../cq.rs");
use std::sync::{Mutex, atomic::*}; static C: AtomicI32 = AtomicI32::new(3);
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let m = Mutex::new(q(x)); { let mut g = m.lock().unwrap(); *g = g.wrapping_add(y); } let r = *m.lock().unwrap(); C.load(Ordering::SeqCst).wrapping_add(r) }
