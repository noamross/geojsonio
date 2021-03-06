% Generated by roxygen2 (4.1.1): do not edit by hand
% Please edit documentation in R/topojson_read.R
\name{topojson_read}
\alias{topojson_read}
\title{Read topojson from a local file or a URL}
\usage{
topojson_read(x, ...)
}
\arguments{
\item{x}{Path to a local file or a URL.}

\item{...}{Further args passed on to \code{\link[rgdal]{readOGR}}}
}
\description{
Read topojson from a local file or a URL
}
\examples{
\donttest{
# From a file
file <- system.file("examples", "us_states.topojson", package = "togeojson")
geojson_read(file)

# From a URL
url <- "https://raw.githubusercontent.com/shawnbot/d3-cartogram/master/data/us-states.topojson"
topojson_read(url)

# Use as.location first if you want
topojson_read(as.location("~/zillow_or.geojson"))
}
}

