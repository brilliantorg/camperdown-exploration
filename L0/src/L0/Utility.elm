module L0.Utility exposing (..)

import Dict exposing (Dict)
import L0.MExpression exposing (MExpression(..))
import Maybe.Extra


getTextList : MExpression -> List String
getTextList mexpr =
    case mexpr of
        MList list ->
            List.map extractText list
                |> List.map (Maybe.withDefault "")
                |> List.map (String.split ",")
                |> List.map (List.map String.trim)
                |> List.concat

        _ ->
            []


getTextList2 : List MExpression -> List (List String)
getTextList2 mexprList =
    List.map extractText mexprList
        |> List.map (Maybe.withDefault "" >> String.trim)
        |> List.filter (\s -> s /= "")
        |> List.map (String.split ",")
        |> List.map (List.map String.trim)


extractText : MExpression -> Maybe String
extractText mexpr =
    case mexpr of
        Literal content ->
            Just content

        _ ->
            Nothing


getPrecisionWithDefault default args =
    getPrecision args |> Maybe.withDefault default


getPrecision : List String -> Maybe Int
getPrecision args =
    let
        dict =
            keyValueDict args
    in
    Dict.get "precision" dict |> Maybe.andThen String.toInt


keyValueDictFromString : String -> Dict String String
keyValueDictFromString str =
    str |> String.split ","
        |> List.map String.trim
        |> List.map (String.split ":")
        |> List.map (List.map String.trim)
        |> List.map pairFromList
        |> Maybe.Extra.values
        |> Dict.fromList

keyValueDict : List String -> Dict String String
keyValueDict strings_ =
    List.map (String.split ":") strings_
        |> List.map (List.map String.trim)
        |> List.map pairFromList
        |> Maybe.Extra.values
        |> Dict.fromList


pairFromList : List String -> Maybe ( String, String )
pairFromList strings =
    case strings of
        [ x, y ] ->
            Just ( x, y )

        _ ->
            Nothing


roundTo : Int -> Float -> Float
roundTo k x =
    let
        factor =
            10.0 ^ toFloat k
    in
    toFloat (round (factor * x)) / factor
