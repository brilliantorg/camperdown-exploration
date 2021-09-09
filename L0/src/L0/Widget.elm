module L0.Widget exposing (bargraph, sum)

import Dict exposing (Dict)
import Element as E exposing (column, el, paragraph, px, row, spacing, text)
import Element.Font as Font
import L0.ASTTools
import L0.MExpression exposing (MExpression(..))
import L0.Utility as Utility
import List.Extra
import Maybe.Extra
import SimpleGraph exposing (Option(..), barChart, lineChart, scatterPlot)

sumHelper : String -> String -> E.Element msg
sumHelper options str =
    let
        data = String.words str
        value = data |>  List.map String.toFloat |> Maybe.Extra.values |> List.sum
        dict = Utility.keyValueDictFromString options
        precision = Dict.get "precision" dict |> Maybe.andThen String.toInt |> Maybe.withDefault 1
    in
    row [ spacing 8 ] (text "sum" :: List.map text data ++ [ text "=" ] ++ [ text (String.fromFloat (Utility.roundTo precision value)) ])

sum : MExpression -> E.Element msg
sum expr =
    case L0.ASTTools.normalize expr of
        MList [Literal data] -> sumHelper "" data
        MList [MElement "opt" (MList [Literal options]),Literal data] -> sumHelper options data
        _ -> E.el [] (E.text "Bad data for sum")



stringToListOfFloat : String -> List Float
stringToListOfFloat str =
    str
      |> String.split ","
      |> List.map (String.trim >> String.toFloat)
      |> Maybe.Extra.values

bargraph format expr =
    let
        info = case L0.ASTTools.normalize expr of
            MList [Literal rawData] ->
              Just (Dict.empty, stringToListOfFloat (Debug.log "RAW DATA" rawData) )
            MList [MElement "opt" (MList [Literal options]),Literal rawData] ->
              Just (Utility.keyValueDictFromString options, stringToListOfFloat rawData )
            _ -> Nothing
    in
    case info of
        Nothing -> E.el [Font.size 14] (text "Invalid data for bar graph")
        Just (dict, data) ->
            renderBarGraph dict data

renderBarGraph dict data =
    let

        _ = Debug.log "DATA" data

        dataMax =
            List.maximum data |> Maybe.withDefault 0

        dataMin =
            List.minimum data |> Maybe.withDefault 0

        n =
            List.length data |> toFloat

        graphHeight =
            200.0

        graphWidth =
            300.0

        deltaX =
            (graphWidth /(n+1))

        graphOptions =
            [ Color "rgb(200,0,0)", DeltaX deltaX, YTickmarks 6, XTickmarks (round (n + 1)), Scale 1.0 1.0 ]

        barGraphAttributes =
            { graphHeight = graphHeight
            , graphWidth = graphWidth
            , options = graphOptions
            }
    in
    column []
        [ barChart barGraphAttributes (List.map (\x -> x + 0.001) data) |> E.html
        , captionElement dict
        , paragraph [ spacing 12, E.moveRight 32]
            [ text ("data points: " ++ String.fromFloat n ++ ", ")
            , text ("min: " ++ String.fromFloat (Utility.roundTo 2 dataMin) ++ ", ")
            , text ("max: " ++ String.fromFloat (Utility.roundTo 2 dataMax))
            ]
        ]


captionElement dict =
    case Dict.get "caption" dict of
        Just caption ->
            E.paragraph [ Font.bold ] [ E.text caption ]

        Nothing ->
            E.none

