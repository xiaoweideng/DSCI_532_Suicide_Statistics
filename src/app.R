# app.R
# Wilson Deng, Rayce Rossum
# Date: 2019. 01, 28
# An exploration of data from WHO and the UN on suicide statistics.
#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com/
#

library(tidyverse)
library(shiny)
library(shinyWidgets)
library(shinythemes)
# library(leaflet)
# library(leaflet.extras)
# library(jsonlite)
# library(ggmap)
library(gridExtra)
library(plotly)

# Define UI for application
ui <- fluidPage(
    theme = shinytheme("simplex"),
    # Application title
    titlePanel("World Suicide Statistics by Country"),
    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            uiOutput('location'),
            #uiOutput('suicide_total'),
            uiOutput('year'),
            #uiOutput('gdp'),
            #uiOutput('population'),
            uiOutput('age'),
            uiOutput("sex")
        ),


        # mainPanel contains two tabsets: country and world
        mainPanel(tabsetPanel(
            tabPanel("Country", column(
                6,
                h4(textOutput("title1")),
                plotlyOutput(
                    outputId = "plotgraph",
                    width = "800px",
                    height = "640px"
                )
            )),
            tabPanel("World", column(
                6,
                h4(textOutput("title2")),
                plotlyOutput(
                    outputId = "plotgraph_world",
                    width = "800px",
                    height = "640px"
                )
            ))#,

            #leafletOutput("suicideMap")

        ))
    )
)

# Define server logic
server <- function(input, output, session) {
    suicideData = read_csv("data/who_suicide_statistics.csv")
    gdpData <- read_csv("data/UN_Gdp_data.csv")

    tidy_data <- suicideData %>%
        group_by(country, year) %>%
        summarise(
            suicides_total = sum(suicides_no, na.rm = TRUE),
            pop = sum(population, na.rm = TRUE)
        ) %>%
        left_join(gdpData, by = c("country" = "Country or Area", "year" = "Year")) %>%
        select(-"Item")

    countries <- suicideData %>%
        distinct(country) %>%
        select(country)

    ageGroups <-
        c("5-14", "15-24", "25-34", "35-54", "55-74", "75+")

    colMax <- function(data)
        sapply(data, max, na.rm = TRUE)
    colMin <- function(data)
        sapply(data, min, na.rm = TRUE)

    # Data wrangling
    data_by_year <- reactive({
        suicideData %>%
            group_by(country, year) %>%
            summarise(
                suicides_total = sum(suicides_no, na.rm = TRUE),
                pop = sum(population, na.rm = TRUE)
            ) %>%
            left_join(gdpData,
                      by = c("country" = "Country or Area", "year" = "Year")) %>%
            filter(country == input$location,
                   year >= input$year[1],
                   year <= input$year[2])
    })

    data_by_sex <- reactive({
        char0 <- character(0)
        sexSelection = tolower(input$sex)

        if (sexSelection == "all" ||
            identical(char0, character(0))) {
            sexSelection <- c("male", "female")
        }
        
        suicideData %>%
            group_by(country, year, sex) %>%
            summarise(
                suicides_total = sum(suicides_no, na.rm = TRUE),
                pop = sum(population, na.rm = TRUE)
            ) %>%
            mutate(suicide_rate = suicides_total / pop) %>%
            left_join(gdpData,
                      by = c("country" = "Country or Area", "year" = "Year")) %>%
            filter(
                country == input$location,
                year >= input$year[1],
                year <= input$year[2],
                sex %in% sexSelection
            )
    })

    data_by_age <- reactive({
        suicideData %>%
            filter(country == input$location,
                   year >= input$year[1],
                   year <= input$year[2]) %>%
            group_by(country, age, sex) %>%
            summarise(
                suicides_total = sum(suicides_no, na.rm = TRUE),
                pop = sum(population, na.rm = TRUE)
            ) %>%
            mutate(suicide_rate = suicides_total / pop)
    })

    data_by_age_sex <- reactive({
        ageGroups <- c("5-14", "15-24", "25-34", "35-54", "55-74", "75+")
        ageSelection <- input$age
        ageRange <- which(ageGroups %in% ageSelection)

        for (i in ageRange[1]:ageRange[2]) {
            ageSelection[i] = paste(ageGroups[i], "years")
        }


        sexSelection = tolower(input$sex)
        if (input$sex == "All") {
            sexSelection <- c("male", "female")
        }

        suicideData %>%
            filter(
                country == input$location,
                year >= input$year[1],
                year <= input$year[2],
                sex %in% sexSelection,
                age %in% ageSelection
            ) %>%
            group_by(country, age, sex) %>%
            summarise(
                suicides_total = sum(suicides_no, na.rm = TRUE),
                pop = sum(population, na.rm = TRUE)
            ) %>%
            mutate(suicide_rate = suicides_total / pop)
    })

    world_by_country_year <- reactive({
        suicideData %>%
            group_by(country, year) %>%
            summarise(
                suicides_total = sum(suicides_no, na.rm = TRUE),
                pop = sum(population, na.rm = TRUE)
            ) %>%
            mutate(suicide_rate = suicides_total / pop) %>%
            left_join(gdpData,
                      by = c("country" = "Country or Area", "year" = "Year"))
    })

    world_by_year <- reactive({
        suicideData %>%
            group_by(year) %>%
            summarise(
                suicides_total = sum(suicides_no, na.rm = TRUE),
                pop = sum(population, na.rm = TRUE)
            ) %>%
            mutate(suicide_rate = suicides_total / pop) %>%
            filter(year >= input$year[1],
                   year <= input$year[2])
    })

    world_by_sex_year <- reactive({
        sexSelection = tolower(input$sex)
        if (input$sex == "All") {
            sexSelection <- c("male", "female")
        }

        suicideData %>%
            group_by(year, sex) %>%
            summarise(
                suicides_total = sum(suicides_no, na.rm = TRUE),
                pop = sum(population, na.rm = TRUE)
            ) %>%
            mutate(suicide_rate = suicides_total / pop) %>%
            filter(year >= input$year[1],
                   year <= input$year[2],
                   sex %in% sexSelection)
    })

    world_by_sex_year_age <- reactive({
        ageGroups <- c("5-14", "15-24", "25-34", "35-54", "55-74", "75+")
        ageSelection <- input$age
        ageRange <- which(ageGroups %in% ageSelection)

        for (i in ageRange[1]:ageRange[2]) {
            ageSelection[i] = paste(ageGroups[i], "years")
        }

        sexSelection = tolower(input$sex)
        if (input$sex == "All") {
            sexSelection <- c("male", "female")
        }


        suicideData %>%
            group_by(year, sex, age) %>%
            summarise(
                suicides_total = sum(suicides_no, na.rm = TRUE),
                pop = sum(population, na.rm = TRUE)
            ) %>%
            mutate(suicide_rate = suicides_total / pop) %>%
            filter(
                year >= input$year[1],
                year <= input$year[2],
                sex %in% sexSelection,
                age %in% ageSelection
            )
    })

    output$location = renderUI({
        selectInput("location",
                    "Location:",
                    choices = countries)
    })

    output$suicide_total = renderUI({
        sliderInput(
            "suicide_total",
            # Get max and min values of gdp
            "Suicide Total:",
            min = as.double(colMin(tidy_data)[3]),
            max = as.double(colMax(tidy_data)[3]),
            value = c(0, 200000)
        )
    })

    output$year = renderUI({
        sliderInput(
            "year",
            # Get max and min values of gdp
            "Year:",
            min = 1985,
            # Pick 1985 because of suicide data
            max = 2015,
            value = c(1985, 2015)
        )
    })

    output$gdp = renderUI({
        sliderInput(
            "gdp",
            # Get max and min values of gdp
            "GDP:",
            min = round(as.double(colMin(tidy_data)[5]), 3),
            max = round(as.double(colMax(tidy_data)[5]), 3),
            value = c(0, 200000)
        )
    })

    output$population = renderUI({
        sliderInput(
            "population",
            # Get max and min values of population
            "Population:",
            min = as.double(colMin(tidy_data)[4]),
            max = as.double(colMax(tidy_data)[4]),
            value = c(as.double(colMin(tidy_data)[4]), as.double(colMax(tidy_data)[4]))
        )
    })

    output$age = renderUI({
        sliderTextInput(
            "age",
            # Get categories
            "Age:",
            choices = ageGroups,
            selected = c(ageGroups[1], ageGroups[6])
        )
    })

    output$sex = renderUI({
        radioButtons(
            "sex",
            "Sex:",
            choices = c("Male", "Female", "All"),
            selected = c("All"),
            inline = TRUE
        )
    })
    
    # Create a map by leaflet. Abondoned after milestone2

    # getSelectedLocation <- reactive({
    #     location_to_search <- input$location
    #     if (is.null(location_to_search)) {
    #         location_to_search <- "Canada"
    #     }
    #     location <- geocode(location_to_search, source="dsk")
    #
    #     return(location)
    # })

    # # https://github.com/datasets/geo-countries/blob/master/data/countries.geojson
    # geojson <- readLines("data/countries.geo.json", warn = FALSE) %>%
    #     paste(collapse = "\n") %>%
    #     fromJSON(simplifyVector = FALSE)

    # Default styles for all features
    # geojson$style = list(
    #     weight = 1,
    #     color = "#555555",
    #     opacity = 1,
    #     fillOpacity = 0.8
    # )

    # Gather GDP estimate from all countries
    # geojson_countries <- sapply(geojson$features, function(feat) {
    #     feat$properties$name
    # })
    #print(geojson_countries)
    #geojson_countries_df <- as_tibble(geojson_countries)
    #print(suicideData)
    #print(geojson_countries_df)

    #suicide_data_geojson <- geojson_countries %>%
    #join(suicideData, by = c("country" = "value"))

    #print(suicide_data_geojson)

    # Gather population estimate from all countries
    # pop <- sapply(geojson$features, function(feat) {
    #     max(1, feat$properties$pop)
    # })

    # Color by per-capita GDP using quantiles
    # pal <- reactive({
    #     colorQuantile("Greens", data_by_year()$suicides_total / data_by_year()$pop)Idk
    # })

    # Add a properties$style list to each feature
    # geojson$features <- lapply(geojson$features, function(feat) {
    #     feat$properties$style <- list(
    #         # fillColor = pal(
    #         #     feat$properties$suicides_total / max(1, feat$properties$pop)
    #         # )
    #         fillColor = 1
    #     )
    #     feat
    # })
    # print(geojson$features)


    # output$suicideMap <- renderLeaflet({
    #     leaflet() %>%
    #         addProviderTiles(providers$CartoDB.PositronNoLabels,
    #                          options = providerTileOptions(noWrap = TRUE)
    #         ) %>%
    #         addGeoJSON(geojson) %>%
    #         setView(getSelectedLocation()$lon, getSelectedLocation()$lat, zoom=3) #TODO set zoom automatically, efficiency could be improved here as well
    #
    # })

    # Line chart shows Suicide Total vs. year
    pt1 <- reactive({
        hide_legend(
            ggplotly(
                data_by_sex() %>%
                    ggplot(aes(x = year, y = suicide_rate)) +
                    geom_line(aes(color = sex), size = 2) +
                    xlab("Year") +
                    ylab("Suicide Rate") +
                    scale_y_continuous(labels = scales::number_format(accuracy = 0.00001)) +
                    # ggtitle(paste(input$location, "From", input$year[1], "to", input$year[2])
                    # ) +
                    theme_bw()
            )
        )
    })


    # bar chart shows suicide_total vs. age
    pt2 <- reactive({
        hide_legend(
            ggplotly(
                data_by_age_sex() %>%
                    ggplot(aes(
                        x = fct_relevel(age, "5-14 years"), y = suicide_rate
                    )) +
                    geom_col(aes(fill = sex), position = "dodge") +
                    xlab("Age Group") +
                    ylab("Suicides Rate") +
                    scale_y_continuous(labels = scales::number_format(accuracy = 0.00001)) +
                    # ggtitle("Number of Suicides vs. Age Group") +
                    theme_bw() +
                    theme(axis.text.x = element_text(
                        angle = -90, hjust = 1
                    ))
            )
        )
    })

    # Line chart shows gdp vs. year
    pt3 <- reactive({
        hide_legend(
            ggplotly(
                data_by_year() %>%
                    ggplot(aes(x = year, y = Value)) +
                    geom_line(size = 2) +
                    expand_limits(y = 0) +
                    xlab("Year") +
                    ylab("GDP Per Capita") +
                    # ggtitle("GDP Per Capita vs. Year") +
                    theme_bw()
            )
        )
    })

    # Line chart shows pop vs. year
    pt4 <- reactive(hide_legend(
        ggplotly(
            data_by_sex() %>%
                ggplot(aes(x = year, y = pop)) +
                geom_line(aes(color = sex), size = 2) +
                geom_line(data = data_by_year(), size = 2) +
                scale_y_continuous(labels = scales::number_format(accuracy = 1)) +
                expand_limits(y = 0) +
                xlab("Year") +
                ylab("Population") +
                # ggtitle("Population vs. Year") +
                theme_bw()
        )
    ))

    # scatter chart shows suicide_rate vs. Log Population over the world
    # This plot does not need to be interactive
    pt5 <- reactive(hide_legend(
        ggplotly(
            world_by_country_year() %>%
                left_join(gdpData, by = c(
                    "country" = "Country or Area", "year" = "Year"
                )) %>%
                ggplot(aes(x = pop, y = suicide_rate)) +
                #geom_point(alpha = 0.4) +
                geom_bin2d() +
                scale_x_log10(
                    breaks = scales::trans_breaks("log10", function(x)
                        10 ^ x)
                    # labels = scales::trans_format("log10", scales::math_format(10 ^
                    #                                                                .x))
                ) +
                scale_y_continuous(labels = scales::number_format(accuracy = 0.0001)) +
                #scale_y_continuous(scales::number_format(accuracy = 0.01)) +
                xlab("log Population") +
                ylab("Suicide Rate") +
                # ggtitle(
                #     paste("World from", input$year[1], "to", input$year[2]),
                #     subtitle = "Suicide Rate vs. Log Population"
                # ) +
                theme_bw()
        )
    ))

    # scatter chart shows suicide_rate vs. Log GDP over the world
    # This plot does not need to be interactive
    pt6 <- reactive(hide_legend(
        ggplotly(
            world_by_country_year() %>%
                ggplot(aes(x = Value, y = suicide_rate)) +
                geom_bin2d() +
                scale_x_log10(
                    # breaks = scales::trans_breaks("log10", function(x)
                    #     10 ^ x)#,
                    # labels = scales::trans_format("log10", scales::math_format(10 ^
                    #                                                                .x))
                ) +
                scale_y_continuous(labels = scales::number_format(accuracy = 0.0001)) +
                xlab("log GDP Per Capita") +
                ylab("Suicide Rate") +
                # ggtitle("", subtitle = "Suicide Rate vs. Log GDP Per Capita") +
                theme_bw()
        )
    ))


    # Line chart shows suicide_rate vs. Year over the world
    # This plot is only interactive with year and/or sex input
    pt7 <- reactive(hide_legend(
        ggplotly(
            world_by_sex_year() %>%
                ggplot(aes(x = year, y = suicide_rate)) +
                geom_line(aes(color = sex), size = 2) +
                geom_line(data = world_by_year(), size = 2) +
                xlab("Year") +
                ylab("Suicide Rate") +
                # ggtitle("", subtitle = "Suicide Rate vs. Year") +
                theme_bw()
        )
    ))

    # bar chart shows suicide_rage vs. age world
    pt8 <- reactive(hide_legend(
        ggplotly(
            world_by_sex_year_age() %>%
                ggplot(aes(
                    x = fct_relevel(age, "5-14 years"), y = suicides_total
                )) +
                geom_col(aes(fill = sex), position = "dodge") +
                xlab("Age Group") +
                ylab("Number of Suicides") +
                # ggtitle("", subtitle = "Number of Suicides vs. Age Group") +
                theme_bw() +
                theme(axis.text.x = element_text(
                    angle = -90, hjust = 1
                ))
        )
    ))

    # render plots with subplot+layout
    output$plotgraph = renderPlotly({
        subplot(pt1(),pt2(),pt3(),pt4(),
                nrows=2, margin = 0.1) %>% 
        layout(annotations = list(list(x = 0.06 , y = 1.05, text = "Number of Suicides vs. Year", showarrow = F, xref='paper', yref='paper'),
                                  list(x = 0.96 , y = 1.05, text = "Number of Suicides vs. Age Group", showarrow = F, xref='paper', yref='paper'),
                                  list(x = 0.1 , y = 0.44, text = "GDP Per Capita vs. Year", showarrow = F, xref='paper', yref='paper'),
                                  list(x = 0.9 , y = 0.44, text = "Population vs. Year", showarrow = F, xref='paper', yref='paper'))
               )
    })

    output$plotgraph_world = renderPlotly({
        subplot(pt5(), pt6(), pt7(), pt8(),
                nrows = 2, margin = 0.1) %>% 
        layout(annotations = list(list(x = 0.04 , y = 1.05, text = "Suicide Rate vs. Log Population", showarrow = F, xref='paper', yref='paper'),
                                  list(x = 0.98 , y = 1.05, text = "Suicide Rate vs. Log GDP Per Capita", showarrow = F, xref='paper', yref='paper'),
                                  list(x = 0.1 , y = 0.44, text = "Suicide Rate vs. Year", showarrow = F, xref='paper', yref='paper'),
                                  list(x = 0.98 , y = 0.44, text = "Number of Suicides vs. Age Group", showarrow = F, xref='paper', yref='paper'))
            )
    })
    
    # render titles
    output$title1 <- renderText(
        paste(input$location, "from", input$year[1], "to", input$year[2]), quoted = FALSE
    )
    
    output$title2 <- renderText(
        paste("World from", input$year[1], "to", input$year[2]), quoted = FALSE
    )
}

# Run the application
shinyApp(ui = ui, server = server)
