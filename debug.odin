package olox

import "core:fmt"

@(private="file")
last_line_written := -1

disassemble_chunk :: proc(chunk: ^Chunk, name: string) {
        fmt.printfln("== %s ==", name)

        offset := 0
        for offset < len(chunk.code) {
                offset = disassemble_instruction(chunk, offset)
        }
}

disassemble_instruction :: proc(chunk: ^Chunk, offset: int) -> int {
        fmt.printf("%04d ", offset)

        line := get_line(chunk, offset)

        if line == last_line_written do fmt.print("   | ")
        else {
                fmt.printf("%4d ", line)
                last_line_written = line
        }

        instruction := OpCode(chunk.code[offset])
        switch instruction {
        case .Constant: return constant_instruction("OP_CONSTANT", chunk, offset)
        case .Return  : return simple_instruction("OP_RETURN", offset)
        case: 
                fmt.println("Unknown opcode", int(instruction))
                return offset + 1
        }
}

get_line :: proc(chunk: ^Chunk, op_index: int) -> int {
        op_count := 0
        for i in 0..<len(chunk.lines)/2 {
                op_count += chunk.lines[i*2+1]
                if op_count > op_index do return chunk.lines[i*2]
        }
        return 0
}

@(private="file")
simple_instruction :: proc(name: string, offset: int) -> int {
        fmt.println(name)
        return offset+1
}

@(private="file")
constant_instruction :: proc(name: string, chunk: ^Chunk, offset: int) -> int {
        constant := chunk.code[offset+1]
        fmt.printf("%-16s %4d '", name, constant)
        value_print(chunk.constants[constant])
        fmt.println("'")
        return offset+2
}
