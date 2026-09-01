library(shiny)

sidebarUI <- function(id) {
  ns <- NS(id)
  tagList(
    tags$head(
      tags$style(HTML("
        /* Hide native fileInput text box */
        .input-group .form-control { display: none !important; }
        .input-group-btn { width: 100% !important; }
        
        /* Flatten upload buttons */
        .btn-file {
          width: 100% !important;
          background-color: #f3f3f3 !important;
          border: 1px solid #ccc !important;
          color: #222 !important;
          font-size: 12px !important;
          border-radius: 4px !important;
          padding: 4px 8px !important;
          font-weight: 400 !important;
        }
        .btn-file:hover { background-color: #e5e5e5 !important; }
        
        /* Dashed button */
        .btn-dashed {
          width: 100% !important;
          background-color: transparent !important;
          border: 1.5px dashed #444 !important;
          color: #222 !important;
          font-size: 12px !important;
          font-weight: 500 !important;
          padding: 4px !important;
          border-radius: 4px !important;
        }
        
        /* Action button */
        .btn-run {
          width: 100% !important;
          background-color: #eeeeee !important;
          border: none !important;
          color: #111 !important;
          font-size: 13px !important;
          padding: 6px !important;
          border-radius: 2px !important;
          margin-top: 4px !important;
        }

        /* Compact Layout Fixes */
        .section-title { font-size: 11px; font-weight: 600; color: #222; text-transform: uppercase; margin: 6px 0 2px 0; }
        .field-label { font-size: 12px; color: #333; margin-bottom: 2px; }
        .form-group { margin-bottom: 4px !important; }
        .form-control-text {
          width: 100%; border: 1px solid #aaa; border-radius: 3px; padding: 2px 6px; font-size: 12px; height: 26px;
        }
        
        /* FIX SLIDER OVERLAP ISSUE */
        .irs-grid { display: none !important; } /* Hide clutter grid tick text */
        .irs--shiny .irs-bar { background: #007bff !important; border: none !important; }
        .irs--shiny .irs-line { height: 6px !important; }
        .irs--shiny .irs-single { background-color: #007bff !important; font-size: 10px !important; top: -6px !important; }
        .irs--shiny .irs-handle { border: 1px solid #007bff !important; width: 14px !important; height: 14px !important; top: 18px !important; }
      "))
    ),
    
    # Section 1: CONNECTOME DATA
    div(class = "section-title", "1. CONNECTOME DATA"),
    div(class = "field-label", "Metric 1 name"),
    tags$input(id = ns("metric_name"), type = "text", class = "form-control-text", value = "FA"),
    div(style = "height: 4px;"),
    fileInput(ns("upload_matrix"), label = NULL, buttonLabel = "Upload matrix (.csv/.mat)"),
    actionButton(ns("add_metric"), "+ Add another metric", class = "btn-dashed"),
    div(style = "height: 4px;"),
    div(class = "field-label", "Atlas / node labels"),
    fileInput(ns("upload_atlas"), label = NULL, buttonLabel = "Upload atlas (.xml)"),
    
    # Section 2: THRESHOLD
    div(class = "section-title", "2. THRESHOLD"),
    div(class = "field-label", "Method"),
    selectInput(ns("method"), label = NULL, choices = c("Consistency-based", "Density-based"), width = "100%"),
    sliderInput(ns("threshold_val"), label = NULL, min = 0, max = 100, value = 60, post = "%", ticks = FALSE, width = "100%"),
    div(class = "field-label", "P-value matrix (optional)"),
    fileInput(ns("upload_pvals"), label = NULL, buttonLabel = "Upload from NBS/MRtrix"),
    
    # Section 3: STATISTICS
    div(class = "section-title", "3. STATISTICS"),
    div(class = "field-label", "Design matrix"),
    fileInput(ns("upload_design"), label = NULL, buttonLabel = "Upload design matrix"),
    p("One row per participant, matched to connectome order", style = "font-size: 10px; color: #666; margin: 2px 0 4px 0;"),
    actionButton(ns("run_analysis"), "Run analysis", class = "btn-run")
  )
}

sidebarServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    reactive({
      list(
        threshold = input$threshold_val,
        method = input$method
      )
    })
  })
}