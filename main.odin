package olox

main :: proc() {
        chunk: Chunk
        constant := add_constant(&chunk, 1.2)
        write_chunk(&chunk, OpCode.Constant,123)
        write_chunk(&chunk, byte(constant), 123) 
        write_chunk(&chunk, OpCode.Return,  123)
        disassemble_chunk(&chunk, "test chunk")
        free_chunk(&chunk)
}
