library(tidyverse)
library(here)
library(rvest)
library(jsonlite)
library(readr)

################################################################################
                            #NEW Work below


###########

#oldData <- read_csv(paste0(here(),"/result_csv_files/final_df_v1.csv"))
#View(oldData)
#For Loop
Main <- NULL

webTracker <- list.files("./newPages")

#webTracker <- webTracker[30000:length(webTracker)]





bind_rows_safely <- function(df1, df2) {
    # Identify columns in df1 not in df2
    cols_missing_in_df2 <- setdiff(names(df1), names(df2))
    # Identify columns in df2 not in df1
    cols_missing_in_df1 <- setdiff(names(df2), names(df1))
    
    # Add missing columns to df2
    for (col in cols_missing_in_df2) {
        df2[[col]] <- NA
    }
    
    # Add missing columns to df1
    for (col in cols_missing_in_df1) {
        df1[[col]] <- NA
    }
    
    # Reorder columns to match df1
    df2 <- df2[, names(df1)]
    
    # Bind rows together
    bind_rows(df1, df2)
}



for(i in webTracker) {
    
    car_data <- data.frame(Make = character(), 
                           Model = character(),
                           Style = character(),
                           Year = character(),
                           MSRP = character(),
                           Trim = character(),
                           Trim_Number = character(),
                           URL = character()
                           )
    
    currentPage <- read_html(paste0(here(),"/newPages/", i))
    
    #Getting the Full Name
    
    make <- currentPage %>%
        html_nodes(xpath = '//*[@id="main-content"]/div[2]/div[1]/nav/ol/li[2]/a') %>%
        html_text()
    
    model <- currentPage %>%
        html_nodes(xpath = '//*[@id="main-content"]/div[2]/div[1]/nav/ol/li[3]/a') %>%
        html_text()
    
    style <- currentPage %>% 
        html_element(xpath = '//*[@id="styleSelect-wrapper"]/div/div[1]') %>% 
        html_text()
    
    year <- currentPage %>% 
        html_elements('.css-19lw4a6.edfupbv0') %>% 
        html_text()
    year <- substring(year,1,4)
    
    #Getting Car MSRP
    car_msrp <- currentPage %>% 
        html_element(".css-f1ylyv.e1c3m9of1") %>%
        html_text() 
    
    trim_no <- substring(i,1, (str_length(i)-5))
    
    trim <- currentPage %>% 
        html_element(xpath = '//*[@id="main-content"]/div[2]/div[3]/div[1]/div[2]') %>% 
        html_text() %>%  
        sub(" Package Includes$", "",.)
    
        
    url <- NULL
    
    curb <- currentPage %>% 
        html_element(".css-48aaf9.e1l3raf11") %>%
        html_text() 
    
    
    car_data <- car_data %>% add_row(Make = make, 
                                     Model = model,
                                     Style = style,
                                     Year = year,
                                     MSRP = car_msrp,
                                     Trim = trim,
                                     Trim_Number = trim_no,
                                     URL = url
                                     )
    
    specs_parent <- currentPage %>% 
        html_elements(".css-9dhox.etxmilo0")
    
    textbox1 <- specs_parent %>% 
        html_elements("div:nth-child(1)") %>% 
        html_text()
    
    textbox2 <- specs_parent %>% 
        html_elements("div:nth-child(2)") %>% 
        html_text()
    
    # Ensure equal lengths of textbox1 and textbox2
    if (length(textbox1) != length(textbox2)) {
        # Handle mismatched lengths, perhaps by filling with NA
        max_length <- max(length(textbox1), length(textbox2))
        textbox1 <- c(textbox1, rep(NA, max_length - length(textbox1)))
        textbox2 <- c(textbox2, rep(NA, max_length - length(textbox2)))
    }
    
    # Adding values, column names, and binding it to the main car_data
    specs_df <- data.frame(t(textbox2), stringsAsFactors = FALSE)
    names(specs_df) <- textbox1
    car_data <- cbind(car_data, specs_df)
    
    if (is.null(Main)) {
        Main <- car_data
    } else {
        Main <- bind_rows_safely(Main, car_data)
    }
}


url_data <- read_excel("addUrl.xlsx")  # Update the path to your addUrl.xlsx file

url_data <- url_data %>%
    rename(Trim_Number = trim_value, full_url = full_url) %>%
    mutate(Trim_Number = as.character(Trim_Number))  # Ensure Trim_Number is character

# Ensure Trim_Number in Main is character
Main <- Main %>%
    mutate(Trim_Number = as.character(Trim_Number))

# Perform the left join
Main <- Main %>%
    left_join(url_data %>% select(Trim_Number, full_url), by = "Trim_Number")

# Remove any existing URL column if it exists
Main <- Main %>%
    select(-URL)

# Relocate full_url to the desired position
Main <- Main %>%
    relocate(full_url, .after = 6)



#Combining

MainData <- read.csv("MainData.csv")

MainData <- MainData %>%
    mutate(across(everything(), as.character))

Main <- Main %>%
    mutate(across(everything(), as.character))

missing_cols_in_MainData <- setdiff(names(Main), names(MainData))
for (col in missing_cols_in_MainData) {
    MainData[[col]] <- NA
}

missing_cols_in_Main <- setdiff(names(MainData), names(Main))
for (col in missing_cols_in_Main) {
    Main[[col]] <- NA
}

MainData <- MainData[, names(Main)]

CombinedData <- bind_rows(Main, MainData)

#write.csv(CombinedData, "MainData.csv", row.names = FALSE)
##
#arrow::write_parquet(CombinedData, "data.parquet")










   