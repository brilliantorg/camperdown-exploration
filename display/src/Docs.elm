module Docs exposing (sample)


sample =
    """


This site provides some documentation for the Camperdown parser, an open source version of the parser used by
[Brilliant.org](link "https://brilliant.org") in the toolchain it uses to build its course offerings in STEM fields.

The Camperdown parser is distinguished by (a) _fault tolerance_ and (b) _configurability._  Fault tolerance is needed
in an interactive editing environment.  Syntax errors, handled gracefully in real time, are displayed
in the rendered text at the point where they occur with a reference to the
line in the source text. Configurability means that the parser can be used
for a wide variety of custom markup languages.  This variety is demonstrated by the apps linked below.


! list >>

  [Campdown](link "https://trusting-jang-9723b7.netlify.app/") — a markup language with many
  features of Markdown but which can be extended without changing the language itelf.

  [Hypercard](link "https://focused-ardinghelli-051c12.netlify.app/") — a simplified resurrection of the
  old Mac Hypercard app (1987).  This was a kind of _web within an app_ featuring text, links, images,
  and other media.  Well before the invention of the world wide web.

  [L0](link "https://cocky-nightingale-a14dab.netlify.app/") — a novel markup language inspired by Lisp.

Code for the parser and for the demo apps is open source:

! list >>

    [Camperdown parser](link "https://package.elm-lang.org/packages/brilliantorg/backpacker-below/latest/")

    [Camperedown explorations](link "https://github.com/brilliantorg/backpacker-below")
    
Documentation:

! list >>

    [Fault Tolerant Parsing in L1](link "https://l1-lab.lamdera.app/g/jxxcarlson-fault-tolerant-parsing-in-l1-2021-07-27")

    The "Pipeline" button below gives some information on how the parser pipeline works.



This demo site is built with a stripped down version of the Campdown app.


"""
