library(tidyverse)
library(here)
library(rvest)
library(jsonlite)
library(readr)

################################################################################
                            #NEW Work below


###########

oldData <- read_csv(paste0(here(),"/result_csv_files/final_df_v1.csv"))
View(oldData)
#For Loop
#MainData <- NULL

webTracker <- list.files("./webpages")
webTracker <- webTracker[30000:length(webTracker)]


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
                           URL = character()
                           )
    
    currentPage <- read_html(paste0("./webpages/", i ,collapse = ""))
    
    #Getting the Full Name
    
    mmS <- car_name <- currentPage %>%
        html_nodes(xpath = '//*[@class="e9l0kn00 css-2t95om epl65fo4"]') %>%
        html_text()
    
    make <- mmS[2]
    
    model <- mmS[3]
    
    style <- currentPage %>% 
        html_element(xpath = '//*[@id="styleSelect"]/option[2]') %>% 
        html_text()
    
    year <- currentPage %>% 
        html_elements('.css-1an3ngc.ezgaj230') %>% 
        html_text()
    year <- substring(year,1,4)
    
    #Getting Car MSRP
    car_msrp <- currentPage %>% 
        html_element(".css-48aaf9.e1l3raf11") %>%
        html_text() 
    
    trim <- substring(i,1, (str_length(i)-5))
        
    url <- NA
    
    curb <- currentPage %>% 
        html_element(".css-48aaf9.e1l3raf11") %>%
        html_text() 
    
    
    car_data <- car_data %>% add_row(Make = make, 
                                     Model = model,
                                     Style = style,
                                     Year = year,
                                     MSRP = car_msrp,
                                     Trim = trim,
                                     URL = url
                                     )
    
    #Getting all the specs
    specs <- currentPage %>% 
        html_elements(".css-iplmtj.e1oyz7g3") %>% 
        html_elements(".css-1ajawdl.eqxeor30") %>% 
        html_text()
    
    #Gets rid of sections that don't have \n, this was only "special" things that the car has. This stuff contained no actual mechanical data
    specs <- specs[grepl("\n", specs)]
    
    
    #Trimming the front and end \n
    for(j in 1:length(specs)) {
        specs[j] <- str_sub(specs[j], 2, str_length(specs[j]) - 1)
    }
    
    
    #Create a names and values list
    names <- list()
    values <- list()
    
    specs <- strsplit(specs, "\n") #Split on the middle \n
    
    # Loop through the specs and split into names and values
    for (spec in specs) {
        name <- spec[1] # First element is the name - will be our column name
        value <- spec[2] # Second element is the value - will be our row name
        names <- c(names, name)
        values <- c(values, value)
    }
    #Adding values, col names, and binding it to the main car_data
    specs_df <- data.frame(t(values), stringsAsFactors = FALSE)
    names(specs_df) <- names
    car_data <- cbind(car_data, specs_df)
    
    if (is.null(MainData)) {
        MainData <- car_data
    } else {
        MainData <- bind_rows_safely(MainData, car_data)
    }
}
   
Main1 <- MainData
 
Main1$Trim <- as.character(Main1$Trim)
oldData$trim_value <- as.character(oldData$trim_value)

# Perform a left join to add the URL from oldData to Main1 based on Trim
Main1 <- Main1 %>%
    left_join(oldData %>% select(trim_value, full_url), by = c("Trim" = "trim_value"))

Main1 <- Main1 %>% select(-URL)

Main1 <- Main1 %>%
    relocate(full_url, .after = 6)


#write.csv(MainData, "car_data.csv", row.names = FALSE)
#
##
Main1[] <- lapply(Main1, as.character)
##
write.csv(Main1, "MainData.csv", row.names = FALSE)
#
#arrow::write_parquet(Main1, "data.parquet")
#
#old <- read_csv(paste0(here::here(), "/result_csv_files/","final_df_v1.csv", collaspe = ""))
#



   