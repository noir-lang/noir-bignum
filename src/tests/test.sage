# sage file for 
a = [0xac8f3bf3e82de4824c69e37615d9d0, 0xdec7cb5187e95beb13d672363f120d, 0xd67c320641ec0448932ee6a0602908, 0x01ae3a]

modulus = [0x0b5d44300000008508c00000000001, 0xd9f300f5138f1ef3622fba09480017, 0x4617c510eac63b05c06ca1493b1a22, 0x013e3c]

a = [0x950dacccffd9f25bfedc3b1c8fb250, 0x5c14ad28aaf9bc0408af6c977184bb, 0xc3739ec96a4185a3801203b8f6b9b2, 0x017231]

b = [0xbc692fd9e5af7b9117e1e0cf64db6f, 0x7cd01a05d660e1736aadcd130a6517, 0xf5205dcdbd5fb252b9b2396381625b, 0x022f29]

reduction_param = [0xd687789c42a591f9fd58c5e4daffcc, 0x0de6776b1a06af2d488d85a6d02d0e, 0xd0cc4060e976c3ca0582ef4f73bbad, 0x261508]

to_reduce = ["0xec0ca0c0adce359af6fcea1a7ab2dc", "0xdd52c4aa3fde93685d3f7cc285de32", "0x75d80e5e132a6f8954a8cdd6c76fea", "0x8414f97f24248c26ecdda05c41c720", "0xfdcc89c595cf1ebab8e5ea8e4680ef", "0x3ede37060164892256a1b291460dd7", "0x85ea3de302", "0x00"]

for i in range(4): 
    a_as_int *= 2^120
    a_as_int += a[i]
    b_as_int += b[3-i] * 2^(120 * (3-i)) 
    modulus_as_int *= 2^120
    modulus_as_int += modulus[i]
    reduction_param_as_int *= 2^120
    reduction_param_as_int += reduction_param[i]
print(modulus_as_int.is_prime() )
print("a is:" , a_as_int)
print("b is :",b_as_int)
print("modulus is:" , modulus_as_int)
print("modulus should be:", int("0x01ae3a4617c510eac63b05c06ca1493b1a22d9f300f5138f1ef3622fba094800170b5d44300000008508c00000000001",16))
print(a_as_int % modulus_as_int)
print(b_as_int % modulus_as_int)
print(a_as_int % modulus_as_int == b_as_int % modulus_as_int) 
print("reduction param is", reduction_param_as_int)
p = 21888242871839275222246405745257275088548364400416034343698204186575808495617
mod_bits = 377 
print("reduction param should be", 2^(mod_bits * 2 + 4))
print(a == b)


the divisor is
[0x0c, 0x00, 0x00]
the remainder is
[0x00, 0x00, 0x00]
the result limb is

the divisor is
[0x0c, 0x00, 0x00]
the remainder is
[0x00, 0x00, 0x00]
# with the flag 
the last limb is
0x00
0x00
the result is
0x0800
the borrow flags are
false
the carry flags are
false
the result limb is
0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593effff801

# without the flag 
the last limb is
0x00
0x00
the result is
0x00
the borrow flags are
false
the carry flags are
false
the result limb is
0x00
