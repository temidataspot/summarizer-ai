# Developing a system that can automatically summarize detailed text descriptions
# into concise 2-5 word phrases following a specific style and format. 
# Using 1000 examples of input text and their corresponding summaries that 
# demonstrate the exact style and format required.

# Install packages and load libraries
library(readr)
library(httr)
library(jsonlite)
library(dplyr)
library(curl)
library(stringr)

# Load the cleaned dataset  or create a new df as prototype
cleaned_summaries <- data.frame(
  Detailed_Description = c(
    "The warehouse experienced a delay in shipment due to severe weather conditions.",
    "Customer reported issue with payment processing on the mobile app during peak hours.",
    "Customer service resolved a complaint regarding overcharged invoice for last month.",
    "Product review mentioned defective packaging and leakage on delivery.",
    "User submitted a ticket about login errors after recent system update.",
    "Technical team investigated database timeout errors during backup process.",
    "Marketing team requested a report on customer engagement by region.",
    "Survey results indicate user dissatisfaction with current navigation design.",
    "Email campaign analytics show a drop in open rates compared to previous quarter.",
    "Multiple users reported slow load times when accessing dashboard features."
  ),
  Concise_Summary = c(
    "Shipment delay",
    "Payment issue",
    "Invoice correction",
    "Packaging defect",
    "Login error",
    "Database timeout",
    "Engagement report",
    "Navigation feedback",
    "Drop in open rates",
    "Slow dashboard load"
  )
)

# Save the data frame as a CSV file
write_csv(cleaned_summaries, "cleaned_summaries.csv")
View(cleaned_summaries)

# Function to create a prompt using examples from the dataset
create_prompt <- function(input_text, example_count = 3) {
  example_count <- min(example_count, nrow(cleaned_summaries))
  examples <- cleaned_summaries[sample(nrow(cleaned_summaries), example_count), ]
  
  prompt <- "Generate a concise 2-5 word summary for each detailed text:\n\n"
  for (i in 1:nrow(examples)) {
    prompt <- paste0(prompt,
                     "Text: ", examples$Detailed_Description[i], "\n",
                     "Summary: ", examples$Concise_Summary[i], "\n\n")
  }
  
  prompt <- paste0(prompt, "Text: ", input_text, "\nSummary:")
  return(prompt)
}

# CASE A: Using HuggingFace API [temilovesdata]

library(plumber)
library(httr)
library(jsonlite)
library(stringr)

summarize_text <- function(input_text, api_key) {
  prompt <- paste0(
    "<|system|>\n",
    "You are a professional summarizer. Return only concise, correctly spelled summaries in 2 to 5 words. ",
    "Use a clean, business-style phrase with no punctuation or sentence structure. ",
    "Do not return full sentences. Do not include explanations. Do not abbreviate.\n",
    "Example: \"Mobile payment issue\"\n",
    "<|user|>\n",
    "Summarize:\n",
    input_text,
    "\n<|assistant|>"
  )
  
  response <- POST(
    url = "https://api-inference.huggingface.co/models/HuggingFaceH4/zephyr-7b-beta",
    add_headers(Authorization = paste("Bearer", api_key)),
    body = list(inputs = prompt),
    encode = "json"
  )
  
  # Parse response safely
  raw <- content(response, "parsed")
  generated <- raw[[1]]$generated_text
  
  # Extract only the summary text
  summary <- sub(".*<\\|assistant\\|>\\s*", "", generated)
  summary <- str_trim(summary)
  summary <- gsub('^"|"$', '', summary)  # remove quotes if present
  
  # Enforce 2–5 word summary
  words <- str_split(summary, "\\s+")[[1]]
  word_count <- length(words)
  
  if (word_count < 2) {
    summary <- "Insufficient summary"
  } else if (word_count > 5) {
    summary <- paste(words[1:5], collapse = " ")
  }
  
  return(summary)
}


#* @post /summarize
#* @param input_text The text to summarize
function(input_text) {
  api_key <- "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"
  summary <- summarize_text(input_text, api_key)
  list(summary = summary)
}

