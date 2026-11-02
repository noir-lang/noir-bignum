# Guarded quadratic carry bounds

The public expression API and operand/quotient checks are unchanged. Selection
uses limb layout and expression arity, not a named curve or protocol. The
existing 126-bit borrow encoding remains the fallback for every other supported
shape and for division. This does not expand the expression API's existing
limits on limb count, coefficient size or quotient size.

Let B = 2^120. For a normalized three-limb modulus of bit length M, let
T = 2^(M-240). Each checked operand has lower limbs below B and top below T.
The padded representation of 2m has lower limbs below 2B and top below 2T.
Thus a positive or negated term has lower limbs below 2B and top below 2T.
The checked quotient has lower limbs below B and top below 64T.
These bounds require valid modulus metadata, as the existing API does.

Let K = NUM_PRODUCTS * LHS_N * RHS_N be the expanded product count.
The individual count guards run before multiplying compile-time u32 counts.

## Fixed signed bias

For M = 254, K <= 3 and at most eight linear terms, every lower signed
coefficient has absolute value below 32B^2. For example, coefficient 1
has at most 8K B^2 of positive products, 2B^2 of quotient products and
16B of linear terms. Coefficient 2 has at most
4K B^2 + 8K BT + B^2 + 65BT + 16T. Adding an incoming signed
carry bounded by 2^125 keeps these bounds below 32B^2.

Encode each signed carry c as c + 2^125 and constrain it to 126 bits.
At coefficient 3, the magnitude is below (8K+65)BT + 2^125.
With T = 2^14 and K <= 3 this is below 2^147, so the last carry
fits [-2^27, 2^27). Encode it with bias 2^27 and 28 bits.
Always propagate the decoded carry; the biases cancel exactly.

The constraint e_i + c_(i-1) = B*c_i is a field equality, but the
bounded difference is smaller in magnitude than the BN254 native field
modulus. It therefore implies the integer equality. The final coefficient
plus decoded carry is similarly bounded and must equal zero. Borrow hints
are unused on this branch; changing them cannot change the relation.

## Narrow final borrow

For 241 <= M <= 258, K <= 32 and at most eight linear terms,
coefficient 3 plus the previous 126-bit carry has magnitude below
(8K+65)BT + 2^126 <= 321BT + 2^126 < 2^148.
Use a 2^148 borrow shift at this transition, check the resulting carry
in 28 bits, and subtract its 2^28 compensation from the final coefficient.
Earlier transitions retain the original encoding. The same bounded-integer
argument excludes native-field aliases.

## Tests

`src/fns/expressions/hint_tests.nr` exercises both encodings with adversarial
quotient and borrow hints whose unconstrained remainder assertion is bypassed
(a failing honest witness generator is not evidence of constraint rejection),
plus boundary-width runtime moduli on either side of each guard.
