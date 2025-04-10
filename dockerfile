# Use R base image with Plumber
FROM rocker/plumber

# Install necessary R packages
RUN R -e "install.packages(c('httr', 'jsonlite', 'stringr', 'plumber'), repos='http://cran.rstudio.com/')"

# Copy your R scripts into the container
COPY summarizer.R /app/summarizer.R
COPY run_api.R /app/run_api.R

# Set working directory
WORKDIR /app

# Expose Plumber default port
EXPOSE 8000

# Run the Plumber API (run_api.R)
CMD ["R", "-e", "source('run_api.R')"]
