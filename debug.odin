package olox

import "core:fmt"


disassemble_chunk :: proc(chunk: ^Chunk, name: string) {
        fmt.printfln("== %s ==", name)

        offset := 0
        for offset < len(chunk.code) {
                offset = disassemble_instruction(chunk, offset)
        }
}

disassemble_instruction :: proc(chunk: ^Chunk, offset: int) -> int {
        fmt.printf("%04d ", offset)

        if offset > 0 && chunk.lines[offset] == chunk.lines[offset-1] {
                fmt.print("   | ")
        }
        else do fmt.printf("%4d ", chunk.lines[offset])

        instruction := OpCode(chunk.code[offset])
        switch instruction {
        case .Constant: return constant_instruction("OP_CONSTANT", chunk, offset)
        case .Return  : return simple_instruction("OP_RETURN", offset)
        case: 
                fmt.println("Unknown opcode", int(instruction))
                return offset + 1
        }
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
        return offset + 2
}
