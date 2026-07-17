module IF.Interpreter exposing
    ( Error(..)
    , RuntimeError(..)
    , Type(..)
    , Value(..)
    , run
    )

import IF.AST as AST exposing (..)
import IF.Parser as P


type Value
    = VNumber Number
    | VBool Bool


type Error
    = SyntaxError P.Error
    | RuntimeError RuntimeError


type RuntimeError
    = TypeError
        { expected : List Type
        , actual : List Type
        }


type Type
    = TNumber
    | TBool


run : String -> Result Error Value
run input =
    case P.parse input of
        Ok program ->
            runProgram program
                |> Result.mapError RuntimeError

        Err err ->
            Err <| SyntaxError err


runProgram : AST.Program -> Result RuntimeError Value
runProgram (Program expr) =
    runExpr expr


runExpr : Expr -> Result RuntimeError Value
runExpr expr =
    case expr of
        Const n ->
            Ok <| VNumber n

        Diff a b ->
            runExpr a
                |> Result.andThen
                    (\va ->
                        runExpr b
                            |> Result.andThen
                                (\vb ->
                                    evalDiff va vb
                                )
                    )

        Zero a ->
            runExpr a
                |> Result.andThen
                    (\va ->
                        evalZero va
                    )

        If condition consequent alternative ->
            runExpr condition
                |> Result.andThen
                    (\vCondition ->
                        evalIf vCondition consequent alternative
                    )


evalDiff : Value -> Value -> Result RuntimeError Value
evalDiff va vb =
    case ( va, vb ) of
        ( VNumber a, VNumber b ) ->
            Ok <| VNumber <| a - b

        _ ->
            Err <|
                TypeError
                    { expected = [ TNumber, TNumber ]
                    , actual = [ typeOf va, typeOf vb ]
                    }


evalZero : Value -> Result RuntimeError Value
evalZero va =
    case va of
        VNumber a ->
            Ok <| VBool <| a == 0

        _ ->
            Err <|
                TypeError
                    { expected = [ TNumber ]
                    , actual = [ typeOf va ]
                    }


evalIf : Value -> Expr -> Expr -> Result RuntimeError Value
evalIf vCondition consequent alternative =
    case vCondition of
        VBool True ->
            runExpr consequent

        VBool False ->
            runExpr alternative

        _ ->
            Err <|
                TypeError
                    { expected = [ TBool ]
                    , actual = [ typeOf vCondition ]
                    }


typeOf : Value -> Type
typeOf v =
    case v of
        VNumber _ ->
            TNumber

        VBool _ ->
            TBool
