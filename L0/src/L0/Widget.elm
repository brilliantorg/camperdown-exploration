module L0.Widget exposing (bargraph, sum)

import Dict exposing (Dict)
import Element as E exposing (column, el, paragraph, px, row, spacing, text)
import Element.Font as Font
import L0.MExpression exposing (MExpression(..))
import L0.Utility as Utility
import List.Extra
import Maybe.Extra
import SimpleGraph exposing (Option(..), barChart, lineChart, scatterPlot)


sum : List String -> MExpression -> E.Element msg
sum args body =
    let
        numbers_ =
            Utility.getTextList body

        numbers =
            List.map String.toFloat numbers_ |> Maybe.Extra.values

        sum_ =
            List.sum numbers

        precision =
            Utility.getPrecisionWithDefault 2 args
    in
    row [ spacing 8 ] (text "sum" :: List.map text numbers_ ++ [ text "=" ] ++ [ text (String.fromFloat (Utility.roundTo precision sum_)) ])



--
--average : FRender CYTMsg
--average renderArgs name args body sm =
--    let
--        numbers_ =
--            Render.Utility.getTextList body
--
--        numbers =
--            List.map String.toFloat numbers_ |> Maybe.Extra.values
--
--        average_ =
--            meanOfList numbers
--
--        precision =
--            Render.Utility.getPrecisionWithDefault 2 args
--    in
--    row [ spacing 8 ] (text "average" :: List.map text numbers_ ++ [ text "=" ] ++ [ text (String.fromFloat (Utility.roundTo precision average_)) ])
--
--
--meanOfList : List Float -> Float
--meanOfList xs =
--    let
--        n =
--            toFloat (List.length xs)
--    in
--    List.sum xs / n
--
--
--stdev : FRender CYTMsg
--stdev renderArgs name args body sm =
--    let
--        numbers_ =
--            Render.Utility.getTextList body
--
--        numbers : List Float
--        numbers =
--            List.map String.toFloat numbers_ |> Maybe.Extra.values
--
--        n =
--            toFloat (List.length numbers)
--
--        sum_ =
--            List.sum numbers
--
--        average_ =
--            sum_ / n
--
--        deltas =
--            List.map (\x -> x - average_) numbers
--
--        sumOfDeltasSquared =
--            List.map2 (*) deltas deltas |> List.sum
--
--        stdev_ =
--            sqrt sumOfDeltasSquared / (n - 1)
--
--        precision =
--            Render.Utility.getPrecisionWithDefault 2 args
--    in
--    row [ spacing 8 ] (text "stdev" :: List.map text numbers_ ++ [ text "=" ] ++ [ text (String.fromFloat (Utility.roundTo precision stdev_)) ])
--
--
--stdevOfList : List Float -> Float
--stdevOfList xs =
--    let
--        n =
--            toFloat (List.length xs)
--
--        mean =
--            meanOfList xs
--
--        deltas =
--            List.map (\x -> x - mean) xs
--
--        sumOfDeltasSquared =
--            List.map2 (*) deltas deltas |> List.sum
--    in
--    sqrt sumOfDeltasSquared / (n - 1)
--
--
--
---- DATA
--


bargraph args body =
    let
        dict =
            Utility.keyValueDict args

        numbers : List Float
        numbers =
            getColumn dict body
                |> List.map (\x -> x + 0.5)

        dataMax =
            List.maximum numbers |> Maybe.withDefault 0

        dataMin =
            List.minimum numbers |> Maybe.withDefault 0

        n =
            List.length numbers |> toFloat

        graphHeight =
            200.0

        graphWidth =
            300.0

        deltaX =
            graphWidth / n

        options =
            [ Color "rgb(200,0,0)", DeltaX deltaX, YTickmarks 6, XTickmarks (round (n + 1)), Scale 1.0 1.0 ]

        barGraphAttributes =
            { graphHeight = graphHeight
            , graphWidth = graphWidth
            , options = options
            }
    in
    column []
        [ barChart barGraphAttributes (List.map (\x -> x + 0.001) numbers) |> E.html
        , captionElement dict
        , paragraph [ spacing 12 ]
            [ text ("data points: " ++ String.fromFloat n ++ ", ")
            , text ("min: " ++ String.fromFloat (Utility.roundTo 2 dataMin) ++ ", ")
            , text ("max: " ++ String.fromFloat (Utility.roundTo 2 dataMax))
            ]
        ]


getColumn : Dict String String -> MExpression -> List Float
getColumn dict body =
    let
        toInt_ : Int -> String -> Int
        toInt_ default str =
            String.toInt str |> Maybe.withDefault default

        col =
            case Dict.get "column" dict of
                Just i ->
                    toInt_ 0 i - 1

                _ ->
                    0

        cutoff =
            Dict.get "cutoff" dict |> Maybe.andThen String.toFloat

        rawData : List (List String)
        rawData =
            getCSV body

        getDataColumn : Int -> List (List String) -> List (Maybe String)
        getDataColumn i data =
            List.map (\column -> List.Extra.getAt i column) rawData

        filter data_ =
            case cutoff of
                Just cutoffValue ->
                    List.filter (\x -> x < cutoffValue) data_

                _ ->
                    data_
    in
    body
        |> getCSV
        |> getDataColumn col
        |> Maybe.Extra.values
        |> List.map String.toFloat
        |> Maybe.Extra.values
        |> filter


getCSV : MExpression -> List (List String)
getCSV element =
    case element of
        MList list_ ->
            Utility.getTextList2 list_

        _ ->
            [ [] ]


captionElement dict =
    case Dict.get "caption" dict of
        Just caption ->
            E.paragraph [ Font.bold ] [ E.text caption ]

        Nothing ->
            E.none



--
--linegraph : FRender CYTMsg
--linegraph renderArgs name args body sm =
--    let
--        dict =
--            Utility.keyValueDict args
--
--        numbers_ : List (List String)
--        numbers_ =
--            Render.Utility.getCSV body
--
--        points : List ( Float, Float )
--        points =
--            List.map (List.map String.toFloat) numbers_
--                |> List.map Maybe.Extra.values
--                |> List.map Render.Utility.makePair
--                |> Maybe.Extra.values
--
--        n =
--            List.length points |> toFloat
--
--        graphHeight =
--            200.0
--
--        graphWidth =
--            350.0
--
--        deltaX =
--            graphWidth / n
--
--        options =
--            [ Color "rgb(0,0,200)", DeltaX deltaX, YTickmarks 6, XTickmarks (round (n + 1)), Scale 1.0 1.0 ]
--
--        lineGraphAttributes =
--            { graphHeight = graphHeight
--            , graphWidth = graphWidth
--            , options = options
--            }
--    in
--    column []
--        [ lineChart lineGraphAttributes points |> E.html
--        , Render.Utility.captionElement dict
--        ]
--
--
--scatterplot : FRender CYTMsg
--scatterplot renderArgs name args body sm =
--    let
--        dict =
--            Utility.keyValueDict args
--
--        points =
--            Render.Utility.getPoints dict body
--
--        xmax =
--            List.maximum (List.map Tuple.first points) |> Maybe.withDefault 0
--
--        ymax =
--            List.maximum (List.map Tuple.second points) |> Maybe.withDefault 0
--
--        n =
--            List.length points |> toFloat
--
--        graphHeight =
--            400.0
--
--        graphWidth =
--            400.0
--
--        deltaX =
--            graphWidth / n
--
--        options =
--            [ Color "rgb(0,0,200)", DeltaX deltaX, YTickmarks 6, XTickmarks (round (n + 1)), Scale 1.0 1.0 ]
--
--        scatterPlotAttributes =
--            { graphHeight = graphHeight
--            , graphWidth = graphWidth
--            , options = options
--            }
--
--        points2 =
--            List.map (\( x, y ) -> ( x - 0.03, y )) points
--    in
--    column []
--        [ scatterPlot scatterPlotAttributes points2 |> E.html
--        , Render.Utility.captionElement dict
--        , paragraph [ spacing 12 ]
--            [ text ("data points: " ++ String.fromFloat n ++ ", ")
--            , text ("xmax: " ++ String.fromFloat (Utility.roundTo 0 xmax) ++ ", ")
--            , text ("ymax: " ++ String.fromFloat (Utility.roundTo 0 ymax))
--            ]
--        ]
