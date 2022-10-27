#' @title results extraction
#' @description This function extracts estimation results.
#' @param x returned object
#' @param pars Names of extracted parameters. They can be "theta" (person trait estimates), "alpha" (statement discrimination parameters), "delta" (statement location parameters), "tau" (statement threshold parameters), data" (gtum.Data), "fit" (the stanfit object), "ind" (the input two-column matrix mapping each statement to each trait), and "ParInits" (A two-column matrix specifying the directions or positivity/negativity of the statements).
#' @return Selected results output
#' @examples
#' \donttest{
#' Data <- c(1,5)
#' Data <- matrix(Data,nrow = 1)
#' ind <- matrix(c(1, 1, 2, 3), ncol = 2)
#' ParInits <- matrix(c(-1, -1, -1, -1), ncol = 2)
#' mod <- gtum(gtum.Data=Data,ind=ind,ParInits=ParInits,block=2,iter=3,warmup=1,chains=1)
#' alpha <- extract(mod, 'alpha')}
#' @export
extract <- function(x, pars){
  UseMethod("extract")
}


#' @export
#' @method extract gtum
extract.gtum <- function(x, pars){

  ret <- switch(pars,
                theta=x[["Theta.est"]],
                alpha=as.matrix(x[["Alpha.est"]]),
                delta=x[["Delta.est"]],
                tau=x[["Tau.est"]],
                cor=x[["Cor.est"]],
                #lambda=x[["Lamda.est"]],
                data=x[["Data"]],
                fit=x[["Fit"]],
                ind=x[["ind"]],
                ParInits=x[["ParInits"]])

  ret
}
