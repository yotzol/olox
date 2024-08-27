package olox

import "core:os"
import "core:fmt"
import "core:strings"
import "core:bufio"


main :: proc() {
        switch len(os.args) {
        case 1: repl()
        case 2: run_file(os.args[1])
        case:
                fmt.eprintln("Usage: olox [path]")
                os.exit(64)
        }
}

repl :: proc() {
        reader: bufio.Reader
        bufio.reader_init(&reader, os.stream_from_handle(os.stdin))
        defer bufio.reader_destroy(&reader)

        for {
                if line, err := bufio.reader_read_string(&reader, '\n'); err == .None {
                        line = strings.trim_right(line, "\r\n")
                        interpret(line)
                }
                else do break
        }
}

run_file :: proc(path: string) {
        data, success := os.read_entire_file_from_filename(path)
        defer delete(data)

        if !success {
                fmt.eprintln("Could not read file ", path)
                os.exit(74)
        }

        result := interpret(string(data))

        switch result {
        case .Ok:           os.exit(0)
        case .CompileError: os.exit(65)
        case .RuntimeError: os.exit(70)
        }
}
