module Test.ZERO.Interpreter exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import ZERO.Interpreter as I exposing (Value(..))


suite : Test
suite =
    describe "ZERO.Interpreter"
        [ describe "run" <|
            List.map (testRun I.run)
                -- Constant expressions
                [ ( "123", SucceedsWith (VNumber 123) )
                , ( "123 ", SucceedsWith (VNumber 123) )
                , ( "123  ", SucceedsWith (VNumber 123) )
                , ( " 123", SucceedsWith (VNumber 123) )
                , ( "  123", SucceedsWith (VNumber 123) )
                , ( "123abc", SyntaxError )
                , ( "onetwothree", SyntaxError )

                -- Difference expressions
                , ( "-(456,123)", SucceedsWith (VNumber 333) )
                , ( "-(456, 123)", SucceedsWith (VNumber 333) )
                , ( "- ( 2, -( 4, 3 ) )", SucceedsWith (VNumber 1) )
                , ( """
                    -(
                        -(5 , 3),
                        -(0 , 1)
                    )
                    """
                  , SucceedsWith (VNumber 3)
                  )
                , ( "-(zero?(0), 1)"
                  , RuntimeError <|
                        I.TypeError
                            { expected = [ I.TNumber, I.TNumber ]
                            , actual = [ I.TBool, I.TNumber ]
                            }
                  )
                , ( "-(0, zero?(1))"
                  , RuntimeError <|
                        I.TypeError
                            { expected = [ I.TNumber, I.TNumber ]
                            , actual = [ I.TNumber, I.TBool ]
                            }
                  )
                , ( "-(zero?(0), zero?(1))"
                  , RuntimeError <|
                        I.TypeError
                            { expected = [ I.TNumber, I.TNumber ]
                            , actual = [ I.TBool, I.TBool ]
                            }
                  )

                -- Is it zero?
                , ( "zero?(0)", SucceedsWith (VBool True) )
                , ( "zero?( 0 ) ", SucceedsWith (VBool True) )
                , ( """
                    zero?(
                        -( 0
                         , 1
                         )
                    )
                    """
                  , SucceedsWith (VBool False)
                  )
                , ( "zero?(zero?(0))"
                  , RuntimeError <|
                        I.TypeError
                            { expected = [ I.TNumber ]
                            , actual = [ I.TBool ]
                            }
                  )
                ]
        ]


type Expected a
    = SucceedsWith a
    | SyntaxError
    | RuntimeError I.RuntimeError


testRun : (String -> Result I.Error a) -> ( String, Expected a ) -> Test
testRun f ( input, expectedOutput ) =
    test (Debug.toString input) <|
        \_ ->
            case ( f input, expectedOutput ) of
                ( Ok actual, SucceedsWith expected ) ->
                    if actual == expected then
                        Expect.pass

                    else
                        Expect.fail <|
                            Debug.toString
                                { expected = expected
                                , actual = actual
                                }

                ( Err (I.SyntaxError _), SyntaxError ) ->
                    Expect.pass

                ( Err (I.RuntimeError actual), RuntimeError expected ) ->
                    if actual == expected then
                        Expect.pass

                    else
                        Expect.fail <|
                            Debug.toString
                                { expected = expected
                                , actual = actual
                                }

                ( actual, expected ) ->
                    Expect.fail <|
                        Debug.toString
                            { expected = expected
                            , actual = actual
                            }
