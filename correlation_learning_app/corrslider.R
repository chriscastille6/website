library(shiny)
library(ggplot2)
library(plotly)

ui <- fluidPage(
  titlePanel("Smooth Correlation Visualization"),
  
  sidebarLayout(
    sidebarPanel(
      width = 4,
      
      h3("Correlation Control"),
      sliderInput("correlation",
                  "Correlation (r):",
                  min = -1,
                  max = 1,
                  value = 0,
                  step = 0.01),
      
      br(),
      
      numericInput("sample_size",
                   "Sample Size:",
                   value = 100,
                   min = 20,
                   max = 500,
                   step = 10),
      
      br(),
      
      checkboxInput("show_trendline", "Show Trendline", value = TRUE),
      
      br(),
      
      div(style = "margin-top: 20px;",
          h4("Current Correlation:"),
          textOutput("corr_display")
      )
    ),
    
    mainPanel(
      width = 8,
      
      plotlyOutput("scatter_plot", height = "500px"),
      
      br(),
      
      div(style = "text-align: center; color: #666;",
          p("Move the slider to see smooth transitions in the correlation pattern")
      )
    )
  )
)

server <- function(input, output, session) {
  
  # Generate stable base data
  base_data <- reactive({
    set.seed(123)  # Fixed seed for reproducible transitions
    n <- input$sample_size
    
    # Generate base variables
    x_base <- rnorm(n, 0, 1)
    y_base <- rnorm(n, 0, 1)
    
    list(x_base = x_base, y_base = y_base, n = n)
  })
  
  # Transform data based on correlation
  plot_data <- reactive({
    req(input$correlation)
    
    data <- base_data()
    r <- input$correlation
    
    # Transform y based on correlation while keeping x stable
    y_transformed <- r * data$x_base + sqrt(1 - r^2) * data$y_base
    
    data.frame(
      x = data$x_base,
      y = y_transformed,
      id = 1:data$n
    )
  })
  
  # Create the scatter plot with smooth transitions
  output$scatter_plot <- renderPlotly({
    data <- plot_data()
    
    # Create scatter plot
    p <- plot_ly(
      data = data,
      x = ~x,
      y = ~y,
      type = 'scatter',
      mode = 'markers',
      marker = list(
        size = 8,
        color = 'steelblue',
        opacity = 0.7,
        line = list(width = 0)
      ),
      text = paste("X:", round(data$x, 2), "<br>Y:", round(data$y, 2)),
      hoverinfo = 'text',
      key = data$id,  # Essential for smooth transitions
      source = "scatter"
    ) %>%
      layout(
        title = list(
          text = paste0("Correlation: r = ", round(input$correlation, 3)),
          font = list(size = 16)
        ),
        xaxis = list(
          title = "X Variable",
          range = c(-3, 3),
          zeroline = TRUE,
          zerolinecolor = '#969696',
          zerolinewidth = 2
        ),
        yaxis = list(
          title = "Y Variable",
          range = c(-3, 3),
          zeroline = TRUE,
          zerolinecolor = '#969696',
          zerolinewidth = 2
        ),
        showlegend = FALSE,
        margin = list(t = 80, b = 80, l = 80, r = 80),
        # Smooth transition settings
        transition = list(
          duration = 800,
          easing = 'cubic-in-out'
        )
      ) %>%
      config(displayModeBar = FALSE)
    
    # Add trendline if requested
    if (input$show_trendline) {
      # Calculate trendline
      x_range <- seq(-3, 3, length.out = 100)
      y_trend <- input$correlation * x_range
      
      p <- p %>% add_trace(
        x = x_range,
        y = y_trend,
        type = 'scatter',
        mode = 'lines',
        line = list(
          color = 'red',
          width = 3,
          dash = 'solid'
        ),
        name = 'Trendline',
        showlegend = FALSE,
        hoverinfo = 'skip'
      )
    }
    
    return(p)
  })
  
  # Display current correlation
  output$corr_display <- renderText({
    paste("r =", round(input$correlation, 3))
  })
}

shinyApp(ui = ui, server = server) 