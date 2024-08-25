package olox

import "core:fmt"


OpCode :: enum byte {
        Constant,
        ConstantLong,
        Return,
}

Chunk :: struct {
        code     : [dynamic]byte,
        constants: [dynamic]Value,
        lines    : [dynamic]int,
        prev_line: int,
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

        // if line already in RLE array, increment line count
        if chunk.prev_line == line do chunk.lines[len(chunk.lines)-1] += 1

        // else add line and set count to 1
        else {
                append(&chunk.lines, line)
                append(&chunk.lines, 1)
                chunk.prev_line = line
        }
}

free_chunk :: proc(chunk: ^Chunk) {
        clear_dynamic_array(&chunk.code)
        clear_dynamic_array(&chunk.constants)
}

add_constant :: proc(chunk: ^Chunk, value: Value) -> int {
        append(&chunk.constants, value)
        return len(chunk.constants) - 1
}

write_constant :: proc(chunk: ^Chunk, value: Value, line: int) {
        index := add_constant(chunk, value)
        if index < 256 {
                write_chunk_opcode(chunk, OpCode.Constant, line)
                write_chunk_byte(chunk, byte(index), line)
        } else {
                bytes := int_to_byte3(index)
                write_chunk_opcode(chunk, OpCode.ConstantLong, line)
                write_chunk_byte(chunk, bytes[0], line)
                write_chunk_byte(chunk, bytes[1], line)
                write_chunk_byte(chunk, bytes[2], line)
        }        
}
