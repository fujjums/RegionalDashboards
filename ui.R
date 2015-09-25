#
library(shiny)
library(ggvis)
library(leaflet)
shinyUI(navbarPage("Regional Dashboard!",
                   tabPanel("Orders",
                            sidebarLayout(
                              sidebarPanel(
                                selectInput("orders_input_region", label = h5("Choose a Region"), 
                                            choices = list("NY", "SF Bay", "Both Regions"), selected = "Both Regions"),
                                
                                selectInput("orders_input_type", label = h5("Choose a Community Type"), 
                                            choices = list("School", "Home/Work", "All"), selected = "All"),
                                dateRangeInput("orders_input_orderDate", label = h5("Order Date Range") , start = "2015-01-01",
                                               format = "yyyy-mm-dd", startview = "month"),
                                conditionalPanel(
                                  'input.ordersTabs==="Deepdive"',
                                  sliderInput("orders_input_memberOrderNumber", label = h5("Member Order Number"), min = 1, 
                                              max = 200, value = c(1, 200)),
                                  sliderInput("orders_input_communityPickupWeek", label = h5("Community Pickup Week"), min = 1, 
                                              max = 200, value = c(1, 200)),
                                  sliderInput("orders_input_pickupsSinceLast", label = h5("Pickup Weeks Since Last Order"), min = 0, 
                                              max = 200, value = c(0, 200)),
                                  checkboxInput("orders_input_couponBool", label = "Coupon", value = FALSE),
                                  checkboxInput("orders_input_comp
                                                Bool", label = "Comp", value = FALSE),
                                  sliderInput("orders_input_value", label = h5("Order Value"), min = 0, 
                                              max = 2000, value = c(0, 2000)),
                                  downloadButton('downloadData', 'Download Data'))
                                ),
                              mainPanel(
                                tabsetPanel(
                                  id = 'ordersTabs',
                                  tabPanel("Summary", 
                                           h3("Orders Data"),
                                           tableOutput("orders_render_table_summary"),
                                           h4("TOV"),
                                           htmlOutput("orders_render_graph_TOV"),
                                           h4("AOV"),
                                           htmlOutput("orders_render_graph_AOV"),
                                           h4("# of Orders"),
                                           htmlOutput("orders_render_graph_ordercount"),
                                           h4("New Members"),
                                           htmlOutput("orders_render_graph_newmembers"),
                                           h4("Delivering Communities"),
                                           htmlOutput("orders_render_graph_communities")
                                           ),
                                  tabPanel("Map", leafletOutput("orders_render_map_orders")),
                                  # tabPanel("Map", plotOutput("map_communitiesmap")),
                                  tabPanel("Deepdive", 
                                           tableOutput("orders_render_table_deepdive"),
                                           tableOutput("orders_render_table_coupon"),
                                           tableOutput("orders_render_table_comp")
                                           
                                           ),
                                  tabPanel("RawData", dataTableOutput(outputId="orders_render_table_rawdata"))
                                )  
                              )
                   )
                            ),
                   tabPanel("Cohort", 
                            sidebarLayout(
                              sidebarPanel(
                                radioButtons("cohort_input_timeframe", label = h5("Choose a Cohort Time Frame"), 
                                             choices = list("Week", "Month", "Annual"), selected = "Week"),
                                
                                selectInput("cohort_input_region", label = h5("Choose a Region"), 
                                            choices = list("NY", "SF Bay", "Both Regions"), selected = "Both Regions"),
                                
                                selectInput("cohort_input_type", label = h5("Choose a Community Type"), 
                                            choices = list("School", "Home/Work", "All"), selected = "All"),
                                dateRangeInput("cohort_input_firstOrder", label = h5("Order Date Range") , start = "2015-01-01",
                                               format = "yyyy-mm-dd", startview = "month")
                                
                              ),
                              
                              mainPanel(
                                tabsetPanel(
                                  tabPanel("Summary", 
                                           h4("AMO-4,12,24"),
                                           htmlOutput("cohort_render_AMOgraph"),
                                           h4("TMV-4,12,24"),
                                           htmlOutput("cohort_render_TMVgraph"),
                                           h4("AMO-4 Breakout"),
                                           checkboxInput("cohort_input_100perc", label = "100% Stacked", value = FALSE),
                                           htmlOutput("cohort_render_AMO4graph"),
                                           htmlOutput("cohort_render_AMO4vsTMV12")
                                  )
                                )
                              )
                            )
                   ),
                   tabPanel("Communities", 
                            sidebarLayout(
                              sidebarPanel(
                                conditionalPanel(
                                  'input.tabs === "Summary"',
                                selectInput("communities_input_region", label = h5("Choose a Region"), 
                                            choices = list("NY", "SF Bay", "Both Regions"), selected = "Both Regions"),
                                
                                selectInput("communities_input_type", label = h5("Choose a Community Type"), 
                                            choices = list("School", "Home/Work", "All"), selected = "All")
                                )
                              ),
                              
                              mainPanel(
                                tabsetPanel(
                                  id = 'tabs',
                                  tabPanel("Summary", dataTableOutput("communities_render_table_data")
                                  )
                                )
                              )
                            )
                   )
                   
                   
))