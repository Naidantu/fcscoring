//
// This Stan program defines a Generalized Thurstonian Unfolding Model (GTUM)_dicho

functions {

// Define the fucntion to calculate model-based probability

real GUFC(int y, int K, real theta1, real theta2,real alpha1, real alpha2,real delta1, real delta2,vector tau) {
    vector[2] prob_obs;
    real t1;
    real t2;

    t1 = -fabs(alpha1*(theta1-delta1));
    t2 = -fabs(alpha2*(theta2-delta2));

    prob_obs[1] = 1-inv_logit(t1-t2-tau[1]);
    prob_obs[2] = 1-prob_obs[1];

    return categorical_lpmf(y|prob_obs);
}

}

data {
  int<lower=1> Categ;                        // no. of response categories
  int<lower=1> Items;                        // no. of items
  int<lower=1> Subjt;                        // no. of subjects
  int<lower=1> Trait;                        // no. of personality traits
  int<lower=1> N;                            // no. of non-missing observations
  int<lower=0> N_mis;                        // no. of missing observations
  int<lower=1, upper=Items> II[N];           // item no. repeated (1,2,3...,1,2,3,...)
  int<lower=1, upper=Subjt> JJ[N];           // person index repeated (1,1,1,...,2,2,2,...,)
  int<lower=1, upper=Categ> y[N];            // observed data in long format
  vector[Trait] Theta_mu;                    // latent mean
  vector[Items*2] Delta_Ind;                 // Index for the sign of deltas
  vector[Items*2] Delta_Std;                 // SD for the prior distribution of Delta
  int<lower=1, upper=20> INDEX[2*Items];                        // Link a statement to its trait
  vector<lower=-5, upper=5>[Items*2] Delta_lower;              // lower bounds of delta
  vector<lower=-5, upper=5>[Items*2] Delta_upper;              // upper bounds of delta

  // user-defined priors
  real ma;
  real va;
  real mt;
  real vt;
  }

parameters {

  ordered[Categ-1] tau[Items];
  vector<lower=0.1,upper=5>[Items*2] alpha;
  vector<lower=0, upper=1>[Items*2] delta_raw;
  matrix[Subjt,Trait] theta;
  cholesky_factor_corr[(Trait)] L_Omega;

}

transformed parameters {
  vector[Items*2] delta = Delta_lower + (Delta_upper - Delta_lower) .* delta_raw;
}

model {

    L_Omega ~ lkj_corr_cholesky(1);
    alpha ~  lognormal(ma,va);
    for (i in 1:Items){
    delta[i] ~ normal(Delta_Ind[i],Delta_Std[i]);
    delta[i+Items] ~ normal(Delta_Ind[i+Items],Delta_Std[i+Items]);
    tau[i,] ~ normal(mt,vt);
    }

for (i in 1:Subjt){

// sampling thetas

   theta[i,] ~ multi_normal_cholesky(Theta_mu,L_Omega);
}

for (n in 1:N){
     target += GUFC(y[n],Categ,theta[JJ[n],INDEX[II[n]]],theta[JJ[n],INDEX[(Items+II[n])]],alpha[II[n]],alpha[(II[n]+Items)],delta[II[n]],delta[(II[n]+Items)],tau[II[n],]);
   }
}

generated quantities {
  matrix[(Trait),(Trait)] Cor;
  Cor = multiply_lower_tri_self_transpose(L_Omega);
}



