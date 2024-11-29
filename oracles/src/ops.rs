use ark_bn254::Fr;
use ark_ff::Field;
use ark_ff::Zero;

pub(crate) fn sqrt(x: Fr) -> Option<Fr> {
    let sqrt: Option<Fr> = if x.legendre().is_qr() {
        let sqrt = x.sqrt().unwrap();
        assert_eq!(sqrt.square(), x);

        Some(sqrt)
    } else {
        assert_eq!(x.sqrt(), None);

        None
    };

    if sqrt == None {
        // I can't be bothered figuring out how to serialise an `Option::None` back to Noir-land, so I'm panicking in this case, instead.
        panic!("NO SQUARE ROOT EXISTS");
    }

    sqrt
}

pub(crate) fn is_zero(limbs: Vec<Fr>) -> bool {
    let mut result: bool = true;
    for limb in limbs {
        result = result & (limb == Fr::zero());
    }
    result
}