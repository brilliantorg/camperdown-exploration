module Main exposing (main)

{- This is a starter app which presents a text label, text field, and a button.
   What you enter in the text field is echoed in the label.  When you press the
   button, the text in the label is reverse.
   This version uses `mdgriffith/elm-ui` for the view functions.
-}

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav exposing (Key)
import Camperdown.Parse
import Camperdown.Parse.Syntax exposing (Document, Label(..), Section)
import Docs
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import File exposing (File)
import File.Select as Select
import L0.Config
import L0.View
import Task
import Url exposing (Url)
import View.AST


main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = UrlClicked
        , onUrlChange = UrlChanged
        }


type alias Model =
    { contents : String
    , document : Maybe Document
    , key : Key
    , url : Url
    , viewMode : ViewMode
    }


type Msg
    = NoOp
    | CodeChanged String
    | UrlClicked UrlRequest
    | UrlChanged Url
    | InputText String
    | ShowAST
    | ShowCampdown
    | About
    | Dummy String
    | FileRequested
    | FileSelected File
    | LoadFileContents String


type ViewMode
    = ViewL0
    | ViewAST
    | ViewAbout


type alias Flags =
    {}


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        doc =
            Just (Camperdown.Parse.parse L0.Config.config Docs.sourceText)
    in
    ( { key = key
      , url = url
      , contents = Docs.sourceText
      , document = doc
      , viewMode = ViewL0
      }
    , Cmd.none
    )


subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        CodeChanged str ->
            ( loadContent model str, Cmd.none )

        InputText str ->
            ( { model
                | contents = str
                , document = Just (Camperdown.Parse.parse L0.Config.config str)
              }
            , Cmd.none
            )

        UrlClicked urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model, Cmd.none )

                External url ->
                    ( model
                    , Nav.load url
                    )

        UrlChanged _ ->
            ( model, Cmd.none )

        ShowAST ->
            ( { model | viewMode = ViewL0 }, Cmd.none )

        ShowCampdown ->
            ( { model | viewMode = ViewAST }, Cmd.none )

        About ->
            ( { model | viewMode = ViewAbout }, Cmd.none )

        Dummy _ ->
            ( { model | viewMode = ViewAST }, Cmd.none )

        FileRequested ->
            ( model, Select.file [ "text/txt" ] FileSelected )

        FileSelected file ->
            ( model, Task.perform LoadFileContents (File.toString file) )

        LoadFileContents contents ->
            ( { model | contents = contents, document = Just (Camperdown.Parse.parse L0.Config.config contents) }, Cmd.none )



-- HELPERS


requestHyperCard : Cmd Msg
requestHyperCard =
    Select.file [ "text/plain" ] FileSelected



--
-- VIEW
--


fontGray g =
    Font.color (Element.rgb g g g)


bgGray g =
    Background.color (Element.rgb g g g)


view : Model -> Browser.Document Msg
view model =
    { title = "L0 Markup Demo"
    , body = [ Element.layout [ bgGray 0.2, centerX, centerY ] (mainColumn model) ]
    }


mainColumn : Model -> Element Msg
mainColumn model =
    column mainColumnStyle
        [ column [ spacing 36, width (px 1200), height (px 800), scrollbarY ]
            [ row [ spacing 12, centerX, centerY ]
                [ el [ Font.size 24 ] (text "L0 Markup Demo")
                , toggleViewButton model.viewMode
                , requestFileButton
                , aboutButton model.viewMode
                ]
            , row [ spacing 12 ] [ editor model, viewDocument model ]
            ]
        ]


viewDocument model =
    case model.viewMode of
        ViewAST ->
            viewAST model

        ViewL0 ->
            viewL0 model

        ViewAbout ->
            text "Not implemented"


viewL0 : Model -> Element msg
viewL0 model =
    case model.document of
        Nothing ->
            Element.none

        Just doc ->
            column [ height (px 700), width (px 500), scrollbarY, Font.size 14 ]
                (L0.View.view ourFormat model.contents doc)


ourFormat =
    -- Units = pixels
    { lineWidth = 500
    , leftPadding = 15
    , bottomPadding = 8
    , topPadding = 8
    }



-- |> column [ height (px 700), width (px 500), scrollbarY ]


viewAST : Model -> Element msg
viewAST model =
    case model.document of
        Nothing ->
            Element.none

        Just doc ->
            View.AST.view model.contents doc |> column [ height (px 700), width (px 500), scrollbarY ]


panelWidth model =
    width (px <| min (model.width // 2 - 100) maxPanelWidth)


maxPanelWidth =
    700


headerHeight =
    40


verticalSpreaderHeight =
    24



--
--panelHeight model =
--    height (px (model.height - headerHeight - verticalSpreaderHeight - 30))
--
--
--editor2 model =
--    el [ panelWidth model, panelHeight model ]
--        (html <|
--            Html.node "custom-editor"
--                [ Html.Attributes.property "editorContents" <|
--                    Encode.string model.contents
--                , Html.Events.on "editorChanged" <|
--                    Decode.map CodeChanged <|
--                        Decode.at [ "target", "editorContents" ] <|
--                            Decode.string
--                ]
--                []
--        )


loadContent : Model -> String -> Model
loadContent model text =
    let
        document =
            documentFromString text
    in
    { model
        | contents = text
        , document = Just document
    }


documentFromString str =
    Camperdown.Parse.parse L0.Config.config str


editor model =
    -- TODO: finish this!
    -- column [ width fill, height fill, Background.color (rgb255 255 212 220), padding 40 ] [ text "EDITOR" ]
    Input.multiline [ width (px 500), height (px 700), Background.color (rgb255 255 212 220), padding 40, Font.size 14 ]
        { onChange = InputText
        , text = model.contents
        , placeholder = Nothing
        , label = Input.labelHidden "Editor"
        , spellcheck = False
        }


format =
    { imageHeight = 500
    , lineWidth = 600
    , leftPadding = 20
    , bottomPadding = 10
    , topPadding = 10
    }


title : String -> Element msg
title str =
    row [ centerX, Font.bold, fontGray 0.9 ] [ text str ]


inputText : Model -> Element Msg
inputText model =
    Input.text []
        { onChange = InputText
        , text = model.contents
        , placeholder = Nothing
        , label = Input.labelAbove [ fontGray 0.9 ] <| el [] (text "Input")
        }


toggleViewButton : ViewMode -> Element Msg
toggleViewButton viewMode =
    case viewMode of
        ViewAST ->
            row []
                [ Input.button buttonStyle
                    { onPress = Just ShowAST
                    , label = el [ centerX, centerY ] (text "AST    ")
                    }
                ]

        ViewL0 ->
            row []
                [ Input.button buttonStyle
                    { onPress = Just ShowCampdown
                    , label = el [ centerX, centerY ] (text "L0")
                    }
                ]

        ViewAbout ->
            Element.none


requestFileButton : Element Msg
requestFileButton =
    row []
        [ Input.button buttonStyle
            { onPress = Just FileRequested
            , label = el [ centerX, centerY ] (text "Open file")
            }
        ]


aboutButton : ViewMode -> Element Msg
aboutButton viewMode =
    case viewMode of
        ViewAbout ->
            row []
                [ Input.button buttonStyle
                    { onPress = Just ShowCampdown
                    , label = el [ centerX, centerY ] (text "L0")
                    }
                ]

        _ ->
            row []
                [ Input.button buttonStyle
                    { onPress = Just About
                    , label = el [ centerX, centerY ] (text "About")
                    }
                ]



--
-- STYLE
--


mainColumnStyle =
    [ centerX
    , centerY
    , bgGray 1.0
    , paddingXY 20 0
    , width (px 1400)
    , height (px 800)
    ]


buttonStyle =
    [ Background.color (Element.rgb 0.5 0.5 0.5)
    , Font.color (rgb255 255 255 255)
    , Font.size 14
    , paddingXY 15 8
    ]



-- DATA


sourceText =
    """


[image [opt width:300, caption:'Blue bird'] https://www.nhm.ac.uk/content/dam/nhmwww/discover/garden-birds/winter-birds-blue-tit-two-column.jpg.thumb.768.768.jpg]

[heading1 The L0 Markup Language]

L0 is a simple yet versatile markup language that takes inspiration from Lisp.  An L0 document consists of ordinary text and [quote elements], e.g., `[blue flowers]`, which is rendered as [blue flowers].  Elements can be nested, as in `[blue [i delicate blue] flowers]`, which renders as [blue [i delicate blue] flowers].

In addtions to the [quote pure L0] just described, we have borrowed from Markdown.  For example, inline code can set off by backticks:

%%%
     This is code: `a[i] = a[i] + 1`

The version of L0 that you see here is implemented in [link Elm https://elm-lang.org] using the [link Camperdown https://package.elm-lang.org/packages/brilliantorg/backpacker-below/latest]


[heading2 the rest]

In the Spring, I will be looking for [blue blue flowers] and [red [i red butterflies!]]


[image https://www.nhm.ac.uk/content/dam/nhmwww/discover/garden-birds/winter-birds-blue-tit-two-column.jpg.thumb.768.768.jpg]

"""
