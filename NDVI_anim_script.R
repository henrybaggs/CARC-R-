# load packages


library(tidyverse)
library(terra)
library(tiff)
library(sf)
library(gganimate)
library(tidyterra)
library(plotly)
library(viridis)
library(RColorBrewer)
library(htmlwidgets)
library(gifski)



# unzip("./CARC/output.zip", exdir = "./Data/", overwrite = F)

# list("./Data/")

# Create a test path for troubleshooting 
test_path <- "./Data/files/PSScene/20231126_172503_80_2460/analytic_udm2/20231126_172503_80_2460_3B_AnalyticMS.tif"


# Create a data frame with decimal degree coordinates of the CARC extent
coords <- data.frame(
  id = 1:4,
  longitude = c(-109.969, -109.946),
  latitude = c(47.0520, 47.0704)
)

# Convert to sf object with WGS84 CRS
coords_sf <- st_as_sf(coords, coords = c("longitude", "latitude"), crs = 4326)

# Transform to UTM (replace 32632 with the appropriate UTM zone)
coords_utm <- st_transform(coords_sf, crs = 32612)

# Load all wanted files into one object
all_img <- 
  list.files(path = "./Data/files/Scene2_clean/files/PSScene/", pattern = ".*_AnalyticMS\\.tif$", recursive = TRUE, full.names = TRUE)



# Create a function to calculate NDVI and remove bad data
t_funct <-
  function(f) {
    
    udm_path <- str_replace(f, "AnalyticMS", "udm2")
    
    if (!file.exists(udm_path)) {
      message("UDM2 file missing for ", f)
      return(NULL)
    }
    
    # make cropped data raster
    rr <- 
      rast(f) %>%
      crop(coords_utm) %>%
      extend(coords_utm) 
    
    # make cropped mask raster
    mask <- 
      rast(udm_path) %>%
      crop(coords_utm) %>%
      extend(coords_utm) 
    
    # define cloud and clear bands
    cloud_band <- mask[[6]]
    clear_band <- mask[[1]]
    
    # Get total pixels in each mask layer
    total_px <- 
      global(!is.na(cloud_band), 
             fun = "sum")[[1]]
    
    # Calculate cloud percentages
    cloud_px <- 
      global(cloud_band, 
             fun = "sum", 
             na.rm = TRUE)[[1]]
    cloud_pct <- cloud_px / total_px
    
    # calculate valid data pct
    valid_px <- 
      global(clear_band, 
             fun = "sum", 
             na.rm = TRUE)[[1]]
    valid_pct <- valid_px / total_px
    
    # Filter conditions
    if (cloud_pct > 0.5 || valid_pct < 0.75) {
      message("Skipping due to cloud or NA threshold: ", f)
      return(NULL)
    }
    
    f_red <- rr[[3]]
    f_NIR <- rr[[4]]
    
    f_ndvi <- 
      (f_NIR - f_red)/(f_NIR + f_red)
    
    time(f_ndvi) <- 
      as.Date(
        str_extract(f, "\\d{8}"), 
        format = "%Y%m%d")
    
    return(f_ndvi)
  }
  
  
# Create a custom NDVI Palette  
NDVI_palette <- colorRampPalette(c("red", "yellow", "green4"))


# Create a small list of images to test on
test_img <- 
  head(all_img)

test_set <-
  lapply(test_img, t_funct) %>%
  rast()

# Generate NDVI for the full image set


full_set <- readRDS("./full_set.rds")

full_set <- 
  full_set %>%
  subset(time(full_set) >= as.Date("2024-02-17"))

#animate 

full_set <-
  lapply(all_img, t_funct) %>%
  compact() %>%
  rast()

anim_para <-
  full_set %>%
  terra::animate(pause = .2, 
                 n = 1, 
                 col = NDVI_palette(50),
                 range = c(-1, 1),
                 main = format(time(full_set), "%Y-%m-%d"))



save_gif(expr = full_set %>%
           terra::animate(pause = 0.1, 
                          n = 1, 
                          col = NDVI_palette(50),
                          range = c(-1, 1),
                          main = format(time(full_set), "%Y-%m-%d")),
         delay = .2,
         gif_file = "full_ndvi.gif",
         width = 200 * 1.4,
         height = 250 * 1.4)




# saveRDS(full_set, "full_set.rds")
