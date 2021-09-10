module L0.L0 exposing (Format, view)

import CellParserExcel
import Dict exposing (Dict)
import Element exposing (..)
import Element.Font as Font
import Html.Attributes
import L0.ASTTools
import L0.MExpression exposing (MExpression(..))
import L0.Utility as Utility
import L0.Widget as Widget
import Maybe.Extra
import Spreadsheet


type alias Format =
    -- Units = pixels
    { lineWidth : Int, leftPadding : Int, bottomPadding : Int, topPadding : Int }


view : Format -> MExpression -> Element msg
view format mexpr =
    case mexpr of
        Literal str ->
            text str

        Verbatim char str ->
            case char of
                '`' ->
                    viewInlineCode str

                '$' ->
                    unimplemented "Unimplemented: math" str

                _ ->
                    unimplemented "Unimplemented verbatim option" str

        MElement fname mexpr2 ->
            viewElement format fname mexpr2

        MList list_ ->
            paragraph [] (List.map (view format) list_)

        MProblem problem ->
            text ("Problem: " ++ problem)


viewInlineCode str =
    el [ Font.family [ Font.typeface "Courier", Font.monospace ], Font.color verbatimColor ] (Element.text str)


viewElement : Format -> String -> MExpression -> Element msg
viewElement format fname mexpr =
    case Dict.get fname fDict of
        Nothing ->
            text <| "Function " ++ fname ++ " not found"

        Just f ->
            f format mexpr



-- FUNCTION DICTIONARY


fDict : Dict String (Format -> MExpression -> Element msg)
fDict =
    Dict.fromList
        [ ( "i", \format expr -> wrappedRow [ width fill, Font.italic ] [ view format expr ] )
        , ( "b", \format expr -> wrappedRow [ width fill, Font.bold ] [ view format expr ] )
        , ( "red", \format expr -> wrappedRow [ width fill, Font.color (rgb255 190 0 0) ] [ view format expr ] )
        , ( "blue", \format expr -> wrappedRow [ width fill, Font.color (rgb255 0 0 200) ] [ view format expr ] )
        , ( "image", \format expr -> image format expr )
        , ( "heading1", \format expr -> heading1 format expr )
        , ( "heading2", \format expr -> heading2 format expr )
        , ( "heading3", \format expr -> heading3 format expr )
        , ( "quote", \format expr -> quote format expr )
        , ( "link", \format expr -> link format expr )
        , ( "sum", \format expr -> Widget.sum expr )
        , ( "preformatted", \format expr -> preformatted format expr )
        , ( "indent", \format expr -> indent format expr )
        , ( "bargraph", \format expr -> Widget.bargraph format expr )
        , ( "datatable", \format expr -> dataTable format expr )

        --, ( "spreadsheet", \format args expr -> spreadsheet format args expr )
        --, ( "row", \format args expr -> Element.none )
        , ( "numbered", \format expr -> numbered format expr )
        , ( "bulleted", \format expr -> bulleted format expr )
        , ( "item", \format expr -> item format expr )
        ]


quote format expr =
    case expr of
        MList [ Literal str ] ->
            el [] (Element.text <| "\"" ++ String.trim str ++ "\"")

        _ ->
            unimplemented "Bad data: " "quote"


link format expr =
    case L0.ASTTools.normalize expr of
        MList [ Literal str ] ->
            case String.words str of
                [ label, url ] ->
                    newTabLink []
                        { url = url
                        , label = el [ linkColor ] (text label)
                        }

                [ url ] ->
                    newTabLink []
                        { url = url
                        , label = el [ linkColor ] (text url)
                        }

                _ ->
                    Element.el [ Font.size 32, verticalPadding 32 8 ] (Element.text "Bad data for link")

        MList [ Literal label, Literal url ] ->
            newTabLink []
                { url = url
                , label = el [ linkColor ] (text label)
                }

        _ ->
            Element.el [ Font.size 32, verticalPadding 32 8 ] (Element.text "Bad data for link")


heading1 format expr =
    case expr of
        MList [ Literal str ] ->
            Element.el [ Font.size 32, verticalPadding 64 8 ] (Element.text str)

        _ ->
            Element.el [ Font.size 32, verticalPadding 64 8 ] (Element.text "Bad data for heading")


heading2 format expr =
    case expr of
        MList [ Literal str ] ->
            Element.el [ Font.size 24, verticalPadding 48 8 ] (Element.text str)

        _ ->
            Element.el [ Font.size 24, verticalPadding 48 8 ] (Element.text "Bad data for heading")


heading3 format expr =
    case expr of
        MList [ Literal str ] ->
            Element.el [ Font.size 18, verticalPadding 36 8 ] (Element.text str)

        _ ->
            Element.el [ Font.size 18, verticalPadding 36 8 ] (Element.text "Bad data for heading")


image format expr_ =
    let
        w =
            500
    in
    case getData expr_ of
        Nothing ->
            Element.el [ Font.size 14 ] (Element.text "Error: bad data for image")

        Just { dict, data } ->
            let
                caption =
                    Dict.get "caption" dict |> Maybe.withDefault ""

                w2 =
                    case Dict.get "width" dict of
                        Nothing ->
                            w

                        Just w_ ->
                            String.toInt w_ |> Maybe.withDefault w
            in
            column [ spacing 8, Element.width (px w2) ]
                [ Element.image [ Element.width (px w2) ]
                    { src = data, description = "image" }
                , el [ Font.size 12 ] (Element.text caption)
                ]


dataTable format expr_ =
    case getData expr_ of
        Nothing ->
            el [ Font.size 14 ] (text "Invalid data for bar graph")

        Just { dict, data } ->
            renderDataTable dict (getCSV "," ";" data)


renderDataTable dict data =
    column [ spacing 8 ] (List.map renderRow data)


renderRow data =
    row [ spacing 8 ] (List.map (\s -> el [ width (px 50) ] (text s)) data)



--list format args_ body =
--    let
--        dict =
--            Utility.keyValueDict args_
--    in
--    case body of
--        MList list_ ->
--            column [ spacing 4, listPadding ]
--                (elementTitle args_ :: List.indexedMap (\k item_ -> renderListItem (getPrefixSymbol k dict) format item_) (filterOutBlankItems list_))
--
--        _ ->
--            el [ Font.color redColor ] (text "Malformed list")


numbered format expr =
    case L0.ASTTools.normalize expr of
        MList items ->
            renderNumberedList format items

        _ ->
            unimplemented "Error: " "Bad data for list"


renderNumberedList format items =
    column []
        [ column [ spacing 18, listPadding ]
            (List.indexedMap (\k item_ -> renderItem k format item_) (filterOutBlankItems items))
        ]


numberedPrefix k =
    el [ Font.size 14, alignTop ] (text (String.fromInt (k + 1) ++ ". "))


renderItem : Int -> Format -> MExpression -> Element msg
renderItem k format expr =
    Element.row [ width (px format.lineWidth) ] [ numberedPrefix k, paragraph [ width (px (format.lineWidth - 50)) ] [ view format expr ] ]


bulleted format expr =
    case L0.ASTTools.normalize expr of
        MList items ->
            renderBulletedList format items

        _ ->
            unimplemented "Error: " "Bad data for list"


renderBulletedList format items =
    column []
        [ column [ spacing 18, listPadding ]
            (List.map (renderBulletedItem format) (filterOutBlankItems items))
        ]


bullet =
    el [ Font.size 14, alignTop ] (text "•")


renderBulletedItem : Format -> MExpression -> Element msg
renderBulletedItem format expr =
    Element.row [ width (px format.lineWidth), spacing 8 ] [ bullet, paragraph [ width (px (format.lineWidth - 50)) ] [ view format expr ] ]


item : Format -> MExpression -> Element msg
item format expr =
    Element.paragraph [ width (px format.lineWidth) ] [ view format expr ]



--(elementTitle dict :: List.indexedMap (\k item_ -> item format item_) (filterOutBlankItems items))
--list format expr =
--    case getData expr of
--        Nothing ->
--            Element.el [ Font.size 14 ] (Element.text "Error: bad data for list")
--
--        Just { dict, data } ->
--            column [ spacing 4, listPadding ]
--                (elementTitle dict
--                    :: List.indexedMap (\k item_ -> renderListItem (getPrefixSymbol k dict) format item_) (filterOutBlankItems list_)
--                )
--
--        _ ->
--            el [ Font.color redColor ] (text "Malformed list")


filterOutBlankItems : List MExpression -> List MExpression
filterOutBlankItems list_ =
    List.filter (\item_ -> not (isBlankItem item_)) list_


isBlankItem : MExpression -> Bool
isBlankItem el =
    case el of
        Literal str ->
            String.trim str == ""

        _ ->
            False


getPrefixSymbol : Int -> Dict String String -> Element msg
getPrefixSymbol k dict =
    case Dict.get "style" dict of
        Just "numbered" ->
            el [ Font.size 12, alignTop, moveDown 2.2 ] (text (String.fromInt (k + 1) ++ "."))

        Nothing ->
            Element.none

        Just "bullet" ->
            el [ Font.size 16 ] (text "•")

        Just "none" ->
            Element.none

        Just str ->
            Element.none



--renderListItem prefixSymbol renderArgs elt =
--    case elt of
--        MElement "item" body ->
--            row [ spacing 8 ] [ el [ alignTop, moveDown 2 ] prefixSymbol, view renderArgs elt ]
--
--        MElement "list" body ->
--            case body of
--                MList list_ ->
--                    column [ spacing 4, listPadding ] (elementTitle args :: List.indexedMap (\k item_ -> renderListItem (getPrefixSymbol k dict) renderArgs item_) (filterOutBlankItems list_))
--
--                _ ->
--                    el [ Font.color redColor ] (text "Malformed list")
--
--        _ ->
--            Element.none


elementTitle dict =
    case Dict.get "title" dict of
        Nothing ->
            Element.none

        Just title_ ->
            el [ Font.bold, Font.size titleSize ] (text title_)



--spreadsheet format args body =
--    let
--        spreadsheet1 =
--            getCSV body
--                |> Spreadsheet.readFromList CellParserExcel.parse
--                |> Spreadsheet.eval
--
--        spreadsheet2 : List (List String)
--        spreadsheet2 =
--            Spreadsheet.printAsList spreadsheet1
--
--        renderItem str =
--            el [ width (px 60) ] (el [ alignRight ] (text str))
--
--        renderRow items =
--            row [ spacing 10 ] (List.map renderItem items)
--    in
--    column [ spacing 8, indentPadding ] (List.map renderRow spreadsheet2)
--


getCSV : String -> String -> String -> List (List String)
getCSV fieldSep recordSep data =
    data
        |> String.split recordSep
        |> List.filter (\line -> line /= "")
        |> List.map (String.split fieldSep)
        |> List.map (List.map String.trim)


indent : Format -> MExpression -> Element msg
indent format expr =
    column [ paddingEach { left = 36, right = 0, top = 0, bottom = 0 } ] [ view format expr ]


preformatted : Format -> MExpression -> Element msg
preformatted format expr =
    el
        [ Font.family
            [ Font.typeface "Courier"
            , Font.monospace
            ]
        , Font.color verbatimColor
        , moveLeft 14
        , verticalPadding 0 15
        ]
        (text (Utility.extractText expr |> Maybe.withDefault "(no text)" |> String.dropLeft 3 |> (\x -> "    " ++ x)))



-- COLORS


verbatimColor =
    rgb255 150 0 220


linkColor =
    Font.color (Element.rgb255 0 0 245)


redColor =
    rgb 0.7 0 0



-- SETTINGS


titleSize =
    14


indentPadding =
    paddingEach { left = 24, right = 0, top = 0, bottom = 0 }


listPadding =
    paddingEach { left = 18, right = 0, top = 0, bottom = 0 }


verticalPadding top bottom =
    Element.paddingEach { left = 0, right = 0, top = top, bottom = bottom }



-- HELPERS


getData : MExpression -> Maybe { dict : Dict String String, data : String }
getData expr_ =
    case L0.ASTTools.normalize expr_ of
        MList [ Literal rawData ] ->
            Just { dict = Dict.empty, data = rawData }

        MList [ Verbatim '`' rawData ] ->
            Just { dict = Dict.empty, data = rawData }

        MList [ MElement "opt" (MList [ Literal options ]), Literal rawData ] ->
            Just { dict = Utility.keyValueDictFromString options, data = rawData }

        MList [ MElement "opt" (MList [ Literal options ]), Verbatim '`' rawData ] ->
            Just { dict = Utility.keyValueDictFromString options, data = rawData }

        _ ->
            Nothing


extractText : MExpression -> Maybe String
extractText element =
    case element of
        Literal content ->
            Just content

        _ ->
            Nothing


unquote : String -> String
unquote str =
    String.replace "\"" "" str


htmlAttribute : String -> String -> Element.Attribute msg
htmlAttribute key value =
    Element.htmlAttribute (Html.Attributes.attribute key value)


unimplemented message content =
    el [ Font.size 14, Font.color (Element.rgb255 240 200 200) ] (text <| message ++ ": " ++ content)


getText : MExpression -> Maybe String
getText mexpr =
    case mexpr of
        Literal s ->
            Just (String.trim s)

        MList list_ ->
            List.map getText list_ |> Maybe.Extra.values |> String.join " " |> String.trim |> Just

        _ ->
            Nothing
