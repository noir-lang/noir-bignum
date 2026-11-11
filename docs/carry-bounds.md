# Fixed-bias carry bounds

`evaluate_quadratic_expression` checks that an expression is zero by splitting
it into limbs and checking a chain of carries between them. By default every
carry is checked in 126 bits, with prover-supplied borrow flags that keep each
limb non-negative. For the shapes selected by `quadratic_fixed_bias`, it
instead checks signed carries with a fixed bias and no borrow flags
(`validate_expression_fixed_bias`). This note derives the bounds behind that
choice. The selection uses only the limb layout and the expression size, never
a named curve. The public API, the checked relation and the operand and
quotient range checks are unchanged.

## Setting

Let B = 2^120. The guard admits three-limb moduli of bit length M with
240 < M <= 258; let T = 2^(M-240), so 2 <= T <= 2^18. It also requires at
most K = NUM_PRODUCTS * LHS_N * RHS_N <= 3 expanded products and at most
A <= 8 linear terms.

- Every term is range-checked to M bits by `evaluate_quadratic_expression`, so
  it has lower limbs below B and top limb below T.
- A negated term is replaced by `double_modulus - term`. `double_modulus` is
  2*MOD with borrow padding: limbs (2m)_0 + B, (2m)_1 + B - 1 and
  (2m)_2 - 1, where (2m)_2 is in [T, 2T) because the modulus has exactly M
  bits. So a term, positive or negated, has lower limbs in [0, 2B) and top
  limb in [0, 2T).
- The quotient is range-checked to lower limbs below B and top limb below
  64T. The modulus has lower limbs below B and top limb below T.

Like the rest of `evaluate_quadratic_expression`, these bounds assume valid
parameters (`modulus` and `double_modulus` as built by `BigNumParams::new` or
the bundled parameter sets).

## Coefficient bounds

The expression is e_0 + e_1 B + ... + e_4 B^4, where e_i is the sum of the
product and linear-term limbs at position i (a non-negative part P_i) minus
the quotient-times-modulus limbs at position i (a non-negative part Q_i).
So |e_i| < max(P_i, Q_i).

| i | P_i below | Q_i below | with K <= 3, A <= 8 |
| --- | --- | --- | --- |
| 0 | 4K B^2 + 2A B | B^2 | < 12B^2 + 16B |
| 1 | 8K B^2 + 2A B | 2B^2 | < 24B^2 + 16B |
| 2 | 4K B^2 + 8K BT + 2A T | B^2 + 65BT | < 12B^2 + 24BT + 16T |
| 3 | 8K BT | 65BT | < 65BT |
| 4 | 4K T^2 | 64T^2 | < 64T^2 |

## Carry bounds

The carries satisfy e_i + c_(i-1) = B c_i for i = 0..3 (with c_(-1) = 0)
and e_4 + c_3 = 0. For an honest witness these are integers, and:

- |c_0| < 12B + 16 < 2^124;
- |c_1| < (24B^2 + 16B + 12B + 16) / B < 25B < 2^125;
- |c_2| < (12B^2 + 24BT + 16T + 25B) / B < 13B < 2^124;
- |c_3| < (65BT + 13B) / B = 65T + 13 < 2^25, using T <= 2^18.

`validate_expression_fixed_bias` encodes c_0, c_1 and c_2 as c + 2^125 and
checks them in 126 bits, which holds for |c| < 2^125. It encodes c_3 as
c + 2^27 and checks it in 28 bits, which holds for |c| < 2^27, four times the
bound above. It always propagates the decoded carry, so the biases cancel.

## Soundness

Soundness does not rely on the prover: for the admitted shapes (three limbs,
M <= 258, K <= 3, A <= 8), the range checks on terms and quotient bound every
coefficient below 2^245 for any witness, honest or not (|e_i| < 25B^2 by the
table above). The checked carries are below 2^125 in magnitude, so B c_i is
below 2^245. Each constraint e_i + c_(i-1) - B c_i = 0 therefore involves
values far below the BN254 scalar field modulus (about 2^254) and holds over
the integers, and so does the final e_4 + c_3 = 0. Summing the equations with
weights B^i shows that the expression is zero over the integers. The
honest-carry bounds matter only for completeness: they ensure that an honest
prover's carries fit the 126-bit and 28-bit ranges.

## Operands of `eq`

`eq` and `assert_is_not_equal` accept operands one bit wider (below
2^(M+1)). Such operands never reach this code, because the M-bit range check
on every term rejects them.

## Tests

`src/fns/expressions/hint_tests.nr` feeds dishonest quotients, computed
without the unconstrained remainder assertion, straight into the constrained
code. A relation that is off by one is rejected at the first carry check. A
relation that is off by 2^360, with the quotient chosen so that limbs 0..2
balance, passes the three 126-bit carry checks and is rejected by the 28-bit
check. Honest relations of the largest admitted shape (three products, eight
linear terms) with the largest operands, all positive, all negated, and with
every term a negated zero, are accepted for BN254 Fq and for runtime moduli
of 241 and 258 bits; at 259 bits the same relations take the borrow-flag
check. With `MOD = 2^258 - 1` (every limb of the modulus at its maximum), all
terms negated and the three products arranged as 3 separate products, as one
product with three left-hand terms, and as one with three right-hand terms,
the relations are accepted too.
