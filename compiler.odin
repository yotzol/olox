package olox

import "core:fmt"


compile :: proc(source: string) {
        scanner_init(source)
        defer scanner_free()

        line := -1

        for {
                token, err := scan_token()
                if (token.line != line) {
                        fmt.printf("%4d ", token.line)
                        line = token.line
                } else do fmt.print("   | ")

                if err == .Ok do fmt.printf("%-12v '%s'\n", token.type, get_lexeme(token))
                else          do fmt.printf("%-24v'\n", err)

                if token.type == .Eof do break
        }
}
