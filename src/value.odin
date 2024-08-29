package olox

import "core:fmt"


Nil :: NilType{}

NilType :: distinct struct{}
Bool    :: bool
Number  :: f64

Value :: union {
        NilType,
        Bool,
        Number,
}

value_print :: proc(value: Value) {
        switch type in value {
        case Bool, Number: fmt.print(value)
        case NilType     : fmt.print("nil")
        }
}

value_is_bool :: proc(value: Value) -> bool {
        v, ok := value.(Bool)
        return ok
}

value_is_number :: proc(value: Value) -> bool {
        v, ok := value.(Number)
        return ok
}
