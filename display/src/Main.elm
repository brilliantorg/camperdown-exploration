module Main exposing (main)

import Browser exposing (UrlRequest(..))
import Browser.Navigation as Nav exposing (Key)
import Camperdown.Config.Config as Config
import Camperdown.Parse
import Camperdown.Parse.Syntax exposing (Document, Label(..), Section)
import Docs
import Docs.Pipeline
import Element exposing (..)
import Element.Background as Background
import Element.Font as Font
import Element.Input as Input
import File exposing (File)
import File.Select as Select
import Markdown
import Task
import Url exposing (Url)
import View.Campdown


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
    , appDoc : AppDoc
    }


type Msg
    = NoOp
    | CodeChanged String
    | UrlClicked UrlRequest
    | UrlChanged Url
    | SetDoc AppDoc


type AppDoc
    = HomeDoc
    | PipelineDoc


type ViewMode
    = ViewCampdown
    | ViewAST
    | ViewAbout


type alias Flags =
    {}


init : Flags -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        doc =
            Just (Camperdown.Parse.parse Config.config sourceText)
    in
    ( { key = key
      , url = url
      , contents = sourceText
      , document = doc
      , appDoc = HomeDoc
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

        SetDoc doc ->
            ( { model | appDoc = doc }, Cmd.none )



-- HELPERS
--
-- VIEW
--


fontGray g =
    Font.color (Element.rgb g g g)


bgGray g =
    Background.color (Element.rgb g g g)


view : Model -> Browser.Document Msg
view model =
    { title = "Campdown Demo"
    , body = [ Element.layout [ bgGray 0.2 ] (mainColumn model) ]
    }


mainColumn : Model -> Element Msg
mainColumn model =
    column mainColumnStyle
        [ column [ spacing 12, paddingXY 0 36, centerX ]
            [ el [ Font.size 24 ] (text "Camperdown Explorations") ]
        , case model.appDoc of
            HomeDoc ->
                viewCampDown model

            PipelineDoc ->
                viewMarkdown model
        , footer model
        ]


footer model =
    row [ paddingXY 8 8, spacing 12, height (px 40), width fill, Background.color (Element.rgb255 20 20 20) ]
        [ homeButton model.appDoc, pipelineDocButton model.appDoc ]


viewMarkdown : Model -> Element msg
viewMarkdown model =
    case model.document of
        Nothing ->
            Element.none

        Just doc ->
            column [ centerX, Background.color (Element.rgb 255 250 250), height (px 650), width (px 500), scrollbarY ]
                [ column [ Font.size 14 f ] [ Markdown.toHtml [] Docs.Pipeline.text |> Element.html ] ]


viewCampDown : Model -> Element msg
viewCampDown model =
    case model.document of
        Nothing ->
            Element.none

        Just doc ->
            column [ centerX, Background.color (Element.rgb 255 250 250), height (px 650), width (px 500), scrollbarY ]
                [ column [ Font.size 14 ] (View.Campdown.view ourFormat model.contents doc) ]


ourFormat =
    -- Units = pixels
    { imageHeight = 300
    , lineWidth = 450
    , leftPadding = 15
    , bottomPadding = 8
    , topPadding = 8
    }



-- |> column [ height (px 700), width (px 500), scrollbarY ]


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
    Camperdown.Parse.parse Config.config str


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


pipelineDocButton : AppDoc -> Element Msg
pipelineDocButton appDoc =
    Input.button (buttonStyle ++ [ bgColor appDoc PipelineDoc, height (px 30) ])
        { onPress = Just (SetDoc PipelineDoc)
        , label = el [ centerX, centerY, bgColor appDoc PipelineDoc ] (text "Pipeline")
        }


homeButton : AppDoc -> Element Msg
homeButton appDoc =
    Input.button (buttonStyle ++ [ bgColor appDoc HomeDoc, height (px 30) ])
        { onPress = Just (SetDoc HomeDoc)
        , label = el [ centerX, centerY, bgColor appDoc HomeDoc ] (text "Home")
        }


bgColor appDoc1 appDoc2 =
    if appDoc1 == appDoc2 then
        Background.color (Element.rgb255 200 40 40)

    else
        Background.color (Element.rgb255 80 80 100)



--
-- STYLE
--


mainColumnStyle =
    [ centerX
    , centerY
    , bgGray 1.0
    , paddingXY 20 0
    , width (px 600)
    , height (px 800)
    ]


buttonStyle =
    [ Background.color (Element.rgb 0.5 0.5 0.5)
    , Font.color (rgb255 255 255 255)
    , Font.size 14
    , paddingXY 15 0
    ]



-- DATA


sourceText =
    Docs.sample
