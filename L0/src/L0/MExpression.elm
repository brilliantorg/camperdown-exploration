module L0.MExpression exposing (MExpression(..), fromElement)

import Camperdown.Loc as Loc
import Camperdown.Parse.Syntax as Syntax
import L0.Config


type MExpression
    = Literal String
    | Verbatim Char String
    | MElement String MExpression
    | MList (List MExpression)
    | MProblem String


{-|

    MExpression.fromElement maps values of type Syntax.Element
    to values of type MExpression

-}
fromElement : Syntax.Element -> MExpression
fromElement element =
    case element of
        Syntax.Paragraph { contents } ->
            fromMarkup contents

        Syntax.Preformatted { contents } ->
            MElement "preformatted" (Literal contents)

        Syntax.Item _ ->
            Literal "item: not implemented"

        Syntax.Command commandData ->
            MElement (commandName commandData.command) (children commandData.child)

        Syntax.Problem { problem } ->
            Literal ("Problem: " ++ problem)



{-
   Camperdown.Parse.Syntax
   Placeholder

   type alias Command =
       ( Maybe (Loc String), Config )
   Placeholder

   type alias Config =
       ( List (Loc Value), List (Loc Parameter) )
   Placeholder

   type Divert
       = Nested (List Element)
       | Immediate (List Element)
       | Reference (Loc String)




-}


children : Maybe Syntax.Divert -> MExpression
children mDivert =
    case mDivert of
        Nothing ->
            MList []

        Just (Syntax.Nested list) ->
            MList (List.map fromElement list)

        Just (Syntax.Immediate list) ->
            MList (List.map fromElement list)

        Just (Syntax.Reference locString) ->
            Literal (Loc.value locString)


commandName : Syntax.Command -> String
commandName ( mLocString, _ ) =
    Maybe.map Loc.value mLocString |> Maybe.withDefault "(command)"


fromMarkup : Syntax.Markup -> MExpression
fromMarkup textList =
    List.map fromText textList |> MList


fromText : Syntax.Text -> MExpression
fromText text =
    case text of
        Syntax.Raw str ->
            Literal str

        Syntax.Verbatim char ( _, str ) ->
            Verbatim char str

        Syntax.Annotation prefix textList _ _ ->
            if not <| List.member (Loc.value prefix) [ "[", "\"" ] then
                MProblem "Error: '[' expected"

            else
                case textList of
                    [] ->
                        Literal "(invalid annotation)"

                    head :: rest ->
                        case head of
                            Syntax.Raw str ->
                                if Loc.value prefix == "\"" then
                                    Literal str

                                else if Loc.value prefix == "[" then
                                    let
                                        firstSpace =
                                            List.head (String.indices " " str) |> Maybe.withDefault 1

                                        fname =
                                            String.left firstSpace str

                                        arg =
                                            String.dropLeft firstSpace str
                                    in
                                    case List.head rest of
                                        Nothing ->
                                            MElement fname (MList (Literal arg :: List.map fromText rest))

                                        Just possibleArg ->
                                            let
                                                ( mark2, args2 ) =
                                                    case possibleArg of
                                                        Syntax.Annotation prefix_ textList_ maybeSuffix_ maybeLocCommand_ ->
                                                            let
                                                                mark_ =
                                                                    Loc.value prefix_

                                                                args_ =
                                                                    List.head textList_
                                                                        |> Maybe.andThen getText
                                                                        |> Maybe.map (String.split "," >> List.map String.trim)
                                                                        |> Maybe.withDefault []
                                                            in
                                                            ( mark_, args_ )

                                                        _ ->
                                                            ( "(error)", [] )
                                            in
                                            if mark2 == "|" then
                                                let
                                                    --args =
                                                    --    String.split ", " "a:1, b:2" |> List.map String.trim
                                                    rest2 =
                                                        List.drop 1 rest
                                                in
                                                MElement fname (MList (List.map fromText rest2))

                                            else
                                                MElement fname (MList (Literal arg :: List.map fromText rest))

                                else
                                    Literal "(I was expecting '[' or '\"')"

                            _ ->
                                Literal "(malformed annotation)"

        Syntax.InlineProblem _ ->
            Literal "(inline problem)"


getText t =
    case t of
        Syntax.Raw text ->
            Just text

        _ ->
            Nothing
