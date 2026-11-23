#![allow(unused_imports, dead_code)]
include!("../cq.rs");
use std::{rc::Rc, cell::RefCell};
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let a = Rc::new(RefCell::new(q(x))); let b = a.clone(); { let mut m = b.borrow_mut(); *m = m.wrapping_add(y); } let v = *a.borrow(); v.wrapping_mul(Rc::strong_count(&a) as i32) }
