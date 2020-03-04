#' diagnose_sample function
#'
#' @param data A list generated by the main function Rapid_aci_correction
#' @param sample_name sample_ID
#'
#' @return Several plots for diagnosing potential failures or problems
#' @export
#'
#' @note IN CONSTRUCTION

diagnose_sample <- function(data, sample_name) {

 data <- data[[sample_name]]
 delta_max <- data$delta_max
 priority_curve <- data$priority_curve
 
 theme_diagnose <- function () {
   theme_classic() %+replace%
     theme(
       plot.title = element_text(size = 20, face = "bold"),
       plot.subtitle = element_text(size = 16, color = "blue4"),
       legend.position = "none",
       axis.text = element_text(size=12),
       axis.title = element_text(size=16),
       plot.margin = unit(c(2.5 ,2.5 ,2.5, 2.5), "cm")
     )
 }

 empty1 <-     
    ggplot(data$empty_chamber_data, aes(x = n, y= delta, color = good)) + 
      geom_point() +
      geom_hline(aes(yintercept = -delta_max)) + 
      geom_hline(aes(yintercept =  delta_max)) +
      labs(title = paste("Retained datapoints (blue) (delta_max =", delta_max, ")"),
           subtitle = "Empty chamber",
           y = "delta A", x = "Measurements") +
      theme_diagnose()
    
 empty2 <-
    ggplot(data$empty_chamber_data, aes(x = Meas_CO2_r, y = GasEx_A, color = good)) + 
      geom_point() +
      labs(title = paste("Stable section(s) of the curve (in blue)"),
           subtitle = "Empty chamber") +
      ylab(paste0("A (", expression("\u03BC"), "mol / m", expression("\U00B2"), "/ s)")) +
      xlab(paste0("CO2 reference (", expression("\u03BC"), "mol / m", expression("\U00B2"), "/ s)")) +
      theme_diagnose()
 
 n <- sum(results[["demo"]]$empty_chamber_data$curve == "negative")
 p <- sum(results[["demo"]]$empty_chamber_data$curve == "positive")
 if(priority_curve == "negative") n <- 9999
 if(n > p) curve_coefs <- data$negCurve_coefs else curve_coefs <- data$posCurve_coefs
 curv <- ifelse(n > p, "negative", "positive")
 deg <- length(curve_coefs)
 
 if(deg > 0){
   if(deg==2){oi<-"st"}else if(deg==3){oi<-"nd"}else if(deg==4){oi<-"rd"}else{oi<-"th"}
   empty3 <-
     ggplot(dplyr::filter(data$empty_chamber_data, good == 1, curve == curv), aes(x = Meas_CO2_r, y = GasEx_A)) +
     geom_point() +
     geom_smooth(method='lm', formula = y~x + poly(x, deg - 1), color = "green2", se = FALSE) +
     labs(title = paste0("Best fitting polynomial curve (", paste0(deg-1, oi, " degree)")),
          subtitle = "Empty chamber") +
     ylab(paste0("A (", expression("\u03BC"), "mol / m", expression("\U00B2"), "/ s)")) +
     xlab(paste0("CO2 reference (", expression("\u03BC"), "mol / m", expression("\U00B2"), "/ s)")) +
     theme_diagnose()
 } else {
   empty3 <- NA
 }

    corr1 <- 
    ggplot(data = cbind("Aleaf" = data$Aleaf[[1]], "GasEx_A" = data$ACi_data$GasEx_A, 
                 "Ci_corrected" = data$Ci_corrected[[1]], "GasEx_Ci" = data$ACi_data$GasEx_Ci) %>% 
           as_tibble()) + 
      geom_point(aes(Ci_corrected, Aleaf), color = "blue") + 
      geom_point(aes(GasEx_Ci, GasEx_A), color = "red") +
      labs(title = "Raw (RED) vs Corrected (BLUE) A - Ci measurements", subtitle = sample_name) +
      xlab("Ci (ppm)") + ylab(paste0("A (", expression("\u03BC"), "mol / m", expression("\U00B2"), "/ s)")) +
      theme_diagnose()
    
    raci1 <-
    ggplot(data$Raci, aes(Ci, Photo)) + 
      geom_point() +
      labs(title = "Portion passed to plantecophys", subtitle = sample_name) + 
      xlab("Ci (ppm)") + ylab(paste0("A (", expression("\u03BC"), "mol / m", expression("\U00B2"), "/ s)")) +
      theme_diagnose()


  dir.create(file.path("diagnosefigure"), showWarnings = FALSE)  
  
  png(paste0("figure/", sample_name, ".png"), height = 1500, width = 2000)
  suppressWarnings(
    gridExtra::grid.arrange(empty1, empty2, empty3, corr1, raci1,
                            layout_matrix = rbind(c(1,1,2,2,3,3), c(4,4,4,5,5,5)))
  )
  dev.off()
  
}  
