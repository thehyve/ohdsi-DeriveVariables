##### Statistical wrappers ######

# Simple wrapper for easy formatted printing to screen. outer invisible may be unnecessary (http://stackoverflow.com/questions/13023274/how-to-do-printf-in-r)
printf <- function(...) invisible(print(sprintf(...)))

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

## Calculate and print survival statistics, comparing two groups
## All three variables should have the same size
printSurvivalStatistics <- function(days_at_risk, censor, grouping, kaplan_ymin = FALSE){
  library(survival)

  # Percentage contigency table
  print("Percentage hazard:")
  cont_table <- table(censor, grouping)
  cont_table_perc <- prop.table( cont_table, margin=2 ) * 100
  print( cont_table_perc )

  # Groups (assume there are 2)
  groups <- levels(grouping)
  group1  <- data.frame(days   = days_at_risk[ grouping == groups[1] ],
                        censor = censor[ grouping == groups[1] ])
  group2  <- data.frame(days   = days_at_risk[ grouping == groups[2] ],
                        censor = censor[ grouping == groups[2] ])

  # Annual rate group 1
  n_deaths1 <- sum(group1$censor == 1)
  time1 <- max(group1$days) - min(group1$days)
  rate1 <- n_deaths1/time1 * 365.25
  printf("'%s' annual death rate: %.3f", groups[1], rate1)

  # Annual rate group 2
  n_deaths2 <- sum(group2$censor == 1)
  time2 <- max(group2$days) - min(group2$days)
  rate2 <- n_deaths2/time2 * 365.25
  printf("'%s' annual death rate: %.3f", groups[2], rate2)

  # Apply Proportional Hazards Regression Model
  # Calculate and report Hazard Ratio
  survival.object <- Surv(days_at_risk,censor)
  ph.model <- coxph(survival.object ~ grouping)
  ph.summary <- summary(ph.model)

  printf( "Hazard Ratio 95%% CI: %.2f to %.2f", ph.summary$conf.int[3], ph.summary$conf.int[4] )

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
