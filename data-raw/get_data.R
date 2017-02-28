library(countrycode)
library(tabulizer)
library(tidyverse)

convert_to_df <- function(tbl) {
  df <- as_data_frame(tbl)
  nm <- trimws(df[1, ])
  df <- df[-1, ]
  set_names(df, c("country", nm[-1]))
}

bind_tables <- function(tbls) {
  tbls %>%
    map(convert_to_df) %>%
    bind_rows() %>%
    gather(year, value, -country) %>%
    mutate(year = as.numeric(year),
           value = as.numeric(value),
           country = trimws(country))
}

labs <- c("Transparency by Region",
          "Augmented Transparency by Region",
          "Regional Transparency Index (Weighted)",
          "Regional Augmented Transparency Index (Weighted)")

# Main
url <- "http://eml.berkeley.edu/~eichengr/Dincer-Eichengreen_figures&tables_2014_9-4-15.pdf"
tmp <- tempfile(fileext = ".pdf")
download.file(url, tmp, mode = "wb")

tbls <- tabulizer::extract_tables(tmp)

# Extract relevant data tables (excludes regression tables)
transp <- list(1:3, 4:6, 7, 8) %>% map(~bind_tables(tbls[.]))

# Add table labels
transp <- map2_df(transp, labs, ~mutate(.x, measure = .y))

# Add country codes
transp <- transp %>%
  mutate(
    iso2c = countrycode(country, "country.name", "iso2c"),
    iso2c = ifelse(country == "Euro Area", "EA", iso2c)
  )

transp$iso2c[transp$country == "Australia and New"] <- NA
transp$country[transp$country == "Australia and New"] <- "Australia and New Zeeland"

devtools::use_data(transp)
