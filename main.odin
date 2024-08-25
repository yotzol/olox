package olox

main :: proc() {
        chunk: Chunk

        chunk_write(&chunk, Value(1.2), 123)
        chunk_write(&chunk, Value(3.4), 123)
        chunk_write(&chunk, OpCode.Add, 123)

        chunk_write(&chunk, Value(5.6),    123)
        chunk_write(&chunk, OpCode.Divide, 123) 

        chunk_write(&chunk, OpCode.Negate, 123)
        chunk_write(&chunk, OpCode.Return, 123)

        interpret(&chunk)
        chunk_free(&chunk)
}
