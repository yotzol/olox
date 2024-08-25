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

interpret :: proc(chunk: ^Chunk) -> InterpretResult {
        vm.chunk = chunk
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
                case .Add         : stack_binary_op(.Add)
                case .Subtract    : stack_binary_op(.Subtract)
                case .Multiply    : stack_binary_op(.Multiply)
                case .Divide      : stack_binary_op(.Divide) 
                case .Negate      : stack_push(-stack_pop())
                case .Return      : 
                        value_print(stack_pop())
                        fmt.println()
                        return .Ok
                }
        }
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

BinaryOp :: enum { Add, Subtract, Multiply, Divide }

stack_binary_op :: proc(op: enum { Add, Subtract, Multiply, Divide }) {
        b, a := stack_pop(), stack_pop()

        switch op {
        case .Add     : stack_push(a+b)
        case .Subtract: stack_push(a-b)
        case .Multiply: stack_push(a*b)
        case .Divide  : stack_push(a/b)
        }
}
