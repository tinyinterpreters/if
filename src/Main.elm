module Main exposing (main)

import Browser as B
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import IF.Stepper as Stepper


main : Program () Model Msg
main =
    B.sandbox
        { init = init
        , update = update
        , view = view
        }



-- MODEL


type alias Model =
    { source : String
    , state : State
    }


type State
    = Off
    | Ready Stepper.State
    | Running Stepper.StepResult
    | Success Stepper.Value
    | Failure


isRunning : State -> Bool
isRunning state =
    case state of
        Running _ ->
            True

        _ ->
            False


init : Model
init =
    { source = ""
    , state = Off
    }



-- UPDATE


type Msg
    = EnteredSource String
    | ClickedStart
    | ClickedStep


update : Msg -> Model -> Model
update msg model =
    case msg of
        EnteredSource source ->
            case Stepper.start source of
                Ok state ->
                    { model | source = source, state = Ready state }

                Err _ ->
                    { model | source = source }

        ClickedStart ->
            case model.state of
                Ready stepperState ->
                    { model | state = Running <| Stepper.Continue stepperState }

                _ ->
                    model

        ClickedStep ->
            case model.state of
                Running (Stepper.Continue stepperState) ->
                    { model | state = Running <| Stepper.step stepperState }

                Running (Stepper.Halt result) ->
                    case result of
                        Ok value ->
                            { model | state = Success value }

                        Err _ ->
                            { model | state = Failure }

                _ ->
                    model



-- VIEW


view : Model -> Html Msg
view { source, state } =
    H.div []
        [ H.textarea
            [ HA.rows 10
            , HA.cols 40
            , HA.placeholder "if zero?(0) then 2 else 3"
            , HA.spellcheck False
            , HA.value source
            , HA.disabled (isRunning state)
            , HE.onInput EnteredSource
            ]
            []
        , H.button
            [ HA.type_ "button"
            , HA.disabled <|
                case state of
                    Ready stepperState ->
                        False

                    Running stepResult ->
                        case stepResult of
                            Stepper.Continue _ ->
                                False

                            Stepper.Halt _ ->
                                True

                    _ ->
                        True
            , case state of
                Ready stepperState ->
                    HE.onClick ClickedStart

                Running stepperState ->
                    HE.onClick ClickedStep

                _ ->
                    HA.class ""
            ]
            [ H.text <|
                case state of
                    Off ->
                        "Start"

                    Ready _ ->
                        "Start"

                    _ ->
                        "Step"
            ]
        , H.p []
            [ H.text <|
                case state of
                    Running (Stepper.Continue stepperState) ->
                        Stepper.stateToString stepperState

                    Running (Stepper.Halt result) ->
                        case result of
                            Ok value ->
                                Stepper.valueToString value

                            Err _ ->
                                "Failed!"

                    Success value ->
                        Stepper.valueToString value

                    Failure ->
                        "Failed!"

                    _ ->
                        ""
            ]
        ]
