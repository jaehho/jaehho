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
  title: "",
  start-date: "",
  end-date: "",
  company: "",
  location: "",
) = {
  generic-two-by-two(
    top-left: strong(title),
    top-right: dates-helper(start-date: start-date, end-date: end-date),
    bottom-left: company,
    bottom-right: emph(location),
  )
}

#let extracurricular(
  activity: "",
  start-date: "",
  end-date: "",
) = {
  generic-one-by-two(
    left: strong(activity),
    right: dates-helper(start-date: start-date, end-date: end-date),
  )
}

#let project(
  role: "",
  name: "",
  url: "",
  start-date: "",
  end-date: "",
) = {
  generic-one-by-two(
    left: {
      if role == "" {
        [*#name* #if url != "" and dates-helper(start-date: start-date, end-date: end-date) != "" [ (#link("https://" + url)[#url])]]
      } else {
        [*#role*, #name #if url != "" and dates-helper(start-date: start-date, end-date: end-date) != ""  [ (#link("https://" + url)[#url])]]
      }
    },
    right: {
      if dates == "" and url != "" {
        link("https://" + url)[#url]
      } else {
        dates-helper(start-date: start-date, end-date: end-date)
      }
    },
  )
}
