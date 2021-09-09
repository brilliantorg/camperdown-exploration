module Docs exposing (sourceText)

sourceText = """

[image [opt width:300, caption:'Blue bird'] https://www.nhm.ac.uk/content/dam/nhmwww/discover/garden-birds/winter-birds-blue-tit-two-column.jpg.thumb.768.768.jpg]

[heading1 The L0 Markup Language (Draft)]

L0 is a simple yet versatile markup language that takes inspiration from Lisp.  An L0 document consists of ordinary text and [quote M-expressions], e.g., `[blue flowers]`, which is rendered as [blue flowers].  M-expressions can be nested, as in `[blue [i delicate blue] flowers]`, which renders as [blue [i delicate blue] flowers].

In addtions to the [quote pure L0] just described, we have borrowed from Markdown.  For example, inline code can set off by backticks:

%%%
     This is code: `a[i] = a[i] + 1`

The version of L0 that you see here is implemented in [link Elm https://elm-lang.org] using the [link Camperdown https://package.elm-lang.org/packages/brilliantorg/backpacker-below/latest] library.

Camperdown is an open-source version of the fault-tolerant parser developed at [link Briliant.org https://brilliannt.org] for the tools used by the authors of their courses in STEM fields.  Because Camperdown is a  [i configurable] parser, it can be used to build quite diffrent apps, e.g.,

[item [link "Campdown Demo" https://trusting-jang-9723b7.netlify.app/]]

[item [link "Hypercard Demo" https://focused-ardinghelli-051c12.netlify.app/]]

[item [link "L0 Demo" https://cocky-nightingale-a14dab.netlify.app/]]

[heading2 To be continued]

In the Spring, I will be looking for [blue blue flowers] and [red [i red butterflies!]]


[image https://www.nhm.ac.uk/content/dam/nhmwww/discover/garden-birds/winter-birds-blue-tit-two-column.jpg.thumb.768.768.jpg]

"""