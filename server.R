
library(shiny)  
library(tidyr)
library(dplyr)
library(ggplot2)
library(zoo)
library(googleVis)
library(zipcode)
library(leaflet)
setwd("./data/")
Orders <- as.data.frame(read.csv("toMergeOrders.csv", stringsAsFactors=FALSE, na.strings = "NA"))
#change dates from strings-> dates
Orders$First.order <- as.Date(Orders$First.order, format = "%Y-%m-%d")
Orders$Last.order <- as.Date(Orders$Last.order, format = "%Y-%m-%d")
Orders$Pick.up.Date <- as.Date(Orders$Pick.up.Date, format = "%Y-%m-%d")
Orders$order_week <- as.Date(Orders$order_week, format = "%Y-%m-%d")
class(Orders$order_week)
Orders$order_month <- as.Date(as.yearmon(Orders$order_week))
Orders$order_year <- format(Orders$order_week, format="%Y")

data(zipcode)
Orders[c("Coupon", "Comp", "Ref.Receipt", "Ref.Sender")][is.na(Orders[c("Coupon", "Comp", "Ref.Receipt", "Ref.Sender")])] <- 0

Orders$Zip.Code <- clean.zipcodes(Orders$Zip.Code)
Orders <- inner_join(Orders, zipcode[c(1,4:5)], by = c("Zip.Code" = "zip"))

Members <- as.data.frame(read.csv("toMergeMembers.csv", stringsAsFactors=FALSE, na.strings = "NA"))
	
Members$mem_first_order_week <- as.Date(Members$mem_first_order_week, format = "%Y-%m-%d")
Members$mem_last_order_week <- as.Date(Members$mem_last_order_week, format = "%Y-%m-%d")

Members$mem_first_order_month <- as.Date(as.yearmon(Members$mem_first_order_week))
Members$mem_first_order_year <- format(Members$mem_first_order_week, format="%Y")

Community <- as.data.frame(read.csv("toMergeCommunity.csv", stringsAsFactors=FALSE, na.strings = "NA"))
Community$comm_first_pickup_week <- as.Date(Community$comm_first_pickup_week, format = "%Y-%m-%d")
Community$comm_last_order_week <- as.Date(Community$comm_last_order_week, format = "%Y-%m-%d")




shinyServer(
  function(input, output) {
#
#
#ORDER TAB#    
#
#
    
#-------------------------------------------------
#Reactive Functions (used by the render functions)
#-------------------------------------------------
    
      orders_reactive_region <- reactive({
          switch(input$orders_input_region,
               "NY" = c("NY"),
               "SF Bay" = c("SF Bay"),
               "Both Regions" = c("NY","SF Bay"))  
      })

      orders_reactive_type <- reactive({
          switch(input$orders_input_type,
                "School" = c("SCHOOL"),
                "Home/Work" = c("HOME", "WORKPLACE"),
                "All" = c("SCHOOL","HOME", "WORKPLACE"))
      })
      
      orders_reactive_coupon <- reactive({
        if(input$orders_input_couponBool == "TRUE"){0}
        else{-1}
      })
      
      orders_reactive_comp <- reactive({
        if(input$orders_input_couponBool == "TRUE"){0}
        else{-1}
      })
      
      orders_reactive_data <- reactive({
        Orders %>%
          filter(Region %in% orders_reactive_region(), Community.Type %in% orders_reactive_type(), 
                 (Pick.up.Date >= input$orders_input_orderDate[1] &
                    Pick.up.Date <= input$orders_input_orderDate[2] )
          )
      })
      
      orders_reactive_data_deepdive <- reactive({
        orders_reactive_data() %>%
          filter(
            (Member.Order.Number >= input$orders_input_memberOrderNumber[1] &
               Member.Order.Number <= input$orders_input_memberOrderNumber[2]),
            (Pick.up.Weeks.Since.Last >= input$orders_input_pickupsSinceLast[1] &
               Pick.up.Weeks.Since.Last <= input$orders_input_pickupsSinceLast[2]),
            (Value >= input$orders_input_value[1] &
               Value <= input$orders_input_value[2]),
            (Community.Pickup.Week >= input$orders_input_communityPickupWeek[1] &
               Community.Pickup.Week <= input$orders_input_communityPickupWeek[2]),
            Coupon > orders_reactive_coupon(),
            Comp > orders_reactive_comp())
      })
      
#-------------------------------------------------
#Render Functions
#-------------------------------------------------
    #Data for Download Button
      output$download_data <- downloadHandler(
        filename = 'download.csv',
        content = function(file) {
          write.csv(orders_reactive_data(), file)
        }
      )
      
    #Summary Tab Output
      output$orders_render_table_summary <- renderTable({
          orders_reactive_data() %>%
          summarise(count = n(), 
                    avg=mean(Value), 
                    median=median(Value), 
                    distinct_members = n_distinct(Subscription.Id),
                    distinct_comms = n_distinct(Community.Id))
      })
      

      output$orders_render_graph_TOV <- renderGvis({
        graph_data <- orders_reactive_data() %>% 
          filter(Community.Type %in% c("WORKPLACE", "HOME", "SCHOOL")) %>%
          group_by(order_week, Community.Type) %>%
          summarise(Total=sum(Value)) %>%
          spread(Community.Type, Total)
        gvisLineChart(graph_data, xvar="order_week", yvar=orders_reactive_type())
      })
      
      output$orders_render_graph_AOV <- renderGvis({
        graph_data <- orders_reactive_data() %>% 
          filter(Community.Type %in% c("WORKPLACE", "HOME", "SCHOOL")) %>%
          group_by(order_week, Community.Type) %>%
          summarise(AOV=mean(Value)) %>%
          spread(Community.Type, AOV)
        gvisLineChart(graph_data, xvar="order_week", yvar=orders_reactive_type())
      })
      
      output$orders_render_graph_ordercount <- renderGvis({
        graph_data <- orders_reactive_data() %>% 
          filter(Community.Type %in% c("WORKPLACE", "HOME", "SCHOOL")) %>%
          group_by(order_week, Community.Type) %>%
          summarise(Count=n()) %>%
          spread(Community.Type, Count)
        gvisLineChart(graph_data, xvar="order_week", yvar=orders_reactive_type())
      })
      
      output$orders_render_graph_newmembers <- renderGvis({
        graph_data <- orders_reactive_data() %>% 
          filter(Community.Type %in% c("WORKPLACE", "HOME", "SCHOOL"), Member.Order.Number == 1) %>%
          group_by(order_week, Community.Type) %>%
          summarise(Count=n()) %>%
          spread(Community.Type, Count)
        gvisLineChart(graph_data, xvar="order_week", yvar=orders_reactive_type())
      })
      
      
      output$orders_render_graph_communities <- renderGvis({
        graph_data <- orders_reactive_data() %>% 
          filter(Community.Type %in% c("WORKPLACE", "HOME", "SCHOOL")) %>%
          group_by(order_week, Community.Type) %>%
          summarise(Count = n_distinct(Community.Id)) %>%
          spread(Community.Type, Count) %>%
        gvisLineChart(xvar="order_week", yvar=orders_reactive_type())
      })
      
    #Map Tab Output
      output$orders_render_map_orders <- renderLeaflet({
        #summarize data by long/lat
        Map_Data<-orders_reactive_data() %>%
          group_by(longitude, latitude, Zip.Code, Community.Type) %>%
          summarize(TotalOrders=n(), TotalOrderValue=sum(Value))
        
        leaflet(Map_Data) %>% addTiles() %>%
        #  addMarkers()
        addCircleMarkers(
          radius = 2,
          popup = ~paste("ZIP CODE: ", Zip.Code, " - ", TotalOrders),
         color = ~ifelse(Community.Type == "SCHOOL", "red","blue")
        ) %>%
          addLegend(position="bottomright", 
                    colors = c("red", "blue"),
                    labels = c("School", "Home/Workplace"))
        
      })
      
    #Deepdive
      output$orders_render_table_deepdive <- renderTable({
          orders_reactive_data_deepdive() %>%
          summarise(count = n(), avg=mean(Value), median=median(Value), distinct_members = n_distinct(Subscription.Id))
      })
      
      output$orders_render_table_coupon <- renderTable({
        Coup<- orders_reactive_data_deepdive() %>%
          summarise(
                    "Avg. Value" = mean(Coupon[Coupon>0]),
                    "Total Value" = sum(Coupon[Coupon>0]),
                    No_Discount = sum(Coupon==0),
                    Discount = sum(Coupon>0),
                    "%Discount" =  Discount/sum(Discount+No_Discount))
        
        Comp<-orders_reactive_data_deepdive() %>%
          summarise(
            "Avg. Value" = mean(Comp[Comp>0]),
            "Total Value" =  sum(Comp[Comp>0]),
            No_Discount= sum(Comp==0),
            Discount = sum(Comp>0),
            "%Discount" = Discount/sum(Discount+No_Discount))
        
        output <- rbind(Coup, Comp)
        row.names(output) <- c("Coup", "Comp")
        output
       })
      
      output$orders_render_table_comp <- renderTable({
        orders_reactive_data_deepdive() %>%
          summarise(
            "Avg. Comp Value" = mean(Comp[Comp>0]),
            "Total Comp Value" =  sum(Comp[Comp>0]),
            "NoComp" = sum(Comp==0),
            "Comp" = sum(Comp>0),
            "%Comp" = Comp/sum(Comp+NoComp))
      })

    #Data Tab Output
      output$orders_render_table_rawdata <- renderDataTable({
        orders_reactive_data_deepdive()
      })
    


                
#
#
#Cohort TAB#  
#                    
#      
      #-------------------------------------------------
      #Reactive Functions (used by the render functions)
      #-------------------------------------------------
      
      
      cohort_reactive_timeframe <- reactive({
        switch(input$cohort_input_timeframe,
               "Week" = "mem_first_order_week",
               "Month" = "mem_first_order_month",
               "Annual" = "mem_first_order_year")
      })
      
      cohort_reactive_region <- reactive({
        switch(input$cohort_input_region,
               "NY" = c("NY"),
               "SF Bay" = c("SF Bay"),
               "Both Regions" = c("NY","SF Bay"))  
      })
      
      cohort_reactive_type <- reactive({
        switch(input$cohort_input_type,
               "School" = c("SCHOOL"),
               "Home/Work" = c("HOME", "WORKPLACE"),
               "All" = c("SCHOOL","HOME", "WORKPLACE"))
      }) 
      cohort_reactive_data <- reactive({
        Members %>%
          filter(Region %in% cohort_reactive_region(), Community.Type %in% cohort_reactive_type(), 
                 (mem_first_order_week >= input$cohort_input_firstOrder[1] &
                    mem_first_order_week <= input$cohort_input_firstOrder[2] )
          )
      })

    
      
      #-------------------------------------------------
      #Render Functions
      #-------------------------------------------------   
     output$cohort_render_AMOgraph <- renderGvis({
        cohort_reactive_data() %>% 
          filter(Community.Type %in% c("WORKPLACE", "HOME", "SCHOOL")) %>%
          group_by_(cohort_reactive_timeframe()) %>%
          summarise(AMO4=mean(count4, na.rm=TRUE), 
                    AMO12=mean(count12, na.rm=TRUE),
                    AMO24=mean(count24, na.rm=TRUE),
                    count=sum(X..Orders>=1, na.rm=TRUE)) %>%
        gvisLineChart(xvar=cohort_reactive_timeframe(), 
                      yvar=c("AMO4", "AMO12", "AMO24", "count"),
                      options=list(legend="bottom",
                                   series=
                                      "[{type:'line', 
                                       targetAxisIndex:0,
                                       color:'blue'}, 
                                       {type:'line', 
                                       targetAxisIndex:0,
                                       color:'red'},
                                       {type:'line', 
                                       targetAxisIndex:0,
                                       color:'orange'},
                                       {type:'bars', 
                                       targetAxisIndex:1,
                                       color:'lightgrey',
                                       opacity: .8}]",
                                   vAxes="[{title:'AMO-4,12,24'
                                      }, 
                                      {title:'Cohort Size',
                                      maxValue:1000}]",
                                   hAxes=
                                        "[{format:'MMM-yy'}
                                        ]"
                                  )
                      )
      })
      
      output$cohort_render_TMVgraph <- renderGvis({
        cohort_reactive_data() %>% 
          filter(Community.Type %in% c("WORKPLACE", "HOME", "SCHOOL")) %>%
          group_by_(cohort_reactive_timeframe()) %>%
          summarise(TMV4=mean(sum4, na.rm=TRUE), 
                    TMV12=mean(sum12, na.rm=TRUE),
                    TMV24=mean(sum24, na.rm=TRUE),
                    count=sum(X..Orders>=1, na.rm=TRUE)
                    ) %>%
          gvisLineChart(xvar=cohort_reactive_timeframe(), 
                        yvar=c("TMV4", "TMV12", "TMV24", "count"),
                        options=list(legend="bottom",
                                     series=
                                      "[{type:'line', 
                                       targetAxisIndex:0,
                                       color:'blue'}, 
                                       {type:'line', 
                                       targetAxisIndex:0,
                                       color:'red'},
                                       {type:'line', 
                                       targetAxisIndex:0,
                                       color:'orange'},
                                       {type:'bars', 
                                       targetAxisIndex:1,
                                       color:'lightgrey',
                                       opacity: .8}]",
                                     vAxes=
                                       "[{title:'AMO-4,12,24'}, 
                                       {title:'Cohort Size',
                                       maxValue:1000}]",
                                     hAxes=
                                       "[{
                                        slantedText: 'TRUE',
                                        slantedTextAngle: 90}
                                        ]"
                                      )
                        )
      })
      
      output$cohort_render_AMO4graph <- renderGvis({
        cohort_reactive_data <- cohort_reactive_data() %>% 
          filter(Community.Type %in% c("WORKPLACE", "HOME", "SCHOOL"), count4<=4) %>%
          group_by_(cohort_reactive_timeframe(), "count4") %>%
          summarise(Count=n()) %>%
          spread(count4, Count)
        
          if(input$cohort_input_100perc==TRUE){
            cohort_reactive_data[,2:5] <- cohort_reactive_data[,2:5]/rowSums(cohort_reactive_data[,2:5], na.rm=TRUE)  
          }
         
          gvisColumnChart(cohort_reactive_data, 
                          xvar=cohort_reactive_timeframe(), 
                          yvar=c("1","2","3","4"), 
                          options=list(
                            isStacked=TRUE,
                            legend="bottom",
                            series=
                              "[{
                            color:'red'}, 
                            {
                            color:'orange'},
                            {
                            color:'green'},
                            {
                            color:'blue'}]")
                          )
      })
      
      output$cohort_render_AMO4vsTMV12 <- renderGvis({
        cohort_reactive_data() %>% 
          filter(Community.Type %in% c("WORKPLACE", "HOME", "SCHOOL")) %>%
          group_by_(cohort_reactive_timeframe()) %>%
          summarise(AMO4=mean(count4, na.rm=TRUE), 
                    TMV12=mean(sum12, na.rm=TRUE)) %>%
          select(AMO4,TMV12) %>%
        gvisScatterChart(
          options=list(
                                      vAxes=
                                        "[{title:'TMV-12'}]", 
                                      hAxes=
                                        "[{title:'AMO-4'}]"
            
           )
          
        )
        
      })
      
      
#
#
#Communities TAB#  
#                    
#      
      #-------------------------------------------------
      #Reactive Functions (used by the render functions)
      #-------------------------------------------------
      
      communities_reactive_region <- reactive({
        switch(input$communities_input_region,
               "NY" = c("NY"),
               "SF Bay" = c("SF Bay"),
               "Both Regions" = c("NY","SF Bay"))  
      })
      
      communities_reactive_type <- reactive({
        switch(input$communities_input_type,
               "School" = c("SCHOOL"),
               "Home/Work" = c("HOME", "WORKPLACE"),
               "All" = c("SCHOOL","HOME", "WORKPLACE"))
      })
      communities_reactive_data <- reactive({
        Community %>%
          filter(Region %in% communities_reactive_region(), Community.Type %in% communities_reactive_type())
      })      

      
      #-------------------------------------------------
      #Render Functions
      #-------------------------------------------------   
      #Data Tab Output
      output$communities_render_table_data <- renderDataTable({
        communities_reactive_data() %>%
          select(Community, Region, Community.Type, comm_total_pickups, sum12, sum24, sum48, count12, count24, count48)
      })
      
      
})