package olox

import "core:fmt"


VM :: struct {
        chunk: ^Chunk,
        ip   : int,
        stack: [dynamic]Value,
}

InterpretResult :: enum {
        Ok,
        CompileError,
        RuntimeError,
}

vm : VM


stack_push :: proc(value: Value) {
        append(&vm.stack, value)
}

stack_pop :: proc() -> Value {
        // pop() itself also asserts non-empty, i'm doing it here just to have an error message
        assert(len(&vm.stack) > 0 , "Stack Underflow")
        return pop(&vm.stack)
}

stack_peek :: proc(distance: int) -> Value {
        assert(distance < len(vm.stack), "Peeked past stack boundary")
        return vm.stack[len(vm.stack)-1 - distance]
}

is_falsey :: proc(value: Value) -> bool {
        return value == Nil || value_is_bool(value) && !value.(Bool)
}

interpret :: proc(source: string) -> InterpretResult {
        chunk: Chunk
        defer chunk_free(&chunk)

        if !compile(source, &chunk) do return .CompileError

        vm.chunk = &chunk
        vm.ip    = 0

        return run()
}

run :: proc() -> InterpretResult {
        for {
                when ODIN_DEBUG {
                        fmt.print("          ");
                        for value in vm.stack {
                                fmt.print("[ ")
                                value_print(value)
                                fmt.print(" ]")
                        }
                        fmt.println()
                        disassemble_instruction(vm.chunk, vm.ip)
                }

                switch OpCode(read_byte()) {
                case .Constant    : stack_push(read_constant())
                case .ConstantLong: stack_push(read_constant_long())
                case .Nil         : stack_push(Nil)
                case .True        : stack_push(true)
                case .False       : stack_push(false)
                case .Equal       : stack_push(stack_pop() == stack_pop())
                case .Less        : stack_binary_op(.Less)
                case .Greater     : stack_binary_op(.Greater)
                case .Add         : stack_binary_op(.Add)
                case .Subtract    : stack_binary_op(.Subtract)
                case .Multiply    : stack_binary_op(.Multiply)
                case .Divide      : stack_binary_op(.Divide) 
                case .Not         : vm.stack[len(vm.stack)-1] = is_falsey(vm.stack[len(vm.stack)-1])
                case .Negate      :
                        if v, ok := stack_peek(0).(Number); ok {
                                vm.stack[len(vm.stack)-1] = -v
                        }
                        else {
                                runtime_error("Operand must be a number.")
                                return .RuntimeError
                        }
                case .Return      : 
                        value_print(stack_pop())
                        fmt.println()
                        return .Ok
                case:
                        runtime_error("Unknown opcode %d", vm.chunk.code[vm.ip-1])
                        return .RuntimeError
                }
        }
}

runtime_error :: proc(format: string, args: ..any) {
        fmt.eprintfln(format, args)
        instruction := vm.ip - 1
        line := get_line(vm.chunk, instruction)
        fmt.eprintfln("[line %d] in script", line)
        clear(&vm.stack)
}

read_byte :: proc() -> byte {
        assert(vm.ip < len(&vm.chunk.code), "No more bytes to read")
        b := vm.chunk.code[vm.ip]
        vm.ip += 1
        return b
}

read_constant :: proc() -> Value {
        index := int(read_byte())
        return vm.chunk.constants[index]
}

read_constant_long :: proc() -> Value {
        index := byte3_to_int({read_byte(), read_byte(), read_byte()})
        return vm.chunk.constants[index]
}

BinaryOp :: enum { Add, Subtract, Multiply, Divide, Less, Greater }

stack_binary_op :: proc(op: BinaryOp) {
        // will fail type assertion if not a number for now
        b, a := stack_pop().(Number), stack_pop().(Number)

        switch op {
        case .Add     : stack_push(a+b)
        case .Subtract: stack_push(a-b)
        case .Multiply: stack_push(a*b)
        case .Divide  : stack_push(a/b)
        case .Less    : stack_push(a<b)
        case .Greater : stack_push(a>b)
        }
}
