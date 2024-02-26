module tern.math.common;

import std.math;
import std.traits;

T factorial(T)(T n) 
    if (isIntegral!T)
{
    return n <= 1 ? 1 : n * factorial(n - 1);
}

A gcd(A, B)(A a, B b) 
    if (isIntegral!A && isIntegral!B)
{
    while (b != 0) 
    {
        auto temp = b;
        b = a % b;
        a = temp;
    }
    return a;
}

A lcm(A, B)(A a, B b) 
    if (isIntegral!A && isIntegral!B)
{
    return abs(a * b) / gcd(a, b);
}

bool isPrime(uint n) 
{
    if (n <= 1)
        return false;

    if (n <= 3)
        return true;

    if (n % 2 == 0 || n % 3 == 0)
        return false;
        
    size_t i = 5;
    while (i * i <= n)
    {
        if (n % i == 0 || n % (i + 2) == 0)
            return false;

        i += 6;
    }
    return true;
}

uint prime(uint n) 
{
    if (n == 1)
        return 2;

    uint count = 1;
    uint num = 3;
    while (count < n) 
    {
        if (isPrime(num))
            count++;

        if (count != n)
            num += 2;
    }
    return num;
}

float finSqrt(float x) 
{
    float xhalf = 0.5f * x;
    int i = *cast(int*)&x;
    i = 0x5f3759df - (i >> 1);
    x = *cast(float*)&i;
    return x * (1.5f - xhalf * x * x);
}