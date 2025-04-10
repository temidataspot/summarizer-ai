library(plumber)
r <- plumb("summarizer.R")
r$run(port = 8000)
