package olox

import "core:fmt"


OpCode :: enum byte {
        Constant,
        Return,
}

Chunk :: struct {
        code     : [dynamic]byte,
        constants: [dynamic]Value,
        lines    : [dynamic]int,
}

write_chunk :: proc {
        write_chunk_byte,
        write_chunk_opcode,
}

@(private="file")
write_chunk_opcode :: proc(chunk: ^Chunk, op: OpCode, line: int) {
        write_chunk_byte(chunk, byte(op), line)
}

@(private="file")
write_chunk_byte :: proc(chunk: ^Chunk, b: byte, line: int) {
        append(&chunk.code, b)
        append(&chunk.lines, line)
}

free_chunk :: proc(chunk: ^Chunk) {
        clear_dynamic_array(&chunk.code)
        clear_dynamic_array(&chunk.constants)
}

add_constant :: proc(chunk: ^Chunk, value: Value) -> int {
        append(&chunk.constants, value)
        return len(chunk.constants) - 1
}
