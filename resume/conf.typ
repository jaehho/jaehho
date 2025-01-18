#import "@preview/fontawesome:0.5.0": fa-icon
#import "functions.typ": contact-helper

#let conf(
  author: "",
  accent-color: "#000000",
  font: "New Computer Modern",
  paper: "us-letter",
  par-leading: 0.65em,
  par-spacing: 1.2em,
  section-heading-pad-bottom: -10pt,
  doc,
) = {

  // Sets document metadata
  set document(author: author, title: author.replace(" ", "_") + "_Resume")

  // Document-wide formatting
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

  // Paragraph formatting
  set par(
    leading: par-leading,
    spacing: par-spacing,
  )

  // List formatting
  set list(
    
  )

  // Section headings
  show heading.where(level: 2): it => [
    #pad(top: 0pt, bottom: section-heading-pad-bottom, [#smallcaps(it.body)
    #place(dy: 0.2em ,line(length: 100%, stroke: 1pt))]) // smallcaps does not work with arial
    
    // #line(length: 100%, stroke: 1pt)
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
