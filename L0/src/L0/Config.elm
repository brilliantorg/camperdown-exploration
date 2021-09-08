module L0.Config exposing (..)

import Set
import Camperdown.Occurs as Occurs
import Camperdown.Config as Config

config : Config.Config
config =
    { verbatimOpts = Set.fromList [ '`', '$' ]
    , annotationOpts =
        [ { startSymbol = "**", endSymbol = Just "**", commandOccursAfterwards = Occurs.Never }
        , { startSymbol = "*", endSymbol = Just "*", commandOccursAfterwards = Occurs.Never }
        , { startSymbol = "__", endSymbol = Just "__", commandOccursAfterwards = Occurs.Never }
        , { startSymbol = "_", endSymbol = Just "_", commandOccursAfterwards = Occurs.Never }
        , { startSymbol = "\"", endSymbol = Just "\"", commandOccursAfterwards = Occurs.Never }
        , { startSymbol = "[", endSymbol = Just "]", commandOccursAfterwards = Occurs.Never }
        , { startSymbol = "...", endSymbol = Nothing, commandOccursAfterwards = Occurs.Never }
        , { startSymbol = "---", endSymbol = Nothing, commandOccursAfterwards = Occurs.Never }
        , { startSymbol = "--", endSymbol = Nothing, commandOccursAfterwards = Occurs.Never }
        ]
    , annotationFirstChars = Set.fromList [ '*', '_', '"', '[', '.', '-' ]
    , meaningful = Set.fromList [ '\\', ']', '\n', '*', '_', '"', '[', '.', '-', '$', '`' ]
    , escapable = Set.fromList [ '#', '\\', '[', ']', '!', '?', ':', '(', ')', '*', '_', '"', '[', '.', '-', '%', '$', '`' ]
    , verbatimMarkers = [ "%%%", "$$$", "```" ]
    }

