module L0.View exposing (view)

import Camperdown.Parse.Syntax as Syntax
import Element exposing (..)
import Element.Font as Font
import Html.Attributes
import L0.ASTTools as ASTTools
import L0.L0 as ViewMExpression exposing (Format)
import L0.MExpression as MExpression exposing (MExpression(..))


view : Format -> String -> Syntax.Document -> List (Element.Element msg)
view format _ ({ prelude, sections } as doc) =
    tableOfContents doc :: viewElements format prelude :: List.map (viewSection format) sections


viewHeadingInTOC : MExpression -> Element.Element msg
viewHeadingInTOC expr =
    case expr of
        MElement "heading1" (MList [ Literal heading ]) ->
            el [ Font.size 12 ] (text heading)

        MElement "heading2" (MList [ Literal heading ]) ->
            el [ Font.size 12, paddingXY 18 0 ] (text heading)

        MElement "heading3" (MList [ Literal heading ]) ->
            el [ Font.size 12, paddingXY 36 0 ] (text heading)

        _ ->
            Element.none


tableOfContents : Syntax.Document -> Element.Element msg
tableOfContents doc =
    let
        headings =
            doc
                |> ASTTools.flatten
                |> List.map MExpression.fromElement
                |> MExpression.filter "heading"
                |> Debug.log "headings"
    in
    Element.column [ spacing 8, paddingEach { left = 0, right = 0, top = 0, bottom = 36 } ]
        (el [ Font.bold ] (text "Table of Contents") :: List.map viewHeadingInTOC (List.drop 1 headings))


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
            [ Font.size 22, Font.bold, paddingEach { top = 10, bottom = 12, left = 0, right = 0 } ]

        2 ->
            [ Font.size 18, Font.bold, Font.italic, paddingEach { top = 9, bottom = 10, left = 0, right = 0 } ]

        3 ->
            [ Font.size 16, Font.bold, Font.italic, Font.color (rgb255 50 50 50), paddingEach { top = 8, bottom = 8, left = 0, right = 0 } ]

        _ ->
            [ Font.size 16, Font.bold, Font.italic, Font.color (rgb255 100 100 100), paddingEach { top = 8, bottom = 8, left = 0, right = 0 } ]


paddingBelow =
    paddingEach { top = 0, bottom = 18, right = 0, left = 0 }


sans : Attribute msg
sans =
    Font.family [ Font.typeface "Soleil", Font.typeface "Arial", Font.sansSerif ]
