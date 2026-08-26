module IF.Lexer exposing (digits, keyword, spaces, symbol)

import IF.AST exposing (Located)
import Parser as P exposing ((|.), (|=), Parser)


digits : Parser (Located Int)
digits =
    chompOneOrMore Char.isDigit
        |> P.getChompedString
        |> P.map (Maybe.withDefault 0 << String.toInt)
        |> lexeme


chompOneOrMore : (Char -> Bool) -> Parser ()
chompOneOrMore isGood =
    P.succeed ()
        |. P.chompIf isGood
        |. P.chompWhile isGood


keyword : String -> Parser (Located ())
keyword =
    lexeme << P.keyword


symbol : String -> Parser (Located ())
symbol =
    lexeme << P.symbol


lexeme : Parser a -> Parser (Located a)
lexeme p =
    P.succeed Located
        |= P.getOffset
        |= p
        |= P.getOffset
        |. spaces


spaces : Parser ()
spaces =
    P.spaces
