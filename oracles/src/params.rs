

// a struct that emulates the bignum Params params from the params.nr file
pub (crate) struct Params {
    has_multiplicative_inverse: bool,
    modulus: Vec<Fr>,
    double_modulus: Vec<Fr>,
    redc_param: Vec<Fr>,
}

impl  Params  {
    // this function takes the foreign call params and returns a Params struct
    pub fn from_foreign_call_params(inputs: &Vec<ForeignCallParam<String>>) -> Params {
        let has_multiplicative_inverse_fc = &inputs[0];
        let has_multiplicative_inverse = get_bool_from_callparam(&has_multiplicative_inverse_fc);
        let modulus_fc = &inputs[1];
        let modulus = gets_limbs(callparam_to_string(modulus_fc));
        let double_modulus_fc = &inputs[4];
        let double_modulus = gets_limbs(callparam_to_string(double_modulus_fc));
        let redc_param_fc = &inputs[5];
        let redc_param = gets_limbs(callparam_to_string(redc_param_fc));

        Params {
            has_multiplicative_inverse: has_multiplicative_inverse,
            modulus: modulus,
            double_modulus: double_modulus,
            redc_param: redc_param,
        }
    }
}

impl std::fmt::Debug for Params {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "Params {{ has_multiplicative_inverse: {:?}, modulus: {:?}, double_modulus: {:?}, redc_param: {:?}", self.has_multiplicative_inverse, self.modulus, self.double_modulus, self.redc_param)
    }
}


