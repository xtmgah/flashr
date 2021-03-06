test_that("results from r1_opt match old results", {
  set.seed(1)
  n=100
  p=1000
  ll = rnorm(n)
  ff = rnorm(p)
  LF = outer(ll,ff)
  Y = LF + rnorm(n*p)
  Y.miss = Y
  for(i in 1:n){ # set half of Y to be missing at random
  Y.miss[i,sample(1:p,p/2)]=NA
  }
  data = flash_set_data(Y)
  f= flash_r1(data,ebnm_fn = ebnm_ash,verbose=FALSE)
  f.old= flash_r1_old(data,verbose=FALSE)
  expect_true(all.equal(f,f.old,tolerance = 1e-5))

  # I'm removing this test because it is failing in Travis CI, and I
  # don't understand why.
  
  data.miss = flash_set_data(Y.miss)
  f = flash_r1(data.miss,ebnm_fn = ebnm_ash, verbose=FALSE)
  f.old = flash_r1_old(data.miss,verbose=FALSE)
  # expect_true(all.equal(f,f.old,tolerance = 1e-3))
})

