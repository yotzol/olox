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
        case .Constant    : return constant_instruction     ("OP_CONSTANT"     , chunk, offset)
        case .ConstantLong: return constant_long_instruction("OP_CONSTANT_LONG", chunk, offset)
        case .Nil         : return simple_instruction       ("OP_NIL"          ,        offset)
        case .True        : return simple_instruction       ("OP_TRUE"         ,        offset)
        case .False       : return simple_instruction       ("OP_FALSE"        ,        offset)
        case .Equal       : return simple_instruction       ("OP_EQUAL"        ,        offset)
        case .Greater     : return simple_instruction       ("OP_GREATER"      ,        offset)
        case .Less        : return simple_instruction       ("OP_LESS"         ,        offset)
        case .Add         : return simple_instruction       ("OP_ADD"          ,        offset)
        case .Subtract    : return simple_instruction       ("OP_SUBRACT"      ,        offset)
        case .Multiply    : return simple_instruction       ("OP_MULTIPLY"     ,        offset)
        case .Divide      : return simple_instruction       ("OP_DIVIDE"       ,        offset)
        case .Not         : return simple_instruction       ("OP_NOT"          ,        offset)
        case .Negate      : return simple_instruction       ("OP_NEGATE"       ,        offset)
        case .Return      : return simple_instruction       ("OP_RETURN"       ,        offset)
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

@(private="file")
constant_long_instruction :: proc(name: string, chunk: ^Chunk, offset: int) -> int {
        constant := byte3_to_int({chunk.code[offset+1], chunk.code[offset+2], chunk.code[offset+3]})
        fmt.printf("%-16s %4d '", name, constant)
        value_print(chunk.constants[constant])
        fmt.println("'")
        return offset+4
}
