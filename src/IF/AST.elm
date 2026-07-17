module IF.AST exposing
    ( Expr(..)
    , Number
    , Program(..)
    )


type Program
    = Program Expr


type Expr
    = Const Number
    | Diff Expr Expr
    | Zero Expr
    | If Expr Expr Expr


type alias Number =
    Int
