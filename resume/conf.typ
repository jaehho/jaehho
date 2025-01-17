#import "@preview/fontawesome:0.5.0": fa-icon
#import "functions.typ": contact-helper

#let conf(
  author: "",
  accent-color: "#000000",
  font: "New Computer Modern",
  paper: "us-letter",
  doc,
) = {

  // Sets document metadata
  set document(author: author, title: author.replace(" ", "_") + "_Resume")

  // Document-wide formatting, including font and margins
  set text(
    font: font,
    size: 10pt,
    lang: "en",
    // Disable ligatures so ATS systems do not get confused when parsing fonts.
    ligatures: false
  )

  // Page formatting
  set page(
    margin: (0.5in),
    paper: paper,
  )

  // Small caps for section titles
  show heading.where(level: 2): it => [
    #pad(top: 0pt, bottom: -10pt, [#smallcaps(it.body)])
    #line(length: 100%, stroke: 1pt)
  ]

  // Accent Color Styling
  show heading: set text(
    fill: rgb(accent-color),
  )

  show link: set text(
    fill: rgb(accent-color),
  )
  
  doc
}
