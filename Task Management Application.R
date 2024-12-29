library(shiny)
library(shinydashboard)
library(readxl)
library(writexl)
library(DT)
library(shinyalert)
library(shinyjs)
library(plotly)
library(dplyr)
library(lubridate)
library(tidyr)

# Define valid users
valid_users <- list(
  admin = "admin123",
  user1 = "user123",
  user2 = "user1234")

# Define weekends and holidays (adjust as per your needs)
weekends <- c("Saturday", "Sunday")  # Example: weekends are Saturday and Sunday

# Define holidays (provide dates in 'YYYY-MM-DD' format)
holidays <- as.Date(c(
  "2024-07-04",  # Example: Independence Day
  "2024-01-01",
  "2024-01-26",
  "2024-02-16",
  "2024-03-08",
  "2024-03-29",
  "2024-03-31",
  "2024-04-10",
  "2024-04-01",
  "2024-05-10",
  "2024-05-12",
  "2024-05-01",
  "2024-06-03",
  "2024-06-09",
  "2024-06-16",
  "2024-10-09",
  "2024-12-25",
  "2024-12-26"
  
  
  # Example: Christmas
))

# Define UI for application
ui <- dashboardPage(
  # Dashboard header with app title
  dashboardHeader(title = HTML("<div class='header-title'>Umeme Limited</div>")),
  
  # Sidebar with a menu for different pages
  dashboardSidebar(
    width = 1,  # You can adjust this value to reduce or increase the width
    
    tags$style(HTML("
      .main-sidebar {
        background-color: #f0f8ff; /* Primary Background Color */
        color: #333333; /* Primary Text Color */
      }
      .main-sidebar .sidebar-menu a {
        color: #333333; /* Text Color in Sidebar */
      }
      .main-sidebar .sidebar-menu a:hover {
        background-color: #ff6347; /* Accent Color on Hover */
        color: #ffffff; /* Text Color on Hover */
      }
      .content-wrapper {
        background-color: #ffffff; /* Secondary Background Color */
        color: #333333; /* Primary Text Color */
      }
      .box {
        background-color: #ffffff; /* Box Background Color */
        border-color: #e0e0e0; /* Box Border Color */
      }
      .box-header {
        background-color: #f0f8ff; /* Box Header Background Color */
      }
      .box-header .box-title {
        color: #333333; /* Box Title Color */
      }
      .navbar {
        background-color: #ff6347; /* Navbar Background Color */
        color: #ffffff; /* Navbar Text Color */
      }
      .navbar a {
        color: #ffffff; /* Navbar Link Color */
      }
      .navbar a:hover {
        color: #f0f8ff; /* Navbar Link Hover Color */
      }
    "))
    
  ),
  
  # Body content
  dashboardBody(
    useShinyalert(),
    tags$head(
      tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css?family=Roboto:300,400,500,700&display=swap"),
      tags$style(HTML("
          .header-title {
          font-size: 20px; /* Adjust font size */
          font-weight: bold; /* Make title bold */
          color: #ffffff; /* Title text color */
             line-height: 50px; /* Align with header height */
          padding-left: 15px; /* Space from the left */
          padding-right: 15px; /* Space from the right */
         # max-width: 80%; /* Limit the maximum width of the title */
         # margin: 0 auto; /* Center the title */
          #text-align: center; /* Center the text */
          }
           .btn-toggle-sidebar {
          margin-top: 15px;
          margin-right: 15px;
          background-color: #007bff;
          color: white;
        }
        .btn-toggle-sidebar:hover {
          background-color: #0056b3;
        }
        
        
        
        .main-header .logo {
          height: 50px; /* Adjust logo height */
        }
      
        body {
          font-family: 'Roboto', sans-serif;
        }
        h2, .box-title, .value-box .value, .value-box .text {
          font-weight: 500;
        }
        .login-form {
          text-align: center;
          padding: 20px;
          background: white;
          border: 1px solid #ddd;
          border-radius: 10px;
          box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
          font-family: 'Roboto', sans-serif;
        }
        .login-container {
          display: flex;
          justify-content: center;
          align-items: center;
          flex-direction: column;
          height: 100vh;
          background-color: #f8f9fa;
        }
        .login-form img {
          max-width: 100%;
          height: auto;
          margin-bottom: 20px;
        }
        .hidden {
          display: none;
        }
        
        .dataTable tbody tr:nth-child(odd) {
          background: linear-gradient(to right, #e0f7fa, #80deea);
        }
        .dataTable tbody tr:nth-child(even) {
          background: linear-gradient(to right, #b2ebf2, #4dd0e1);
        }
        .dataTable tbody tr:hover {
          background-color: #b2ebf2 !important;
        }
  .centered-title {
    text-align: center;
    font-weight: bold;
    margin-bottom: 30px;  /* Adjust the value as needed */
  }
  
      "))
    ),
    uiOutput("ui")
  )
)

# Define server logic
server <- function(input, output, session) {
  
  # Determine the relative path to the Excel file
  excel_file <- "task_list.xlsx"
  
  # Reactive value to store login status
  logged_in <- reactiveVal(FALSE)
  current_user <- reactiveVal(NULL)
  
  # Reactive value for showing/hiding the notification box
  show_notification <- reactiveVal(FALSE)
  
  # Function to read tasks from Excel, handling file existence
  load_tasks <- function() {
    if (file.exists(excel_file)) {
      read_excel(excel_file, na = "")
    } else {
      data.frame(
        emp_id = character(),
        emp_name = character(),
        task_desc = character(),
        start_date = as.Date(character()),
        end_date = as.Date(character()),
        proposed_end_date = as.Date(character()),
        status = character(),
        stringsAsFactors = FALSE
      )
    }
  }
  
  # Reactive values for tasks
  tasks <- reactiveVal(load_tasks())
  
  # Function to calculate working days between two dates
  working_days <- function(start_date, end_date) {
    all_days <- seq.Date(start_date, end_date, by = "day")
    work_days <- all_days[!weekdays(all_days) %in% weekends & !(all_days %in% holidays)]
    length(work_days)
  }
  
  # Reactive expression to filter tasks based on search
  filtered_tasks <- reactive({
    if (input$search_employee == "") {
      tasks()
    } else {
      tasks()[grepl(input$search_employee, tasks()$emp_name, ignore.case = TRUE), ]
    }
  })
  
  # Render the UI based on login status
  output$ui <- renderUI({
    if (!logged_in()) {
      fluidPage(
        div(class = "login-container",
            h2(HTML("<b>Strategy and Analytics</b>"), align = "center"),  # Text made bold here
            div(class = "login-form",
                tags$i(class = "fa fa-lock fa-3x", style = "margin-bottom: 50px;"),
                titlePanel("Login"),
                textInput("username", "Username", value = ""),
                passwordInput("password", "Password", value = ""),
                actionButton("login", "Login"),
                textOutput("login_message")
            )
        )
      )
    } else {
      fluidPage(
        
        div(class = "centered-title",
            titlePanel(HTML("<b>Welcome to the Strategy and Analytics Task Management System</b>"))
        )
        ,
        fluidRow(
          box( width = 12, status = "primary",
               box(width = 12, 
                   valueBoxOutput("completed_tasks"),
                   valueBoxOutput("avg_days_to_complete"),
                   valueBoxOutput("avg_task_efficiency")
                   
               )),
          
          
          # Search employees
          box(width = 12,
              box(title = "Search employee by name", width = 12, solidHeader = TRUE,
                  textInput("search_employee", "Search Employee by Name:", value = ""),
                  status = "primary", collapsible = TRUE
              )),
          
  
          
          fluidRow(
            tabBox(
              title = "",
              id = "tabset1", width = 12,
              tabPanel("Tab"),
              
              tabPanel(  title = div(style = "color: #fff; background-color: #007bff; padding: 10px;", "Monthly statistics"), # Section to display the graph
                         box(width = 12, solidHeader = TRUE,
                             fluidRow(
                               box(title = "Tasks by Month", width = 6, plotlyOutput("tasks_month_plot")),
                        
                               
                               
                                
                                 box(title = "Average days to complete tasks by Month", width = 6, plotlyOutput("avg_days_to_complete_plot")),
                               box(title = "Tasks Completed Within and Beyond 10 Days", width = 12,   plotlyOutput("completion_plot")),
                               
                               box(title = "Completed and Pending Tasks Per Month", width = 12,    plotlyOutput("tasks_month_plot1") )
                              
                             )
                             
                         )),
              
              
              tabPanel( title = div(style = "color: #fff; background-color:  #007bff; padding: 10px;", "Task Entry Form "), 
                        fluidRow(
                          box(width = 4,
                              # Add New Task section with integrated sidebar content
                              box(title = "Add New Task", width = 12, solidHeader = TRUE,status = "primary", background = "light-blue",
                                  fluidRow(
                                    column(12, textInput("emp_id", "Employee ID:")),
                                    column(12, textInput("emp_name", "Employee Name:")),
                                    column(12, textInput("task_desc", "Task Description:")),
                                    column(6, dateInput("start_date", "Start Date:", value = Sys.Date())),
                                    column(6, dateInput("proposed_end_date", "Proposed Date:")),  # Added proposed end date input field
                                    column(6, dateInput("end_date", "End Date:")),
                                    column(12, selectInput("status", "Status:", choices = c("Pending", "Completed"))),
                                    actionButton("add_task_button", "Add Task", icon = icon("save"), width = "100%"),
                                    br(),
                                    actionButton("edit_task", "Edit Selected Task", icon = icon("pencil"), width = "100%"),
                                    br(),
                                    actionButton("delete_task", "Delete Selected Task", icon = icon("trash"), width = "100%"),
                                    br(),
                                    actionButton("save_tasks", "Save Tasks to Excel", icon = icon("save"), width = "100%"),
                                    br(),
                                    downloadButton("download_tasks", "Download Task List as Excel", width = "100%"),
                                    br()
                                  ),
                                  collapsible = TRUE 
                              )
                          ),
                          # Task table in a box
                          box(width = 8,
                              box(title = "Task List", width = 12,collapsible = TRUE, solidHeader = TRUE, 
                                  status = "primary",
                                  DTOutput("task_table")
                              )
                              
                          )
                        )),
              tabPanel(   title = div(style = "color: #fff; background-color:  #007bff; padding: 10px;", "Total Tasks and Pending Tasks"),   
                          # Notification box for pending tasks
                          box( 
                            title = "Pending Tasks", width = 12, solidHeader = TRUE,
                            fluidRow(
                              
                              valueBoxOutput("total_tasks"),
                              valueBoxOutput("average_tasks"),
                              valueBoxOutput("pending_tasks")
                              
                            ),
                            uiOutput("pending_tasks_notification"),
                            status = "primary",
                            collapsible = TRUE
                          ))
            )
          ),
          
          actionButton("logout", "Logout")
        )
        
      )
    }
  })
  
  # Handle editing and updating tasks
  observeEvent(input$task_table_cell_edit, {
    info <- input$task_table_cell_edit
    row <- info$row
    col <- info$col
    value <- info$value
    
    # Update the tasks data frame
    tasks_df <- tasks()
    
    if (col == "end_date" || col == "proposed_end_date") {
      # Ensure value is converted to Date format
      tasks_df[row, col] <- as.Date(value)
      tasks_df$days_to_complete[row] <- working_days(tasks_df[row, "start_date"], tasks_df[row, "end_date"])
      
      # Calculate proposed time if both actual and proposed end dates are available
      if (!is.na(tasks_df[row, "proposed_end_date"])) {
        proposed_time <- working_days(tasks_df[row, "start_date"], tasks_df[row, "proposed_end_date"])
        tasks_df$proposed_time[row] <- proposed_time
        tasks_df$efficiency[row] <- round(((proposed_time) / tasks_df[row, "days_to_complete"] ) * 100, 0)
      }
    } else {
      tasks_df[row, col] <- value
    }
    
    tasks(tasks_df)
  })
  # Function to display a pop-up notification
  show_success_alert <- function() {
    shinyalert("Login Successful", "You have logged in successfully!", type = "success")
  }
  
  # Handle login button click
  observeEvent(input$login, {
    username <- input$username
    password <- input$password
    
    if (username %in% names(valid_users) && valid_users[[username]] == password) {
      logged_in(TRUE)
      current_user(username)
      show_success_alert()  # Show success alert on successful login
      
    } else {
      output$login_message <- renderText("Invalid username or password")
    }
  })
  
  # Handle logout button click
  observeEvent(input$logout, {
    logged_in(FALSE)
    current_user(NULL)
  })
  
  # Render tasks table
  output$task_table <- renderDT({
    datatable(filtered_tasks(), options = list(scrollX = TRUE), editable = TRUE)
  })
  
  # Handle add task button click
  observeEvent(input$add_task_button, {
    emp_id <- input$emp_id
    emp_name <- input$emp_name
    task_desc <- input$task_desc
    
    # Check if required fields are filled
    if (emp_id == "" || emp_name == "" || task_desc == "") {
      shinyalert("Error", "Please fill in Employee ID, Employee Name, and Task Description.", type = "error")
    } else {
      new_task <- data.frame(
        emp_id = emp_id,
        emp_name = emp_name,
        task_desc = task_desc,
        start_date = as.Date(input$start_date),
        end_date = as.Date(input$end_date),
        proposed_end_date = as.Date(input$proposed_end_date),
        status = input$status,
        stringsAsFactors = FALSE
      )
      
      new_task$days_to_complete <- working_days(new_task$start_date, new_task$end_date)
      
      if (!is.na(new_task$proposed_end_date)) {
        proposed_time <- working_days(new_task$start_date, new_task$proposed_end_date)
        new_task$proposed_time <- proposed_time
        new_task$efficiency <- round((( proposed_time) / new_task$days_to_complete) * 100, 0)
      } else {
        new_task$proposed_time <- NA
        new_task$efficiency <- NA
      }
      
      tasks(rbind(tasks(), new_task))
      shinyalert("Task Added", "The task has been successfully added!", type = "success")
      
      # Clear the form inputs
      updateTextInput(session, "emp_id", value = "")
      updateTextInput(session, "emp_name", value = "")
      updateTextInput(session, "task_desc", value = "")
      updateDateInput(session, "start_date", value = Sys.Date())
      updateDateInput(session, "end_date", value = NULL)
      updateDateInput(session, "proposed_end_date", value = NULL)
      updateSelectInput(session, "status", selected = "Pending")
    }
  })
  
  
  
  
  
  # Handle edit task button click
  observeEvent(input$edit_task, {
    selected_task <- input$task_table_rows_selected
    
    # Check if a task is selected from the filtered tasks
    if (length(selected_task) > 0 && nrow(filtered_tasks()) >= length(selected_task)) {
      
      # Get the task to edit based on the filtered list
      task_to_edit <- filtered_tasks()[selected_task, ]
      
      showModal(modalDialog(
        title = "Edit Task",
        textInput("edit_emp_id", "Employee ID:", value = task_to_edit$emp_id),
        textInput("edit_emp_name", "Employee Name:", value = task_to_edit$emp_name),
        textInput("edit_task_desc", "Task Description:", value = task_to_edit$task_desc),
        dateInput("edit_start_date", "Start Date:", value = as.Date(task_to_edit$start_date)),
        dateInput("edit_end_date", "End Date:", value = as.Date(task_to_edit$end_date)),
        dateInput("edit_proposed_end_date", "Proposed End Date:", value = as.Date(task_to_edit$proposed_end_date)),
        selectInput("edit_status", "Status:", choices = c("Pending", "Completed"), selected = task_to_edit$status),
        footer = tagList(
          actionButton("save_edit_task", "Save Changes"),
          modalButton("Cancel")
        )
      ))
      
      # Handle saving the edited task
      observeEvent(input$save_edit_task, {
        # Get the full task list
        tasks_df <- tasks()
        
        # Find the index of the task to update in the original task list
        full_task_index <- which(tasks_df$emp_name == task_to_edit$emp_name & tasks_df$task_desc == task_to_edit$task_desc)
        
        # Update the selected task's fields but leave other fields unchanged
        if (length(full_task_index) > 0) {
          # Update the specific fields with the edited input
          tasks_df[full_task_index, "emp_id"] <- input$edit_emp_id
          tasks_df[full_task_index, "emp_name"] <- input$edit_emp_name
          tasks_df[full_task_index, "task_desc"] <- input$edit_task_desc
          tasks_df[full_task_index, "start_date"] <- as.Date(input$edit_start_date)
          tasks_df[full_task_index, "end_date"] <- as.Date(input$edit_end_date)
          tasks_df[full_task_index, "proposed_end_date"] <- as.Date(input$edit_proposed_end_date)
          tasks_df[full_task_index, "status"] <- input$edit_status
          
          # Recalculate any derived fields
          tasks_df[full_task_index, "days_to_complete"] <- working_days(as.Date(input$edit_start_date), as.Date(input$edit_end_date))
          
          if (!is.na(input$edit_proposed_end_date)) {
            proposed_time <- working_days(as.Date(input$edit_start_date), as.Date(input$edit_proposed_end_date))
            tasks_df[full_task_index, "proposed_time"] <- proposed_time
            tasks_df[full_task_index, "efficiency"] <- round(((proposed_time) / tasks_df[full_task_index, "days_to_complete"]) * 100, 0)
          } else {
            tasks_df[full_task_index, "proposed_time"] <- NA
            tasks_df[full_task_index, "efficiency"] <- NA
          }
          
          # Save the updated task list
          tasks(tasks_df)
          
          # Close the modal and show confirmation
          removeModal()
          shinyalert::shinyalert("Task Updated", "The task has been successfully updated!", type = "success")
        } else {
          shinyalert::shinyalert("Error", "Task not found.", type = "error")
        }
      }, once = TRUE) # Ensure observeEvent runs only once for save_edit_task
    } else {
      shinyalert::shinyalert("No Selection", "Please select a task to edit.", type = "warning")
    }
  })
  
  # Reactive expression to filter tasks based on search
  filtered_tasks <- reactive({
    if (input$search_employee == "") {
      tasks()
    } else {
      tasks()[grepl(input$search_employee, tasks()$emp_name, ignore.case = TRUE), ]
    }
  })
  
  # Handle delete task button click
  observeEvent(input$delete_task, {
    selected_task <- input$task_table_rows_selected
    
    # Check if a task is selected and filtered_tasks() is not empty
    if (!is.null(selected_task) && length(selected_task) > 0 && nrow(filtered_tasks()) >= length(selected_task)) {
      shinyalert::shinyalert(
        title = "Confirm Deletion",
        text = "Are you sure you want to delete the selected task?",
        type = "warning",
        showCancelButton = TRUE,
        confirmButtonText = "Yes, delete it!",
        cancelButtonText = "Cancel",
        callbackR = function(value) {
          if (value) { # If user confirmed deletion
            
            # Get the task to delete from the filtered list
            task_to_delete <- filtered_tasks()[selected_task, ]
            
            # Find the corresponding task index in the full tasks list
            full_task_index <- which(
              tasks()$emp_id == task_to_delete$emp_id &
                tasks()$emp_name == task_to_delete$emp_name &
                tasks()$task_desc == task_to_delete$task_desc &
                tasks()$start_date == task_to_delete$start_date &
                tasks()$end_date == task_to_delete$end_date
            )
            
            # Ensure a valid index was found before proceeding
            if (length(full_task_index) > 0) {
              # Remove only the selected task from the full task list
              updated_tasks <- tasks()[-full_task_index, ]
              tasks(updated_tasks)  # Update the reactive `tasks()` list
              
              # Confirm deletion success
              shinyalert::shinyalert("Task Deleted", "The selected task has been deleted.", type = "success")
            } else {
              shinyalert::shinyalert("Error", "Task not found in the full list.", type = "error")
            }
          }
        }
      )
    } else {
      shinyalert::shinyalert("No Selection", "Please select a task to delete.", type = "warning")
    }
  })
  
  
  
  
  
  # Handle save tasks button click
  observeEvent(input$save_tasks, {
    write_xlsx(tasks(), path = excel_file)
    shinyalert("Tasks Saved", "Tasks have been saved to Excel.", type = "success")
  })
  
  # Download tasks as Excel file
  output$download_tasks <- downloadHandler(
    filename = function() {
      "task_list.xlsx"
    },
    content = function(file) {
      write_xlsx(tasks(), path = file)
    }
  )
  output$completed_tasks <- renderValueBox({
    filtered_tasks_df <- filtered_tasks()
    completed_tasks_count <- sum(filtered_tasks_df$status == "Completed")
    valueBox(completed_tasks_count, "Completed Tasks", icon = icon("check"), color = "green")
  })
  
  
  # Reactive expression to filter completed tasks
  completed_tasks <- reactive({
    filtered_tasks()[filtered_tasks()$status == "Completed", ]
  })
  
  # Render average days to complete value box
  output$avg_days_to_complete <- renderValueBox({
    filtered_tasks_df <- completed_tasks()
    if (nrow(filtered_tasks_df) > 0) {
      avg_days <- round(mean(filtered_tasks_df$days_to_complete, na.rm = TRUE), 0)
    } else {
      avg_days <- NA
    }
    valueBox(avg_days, "Avg Days to Complete Task", icon = icon("calendar"), color = "blue")
  })
  
  # Render average task efficiency value box
  output$avg_task_efficiency <- renderValueBox({
    filtered_tasks_df <- completed_tasks()
    if (nrow(filtered_tasks_df) > 0) {
      avg_efficiency <- round(mean(filtered_tasks_df$efficiency, na.rm = TRUE), 0)
    } else {
      avg_efficiency <- NA
    }
    valueBox(paste0(avg_efficiency, "%"), " Task Efficiency", icon = icon("line-chart"), color = "yellow")
  })
  
  output$total_tasks <- renderValueBox({
    search_name <- input$search_employee
    tasks_subset <- tasks()[grepl(search_name, tasks()$emp_name, ignore.case = TRUE), ]
    total <- nrow(tasks_subset)
    valueBox(total, "Total Tasks", icon = icon("tasks"), color = "purple")
  })
  
  output$pending_tasks <- renderValueBox({
    filtered_tasks_df <- filtered_tasks()
    pending_tasks_count <- sum(filtered_tasks_df$status == "Pending")
    valueBox(pending_tasks_count, "Pending Tasks", icon = icon("bell"), color = "red")
    
  })
  
  
  
  #############################################################GRAPH PLOTLY##############################################################  


  
  output$tasks_month_plot <- renderPlotly({
    tasks_data <- filtered_tasks()
    
    # Ensure the start_date column is in Date format
    tasks_data$start_date <- as.Date(tasks_data$start_date)
    
    # Generate a sequence of months covering the full range of dates
    all_months <- seq(min(tasks_data$start_date), max(tasks_data$start_date), by = "month")
    
    # Group tasks by month and count
    tasks_by_month <- tasks_data %>%
      mutate(month = floor_date(start_date, "month")) %>%
      group_by(month) %>%
      summarise(count = n(), .groups = 'drop') %>%
      complete(month = all_months, fill = list(count = 0))  # Ensure all months are included
    
    # Define a consistent color mapping for each month
    unique_months <- unique(tasks_by_month$month)
    colors <- c('#FF5733', '#33FF57', '#3357FF', '#FF33A1', '#F0FF33', '#FF8033', '#33F0FF', '#F033FF')
    color_mapping <- setNames(colors[1:length(unique_months)], unique_months)
    
    # Map colors to months
    tasks_by_month$color <- color_mapping[as.character(tasks_by_month$month)]
    
    # Define the y-axis scale
    y_ticks <- seq(0, ceiling(max(tasks_by_month$count)/2) * 2, by = 2)  # Generates ticks like 0, 2, 4, 6, 8
    
    # Plot using plotly
    plot_ly(tasks_by_month, x = ~month, y = ~count, type = "bar", text = ~count, textposition = 'auto',
            marker = list(color = ~color)) %>%
      layout(title = "Number of Tasks by Month",
             xaxis = list(title = "Month", type = 'date', 
                          tickformat = "%b %Y",  # Short month format
                          tickvals = as.Date(seq(min(tasks_by_month$month), max(tasks_by_month$month), by = "month")),
                          ticktext = format(as.Date(seq(min(tasks_by_month$month), max(tasks_by_month$month), by = "month")), "%b %Y")),
             yaxis = list(title = "Count",
                          tickmode = 'array',
                          tickvals = y_ticks,  # Set specific tick values
                          ticktext = as.character(y_ticks)))  # Labels for the ticks
  })
  
  
  
  ###############################################################################Graph################################################3
  
  # Reactive expression to filter completed tasks
  completed_tasks <- reactive({
    filtered_tasks()[filtered_tasks()$status == "Completed", ]
  })
  
  # Render average days to complete value box
  output$avg_days_to_complete <- renderValueBox({
    filtered_tasks_df <- completed_tasks()
    if (nrow(filtered_tasks_df) > 0) {
      avg_days <- round(mean(filtered_tasks_df$days_to_complete, na.rm = TRUE), 1)
    } else {
      avg_days <- NA
    }
    valueBox(avg_days, "Avg Days to Complete Task", icon = icon("calendar"), color = "blue")
  })
  
  # Render Plotly bar graph for average days to complete per month
  output$avg_days_to_complete_plot <- renderPlotly({
    filtered_tasks_df <- completed_tasks()
    if (nrow(filtered_tasks_df) > 0) {
      # Extract month names from start_date
      filtered_tasks_df$month <- format(as.Date(filtered_tasks_df$start_date), "%B")
      
      # Compute average days to complete per month
      avg_days_per_month <- aggregate(days_to_complete ~ month, data = filtered_tasks_df, FUN = mean)
      
      # Define bright colors for bars
      bright_colors <- c('#FF6347', '#4682B4', '#32CD32', '#FFD700', '#FF1493', '#00CED1', '#FF4500', '#DDA0DD', '#ADFF2F', '#FF69B4', '#7CFC00', '#8A2BE2')
      
      # Create the Plotly bar graph
      p <- plot_ly(avg_days_per_month, x = ~month, y = ~days_to_complete, type = 'bar', 
                   text = ~paste0(round(days_to_complete, 0), " days"), textposition = 'auto',
                   marker = list(color = bright_colors[1:length(avg_days_per_month$month)])) %>%
        layout(title = '',
               xaxis = list(title = 'Month'),
               yaxis = list(title = 'Average Days'),
               xaxis = list(tickvals = 1:12, ticktext = c('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December')),
               showlegend = FALSE)
      
      p
    } else {
      # Return empty plot if no data
      plot_ly() %>%
        layout(title = 'No data available',
               xaxis = list(title = 'Month'),
               yaxis = list(title = 'Average Days'))
    }
  })
  
  
########################################################################Number of task completed within 10 days
  
  # Reactive expression to filter completed tasks
  completed_tasks <- reactive({
    filtered_tasks()[filtered_tasks()$status == "Completed", ]
  })
  
  # Reactive expression to calculate the number of tasks completed within and beyond 10 days per month
  tasks_by_time <- reactive({
    completed_tasks() %>%
      mutate(days_to_complete = as.numeric(difftime(end_date, start_date, units = "days"))) %>%
      mutate(time_category = ifelse(days_to_complete <= 10, "Within 10 Days", "Beyond 10 Days")) %>%
      mutate(month = format(start_date, "%Y-%m")) %>%
      group_by(month, time_category) %>%
      summarise(task_count = n()) %>%
      ungroup()
  })
  
  # Render Plotly graph
  output$completion_plot <- renderPlotly({
    p <- ggplot(tasks_by_time(), aes(x = month, y = task_count, fill = time_category, label = task_count)) +
      geom_bar(stat = "identity", position = "dodge") +
      geom_text(position = position_dodge(width = 0.9), vjust = -0.9) +
      labs(x = "Month", y = "Number of Tasks", title = "", fill = "Completion Time") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  
  

 #########################################################################Number of Tasks Per Month################################################################
  # Render Plotly graph
  output$tasks_month_plot1 <- renderPlotly({
    tasks_data <- filtered_tasks()
    
    # Ensure the start_date column is in Date format
    tasks_data$start_date <- as.Date(tasks_data$start_date)
    
    # Generate a sequence of months covering the full range of dates
    all_months <- seq(min(tasks_data$start_date), max(tasks_data$start_date), by = "month")
    
    # Group tasks by month and status, and count
    tasks_by_month_status <- tasks_data %>%
      mutate(month = floor_date(start_date, "month")) %>%
      group_by(month, status) %>%
      summarise(count = n(), .groups = 'drop') %>%
      complete(month = all_months, status = c("Completed", "Pending"), fill = list(count = 0))  # Ensure all months and statuses are included
    
    # Define a consistent color mapping for each status
    status_colors <- c("Completed" = '#32CD32', "Pending" = '#FF5733')
    
    # Plot using plotly
    plot_ly(tasks_by_month_status, x = ~month, y = ~count, color = ~status, colors = status_colors, type = "bar",
            text = ~count, textposition = 'outside',
            textfont = list(color = 'black')) %>%
      layout(title = "",
             xaxis = list(title = "Month", type = 'date', 
                          tickformat = "%b %Y",  # Short month format
                          tickvals = as.Date(seq(min(tasks_by_month_status$month), max(tasks_by_month_status$month), by = "month")),
                          ticktext = format(as.Date(seq(min(tasks_by_month_status$month), max(tasks_by_month_status$month), by = "month")), "%b %Y")),
             yaxis = list(title = "Count",
                          tickmode = 'array',
                          tickvals = seq(0, ceiling(max(tasks_by_month_status$count)/2) * 2, by = 2),  # Adjust ticks as needed
                          ticktext = as.character(seq(0, ceiling(max(tasks_by_month_status$count)/2) * 2, by = 2))),
             barmode = 'group')  # Group bars by status
  })
  


  output$total_tasks <- renderValueBox({
    filtered_tasks_df <- filtered_tasks()
    total <- nrow(filtered_tasks_df)
    valueBox(total, "Total Tasks", icon = icon("tasks"), color = "purple")
  })
  
#####################################################Average Tasks Per Month####################################################33
  # Render value box for average tasks per month
  output$average_tasks <- renderValueBox({
    filtered_tasks_df <- filtered_tasks()
    
    if (nrow(filtered_tasks_df) == 0) {
      avg_tasks <- 0
    } else {
      tasks_by_month <- filtered_tasks_df %>%
        mutate(month = floor_date(start_date, "month")) %>%
        group_by(month) %>%
        summarise(count = n(), .groups = 'drop')
      
      avg_tasks <- mean(tasks_by_month$count)
    }
    
    valueBox(round(avg_tasks, 1), "Average Tasks per Month", icon = icon("calendar"), color = "blue")
  })
  
  
  
  
  
  
  output$pending_tasks_notification <- renderUI({
    pending_tasks_list <- tasks()[tasks()$status == "Pending", ]
    if (nrow(pending_tasks_list) > 0) {
      DTOutput("pending_tasks_table")
    } else {
      h4("No pending tasks")
    }
  })
  
  # Update the pending_tasks_table rendering
  output$pending_tasks_table <- renderDT({
    pending_tasks <- filtered_tasks()[filtered_tasks()$status == "Pending", ]
    datatable(pending_tasks[, c("emp_id", "emp_name", "task_desc", "start_date", "proposed_end_date")], options = list(scrollX = TRUE))
  })
  
  # Toggle notification box visibility
  observeEvent(input$toggle_notification, {
    show_notification(!show_notification())
  })
  
  # Show/hide notification box based on toggle state
  outputOptions(output, "pending_tasks_notification", suspendWhenHidden = FALSE)
  observe({
    toggle("pending_tasks_notification", condition = show_notification())
  })
}

# Run the application 
shinyApp(ui = ui, server = server)