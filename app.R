library(shiny)

# ----------------------------------------------------------------------
# 1. User Interface (UI)
# ----------------------------------------------------------------------
ui <- fluidPage(
  
  # Application Title
  titlePanel("🧠 Connectome Consistency Thresholding Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      h4("Algorithm Parameters"),
      hr(),
      
      # 1. Consistency threshold slider
      sliderInput("threshold", 
                  "Consistency Threshold:", 
                  min = 0.0, max = 0.9, value = 0.3, step = 0.05),
      
      # 2. Number of brain regions selector
      selectInput("n_nodes", 
                  "Brain Regions (Nodes):", 
                  choices = c("20 Regions" = 20, "50 Regions" = 50), 
                  selected = 20),
      
      # 3. Heatmap color palette selector
      selectInput("heatmap_color", 
                  "Heatmap Palette:",
                  choices = c("Terrain" = "terrain", 
                              "Heat Colors" = "heat", 
                              "Gray Scale" = "gray"))
    ),
    
    mainPanel(
      tabsetPanel(
        type = "tabs",
        
        # Tab 1: Visualization Plots & Metric Summary
        tabPanel("Visualization", 
                 fluidRow(
                   column(6, 
                          h4("Thresholded Connectome Matrix"),
                          plotOutput("matrixPlot", height = "350px")
                   ),
                   column(6, 
                          h4("Edge Weight vs. Distance"),
                          plotOutput("distancePlot", height = "350px")
                   )
                 ),
                 hr(),
                 h4("Thresholding Summary"),
                 verbatimTextOutput("networkSummary")
        ),
        
        # Tab 2: Pruned Edge Data Preview
        tabPanel("Edge Data Table", 
                 h4("Pruned Network Edges Preview"),
                 tableOutput("edgeTable")
        )
      )
    )
  )
)

# ----------------------------------------------------------------------
# 2. Server Logic
# ----------------------------------------------------------------------
server <- function(input, output) {
  
  # A. Generate simulated network data (reactive object)
  rawNetworkData <- reactive({
    n <- as.numeric(input$n_nodes)
    set.seed(42) # Fixed seed for reproducibility
    
    # Create pairwise node combinations
    edges <- expand.grid(Node1 = 1:n, Node2 = 1:n)
    edges <- edges[edges$Node1 < edges$Node2, ] # Keep upper triangle
    
    # Simulate inter-regional fiber distance (10mm to 100mm)
    edges$Distance <- round(runif(nrow(edges), 10, 100), 1)
    
    # Simulate connection weight (decays exponentially with distance)
    edges$Weight <- exp(-0.03 * edges$Distance) * runif(nrow(edges), 0.5, 1.5)
    
    # Simulate consistency score (Roberts et al. 2017 principle)
    edges$Consistency <- pmin(1, pmax(0, edges$Weight * (edges$Distance / 30) + runif(nrow(edges), -0.2, 0.2)))
    edges$Consistency <- round(edges$Consistency, 2)
    
    return(edges)
  })
  
  # B. Filter network based on the consistency threshold
  filteredData <- reactive({
    df <- rawNetworkData()
    df[df$Consistency >= input$threshold, ]
  })
  
  # --------------------------------------------------------------------
  # 3. Outputs
  # --------------------------------------------------------------------
  
  # 1) Connectome Adjacency Heatmap
  output$matrixPlot <- renderPlot({
    n <- as.numeric(input$n_nodes)
    edges <- filteredData()
    
    mat <- matrix(0, nrow = n, ncol = n)
    for (i in 1:nrow(edges)) {
      mat[edges$Node1[i], edges$Node2[i]] <- edges$Weight[i]
      mat[edges$Node2[i], edges$Node1[i]] <- edges$Weight[i]
    }
    
    colors <- switch(input$heatmap_color,
                     "terrain" = terrain.colors(12),
                     "heat"    = heat.colors(12),
                     "gray"    = gray.colors(12, start = 0.9, end = 0.1))
    
    image(1:n, 1:n, mat, col = colors,
          xlab = "Brain Region ID", ylab = "Brain Region ID",
          main = paste0("Edges Retained (Threshold >= ", input$threshold, ")"))
  })
  
  # 2) Connection Weight vs. Fiber Distance Scatter Plot
  output$distancePlot <- renderPlot({
    all_edges <- rawNetworkData()
    retained_edges <- filteredData()
    
    plot(all_edges$Distance, all_edges$Weight, 
         col = "lightgray", pch = 16, cex = 0.8,
         xlab = "Fiber Distance (mm)", ylab = "Connection Weight",
         main = "Pruning Effect on Long-Range Connections")
    
    points(retained_edges$Distance, retained_edges$Weight, 
           col = "red", pch = 16, cex = 1.0)
    
    legend("topright", legend = c("Pruned Edge", "Retained Edge"),
           col = c("lightgray", "red"), pch = 16)
  })
  
  # 3) Metric Summary Text
  output$networkSummary <- renderPrint({
    all_count <- nrow(rawNetworkData())
    retained_count <- nrow(filteredData())
    retention_rate <- round((retained_count / all_count) * 100, 2)
    
    cat("=== Connectome Pruning Metrics ===\n")
    cat("Total Possible Edges  :", all_count, "\n")
    cat("Retained Edges        :", retained_count, "\n")
    cat("Network Retention Rate:", retention_rate, "%\n")
    cat("Network Sparsity      :", round(100 - retention_rate, 2), "%\n")
  })
  
  # 4) Table preview of retained edges
  output$edgeTable <- renderTable({
    head(filteredData(), 12)
  })
}

# ----------------------------------------------------------------------
# Run Application
# ----------------------------------------------------------------------
shinyApp(ui = ui, server = server)