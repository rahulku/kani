// Copyright Kani Contributors
// SPDX-License-Identifier: Apache-2.0 OR MIT

#[cfg(kani)]
mod bugsbuddy_ci {
    #[kani::proof]
    fn range_contract() {
        let a: i32 = kani::any();
        let b: i32 = kani::any();
        let result = crate::create_non_empty_range(a, b);

        match result {
            None => assert_eq!(a, b),
            Some(range) => {
                assert_ne!(a, b);
                assert_eq!(range.start, a.min(b));
                assert_eq!(range.end, a.max(b));
                assert!(range.start < range.end);
            }
        }
    }
}