module IF.AST exposing
    ( Expr(..)
    , Number
    , Program(..)
    , Located
    )


type alias Located a =
    { start : Int
    , value : a
    , end : Int
    }


type Program
    = Program Expr


type Expr
    = Const Number
    | Diff Expr Expr
    | Zero Expr
    | If Expr Expr Expr


type alias Number =
    Int
