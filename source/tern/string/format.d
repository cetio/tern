module tern.string.format;

import std.string;
import std.algorithm;
import std.array;
import tern.string.lettering;

string mangle(string str) 
{
    size_t idx = str.lastIndexOf('.');
    if (idx != -1)
        str = str[(idx + 1)..$];

    str = str.replace("*", "PTR")
        .replace("[", "OPBRK")
        .replace("]", "CLBRK")
        .replace(",", "COMMA")
        .replace("!", "EXCLM");

    return cast(string)str.filter!(c => isAlphaNum(c) || c == '_').array;
}