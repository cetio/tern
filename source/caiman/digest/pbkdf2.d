module caiman.digest.pbkdf2;

import std.math;

// Credit: https://github.com/1100110/cryptod/blob/master/cryptod/src/kdf/pbkdf2.d
ubyte[] PBKDF2(ubyte[] function(ubyte[], ubyte[]) PRF, string P, ubyte[] S, uint c, uint dkLen)
{
	union WORD 
    { 
        uint i; 
        ubyte[4] b; 
    }

	WORD x;
	ptrdiff_t hLen = PRF([],[]).length;
	uint l = cast(uint)ceil((cast(float)dkLen)/(cast(float)hLen));
	ptrdiff_t r = dkLen - (l - 1) * hLen;
	
	ubyte[] F(ubyte[] PP, ubyte[] SS, uint cc, uint ii)
	{
		x.i = ii;
		SS ~= x.b;
		ubyte[] U = PRF(PP,SS);

		for(uint j = 1; j < cc; j++)
			U[] ^= PRF(PP,U)[];

		return U;
	}
	
	ubyte[] T;
	for(uint i = 0; i < l; i++)
		T ~= F(cast(ubyte[])P,S,c,i+1);
	
	return T[0..r];
}