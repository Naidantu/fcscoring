#' @title Generalized Thurstonian Unfolding Model estimation
#' @description This function implements full Bayesian estimation of the Generalized Thurstonian Unfolding Model using rstan
#' @param gtum.Data Response data in wide format (each row represents a person). If the original block size is three or more, then users need to first decompose the original responses into several pairwise comparisons and use the pairwise comparison data as input here. For example, if the original test has 3 blocks and each block contains statements A, B, and C, then the input data should have 9 columns (A1B1, A1C1, B1C1, A2B2, A2C2, B2C2, A3B3, A3C3, B3C3) where 1 means the first statement within the pair is preferred and 2 means the second statement within the pair is preferred. For graded preference forced-choice design, the data should be coded as the response option endorsed (e.g., 1= Statement A is much more like me; 2= Statement A is slightly more like me; 3= Statement B is slightly more like me; 4= Statement B is much more like me).
#' @param ind A two-column matrix mapping each statement to each trait in the pair format. For example, matrix(c(1, 1, 1, 2, 2, 2), ncol = 2) means that for each pair, the first statement measures trait 1 and the second statement measures trait 2.
#' @param ParInits A three-column matrix containing initial values for the statement parameters block by block. 1 and -1 for alphas and taus are recommended and -1/-2 or 1/2 for deltas are recommended depending on the signs of the statements. Pre-estimated statement parameters can be used as the initial values for scoring purpose.
#' @param block The number of statements in each block in the original test. For now, it can be 2 or 3. We will further expand the code to incorporate bigger blocks.
#' @param pairmap A two-column matrix specifying the ID of statements within each trait. The row of this matrix equals to the total number of pairwise comparisons. For example, for a 20-block tests with 3 statements per block, there will be 20*(3*(3-1)/2) = 60 pairwise comparisons. Suppose there are 12 statements measuring each trait. Then 1 means the statement is the first statement measuring the trait and 12 means the statement is the twelfth statement measuring the trait.
#' @param covariate An p*c person covariate matrix where p equals sample size and c equals the number of covariates. The default is NULL, meaning no person covariate.
#' @param iter The number of iterations. The default value is 2000. See documentation for rstan for more details.
#' @param chains The number of chains. The default value is 2. See documentation for rstan for more details.
#' @param warmup The number of warmups to discard. The default value is 0.5*iterations. See documentation for rstan for more details.
#' @param adapt_delta Target average proposal acceptance probability during Stan's adaptation period. The default value is 0.85. See documentation for rstan for more details.
#' @param thin Thinning. The default value is 1. See documentation for rstan for more details.
#' @param cores The number of computer cores used for parallel computing. The default value is 2.
#' @param ma Mean of the prior distribution for alphas, which follows a lognormal distribution. The default value is 0.2.
#' @param va Standard deviation of the prior distribution for alpha. The default value is 1.
#' @param mt Means of the prior distributions for taus, which follows a normal distribution. The default values is 0.
#' @param vt Standard deviation of the prior distribution for taus. The default value is 3.
#' @param mdne Mean of the prior distribution for the location parameters (delta) of negative items. For example, the item “I am often lazy” as an indicator of conscientiousness should have a negative location parameter (e.g., -2.5). Location parameters are on the same scale (z score) as the latent trait scores. We assume a normal prior for the location parameters and fix the range of negative location parameters between -10 and 0. The default value is -2.
#' @param vdne Standard deviation of the prior distribution for negative deltas. The default value is 2.
#' @param mdnu Mean of the prior distribution for the location parameters (delta) of neutral (intermediate) items. For example, the item “I as productive as an average person” as an indicator of conscientiousness should have a location parameter close to zero. We fix the range of location parameters of neutral items between -10 and 10 as we are not sure whether they are slightly positive or slightly negative. The default value is 0.
#' @param vdnu Standard deviation of the prior distribution for negative deltas. The default value is 2.
#' @param mdpo Mean of the prior distribution for the location parameters (delta) of positive items. For example, the item “I very hardworking” as an indicator of conscientiousness should have a positive location parameter (e.g., 2.5). We fix the range of location parameters of positive items between 0 and 10.  The default value is 2.
#' @param vdpo Standard deviation of the prior distribution for positive deltas. The default value is 2.
#' @param mb Means of the prior distributions for the random block factor. The default values is 0.
#' @param vb Standard deviation of the prior distribution for the random block factor. The default value is 1.
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
                 ma=0.2, va=1, mt=0, vt=3,
                 mdne=-2, vdne=2, mdnu=0, vdnu=2, mdpo=2, vdpo=2,
                 mb=0, vb=1){
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

      #Delta.Ind.0 <- c(ParInits[,1],ParInits[,2])   #Statements in pair format are estimated column by column
      #Delta.Ind.0 <- as.matrix(ParInits[,2])    #Statements in pair format are estimated block by block
      Delta.Ind.0 <- c(t(matrix(ParInits[,2], nrow = 2))[,1], t(matrix(ParInits[,2], nrow = 2))[,2])
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


      # init <- list(list(alpha=rep(1,Data$I*2),delta_raw=Delta.Ind),
      #              list(alpha=rep(1,Data$I*2),delta_raw=Delta.Ind))

      #initial values
      init <- function() {
        list(alpha=ParInits[,1], delta=ParInits[,2], tau=ParInits[,3])
      }

      Stan.data <- list(y = Data$y,
                        Categ = max(Data$y),
                        Items = Data$I,
                        Subjt = Data$J,
                        N=Data$N,
                        N_mis=(Data$I*Data$J-Data$N),
                        II=Data$ii,
                        JJ=Data$jj,
                        Trait = max(ind),
                        INDEX  = c(ind1[,1], ind1[,2]),
                        Delta_lower = Delta.lower,
                        Delta_upper = Delta.upper,
                        Delta_Ind = Delta.Ind,
                        Delta_Std = Delta.Std,
                        Theta_mu=rep(0,max(ind)),
                        ma=ma,
                        va=va,
                        mt=mt,
                        vt=vt,
                        mb=mb,
                        vb=vb)


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

      #Delta.Ind.0 <- as.matrix(c(t(ParInits)))    #Statements in triplet format are estimated row by row
      Delta.Ind.0 <- as.matrix(ParInits[,2])    #Statements in triplet format are estimated block by block

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


      # init <- list(list(alpha_raw=rep(1.00,Data$I),delta_1=Delta.Ind),
      #              list(alpha_raw=rep(1.50,Data$I),delta_1=Delta.Ind))

      init <- function() {
        list(alpha=ParInits[,1], delta=ParInits[,2], tau=ParInits[,3])
      }

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
