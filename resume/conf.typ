#import "@preview/fontawesome:0.5.0": fa-icon
#import "functions.typ": contact-helper

#let resume(
  name: "",
  location: "",
  email: "",
  phone: "",
  linkedin: "",
  website: "",
  accent-color: "#000000",
  font: "New Computer Modern",
  paper: "us-letter",
  fa-icon-size: 8pt,
  body,
) = {

  // Sets document metadata
  set document(author: name, title: name.replace(" ", "_") + "_Resume")

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

  // Name Styling
  show heading.where(level: 1): it => [
    #set align(center)
    #set text(
      weight: 700,
      size: 20pt,
    )
    #pad(it.body)
  ]
  [= #(name)]

  // Personal Info
  pad(
    top: 0.25em,
    align(center)[
      #{
        let items = (
          contact-helper(location, prefix: fa-icon("location-dot", size: fa-icon-size)),
          contact-helper(phone, prefix: fa-icon("phone", size: fa-icon-size)),
          contact-helper(email, prefix: fa-icon("envelope", size: fa-icon-size), link-type: "mailto:"),
          contact-helper(linkedin, prefix: fa-icon("linkedin-in", size: fa-icon-size), link-type: "https://linkedin.com/in/"),
          contact-helper(website, prefix: fa-icon("link", size: fa-icon-size), link-type: "https://"),
        )
        items.filter(x => x != none).join("    ")
      }
    ],
  )
  
  body
}
