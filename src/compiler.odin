package olox

import "core:fmt"
import "core:strconv"


parser : Parser

compiling_chunk: ^Chunk

Parser :: struct {
        current, previous: Token,
        had_error        : bool ,
        panic_mode       : bool ,
}

Precedence :: enum {
        None      ,
        Assignment, // =
        Or        , // or
        And       , // and
        Equality  , // == !=
        Comparison, // < > <= >=
        Term      , // + -
        Factor    , // * /
        Unary     , // ! -
        Call      , // . ()
        Primary   ,
}

ParserRule :: struct {
        prefix, infix: proc(),
        precedence   : Precedence,
}

RULES := map[TokenType]ParserRule {
        .LeftParen    = {grouping      , nil          , .None      },
        .RightParen   = {nil           , nil          , .None      },
        .LeftBrace    = {nil           , nil          , .None      },
        .RightBrace   = {nil           , nil          , .None      },
        .Comma        = {nil           , nil          , .None      },
        .Dot          = {nil           , nil          , .None      },
        .Minus        = {parser_unary  , parser_binary, .Term      },
        .Plus         = {nil           , parser_binary, .Term      },
        .Semicolon    = {nil           , nil          , .None      },
        .Slash        = {nil           , parser_binary, .Factor    },
        .Star         = {nil           , parser_binary, .Factor    },
        .Bang         = {parser_unary  , nil          , .None      },
        .BangEqual    = {nil           , parser_binary, .Equality  },
        .Equal        = {nil           , nil          , .None      },
        .EqualEqual   = {nil           , parser_binary, .Comparison},
        .Greater      = {nil           , parser_binary, .Comparison},
        .GreaterEqual = {nil           , parser_binary, .Comparison},
        .Less         = {nil           , parser_binary, .Comparison},
        .LessEqual    = {nil           , parser_binary, .Comparison},
        .Identifier   = {nil           , nil          , .None      },
        .String       = {nil           , nil          , .None      },
        .Number       = {parser_number , nil          , .None      },
        .And          = {nil           , nil          , .None      },
        .Class        = {nil           , nil          , .None      },
        .Else         = {nil           , nil          , .None      },
        .False        = {parser_literal, nil          , .None      },
        .For          = {nil           , nil          , .None      },
        .Fun          = {nil           , nil          , .None      },
        .If           = {nil           , nil          , .None      },
        .Nil          = {parser_literal, nil          , .None      },
        .Or           = {nil           , nil          , .None      },
        .Print        = {nil           , nil          , .None      },
        .Return       = {nil           , nil          , .None      },
        .Super        = {nil           , nil          , .None      },
        .This         = {nil           , nil          , .None      },
        .True         = {parser_literal, nil          , .None      },
        .Var          = {nil           , nil          , .None      },
        .While        = {nil           , nil          , .None      },
        .Error        = {nil           , nil          , .None      },
        .Eof          = {nil           , nil          , .None      },
}

compile :: proc(source: string, chunk: ^Chunk) -> bool {
        scanner_init(source)
        defer scanner_free()

        compiling_chunk = chunk

        parser.had_error  = false
        parser.panic_mode = false

        parser_advance()
        parser_expression()
        parser_consume(.Eof, "Expect end of expression")
        compiler_end()
        return !parser.had_error
}

parser_advance :: proc() {
        parser.previous = parser.current

        for {
                next_token, err := scan_token()
                parser.current   = next_token

                if err == .Ok do break

                error_at_current(get_lexeme(&parser.current))
        }
}

parser_consume :: proc(type: TokenType, msg: string) {
        // had to create the .Error TokenType for this function, as a scan
        // error returns a default token, with a previously default type of
        // .LeftParen, thereby passing this type check as one. .Error is now
        // the default token type

        if parser.current.type == type {
                parser_advance()
                return
        }

        error_at_current(msg)
}

parser_current_chunk :: proc() -> ^Chunk {
        return compiling_chunk
}

emit_byte :: proc(b: $T)
        where T == byte || T == OpCode {
        chunk_write(parser_current_chunk(), b, parser.previous.line)
}

emit_bytes :: proc(byte1: OpCode, byte2: $T)
        where T == byte || T == OpCode {
        emit_byte(byte1)
        emit_byte(byte2)
}

emit_return :: proc() {
        emit_byte(OpCode.Return)
}

emit_constant :: proc(value: Value) {
        constant := make_constant(value)

        if constant < 256 do emit_bytes(.Constant, byte(constant))
        else {
                bytes := int_to_byte3(constant)
                emit_byte(OpCode.ConstantLong)
                emit_byte(bytes[0])
                emit_byte(bytes[1])
                emit_byte(bytes[1])
        }
}

make_constant :: proc(value: Value) -> int {
        return chunk_add_constant(parser_current_chunk(), value)
}

compiler_end :: proc() {
        emit_return()

        when ODIN_DEBUG {
                if !parser.had_error do disassemble_chunk(parser_current_chunk(), "code")
        }
}

grouping :: proc() {
        parser_expression()
        parser_consume(.RightParen, "Expect ')' after expression.")
}

parser_number :: proc() {
        lexeme    := get_lexeme(&parser.previous)
        value, ok := strconv.parse_f64(lexeme)

        assert(ok, fmt.tprint("Error parsing number:", lexeme))

        emit_constant(value)
}

parser_expression :: proc() {
        parse_precedence(.Assignment)
}

parser_get_rule :: proc(operator_type: TokenType) -> ParserRule {
        rule, ok := RULES[operator_type]
        assert(ok, fmt.tprintf("ParserRule not found for operator %v", operator_type))
        return rule
}

parser_unary :: proc() {
        operator_type := parser.previous.type

        parse_precedence(.Unary)

        #partial switch operator_type {
        case .Bang : emit_byte(OpCode.Not)
        case .Minus: emit_byte(OpCode.Negate)
        }
}

parser_binary :: proc() {
        operator_type := parser.previous.type
        rule          := parser_get_rule(operator_type)

        parse_precedence(Precedence(int(rule.precedence)+1))

        #partial switch operator_type {
        case .BangEqual   : emit_bytes(OpCode.Equal   , OpCode.Not)
        case .EqualEqual  : emit_byte (OpCode.Equal               )
        case .Greater     : emit_byte (OpCode.Greater             )
        case .GreaterEqual: emit_bytes(OpCode.Less    , OpCode.Not)
        case .Less        : emit_byte (OpCode.Less                )
        case .LessEqual   : emit_bytes(OpCode.Greater , OpCode.Not)
        case .Plus        : emit_byte (OpCode.Add                 )
        case .Minus       : emit_byte (OpCode.Subtract            )
        case .Star        : emit_byte (OpCode.Multiply            )
        case .Slash       : emit_byte (OpCode.Divide              )
        }
}

parser_literal :: proc() {
        #partial switch parser.previous.type {
        case .Nil  : emit_byte(OpCode.Nil)
        case .True : emit_byte(OpCode.True)
        case .False: emit_byte(OpCode.False)
        }
}

parse_precedence :: proc(precedence: Precedence) {
        parser_advance()

        prefix_rule := parser_get_rule(parser.previous.type).prefix
        if prefix_rule == nil {
                error("Expect expression.")
                return
        }

        prefix_rule()

        for precedence <= parser_get_rule(parser.current.type).precedence {
                parser_advance()
                infix_rule := parser_get_rule(parser.previous.type).infix
                if infix_rule != nil do infix_rule()
        }
}

error_at_current :: proc(msg: string) {
        error_at(&parser.current, msg)
}

error :: proc(msg: string) {
        error_at(&parser.previous, msg)
}

error_at :: proc(token: ^Token, msg: string) {
        if parser.panic_mode do return
        parser.panic_mode = true

        fmt.eprintf("[line %d] Error", token.line)

        switch {
        case token.type == .Eof: fmt.eprint(" at end")
        case token.length >= 0 : fmt.eprint(" at", get_lexeme(token))
        }

        fmt.eprintln(":", msg)
}
