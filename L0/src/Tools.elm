module Tools exposing (q, qq)

import Camperdown.Parse
import L0.Config
import L0.MExpression
import L0.ASTTools


q s = Camperdown.Parse.parse L0.Config.config s |> .prelude
qq s = q s |> List.map (L0.MExpression.fromElement >> L0.ASTTools.normalize)