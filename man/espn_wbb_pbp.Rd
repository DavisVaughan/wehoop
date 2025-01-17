% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/espn_wbb_data.R
\name{espn_wbb_pbp}
\alias{espn_wbb_pbp}
\title{Get ESPN women's college basketball play by play data}
\usage{
espn_wbb_pbp(game_id)
}
\arguments{
\item{game_id}{Game ID}
}
\value{
Returns a play-by-play data frame
}
\description{
Get ESPN women's college basketball play by play data
}
\examples{
\donttest{
  try(espn_wbb_pbp(game_id = 401276115))
}
}
\author{
Saiem Gilani
}
\keyword{PBP}
\keyword{WBB}
