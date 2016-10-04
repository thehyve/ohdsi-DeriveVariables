#' Prints statistics of a continuous variable
printContinuousDescriptives <- function(x, name = "", ignore_na = TRUE){
  # Number of variables (that are not na)
  n <- sum(!is.na(x))

  # Calculate metrics.
  mean <- mean(x, na.rm = ignore_na)
  sd <- sd(x, na.rm = ignore_na)
  # Quartiles:
  quartiles <- quantile( x, c(0.25,0.5,0.75), na.rm = ignore_na )

  printf( "##%s  n=%d##", name, n)
  printf( "Mean ± s.d. = %.2f ± %.2f", mean, sd  )
  printf( "Median      = %.0f", quartiles[[2]] )
  printf( "IQR         = %.0f-%.0f", quartiles[[1]], quartiles[[3]] )
}

#' Calculate and print survival statistics, comparing two groups
#' All three variables should have the same size
#' @param days_at_risk   Number of days to event, end of study or other censoring
#' @param censor         1 if event happened, 0 if event did not happen.
#' @param grouping       factor with the group to which the data belongs
#' @param kaplan_ymin    optional. controls the y axis of the kaplan meijer curve.
printSurvivalStatistics <- function(days_at_risk, censor, grouping, kaplan_ymin = FALSE){
  library(survival)

  # Percentage contigency table
  event_string <- as.factor( censor )
  levels( event_string ) <- list('Event'=0, 'No event'=1)
  print("Percentage occurrence of event:")
  cont_table <- table(event_string, grouping)
  cont_table_perc <- prop.table( cont_table, margin=2 ) * 100
  print( cont_table_perc )

  # Groups (assume there are 2)
  groups <- levels(grouping)
  group1  <- data.frame(days   = days_at_risk[ grouping == groups[1] ],
                        censor = censor[ grouping == groups[1] ])
  group2  <- data.frame(days   = days_at_risk[ grouping == groups[2] ],
                        censor = censor[ grouping == groups[2] ])

  # Rate group 1
  n_events1 <- sum(group1$censor == 1)
  total_risk_time1 <- sum(group1$days)
  annual_rate1 <- n_events1/total_risk_time1 *365.25 * 100
  #time1 <- max(group1$days) - min(group1$days)
  # Rate group 2
  n_events2 <- sum(group2$censor == 1)
  total_risk_time2 <- sum(group2$days)
  annual_rate2 <- n_events2/total_risk_time2 *365.25 * 100

  printf("'%s' - number of events: %d", groups[1], n_events1)
  printf("'%s' - event rate per 100 years at risk: %.3f", groups[1], annual_rate1)
  printf("'%s' - number of events: %d", groups[2], n_events2)
  printf("'%s' - event rate per 100 years at risk: %.3f", groups[2], annual_rate2)

  # Apply Proportional Hazards Regression Model
  # Censor = 0 if event did not happen, censor = 1 if event happened
  survival.object <- Surv(days_at_risk, censor)
  ph.model <- coxph(survival.object ~ grouping)
  ph.summary <- summary(ph.model)

  # Report Hazard Ratio
  printf( "Hazard Ratio: %.3f", ph.summary$conf.int[1] )
  printf( "Hazard Ratio 95%% CI: %.3f to %.3f", ph.summary$conf.int[3], ph.summary$conf.int[4] )

  # Kaplan Meier
  # Create a survival fit
  sfit <- survfit(survival.object ~ grouping)
  # Only show the upper y-range, depending on minimal survival rate
  if (kaplan_ymin){
    ymin <- kaplan_ymin
  } else {
    ymin <- round( min(sfit$surv) - (1-min(sfit$surv))*0.20, 2 )
  }

  # Plot and add legend
  plot(sfit, mark.time=F, col=c(1,2), lty=1, lwd=2,
       xscale=365.25, xlab="Years from Index date", ymin = ymin,
       ylab="Survival")
  legend("bottomleft", groups, col = c(1,2), pch = c(20,20) )

  return(ph.summary)
}
