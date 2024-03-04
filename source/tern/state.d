module tern.state;

import tern.traits;

public:
static:
pure:
/**
 * Generates a string representation of a value based on its flag members.
 *
 * Params:
 *  val = The value for which to generate the string representation.
 *
 * Returns:
 *  A string representing the flag members set in the value.
 */
string toString(T)(T val)
{
    foreach (string member; Children!T)
    {
        if (val.hasFlag(__traits(getMember, T, member)))
        {
            string str;
            foreach (m; Children!T)
            {
                if (val.hasFlag(__traits(getMember, T, m)))
                    str ~= m~" | ";
            }
            return str[0 .. $-3];
        }
    }
    return Children!T[0];
}

@nogc:
/**
 * Checks if a value has a specific flag set.
 *
 * Params:
 *  value = The value to check for the flag.
 *  flag = The flag to check within the value.
 *
 * Returns:
 *  A boolean indicating whether the flag is set in the value.
 */
bool hasFlag(T)(T value, T flag)
{
    return (value & flag) != 0;
}

/**
 * Checks if a value's masked portion matches a specific flag.
 *
 * Params:
 *  value = The value to check for the flag match.
 *  mask = The mask to apply to the value.
 *  flag = The flag to match within the masked value.
 *
 * Returns:
 *  A boolean indicating whether the flag matches the masked value.
 */
bool hasFlagMasked(T)(T value, T mask, T flag)
{
    return (value & mask) == flag;
}

/**
 * Sets or clears a flag in a value based on the provided state.
 *
 * Params:
 *  value = Reference to the value where the flag will be modified.
 *  flag = The flag to set or clear.
 *  state = A boolean indicating whether to set or clear the flag.
 */
void setFlag(T)(ref T value, T flag, bool state)
{
    value = cast(T)(state ? (value | flag) : (value & ~flag));
}

/**
 * Toggles a flag in a value.
 *
 * Params:
 *  value = Reference to the value where the flag will be toggled.
 *  flag = The flag to toggle.
 */
void toggleFlag(T)(ref T value, T flag)
{
    value = cast(T)(value ^ flag);
}

/**
 * Sets a flag in a masked value based on the provided state.
 *
 * Params:
 *  value = Reference to the value where the flag will be modified.
 *  mask = The mask to apply to the value.
 *  flag = The flag to set or clear.
 *  state = A boolean indicating whether to set or clear the flag.
 */
void setFlagMasked(T)(ref T value, T mask, T flag, bool state)
{
    value = cast(T)(state ? (value & mask) | flag : (value & mask) & ~flag);
}

/**
 * Toggles a flag within a masked value.
 *
 * Params:
 *  value = Reference to the value where the flag will be toggled.
 *  mask = The mask to apply to the value.
 *  flag = The flag to toggle within the masked value.
 */
void toggleFlagMasked(T)(ref T value, T mask, T flag)
{
    value = cast(T)((value & mask) ^ flag);
}

/**
 * Clears a mask from the provided value.
 *
 * Params:
 *  value = The value from which the mask will be cleared.
 *  mask = The mask to clear from the value.
 *
 * Returns:
 *  The value after clearing the specified mask.
 */
T clearMask(T)(T value, T mask)
{
    return cast(T)(value & ~mask);
}