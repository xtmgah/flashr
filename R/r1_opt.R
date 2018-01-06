#' @title r1_opt
#' @description Optimize a single loading and factor ("rank 1" model)
#' @details This function iteratively optimizes the loading, factor and residual precision, from residuals and their expected squared values
#' Currently the tolerance is on the changes in l and f (not on the objective function)
#' @param R an n times p matrix of data (expected residuals)
#' @param R2 an n times p matrix of expected squared residuals
#' @param l_init the initial value of loading used for iterative scheme (n vector)
#' @param f_init the initial value of the factor for iterative scheme (p vector)
#' @param l2_init initial value of l2 (optional)
#' @param f2_init initial value of f2 (optional)
#' @param ebnm_fn function to solve the Empirical Bayes normal means problem
#' @param ebnm_param parameters to be passed to ebnm_fn when optimizing
#' @param var_type the type of variance structure to assume
#' @param tol a tolerance on changes in l and f to diagnose convergence
#' @param calc_F whether to compute the objective function (useful for testing purposes)
#' @param missing an n times matrix of TRUE/FALSE indicating which elements of R and R2 should be considered missing (note neither R nor R2 must have missing values; eg set them to 0)
#' @param verbose if true then trace of objective function is printed
#' @return an updated flash object
r1_opt = function(R,R2,l_init,f_init,l2_init = NULL, f2_init = NULL, l_subset = 1:length(l_init),f_subset=1:length(f_init),
                  ebnm_fn = ebnm_ash, ebnm_param=flash_default_ebnm_param(ebnm_fn),
                  var_type=c("by_column","constant","by_row","kroneker"),tol=1e-3,calc_F = TRUE, missing=NULL,verbose=FALSE){

  message("todo: check works for subset of length 1")

  l = l_init
  f = f_init
  l2 = l2_init
  f2 = f2_init
  if(is.null(l2)){l2 = l^2} # default initialization of l2 and f2
  if(is.null(f2)){f2 = f^2}

  F_obj = Inf #variable to store value of objective function

  diff = 1
  R2new = R2 - 2*outer(l,f)*R + outer(l2,f2) # expected squared residuals with l and f included

  while(diff > tol){
    l_old = l
    f_old = f

    tau = compute_precision(R2new,missing,var_type)

    if(length(f_subset)>0){
      s2 = 1/( t(l2) %*% tau[,f_subset,drop=FALSE])
      if(any(is.finite(s2))){ # check some finite values before proceeding
        x = (t(l) %*% (R[,f_subset,drop=FALSE]*tau[,f_subset,drop=FALSE])) * s2
        ebnm_f = ebnm_fn(x,sqrt(s2),ebnm_param)
        f[f_subset] = ebnm_f$postmean
        f2[f_subset] = ebnm_f$postmean2

        if(calc_F){
          KL_f = ebnm_f$penloglik - NM_posterior_e_loglik(x,sqrt(s2),ebnm_f$postmean,ebnm_f$postmean2)
        }
      }
    }

    if(length(l_subset)>0){
      s2 = 1/(tau[l_subset,,drop=FALSE] %*% f2)
      if(any(is.finite(s2))){ # check some finite values before proceeding
        x = ((R[l_subset,,drop=FALSE]*tau[l_subset,,drop=FALSE]) %*% f) * s2
        ebnm_l = ebnm_fn(x,sqrt(s2),ebnm_param)
        l[l_subset] = ebnm_l$postmean
        l2[l_subset] = ebnm_l$postmean2

        if(calc_F){
          KL_l = ebnm_l$penloglik - NM_posterior_e_loglik(x,sqrt(s2),ebnm_l$postmean,ebnm_l$postmean2)
        }
      }
    }


    R2new = R2 - 2*outer(l,f)*R + outer(l2,f2)

    if(calc_F){
      Fnew = sum(KL_l) + sum(KL_f) + e_loglik_from_R2_and_tau(R2new,tau,missing)
      if(verbose){
        message(paste0("Objective:",Fnew))
      }
      diff = abs(F_obj - Fnew)
      F_obj = Fnew
    } else { # check convergence by percentage changes in l and f
      #normalize l and f so that f has unit norm
      # note that this messes up stored log-likelihoods etc... so not recommended
      warning("renormalization step not fully tested; be careful!")
      norm = sqrt(sum(f^2))
      f = f/norm
      f2 = f2/(norm^2)
      l = l*norm
      l2 = l2*(norm^2)

      diff = max(abs(c(l,f)/c(l_old,f_old) - 1))
      if(verbose){
        message(paste0("diff:",diff))
      }
    }
  }

  return(list(l=l,f=f,l2=l2,f2=f2,tau=tau,F_obj=F_obj,KL_l = KL_l, KL_f = KL_f,
              gl = ebnm_l$fitted_g, gf = ebnm_f$fitted_g,
              penloglik_l = ebnm_l$penloglik, penloglik_f = ebnm_f$penloglik,
              ebnm_param = ebnm_param))
}

# put the results into f
update_f_from_r1_opt_results = function(f,k,res){
  f$EL[,k] = res$l
  f$EF[,k] = res$f
  f$EL2[,k] = res$l2
  f$EF2[,k] = res$f2
  f$tau = res$tau

  f$gf[[k]] = res$gf
  f$gl[[k]] = res$gl

  f$ebnm_param_f[[k]] = res$ebnm_param
  f$ebnm_param_l[[k]] = res$ebnm_param

  f$KL_f[[k]] = res$KL_f
  f$KL_l[[k]] = res$KL_l

  f$penloglik_f[[k]] = res$penloglik_f
  f$penloglik_l[[k]] = res$penloglik_l
  return(f)
}

# compute the expected log-likelihood (at non-missing locations)
# based on expected squared residuals and tau
e_loglik_from_R2_and_tau = function(R2,tau,missing){
  -0.5 * sum(log((2*pi)/tau[!missing]) + tau[!missing] * R2[!missing])
}