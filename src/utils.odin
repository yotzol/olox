package olox

import "core:fmt"


int_to_byte3 :: proc(value: int) -> [3]byte {
        if value < 0        do fmt.println("Warning: negative value converted to u24")
        if value > 0xFFFFFF do fmt.println("Warning: value truncated to u24")

        return {byte(value >> 16), byte(value >> 8), byte(value)}
}

byte3_to_int :: proc(bytes: [3]byte) -> int {
        return int(bytes[0]) << 16 | int(bytes[1]) << 8 | int(bytes[2])
}
