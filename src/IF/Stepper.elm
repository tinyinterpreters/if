module IF.Stepper exposing
    ( Error(..)
    , RuntimeError(..)
    , Type(..)
    , Value(..)
    , start
    , step
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


type alias State =
    { control : Control
    , k : Kont
    }


type Control
    = Evaluate (Located Expr)
    | Good Value
    | Bad Error


type Kont
    = Done
    | DiffLeft (Located Expr) Kont
    | DiffRight Value Kont
    | ZeroOperand Kont
    | IfCondition (Located Expr) (Located Expr) Kont


type StepResult
    = Continue State
    | Halt (Result Error Value)


start : String -> State
start input =
    { control =
        case P.parse input of
            Ok (Program locatedExpr) ->
                Evaluate locatedExpr

            Err err ->
                Bad <| SyntaxError err
    , k = Done
    }


step : State -> StepResult
step ({ control, k } as state) =
    case control of
        Evaluate expr ->
            stepExpr expr.value k

        Good value ->
            applyK value k

        Bad err ->
            Halt <| Err err


stepExpr : Expr -> Kont -> StepResult
stepExpr expr k =
    Continue <|
        case expr of
            Const n ->
                { control = Good <| VNumber n.value
                , k = k
                }

            Diff a b ->
                { control = Evaluate a
                , k = DiffLeft b k
                }

            Zero a ->
                { control = Evaluate a
                , k = ZeroOperand k
                }

            If condition consequent alternative ->
                { control = Evaluate condition
                , k = IfCondition consequent alternative k
                }


applyK : Value -> Kont -> StepResult
applyK value k =
    case k of
        Done ->
            Halt <| Ok value

        DiffLeft b nextK ->
            Continue
                { control = Evaluate b
                , k = DiffRight value nextK
                }

        DiffRight va nextK ->
            Continue
                { control = evalDiff va value
                , k = nextK
                }

        ZeroOperand nextK ->
            Continue
                { control = evalZero value
                , k = nextK
                }

        IfCondition consequent alternative nextK ->
            Continue
                { control = evalIf value consequent alternative
                , k = nextK
                }


evalDiff : Value -> Value -> Control
evalDiff va vb =
    case ( va, vb ) of
        ( VNumber a, VNumber b ) ->
            Good <| VNumber <| a - b

        _ ->
            Bad <|
                RuntimeError <|
                    TypeError
                        { expected = [ TNumber, TNumber ]
                        , actual = [ typeOf va, typeOf vb ]
                        }


evalZero : Value -> Control
evalZero va =
    case va of
        VNumber a ->
            Good <| VBool <| a == 0

        _ ->
            Bad <|
                RuntimeError <|
                    TypeError
                        { expected = [ TNumber ]
                        , actual = [ typeOf va ]
                        }


evalIf : Value -> Located Expr -> Located Expr -> Control
evalIf vCondition consequent alternative =
    case vCondition of
        VBool True ->
            Evaluate consequent

        VBool False ->
            Evaluate alternative

        _ ->
            Bad <|
                RuntimeError <|
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
