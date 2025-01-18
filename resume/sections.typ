#import "functions.typ": *

#let edu(
  institution: "",
  start-date: "",
  end-date: "",
  degree: "",
  gpa: "",
  location: "",
) = {
  generic-two-by-two(
    top-left: strong(institution),
    top-right: location,
    bottom-left: emph(degree),
    bottom-right: emph(dates-helper(start-date: start-date, end-date: end-date)),
  )
}

#let work(
  position: "",
  details: "",
  start-date: "",
  end-date: "",
  company: "",
  location: "",
) = {
  generic-two-by-two(
    top-left: [#strong(position) #if details != "" [ | #details]],
    top-right: emph(dates-helper(start-date: start-date, end-date: end-date)),
    bottom-left: [#emph(company) #sym.bullet #location],
    bottom-right: "",
  )
}

#let extracurricular(
  title: "",
  details: "",
  start-date: "",
  end-date: "",
) = {
  generic-one-by-two(
    left: [#strong(title) #if details != "" [ | #details]],
    right: emph(dates-helper(start-date: start-date, end-date: end-date)),
  )
}

#let project(
  name: "",
  role: "",
  start-date: "",
  end-date: "",
) = {
  generic-one-by-two(
    left: {
      if role == "" {
        [*#name*]
      } else {
        [*#name* (#role)]
      }
    },
    right: {
        emph(dates-helper(start-date: start-date, end-date: end-date))
    },
  )
}
