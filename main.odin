package olox

main :: proc() {
        chunk: Chunk
        write_constant(&chunk, 1.2, 123)
        write_constant(&chunk, 3.4, 123)
        write_chunk(&chunk, OpCode.Add, 123)
        write_constant(&chunk, 5.6, 123)
        write_chunk(&chunk, OpCode.Divide, 123) 
        write_chunk(&chunk, OpCode.Negate, 123) 
        write_chunk(&chunk, OpCode.Return, 123)
        interpret(&chunk)
        free_chunk(&chunk)
}
