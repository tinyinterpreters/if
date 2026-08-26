module IF.Parser exposing (Error, parse)

import IF.AST as AST exposing (..)
import IF.Lexer as L
import Parser as P exposing ((|.), (|=), Parser)


type alias Error =
    List P.DeadEnd


parse : String -> Result Error AST.Program
parse =
    P.run program


program : Parser AST.Program
program =
    P.succeed Program
        |. L.spaces
        |= expr
        |. P.end


expr : Parser (Located Expr)
expr =
    P.oneOf
        [ constExpr
        , diffExpr
        , zeroExpr
        , ifExpr
        ]


constExpr : Parser (Located Expr)
constExpr =
    P.map
        (\n ->
            Located
                n.start
                (Const n)
                n.end
        )
        number


number : Parser (Located Number)
number =
    L.digits


diffExpr : Parser (Located Expr)
diffExpr =
    P.succeed
        (\symMinus left right symRightParen ->
            Located
                symMinus.start
                (Diff left right)
                symRightParen.end
        )
        |= L.symbol "-"
        |. L.symbol "("
        |= P.lazy (\_ -> expr)
        |. L.symbol ","
        |= P.lazy (\_ -> expr)
        |= L.symbol ")"


zeroExpr : Parser (Located Expr)
zeroExpr =
    P.succeed
        (\kwdZero testExpr ->
            Located
                kwdZero.start
                (Zero testExpr)
                testExpr.end
        )
        |= L.keyword "zero?"
        |. L.symbol "("
        |= P.lazy (\_ -> expr)
        |. L.symbol ")"


ifExpr : Parser (Located Expr)
ifExpr =
    P.succeed
        (\kwdIf condition consequent alternative ->
            Located
                kwdIf.start
                (If condition consequent alternative)
                alternative.end
        )
        |= L.keyword "if"
        |= P.lazy (\_ -> expr)
        |. L.keyword "then"
        |= P.lazy (\_ -> expr)
        |. L.keyword "else"
        |= P.lazy (\_ -> expr)
