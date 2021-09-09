module Docs exposing (aboutDoc, sample)

sample = """

*Note:* _This is the start of some documentation for Camperdown._

! heading1  [Introduction]

Camperdown is a markup language for non-hypertext branching storytelling. It tries to steal good ideas about branching-paths storytelling from the [Inkle](link "https://www.inklestudios.com/ink/") language, good ideas about markup languages from [Idyll](link "https://idyll-lang.org/docs") and some syntax from [Elm](link "https://elm-lang.org"). While Camperdown shares many features with Markdown, it is distinguished by

! list >>
   :  configurability

   :  extensibility: new features can be added without changing       the language.

   :  robust, real-time, and informative error handling.
Configurability means that the markup language can be changed simply by changing the parser configuration. Extensibility means that new features can be added without changes to the parser, other than configuration. Robust error handling means that the parser will parse the entire input document even if it contains errors. Informative error messages are generated in real time so that an author can react to them as the document is being edited.

! heading2  [Line commands]

Markdown implements new features by implementing new prefixes, e.g., `[` to open a hyperlink, `![` to open a placed image, and `>>` to open a quotation. Camperdown achieves the same by a number of mechanisms, among which is the notion of a _line command._ Here are three examples, on which we elaborate below:

%%% ! image
    ! quote
    ! table

Thus one grammatical form suffices to parse an infinite set of distinct commands, one for each command name, "image," "quote," "table," etc. The host app, through its view and update functions, determines how line commands are interpreted.

! heading2  [Images]

Images are rendered by a line commmand like the one below.

%%% ! image "URL for the bird"

! image "https://cdn.download.ams.birds.cornell.edu/api/v1/asset/303881651/1800"

! heading2  [Quotations]

The format of the `quote` line commmand is slightly different. The command name `quote` is followed by the chevron `>>`, which indicates that "children" follow. In the case at hand, the children, which must be indented, are ordinary text.

%%% ! quote >>

      Paragraph 1

      Paragraph 2

      ...

! quote >>
   Four score and seven years ago our fathers brought    forth upon this continent, a new nation, conceived in    Liberty, and dedicated to the proposition that all men    are created equal.

   Now we are engaged in a great civil war, testing whether    that nation, or any nation so conceived and so dedicated,    can long endure. We are met on a great battle-field of    that war. We have come to dedicate a portion of that    field, as a final resting place for those who here gave    their lives that that nation might live. It is altogether    fitting and proper that we should do this.

   --- Abraham Lincoln
! heading2  [Tables]

In the table example below, we see two kinds of line commmands, those with _mark_ `!` and those with mark `?`. The latter are "subcommands," used to signal rows and cells of the table.

%%% ! table >>
      ? row >>
      ? [*Pizza*]
      ? [*Price*]
      ? [*Quantity Ordered*]

! table >>
   ? row >>
      ? [*Pizza*]

      ? [*Price*]

      ? [*Quantity Ordered*]
   ? row >>
      ? [~Cheese~]

      ? [\\$10.00]

      ? [$5$]
   ? row >>
      ? [Pepperoni]

      ? [\\$12.00]

      ? [$7$]

"""


aboutDoc = """

# A HyperCard App in Camperdown

Way back when, in 1987, Apple released [Campdown](https://en.wikipedia.org/wiki/HyperCard), an app that
presented the user with a "deck of cards" containing text,
images and other media, as well as links to other cards in
the deck. Clicking on such a link would bring the target
card into view.

![](https://cdn.arstechnica.net//wp-content/uploads/2012/05/HyperCardbird-e1338220256722.jpg)

Our goal here is to describe how a hypercard-like app can
be implemented using Camperdown. To see the app in action,
select *Tour* in the *Document* menu of this app and select
*Campdown* in the *View Mode* menu to view *Tour* as a
Campdown deck.

For the implementation, consider the general structure
of a typical Camperdown app. This will be an Elm app that
reads a document written in Camperdown markup, parses it,
stores the AST in the model, and then renders the AST in
using its view function. The app you are using right now
is a species of this general structure in which the entire
AST is rendered with headings, bold and italic text,
links and images, but with no active elements that require
interaction with the update function. In a Camperdown
HyperCard app, one displays just one section of the document
at a time. Each section or "card," contains one or more
named links, each pointing to some other section of the
document. When the user clicks on a link, the "target"
card is displayed.

The app, which relies on the Elm `brilliantorg/backpacker-below"`
package, is quite slim. The `Campdown` module (360 loc) is the
interface between the app code in `Main` (260 loc). It makes use 
of a small module, `ASTTools` (80 loc) that manipulates
the AST obtained by parsing a Campdown source file.
That's it!

## Implementation

A Camperdown document has a _prelude_ and a bunch of _sections_:

```
This is the prelude.  It is optional
and consists of whatever comes before the
first section

# First section
Stuff

# Second section
More stuff
```

Parsing the text yields a value of type `Document`, where

```
type alias Document =
    { prelude : List Element
    , sections : List Section
    }
```

and where

```
type alias Section =
    { level : Int
    , contents : List Element
    , label : Label
    }
```

In order to work with a homogeneous type, we assume that
a Camperdown Campdown document has an empty prelude. When
such a document is loaded or modified in the editor, the
content is parsed and stored as the `currentDocument`
field of the model, with `currentSection` set to the head
of the list of sections.

```
type alias Model =
   {  contents : String
    , currentDocument : Maybe Document
    , currentSection : Maybe Section
    ...
   }
```

The current section is displayed to the user via function
`viewSection` in module `ViewHyperCard.` As an example,
consider the *Tour* document:

```
    # The beginning

    Go around Europe!

    You start in Dover, and hop aboard the Chunnel
    to go to [France](go "france-entry" ).

    # france-entry

    Welcome to France!

    ...
```

When this document is opened, the section _The beginning_
is displayed with a link `France.` Referring to the source
code, we find the annotation `[France](go "france-entry" )`
with a following command. The command has name `go` and
arguument `#france-entry"`. The intent is for a click on
this link to cause the section entitled `france-entry` to
be displayed. The main work, then, is implementing this command.

## The go command

The `go` command will be implemented as part of the view
function defined in module `ViewHyperCard.` As a starting
point for writing `ViewHyperCard,` we take the module
`ViewMarkup` which is used to render an entire document
much as if it were a Markdown document. The first task,
then, is to find the part of the code where we can handle
the go command. To that end, we search our newly renamed
copy of `ViewMarkup` for `Annotation.` There is just one
hit, as a clause of `viewText.` There we find the code

```
( _, ( ( start, end, cmd ), ( arguments, parameters ) ) ) =
        annotation
```

The `cmd` snippet looks promising, especially in view of
code we find a bit further down.

```
case cmd of
   Just "link" ->
      [ newTabLink
        [ Font.color (Element.rgb 0 0 0.8) ]
        { url = arg, label = el [] (text label) } ]

   _ ->
      List.concat <| List.map (viewText attr newStyle)
         Loc.value markup)
```

So it seems that we should add some code like this:

```
Just "go" ->
       [ goToSectionButton arg label ]
```

We confirm the wisdom of this choice by stubbing out the
function `goToSectionButton` with some `Debug.log` statements
to ensure that we really do capture the correct values
with `arg` and `label.` The finished code the button is

```
goToSectionButton arg label =
      Input.button []
        { onPress = Just (GoToSection arg),
          label = el [ ... ] (text label) }
```

where `arg` is the name of the destination section. The
real action occurs is in the clause `GoToSection arg ->`
of the `update` function:

```
HyperCard hyperCardMsg ->
      case hyperCardMsg of
         GoToSection dest ->
            case model.currentDocument of
               Nothing -> ( model, Cmd.none )
               Just doc ->
                  ( { model | currentSection =
                      findSectionByLabel dest doc.sections }
                    , Cmd.none )
```

Burrowing into the code still further, we see that the
heart of the matter is the function call

```findSectionByLabel dest doc.sections```

Its role is to extract from a list of sections a section
with given name:

```findSectionByLabel : String -> List Section -> Maybe Section```

This is accomplished by a simple application of `List.filter:`

```
findSectionByLabel label_ sections =
      List.filter (\\sec -> getLabel sec == label_) sections
        |> List.head
```
where

```
getLabel { label } =
    case label of
        Camp.Named ( _, s ) ->
            s

        Camp.Anonymous n ->
            String.fromInt n
```


"""