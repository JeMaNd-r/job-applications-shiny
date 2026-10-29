library(shiny)
library(bslib)
library(bsicons)
library(ggplot2)
library(dplyr)

source("global.R")

# Load data (before app to increase performance)
df_all <- get_data()

# Define user interface
ui <- page_sidebar(
  
  # theme
  theme = bs_theme(
    version = 5,
    primary = "forestgreen",
    secondary = "#D98E32"
  ),
  
  tags$head(
    tags$style(HTML("
      .nav-pills .nav-link.active,
      .nav-pills .show > .nav-link {
        color: white !important;
        background-color: forestgreen !important;
      }
      
      /* Date labels in the slider handles */
      .irs--shiny .irs-from,
      .irs--shiny .irs-to,
      .irs--shiny .irs-single {
        color: white !important;
      }
    "))
  ),

  # Application title
  title = "Job applications 2026",
  window_title = "Job search progress",

  # Sidebar with a slider input for number of bins 
  sidebar = sidebar(
    tags$h5("Filter"),
    sliderInput(
      "date_range", 
      label = "Date range",
      min = as.Date("2000-01-01"),
      max = as.Date("2030-12-31"),
      value = c(as.Date("2000-01-01"), as.Date("2030-12-31"))
    ),
    radioButtons(
      "submission_status",
      label = "Submission status",
      choices = c("All", "Sent", "In Preparation", "Stopped", "Rejected"),
      selected = "All"
    ),
    hr(),
    tags$h5("Data source"),
    textOutput("data_source"),
  ),
  
  navset_card_pill(
    nav_panel(
      "Overview",
      value_box(
        title = "Total number of applications",
        value = shiny::textOutput("count_total"),
        showcase = bsicons::bs_icon("card-text"),
        theme = "bg-success"
      ),
      layout_column_wrap(
        width = "250px",
        value_box(
          title = "Number of sent applications",
          value = shiny::textOutput("count_sent"),
          showcase = bsicons::bs_icon("envelope-arrow-up"),
          theme = "text-success"
        ),
        value_box(
          title = "Number of application processes stopped",
          value = shiny::textOutput("count_stopped"),
          showcase = bsicons::bs_icon("envelope-slash-fill"),
          theme = "text-success"
        ),
        value_box(
          title = "Number of application processes terminated",
          value = shiny::textOutput("count_terminated"),
          showcase = bsicons::bs_icon("envelope-dash-fill"),
          theme = "text-success"
        ),
        value_box(
          title = "Number of applications not yet started",
          value = shiny::textOutput("count_not_started"),
          showcase = bsicons::bs_icon("envelope-open"),
          theme = "text-success"
        )
      )
    ),
    nav_panel(
      "Applications over time",
      plotOutput("appl_over_time")
    ),
    nav_panel(
      "Underlying data",
      tableOutput("data")
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  
  # get names of date columns
  date_columns <- names(df_all)[
    vapply(df_all, inherits, logical(1), what = "Date")
  ]
  
  # get min and max for dates
  date_range <- reactive( as.Date(range(unlist(df_all[, date_columns]), na.rm = TRUE)) )

  observe({
    req(date_range())
    
    updateSliderInput(
      session,
      "date_range",
      min = date_range()[1],
      max = date_range()[2],
      value = date_range()
    )
  })
  
  # Sub-setting data based on selected filters
  df <- reactive({
    req(input$date_range, input$submission_status)
    
    df_subset <- df_all |>
      dplyr::filter(
        dplyr::if_any(
          dplyr::all_of(date_columns),
          ~ !is.na(.x) & 
            .x >= input$date_range[1] & 
            .x <= input$date_range[2]
        )
      )
      
    switch(
      input$submission_status,
      "All" = df_subset,
      "Sent" = df_subset |>
        dplyr::filter(!is.na(Einreichung)),
      "In Preparation" = df_subset |>
        dplyr::filter(Status %in% c("Prio - tbc", "Nicht gestartet")),
      "Stopped" = df_subset |>
        dplyr::filter(Status %in% c("Beendet", "Abgebrochen")),
      "Rejected" = df_subset |>
        dplyr::filter(Status == "Absage"),
      df_subset
    )
  })
  
  ## Count number of positions ####
  counts <- reactive({
    list(
      "total" = count_total(df()$`Stelle/ Position`),
      
      "stopped" = count_total(
        df() |>
          dplyr::filter(Status == "Abgebrochen") |>
          dplyr::pull(`Stelle/ Position`)
      ),
      
      "sent" = count_total(
        df() |>
          dplyr::filter(Status %in% c("Gesendet", "Einladung", "Absage")) |>
          dplyr::pull(`Stelle/ Position`)
      ),
      
      "terminated" = count_total(
        df() |>
          dplyr::filter(Status %in% c("Beendet", "Abgebrochen", "Absage")) |>
          dplyr::pull(`Stelle/ Position`)
      ),
      
      "not_started" = count_total(
        df() |>
          dplyr::filter(Status %in% c("Nicht gestartet", "Prio - tbc")) |>
          dplyr::pull(`Stelle/ Position`)
      )
    )
  })
  
  count_names <- c(
    "total",
    "stopped",
    "sent",
    "terminated",
    "not_started"
  )
  
  lapply(count_names, function(name) {
    local({
      n <- name
      output[[paste0("count_", n)]] <- renderText({
        counts()[[n]]
      })
    })
  })
  
  ## Applications over time ####
  output$appl_over_time <- renderPlot({
    appl_deadline_over_time <- count_cummulative(df() |> dplyr::select(`Stelle/ Position`, Deadline), "Deadline")

    if(input$submission_status == "In Preparation"){
      appl_over_time <- appl_deadline_over_time
      
      ggplot(data = appl_over_time)+
        geom_line(aes(x = Deadline, y = count, color = "Deadline")) + geom_point(aes(x = Deadline, y = count)) +
        theme_bw()
      
    } else {
      appl_contact_over_time <- count_cummulative(df() |> dplyr::select(`Stelle/ Position`, `Letzter Kontakt`), "Letzter Kontakt")
      appl_sent_over_time <- count_cummulative(df() |> dplyr::select(`Stelle/ Position`, Einreichung), "Einreichung")
      
      appl_over_time <- 
        full_join(appl_sent_over_time, appl_deadline_over_time) |>
        full_join(appl_contact_over_time)
      
      ggplot(data = appl_over_time)+
        geom_line(aes(x = Einreichung, y = count, color = "Einreichung")) + geom_point(aes(x = Einreichung, y = count)) +
        geom_line(aes(x = Deadline, y = count, color = "Deadline")) + geom_point(aes(x = Deadline, y = count)) +
        geom_line(aes(x = `Letzter Kontakt`, y = count, color = "Letzter Kontakt")) + geom_point(aes(x = `Letzter Kontakt`, y = count)) +
        theme_bw()
    }
  })
  
  ## Data table
  output$data <- renderTable({
    df() |>
      mutate(across(date_columns, as.character))
  })
  
  ## Data source
  output$data_source <- renderText({
    if(own_data_file != ""){
      paste0("Own data file: ", own_data_file)
    } else {
      if(has_access_permission) {
        paste0("Downloaded data file: Applications_", Sys.Date(), ".csv")
      } else {
        "Test dataset: test_data.csv"
      }
    }
  })
}

# run app
shiny::shinyApp(ui = ui, server = server)
