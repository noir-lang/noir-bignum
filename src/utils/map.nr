// Copied from std::array, because I couldn't figure out how to import the `map` method of the weird trait for an array.
// And the reason I wanted direct access to it, is because I couldn't figure out how to implement a double map.
pub(crate) fn map<T, let N: u32, U, Env>(arr: [T; N], f: fn[Env](T) -> U) -> [U; N] {
    let first_elem = f(arr[0]);
    let mut ret = [first_elem; N];

    for i in 1..arr.len() {
        ret[i] = f(arr[i]);
    }

    ret
}
