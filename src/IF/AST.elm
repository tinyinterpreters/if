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
    = Program (Located Expr)


type Expr
    = Const (Located Number)
    | Diff (Located Expr) (Located Expr)
    | Zero (Located Expr)
    | If (Located Expr) (Located Expr) (Located Expr)


type alias Number =
    Int
