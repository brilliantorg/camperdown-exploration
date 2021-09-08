module L0.View exposing (view)

import Camperdown.Parse.Syntax as Syntax
import Element exposing (..)
import Element.Font as Font
import Html.Attributes
import L0.L0 as ViewMExpression exposing (Format)
import L0.MExpression as MExpression exposing (MExpression)


viewSection : Format -> Syntax.Section -> Element.Element msg
viewSection format { level, contents, label } =
    let
        title =
            case label of
                Syntax.Named ( _, s ) ->
                    s

                Syntax.Anonymous n ->
                    "(Passage beginning on line " ++ String.fromInt n ++ ")"

        attrs =
            styleOfLevel level
    in
    column [ width fill ]
        [ el (paddingBelow :: attrs) (text title)
        , column [ sans, width (px format.lineWidth) ] [ viewElements format contents ]
        ]


view : Format -> String -> Syntax.Document -> List (Element.Element msg)
view format _ { prelude, sections } =
    viewElements format prelude :: List.map (viewSection format) sections


viewElements : Format -> List Syntax.Element -> Element.Element msg
viewElements format elements =
    column [ width (px format.lineWidth), spacing 18 ] <| List.map (\element_ -> viewElement format element_) elements


viewElement : Format -> Syntax.Element -> Element.Element msg
viewElement format elem =
    el [ alignLeft ] (ViewMExpression.view format (MExpression.fromElement elem))


styleOfLevel : Int -> List (Element.Attribute msg)
styleOfLevel k =
    case k of
        1 ->
            -- original 18
            [ Font.size 22, Font.bold, paddingEach { top = 10, bottom = 12, left = 0, right = 0 } ]

        2 ->
            -- original 17
            [ Font.size 18, Font.bold, Font.italic, paddingEach { top = 9, bottom = 10, left = 0, right = 0 } ]

        3 ->
            [ Font.size 16, Font.bold, Font.italic, Font.color (rgb255 50 50 50), paddingEach { top = 8, bottom = 8, left = 0, right = 0 } ]

        _ ->
            [ Font.size 16, Font.bold, Font.italic, Font.color (rgb255 100 100 100), paddingEach { top = 8, bottom = 8, left = 0, right = 0 } ]


paddingBelow =
    paddingEach { top = 0, bottom = 18, right = 0, left = 0 }


monospace : Attribute msg
monospace =
    Font.family [ Font.typeface "Source Code Pro", Font.monospace ]


sans : Attribute msg
sans =
    Font.family [ Font.typeface "Soleil", Font.typeface "Arial", Font.sansSerif ]


htmlAttribute : String -> String -> Attribute msg
htmlAttribute key value =
    Element.htmlAttribute (Html.Attributes.attribute key value)
