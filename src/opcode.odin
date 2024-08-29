package olox

OpCode :: enum byte {
        Constant,
        ConstantLong,
        Nil,
        True,
        False,
        Equal,
        Greater,
        Less,
        Add,
        Subtract,
        Multiply,
        Divide,
        Not,
        Negate,
        Return,
}
