% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/flash_utils.R
\name{flash_fill}
\alias{flash_fill}
\title{Use a flash fit to fill in missing entries.}
\usage{
flash_fill(Y, f)
}
\arguments{
\item{Y}{A flash data object, or an n by p matrix, used to fit f.}

\item{f}{The flash fit object obtained from running flash on Y.}
}
\value{
A matrix with non-missing entries the same as $Y$, and
  missing entries imputed from the flash fit
}
\description{
Fills in missing entries of Y by using the relevant
  entries of the estimated LDF' from the flash fit.
}
