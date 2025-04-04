library(shiny)  # Framework for building interactive web applications in R
library(ggplot2)  # For data visualization
library(dplyr)  # For data manipulation
library(lubridate)  # For working with date objects

expenses_file <- "expenses.csv"
income_file <- "income.csv"
goals_file <- "savings_goals.csv"

load_data <- function(file, default_data) {
  if (file.exists(file)) {
    read.csv(file, stringsAsFactors = FALSE) %>%
      mutate(Data = as.Date(Data))  # Convert date column to Date format
  } else {
    default_data
  }
}

# UI (User Interface) of the application
ui <- fluidPage(
  titlePanel("Home Budget - Financial Management"),
  
  sidebarLayout(
    sidebarPanel(
      h3("Add Income"),
      numericInput("income_amount", "Amount (PLN):", value = 0, min = 0),
      dateInput("income_date", "Income Date:", value = Sys.Date()),
      actionButton("add_income", "Add Income"),
      br(),
      
      h3("Add Expense"),
      selectInput("category", "Expense Category:",
                  choices = c("Bills", "Food", "Childcare", "Transport", "Entertainment", "Pet")),
      numericInput("amount", "Amount (PLN):", value = 0, min = 0),
      dateInput("date", "Expense Date:", value = Sys.Date()),
      actionButton("add", "Add Expense"),
      br(),
      
      h3("Add Savings Goal"),
      textInput("goal_name", "Goal Name:", ""),
      numericInput("goal_amount", "Amount to Save (PLN):", value = 0, min = 0),
      actionButton("add_goal", "Add Goal"),
      br(),
      
      actionButton("reset", "Reset Data")
    ),
    
    mainPanel(
      h4("Total Income (PLN):"),
      verbatimTextOutput("totalIncome"),
      h4("Total Expenses (PLN):"),
      verbatimTextOutput("totalExpenses"),
      h4("Savings (PLN):"),
      verbatimTextOutput("savings"),
      h4("Daily Expense Chart:"),
      plotOutput("dailyPlot"),
      h4("Expense Breakdown by Category:"),
      plotOutput("categoryPlot"),
      h4("Savings Goals List:"),
      tableOutput("goalsTable")
    )
  )
)

server <- function(input, output, session) {
  
  # Reactive variables to store financial data
  expenses_data <- reactiveVal(load_data(expenses_file, data.frame(
    Data = as.Date(character()),
    Kategoria = character(),
    Kwota = numeric(),
    stringsAsFactors = FALSE
  )))
  
  income_data <- reactiveVal(load_data(income_file, data.frame(
    Data = as.Date(character()),
    Kwota = numeric(),
    stringsAsFactors = FALSE
  )))
  
  savings_goals <- reactiveVal(load_data(goals_file, data.frame(
    Cel = character(),
    Kwota = numeric(),
    Osiągnięto = numeric(),
    stringsAsFactors = FALSE
  )))
  
  # Function to save data back to CSV files
  save_data <- function(data, file) {
    write.csv(data, file, row.names = FALSE)
  }

  # Event listener for adding income
  observeEvent(input$add_income, {
    if (input$income_amount > 0) {
      new_income <- data.frame(Data = input$income_date, Kwota = input$income_amount, stringsAsFactors = FALSE)
      updated_income <- rbind(income_data(), new_income)
      income_data(updated_income)
      save_data(updated_income, income_file)
    } else {
      showNotification("Income amount must be greater than 0.", type = "error")
    }
  })
  
  # Event listener for adding an expense
  observeEvent(input$add, {
    if (input$amount > 0) {
      new_expense <- data.frame(Data = input$date, Kategoria = input$category, Kwota = input$amount, stringsAsFactors = FALSE)
      updated_expenses <- rbind(expenses_data(), new_expense)
      expenses_data(updated_expenses)
      save_data(updated_expenses, expenses_file)
    } else {
      showNotification("Expense amount must be greater than 0.", type = "error")
    }
  })

  # Event listener for adding a savings goal
  observeEvent(input$add_goal, {
    if (input$goal_amount > 0 & input$goal_name != "") {
      new_goal <- data.frame(Cel = input$goal_name, Kwota = input$goal_amount, Osiągnięto = 0, stringsAsFactors = FALSE)
      updated_goals <- rbind(savings_goals(), new_goal)
      savings_goals(updated_goals)
      save_data(updated_goals, goals_file)
    } else {
      showNotification("Please enter a valid name and amount for the goal!", type = "error")
    }
  })

  # Reset all stored data
  observeEvent(input$reset, {
    expenses_data(data.frame(Data = as.Date(character()), Kategoria = character(), Kwota = numeric(), stringsAsFactors = FALSE))
    income_data(data.frame(Data = as.Date(character()), Kwota = numeric(), stringsAsFactors = FALSE))
    savings_goals(data.frame(Cel = character(), Kwota = numeric(), Osiągnięto = numeric(), stringsAsFactors = FALSE))
    
    save_data(expenses_data(), expenses_file)
    save_data(income_data(), income_file)
    save_data(savings_goals(), goals_file)
  })
  
  # Calculate total income, expenses, and savings
  output$totalIncome <- renderText({ paste("Total Income:", sum(income_data()$Kwota, na.rm = TRUE), "PLN") })
  output$totalExpenses <- renderText({ paste("Total Expenses:", sum(expenses_data()$Kwota, na.rm = TRUE), "PLN") })
  output$savings <- renderText({ paste("Savings:", sum(income_data()$Kwota, na.rm = TRUE) - sum(expenses_data()$Kwota, na.rm = TRUE), "PLN") })
  
  output$dailyPlot <- renderPlot({
    if (nrow(expenses_data()) == 0) return(NULL)
    ggplot(expenses_data() %>% group_by(Data) %>% summarize(Suma = sum(Kwota)), aes(x = Data, y = Suma)) +
      geom_bar(stat = "identity", fill = "#3498db") +
      theme_minimal() +
      labs(title = "Daily Expense Distribution", x = "Date", y = "Amount (PLN)")
  })
}

# Run the Shiny application
shinyApp(ui, server)
