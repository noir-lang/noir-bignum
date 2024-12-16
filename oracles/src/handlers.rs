use ark_bn254::Fr;
// use jsonrpsee::core::params;
use num_bigint::BigInt;
use num_bigint::BigUint;
// It's pretty disgusting that I've introduced this library, just to convert to/from radix 16. I wonder if there's a better way with arkworks?
use num_traits::Num;
use serde::Serialize;
// It's pretty disgusting that I've introduced this library, just to convert to/from radix 16. I wonder if there's a better way with arkworks?
use serde_json::{json, Value};
// use std::str::FromStr;

use crate::foreign_call::ForeignCallParam;
use crate::ops::batch_invert;
use crate::ops::invert;
use crate::ops::is_zero;
use crate::ops::pow_bn;
// use crate::ops::sqrt;

// a struct that emulates the bignum Params params from the params.nr file
struct Params {
    has_multiplicative_inverse: bool,
    modulus: BigUint,
    double_modulus: Vec<Fr>,
    redc_param: Vec<Fr>,
}

/**** THERE'S A LOT OF BOILERPLATE INSIDE THESE "HANDLERS", THAT WE CAN PROBABLY PUT INTO COMMON HELPER FUNCTIONS ****/

/** Note: I _think_ the type `Vec<ForeignCallParam<String>>` will be generically applicable to _any_ oracle call arguments, so I've made _all_ handlers receive this type. */
pub(crate) fn pack_in_json<T: Serialize>(return_vec: T) -> Value {
    let json_response = json!({"values" : return_vec});
    json_response
}
// pub(crate) fn handle_get_sqrt(inputs: &Vec<ForeignCallParam<String>>) -> Value {
//     /**** EXTRACT INPUT STRING(S) ****/
//     println!("inputs: {:?}", inputs);
//     assert!(inputs.len() == 1);

//     let input_param = &inputs[0];

//     let input_string = match input_param {
//         ForeignCallParam::Single(value) => value.trim_start_matches('0'), // Trimming leading zeroes turned out to be very important, otherwise `from_str` on the next line was erroring!
//         ForeignCallParam::Array(_) => panic!("Expected single value, found array"),
//     };

//     println!("input_string: {:?}", input_string);

//     /**** CONVERT INPUT STRING(S) TO MEANINGFUL TYPE(S) ****/
//     let x_big_uint: BigUint = BigUint::from_str_radix(input_string, 16).unwrap();
//     let x: Fr = x_big_uint.into();
//     // let x: Fr = Fr::from_str(input_string).unwrap(); // This was incorrectly assuming the input_string to be decimal.
//     println!("x: {:?}", x);

//     /**** OPERATE ****/
//     let sqrt = sqrt(x);
//     println!("Computed sqrt: {:?}", sqrt);

//     /**** ENSURE HEX ****/
//     let as_big_uint: BigUint = sqrt.unwrap().into();
//     let as_hex_str = as_big_uint.to_str_radix(16);

//     let oracle_return_data_the_noir_program_expects = as_hex_str;

//     /**** FORMAT RESULT FOR NOIR CONSUMPTION, AND CONVERT RESULT TO JSON `Value` TYPE ****/
//     //** Note: I'm converting to `Value` within these "handler" functions, instead of within the main callback (the callback inside run_server --> module.register_method --> resolve_foreign_call), because the return types can be subtly different: Vec<String>, or Vec<Vec<String>>, or maybe some more-complex arrangement of Strings and Vec<Strings>. It felt easiest to have the "hander" functions figure out how to serialise their return data. */
//     let return_vec = vec![oracle_return_data_the_noir_program_expects];
//     println!("return_vec: {:?}", return_vec);

//     let json_response = json!({"values" : return_vec});
//     println!("json_response: {:?}", json_response);
//     json_response
// }

// pub(crate) fn handle_get_sqrts(inputs: &Vec<ForeignCallParam<String>>) -> Value {
//     /**** EXTRACT INPUT STRING(S) ****/
//     println!("inputs: {:?}", inputs);

//     let input_param = &inputs[0];
//     let input_strings: Vec<&str> = match input_param {
//         ForeignCallParam::Single(_value) => panic!("Expected array, found single value"),
//         ForeignCallParam::Array(values) => values
//             .into_iter()
//             .map(|v| v.trim_start_matches('0'))
//             .collect(),
//     };

//     println!("input_strings: {:?}", input_strings);

//     let mut sqrts: Vec<String> = vec![];

//     for input_string in input_strings {
//         /**** CONVERT INPUT STRING(S) TO MEANINGFUL TYPE(S) ****/
//         println!("input_string: {:?}", input_string);

//         let x_big_uint: BigUint = BigUint::from_str_radix(input_string, 16).unwrap();
//         let x: Fr = x_big_uint.into();
//         // let x: Fr = Fr::from_str(input_string).unwrap(); // This was incorrectly assuming the input_string to be decimal.
//         println!("x: {:?}", x);

//         /**** OPERATE ****/
//         let sqrt = sqrt(x);
//         println!("Computed sqrt: {:?}", sqrt);

//         /**** ENSURE HEX ****/
//         let as_big_uint: BigUint = sqrt.unwrap().into();
//         let as_hex_str = as_big_uint.to_str_radix(16);

//         sqrts.push(as_hex_str);
//     }

//     let oracle_return_data_the_noir_program_expects = sqrts;

//     /**** FORMAT RESULT FOR NOIR CONSUMPTION, AND CONVERT RESULT TO JSON `Value` TYPE ****/
//     let return_vec = vec![oracle_return_data_the_noir_program_expects]; // Notice! This is a different type from the singular handle_get_sqrt function! Hence why the `Value` is being computed inside this function, instead in the calling function.
//     println!("return_vec: {:?}", return_vec);

//     let json_response = json!({"values" : return_vec});
//     println!("json_response: {:?}", json_response);
//     json_response
// }

// ==============================
// ==============================
// ==============================
// call handler for is_zero
pub(crate) fn handle_is_zero(inputs: &Vec<ForeignCallParam<String>>) -> Vec<String> {
    // Create a vector with a single boolean value (true) as the result
    // let input_param = &inputs[0];
    // parse the input into strings
    let mut input_strings = vec![];
    for input in inputs {
        input_strings.push(callparam_to_string(input)[0]);
    }
    let limbs = gets_limbs(input_strings);
    // call the is_zero function from the ops.rs
    let result = is_zero(limbs);
    // print the result
    /**** ENSURE HEX ****/
    let as_big_uint: BigUint = result.into();
    let as_hex_str = as_big_uint.to_str_radix(16);
    let mut results: Vec<String> = vec![];
    results.push(as_hex_str);
    let oracle_return_data_the_noir_program_expects = results;

    /**** FORMAT RESULT FOR NOIR CONSUMPTION, AND CONVERT RESULT TO JSON `Value` TYPE ****/
    let return_vec = oracle_return_data_the_noir_program_expects; // Notice! This is a different type from the singular handle_get_sqrt function! Hence why the `Value` is being computed inside this function, instead in the calling function.
    return_vec
    // let json_response = json!({"values" : return_vec});
    // json_response
}

// ==============================
// ==============================
// ==============================
// call handler for add
pub(crate) fn handle_mul_with_quotient(inputs: &Vec<ForeignCallParam<String>>) -> Vec<Vec<String>> {
    // parse the input, the last 2 elements of the input are the modulus bits and the number of limbs
    let num_limbs_fc = &inputs[inputs.len() - 2];
    let num_limbs = get_u32_from_callparam(&num_limbs_fc);
    // create the params struct
    let params: Params = Params::from_foreign_call_params(&inputs);
    // get the lhs and rhs
    let lhs_fc = &inputs[inputs.len() - 3];
    let lhs_str = callparam_to_string(lhs_fc);
    let lhs_biguint = cast_to_biguint(lhs_str);
    let rhs_fc = &inputs[inputs.len() - 4];
    let rhs_str = callparam_to_string(rhs_fc);
    let rhs_biguint = cast_to_biguint(rhs_str);
    let mul_res = lhs_biguint * rhs_biguint;
    let modulus = params.modulus;
    let q = &mul_res / &modulus;
    let r = &mul_res % &modulus;
    // cast the q and r to limbs
    let q_limbs = cast_biguint_to_bignum_limbs(&q, num_limbs);
    let r_limbs = cast_biguint_to_bignum_limbs(&r, num_limbs);
    // call the mul_with_quotient function from the ops.rs file
    let return_vec: Vec<Vec<String>> = vec![q_limbs, r_limbs];
    // let json_response = json!({"values" : return_vec});
    // json_response
    return_vec
}

// ==============================
// ==============================
// ==============================
// call handler for add
// the inputs of the function are params, lhs, rhs, num_limbs, mod_bits, returns the result of the addition which is a vector of hex limbs
// params are of form
// lhs and rhs are vector of limbs
// the input is 8 elements
pub(crate) fn handle_add(inputs: &Vec<ForeignCallParam<String>>) -> Vec<Vec<String>> {
    // parse the input, the last 2 elements of the input are the modulus bits and the number of limbs
    // get the number of limbs from the input
    // let num_limbs_fc = &inputs[inputs.len()-2];
    // let num_limbs = get_u32_from_callparam(&num_limbs_fc);
    // convert the lhs and rhs to biguints
    let lhs_fc = &inputs[inputs.len() - 3];
    let lhs_str = callparam_to_string(lhs_fc);
    let num_limbs = lhs_str.len();
    let lhs_biguint = cast_to_biguint(lhs_str);
    let rhs_fc = &inputs[inputs.len() - 4];
    let rhs_str = callparam_to_string(rhs_fc);
    let rhs_biguint = cast_to_biguint(rhs_str);
    // lastly parse out the params
    // create the params struct
    let params: Params = Params::from_foreign_call_params(&inputs);
    let modulus = params.modulus;
    let result = lhs_biguint + rhs_biguint;
    let result_mod = result % modulus;
    // cast the result to limbs
    let limbs = cast_biguint_to_bignum_limbs(&result_mod, num_limbs as u32);
    // pack it in a json response
    let return_vec: Vec<Vec<String>> = vec![limbs];
    // let json_response = json!({"values" : return_vec});

    // json_response
    return_vec
}

pub(crate) fn handle_neg(inputs: &Vec<ForeignCallParam<String>>) -> Vec<Vec<String>> {
    // parse the input, the last 2 elements of the input are the modulus bits and the number of limbs
    // create the params struct

    let params: Params = Params::from_foreign_call_params(&inputs);
    let modulus = params.modulus;
    let limbs_fc = &inputs[inputs.len() - 3];
    let num_limbs = limbs_fc.len();
    let mut limbs_biguint = cast_to_biguint(callparam_to_string(limbs_fc));
    if limbs_biguint > modulus {
        limbs_biguint = limbs_biguint % &modulus;
    }
    let neg = &modulus - &limbs_biguint;
    let neg_limbs = cast_biguint_to_bignum_limbs(&neg, num_limbs as u32);
    let return_vec: Vec<Vec<String>> = vec![neg_limbs];
    return_vec
    // let json_response = json!({"values" : return_vec});
    // json_response
}

pub(crate) fn handle_udiv_mod(inputs: &Vec<ForeignCallParam<String>>) -> Vec<Vec<String>> {
    // get the numerator and the divisor
    let numerator_fc = &inputs[0];
    let numerator_str = callparam_to_string(&numerator_fc);
    let numerator = cast_to_biguint(numerator_str);
    let divisor_fc = &inputs[1];
    let divisor_str = callparam_to_string(divisor_fc);
    let divisor = cast_to_biguint(divisor_str);
    // get the number of limbs
    let num_limbs = numerator_fc.len();

    // divide the numerator by the divisor
    let quotient = &numerator / &divisor;
    let remainder = &numerator % &divisor;

    // cast the quotient and the remainder to limbs
    let quotient_limbs = cast_biguint_to_bignum_limbs(&quotient, num_limbs as u32);
    let remainder_limbs = cast_biguint_to_bignum_limbs(&remainder, num_limbs as u32);

    let return_vec: Vec<Vec<String>> = vec![quotient_limbs, remainder_limbs];
    return_vec
    // let json_response = json!({"values" : return_vec});
    // json_response
}

// a handler for modular inversion
pub(crate) fn handle_invmod(inputs: &Vec<ForeignCallParam<String>>) -> Vec<Vec<String>> {
    // get the params
    let params: Params = Params::from_foreign_call_params(&inputs);
    // get the value to be inverted
    let val_fc = &inputs[inputs.len() - 3];
    let val_str = callparam_to_string(val_fc);
    let val = cast_to_biguint(val_str);
    let num_limbs = val_fc.len();
    // invert the value
    let inv = invert(&val, &params.modulus);
    // cast the inverse to limbs
    let limbs = cast_bigint_to_bignum_limbs(&inv, num_limbs as u32);
    // return the json response for now
    let return_vec: Vec<Vec<String>> = vec![limbs];
    return_vec
    // let json_response = json!({"values" : return_vec});
    // json_response
}

// a handler for modular exponentiation
pub(crate) fn handle_pow(inputs: &Vec<ForeignCallParam<String>>) -> Vec<Vec<String>> {
    // return an empty json response for now
    let params: Params = Params::from_foreign_call_params(&inputs);
    let exponent_fc = &inputs[inputs.len() - 3];
    let exponent_str = callparam_to_string(exponent_fc);
    let exponent = cast_to_biguint(exponent_str);
    let num_limbs = exponent_fc.len();
    let val_fc = &inputs[inputs.len() - 4];
    let val_str = callparam_to_string(val_fc);
    let val = cast_to_biguint(val_str);

    let res = pow_bn(&val, &exponent, &params.modulus);
    let limbs = cast_biguint_to_bignum_limbs(&res, num_limbs as u32);
    let return_vec: Vec<Vec<String>> = vec![limbs];
    return_vec
    // let json_response = json!({"values" : return_vec});
    // json_response
}

// a handler for modular division
pub(crate) fn handle_div(inputs: &Vec<ForeignCallParam<String>>) -> Vec<Vec<String>> {
    let params: Params = Params::from_foreign_call_params(&inputs);
    let numerator_fc = &inputs[inputs.len() - 4];
    let numerator_str = callparam_to_string(numerator_fc);
    let numerator = cast_to_biguint(numerator_str);
    let divisor_fc = &inputs[inputs.len() - 3];
    let divisor_str = callparam_to_string(divisor_fc);
    let divisor = cast_to_biguint(divisor_str);
    let num_limbs = numerator_fc.len();

    // compute the inverse of the divisor with respect to the modulus
    let inv = invert(&divisor, &params.modulus);
    // multiply the numerator by the inverse
    let result = (BigInt::from(numerator.clone())) * &inv;
    let reduced = result % BigInt::from(params.modulus.clone());
    // cast the result to limbs
    let limbs = cast_bigint_to_bignum_limbs(&reduced, num_limbs as u32);
    let return_vec: Vec<Vec<String>> = vec![limbs];
    return_vec
    // let json_response = json!({"values" : return_vec});
    // json_response
}

pub(crate) fn handle_barrett_reduction(inputs: &Vec<ForeignCallParam<String>>) -> Vec<Vec<String>> {
    // return an empty json response for now
    // the inputs are x , modulus
    let x_fc = &inputs[0];
    let x_str = callparam_to_string(x_fc);
    let modulus_fc = &inputs[1];
    let modulus_str = callparam_to_string(modulus_fc);
    let x = cast_to_biguint(x_str);
    let modulus = cast_to_biguint(modulus_str);
    let num_limbs = modulus_fc.len();
    let quotient = &x / &modulus;
    let remainder = &x % &modulus;
    //cast the quotient and the remainder to limbs
    let quotient_limbs = cast_biguint_to_bignum_limbs(&quotient, num_limbs as u32);
    let remainder_limbs = cast_biguint_to_bignum_limbs(&remainder, num_limbs as u32);
    let return_vec: Vec<Vec<String>> = vec![quotient_limbs, remainder_limbs];
    return_vec
    // let json_response = json!({"values" : return_vec});
    // json_response
}

pub(crate) fn handle_batch_invert(inputs: &Vec<ForeignCallParam<String>>) -> Vec<Vec<String>> {
    // get the params
    let params: Params = Params::from_foreign_call_params(&inputs);
    // get the number of input bignums
    // let m_fc = &inputs[inputs.len() - 1];
    // let m = get_u32_from_callparam(&m_fc);
    // get the number of limbs
    let num_limbs_fc = &inputs[inputs.len() - 3];
    let num_limbs = get_u32_from_callparam(&num_limbs_fc);
    // get the array of bignums
    let xs = &inputs[inputs.len() - 4];
    let xs_vec = xs.get_values();
    // cast the xs_vec into a vector of &str
    // this is gross but we have to switch back to &str
    // and then we push them into a vector of bignum elements
    let mut x_str: Vec<&str> = vec![];
    let mut inputs_bns: Vec<BigUint> = vec![];
    for i in 0..xs_vec.len() {
        let y = xs_vec[i].as_str();
        x_str.push(y);
        if x_str.len() as u32 % num_limbs == 0 {
            let bn = cast_to_biguint(x_str);
            x_str = vec![];
            inputs_bns.push(bn);
        }
    }
    let results = batch_invert(&inputs_bns, &params.modulus);
    // cast BigInt to bignum limbs
    let mut results_formatted: Vec<String> = vec![];
    for result in results {
        let limbs = cast_bigint_to_bignum_limbs(&result, num_limbs);
        for limb in limbs {
            results_formatted.push(limb);
        }
    }

    // println!("xs_str: {:?}", x_str);
    // split the xs_vec into arrays of size num_limbs

    // let res = batch_invert(&chunks, &params.modulus);
    let return_vec: Vec<Vec<String>> = vec![results_formatted];
    // let json_response = json!({"values" : return_vec});
    // json_response
    return_vec
}

// ==============================
// ==============================
// ==============================
// helper functions

pub(crate) fn cast_to_biguint(input_strings: Vec<&str>) -> BigUint {
    // split the limbs
    let mut limbs: Vec<BigUint> = vec![];
    for input_string in input_strings {
        // handle the case of a zero input
        if input_string == "" {
            let x_big_uint = BigUint::from_str_radix("0", 16).unwrap();
            limbs.push(x_big_uint);
        } else {
            let x_big_uint: BigUint = BigUint::from_str_radix(input_string, 16).unwrap();
            limbs.push(x_big_uint);
        }
    }
    // a constant 2^120 as biguint
    let base: BigUint = BigUint::from(2u32);
    let exp = 120u32;
    let shift_constant = base.pow(exp);
    let mut res = BigUint::ZERO;
    for i in 0..limbs.len() {
        res = res + &limbs[i] * &shift_constant.pow(i as u32);
    }
    res
}

// helper function to get limbs of a big num and pack them into a vector of Fr elements
pub(crate) fn gets_limbs(input_strings: Vec<&str>) -> Vec<Fr> {
    let mut limbs: Vec<Fr> = vec![];
    for input_string in input_strings {
        // handle the case of a zero input
        if input_string == "" {
            let x_big_uint = BigUint::from_str_radix("0", 16).unwrap();
            let limb: Fr = x_big_uint.into();
            limbs.push(limb);
        } else {
            let x_big_uint: BigUint = BigUint::from_str_radix(input_string, 16).unwrap();
            let limb: Fr = x_big_uint.into();
            limbs.push(limb);
        }
    }
    limbs
}

pub(crate) fn callparam_to_string(input: &ForeignCallParam<String>) -> Vec<&str> {
    match input {
        ForeignCallParam::Single(value) => vec![value.trim_start_matches('0')],
        ForeignCallParam::Array(values) => values
            .into_iter()
            .map(|v| v.trim_start_matches('0'))
            .collect(),
    }
}

pub(crate) fn get_u32_from_callparam(input: &ForeignCallParam<String>) -> u32 {
    let input_string = callparam_to_string(input)[0];
    u32::from_str_radix(input_string, 16).unwrap()
}

pub(crate) fn get_bool_from_callparam(input: &ForeignCallParam<String>) -> bool {
    let mut input_string = callparam_to_string(input)[0];
    if input_string == "" {
        input_string = "0";
    }
    let res = u32::from_str_radix(input_string, 16).unwrap();
    res == 1
}

pub(crate) fn cast_biguint_to_bignum_limbs(input: &BigUint, num_limbs: u32) -> Vec<String> {
    // a constant 2^120 as biguint
    let base: BigUint = BigUint::from(2u32);
    let exp = 120u32;
    let shift_constant = base.pow(exp);
    let mut input_copy = input.clone();
    // an empty array of size num_limbs of type hex limbs
    let mut limbs_hex: Vec<String> = vec![];
    for _ in 0..num_limbs {
        let remainder = &input_copy % &shift_constant;
        limbs_hex.push(remainder.to_str_radix(16));
        let quetient: BigUint = input_copy / &shift_constant;
        input_copy = quetient.clone();
    }
    limbs_hex
}

pub(crate) fn cast_bigint_to_bignum_limbs(input: &BigInt, num_limbs: u32) -> Vec<String> {
    // a constant 2^120 as biguint
    let base: BigInt = BigInt::from(2u32);
    let exp = 120u32;
    let shift_constant = base.pow(exp);
    let mut input_copy = input.clone();
    // an empty array of size num_limbs of type hex limbs
    let mut limbs_hex: Vec<String> = vec![];
    for _ in 0..num_limbs {
        let remainder = &input_copy % &shift_constant;
        limbs_hex.push(remainder.to_str_radix(16));
        let quetient: BigInt = input_copy / &shift_constant;
        input_copy = quetient.clone();
    }
    limbs_hex
}

impl Params {
    // this function takes the foreign call params and returns a Params struct
    pub fn from_foreign_call_params(inputs: &Vec<ForeignCallParam<String>>) -> Params {
        let has_multiplicative_inverse_fc = &inputs[0];
        let has_multiplicative_inverse = get_bool_from_callparam(&has_multiplicative_inverse_fc);
        let modulus_fc = &inputs[1];
        // let modulus = gets_limbs(callparam_to_string(modulus_fc));
        let modulus_str = callparam_to_string(modulus_fc);
        let modulus = cast_to_biguint(modulus_str);
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
