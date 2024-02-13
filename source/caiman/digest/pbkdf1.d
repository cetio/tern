module caiman.digest.pbkdf1;

public:
static:
ubyte[] pbkdf1(string P, ubyte[8] S, uint C, uint kLen, ubyte[] function(ubyte[]) hash)
{
	ptrdiff_t hLen = hash([]).length;
	if(kLen > hLen)
		throw new Exception("The key length must be less than or equal to the output of the hash.");
	
	ubyte[] T = new ubyte[hLen];
	T = hash(cast(ubyte[])P ~ S);
	for(uint i = 1; i < C; i++)
		T = hash(T);
	
	return T[0..kLen];
}