module L0 exposing (..)

import Camperdown.Parse
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import L0.ASTTools
import L0.Config
import L0.MExpression exposing (..)
import Test exposing (..)


parse =
    Camperdown.Parse.parse L0.Config.config


mExpression =
    parse >> .prelude >> List.map (L0.MExpression.fromElement >> L0.ASTTools.normalize)


test : String -> String -> List MExpression -> Test.Test
test label input expectedOutput =
    Test.test label <|
        \_ ->
            mExpression (String.trim input) |> Expect.equal expectedOutput


suite : Test.Test
suite =
    Test.describe "L0 parser"
        [ test "simple element" "[blue flowers]" [ MList [ MElement "blue" (MList [ Literal "flowers" ]) ] ]
        , test "nested elements" "[blue [i flowers]]" [ MList [ MElement "blue" (MList [ MElement "i" (MList [ Literal "flowers" ]) ]) ] ]
        , test "image element with options"
            """[image [opt width:300, caption:'Blue bird'] URL]"""
            [ MList [ MElement "image" (MList [ MElement "opt" (MList [ Literal "width:300, caption:'Blue bird'" ]), Literal "URL" ]) ] ]
        , test "image element with empty options"
            """[image URL]"""
            [ MList [ MElement "image" (MList [ Literal "URL" ]) ] ]
        , test "heading1"
            """[heading1 Introduction to Bird Watching]"""
            [ MList [ MElement "heading1" (MList [ Literal "Introduction to Bird Watching" ]) ] ]
        ]
