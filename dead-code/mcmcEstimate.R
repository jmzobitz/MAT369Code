#' Markov Chain parameter estimates
#'
#' \code{mcmcEstimate} Computes and Markov Chain Monte Carlo parameter estimate for a given model
#'

#' @param obs_data the data we need in order to solve optimize our cost function.
#' @param indep_var the independent variable we are using to organize the code
#' @param parameters an initial guess for our parameters
#' @param iterations the number of iterations we wish to run the MCMC for.
#' @param lower_bound the lower bound values for our parameters
#' @param upper_bound the upper bound values for our parameters
#' @param burn_percent the percentage of the iterations we discard due to "burn-in". This should be a number between 0 and 1
#' @return A output of the accepted parameter histograms, model output (with uncertainty) + data utilized, and a listing of the accepted parameters.
#' @examples
#' # Run the vignette that works through an example.
#' vignette("mcmc")
#'
#' @import FME
#' @import GGally
#' @import tidyr
#' @import stringr
#' @import deSolve
#' @import ggplot2
#' @export




mcmcEstimate <- function(obs_data,indep_var,parameters,lower_bound,upper_bound,iterations = 1500,burn_percent=0.2) {

  # cost function
  cost <- function(p){
    out = solveModel(p)
    modCost_JZ(out, obs_data,x=indep_var)
  }

  burninlength = floor(burn_percent*iterations)


  # do MCMC
  fit = modMCMC(f = cost, p = parameters, niter=iterations, burninlength=burninlength, lower = lower_bound, upper = upper_bound, verbose = TRUE)

  # view results
  ### Can we save this to a file?  make a directory in the folder?
  print(summary(fit))

  print("The best parameter value:")
  print(fit$bestpar)


  print("The 95% confidence intervals:")
  print(apply(fit$pars,FUN=quantile,MARGIN = 2,c(0.025,0.50,0.975)))

  out = solveModel(fit$bestpar)
  outVal <- modCost_JZ(out, obs_data,x=indep_var)

  print("The log likelihood:")
  print(outVal$minlogp)

  # Make a correlation plot uses ggpairs

  ggpairs(data.frame(fit$pars), diag = list(continuous ="barDiag", discrete = "barDiag", na = "naDiag")) %>% print()


  # Generate a summary of the model and the data - with confidence intervals
  sR <- sensRange(func = solveModel,parms=parameters,parInput=fit$pars) %>%
    summary() %>% rename(time=x)

  vars<- row.names(sR) %>% str_extract_all(paste(names(obs_data), collapse="|")) %>% unlist()

  plotData <- sR %>% mutate(vars)

  ### Now let's do the ribbon w/ the data - yay!
  measuredData <- obs_data %>% gather(key=vars,value=measurement,-1)
  ggplot(plotData)+
    geom_line(aes(x=time,y=q50)) +
    geom_ribbon(aes(x=time,ymin=q05,ymax=q95),alpha=0.3) +
    geom_point(data=measuredData,aes(x=measuredData[[1]],y=measurement),color="red",size=2) +
    facet_grid(vars~.,scales="free") + labs(y="") %>% print()







}

