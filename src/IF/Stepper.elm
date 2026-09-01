module IF.Stepper exposing
    ( Control(..)
    , Kont(..)
    , RuntimeError(..)
    , State
    , StepResult(..)
    , SyntaxError
    , Type(..)
    , Value(..)
    , start
    , stateToString
    , step
    , valueToString
    )

import IF.AST as AST exposing (..)
import IF.Parser as P


type Value
    = VNumber Number
    | VBool Bool


type alias SyntaxError =
    P.Error


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
    | Bad RuntimeError


type Kont
    = Done
    | DiffLeft (Located Expr) Kont
    | DiffRight Value Kont
    | ZeroOperand Kont
    | IfCondition (Located Expr) (Located Expr) Kont


type StepResult
    = Continue State
    | Halt (Result RuntimeError Value)


start : String -> Result SyntaxError State
start input =
    case P.parse input of
        Ok (Program expr) ->
            Ok { control = Evaluate expr, k = Done }

        Err err ->
            Err err


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


stateToString : State -> String
stateToString { control, k } =
    case control of
        Evaluate expr ->
            stateToStringHelper ("[" ++ exprToString expr.value ++ "]") False k

        Good value ->
            stateToStringHelper ("{" ++ valueToString value ++ "}") True k

        Bad _ ->
            "Bad"


highlight : Bool -> String -> String
highlight b s =
    if b then
        "[" ++ s ++ "]"

    else
        s


stateToStringHelper : String -> Bool -> Kont -> String
stateToStringHelper s h k =
    case k of
        Done ->
            s

        DiffLeft b nextK ->
            stateToStringHelper
                (highlight h <| "-(" ++ s ++ ", " ++ exprToString b.value ++ ")")
                False
                nextK

        DiffRight va nextK ->
            stateToStringHelper
                (highlight h <| "-(" ++ valueToString va ++ ", " ++ s ++ ")")
                False
                nextK

        ZeroOperand nextK ->
            stateToStringHelper
                (highlight h <| "zero?(" ++ s ++ ")")
                False
                nextK

        IfCondition consequent alternative nextK ->
            stateToStringHelper
                (highlight h <| "if " ++ s ++ " then " ++ exprToString consequent.value ++ " else " ++ exprToString alternative.value)
                False
                nextK


exprToString : Expr -> String
exprToString expr =
    case expr of
        Const n ->
            String.fromInt n.value

        Diff a b ->
            "-(" ++ exprToString a.value ++ ", " ++ exprToString b.value ++ ")"

        Zero a ->
            "zero?(" ++ exprToString a.value ++ ")"

        If condition consequent alternative ->
            "if " ++ exprToString condition.value ++ " then " ++ exprToString consequent.value ++ " else " ++ exprToString alternative.value


valueToString : Value -> String
valueToString value =
    case value of
        VNumber n ->
            String.fromInt n

        VBool b ->
            if b then
                "true"

            else
                "false"
