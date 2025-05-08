# I'm a horrible bitch and I did not write this script, I simply stole it from chat

# app.R

library(tidyverse)
library(shiny)
library(terra)
library(leaflet)

full_set <- 
  readRDS("full_set.rds") 

full_set <- 
  full_set %>%
  subset(time(full_set) >= as.Date("2024-02-17"))
# 
# small_set <- aggregate(full_set, fact = 10)
# 
# saveRDS(small_set, "full_set_small.rds")


# Define color palette for NDVI


ndvi_pal <- colorNumeric(
  palette = colorRampPalette(c("red", "orange", "yellow", "green"))(200),
  domain = c(-1, 1),
  na.color = "transparent"
)

ui <- fluidPage(
  titlePanel("NDVI Time Series Viewer"),
  sidebarLayout(
    sidebarPanel(
      uiOutput("date_ui")  # <- render slider later
    ),
    mainPanel(
      leafletOutput("map", height = 600)
    )
  )
)

server <- function(input, output, session) {
  
  # Reactive value to store the raster stack
  rv <- reactiveValues(full_set = NULL)
  
  # Load the raster lazily (first time)
  observe({
    if (is.null(rv$full_set)) {
      message("Loading full_set...")
      rv$full_set <- full_set
    }
    
    # Dynamically render the slider once full_set is loaded
    output$date_ui <- renderUI({
      sliderInput("date", "Select Date:",
                  min = min(time(rv$full_set)),
                  max = max(time(rv$full_set)),
                  value = min(time(rv$full_set)),
                  timeFormat = "%Y-%m-%d",
                  animate = animationOptions(interval = 300, loop = TRUE),
                  step = 1)
    })
    
    # Initialize map once
    output$map <- renderLeaflet({
      leaflet() %>%
        addTiles(group = "Base") %>%
        setView(lng = -109.949, lat = 47.057, zoom = 12)
    })
  })
  
  # Watch for date changes after raster is loaded
  observe({
    req(input$date)
    req(rv$full_set)
    
    index <- which(time(rv$full_set) == as.Date(input$date))
    if (length(index) == 0) return()
    
    r <- rv$full_set[[index]]
    
    leafletProxy("map") %>%
      removeImage("ndvi_layer") %>%
      addRasterImage(r, layerId = "ndvi_layer", colors = ndvi_pal, opacity = 0.9, project = TRUE) %>%
      clearControls() %>%
      addLegend(pal = ndvi_pal, values = c(-1, 1),
                title = "NDVI", position = "bottomright")
  })
}

shinyApp(ui, server)
