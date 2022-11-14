//
// This Stan program defines a Generalized Thurstonian Unfolding Model (GTUM)_poly

functions {

// Define the fucntion to calculate model-based probability

real GFCU(int y, real theta1, real theta2,real alpha1, real alpha2,real delta1, real delta2,vector tau,real blockrandomness) {

    real t1;
    real t2;

    t1 = -fabs(alpha1*((theta1-delta1)));
    t2 = -fabs(alpha2*((theta2-delta2)));

    return ordered_logistic_lpmf(y|(t1-t2+blockrandomness),tau);
}
}


data {
  int<lower=1> Categ;                        // no. of response categories
  int<lower=1> Items;                        // no. of items
  int<lower=1> Subjt;                        // no. of subjects
  int<lower=1> Trait;                        // no. of personality traits
  int<lower=2> Block;                        // block size
  int<lower=1> N;                            // no. of non-missing observations
  int<lower=0> N_mis;                        // no. of missing observations
  int<lower=1, upper=Items> II[N];           // item no. repeated (1,2,3...,1,2,3,...)
  int<lower=1, upper=Subjt> JJ[N];           // person index repeated (1,1,1,...,2,2,2,...,)
  int<lower=1, upper=Categ> y[N];            // observed data in long format
  vector[Trait] Theta_mu;                    // latent mean
  vector[Items] Delta_Ind;                   // Index for the sign of deltas
  vector[Items] Delta_Std;                   // SD for the prior distribution of Delta
  int<lower=1, upper=Trait> Dime_Ind[2*Items];                 // Link a statement to its trait
  int<lower=1, upper=Items> Item_Ind[2*Items];                 // item no. within a factor
  vector<lower=-10, upper=10>[Items] Delta_lower;                // lower bounds of delta
  vector<lower=-10, upper=10>[Items] Delta_upper;                // upper bounds of delta

  // user-defined priors
  real ma;
  real va;
  real mt;
  real vt;
  real mb;
  real vb;
  }

parameters {
  ordered[Categ-1] tau[Items];
  vector<lower=0.1,upper=5>[Items] alpha_raw;
  vector<lower=0, upper=1>[Items] delta_raw;
  matrix[Trait, Subjt] z_trait;                // unscaled person scores
  cholesky_factor_corr[(Trait)] L_Omega;       // cholesky factor of correlation matrix of traits
  matrix[Subjt,20] randomblock_raw;
  real<lower=0.01,upper=5> randomblock_var;

}

transformed parameters {

  matrix[Subjt, Trait] theta;
  vector<lower=0.1,upper=5>[Items*2] alpha;
  vector[Items*2] delta;
  matrix[Subjt,Items] randomblock;
  vector[Items] delta_1 = Delta_lower + (Delta_upper - Delta_lower) .* delta_raw;
  theta = (L_Omega * z_trait)';

for (i in 1:20){

// rearrange item parameters

  randomblock[,(i-1)*3+1] = randomblock_raw[,i];
  randomblock[,(i-1)*3+2] = randomblock_raw[,i];
  randomblock[,(i-1)*3+3] = randomblock_raw[,i];

  alpha[(i-1)*3+1] = alpha_raw[(i-1)*3+1];
  alpha[(i-1)*3+2] = alpha_raw[(i-1)*3+1];
  alpha[(i-1)*3+3] = alpha_raw[(i-1)*3+2];

  alpha[(i-1)*3+Items+1] = alpha_raw[(i-1)*3+2];
  alpha[(i-1)*3+Items+2] = alpha_raw[(i-1)*3+3];
  alpha[(i-1)*3+Items+3] = alpha_raw[(i-1)*3+3];

  delta[(i-1)*3+1] = delta_1[(i-1)*3+1];
  delta[(i-1)*3+2] = delta_1[(i-1)*3+1];
  delta[(i-1)*3+3] = delta_1[(i-1)*3+2];

  delta[(i-1)*3+Items+1] = delta_1[(i-1)*3+2];
  delta[(i-1)*3+Items+2] = delta_1[(i-1)*3+3];
  delta[(i-1)*3+Items+3] = delta_1[(i-1)*3+3];

 }
}

model {


    L_Omega ~ lkj_corr_cholesky(1);
    alpha_raw ~  lognormal(ma,va);
    randomblock_var ~ lognormal(mb,vb);

    for (i in 1:Items){
    tau[i,] ~ normal(mt,vt);
    }

    delta_1 ~ normal(Delta_Ind,Delta_Std);
    to_vector(z_trait) ~ normal(0, 1);
    to_vector(randomblock_raw) ~ normal(0, randomblock_var);

for (n in 1:N){
     target += GFCU(y[n],theta[JJ[n],Dime_Ind[II[n]]],theta[JJ[n],Dime_Ind[(60+II[n])]],alpha[II[n]],alpha[(II[n]+60)],delta[II[n]],delta[(II[n]+60)],tau[II[n],],randomblock[JJ[n],II[n]]);
}
}

generated quantities {
  matrix[(Trait),(Trait)] Cor;
  Cor = multiply_lower_tri_self_transpose(L_Omega);
}
