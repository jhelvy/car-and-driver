# Load required libraries
library(readxl)
library(httr)

# Read the Excel file
file_path <- "addUrl.xlsx" # Replace with your actual file path
df <- read_excel(file_path)

# Ensure you have the columns "trim_value" and "full_url"
if (!all(c("trim_value", "full_url") %in% colnames(df))) {
    stop("The Excel file must contain 'trim_value' and 'full_url' columns")
}

# Create the directory if it doesn't exist
output_dir <- "newpages"
if (!dir.exists(output_dir)) {
    dir.create(output_dir)
}

# Function to download a single URL
download_html <- function(url, output_dir, trim_value) {
    file_name <- paste0(output_dir, "/", trim_value, ".html")
    GET(url, write_disk(file_name, overwrite = TRUE))
}

# Loop through each URL and download the HTML file
for (i in 1:nrow(df)) {
    download_html(df$full_url[i], output_dir, df$trim_value[i])
}
