package olox

main :: proc() {
        chunk: Chunk
        for i in 0..=256 do write_constant(&chunk, 12.34, 123)
        write_chunk(&chunk, OpCode.Return, 123)
        disassemble_chunk(&chunk, "test chunk")
        free_chunk(&chunk)
}
