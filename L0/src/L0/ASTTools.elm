module L0.ASTTools exposing (normalize)

import L0.MExpression exposing (MExpression(..))


normalize : MExpression -> MExpression
normalize =
    trim >> filterEmptyRaw


trim : MExpression -> MExpression
trim mExpr =
    case mExpr of
        Literal str ->
            Literal (String.trim str)

        Verbatim char str ->
            Verbatim char (String.trim str)

        MElement str mExpr2 ->
            MElement str (trim mExpr2)

        MList listMExpr ->
            MList (List.map trim listMExpr)

        MProblem str ->
            MProblem str


filterEmptyRaw : MExpression -> MExpression
filterEmptyRaw mExpr =
    case mExpr of
        MElement str (MList listExpr) ->
            MElement str (filterEmptyRaw (MList listExpr))

        MList listExpr ->
            MList (List.filter (\expr -> notEmptyRaw expr) listExpr |> List.map filterEmptyRaw)

        _ ->
            mExpr


notEmptyRaw : MExpression -> Bool
notEmptyRaw mExpr =
    case mExpr of
        Literal "" ->
            False

        _ ->
            True
