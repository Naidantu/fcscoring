
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

###Example 1. dichotomous forced choice pairs

``` r
library(fcscoring)

## Step 1: Read data
# 1.1 Response data in wide format for a 60-statement forced choice test measuring 5 trait from 50 respondents
gtum.Data <- response
#first 10 respondents' response
gtum.Data[1:10,]
#>       [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10] [,11] [,12] [,13]
#>  [1,]    2    2    2    2    1    2    1    1    2     1     1     2     2
#>  [2,]    1    2    2    1    1    2    2    1    1     2     1     1     1
#>  [3,]    2    2    1    1    2    2    2    2    2     1     1     1     2
#>  [4,]    1    1    1    2    1    2    2    2    2     1     1     1     1
#>  [5,]    2    1    1    1    1    2    2    2    2     1     1     1     1
#>  [6,]    2    2    1    1    1    1    2    2    2     1     1     1     2
#>  [7,]    2    1    2    2    1    2    2    1    1     1     1     1     1
#>  [8,]    2    1    2    2    1    1    2    1    1     2     1     1     1
#>  [9,]    2    2    2    2    1    2    2    1    2     1     1     1     1
#> [10,]    2    2    1    1    2    2    2    2    2     2     1     1     1
#>       [,14] [,15] [,16] [,17] [,18] [,19] [,20] [,21] [,22] [,23] [,24] [,25]
#>  [1,]     1     1     2     2     2     1     1     2     2     1     2     2
#>  [2,]     1     1     2     2     2     2     1     2     2     1     2     2
#>  [3,]     1     1     2     2     2     1     1     1     2     1     2     1
#>  [4,]     1     1     2     2     2     2     1     1     1     1     2     2
#>  [5,]     1     1     2     1     1     2     1     2     1     2     2     2
#>  [6,]     1     1     2     1     2     1     1     1     1     2     2     2
#>  [7,]     1     1     1     2     2     1     1     1     2     2     2     2
#>  [8,]     1     2     2     2     2     2     2     2     2     1     2     2
#>  [9,]     1     1     1     1     2     1     1     1     2     2     2     1
#> [10,]     2     1     2     2     2     2     1     1     2     1     2     2
#>       [,26] [,27] [,28] [,29] [,30]
#>  [1,]     2     2     1     2     1
#>  [2,]     2     2     1     1     1
#>  [3,]     1     2     2     2     2
#>  [4,]     1     2     1     2     2
#>  [5,]     2     2     2     2     2
#>  [6,]     1     2     2     2     1
#>  [7,]     2     2     1     1     1
#>  [8,]     2     2     1     1     1
#>  [9,]     1     2     2     2     2
#> [10,]     2     2     2     1     1

# 1.2 A two-column matrix mapping each statement to each trait. 
# The first row [1,2] means that the first statement in the first pair measures trait 1 and the second statement measures trait 2;
# Similarly, the second row [1,3] means that the first statement in the second pair measures trait 1 and the second statement measures trait 3.
# Please note that the number of rows in "ind" equals the total number of pairs. 
ind <- c(t(fc.pair.1[, 1:2]))
ind
#>  [1] 1 2 1 3 1 2 1 5 1 3 1 4 2 3 2 1 2 5 2 4 2 3 2 4 3 5 3 4 3 4 3 5 3 2 3 1 4 1
#> [39] 4 5 4 2 4 5 4 1 4 3 5 2 5 2 5 4 5 1 5 1 5 3

# 1.3 A three-column matrix containing initial values for the statement parameters block by block.
# 1 and -1 for alphas and taus are recommended and -1/-2 or 1/2 for deltas are recommended depending on the signs of the statements.
ParInits <- matrix(c(rep(1,60), rep(c(-1,-1,-1,-1,-1,-1,1,1,1,1,1,1), 5), rep(-1,60)), ncol = 3)
ParInits
#>       [,1] [,2] [,3]
#>  [1,]    1   -1   -1
#>  [2,]    1   -1   -1
#>  [3,]    1   -1   -1
#>  [4,]    1   -1   -1
#>  [5,]    1   -1   -1
#>  [6,]    1   -1   -1
#>  [7,]    1    1   -1
#>  [8,]    1    1   -1
#>  [9,]    1    1   -1
#> [10,]    1    1   -1
#> [11,]    1    1   -1
#> [12,]    1    1   -1
#> [13,]    1   -1   -1
#> [14,]    1   -1   -1
#> [15,]    1   -1   -1
#> [16,]    1   -1   -1
#> [17,]    1   -1   -1
#> [18,]    1   -1   -1
#> [19,]    1    1   -1
#> [20,]    1    1   -1
#> [21,]    1    1   -1
#> [22,]    1    1   -1
#> [23,]    1    1   -1
#> [24,]    1    1   -1
#> [25,]    1   -1   -1
#> [26,]    1   -1   -1
#> [27,]    1   -1   -1
#> [28,]    1   -1   -1
#> [29,]    1   -1   -1
#> [30,]    1   -1   -1
#> [31,]    1    1   -1
#> [32,]    1    1   -1
#> [33,]    1    1   -1
#> [34,]    1    1   -1
#> [35,]    1    1   -1
#> [36,]    1    1   -1
#> [37,]    1   -1   -1
#> [38,]    1   -1   -1
#> [39,]    1   -1   -1
#> [40,]    1   -1   -1
#> [41,]    1   -1   -1
#> [42,]    1   -1   -1
#> [43,]    1    1   -1
#> [44,]    1    1   -1
#> [45,]    1    1   -1
#> [46,]    1    1   -1
#> [47,]    1    1   -1
#> [48,]    1    1   -1
#> [49,]    1   -1   -1
#> [50,]    1   -1   -1
#> [51,]    1   -1   -1
#> [52,]    1   -1   -1
#> [53,]    1   -1   -1
#> [54,]    1   -1   -1
#> [55,]    1    1   -1
#> [56,]    1    1   -1
#> [57,]    1    1   -1
#> [58,]    1    1   -1
#> [59,]    1    1   -1
#> [60,]    1    1   -1

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
#first 10 respondents' thetas
theta[1:10,]
#>             [,1]       [,2]       [,3]       [,4]       [,5]
#>  [1,] -0.5442610 -0.6472786 -0.4666002 -0.5670308 -0.6995072
#>  [2,] -0.8483022 -0.6415157 -0.4936619 -0.7715202 -0.8401651
#>  [3,]  1.3000737  1.4640008  1.1194457  1.2731501  1.4351816
#>  [4,]  0.2943427  0.5803732  0.9929572  0.1702167  0.9806173
#>  [5,]  0.5709954  0.7723249  0.7268576  0.7365284  0.4502826
#>  [6,]  1.1857590  1.3731113  1.0592086  1.1424288  1.2291424
#>  [7,] -0.5406283 -0.5668053 -0.3611441 -0.5691672 -0.2641664
#>  [8,] -0.5076499 -0.9325885 -0.5484221 -0.6383680 -0.8114238
#>  [9,]  1.1065971  1.0097152  0.8194730  1.0748503  0.9528912
#> [10,]  0.2983767  0.2827557  0.4615067  0.1622240  0.1966840
# 3.2 Extract the tau estimates
tau <- extract(x=mod, pars='tau')
tau <- tau[,1]
tau
#>    tau[1,1]    tau[2,1]    tau[3,1]    tau[4,1]    tau[5,1]    tau[6,1] 
#> -1.10219396  0.18005401  1.18540271  0.16652082 -0.44103067 -0.41873520 
#>    tau[7,1]    tau[8,1]    tau[9,1]   tau[10,1]   tau[11,1]   tau[12,1] 
#> -0.85072824 -1.36017975 -2.17825600  0.27938901  2.04607554  1.33996808 
#>   tau[13,1]   tau[14,1]   tau[15,1]   tau[16,1]   tau[17,1]   tau[18,1] 
#> -0.14981247  0.71447491  1.49040238 -0.14964778 -0.33110581 -0.46193210 
#>   tau[19,1]   tau[20,1]   tau[21,1]   tau[22,1]   tau[23,1]   tau[24,1] 
#>  0.02373551  2.07373088  1.06016319  0.38064180  0.26404776 -1.86047218 
#>   tau[25,1]   tau[26,1]   tau[27,1]   tau[28,1]   tau[29,1]   tau[30,1] 
#>  0.23138157  0.85410426 -1.66459506 -1.32713890 -0.39025410 -1.19473934
#3.3 Extract the estimates of the correlations among dimensions
cor <- extract(x=mod, pars='cor')

## Step 4: Plottings
# 4.1 Obtain the density plots for alphas of the first four statements
bayesplot(x=mod, pars=paste0("alpha[",1:4,"]"), plot='density', inc_warmup=FALSE)
```

<img src="man/figures/README-example-1.png" width="70%" />

``` r
# 4.2 Obtain the trace plots for alphas of the first four statements
bayesplot(x=mod, pars=paste0("alpha[",1:4,"]"), plot='trace', inc_warmup=FALSE)
```

<img src="man/figures/README-example-2.png" width="70%" />

###Example 2. polytomous forced choice pairs

``` r
library(fcscoring)

## Step 1: Read data
# 1.1 Response data in wide format for a 60-statement forced choice test measuring 5 trait from 50 respondents
gtum.Data <- response
#first 10 respondents' response
gtum.Data[1:10,]
#>       [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10] [,11] [,12] [,13]
#>  [1,]    1    3    5    5    4    3    4    4    3     3     4     3     2
#>  [2,]    5    3    1    5    2    3    4    3    5     1     4     5     2
#>  [3,]    1    1    3    3    1    3    5    4    3     3     1     1     2
#>  [4,]    1    1    5    3    5    5    4    3    2     3     4     3     3
#>  [5,]    5    5    2    4    4    3    5    3    5     5     1     2     3
#>  [6,]    1    3    1    3    2    4    3    3    5     3     3     2     5
#>  [7,]    2    4    3    3    5    3    5    4    1     2     5     2     3
#>  [8,]    5    4    3    3    1    3    5    4    1     5     4     1     1
#>  [9,]    5    5    5    1    1    2    2    3    5     5     5     3     3
#> [10,]    5    3    1    3    5    3    3    1    5     2     1     5     3
#>       [,14] [,15] [,16] [,17] [,18] [,19] [,20] [,21] [,22] [,23] [,24] [,25]
#>  [1,]     3     3     2     4     4     5     3     3     3     4     3     3
#>  [2,]     2     5     4     5     3     5     5     3     5     3     1     5
#>  [3,]     3     3     2     1     5     3     2     5     5     3     1     4
#>  [4,]     3     5     3     3     1     5     4     4     3     5     3     1
#>  [5,]     3     3     5     3     3     3     5     5     5     4     3     3
#>  [6,]     1     2     5     1     1     5     5     5     5     1     1     4
#>  [7,]     2     4     3     3     5     5     5     4     3     1     1     3
#>  [8,]     5     2     5     4     5     3     5     1     1     5     1     5
#>  [9,]     3     1     3     1     4     5     4     3     5     2     4     3
#> [10,]     4     1     2     1     3     4     3     5     2     2     1     1
#>       [,26] [,27] [,28] [,29] [,30]
#>  [1,]     2     3     1     3     5
#>  [2,]     2     3     1     4     5
#>  [3,]     5     3     3     3     5
#>  [4,]     3     2     1     4     3
#>  [5,]     5     1     5     3     4
#>  [6,]     1     2     3     5     3
#>  [7,]     3     3     4     3     4
#>  [8,]     5     3     5     4     4
#>  [9,]     3     3     3     5     5
#> [10,]     2     5     4     3     5

# 1.2 A two-column matrix mapping each statement to each trait. 
# The first row [1,2] means that the first statement in the first pair measures trait 1 and the second statement measures trait 2;
# Similarly, the second row [1,3] means that the first statement in the second pair measures trait 1 and the second statement measures trait 3.
# Please note that the number of rows in "ind" equals the total number of pairs. 
ind <- c(t(fc.pair.1[, 1:2]))
ind
#>  [1] 1 2 1 3 1 2 1 5 1 3 1 4 2 3 2 1 2 5 2 4 2 3 2 4 3 5 3 4 3 4 3 5 3 2 3 1 4 1
#> [39] 4 5 4 2 4 5 4 1 4 3 5 2 5 2 5 4 5 1 5 1 5 3

# 1.3 A three-column matrix containing initial values for the statement parameters block by block.
# 1 and -1 for alphas and taus are recommended and -1/-2 or 1/2 for deltas are recommended depending on the signs of the statements.
ParInits <- matrix(c(rep(1,60), rep(c(-1,-1,-1,-1,-1,-1,1,1,1,1,1,1), 5), rep(-1,60)), ncol = 3)
ParInits
#>       [,1] [,2] [,3]
#>  [1,]    1   -1   -1
#>  [2,]    1   -1   -1
#>  [3,]    1   -1   -1
#>  [4,]    1   -1   -1
#>  [5,]    1   -1   -1
#>  [6,]    1   -1   -1
#>  [7,]    1    1   -1
#>  [8,]    1    1   -1
#>  [9,]    1    1   -1
#> [10,]    1    1   -1
#> [11,]    1    1   -1
#> [12,]    1    1   -1
#> [13,]    1   -1   -1
#> [14,]    1   -1   -1
#> [15,]    1   -1   -1
#> [16,]    1   -1   -1
#> [17,]    1   -1   -1
#> [18,]    1   -1   -1
#> [19,]    1    1   -1
#> [20,]    1    1   -1
#> [21,]    1    1   -1
#> [22,]    1    1   -1
#> [23,]    1    1   -1
#> [24,]    1    1   -1
#> [25,]    1   -1   -1
#> [26,]    1   -1   -1
#> [27,]    1   -1   -1
#> [28,]    1   -1   -1
#> [29,]    1   -1   -1
#> [30,]    1   -1   -1
#> [31,]    1    1   -1
#> [32,]    1    1   -1
#> [33,]    1    1   -1
#> [34,]    1    1   -1
#> [35,]    1    1   -1
#> [36,]    1    1   -1
#> [37,]    1   -1   -1
#> [38,]    1   -1   -1
#> [39,]    1   -1   -1
#> [40,]    1   -1   -1
#> [41,]    1   -1   -1
#> [42,]    1   -1   -1
#> [43,]    1    1   -1
#> [44,]    1    1   -1
#> [45,]    1    1   -1
#> [46,]    1    1   -1
#> [47,]    1    1   -1
#> [48,]    1    1   -1
#> [49,]    1   -1   -1
#> [50,]    1   -1   -1
#> [51,]    1   -1   -1
#> [52,]    1   -1   -1
#> [53,]    1   -1   -1
#> [54,]    1   -1   -1
#> [55,]    1    1   -1
#> [56,]    1    1   -1
#> [57,]    1    1   -1
#> [58,]    1    1   -1
#> [59,]    1    1   -1
#> [60,]    1    1   -1

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
#first 10 respondents' thetas
theta[1:10,]
#>              [,1]        [,2]       [,3]       [,4]         [,5]
#>  [1,]  0.13678826 -0.02559634 0.04218752 -0.1207635  0.063262028
#>  [2,]  0.21309914 -0.21185551 0.44161404 -0.3034583  0.205821410
#>  [3,] -0.17303966  0.04472782 0.25189640  0.1586983  0.294416913
#>  [4,]  0.09788051  0.08834298 0.03677033 -0.1678943 -0.006956459
#>  [5,]  1.07250258  1.04253488 1.00730588  0.9365662  0.931342075
#>  [6,]  0.60328459  0.73137109 0.92994558  0.8177410  0.808639787
#>  [7,]  0.09563004  0.34763598 0.03985973  0.3052572  0.330510900
#>  [8,]  0.60307659  0.72084333 0.51610238  0.6735031  0.598274622
#>  [9,]  1.03095001  0.65929422 1.35130738  0.7565609  1.150877393
#> [10,]  0.58674772  0.53872113 0.30200710  0.8020421  0.134469622
# 3.2 Extract the tau estimates
tau <- extract(x=mod, pars='tau')
tau <- tau[,1]
# nrow=response option-1
tau <- matrix(tau, nrow=4)  
tau <- t(tau)
tau
#>             [,1]       [,2]       [,3]      [,4]
#>  [1,] -1.5767953 -0.9134023 0.42944863 0.9128202
#>  [2,] -1.9935117 -0.9912001 0.38402537 1.3898395
#>  [3,] -0.6611163 -0.1653406 0.82422521 1.4797078
#>  [4,] -1.4949263 -1.0262848 0.67236578 1.5036778
#>  [5,] -1.6475446 -0.3257724 0.72905288 1.3170318
#>  [6,] -1.4740711 -0.8317973 1.10006438 1.7812135
#>  [7,] -2.3645073 -1.2854142 0.16500987 1.6165738
#>  [8,] -1.8169961 -0.4464454 0.76077048 2.2418245
#>  [9,] -1.8066026 -1.0136417 0.81705963 1.4216429
#> [10,] -1.2840477 -0.6451547 0.55608640 1.2749844
#> [11,] -1.6936764 -1.1580698 0.80444097 1.7229234
#> [12,] -0.9596478 -0.1384553 1.54845252 1.9195353
#> [13,] -1.7622498 -0.5586376 0.91510133 1.7121050
#> [14,] -1.7274742 -0.4971620 0.43215832 1.4969275
#> [15,] -1.6081288 -0.2974773 0.96209822 1.9156127
#> [16,] -1.6654622 -0.6390347 0.54742426 1.3112828
#> [17,] -0.9334845 -0.6214463 1.17331218 2.1007236
#> [18,] -1.0531426 -0.6603119 0.46122647 1.3776425
#> [19,] -1.9674215 -1.5030434 0.48562842 1.5355497
#> [20,] -1.8974941 -0.4840412 0.97434845 1.6152331
#> [21,] -1.6535507 -1.1790720 0.13623244 1.4669526
#> [22,] -1.3993748 -0.9842099 0.27097123 0.9214591
#> [23,] -1.4827134 -0.4613140 1.01208379 1.6635913
#> [24,] -0.8097872 -0.2041143 1.30932978 2.1870562
#> [25,] -1.7880395 -1.1915950 0.36760490 0.8114334
#> [26,] -1.9278416 -0.7229381 0.86272651 1.5289375
#> [27,] -2.2547395 -0.8788841 1.05118224 1.7558064
#> [28,] -2.1459217 -1.2252807 0.61144796 1.7788625
#> [29,] -1.7371990 -0.8065699 0.99040656 2.2337299
#> [30,] -1.9368126 -1.1686357 0.08612558 1.0500145
#3.3 Extract the estimates of the correlations among dimensions
cor <- extract(x=mod, pars='cor')

## Step 4: Plottings
# 4.1 Obtain the density plots for alphas of the first four statements
bayesplot(x=mod, pars=paste0("alpha[",1:4,"]"), plot='density', inc_warmup=FALSE)
```

<img src="man/figures/README-example 2-1.png" width="70%" />

``` r
# 4.2 Obtain the trace plots for alphas of the first four statements
bayesplot(x=mod, pars=paste0("alpha[",1:4,"]"), plot='trace', inc_warmup=FALSE)
```

<img src="man/figures/README-example 2-2.png" width="70%" />

###Example 3. dichotomous forced choice triplets recoded into pairs

``` r
library(fcscoring)

## Step 1: Read data
# 1.1 Response data in wide format for a 60-statement forced choice test measuring 5 trait from 50 respondents
gtum.Data <- response
#first 10 respondents' response
gtum.Data[1:10,]
#>       [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10] [,11] [,12] [,13]
#>  [1,]    1    1    1    2    2    2    2    1    1     2     1     1     2
#>  [2,]    1    2    1    1    1    2    2    2    1     1     1     2     2
#>  [3,]    1    1    2    2    2    2    2    2    1     2     2     2     2
#>  [4,]    1    2    1    1    1    2    2    1    2     1     2     1     2
#>  [5,]    1    2    2    1    1    1    2    2    1     2     2     1     1
#>  [6,]    1    2    2    1    1    2    2    1    2     2     2     1     1
#>  [7,]    1    1    2    1    1    2    1    1    2     1     1     1     1
#>  [8,]    1    1    1    1    1    2    1    1    1     2     2     1     2
#>  [9,]    1    2    2    2    2    2    1    1    2     2     2     2     1
#> [10,]    1    2    1    1    1    2    1    2    1     2     1     1     1
#>       [,14] [,15] [,16] [,17] [,18] [,19] [,20] [,21] [,22] [,23] [,24] [,25]
#>  [1,]     2     1     2     1     1     1     1     1     2     1     2     2
#>  [2,]     2     2     1     1     1     1     1     1     2     2     1     1
#>  [3,]     1     1     2     1     1     1     1     1     2     2     1     2
#>  [4,]     1     1     1     2     2     1     2     2     2     1     2     1
#>  [5,]     1     1     1     1     1     2     2     2     1     1     1     2
#>  [6,]     1     1     1     1     1     1     1     1     1     1     1     1
#>  [7,]     1     1     1     1     1     2     1     2     1     2     2     2
#>  [8,]     1     2     1     1     1     1     2     2     2     2     2     2
#>  [9,]     2     1     2     2     2     2     2     1     1     2     1     2
#> [10,]     1     2     2     2     2     1     1     2     1     2     1     2
#>       [,26] [,27] [,28] [,29] [,30] [,31] [,32] [,33] [,34] [,35] [,36] [,37]
#>  [1,]     1     1     2     1     1     2     2     1     2     1     1     2
#>  [2,]     1     1     1     1     2     2     1     2     1     2     1     1
#>  [3,]     2     1     1     1     1     1     2     2     2     2     2     1
#>  [4,]     2     1     2     1     1     1     2     1     2     1     1     1
#>  [5,]     2     2     1     1     2     2     2     1     2     2     1     1
#>  [6,]     2     2     2     1     1     2     1     1     1     1     1     2
#>  [7,]     1     1     2     2     2     1     1     2     1     1     2     1
#>  [8,]     2     2     2     1     1     2     2     1     2     2     2     1
#>  [9,]     2     2     1     1     1     1     2     2     1     2     1     1
#> [10,]     2     2     1     1     1     1     1     1     2     2     2     2
#>       [,38] [,39] [,40] [,41] [,42] [,43] [,44] [,45] [,46] [,47] [,48] [,49]
#>  [1,]     1     2     1     2     1     2     1     2     2     2     2     2
#>  [2,]     1     1     2     2     1     2     2     1     2     1     1     1
#>  [3,]     2     2     2     2     2     2     1     2     1     2     2     2
#>  [4,]     2     1     2     1     1     1     1     2     2     2     1     2
#>  [5,]     2     2     2     1     1     2     1     1     2     1     1     2
#>  [6,]     1     2     2     1     1     2     1     2     1     1     2     2
#>  [7,]     1     2     1     1     1     1     1     2     1     2     1     1
#>  [8,]     1     1     2     1     1     2     2     2     1     2     1     1
#>  [9,]     2     2     2     1     1     1     1     2     1     2     1     2
#> [10,]     2     1     2     2     2     2     2     2     2     2     1     2
#>       [,50] [,51] [,52] [,53] [,54] [,55] [,56] [,57] [,58] [,59] [,60]
#>  [1,]     1     2     2     1     2     1     1     2     2     1     2
#>  [2,]     1     1     2     2     2     1     1     1     1     1     1
#>  [3,]     2     2     1     1     1     2     1     1     1     2     2
#>  [4,]     1     2     2     2     1     1     1     1     1     1     1
#>  [5,]     2     2     2     2     1     1     1     2     1     2     2
#>  [6,]     2     2     1     1     1     2     2     1     1     1     2
#>  [7,]     1     1     2     1     1     2     1     2     2     2     2
#>  [8,]     1     1     2     1     1     2     1     1     1     2     2
#>  [9,]     2     2     2     2     1     2     2     2     2     2     2
#> [10,]     2     2     2     2     2     1     1     1     1     1     2

# 1.2 A two-column matrix mapping each statement to each trait. 
# The first row [1,2] means that the first statement in the first pair measures trait 1 and the second statement measures trait 2;
# Similarly, the second row [1,3] means that the first statement in the second pair measures trait 1 and the second statement measures trait 3.
# Please note that the number of rows in "ind" equals the total number of pairs. 
ind <- c(t(fc.pair[, 5:6]))
ind
#>   [1] 1 2 1 5 2 5 3 4 3 1 4 1 5 2 5 3 2 3 4 5 4 1 5 1 3 1 3 2 1 2 5 2 5 4 2 4 2
#>  [38] 1 2 3 1 3 4 5 4 2 5 2 5 1 5 3 1 3 4 1 4 2 1 2 2 3 2 4 3 4 1 3 1 5 3 5 2 1
#>  [75] 2 4 1 4 3 4 3 5 4 5 2 5 2 1 5 1 4 1 4 3 1 3 4 3 4 5 3 5 3 2 3 5 2 5 5 4 5
#> [112] 1 4 1 4 3 4 2 3 2

# 1.3 A three-column matrix containing initial values for the statement parameters block by block.
# 1 and -1 for alphas and taus are recommended and -1/-2 or 1/2 for deltas are recommended depending on the signs of the statements.
ParInits <- matrix(c(rep(1,60), item.order[,4], rep(-1,60)), ncol = 3)
ParInits
#>       [,1]  [,2] [,3]
#>  [1,]    1 -2.50   -1
#>  [2,]    1 -2.25   -1
#>  [3,]    1 -2.50   -1
#>  [4,]    1 -2.25   -1
#>  [5,]    1 -2.50   -1
#>  [6,]    1 -2.25   -1
#>  [7,]    1 -2.00   -1
#>  [8,]    1 -2.25   -1
#>  [9,]    1 -2.00   -1
#> [10,]    1 -1.75   -1
#> [11,]    1 -1.50   -1
#> [12,]    1 -1.75   -1
#> [13,]    1 -1.50   -1
#> [14,]    1 -1.75   -1
#> [15,]    1 -1.50   -1
#> [16,]    1 -1.25   -1
#> [17,]    1 -1.00   -1
#> [18,]    1 -1.25   -1
#> [19,]    1 -1.00   -1
#> [20,]    1 -1.25   -1
#> [21,]    1 -1.00   -1
#> [22,]    1 -0.75   -1
#> [23,]    1 -0.50   -1
#> [24,]    1 -0.75   -1
#> [25,]    1 -0.50   -1
#> [26,]    1 -0.75   -1
#> [27,]    1 -0.50   -1
#> [28,]    1 -0.25   -1
#> [29,]    1  0.00   -1
#> [30,]    1 -0.25   -1
#> [31,]    1  0.00   -1
#> [32,]    1  0.25   -1
#> [33,]    1  0.00   -1
#> [34,]    1  0.25   -1
#> [35,]    1  0.50   -1
#> [36,]    1  0.25   -1
#> [37,]    1  0.50   -1
#> [38,]    1  0.75   -1
#> [39,]    1  0.50   -1
#> [40,]    1  0.75   -1
#> [41,]    1  0.50   -1
#> [42,]    1  0.75   -1
#> [43,]    1  1.00   -1
#> [44,]    1  0.75   -1
#> [45,]    1  1.00   -1
#> [46,]    1  1.25   -1
#> [47,]    1  1.50   -1
#> [48,]    1  1.25   -1
#> [49,]    1  1.50   -1
#> [50,]    1  1.75   -1
#> [51,]    1  1.50   -1
#> [52,]    1  1.75   -1
#> [53,]    1  2.00   -1
#> [54,]    1  1.75   -1
#> [55,]    1  2.00   -1
#> [56,]    1  2.25   -1
#> [57,]    1  2.00   -1
#> [58,]    1  2.50   -1
#> [59,]    1  2.25   -1
#> [60,]    1  2.50   -1

# Please note that if the original test format is triplets, a pairmap file that specifies the rank/ID of the statement in each trait it measures. For example, suppose there are 3 statements measuring each trait. 1 means the statement is the first statement measuring the trait and 3 means the statement is the last statement measuring the trait.

# 1.4 A two-column matrix specifying the ID of statements within each trait. The row of this matrix equals to the total number of pairwise comparisons. 
pairmap <- fc.pair[, 3:4]
pairmap
#>    ino.1 ino.2
#> 1      1     1
#> 2      1     1
#> 3      1     1
#> 4      1     1
#> 5      1     2
#> 6      1     2
#> 7      2     2
#> 8      2     2
#> 9      2     2
#> 10     2     3
#> 11     2     3
#> 12     3     3
#> 13     3     4
#> 14     3     3
#> 15     4     3
#> 16     4     4
#> 17     4     3
#> 18     4     3
#> 19     5     5
#> 20     5     4
#> 21     5     4
#> 22     4     5
#> 23     4     6
#> 24     5     6
#> 25     6     6
#> 26     6     5
#> 27     6     5
#> 28     5     7
#> 29     5     7
#> 30     7     7
#> 31     8     6
#> 32     8     6
#> 33     6     6
#> 34     8     7
#> 35     8     7
#> 36     7     7
#> 37     9     9
#> 38     9     7
#> 39     9     7
#> 40     8     8
#> 41     8     8
#> 42     8     8
#> 43    10     9
#> 44    10    10
#> 45     9    10
#> 46     9    11
#> 47     9     9
#> 48    11     9
#> 49    10    10
#> 50    10    10
#> 51    10    10
#> 52    11    11
#> 53    11    11
#> 54    11    11
#> 55    12    11
#> 56    12    12
#> 57    11    12
#> 58    12    12
#> 59    12    12
#> 60    12    12

## Step 2: Fit the model
mod <- gtum(gtum.Data=gtum.Data, ind=ind, block=2, ParInits=ParInits, pairmap=pairmap, iter=500)

## Step 3: Extract the estimated results 
# 3.1 Extract the theta estimates 
theta <- extract(x=mod, pars='theta')
# Turn the theta estimates into p*trait matrix where p equals sample size and trait equals the number of latent traits
theta <- theta[,1]
# nrow=trait
theta <- matrix(theta, nrow=5)  
theta <- t(theta)
# theta estimates in p*trait matrix format
#first 10 respondents' thetas
theta[1:10,]
#>              [,1]       [,2]        [,3]        [,4]       [,5]
#>  [1,] -1.17459994  0.7451818 -0.60603040 -0.78797574  1.0526744
#>  [2,] -0.58771388 -0.1818760  0.29476817 -0.68510334  0.5418014
#>  [3,]  0.64513240 -0.0370030  0.11869223  0.92715597 -0.4509827
#>  [4,]  0.93442728 -0.7933075  0.52394142  0.36738103 -0.8841746
#>  [5,]  0.95568428 -0.8625537  1.05045676 -0.05890969 -1.0700376
#>  [6,]  0.37884472 -0.4549013  0.13619396 -0.50796286 -0.6898211
#>  [7,] -0.04802645 -0.1796862  0.01755479 -0.09161227  0.1274090
#>  [8,] -0.66753671  0.2583375 -0.23089203  0.10067346  0.8980666
#>  [9,]  1.07061610 -0.2070278  0.78362384  1.54878064 -0.6174919
#> [10,]  0.95852369 -1.2964691  1.22977702  0.55064136 -0.9268375
# 3.2 Extract the tau estimates
tau <- extract(x=mod, pars='tau')
tau <- tau[,1]
tau
#>     tau[1,1]     tau[2,1]     tau[3,1]     tau[4,1]     tau[5,1]     tau[6,1] 
#>  0.825023607 -0.164208871  0.235227472  0.307095123 -0.362625167 -1.365800724 
#>     tau[7,1]     tau[8,1]     tau[9,1]    tau[10,1]    tau[11,1]    tau[12,1] 
#>  0.084543352  0.660781645  0.603233477  0.237001564  0.573474529  0.103071932 
#>    tau[13,1]    tau[14,1]    tau[15,1]    tau[16,1]    tau[17,1]    tau[18,1] 
#> -0.274117012 -0.089667836  0.270045586  0.717500137  1.708149866  0.691982361 
#>    tau[19,1]    tau[20,1]    tau[21,1]    tau[22,1]    tau[23,1]    tau[24,1] 
#>  1.179733346  0.224161856  0.486715045  0.154232316 -0.533591294  0.355696867 
#>    tau[25,1]    tau[26,1]    tau[27,1]    tau[28,1]    tau[29,1]    tau[30,1] 
#> -0.411461398 -1.095772320 -0.292552558 -1.390496775  1.234004786  0.024405440 
#>    tau[31,1]    tau[32,1]    tau[33,1]    tau[34,1]    tau[35,1]    tau[36,1] 
#> -0.347284536  0.050869311  0.785597362 -0.685535938 -0.253025190  0.173041436 
#>    tau[37,1]    tau[38,1]    tau[39,1]    tau[40,1]    tau[41,1]    tau[42,1] 
#>  0.861091742 -1.226452232  0.481765960 -0.354032683  0.016790967  0.537800432 
#>    tau[43,1]    tau[44,1]    tau[45,1]    tau[46,1]    tau[47,1]    tau[48,1] 
#> -0.767939903  0.149343455 -0.609116422 -0.016659848 -0.659888824 -0.591344392 
#>    tau[49,1]    tau[50,1]    tau[51,1]    tau[52,1]    tau[53,1]    tau[54,1] 
#>  0.556360346  0.047405152  0.663430583 -0.466228171 -0.003366885  1.465608732 
#>    tau[55,1]    tau[56,1]    tau[57,1]    tau[58,1]    tau[59,1]    tau[60,1] 
#>  0.031514866  1.453826348  0.792766688 -0.709648642 -0.171519447 -0.237566322
#3.3 Extract the estimates of the correlations among dimensions
cor <- extract(x=mod, pars='cor')

## Step 4: Plottings
# 4.1 Obtain the density plots for alphas of the first four statements
bayesplot(x=mod, pars=paste0("alpha[",1:4,"]"), plot='density', inc_warmup=FALSE)
```

<img src="man/figures/README-example 3-1.png" width="70%" />

``` r
# 4.2 Obtain the trace plots for alphas of the first four statements
bayesplot(x=mod, pars=paste0("alpha[",1:4,"]"), plot='trace', inc_warmup=FALSE)
```

<img src="man/figures/README-example 3-2.png" width="70%" />
