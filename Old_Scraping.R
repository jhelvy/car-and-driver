library(tidyverse)
library(rvest)
library(microbenchmark)
library(parallel)

full_df <- read_csv(here::here('full-urls.csv'))

saveWebpage <- function() {
  urls <- full_df %>%
    filter(!is.na(full_url)) %>%
    select(trim_value, full_url) %>%
    slice(4393:n())
  for (i in seq(1, nrow(urls))) {
    tryCatch(
      expr = {
        url <- as.character(urls$full_url[i])
        trim_number <- paste0('webpages/', as.character(urls$trim_value[i]), '.html')
        jph::write_html(url, file = trim_number)
        print(i)
      },
      error = function(e) {
        print('Encountered an error:')
        print(e)
      },
      warning = function(w) {
        print('Found a warning:')
        print(w)
      }
    )
  }
}
# exec_time <- microbenchmark(saveWebpage(), times=1L)
# print(exec_time)

# The function below returns the string of all data values from the Car and Driver
#   spec table for any given vehicle trim.
datapoint_str <- function(pathToFile, subrow_index, section_index=6) {
  data_table <- read_html(pathToFile) %>%
    html_elements(".e1oyz7g6")
  vec <- c(
    data_table[{{ section_index }}] %>%
      html_elements(".eqxeor30") %>%
      html_text2()
  )
  row_val <- str_split_i(vec[subrow_index], ("\\n"), 2)
  return(row_val)
}

createEmptyTibble <- function(dataframe, num_rows, variables) {
  for (i in seq(1, num_rows)) {
    for (j in variables) {
      dataframe[i, j] <- NA
    }
    print(i)
  }
  return(dataframe)
}

getWheelbaseAndTrackWidth <- function() {
  WHEELBASE <- 1
  LENGTH <- 2
  WIDTH <- 3
  HEIGTH <- 4
  FRONT_TRACKWIDTH <- 5
  REAR_TRACKWIDTH <- 6
  NUM_FILES <- 40956
  FULL_FOLDER <- './webpages'
  TEST_FOLDER <- './html_test_files'
  TEST_FILES <- c(439668, 439785, 440081, 440568, 441602)
  vars <- c('trim_value', 'wheelbase', 'length', 'width', 'fron_trackwidth', 'rear_trackwidth')
  df <- tibble()
  # To test this and related functions with the test files included in the repo,
  #   change path='./webpages' to path='./html_test_files' if using the cloned repo structure.
  # Also make sure to pipe this: filter(trim_value %in% TEST_FILES), from the csv_file assignment
  #   down the bottom. This ensures that the following left_join() function works by having the
  #   same trim values in both resulting dataframes. And make sure to change the 5 in createEmptyTibble()
  #   to the NUM_FILES constant.
  createEmptyTibble(df, NUM_FILES, vars)
  html_files <- list.files(path=FULL_FOLDER, pattern="html$", full.names=TRUE)
  i <- 1
  for (file_path in html_files) {
    trim_url <- read_html(file_path) %>%
      html_element('link') %>%
      html_attr('href')
    df[i, 'trim_value'] <- str_split(trim_url, "/")[[1]] %>%
      tail(1) %>%
      as.numeric()
    df[i, 'wheelbase'] <- file_path %>%
      datapoint_str(subrow_index=WHEELBASE) %>%
      as.numeric()
    df[i, 'length'] <- file_path %>%
      datapoint_str(subrow_index=LENGTH) %>%
      as.numeric()
    df[i, 'width'] <- file_path %>%
      datapoint_str(subrow=WIDTH) %>%
      as.numeric()
    df[i, 'front_trackwidth'] <- file_path %>%
      datapoint_str(subrow=FRONT_TRACKWIDTH) %>%
      as.numeric()
    df[i, 'rear_trackwidth'] <- file_path %>%
      datapoint_str(subrow=REAR_TRACKWIDTH) %>%
      as.numeric()
    print(i)
    i <- i + 1
    #         if (i > 5) {
    #             break
    #         }
  }
  #     print(df)
  glimpse(df)
  csv_file <- tibble(full_df) # %>%
  #         filter(trim_value %in% TEST_FILES) # See note above ^^^
  glimpse(csv_file)
  df2 <- left_join(csv_file, df, by = 'trim_value')
  write_csv(df2, file = file.path('result_csv_files', 'final_df_v1.csv'))
  glimpse(df2)
}
exec_time <- microbenchmark(getWheelbaseAndTrackWidth(), times=1L)
print(exec_time)
# Alternative timing with {tictoc}
# tictoc::tic()
# getWheelbaseAndTrackWidth()
# tictoc::toc()