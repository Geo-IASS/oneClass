context('Test holdOutPredictions')

toy <- threeGaussians(seed=123)

### generate reproducible objects (store somewhere and load for testing!?)
set.seed(123)
partitions <- list(
  cv = createFolds(toy$tr$y, k=2)
  , repeatedcv = createMultiFolds(toy$tr$y, k=2, times=2)
  , boot = createResample(toy$tr$y, times=2) 
  #, cvPu = createFoldsPu(toy$tr$y, k=2, positive=1, indepUn=71:120), 
  #, repeatedcvPu = createMultiFoldsPu(toy$tr$y, k=2, times=2, positive=1, indepUn=71:120), 
  #, bootPu = createResamplePu(toy$tr$y, times=2, positive=1, indepUn=71:120)
)


fits <- lapply(partitions, function(i) 
  trainOcc(x = toy$tr[,-1], y = toy$tr[,1], positive = 1,
           index = i,
           tuneGrid = data.frame( sigma=.1, cNeg=10, cMultiplier=2) ) )

fits2 <- lapply(partitions, function(i) 
  trainOcc(x = toy$tr[,-1], y = toy$tr[,1], positive = 1,
           index = i,
           tuneGrid = data.frame( sigma=.1, cNeg=10, cMultiplier=2) ) )

hops <- lapply(fits, holdOutPredictions)
hops.ag <- lapply(fits, holdOutPredictions, aggregate=TRUE)
hops.p <-  lapply(fits, holdOutPredictions, partition=2)
hops.p.ag <- lapply(fits, holdOutPredictions, partition=2, aggregate=TRUE)



### check if hold out predictions are identical
test_that('holdOutPredictions returns the right values', {
  
  expect_equal(mapply(function(a, b) identical(a$pred, b$pred), a=fits, b=fits2), 
               c(cv=TRUE, repeatedcv=TRUE, boot=TRUE))#, cvPu=TRUE, repeatedcvPu=TRUE, bootPu=TRUE))
  
  ### class, resampling name, aggregate
  resamplingNames <- c("cv", "repeatedcv", "boot", "cvPu", "repeatedcvPu", "bootPu")
  resamplingPu <- rep(c(FALSE, TRUE), c(3, 3))
  resamplingCv <- c(TRUE, FALSE, FALSE, TRUE, FALSE, FALSE)
  resamplingRepeatedcv <- c(FALSE, TRUE, FALSE, FALSE, TRUE, FALSE)
  resamplingBoot <- c(FALSE, FALSE, TRUE, FALSE, FALSE, TRUE)
  
  ### do
  #numberOfPartitions <- lapply(partitions, length)
  #numberOfSamples <- lapply(partitions, length)
  
  for (i in 1:3) {
    hop <- hops[[i]]
    hop.ag <- hops.ag[[i]]
    
    ### class
    expect_that(hop, is_a('holdOutPredictions'))
    expect_that(hop.ag, is_a('aggregate'))
    expect_that(hop.ag, is_a('holdOutPredictions'))
    
    ### info
    expect_that(hop$resampling$name, equals(resamplingNames[i]))
    expect_that(hop.ag$resampling$name, equals(resamplingNames[i]))
    
    expect_that(hop$resampling$pu, equals(resamplingPu[i]))
    expect_that(hop.ag$resampling$pu, equals(resamplingPu[i]))
    
    expect_that(hop$resampling$cv, equals(resamplingCv[i]))
    expect_that(hop.ag$resampling$cv, equals(resamplingCv[i]))
    
    expect_that(hop$resampling$repeatedcv, equals(resamplingRepeatedcv[i]))
    expect_that(hop.ag$resampling$repeatedcv, equals(resamplingRepeatedcv[i]))
    
    expect_that(hop$resampling$boot, equals(resamplingBoot[i]))
    expect_that(hop.ag$resampling$boot, equals(resamplingBoot[i]))
    
    expect_that(hop$partition, equals('all'))
    expect_that(hop.ag$partition, equals('all'))
    
    expect_that(hop$aggregate, equals(FALSE))
    expect_that(hop.ag$aggregate, equals(TRUE))
    
  }
} 
) # end of test