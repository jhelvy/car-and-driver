library(tidyverse)
library(here)
library(rvest)
library(jsonlite)
library(readr)

################################################################################
                            #NEW Work below
#Init Work
webTracker <- list.files("./webpages")

###########

#For Loop
MainData <- NULL


for(i in webTracker) {
    
    car_data <- data.frame(CarName = character(), MSRP = character(), stringsAsFactors = FALSE)
    
    currentPage <- read_html(paste0("./webpages/", i ,collapse = ""))
    
    #Getting the Full Name
    car_name <- currentPage %>% 
        html_element(".css-1an3ngc.ezgaj230") %>%
        html_text() 
    
    #Getting Car MSRP
    car_msrp <- currentPage %>% 
        html_element(".css-48aaf9.e1l3raf11") %>%
        html_text() 
    car_data <- car_data %>% add_row(CarName = car_name, MSRP = car_msrp)
    
    #Getting all the specs
    specs <- currentPage %>% 
        html_elements(".css-iplmtj.e1oyz7g3") %>% 
        html_elements(".css-1ajawdl.eqxeor30") %>% 
        html_text()
    
    #Gets rid of sections that don't have \n, this was only "special" things that the car has. This stuff contained no actual mechanical data
    specs <- specs[grepl("\n", specs)]
    
    
    #Trimming the front and end \n
    for(i in 1:length(specs)) {
        specs[i] <- str_sub(specs[i], 2, str_length(specs[i]) - 1)
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
    
    #You need this because some columns are non-existant so we just skip
    if(ncol(car_data) < 50) {
        next()
    }
    
    # Append car_data to MainData, ensuring column order consistency
    if (is.null(MainData)) {
        MainData <- car_data
    } else {
        cols_to_select <- intersect(names(MainData), names(car_data))
        car_data <- car_data[, cols_to_select]
        MainData <- MainData[, cols_to_select]
        MainData <- rbind(MainData, car_data[, names(MainData)])
    }
}
    


#write.csv(MainData, "car_data.csv", row.names = FALSE)
#
Main1 <- MainData
#
Main1[] <- lapply(Main1, as.character)
#
write.csv(Main1, "MainData.csv", row.names = FALSE)








   