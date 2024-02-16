    /// Implementation of FNV1 digester
    module caiman.digest.fnv1;

    import caiman.object;
    import caiman.digest;

    /**
    * Implementation of FNV1 digester.
    *
    * FNV1 (Fowler–Noll–Vo) is a simple hash function that XORs each byte of 
    * the input data with a predefined constant and then multiplies the result 
    * by another predefined constant. The process is repeated for each byte in 
    * the data.
    *
    * Example:
    * ```d
    * import caiman.digest.fnv1;
    * 
    * ubyte[] data = [1, 2, 3, 4, 5];
    * auto hashValue = FNV1.hash(data);
    * ```
    */
    public static @digester class FNV1
    {
    private:
    static:
    pure:
        enum OFFSETBASIS = 14_695_981_039_346_656_037;
        enum PRIME = 1_099_511_628_211;

    public:
        /**
        * Computes the FNV1 hash digest of the given data.
        *
        * Params:
        *  data = The input byte array for which the FNV1 hash is to be computed.
        *
        * Returns:
        *  A byte array representing the computed FNV1 hash digest.
        */
        ubyte[] hash(ubyte[] data) 
        {
            ulong hash = OFFSETBASIS;
            foreach (b; data) 
            {
                hash ^= b;
                hash *= PRIME;
            }
            return hash.serialize!true();
        }
    }