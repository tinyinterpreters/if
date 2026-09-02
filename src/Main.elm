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
    { maybePreset : Maybe Preset
    , source : String
    , phase : Phase
    }


type Phase
    = Editing
    | Ready AST.Program
    | Stepping AST.Program Stepper.StepResult
    | Finished AST.Program Stepper.StepResult


isRunning : Phase -> Bool
isRunning phase =
    case phase of
        Stepping _ (Stepper.Running _) ->
            True

        _ ->
            False


init : Model
init =
    setPreset defaultPreset
        { maybePreset = Nothing
        , source = ""
        , phase = Editing
        }


setPreset : Preset -> Model -> Model
setPreset preset model =
    setSource preset.source { model | maybePreset = Just preset }


setSource : String -> Model -> Model
setSource source model =
    { model
        | source = source
        , phase =
            case P.parse source of
                Ok program ->
                    Ready program

                Err _ ->
                    Editing
    }



-- UPDATE


type Msg
    = PresetChanged String
    | SourceChanged String
    | StartClicked
    | StepClicked


update : Msg -> Model -> Model
update msg model =
    case msg of
        PresetChanged id ->
            case findPreset id defaultPresets of
                Just preset ->
                    setPreset preset model

                Nothing ->
                    model

        SourceChanged source ->
            setSource source model

        StartClicked ->
            case model.phase of
                Ready program ->
                    { model | phase = Stepping program <| Stepper.start program }

                Finished program _ ->
                    { model | phase = Stepping program <| Stepper.start program }

                _ ->
                    model

        StepClicked ->
            case model.phase of
                Stepping program result ->
                    case Stepper.step result of
                        Just nextResult ->
                            case nextResult of
                                Stepper.Running _ ->
                                    { model | phase = Stepping program nextResult }

                                Stepper.Halted _ ->
                                    { model | phase = Finished program nextResult }

                        Nothing ->
                            model

                _ ->
                    model



-- VIEW


view : Model -> Html Msg
view { maybePreset, source, phase } =
    H.div
        [ HA.style "margin" "20px" ]
        [ H.h1 [] [ H.text "IF Stepper" ]
        , viewPresets maybePreset (isRunning phase)
        , H.textarea
            [ HA.rows 10
            , HA.cols 40
            , HA.placeholder "if zero?(0) then 2 else 3"
            , HA.spellcheck False
            , HA.value source
            , HA.disabled (isRunning phase)
            , HE.onInput SourceChanged
            ]
            []
        , H.p []
            [ H.button
                [ HA.type_ "button"
                , HA.disabled <|
                    case phase of
                        Ready _ ->
                            False

                        Stepping _ (Stepper.Running _) ->
                            False

                        Finished _ _ ->
                            False

                        _ ->
                            True
                , case phase of
                    Ready _ ->
                        HE.onClick StartClicked

                    Stepping _ (Stepper.Running _) ->
                        HE.onClick StepClicked

                    Finished _ _ ->
                        HE.onClick StartClicked

                    _ ->
                        HA.class ""
                ]
                [ H.text <|
                    case phase of
                        Stepping _ _ ->
                            "Step"

                        _ ->
                            "Start"
                ]
            ]
        , H.p []
            [ H.text <|
                case phase of
                    Stepping _ result ->
                        Stepper.stepResultToString result

                    Finished _ result ->
                        Stepper.stepResultToString result

                    _ ->
                        ""
            ]
        ]


viewPresets : Maybe Preset -> Bool -> Html Msg
viewPresets maybePreset isDisabled =
    let
        maybePresetId =
            maybePreset
                |> Maybe.map .id
    in
    H.p []
        [ H.select
            [ HA.disabled isDisabled
            , if isDisabled then
                HA.class ""

              else
                HE.onInput PresetChanged
            ]
            (List.map
                (\{ id, name } ->
                    H.option
                        [ HA.value id
                        , HA.selected (Just id == maybePresetId)
                        ]
                        [ H.text name ]
                )
                defaultPresets
            )
        ]



-- HELPERS


type alias Preset =
    { id : String
    , name : String
    , source : String
    }


defaultPreset : Preset
defaultPreset =
    { id = "if3"
    , name = "Nested conditionals"
    , source =
        """if zero?(0) then
    if zero?(1) then 2 else 4
else
    if zero?(3) then 5 else 7"""
    }


defaultPresets : List Preset
defaultPresets =
    [ { id = "const"
      , name = "Constant"
      , source = "123"
      }
    , { id = "diff1"
      , name = "Difference"
      , source = "-(456, 123)"
      }
    , { id = "diff2"
      , name = "Nested difference"
      , source = "-(2, -(4, 3))"
      }
    , { id = "diff3"
      , name = "Multiline difference"
      , source =
            """-(
    -(5, 3),
    -(0, 1)
)"""
      }
    , { id = "zero1"
      , name = "Zero is true"
      , source = "zero?(-(1, 1))"
      }
    , { id = "zero2"
      , name = "Nonzero is false"
      , source = "zero?(-(1, 2))"
      }
    , { id = "zero3"
      , name = "Zero type error"
      , source = "zero?(zero?(0))"
      }
    , { id = "zero4"
      , name = "Difference type error"
      , source = "-(zero?(0), 1)"
      }
    , { id = "if1"
      , name = "True condition"
      , source = "if zero?(0) then 2 else 3"
      }
    , { id = "if2"
      , name = "False condition"
      , source = "if zero?(1) then 2 else 3"
      }
    , defaultPreset
    , { id = "if4"
      , name = "Condition type error"
      , source = "if 0 then 2 else 3"
      }
    , { id = "if5"
      , name = "Different branch types"
      , source = "if zero?(0) then 2 else zero?(3)"
      }
    , { id = "if6"
      , name = "Skip else branch"
      , source = "if zero?(0) then 2 else -(zero?(0), 1)"
      }
    , { id = "if7"
      , name = "Skip then branch"
      , source = "if zero?(1) then -(zero?(0), 1) else 3"
      }
    ]


findPreset : String -> List Preset -> Maybe Preset
findPreset id presets =
    case presets of
        [] ->
            Nothing

        preset :: restOfPresets ->
            if id == preset.id then
                Just preset

            else
                findPreset id restOfPresets
