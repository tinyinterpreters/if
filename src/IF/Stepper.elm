module IF.Stepper exposing
    ( Continuation(..)
    , Control(..)
    , RuntimeError(..)
    , State
    , StepResult(..)
    , Type(..)
    , Value(..)
    , start
    , step
    , stepResultToString
    )

import IF.AST as AST exposing (..)


type Value
    = VNumber Number
    | VBool Bool


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
    , k : Continuation
    }


type Control
    = Evaluate Expr
    | Return Value
    | Fail RuntimeError


type Continuation
    = Done
    | DiffLeft Expr Continuation
    | DiffRight Value Continuation
    | ZeroOperand Continuation
    | IfCondition Expr Expr Continuation


type StepResult
    = Running State
    | Halted (Result RuntimeError Value)


start : AST.Program -> StepResult
start (Program expr) =
    Running
        { control = Evaluate expr
        , k = Done
        }


step : StepResult -> Maybe StepResult
step result =
    case result of
        Running { control, k } ->
            Just <|
                case control of
                    Evaluate expr ->
                        stepExpr expr k

                    Return value ->
                        applyK value k

                    Fail err ->
                        Halted <| Err err

        Halted _ ->
            Nothing


stepExpr : Expr -> Continuation -> StepResult
stepExpr expr k =
    Running <|
        case expr of
            Const n ->
                { control = Return <| VNumber n
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


applyK : Value -> Continuation -> StepResult
applyK value k =
    case k of
        Done ->
            Halted <| Ok value

        DiffLeft b nextK ->
            Running
                { control = Evaluate b
                , k = DiffRight value nextK
                }

        DiffRight va nextK ->
            Running
                { control = evalDiff va value
                , k = nextK
                }

        ZeroOperand nextK ->
            Running
                { control = evalZero value
                , k = nextK
                }

        IfCondition consequent alternative nextK ->
            Running
                { control = evalIf value consequent alternative
                , k = nextK
                }


evalDiff : Value -> Value -> Control
evalDiff va vb =
    case ( va, vb ) of
        ( VNumber a, VNumber b ) ->
            Return <| VNumber <| a - b

        _ ->
            Fail <|
                TypeError
                    { expected = [ TNumber, TNumber ]
                    , actual = [ typeOf va, typeOf vb ]
                    }


evalZero : Value -> Control
evalZero va =
    case va of
        VNumber a ->
            Return <| VBool <| a == 0

        _ ->
            Fail <|
                TypeError
                    { expected = [ TNumber ]
                    , actual = [ typeOf va ]
                    }


evalIf : Value -> Expr -> Expr -> Control
evalIf vCondition consequent alternative =
    case vCondition of
        VBool True ->
            Evaluate consequent

        VBool False ->
            Evaluate alternative

        _ ->
            Fail <|
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


stepResultToString : StepResult -> String
stepResultToString result =
    case result of
        Running state ->
            stateToString state

        Halted (Ok value) ->
            "Answer = " ++ valueToString False value

        Halted (Err _) ->
            "Type error!"


stateToString : State -> String
stateToString { control, k } =
    case control of
        Evaluate expr ->
            stateToStringHelper ("[" ++ exprToString expr ++ "]") False k

        Return value ->
            stateToStringHelper (valueToString True value) True k

        Fail _ ->
            stateToStringHelper "{Type error}" True k


stateToStringHelper : String -> Bool -> Continuation -> String
stateToStringHelper s shouldWrap k =
    case k of
        Done ->
            s

        DiffLeft b nextK ->
            stateToStringHelper
                (highlightIf shouldWrap <| "-(" ++ s ++ ", " ++ exprToString b ++ ")")
                False
                nextK

        DiffRight va nextK ->
            stateToStringHelper
                (highlightIf shouldWrap <| "-(" ++ valueToString True va ++ ", " ++ s ++ ")")
                False
                nextK

        ZeroOperand nextK ->
            stateToStringHelper
                (highlightIf shouldWrap <| "zero?(" ++ s ++ ")")
                False
                nextK

        IfCondition consequent alternative nextK ->
            stateToStringHelper
                (highlightIf shouldWrap <| "if " ++ s ++ " then " ++ exprToString consequent ++ " else " ++ exprToString alternative)
                False
                nextK


highlightIf : Bool -> String -> String
highlightIf shouldWrap s =
    if shouldWrap then
        "[" ++ s ++ "]"

    else
        s


exprToString : Expr -> String
exprToString expr =
    case expr of
        Const n ->
            String.fromInt n

        Diff a b ->
            "-(" ++ exprToString a ++ ", " ++ exprToString b ++ ")"

        Zero a ->
            "zero?(" ++ exprToString a ++ ")"

        If condition consequent alternative ->
            "if " ++ exprToString condition ++ " then " ++ exprToString consequent ++ " else " ++ exprToString alternative


valueToString : Bool -> Value -> String
valueToString shouldWrap value =
    let
        inner =
            case value of
                VNumber n ->
                    String.fromInt n

                VBool b ->
                    if b then
                        "true"

                    else
                        "false"
    in
    if shouldWrap then
        "{" ++ inner ++ "}"

    else
        inner
