
# Load necessary libraries
library(shiny)
library(Giotto)

# Define the UI for the Shiny app
ui <- fluidPage(
  titlePanel("Interactive Filtering and Visualization of Giotto Object"),
  
  sidebarLayout(
    sidebarPanel(
      # Sliders to adjust filtering parameters
      sliderInput("expression_threshold", "Expression Threshold", 
                  min = 1, max = 5, value = 2, step = 0.25),
      
      sliderInput("feat_det_in_min_cells", "Features Detected in Min Cells", 
                  min = 1, max = 500, value = 45, step = 1),
      
      sliderInput("min_det_feats_per_cell", "Min Detected Features per Cell", 
                  min = 50, max = 1000, value = 500, step = 10),
      
      # Button to save the filtered object and plot
      textInput("save_name", "Save filtered object as:", value = "SpatPlot2_QC_afterfiltering"),
      actionButton("save_filtered", "Create Filtered Object and Save Plot"),
      
      # Button to close the Shiny app
      actionButton("close_app", "Close Shiny App")
    ),
    
    mainPanel(
      # Display the filtered plot in a larger plot area
      plotOutput("qcPlot", height = "700px", width = "700px"),
      verbatimTextOutput("objectSummary")
    )
  )
)

# Define the server logic for the Shiny app
server <- function(input, output, session) {
  # Reactive expression to filter the Giotto object based on the slider inputs
  filteredGiotto <- reactive({
    filterGiotto(
      gobject = SpatialTrans_DMSO_ONTtrans,
      expression_threshold = input$expression_threshold,
      feat_det_in_min_cells = input$feat_det_in_min_cells,
      min_det_feats_per_cell = input$min_det_feats_per_cell,
      expression_values = "raw",
      verbose = TRUE
    )
  })
  
  # Normalize the Giotto object and add statistics
  filteredGiottoNorm <- reactive({
    gobject <- filteredGiotto()
    gobject <- normalizeGiotto(gobject, scalefactor = 6000, verbose = TRUE)
    addStatistics(gobject, expression_values = "raw")
  })
  
  # Render the QC plot without saving (just for visualization)
  output$qcPlot <- renderPlot({
    gobject <- filteredGiottoNorm()
    
    SpatPlot2_QC_afterfiltering <- spatPlot2D(
      gobject = gobject,
      cell_color = "total_expr",            # Color based on total expression per spot
      point_size = 4,
      show_image = TRUE,                    # Show the underlying image
      point_alpha = 0.7,
      color_as_factor = FALSE,              # Use continuous color scale (not a factor)
      cell_color_gradient = c("#ebe2e2", "darkred"),  # Define a continuous gradient from light red to dark red
      save_plot = FALSE  # Do not save the plot during Shiny interactions
    )
    
    print(SpatPlot2_QC_afterfiltering)
  })
  
  # Render the object summary
  output$objectSummary <- renderPrint({
    gobject <- filteredGiottoNorm()
    summary(gobject)
  })
  
  # Save the filtered object and plot when the button is clicked
  observeEvent(input$save_filtered, {
    # Save the filtered object with the same name `SpatialTrans_DMSO_ONTtrans`
    SpatialTrans_DMSO_ONTtrans <<- filteredGiottoNorm()
    
    # Save the plot with the specified name
    SpatPlot2_QC_nr_feats <- spatPlot2D(
      gobject = SpatialTrans_DMSO_ONTtrans,
      cell_color = "total_expr",
      point_size = 4,
      show_image = TRUE,
      point_alpha = 0.7,
      color_as_factor = FALSE,
      cell_color_gradient = c("#ebe2e2", "darkred"),  # Continuous gradient from light red to dark red
      save_plot = TRUE,  # Save the plot only when clicked
      save_param = base_save_parameters,
      default_save_name = input$save_name  # Use the input save name
    )
    
    showModal(modalDialog(
      title = "Save Complete",
      paste("Filtered Giotto object and plot saved as", input$save_name)
    ))
  })
  
  # Close the Shiny app when the "Close Shiny App" button is clicked
  observeEvent(input$close_app, {
    stopApp()  # Gracefully stop the Shiny app
  })
}

# Run the Shiny app
shinyApp(ui, server)