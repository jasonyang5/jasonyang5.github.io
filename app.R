#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

# TODO:
# finish regression tables part for log gdp / log gdp per capita

library(shiny)
library(tidyverse)

pwt = read_csv("pwt901.csv")

choices_ui = c("GDP",
               "GDP Per Capita",
               "Labor Share of Production",
               "Employment",
               "Capital Stock",
               "Savings Rate",
               "Solow Residuals")
choices_var = c("rgdpna",
                "gdpcapita",
                "labsh",
                "emp",
                "ck",
                "csh_i",
                "rtfpna")
log_vars = c("GDP", "GDP Per Capita", "Employment", "Capital Stock")

ui <- fluidPage(
  # Application title
  titlePanel("PWT 90 Data"),
  
  sidebarLayout(
    sidebarPanel(
      # Choose Which Country
      selectizeInput(inputId = "countries",
                     label = strong("Countries"),
                     choices = unique(pwt$country),
                     multiple = TRUE
      ),
      # Choose Which Data
      radioButtons(inputId = "feature",
                   label = strong("Data to Display"),
                   choices = choices_ui),
      # Choose the Years
      sliderInput(inputId = "years",
                  label = strong("Years"),
                  min = 1950, max = 2014,
                  value = c(1950,2014)),
      # Choose to plot Log Scale
      conditionalPanel(
        condition = "['GDP', 'GDP Per Capita', 'Employment', 'Capital Stock'].indexOf(input.feature) >= 0",
        checkboxInput(inputId = "log_scale",
                      label = "Plot Log Scale?")),
      # Button for Pick Random Countries
      actionButton(inputId = "random_countries",
                   label = strong("5 Random Countries!"))
    ),
    # checkbox for log scale if it makes sense to log scale the variable
    
    mainPanel(
      plotOutput("pwtplot"),
      textOutput("units"),
      textOutput("interp")
    )
  )

)

server <- function(input, output, session) {
  # Mapping From Features to Variable
  feat_var_map = data_frame(feat = choices_ui,
                            var = choices_var)
 
  # pick random countries if button clicked
  observeEvent(input$random_countries,{
    # pick the countries- one per development bucket
    countries = group_by(pwt, dev_bucket) %>%
      sample_n(1) %>%
      ungroup() %>%
      select(country)
    # update the selectize object
    updateSelectizeInput(session,
                         inputId = "countries",
                         selected = countries[[1]],
                         choices = unique(pwt$country),
                         server = TRUE)
  })
  
  # reset log scale to no when feature changes
  observeEvent(input$feature,{
    updateCheckboxInput(session, 
                        inputId = "log_scale",
                        value = FALSE)
  })
  
  # get the variable names from the selected words 
  yvarname = reactive({
    req(input$feature)
    var = filter(feat_var_map, feat == input$feature)[[2]]
    
    # if we choose to log scale, return log of the variable
    if (input$log_scale == TRUE)
      return(paste0("log(", var, ")"))
    else # otherwise, return the bare variable
      return(var)
  })
   
  # Subset PWT Data by Country and Year 
  selected_data = reactive({
    req(input$years)
    req(input$countries)
    filter(pwt, 
           country %in% input$countries,
           year %in% input$years[1]:input$years[2])
  })
  
  gdps = c("GDP", "GDP Per Capita")
  
  # render the plot
  output$pwtplot = renderPlot({
    # initial plot adds the theme, labels, and loads the data
    initial_plot = ggplot(selected_data(), aes_string(x = "year", y = yvarname())) +
      theme_bw() +
      labs(title = paste(input$feature, "Over Time for Selected Countries"),
           x = "Year",
           y = input$feature,
           col = "Country")
    
    # if it's a log variable, include a regression line
    if ((input$feature %in% log_vars) && (input$log_scale == TRUE))
    {
      output_plot = initial_plot +
        geom_point(aes(col = country)) +
        geom_smooth(method = "lm", se = FALSE, aes(col = country))
      return(output_plot)
    }
    # otherwise, just report the points
    else # solow residuals, or employment trend
    {
      output_plot = initial_plot +
        geom_point(aes(col = country))
      return(output_plot)
    }
  })
 
  # Explanation of Units 
  output$units = renderText({
    req(input$countries)
    if (input$feature %in% gdps)
      return("GDP measured in Million USD (2011)")
    else if (input$feature == "Labor Share of Production")
      return("Labor Shares measured in percent production owned by labor")
    else if (input$feature == "Savings Rate")
      return("Savings Rate measured in percent of GDP saved for next year (not consumed)")
    else if (input$feature == "Capital Stock")
      return("Capital Stock measured in Million USD (2011)")
    else if (input$feature == "Solow Residuals")
      return("Solow Residuals measured in percentage deviation from Solow Model prediction")
    else # employment
      return("Employment measured in millions of people employed")
  })
  
  # Render the appropriate interpretation
  output$interp = renderText({
    req(input$countries)
    
    # if on log scale, explain that log scale slope gives percent change
    if (input$log_scale == TRUE)
      return(paste0("Taking Log(", input$feature, ") allows us to interpret the slope of the line as percentage growth per year."))
   
    # explain solow residuals 
    if (input$feature == "Solow Residuals")
      return("Higher Solow Residual means higher productivity. Since GDP growth comes outside of labor and capital growth, the labor and capital must be more efficient.")
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

