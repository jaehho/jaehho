#import "@preview/fontawesome:0.5.0": fa-icon

// Generic two by two binding
#let generic-two-by-two(
  top-left: "",
  top-right: "",
  bottom-left: "",
  bottom-right: "",
) = {
  [
    #top-left #h(1fr) #top-right \
    #bottom-left #h(1fr) #bottom-right
  ]
}

// Generic one by two binding
#let generic-one-by-two(
  left: "",
  right: "",
) = {
  [
    #left #h(1fr) #right
  ]
}

// Dates formatting binding
#let dates-helper(
  start-date: "",
  end-date: "",
) = {
  start-date + " " + sym.dash.en + " " + end-date
}

// Contact item binding
#let contact-helper(value, prefix: "", link-type: "") = {
  if value != "" {
    if link-type != "" {
      link(link-type + value)[#(prefix + " " + value)]
    } else {
      prefix + " " + value
    }
  }
}

// Header binding
#let header(
  name: "",
  location: "",
  phone: "",
  email: "",
  linkedin: "",
  website: "",
) = {
  [
    #show heading.where(level: 1): it => [
      #set align(center)
      #set text(
        weight: 700,
        size: 20pt,
      )
      #pad(it.body)
    ]
    = #name

    #pad(
      top: 0.25em,
      align(center)[
        #{
          let fa-icon-size = 8pt
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
  ]
}
