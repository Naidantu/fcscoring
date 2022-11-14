
<!-- README.md is generated from README.Rmd. Please edit that file -->

# fcscoring

The fscoring package is designed to implement Bayesian estimation of the
Generalized Thurstonian Unfolding Model (GTUM; paper under review) that
can be seen as an unfolding version of the Thurstonian Item Response
Theory (TIRT; Brown & Maydeu-Olivares, 2011). The TIRT model assumes a
dominance response process that may not be the most appropriate for some
noncognitive tests. Therefore, we developed the GTUM model that adopts
an unfolding response process, which has been shown to better describe
how people respond to noncognitive items (see Roberts, Donoghue, &
Laughlin \[2000\] for the distinction between dominance vs. unfolding
response processes). Although there have been several unfolding forced
choice models, they are limited to specific types of forced choice test
designs (e.g., dichotomous choice, pairs, rank, unidimensional blocks).
The GTUM was intended to be as flexible as the TIRT model so that it can
work with any block size, any response format (e.g., PICK, MOLE, or
RANK; see Cao & Drasgow \[2019\] for details), and any number of
response options (e.g., dichotomous choice vs. graded preference; see
Brown & Maydeu-Olivares \[2018\] for details). Some useful features of
the fscoring function include:

1.  The capacity to deal with missing data in a way similar to how full
    information maximum likelihood works
2.  The capacity to handle high-dimensional structure (e.g., 30 latent
    traits).
3.  Functions for results extraction and Bayesian diagnostic plotting.

Users should be aware of the long computation time (hours) due to the
use of the Bayesian estimator. The backend estimation engine was stan
(Carpenter et al., 2017).

Brown, A., & Maydeu-Olivares, A. (2011). Item response modeling of
forced-choice questionnaires. Educational and Psychological Measurement,
71(3), 460-502.

Brown, A., & Maydeu-Olivares, A. (2018). Ordinal factor analysis of
graded-preference questionnaire data. Structural Equation Modeling: A
Multidisciplinary Journal, 25(4), 516-529.

Cao, M., & Drasgow, F. (2019). Does forcing reduce faking? A
meta-analytic review of forced-choice personality measures in
high-stakes situations. Journal of Applied Psychology, 104(11),
1347–1368.

Carpenter, B., Gelman, A., Hoffman, M. D., Lee, D., Goodrich, B.,
Betancourt, M., … & Riddell, A. (2017). Stan: A probabilistic
programming language. Journal of Statistical Software, 76(1).

Roberts, J. S., Donoghue, J. R., & Laughlin, J. E. (2000). A general
item response theory model for unfolding unidimensional polytomous
responses. Applied Psychological Measurement, 24(1), 3-32.

## Installation

You can install the development version of fcscoring from GitHub:

``` r
devtools::install_github("Naidantu/fcscoring")
```

## Example

This is a basic example which shows you how to prepare data, fit the
model, extract and plot results:

``` r
library(fcscoring)

## basic example code
## Step 1: Input data
# 1.1 Response data in wide format. 
gtum.Data <- c(1,5,2,3,1,2,1,5,3,1,1,1,4,1,4,4,3,2,2,3)
gtum.Data <- matrix(gtum.Data,nrow = 5)
gtum.Data
#>      [,1] [,2] [,3] [,4]
#> [1,]    1    2    1    4
#> [2,]    5    1    1    3
#> [3,]    2    5    4    2
#> [4,]    3    3    1    2
#> [5,]    1    1    4    3

# 1.2 A two-column matrix mapping each statement to each trait. 
# The first row [1,2] means that the first statement in the first pair measures trait 1 and the second statement measures trait 2;
# Similarly, the second row [1,3] means that the first statement in the second pair measures trait 1 and the second statement measures trait 3.
# Please note that the number of rows in "ind" equals the total number of pairs. 
ind <- matrix(c(1, 1, 1, 1, 2, 3, 2, 5), ncol = 2)

# 1.3 A two-column matrix specifying the directions or positivity/negativity of the statements. 
ParInits <- matrix(c(-1, -1, -1, 1, -1, -1, -1, 1), ncol = 2)
ParInits
#>      [,1] [,2]
#> [1,]   -1   -1
#> [2,]   -1   -1
#> [3,]   -1   -1
#> [4,]    1    1

# Please note that if the original test format is triplets, a pairmap file that specifies the rank/ID of the statement in each trait it measures. For example, suppose there are 3 statements measuring each trait. 1 means the statement is the first statement measuring the trait and 3 means the statement is the last statement measuring the trait.

## Step 2: Fit the model
mod <- gtum(gtum.Data=gtum.Data, ind=ind, block=2, ParInits=ParInits, iter=500)

## Step 3: Extract the estimated results 
# 3.1 Extract the theta estimates 
theta <- extract(x=mod, pars='theta')
# Turn the theta estimates into p*trait matrix where p equals sample size and trait equals the number of latent traits
theta <- theta[,1]
# nrow=trait
theta <- matrix(theta, nrow=5)  
theta <- t(theta)
# theta estimates in p*trait matrix format
theta
#>            [,1]        [,2]         [,3]        [,4]        [,5]
#> [1,]  0.7828224 -0.40658708  0.007062224  0.01307353 -0.12785330
#> [2,]  0.1991076  0.05725917 -0.513406680  0.02289327 -0.02429067
#> [3,] -0.8293374 -0.18243126  0.423062355 -0.09387768  0.10236786
#> [4,] -0.2557614 -0.29093250  0.065087933  0.02942721  0.24359255
#> [5,]  0.4101054 -0.07382598 -0.385740311  0.01997131 -0.01225312
# 3.2 Extract the tau estimates
tau <- extract(x=mod, pars='tau')
tau <- tau[,1]
tau
#>    tau[1,1]    tau[1,2]    tau[1,3]    tau[1,4]    tau[2,1]    tau[2,2] 
#> -1.50131965 -0.24129962  0.90507874  1.68123820 -1.74001493 -0.41285177 
#>    tau[2,3]    tau[2,4]    tau[3,1]    tau[3,2]    tau[3,3]    tau[3,4] 
#>  0.92113536  1.69761174 -1.16531049 -0.51288369  0.07242581  2.56426199 
#>    tau[4,1]    tau[4,2]    tau[4,3]    tau[4,4] 
#> -3.14967578 -0.75526138  1.05965790  2.96481719
#3.3 Extract the estimates of the correlations among dimensions
cor <- extract(x=mod, pars='cor')

## Step 4: Plottings
# 4.1 Obtain the density plots for alpha
bayesplot(x=mod, pars='alpha', plot='density', inc_warmup=FALSE)
```

<img src="man/figures/README-example-1.png" width="70%" />

``` r
# 4.2 Obtain the trace plots for alpha
bayesplot(x=mod, pars='alpha', plot='trace', inc_warmup=FALSE)
```

<img src="man/figures/README-example-2.png" width="70%" />
