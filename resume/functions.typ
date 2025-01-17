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
