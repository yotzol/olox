package olox

import "core:fmt"


Chunk :: struct {
        code     : [dynamic]byte,
        constants: [dynamic]Value,
        lines    : [dynamic]int,
        prev_line: int,
}

chunk_write :: proc {
        chunk_write_byte,
        chunk_write_opcode,
        chunk_write_constant, // having this in the same proc can lead to errors rn but will be solved later (e.g.: chunk_write(_, 2, _ will take "2" as a byte, not as a Value)
}

chunk_write_opcode :: proc(chunk: ^Chunk, op: OpCode, line: int) {
        chunk_write_byte(chunk, byte(op), line)
}

chunk_write_byte :: proc(chunk: ^Chunk, b: byte, line: int) {
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

chunk_free :: proc(chunk: ^Chunk) {
        clear_dynamic_array(&chunk.code)
        clear_dynamic_array(&chunk.constants)
}

chunk_add_constant :: proc(chunk: ^Chunk, value: Value) -> int {
        append(&chunk.constants, value)
        return len(chunk.constants) - 1
}

chunk_write_constant :: proc(chunk: ^Chunk, value: Value, line: int) {
        index := chunk_add_constant(chunk, value)
        if index < 256 {
                chunk_write_opcode(chunk, OpCode.Constant, line)
                chunk_write_byte(chunk, byte(index), line)
        } else {
                bytes := int_to_byte3(index)
                chunk_write_opcode(chunk, OpCode.ConstantLong, line)
                chunk_write_byte(chunk, bytes[0], line)
                chunk_write_byte(chunk, bytes[1], line)
                chunk_write_byte(chunk, bytes[2], line)
        }        
}
