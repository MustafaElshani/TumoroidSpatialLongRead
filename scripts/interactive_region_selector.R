# Interactive Region Selector for Spatial Transcriptomics
# This Shiny app allows interactive selection of regions from spatial plots
# Usage: source("./scripts/interactive_region_selector.R")
# Requires: SpatialTrans_DMSO_ONTgene object to be loaded in the environment

library(shiny)
library(ggplot2)
library(cowplot)
library(plotly)
library(Giotto)

# Define the shiny app
shinyApp(
  ui = fluidPage(
    titlePanel("Interactive Region Selector for Spatial Transcriptomics"),
    
    sidebarLayout(
      sidebarPanel(
        textInput("region_name", "Region Name", "Tumouroid_1"),
        actionButton("generate_plot", "Generate Plot"),
        actionButton("save_and_close", "Save and Close App"),
        verbatimTextOutput("selected_coords")
      ),
      
      mainPanel(
        plotlyOutput("interactive_plot", height = "600px"),
        plotOutput("final_plot", height = "600px")
      )
    )
  ),
  
  server = function(input, output, session) {
    # Reactive values to store the coordinates and the plot
    plot_data <- reactiveValues(
      x_min = NULL,
      x_max = NULL,
      y_min = NULL,
      y_max = NULL,
      plot = NULL
    )
    
    # Generate the initial plot
    output$interactive_plot <- renderPlotly({
      base_plot <- spatPlot2D(
        gobject = SpatialTrans_DMSO_ONTgene,
        cell_color = "leiden_clus",
        point_size = 2,
        point_alpha = 0.7,
        show_image = TRUE,
        save_plot = FALSE,
        return_plot = TRUE
      )+ ggplot2::xlim(0, 37690) +  ggplot2::ylim(-37955, 0)
      
      ggplotly(base_plot) %>%
        layout(dragmode = "select")  # Enable rectangular selection
    })
    
    # Observe plotly selection
    observeEvent(event_data("plotly_selected"), {
      selection <- event_data("plotly_selected")
      if (!is.null(selection)) {
        plot_data$x_min <- min(selection$x)
        plot_data$x_max <- max(selection$x)
        plot_data$y_min <- min(selection$y)
        plot_data$y_max <- max(selection$y)
        
        # Display selected coordinates
        output$selected_coords <- renderPrint({
          list(
            x_min = plot_data$x_min,
            x_max = plot_data$x_max,
            y_min = plot_data$y_min,
            y_max = plot_data$y_max
          )
        })
      }
    })
    
    # Generate the final plot based on the selected region
    observeEvent(input$generate_plot, {
      req(plot_data$x_min, plot_data$x_max, plot_data$y_min, plot_data$y_max)
      
      # Define scale bar length
      scale_bar_length_microns <- 50
      microns_per_pixel <- 1  # Set your microns per pixel value here
      scale_bar_length_pixels <- scale_bar_length_microns / microns_per_pixel
      
      # Calculate scale bar position dynamically
      x_right <- plot_data$x_max - scale_bar_length_pixels - 20
      y_bottom <- plot_data$y_min + 80
      
      # Generate plot
      plot_data$plot <- spatInSituPlotPoints(
        SpatialTrans_DMSO_ONTgene,
        background_color = "white",
        polygon_fill = "leiden_clus",
        polygon_fill_as_factor = TRUE,
        show_image = TRUE,
        save_plot = FALSE,
        xlim = c(plot_data$x_min, plot_data$x_max),
        ylim = c(plot_data$y_min, plot_data$y_max)
      ) +
        ggplot2::theme(
          axis.line = ggplot2::element_line(color = "black"),
          axis.title.x = ggplot2::element_text(size = 12),
          axis.title.y = ggplot2::element_text(size = 12),
          legend.title = ggplot2::element_text(size = 10),
          legend.text = ggplot2::element_text(size = 8)
        ) +
        ggplot2::labs(
          x = "x coordinates",
          y = "y coordinates",
          fill = "Leiden Clusters"
        ) +
        ggplot2::annotate(
          "segment",
          x = x_right,
          xend = x_right + scale_bar_length_pixels,
          y = y_bottom + 40,
          yend = y_bottom + 40,
          color = "black",
          linewidth = 1.5,
          lineend = "round"
        ) +
        ggplot2::annotate(
          "text",
          x = x_right + scale_bar_length_pixels / 2,
          y = y_bottom - 20,
          label = paste0(scale_bar_length_microns, " µm"),
          color = "black",
          size = 4,
          hjust = 0.5
        )
      
      # Render final plot
      output$final_plot <- renderPlot({
        plot_data$plot
      })
    })
    
    # Save and close the app
    observeEvent(input$save_and_close, {
      req(plot_data$plot)
      
      # Define file paths
      results_folder <- "./results"
      if (!dir.exists(results_folder)) {
        dir.create(results_folder, recursive = TRUE)
      }
      png_path <- file.path(results_folder, paste0(input$region_name, ".png"))
      pdf_path <- file.path(results_folder, paste0(input$region_name, ".pdf"))
      
      # Save as PNG
      cowplot::save_plot(
        filename = png_path,
        plot = plot_data$plot,
        base_height = 10,
        base_width = 10,
        dpi = 600
      )
      
      # Save as PDF
      cowplot::save_plot(
        filename = pdf_path,
        plot = plot_data$plot,
        base_height = 10,
        base_width = 10,
        device = cairo_pdf
      )
      
      # Stop the app
      stopApp()
    })
  }
)
