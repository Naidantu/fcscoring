#' @title bayesian convergence diagnosis plotting function
#' @description This function provides plots including density plots, trace plots, and auto-correlation plots to aid model convergence diagnosis.
#' @param x returned object
#' @param pars Names of plotted parameters. They can be "theta", "alpha", "delta", "tau", or a subset of parameters.
#' @param plot Types of plots.They can be "density", "trace", or "autocorrelation".
#' @param inc_warmup Whether to include warmup iterations or not when plotting. The default is FALSE.
#' @return Selected plots for selected parameters
#' @examples
#' \donttest{
#' Data <- c(1,5)
#' Data <- matrix(Data,nrow = 1)
#' ind <- matrix(c(1, 1, 2, 3), ncol = 2)
#' ParInits <- matrix(c(1, 1, 1, 1, -1, -1, -1, -1), ncol = 2)
#' mod <- gtum(gtum.Data=Data,ind=ind,ParInits=ParInits,block=2,iter=3,warmup=1,chains=1)
#' bayesplot(mod, 'alpha', 'density', inc_warmup=FALSE)}
#' @export
bayesplot <- function(x, pars, plot, inc_warmup=FALSE){
  UseMethod("bayesplot")
}


#' @export
#' @method bayesplot gtum
bayesplot.gtum <- function(x, pars, plot, inc_warmup=FALSE){

  x <- extract(x, 'fit')
  if (plot=="trace"){

    ret <- rstan::stan_trace(x, pars, inc_warmup = inc_warmup)

  }
  if (plot=="density"){

    ret <- rstan::stan_dens(x, pars, inc_warmup = inc_warmup)

  }
  if (plot=="autocorrelation"){

    ret <- rstan::stan_ac(x, pars, inc_warmup = inc_warmup)

  }
  ret
}
