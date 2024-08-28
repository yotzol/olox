package olox

import "core:unicode/utf8"
import "core:slice"


scanner : Scanner

Scanner :: struct {
        source : []rune,        
        start  : int,
        current: int,
        line   : int,
}

Token :: struct {
        type  : TokenType,
        start : int,
        length: int,
        line  : int,
}

// i chose to use indexes relative to the source rune slice rather than create
// a new lexeme string for each token so as to save memory. however, this
// makes it so you can't provide custom messages for error tokens, so instead
// of error tokens, i made an error enum:

TokenError :: enum {
        Ok,
        UnexpectedCharacter,
        UnterminatedString,
}

TokenType :: enum {
        Error,  // used for token type checking. default enum value 

        // single-character tokens
        LeftParen, RightParen, LeftBrace, RightBrace,
        Comma    , Dot       , Minus    , Plus      ,
        Semicolon, Slash     , Star     ,

        // one or two character tokens
        Bang   , BangEqual   ,
        Equal  , EqualEqual  ,
        Greater, GreaterEqual,
        Less   , LessEqual   ,

        // literals
        Identifier, String, Number,

        // keywords
        And , Class, Else  , False,
        For , Fun  , If    , Nil  ,
        Or  , Print, Return, Super,
        This, True , Var   , While,

        Eof,
}

scanner_init :: proc(source: string) {
        scanner.source  = utf8.string_to_runes(source)
        scanner.start   = 0
        scanner.current = 0
        scanner.line    = 1
}

scanner_free :: proc() {
        delete(scanner.source)
}

scanner_advance :: proc() -> rune {
        scanner.current += 1
        return scanner.source[scanner.current-1]
}

is_at_end :: proc() -> bool {
        return scanner.current >= len(scanner.source)
}

match :: proc(expected: rune) -> bool {
        if is_at_end() do return false
        if (scanner.source[scanner.current] != expected) do return false
        scanner.current += 1
        return true
}

peek :: proc() -> rune {
        if is_at_end() do return 0
        return scanner.source[scanner.current]
}

peek_next :: proc() -> rune {
        if scanner.current+1 >= len(scanner.source) do return 0
        return scanner.source[scanner.current+1]
}

get_lexeme :: proc(token: ^Token) -> string {
        if token.length == 0 do return ""
        return utf8.runes_to_string(scanner.source[token.start : token.start+token.length])
}

skip_whitespace :: proc() {
        for !is_at_end() {
                switch peek() {
                case ' ', '\r', '\t': scanner_advance()
                case '\n':
                        scanner.line += 1
                        scanner_advance()
                case '/':
                        if peek_next() == '/' {
                                for peek() != '\n' && !is_at_end() do scanner_advance()
                        } else do return
                case: return
                }
        }
}

scan_token :: proc() -> (token: Token, err: TokenError) {
        skip_whitespace()

        scanner.start = scanner.current

        token.line    = scanner.line     // set line for default return token in case of a TokenError

        if is_at_end() do return make_token(.Eof), .Ok

        c := scanner_advance()

        if is_alpha(c) do return make_identifier(), .Ok
        if is_digit(c) do return make_number()    , .Ok

        switch c {
        case '(': token = make_token(.LeftParen )
        case ')': token = make_token(.RightParen)
        case '{': token = make_token(.LeftBrace )
        case '}': token = make_token(.RightBrace)
        case ';': token = make_token(.Semicolon )
        case ',': token = make_token(.Comma     )
        case '.': token = make_token(.Dot       )
        case '-': token = make_token(.Minus     )
        case '+': token = make_token(.Plus      )
        case '/': token = make_token(.Slash     )
        case '*': token = make_token(.Star      )
        case '!': token = make_token(.BangEqual    if match('=') else .Bang   )
        case '=': token = make_token(.EqualEqual   if match('=') else .Equal  )
        case '<': token = make_token(.LessEqual    if match('=') else .Less   )
        case '>': token = make_token(.GreaterEqual if match('=') else .Greater)
        case '"': token = make_string() or_return

        case: return token, .UnexpectedCharacter
        }

        return
}

make_token :: proc(type: TokenType) -> Token {
        return {
                type,
                scanner.start,
                scanner.current - scanner.start,
                scanner.line,
        }
}

make_string :: proc() -> (token: Token, err: TokenError) {
        for peek() != '"' && !is_at_end() {
                if peek() == '\n' do scanner.line += 1
                scanner_advance()
        }

        if is_at_end() do return token, .UnterminatedString

        scanner_advance()
        return make_token(.String), .Ok
}

is_digit :: proc(c: rune) -> bool {
        return c >= '0' && c <= '9'
}

make_number :: proc() -> Token {
        for is_digit(peek()) do scanner_advance()

        if peek() == '.' && is_digit(peek_next()) {
                scanner_advance()
                for is_digit(peek()) do scanner_advance()
        }

        return make_token(.Number)
}

is_alpha :: proc(c: rune) -> bool {
        return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= '>') || c == '_'
}

make_identifier :: proc() -> Token {
        for is_alpha(peek()) || is_digit(peek()) do scanner_advance()
        return make_token(identifier_type())
}

// offset 1
rest_and    := utf8.string_to_runes("nd"   )
rest_class  := utf8.string_to_runes("lass" )
rest_else   := utf8.string_to_runes("lse"  )
rest_if     := utf8.string_to_runes("f"    )
rest_nil    := utf8.string_to_runes("il"   )
rest_or     := utf8.string_to_runes("r"    )
rest_print  := utf8.string_to_runes("rint" )
rest_return := utf8.string_to_runes("eturn")
rest_super  := utf8.string_to_runes("uper" )
rest_var    := utf8.string_to_runes("ar"   )
rest_while  := utf8.string_to_runes("hile" )

// offset 2
rest_false  := utf8.string_to_runes("lse"  )
rest_for    := utf8.string_to_runes("r"    )
rest_fun    := utf8.string_to_runes("n"    )
rest_this   := utf8.string_to_runes("is"   )
rest_true   := utf8.string_to_runes("ue"   )

identifier_type :: proc() -> TokenType {
        switch scanner.source[scanner.start] {
        case 'a': return check_keyword(1, 2, rest_and   , .And   )
        case 'c': return check_keyword(1, 4, rest_class , .Class )
        case 'e': return check_keyword(1, 3, rest_else  , .Else  )
        case 'i': return check_keyword(1, 1, rest_if    , .If    )
        case 'n': return check_keyword(1, 2, rest_nil   , .Nil   )
        case 'o': return check_keyword(1, 1, rest_or    , .Or    )
        case 'p': return check_keyword(1, 4, rest_print , .Print )
        case 'r': return check_keyword(1, 5, rest_return, .Return)
        case 's': return check_keyword(1, 4, rest_super , .Super )
        case 'v': return check_keyword(1, 2, rest_var   , .Var   )
        case 'w': return check_keyword(1, 4, rest_while , .While )
        case 'f': 
                switch scanner.current - scanner.start {
                case 3: 
                        switch scanner.source[scanner.start+1] {
                        case 'o': return check_keyword(2, 1, rest_for, .For)
                        case 'u': return check_keyword(2, 1, rest_fun, .Fun)
                        }
                case 5: switch scanner.source[scanner.start+1] {
                        case 'a': return check_keyword(2, 3, rest_false, .False)
                        }
                }
        case 't':
                if scanner.current - scanner.start == 4 {
                        switch peek_next() {
                        case 'h': return check_keyword(2, 2, rest_this, .This)
                        case 'r': return check_keyword(2, 2, rest_true, .True)
                        }
                }
        }

        return .Identifier
}

check_keyword :: proc(start, length: int, rest: []rune, type: TokenType) -> TokenType {
        if scanner.current - scanner.start == start + length {
                if slice.equal(scanner.source[scanner.start+start : scanner.current], rest) {
                        return type
                }
        }
        return .Identifier
}
