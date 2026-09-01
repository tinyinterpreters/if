module Main exposing (main)

import Browser as B
import Html as H exposing (Html)
import Html.Attributes as HA
import Html.Events as HE
import IF.AST as AST
import IF.Parser as P
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
    , phase : Phase
    }


type Phase
    = Editing
    | Ready AST.Program
    | Stepping Stepper.StepResult


isRunning : Phase -> Bool
isRunning phase =
    case phase of
        Stepping (Stepper.Running _) ->
            True

        _ ->
            False


init : Model
init =
    { source = ""
    , phase = Editing
    }



-- UPDATE


type Msg
    = SourceChanged String
    | StartClicked
    | StepClicked


update : Msg -> Model -> Model
update msg model =
    case msg of
        SourceChanged source ->
            case P.parse source of
                Ok program ->
                    { model | source = source, phase = Ready program }

                Err _ ->
                    { model | source = source, phase = Editing }

        StartClicked ->
            case model.phase of
                Ready program ->
                    { model | phase = Stepping <| Stepper.start program }

                _ ->
                    model

        StepClicked ->
            case model.phase of
                Stepping result ->
                    case Stepper.step result of
                        Just nextResult ->
                            { model | phase = Stepping nextResult }

                        Nothing ->
                            model

                _ ->
                    model



-- VIEW


view : Model -> Html Msg
view { source, phase } =
    H.div []
        [ H.textarea
            [ HA.rows 10
            , HA.cols 40
            , HA.placeholder "if zero?(0) then 2 else 3"
            , HA.spellcheck False
            , HA.value source
            , HA.disabled (isRunning phase)
            , HE.onInput SourceChanged
            ]
            []
        , H.button
            [ HA.type_ "button"
            , HA.disabled <|
                case phase of
                    Ready _ ->
                        False

                    Stepping (Stepper.Running _) ->
                        False

                    _ ->
                        True
            , case phase of
                Ready _ ->
                    HE.onClick StartClicked

                Stepping (Stepper.Running _) ->
                    HE.onClick StepClicked

                _ ->
                    HA.class ""
            ]
            [ H.text <|
                case phase of
                    Stepping _ ->
                        "Step"

                    _ ->
                        "Start"
            ]
        , H.p []
            [ H.text <|
                case phase of
                    Stepping result ->
                        Stepper.stepResultToString result

                    _ ->
                        ""
            ]
        ]
