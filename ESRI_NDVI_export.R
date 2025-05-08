library(terra)

full_set <-
  readRDS("./full_set.rds")

# Create export folder if needed
dir.create("ndvi_tiffs", showWarnings = FALSE)

# Get dates
dates <- time(full_set)

# Track duplicates
date_counts <- table(format(dates, "%Y%m%d"))
name_tracker <- list()

for (i in seq_along(dates)) {
  date_str <- format(dates[i], "%Y%m%d")
  
  # Count how many times we've seen this date
  if (is.null(name_tracker[[date_str]])) {
    name_tracker[[date_str]] <- 1
  } else {
    name_tracker[[date_str]] <- name_tracker[[date_str]] + 1
  }
  
  # Create unique filename
  suffix <- if (name_tracker[[date_str]] > 1) {
    paste0("_", name_tracker[[date_str]])
  } else {
    ""
  }
  
  filename <- file.path("ndvi_tiffs", paste0(date_str, suffix, ".tif"))
  
  # Write raster
  writeRaster(full_set[[i]],
              filename = filename,
              overwrite = TRUE,
              NAflag = -9999)
}

