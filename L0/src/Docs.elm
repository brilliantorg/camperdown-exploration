module Docs exposing (sourceText)


sourceText =
    """






[image [opt caption:The L0 Mascot] https://www.nhm.ac.uk/content/dam/nhmwww/discover/garden-birds/winter-birds-blue-tit-two-column.jpg.thumb.768.768.jpg]

[heading1 The L0 Markup Language (Draft)]

L0 is a simple yet versatile markup language that takes inspiration from Lisp.  An L0 document consists of ordinary text and [quote M-expressions], e.g., `[blue flowers]`, which is rendered as [blue flowers].  M-expressions can be nested, as in `[blue [i delicate blue] flowers]`, which renders as [blue [i delicate blue] flowers].

In addition to the [quote pure L0] just described, we have borrowed from Markdown.  For example, inline code can set off by backticks:

%%%
      This is code: `a[i] = a[i] + 1`

Here is the rendered version:

[indent  This is code: `a[i] = a[i] + 1`]

The version of L0 that you see here is implemented in [link Elm https://elm-lang.org] using the [link Camperdown https://package.elm-lang.org/packages/brilliantorg/backpacker-below/latest] library. Camperdown is an open-source version of the fault-tolerant parser developed at [link Briliant.org https://brilliant.org] for the tools used by the authors of their courses in STEM fields.  Because Camperdown is a  [i configurable] parser, it can be used to build quite a variety of apps, e.g.,

[item [link "Campdown Demo" https://trusting-jang-9723b7.netlify.app/]]

[item [link "Hypercard Demo" https://focused-ardinghelli-051c12.netlify.app/]]

[item [link "This L0 Demo" https://cocky-nightingale-a14dab.netlify.app/]]

[heading2 Widgets]



In L0, one can easily implement [i widgets] that display data, carry out computations, or produce graphical output.


[heading3 Tables]

%%%
      [datatable H, 1, 1.008; He, 2, 4.003;]

[indent
[datatable H, 1, 1.008; He, 2, 4.003; Li, 3, 6.940; Be, 4, 9.012; B, 5, 10.810; C, 6, 12.011; N, 7, 14.007; O, 8, 15.999; F, 9, 18.998; Ne, 10, 20.180;]
]

[heading3 Computations]


%%%
      [sum 11.4 4.5 -7.7]

It renders as

[indent
   [sum 11.4 4.5 -7.7]
]

One can also specify a precision:

%%%
      [sum [opt precision:3] 0.02 0.015 -0.009]

This renders as

[indent
   [sum [opt precision:3] 0.02 0.015 -0.009]
]

[heading3 Graphs]

%%%
   [bargraph 1.2, 1.3, 2.4, 3.1, 2.9, 2.2, 1.8, 2.5, 2.7]

[bargraph 1.2, 1.3, 2.4, 3.1, 2.9, 2.2, 1.8, 2.5, 2.7]


[heading3 Footnote]

For those curious about the origin of the name [quote Camperdown parser], the clue is in the photograph below. Taken in Prospect Park, Brooklyn, its subject is a particular interesting species of Elm tree, [i Ulmus glabra 'Camperdownii'].  Courtesy of Wikimedia Foundation.

[image [opt caption: Camperdown Elm Tree] `https://upload.wikimedia.org/wikipedia/commons/2/20/Camperdown_Elm_Prospect_Park_Brooklyn.jpg`]




"""
