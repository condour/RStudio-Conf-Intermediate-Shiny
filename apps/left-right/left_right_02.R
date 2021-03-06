library(shiny)

# Module 1: Dataset chooser ---------------------------------------------------

# Module 1 UI
dataset_chooser_UI <- function(id) {
  ns <- NS(id)

  tagList(
    selectInput(ns("dataset"), "Choose a dataset", c("pressure", "cars")),
    numericInput(ns("count"), "Number of records to return", 10)
  )
}

# Module 1 Server
dataset_chooser <- function(input, output, session) {
  dataset <- reactive({
    req(input$dataset)
    get(input$dataset, pos = "package:datasets")
  })
  
  return(list(
    dataset = dataset,
    count = reactive(input$count)
  ))
}

# Module 2: Dataset summarizer ------------------------------------------------

# Module 2 UI
dataset_summarizer_UI <- function(id) {
  ns <- NS(id)
  
  verbatimTextOutput(ns("summary"))
}

# Module 2 Server
dataset_summarizer <- function(input, output, session, dataset, count) {
  selected_data <- reactive({ head(dataset(), count()) })

  output$summary <- renderPrint({
    summary( selected_data() )
  })
  
  mean_x <- reactive({ mean(selected_data()[,1]) })
  mean_y <- reactive({ mean(selected_data()[,2]) })
  
  return(list(
    mean_x = mean_x,
    mean_y = mean_y
  ))
  
}

# Module 3: Dataset plotter ---------------------------------------------------

# Module 3 UI
dataset_plotter_UI <- function(id) {
  ns <- NS(id)
  
  plotOutput(ns("scatterplot"))
}

# Module 3 Server
dataset_plotter <- function(input, output, session, dataset, count, mean_x, mean_y) {
  output$scatterplot <- renderPlot({
    plot(head(dataset(), count()))
    points(x = mean_x(), y = mean_y(), pch = 19, col = "red")
  })
}

# App combining Module 1 and Module 2 -----------------------------------------

# App UI
ui <- fluidPage(
  fluidRow(
    column(6,
      dataset_chooser_UI("left_input"),
      dataset_summarizer_UI("left_output"),
      dataset_plotter_UI("left_plot")
    ),
    column(6,
      dataset_chooser_UI("right_input"),
      dataset_summarizer_UI("right_output"),
      dataset_plotter_UI("right_plot")
    )
  )
)

# App server
server <- function(input, output, session) {
  left_result <- callModule(dataset_chooser, "left_input")
  right_result <- callModule(dataset_chooser, "right_input")
  
  left_means <- callModule(dataset_summarizer, "left_output", dataset = left_result$dataset, count = left_result$count)
  right_means <- callModule(dataset_summarizer, "right_output", dataset = right_result$dataset, count = right_result$count)
  
  callModule(dataset_plotter, "left_plot", dataset = left_result$dataset, count = left_result$count, mean_x = left_means$mean_x, mean_y = left_means$mean_y)
  callModule(dataset_plotter, "right_plot", dataset = right_result$dataset, count = right_result$count, mean_x = right_means$mean_x, mean_y = right_means$mean_y)
}

shinyApp(ui, server)