#' @title Generalized Thurstonian Unfolding Model estimation
#' @description This function implements full Bayesian estimation of the Generalized Thurstonian Unfolding Model using rstan
#' @param gtum.Data Response data in wide format. For dichotomous forced choice data, if the first statement is preferred, the data should be coded as 1, otherwise it should be coded as 2. For polytomous forced choice data, the data should be coded as the response option endorsed.
#' @param ind A two-column matrix mapping each statement to each trait. For example, matrix(c(1, 1, 1, 2, 2, 2), ncol = 2) means that for each pair, the first statement measures trait 1 and the second statement measures trait 2.
#' @param ParInits A two-column or three column (depending on the block size) matrix specifying the directions or positivity/negativity of the statements in each pair. 1 means the statement is positive, -1 means the statement is negative, and 0 means the statement is neutral(intermediate items). For example, matrix(c(1, 1, 1, -1, -1, -1), ncol = 2) means that for each pair, the first statement is positive and the second statement is negative.
#' @param block The number of statements in each block in the original test. For now, it can be 2 or 3. We will further expand the code to incorporate bigger blocks.
#' @param pairmap A two-column matrix specifying the rank/ID of the statement in each trait it measures. For example, suppose there are 3 statements measuring each trait. 1 means the statement is the first statement measuring the trait and 3 means the statement is the last statement measuring the trait.
#' @param covariate An p*c person covariate matrix where p equals sample size and c equals the number of covariates. The default is NULL, meaning no person covariate.
#' @param iter The number of iterations. The default value is 2000. See documentation for rstan for more details.
#' @param chains The number of chains. The default value is 2. See documentation for rstan for more details.
#' @param warmup The number of warmups to discard. The default value is 0.5*iterations. See documentation for rstan for more details.
#' @param adapt_delta Target average proposal acceptance probability during Stan's adaptation period. The default value is 0.85. See documentation for rstan for more details.
#' @param thin Thinning. The default value is 1. See documentation for rstan for more details.
#' @param cores The number of computer cores used for parallel computing. The default value is 2.
#' @param ma Mean of the prior distribution for alphas for block of 2 in the original test, which follows a lognormal distribution. The default value is 0.2.
#' @param va Standard deviation of the prior distribution for alpha for block of 2 in the original test. The default value is 0.5.
#' @param mt Means of the prior distributions for taus for block of 2 in the original test, which follows a normal distribution. The default values is 0.
#' @param vt Standard deviation of the prior distribution for taus for block of 2 in the original test. The default value is 2.
#' @param ma_t Mean of the prior distribution for alphas for block of 3 in the original test, which follows a lognormal distribution. The default value is 0.2.
#' @param va_t Standard deviation of the prior distribution for alpha for block of 3 in the original test. The default value is 1.
#' @param mt_t Means of the prior distributions for taus for block of 3 in the original test, which follows a normal distribution. The default values is 0.
#' @param vt_t Standard deviation of the prior distribution for taus for block of 3 in the original test. The default value is 3.
#' @param mdne Mean of the prior distribution for negative deltas for block of 2/3 in the original test, which follows a normal distribution. The default value is 0.7.
#' @param vdne Standard deviation of the prior distribution for negative deltas for block of 2/3 in the original test. The default value is 0.2.
#' @param mdnu Mean of the prior distribution for neutral deltas for block of 2/3 in the original test, which follows a normal distribution. The default value is 0.5.
#' @param vdnu Standard deviation of the prior distribution for neutral deltas for block of 2/3 in the original test. The default value is 0.1.
#' @param mdpo Mean of the prior distribution for positive deltas for block of 2/3 in the original test, which follows a normal distribution. The default value is 0.3.
#' @param vdpo Standard deviation of the prior distribution for positive deltas for block of 2/3 in the original test. The default value is 0.2.
#' @return Result object that stores information including the (1) stanfit object, (2) estimated item parameters, (3) estimated person parameters, (4) response data, and (5) the input column vector mapping each statement to each trait.
#' @examples
#' \donttest{
#' Data <- c(1,5)
#' Data <- matrix(Data,nrow = 1)
#' ind <- matrix(c(1, 1, 2, 3), ncol = 2)
#' ParInits <- matrix(c(-1, -1, -1, -1), ncol = 2)
#' mod <- gtum(gtum.Data=Data,ind=ind,ParInits=ParInits,block=2,iter=3,warmup=1,chains=1)}
#' @export
gtum <- function(gtum.Data, ind, ParInits, block, pairmap=NULL, covariate=NULL, iter=2000, chains=2,
                 warmup=floor(iter/2), adapt_delta=0.85, thin=1, cores=2,
                 ma=0.2, va=0.5, mt=0, vt=2,
                 ma_t=0.2, va_t=1, mt_t=0, vt_t=3,
                 mdne=0.7, vdne=0.2, mdnu=0.5, vdnu=0.1, mdpo=0.3, vdpo=0.2){
  if (block==2){
    ind1 <- ind
    ind <- c(t(ind))

    if (is.null(covariate)){

      N1 <- nrow(gtum.Data)

      Missing <- matrix(NA,nrow=(ncol(gtum.Data))*N1,ncol=1)
      MissPattern<-data.frame(Missing=((as.numeric(is.na(t(gtum.Data)))*-1)+1),ID=seq(1,((ncol(gtum.Data))*N1),1))
      Miss<-subset(MissPattern,Missing==0)
      if (nrow(Miss)==0){
        ind<-rep(ind,N1)
      }else{
        ind<-rep(ind,N1)[-c(Miss$ID*2-1, Miss$ID*2)]
      }

      Data<-suppressWarnings(edstan::irt_data(response_matrix =gtum.Data))

      Delta.Ind.0 <- c(ParInits[,1],ParInits[,2])   #Statements in pair format are estimated column by column
      Delta.Ind <- Delta.upper <- Delta.lower <- Delta.Std<- numeric(Data$I*2)

      #initial values
      for (i in 1:(Data$I*2)) {
        if(Delta.Ind.0[i] > 0) {
          Delta.Ind[i]=mdpo
          Delta.Std[i]=vdpo
          Delta.lower[i]=0
          Delta.upper[i]=10}
        else if(Delta.Ind.0[i] < 0) {
          Delta.Ind[i]=mdne
          Delta.Std[i]=vdne
          Delta.lower[i]=-10
          Delta.upper[i]=0}
        else{
          Delta.Ind[i]=mdnu
          Delta.Std[i]=vdnu
          Delta.lower[i]=-10
          Delta.upper[i]=10}
      }


      init <- list(list(alpha=rep(1,Data$I*2),delta_raw=Delta.Ind),
                   list(alpha=rep(1,Data$I*2),delta_raw=Delta.Ind))

      Stan.data <- list(y = Data$y,
                        Categ = max(Data$y),
                        Items = Data$I,
                        Subjt = Data$J,
                        N=Data$N,
                        N_mis=(Data$I*Data$J-Data$N),
                        II=Data$ii,
                        JJ=Data$jj,
                        Trait = max(ind),
                        INDEX  = c(ind1),
                        Delta_lower = Delta.lower,
                        Delta_upper = Delta.upper,
                        Delta_Ind = Delta.Ind,
                        Delta_Std = Delta.Std,
                        Theta_mu=rep(0,max(ind)),
                        ma=ma,
                        va=va,
                        mt=mt,
                        vt=vt)


      ##################################################
      #       Input response data estimation        #
      ##################################################

      rstan::rstan_options(auto_write = TRUE)

      Categ = max(Data$y)

      if(Categ == 2){
        gtum <- rstan::sampling(stanmodels$GTUMdicho_pair,data=Stan.data,
                                iter=iter, chains=chains,cores=cores, warmup=warmup,
                                init=init, thin=thin,
                                control=list(adapt_delta=0.85))
      }

      if (Categ > 2){
        gtum <- rstan::sampling(stanmodels$GTUMpoly_pair,data=Stan.data,
                                iter=iter, chains=chains,cores=cores, warmup=warmup,
                                init=init, thin=thin,
                                control=list(adapt_delta=0.85))
      }

      #####Extract some parameters
      THETA<-rstan::summary(gtum, pars = c("theta"), probs = c(0.05,0.5, 0.95))$summary
      Alpha_ES<-rstan::summary(gtum, pars = c("alpha"), probs = c(0.05,0.5, 0.95))$summary
      Delta_ES<-rstan::summary(gtum, pars = c("delta"), probs = c(0.05,0.5, 0.95))$summary
      Tau_ES<-rstan::summary(gtum, pars = c("tau"), probs = c(0.05,0.5, 0.95))$summary
      Cor_ES<-rstan::summary(gtum, pars = c("Cor"), probs = c(0.05,0.5, 0.95))$summary

      #####save estimated parameters to an R object
      gtum.summary<-list(Theta.est=THETA,
                         Alpha.est=Alpha_ES,
                         Delta.est=Delta_ES,
                         Tau.est=Tau_ES,
                         Cor.est=Cor_ES,
                         Data=Stan.data,
                         Fit=gtum,
                         ind=ind,
                         ParInits=ParInits)
    }

  }
  if (block==3){
    ind1 <- ind
    ind <- c(t(ind))

    if (is.null(covariate)){

      N1 <- nrow(gtum.Data)

      Missing <- matrix(NA,nrow=(ncol(gtum.Data))*N1,ncol=1)
      MissPattern<-data.frame(Missing=((as.numeric(is.na(t(gtum.Data)))*-1)+1),ID=seq(1,((ncol(gtum.Data))*N1),1))
      Miss<-subset(MissPattern,Missing==0)
      if (nrow(Miss)==0){
        ind<-rep(ind,N1)
      }else{
        ind<-rep(ind,N1)[-c(Miss$ID*2-1, Miss$ID*2)]
      }

      Data<-suppressWarnings(edstan::irt_data(response_matrix =gtum.Data))

      Delta.Ind.0 <- as.matrix(c(t(ParInits)))    #Statements in triplet format are estimated row by row

      Delta.Ind <- Delta.upper <- Delta.lower <- Delta.Std<- numeric(Data$I)

      #initial values
      for (i in 1:(Data$I)) {
        if(Delta.Ind.0[i] > 0) {
          Delta.Ind[i]=mdpo
          Delta.Std[i]=vdpo
          Delta.lower[i]=0
          Delta.upper[i]=10}
        else if(Delta.Ind.0[i] < 0) {
          Delta.Ind[i]=mdne
          Delta.Std[i]=vdne
          Delta.lower[i]=-10
          Delta.upper[i]=0}
        else{
          Delta.Ind[i]=mdnu
          Delta.Std[i]=vdnu
          Delta.lower[i]=-10
          Delta.upper[i]=10}
      }


      init <- list(list(alpha_raw=rep(1.00,Data$I),delta_1=Delta.Ind),
                   list(alpha_raw=rep(1.50,Data$I),delta_1=Delta.Ind))

      Stan.data <- list(y = Data$y,
                        Categ = max(Data$y),
                        Items = Data$I,
                        Subjt = Data$J,
                        N=Data$N,
                        N_mis=(Data$I*Data$J-Data$N),
                        II=Data$ii,
                        JJ=Data$jj,
                        Trait = max(ind),
                        Delta_lower = Delta.lower,
                        Delta_upper = Delta.upper,
                        Delta_Ind = Delta.Ind,
                        Delta_Std = Delta.Std,
                        Theta_mu=rep(0,max(ind)),
                        ma=ma_t,
                        va=va_t,
                        mt=mt_t,
                        vt=vt_t,
                        Block = block,
                        Dime_Ind = c(ind1[,1], ind1[,2]),
                        Item_Ind = c(pairmap[,1], pairmap[,2]),
                        Randomblock_mean = rep(0,block))

      ##################################################
      #       Input response data estimation        #
      ##################################################

      rstan::rstan_options(auto_write = TRUE)

      Categ = max(Data$y)

      if(Categ == 2){
        gtum <- rstan::sampling(stanmodels$GTUMdicho_triplet,data=Stan.data,
                                iter=iter, chains=chains,cores=cores, warmup=warmup,
                                init=init, thin=thin,
                                control=list(adapt_delta=0.85))
      }

      if (Categ > 2){
        gtum <- rstan::sampling(stanmodels$GTUMpoly_triplet,data=Stan.data,
                                iter=iter, chains=chains,cores=cores, warmup=warmup,
                                init=init, thin=thin,
                                control=list(adapt_delta=0.85))
      }

      #####Extract some parameters
      THETA<-rstan::summary(gtum, pars = c("theta"), probs = c(0.05,0.5, 0.95))$summary
      Alpha_ES<-rstan::summary(gtum, pars = c("alpha"), probs = c(0.05,0.5, 0.95))$summary
      Delta_ES<-rstan::summary(gtum, pars = c("delta"), probs = c(0.05,0.5, 0.95))$summary
      Tau_ES<-rstan::summary(gtum, pars = c("tau"), probs = c(0.05,0.5, 0.95))$summary
      Cor_ES<-rstan::summary(gtum, pars = c("Cor"), probs = c(0.05,0.5, 0.95))$summary
      Randomblock_var <- rstan::summary(gtum, pars = c("randomblock_var"), probs = c(0.05,0.5, 0.95))$summary

      #####save estimated parameters to an R object
      gtum.summary<-list(Theta.est=THETA,
                         Alpha.est=Alpha_ES,
                         Delta.est=Delta_ES,
                         Tau.est=Tau_ES,
                         Cor.est=Cor_ES,
                         Randomblock_sd.est = Randomblock_var,
                         Data=Stan.data,
                         Fit=gtum,
                         ind=ind,
                         ParInits=ParInits)
    }
  }
  class(gtum.summary) <- "gtum"
  return(gtum.summary)
}
