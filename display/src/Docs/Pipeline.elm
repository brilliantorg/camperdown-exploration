module Docs.Pipeline exposing (..)


text =
    """
# The Camperdown Parser Pipeline

This document describes the pipeline through which data flows in the
Camperdown parser.  The top-level function is

```elm
parse : Config.ParserConfig -> String -> Syn.Document
parse config file = ...
```

in module `Camperdown.Parse`.  A value of type `Config.ParserConfig`
defines a configuration for the parser, specifying what kind of
marked text it will accept.  Thus, if `standard` is a configuration
and `mydoc` is a string representing a Camperdown document, it
suffices to say `parse standard mydoc` to obtain the AST of `mydoc`.
The type of the AST is

```
type alias Document =
    { prelude : List Element
    , sections : List Section
    }
```

It is defined in module `Camperdown.Parse.Syntax`, aka module `Syn`,
along with the fundamental type


```
type Element
    = Paragraph { contents : Markup }
    | Preformatted { ... }
    | Item { ... }
    | Command { ... }
    | Problem { ... }
```

and

```
type alias Section =
    { level : Int
    , contents : List Element
    , label : Label
    }
```


## Overall data flow

The overall data flow is as follows:

```
Source text : String
       |
       |
 (1)   | |> Sections.splitIntoSections
       |
       |
rawParsed : { prelude : Lines, sections : Sections}
       |
       |
 (2,3) | |> Pieces.pieces config |> Hierarchy.elements
       |
       |
{ prelude : List Element, sections: List Section }

```

### Step 1


In step (1), the source text is broken up into parts. The _prelude_ is
'the text appearing before the first section marker (`#`, `##` or `###`),
while the sections are derived from the text between markers.  We say
"derived", because the type `Section` is slightly more elaborate than
a list of lines.  It contains information on the location of the section
in the source text, indentation, and the "label", which is either the
a named label, consisting of the text of the first line after the the
section marker.  Thus the label for `# Intro` is essentially the value
`Named "Intro"`, while if no text follows the section marker, the label
is `Anonymous k` for some integer k.

### Step 2

Division of the source text into parts in this first stage makes it
impossible for syntax errors to propagate across section boundaries.
This facilitates the task of gracefully handling those errors.
In step (2), the prelude or section is further divided and parsed
into pieces.  A `Piece` is a record whose `piece` field holds parsed
text.
Thus we have


```elm
type alias Piece =
    { lines : { start : Int, end : Int }
    , indent : Int
    , piece : PieceType
    }
```

where the `PieceType` mirrors the `Element` type discussed above.

```elm
type PieceType
    = Paragraph Syn.Markup
    | Item Loc.Location Syn.Markup
    | Command (Loc Syn.Mark) Syn.Command Ending
    | Preformatted String
    | Problem
        { errorLocation : Loc.Location
        , errorMessage : String
        }
```

The module `Pieces` exports a single function:

```elm
pieces : Config -> Lines -> List Piece
pieces = accumPieces [ ]
```

which carries out step (2). It acts as a driver for function
`accumPieces`,
which recursively calls itself using function `getNextPiece`:

```elm
accumPieces : List Piece -> Config -> Lines -> List Piece
accumPieces accum config maybeLines =
    case maybeLines of
        Nothing ->
            List.reverse accum

        Just lines ->
            let
                ( piece, rest ) =
                    getNextPiece config lines
            in
            accumPieces (piece :: accum) config rest
```

Function `getNextPiece` examines the first (or several) leading
characters
of the first line it looks at, then dispatches a handler depending
on those characters to complete the task of gathering the text of the
piece and parsing it.  If the first character is "!" or "?", the
handler is `getCommandPiece`.  If the first character is ":", the handler
is `getItemPiece`.  Etc.  There are five handlers, one for each variant
of `PieceType`.  All but one are straightforward in their operation.
Two of the three (`getProbelmPiece` and `getVerbatimPiece`) do not
invoke functions of module `Camperdown.Parse.Parse`.  Two of those
that do, `getCommandPiece` and `getItemPiece`, invoke functions
`Parse.lineCommand` and `Parse.lineItem`, respectively.

The remaining
handler, `getParagraphLines` is the most complex in its operation.
It invokes the function `Parse.paragraph`, which in turn calls on
`styledText`and then `styledTextLoop`.  The latter function modifies
the so-called `TextCursor`, a data structure which is used to implement
fail-free or tolerant parsing: a parsing strategy that will not fail
in the presence of syntax errors, and which will in fact provide useful,
real-time feedback to the human user of the system about what went wrong.
We discuss the role of the `TextCursor` in the next main section.

### Step 3


The purpose of step 3 is to re-group a list of pieces into their
hierarchical elements.

   When a piece is encountered that is expected to have children,
`getMoreIndented pieces` is called to separate the remainder of the
stream into two bits: the bit that, by virture of its increased
indent, is a child of that piece, and the bit that's not.


       >    - I'm a piece that might have children
       ✓         - I'm child 1 of that piece!
       ✓       - I'm child 2 of that piece!
       ✓          - I'm a child (possibly of child 2, if child 2 can have children)
       ✓       - I'm a child (possibly of child 2, if child 2 can have children)
       X    - I am not a child of that first piece
       X          - I am not a child of that first piece
       X        - I am not a child of that first piece
       X          - I am not a child of that first piece

`getElements` is then called recursively on the first segment,
which parses all of the child pieces into proper children.

This is not really sufficient for reasonable Camperdown: a later
pass needs to be performed to mark as a problem places where child
elements do not all have the _same_ indentation level. Without this as-yet
unimplemented pass, the parse structure could get really mysterious of someone
forgets a chevron.

   See PARSE.md for details

## TextCursor: Overview

The TextCursor design is taken from the
[elm-markup](https://package.elm-lang.org/packages/mdgriffith/elm-mark
up/latest/) data structure with the same name. The main idea is that
in order to successfully have a fail-free parser in the context of
Elm's current parsing infrastructure, you must be able to parse every
_prefix_ in a meaningful sense.

To see what this means, consider the following example.

    My [dog [has] [fleas]] today
    ^

The `^` symbol shows the current position of the parser as it scans
the source text from left to right. So far, the string `M` has been
parsed.

    My [dog [has] [fleas]] today
    ^^^^^^^

Now the string `My [dog` has been parsed, and one is in a state where
a single closing `]` is required at some point.

    My [dog [has] [fleas]] today
    ^^^^^^^^^^^^^^^^^

This is getting complicated.

  - The _current_ passage being parsed is `fl`, which is eventually
going to become an annotation, one supposes.

  - Once that annotation is completely discovered, then we're working
on parsing an annotation containing `dog [has]`, followed by whatever
the annotation we eventually create is.

  - Once we know what _that_ annotation is, then we're working on
parsing an annotation containing `My`, followed by whatever the
annotation we eventually create is.

This ordered sequence of goals forms a (call) stack structure:

  - Goal: Parse `fl`
  - Goal: Parse `dog [has]`, plus whatever is returned from above.
  - Goal: Parse `My`, plus whetever is returned from above.

The current _raw text component_ being parsed is stored in the
`text` field. This would contain `M` in the first example,
`dog` in the second example, and `fl` in the third
example.

The current _trailing list of text segments_ is stored in
the `parsed` field. This would be the empty list in the first
 and third examples, and `dog [has]` in the third example.
That's really three components: the raw text `dog`, the
annotation `[has]`, and the raw text segment that's the
single space between annotations.

Because functional programming lists, these are stored
in the "wrong order":

    [ Types.Raw " "
    , Annotation { startMark = "[", contents = [ Types.Raw "has" ],
endMark = "]", command = Nothing }
    , Types.Raw "dog "
    ]

So "cursor" is perhaps a misnomer: it's really a "selection,"
and the process of parsing feels like ragging that selection,
line by line, across the whole passage. The reason "cursor" is a good
name
is that the goal of the parser's `styledTextLoop` is to always chomp
at least
SOME of the file that's immediately ahead of the "cursor",
incorporating that new text into the
cursor/selection/whatever.


## TextCursor: Worked-out Example

Let us work through the example above in excruciating detail.
Here it is again:

```
  My [dog [has] [fleas]] today
```

Our goal is to study how the `TextCursor`
changes as we scan from left to right.


### Types and notation

The  main type definition is

```
type alias TextCursor =
    { text : String
    , parsed : List Syn.Text
    , annotationStack : List Annotation
    }
```

An `Annotation` is a record with fields defining the start and
expected
end marks, as in the annotations `[foo]` and `*bar*`, where the marks
are
`[`, `]` and `*`, `*`, respectively.

```
type alias Annotation =
    { startMark : Loc String
    , expectedEndMark : String
    , commandOccursAfterwards : Occurs
    , precedingText : List Syn.Text
    }
```

In this exposition we ignore the field `commandOccursAfterwards` and
we
write annotations in an the abbreviated form as in this example:

```
annotation = { st = "[", ex = "]", pt = [ ] }
```

The type `Syn.Text` is the `Text` type in `Camperdown.Parser.Syntax`:

```
type Text
    = Raw String
    | Verbatim Char (Loc String)
    | Annotation (Loc String)
                 (List Text)
                 (Maybe (Loc String))
                 (Maybe (Loc Command))
    | InlineProblem Problem.Inline

```

We will write Annotations in an abbreviated form as in the example
below:

```
Ann "[" [Raw "foo", Raw "bar"] "]"
```

The string "[" is a stand-in for a `Loc String` and "]" is a stand-in
for a `Maybe (Loc String)`.  The `(Maybe (Loc Command)` component is
ignored entirely.  Text cursors will also be written in shorthand
form,
 as in the example below,  where the stack `as` has length 1:
```
cursor = { t = "My ", p = [ ], as = { st = "[", ex = "]", pt = [ ]
}::[ ] }
```



### The example

```
  My [dog [has] [fleas]] today
    ^^   ^^  ^^ ^    ^^^     ^
    01   23  45 6    789     *
```

After having scanned the first three characters, we
are at mark 0, and can apply apply the function


```
addText : String -> TextCursor -> TextCursor
addText newText cursor =
    { cursor | text = cursor.text ++ newText }
```

The resulting text cursor is.

```
0 : {t = "My ", p = [ ], as = [ ]}
```

At mark 1 we encounter a left bracket, and so apply function

```
pushAnnotation : { startMark : Loc String, expectedEndMark : String }
                 -> TextCursor
                 -> TextCursor
pushAnnotation { startMark, expectedEndMark } cursor =
    if cursor.text == "" then
        { cursor
            | parsed = []
            , annotationStack =
                { startMark = startMark
                , expectedEndMark = expectedEndMark
                , precedingText = cursor.parsed
                }
                    :: cursor.annotationStack
        }

    else
        { cursor
            | text = ""
            , parsed = []
            , annotationStack =
                { startMark = startMark
                , expectedEndMark = expectedEndMark
                , precedingText = Syn.Raw cursor.text :: cursor.parsed
                }
                    :: cursor.annotationStack
        }

```


We encounter a left bracket and so apply `push`:

```
1: { t = ""
   , p = [ ]
   , as = [ {st = "[", ex = "]", pt = [Raw "My "]} ]
   }
```

Time to add more text.  At mark 2 we have

```
2: { t = "dog "
   , p = [ ]
   , as = [ {st = "[", ex = "]", pt = [Raw "My "]} ]
   }
```

At mark 3 we discover the opening of a new annotation, and
so once again apply `pushAnnotation`:

```
3 : { t = ""
    , p = [ ]
    , as = [  {st = "[", ex = "]", pt = [Raw "dog "]}
            , {st = "[", ex = "]", pt = [Raw "My "]}
           ]
    }
```

At mark 4 still more text is added, so we have


```
4 : { t = "has"
    , p = [ ]
    , as = [  {st = "[", ex = "]", pt = [Raw "dog "]}
            , {st = "[", ex = "]", pt = [Raw "My "]}
           ]
    }
```

But at mark 5 something new happens.  We have encountered
an expected closing, and so it is time to apply a function that
pops the annotation stack:

```
takeTheCommandPartAndUpdateTheCursor cursor endMark annotation
annotationStack =
    \\cmd ->
        { cursor
            | text = ""
            , parsed = Syn.Annotation annotation.startMark
              (capturedText cursor) endMark cmd
              :: annotation.precedingText
            , annotationStack = annotationStack
        }
```

where

```
capturedText cursor =
    if cursor.text == "" then
        List.reverse cursor.parsed

    else
        List.reverse (Syn.Raw cursor.text :: cursor.parsed)

```

In the case at hand, the value of `capturedText cursor` is
`Raw "has"`, and so

```
parsed = [Ann "[" (Raw "has") "]", Raw "dog" ]
```

Therefore at mark 5, we have

```
5 : { t = ""
    , p = [Ann "[" [Raw "has"] "]", Raw "dog" ]
    , as = [ {st = "[", ex = "]", pt = [Raw "My "]} ]
    }
```

The cursor moves one unit to the right, encountering the
opening of an annotation, so we push. Both the text and
parsed fields are emptied, with the parsed field transferred
to the preceding text field of the element pushed onto the
annotation stack:


```
6 : { t = ""
    , p = [ ]
    , as = [ {  st = "[", ex = "]"
              , pt = [ Ann "[" [Raw "has"] "]" , Raw "dog" ]}
           , {st = "[", ex = "]", pt = [Raw "My "]}
           ]
    }
```

Another easy step, adding text:

```
7 : { t = "fleas"
    , p = [ ]
    , as = [ {  st = "[", ex = "]"
              , pt = [ Ann "[" [Raw "has"] "]" , Raw "dog" ]}
           , {st = "[", ex = "]", pt = [Raw "My "]}
           ]
    }
```

At mark 8 we apply `takeTheCommandPartAndUpdateTheCursor` again.
To compute its value, we first find the value of `capturedText
cursor`, which is just `Raw "fleas"`.  Then


```
parsed = [ Ann "[" [Raw "fleas"] "]"
         , Ann "[" [Raw "has"] "]"
         , Raw "dog"
         ]
 ```

and so we have

```
8 : { t = ""
    , p = [ Ann "[" [Raw "fleas"] "]"
          , Ann "[" [Raw "has"] "]"
          , Raw "dog"
          ]
    , as = [  {st = "[", ex = "]", pt = [Raw "My "]} ]
    }
```

Mark 9 is another occasion to pop the stack.  Since cursor holds no
text, we simply reverse the parsed text to obtain the captured text:

```
  [Raw "dog", Ann "[" [Raw "has"] "]", Ann "[" [Raw "fleas"] "]"
```

and so
```
9 : { t = ""
    , p = [ Ann "["
            [ Raw "dog", Ann "[" [Raw "has"] "]", Ann "[" [Raw
"fleas"] "]"
            "]" ], Raw "My "
          ]
    , as = [ ]
    }
```


The stack has been emptied, but there is still a bit of work to do.
First, we add the remaining text:

```
* : { t = "today"
    , p = [ Ann "["
            [ Raw "dog"
            , Ann "[" [Raw "has"] "]"
            , Ann "[" [Raw "fleas"] "]"
            ]
            "]", Raw "My "
          ]
    , as = [ ]
    }
```

At this point we have reached the end of input. We cannot proceed, and
so it is time to call `commitCursor`:

```
commitCursor : Offset -> ( Int, Int ) -> TextCursor -> List Syn.Text
commitCursor offset end cursor =
    let
        parsed =
            if cursor.text == "" then
                cursor.parsed

            else
                Syn.Raw cursor.text :: cursor.parsed
    in
    case cursor.annotationStack of
        [] ->
            List.reverse parsed

        { startMark, expectedEndMark, precedingText } ::
annotationStack ->
            ... Error handling code

```

Much of `commitCursor` is devoted to error handling.  But in our
example, the stack is empty when we reach the end of input, so we simply (1)
update the value of `parsed` to get

```
[ Raw "today"
  , "Ann "["
      [ Raw "dog"
      , Ann "[" Raw "has" "]"
      , Ann "[" Raw "fleas" "]"
      ] "]",
  , Raw "My "
]
```

and (2) return the reversed result:

```
[   Raw "My, "
  , Ann "[" [ Raw "dog"
            , Ann "[" Raw "has" "]"
            , Ann "[" Raw "fleas" "]"
            ] "]"
  , Raw "today"
]
```

### Error handling

YET TO BE WRITTEN ...

"""


text2 =
    """
# The Camperdown Parser Pipeline

This document describes the pipeline through which data flows in the Camperdown parser.  The top-level function is

```elm
parse : Config.ParserConfig -> String -> Syn.Document
parse config file = ...
```

in module `Camperdown.Parse`.  A value of type `Config.ParserConfig` defines a configuration for the parser, specifying what kind of marked text it will accept.  Thus, if `standard` is a configuration and `mydoc` is a string representing a Camperdown document, it suffices to say `parse standard mydoc` to obtain the AST of `mydoc`. The type of the AST is

```
type alias Document =
    { prelude : List Element
    , sections : List Section
    }
```

It is defined in module `Camperdown.Parse.Syntax`, aka module `Syn`,
along with the fundamental type


```
type Element
    = Paragraph { contents : Markup }
    | Preformatted { ... }
    | Item { ... }
    | Command { ... }
    | Problem { ... }
```

and

```
type alias Section =
    { level : Int
    , contents : List Element
    , label : Label
    }
```


## Overall data flow

The overall data flow is as follows:

```
Source text : String
       |
       |
 (1)   | |> Sections.splitIntoSections
       |
       |
rawParsed : { prelude : Lines, sections : Sections}
       |
       |
 (2,3) | |> Pieces.pieces config |> Hierarchy.elements
       |
       |
{ prelude : List Element, sections: List Section }

```

### Step 1


In step (1), the source text is broken up into parts.
The _prelude_ is the text appearing before the first
section marker (`#`, `##` or `###`), while the sections
are derived from the text between markers.  We say
"derived", because the type `Section` is slightly more
elaborate than a list of lines.  It contains information
on the location of the section in the source text,
indentation, and the "label", which is either the
a named label, consisting of the text of the first
line after the the section marker.  Thus the label
for `# Intro` is essentially the value `Named "Intro"`
, while if no text follows the section marker,
the label is `Anonymous k` for some integer k.

### Step 2

Division of the source text into parts in this first stage makes it
impossible for syntax errors to propagate across section boundaries.
This facilitates the task of gracefully handling those errors.
In step (2), the prelude or section is further divided and parsed into pieces.  A `Piece` is a record whose `piece` field holds parsed text.
Thus we have


```elm
type alias Piece =
    { lines : { start : Int, end : Int }
    , indent : Int
    , piece : PieceType
    }
```

where the `PieceType` mirrors the `Element` type discussed above.

```elm
type PieceType
    = Paragraph Syn.Markup
    | Item Loc.Location Syn.Markup
    | Command (Loc Syn.Mark) Syn.Command Ending
    | Preformatted String
    | Problem
        { errorLocation : Loc.Location
        , errorMessage : String
        }
```

The module `Pieces` exports a single function:

```elm
pieces : Config -> Lines -> List Piece
pieces = accumPieces [ ]
```

which carries out step (2). It acts as a driver for function `accumPieces`,
which recursively calls itself using function `getNextPiece`:

```elm
accumPieces : List Piece -> Config -> Lines -> List Piece
accumPieces accum config maybeLines =
    case maybeLines of
        Nothing ->
            List.reverse accum

        Just lines ->
            let
                ( piece, rest ) =
                    getNextPiece config lines
            in
            accumPieces (piece :: accum) config rest
```

Function `getNextPiece` examines the first (or several) leading characters
of the first line it looks at, then dispatches a handler depending
on those characters to complete the task of gathering the text of the
piece and parsing it.  If the first character is "!" or "?", the handler
is `getCommandPiece`.  If the first character is ":", the handler is
`getItemPiece`.  Etc.  There are five handlers, one for each variant
of `PieceType`.  All but one are straightforward in their operation.
Two of the three (`getProbelmPiece` and `getVerbatimPiece`) do not
invoke functions of module `Camperdown.Parse.Parse`.  Two of those
that do, `getCommandPiece` and `getItemPiece`, invoke functions
`Parse.lineCommand` and `Parse.lineItem`, respectively.

The remaining
handler, `getParagraphLines` is the most complex in its operation.  It invokes the function `Parse.paragraph`, which in turn calls on `styledText`
and then `styledTextLoop`.  The latter function modifies the so-called `TextCursor`, a data structure which is used to implement fail-free
or tolerant parsing:
a parsing strategy that will not fail in the presence of syntax errors, and
which will in fact provide useful, real-time feedback to the human user
of the system about what went wrong. We discuss the role of the
`TextCursor` in the next main section.

### Step 3


The purpose of step 3 is to re-group a list of pieces into their hierarchical elements.

   When a piece is encountered that is expected to have children, `getMoreIndented pieces` is called to separate the remainder of the stream into two bits: the bit that, by virture of its increased indent, is a child of that piece, and the bit that's not.

       >    - I'm a piece that might have children
       ✓         - I'm child 1 of that piece!
       ✓       - I'm child 2 of that piece!
       ✓          - I'm a child (possibly of child 2, if child 2 can have children)
       ✓       - I'm a child (possibly of child 2, if child 2 can have children)
       X    - I am not a child of that first piece
       X          - I am not a child of that first piece
       X        - I am not a child of that first piece
       X          - I am not a child of that first piece

   `getElements` is then called recursively on the first segment, which parses
   all of the child pieces into proper children.

   This is not really sufficient for reasonable Camperdown: a later pass
   needs to be performed to mark as a problem places where child elements do not
   all have the _same_ indentation level. Without this as-yet unimplemented
   pass, the parse structure could get really mysterious of someone forgets a
   chevron.

   See PARSE.md for details

## TextCursor: Overview

The TextCursor design is taken from the [elm-markup](https://package.elm-lang.org/packages/mdgriffith/elm-markup/latest/) data structure with the same name. The main idea is that in order to successfully have a fail-free parser in the context of Elm's current parsing infrastructure, you must be able to parse every _prefix_ in a meaningful sense.

To see what this means, consider the following example.

    My [dog [has] [fleas]] today
    ^

The `^` symbol shows the current position of the parser as it scans
the source text from left to right. So far, the string `M` has been parsed.

    My [dog [has] [fleas]] today
    ^^^^^^^

Now the string `My [dog` has been parsed, and one is in a state where a single closing `]` is required at some point.

    My [dog [has] [fleas]] today
    ^^^^^^^^^^^^^^^^^

This is getting complicated.

  - The _current_ passage being parsed is `fl`, which is eventually going to
    become an annotation, one supposes.
  - Once that annotation is completely discovered, then we're working on parsing
    an annotation containing `dog [has]`, followed by whatever the annotation we
    eventually create is.
  - Once we know what _that_ annotation is, then we're working on parsing an annotation
    containing `My`, followed by whatever the annotation we eventually create is.

This ordered sequence of goals forms a (call) stack structure:

  - Goal: Parse `fl`
  - Goal: Parse `dog [has]`, plus whatever is returned from above.
  - Goal: Parse `My`, plus whetever is returned from above.

The current _raw text component_ being parsed is stored in the
`text` field. This would contain `M` in the first example,
`dog` in the second example, and `fl` in the third
example.

The current _trailing list of text segments_ is stored in
the `parsed` field. This would be the empty list in the first
 and third examples, and `dog [has]` in the third example.
That's really three components: the raw text `dog`, the
annotation `[has]`, and the raw text segment that's the
single space between annotations.

Because functional programming lists, these are stored
in the "wrong order":

    [ Types.Raw " "
    , Annotation { startMark = "[", contents = [ Types.Raw "has" ], endMark = "]", command = Nothing }
    , Types.Raw "dog "
    ]

So "cursor" is perhaps a misnomer: it's really a "selection,"
and the process of parsing feels like ragging that selection,
line by line, across the whole passage. The reason "cursor" is a good name
is that the goal of the parser's `styledTextLoop` is to always chomp at least
SOME of the file that's immediately ahead of the "cursor", incorporating that new text into the
cursor/selection/whatever.


## TextCursor: Worked-out Example

Let us work through the example above in excruciating detail.
Here it is again:

```
  My [dog [has] [fleas]] today
```

Our goal is to study how the `TextCursor`
changes as we scan from left to right.


### Types and notation

The  main type definition is

```
type alias TextCursor =
    { text : String
    , parsed : List Syn.Text
    , annotationStack : List Annotation
    }
```

An `Annotation` is a record with fields defining the start and expected
end marks, as in the annotations `[foo]` and `*bar*`, where the marks are
`[`, `]` and `*`, `*`, respectively.

```
type alias Annotation =
    { startMark : Loc String
    , expectedEndMark : String
    , commandOccursAfterwards : Occurs
    , precedingText : List Syn.Text
    }
```

In this exposition we ignore the field `commandOccursAfterwards` and we
write annotations in an the abbreviated form as in this example:

```
annotation = { st = "[", ex = "]", pt = [ ] }
```

The type `Syn.Text` is the `Text` type in `Camperdown.Parser.Syntax`:

```
type Text
    = Raw String
    | Verbatim Char (Loc String)
    | Annotation (Loc String)
                 (List Text)
                 (Maybe (Loc String))
                 (Maybe (Loc Command))
    | InlineProblem Problem.Inline

```

We will write Annotations in an abbreviated form as in the example below:

```
Ann "[" [Raw "foo", Raw "bar"] "]"
```

The string "[" is a stand-in for a `Loc String` and "]" is a stand-in
for a `Maybe (Loc String)`.  The `(Maybe (Loc Command)` component is
ignored entirely.  Text cursors will also be written in shorthand form,
 as in the example below,  where the stack `as` has length 1:
```
cursor = { t = "My ", p = [ ], as = { st = "[", ex = "]", pt = [ ] }::[ ] }
```



### The example

```
  My [dog [has] [fleas]] today
    ^^   ^^  ^^ ^    ^^^     ^
    01   23  45 6    789     *
```

After having scanned the first three characters, we
are at mark 0, and can apply apply the function


```
addText : String -> TextCursor -> TextCursor
addText newText cursor =
    { cursor | text = cursor.text ++ newText }
```

The resulting text cursor is.

```
0 : {t = "My ", p = [ ], as = [ ]}
```

At mark 1 we encounter a left bracket, and so apply function

```
pushAnnotation : { startMark : Loc String, expectedEndMark : String }
                 -> TextCursor
                 -> TextCursor
pushAnnotation { startMark, expectedEndMark } cursor =
    if cursor.text == "" then
        { cursor
            | parsed = []
            , annotationStack =
                { startMark = startMark
                , expectedEndMark = expectedEndMark
                , precedingText = cursor.parsed
                }
                    :: cursor.annotationStack
        }

    else
        { cursor
            | text = ""
            , parsed = []
            , annotationStack =
                { startMark = startMark
                , expectedEndMark = expectedEndMark
                , precedingText = Syn.Raw cursor.text :: cursor.parsed
                }
                    :: cursor.annotationStack
        }

```


We encounter a left bracket and so apply `push`:

```
1: { t = ""
   , p = [ ]
   , as = [ {st = "[", ex = "]", pt = [Raw "My "]} ]
   }
```

Time to add more text.  At mark 2 we have

```
2: { t = "dog "
   , p = [ ]
   , as = [ {st = "[", ex = "]", pt = [Raw "My "]} ]
   }
```

At mark 3 we discover the opening of a new annotation, and
so once again apply `pushAnnotation`:

```
3 : { t = ""
    , p = [ ]
    , as = [  {st = "[", ex = "]", pt = [Raw "dog "]}
            , {st = "[", ex = "]", pt = [Raw "My "]}
           ]
    }
```

At mark 4 still more text is added, so we have


```
4 : { t = "has"
    , p = [ ]
    , as = [  {st = "[", ex = "]", pt = [Raw "dog "]}
            , {st = "[", ex = "]", pt = [Raw "My "]}
           ]
    }
```

But at mark 5 something new happens.  We have encountered
an expected closing, and so it is time to apply a function that
pops the annotation stack:

```
takeTheCommandPartAndUpdateTheCursor cursor endMark annotation annotationStack =
    \\cmd ->
        { cursor
            | text = ""
            , parsed = Syn.Annotation annotation.startMark
              (capturedText cursor) endMark cmd
              :: annotation.precedingText
            , annotationStack = annotationStack
        }
```

where

```
capturedText cursor =
    if cursor.text == "" then
        List.reverse cursor.parsed

    else
        List.reverse (Syn.Raw cursor.text :: cursor.parsed)

```

In the case at hand, the value of `capturedText cursor` is
`Raw "has"`, and so

```
parsed = [Ann "[" (Raw "has") "]", Raw "dog" ]
```

Therefore at mark 5, we have

```
5 : { t = ""
    , p = [Ann "[" [Raw "has"] "]", Raw "dog" ]
    , as = [ {st = "[", ex = "]", pt = [Raw "My "]} ]
    }
```

The cursor moves one unit to the right, encountering the
opening of an annotation, so we push. Both the text and
parsed fields are emptied, with the parsed field transferred
to the preceding text field of the element pushed onto the
annotation stack:


```
6 : { t = ""
    , p = [ ]
    , as = [ {  st = "[", ex = "]"
              , pt = [ Ann "[" [Raw "has"] "]" , Raw "dog" ]}
           , {st = "[", ex = "]", pt = [Raw "My "]}
           ]
    }
```

Another easy step, adding text:

```
7 : { t = "fleas"
    , p = [ ]
    , as = [ {  st = "[", ex = "]"
              , pt = [ Ann "[" [Raw "has"] "]" , Raw "dog" ]}
           , {st = "[", ex = "]", pt = [Raw "My "]}
           ]
    }
```

At mark 8 we apply `takeTheCommandPartAndUpdateTheCursor` again.
To compute its value, we first find the value of `capturedText cursor`, which is just `Raw "fleas"`.  Then


```
parsed = [ Ann "[" [Raw "fleas"] "]"
         , Ann "[" [Raw "has"] "]"
         , Raw "dog"
         ]
 ```

and so we have

```
8 : { t = ""
    , p = [ Ann "[" [Raw "fleas"] "]"
          , Ann "[" [Raw "has"] "]"
          , Raw "dog"
          ]
    , as = [  {st = "[", ex = "]", pt = [Raw "My "]} ]
    }
```

Mark 9 is another occasion to pop the stack.  Since cursor holds no
text, we simply reverse the parsed text to obtain the captured text:

```
  [Raw "dog", Ann "[" [Raw "has"] "]", Ann "[" [Raw "fleas"] "]"
```

and so
```
9 : { t = ""
    , p = [ Ann "["
            [ Raw "dog", Ann "[" [Raw "has"] "]", Ann "[" [Raw "fleas"] "]"
            "]" ], Raw "My "
          ]
    , as = [ ]
    }
```


The stack has been emptied, but there is still a bit of work to do.
First, we add the remaining text:

```
* : { t = "today"
    , p = [ Ann "["
            [ Raw "dog"
            , Ann "[" [Raw "has"] "]"
            , Ann "[" [Raw "fleas"] "]"
            ]
            "]", Raw "My "
          ]
    , as = [ ]
    }
```

At this point we have reached the end of input. We cannot proceed, and
so it is time to call `commitCursor`:

```
commitCursor : Offset -> ( Int, Int ) -> TextCursor -> List Syn.Text
commitCursor offset end cursor =
    let
        parsed =
            if cursor.text == "" then
                cursor.parsed

            else
                Syn.Raw cursor.text :: cursor.parsed
    in
    case cursor.annotationStack of
        [] ->
            List.reverse parsed

        { startMark, expectedEndMark, precedingText } :: annotationStack ->
            ... Error handling code

```

Much of `commitCursor` is devoted to error handling.  But in our example,
the stack is empty when we reach the end of input, so we simply (1) update
the value of `parsed` to get

```
[ Raw "today"
  , "Ann "["
      [ Raw "dog"
      , Ann "[" Raw "has" "]"
      , Ann "[" Raw "fleas" "]"
      ] "]",
  , Raw "My "
]
```

and (2) return the reversed result:

```
[   Raw "My, "
  , Ann "[" [ Raw "dog"
            , Ann "[" Raw "has" "]"
            , Ann "[" Raw "fleas" "]"
            ] "]"
  , Raw "today"
]
```

### Error handling

YET TO BE WRITTEN ...

"""
