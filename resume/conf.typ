#import "functions.typ": contact-helper

#let conf(
  author: "",
  paper: "us-letter",
  accent-color: "#000000",
  font: "New Computer Modern",
  font-size: 10pt,
  paragraph-leading: 0.65em,
  paragraph-spacing: 1.2em,
  section-heading-margin-top: 1em,
  section-heading-margin-bottom: 0pt,
  border-margin: 0.3in,
  doc,
) = {

  // Sets document metadata
  set document(author: author, title: author.replace(" ", "_") + "_Resume")

  // Document-wide formatting
  set text(
    font: font,
    size: font-size,
    // Disable ligatures so ATS systems do not get confused when parsing fonts.
    ligatures: false
  )

  // Page formatting
  set page(
    margin: (0.5in),
    paper: paper,
    background: context {
      place(dx: border-margin, dy: border-margin, rect(width: page.width - border-margin*2, height: page.height - border-margin*2, stroke: 0.5pt))
    }
  )

  // Paragraph formatting
  set par(
    leading: paragraph-leading,
    spacing: paragraph-spacing,
  )

  // List formatting
  set list(
    
  )

  // Section headings
  show heading.where(level: 2): it => [
    #v(-1em)
    #pad(top: section-heading-margin-top, bottom: section-heading-margin-bottom, [#smallcaps(it.body)
    #place(dy: 0.2em ,line(length: 100%, stroke:0.5pt))]) // smallcaps does not work with arial
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
