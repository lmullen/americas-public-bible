#!/usr/bin/env Rscript --vanilla

# Train the model for figuring out biblical quotations

library(feather)
library(dplyr)
library(tidyr)
library(caret)
library(caretEnsemble)
library(randomForest)
library(kernlab)
library(nnet)
library(doParallel)

relabel_matches <- function(x) {
  stopifnot(is.logical(x))
  x <- ifelse(x, "quotation", "noise")
  x <- factor(x, levels = c("quotation", "noise"))
  x
}

labeled <- read_feather("data/labeled-features.feather") %>%
  select(reference, page, match, everything()) %>%
  select(-position_range, -position_sd, - tf) %>%
  mutate(match = relabel_matches(match))

predictors <- labeled %>% select(-page, -reference)

set.seed(7347)
split_i <- createDataPartition(y = predictors$match, p = 0.7, list = FALSE)
training <- predictors[split_i, ]
testing  <- predictors[-split_i, ]
testing_references <- labeled[-split_i, ]

tr_ctrl <- trainControl(method = "repeatedcv",
                        number = 10,
                        repeats = 5,
                        savePredictions = "final",
                        classProbs = TRUE,
                        index = createResample(training$match, 5),
                        summaryFunction = twoClassSummary)

registerDoParallel(8, cores = 8)
getDoParWorkers()

set.seed(7347)
model_list <- caretList(
  x = select(predictors, -match),
  y = predictors$match,
  metric = "ROC",
  trControl = tr_ctrl,
  tuneList = list(
    # svmRadial = caretModelSpec(method = "svmRadial",
    #                            tuneGrid = expand.grid(sigma = seq(6.8, 7.8, 0.1),
    #                                                   C = seq(0.05, .35, 0.05)
    #                                                   ),
    #                             preProcess = c("center", "scale")
    #                            ),
    # svmLinear = caretModelSpec(method = "svmLinear",
    #                            tuneGrid = expand.grid(C = seq(0.05, 1, 0.05)),
    #                            preProcess = c("center", "scale")
    #                            ),
    knn = caretModelSpec(method = "knn",
                         tuneLength = 20,
                         preProcess = c("center", "scale")
                         ),
    nnet = caretModelSpec(method = "nnet",
                          tuneLength = 20,
                          preProcess = c("center", "scale")
                          ),
    rf = caretModelSpec(method = "rf", tuneLength = 3, preProcess = NULL)
  )
)

resamp <- resamples(model_list)
modelCor(resamp)
dotplot(resamp, metric = "ROC")
# rocDiffs <- diff(resamp, metric = "ROC")
# summary(rocDiffs)
# dotplot(rocDiffs)

# train_ensemble <- function(m_list) {
# caretEnsemble(
#   m_list,
#   metric = "ROC",
#   trControl = trainControl(
#     number = 40,
#     summaryFunction = twoClassSummary,
#     classProbs = TRUE
#     ))
# }
#
# ensemble0 <- train_ensemble(model_list)
#
# models_ensemble1 <- model_list
# models_ensemble1$svmRadial <- NULL
# models_ensemble1$svmLinear <- NULL
# models_ensemble1$rf <- NULL
# ensemble1 <- train_ensemble(models_ensemble1)
#
# models_ensemble2 <- model_list
# models_ensemble2$svmRadial <- NULL
# models_ensemble2$rf <- NULL
# models_ensemble2$nnet <- NULL
# ensemble2 <- train_ensemble(models_ensemble2)
#
# models_ensemble3 <- model_list
# models_ensemble3$knn <- NULL
# models_ensemble3$rf <- NULL
# models_ensemble3$nnet <- NULL
# ensemble3 <- train_ensemble(models_ensemble3)
#
# model_list$ensemble0 <- ensemble0
# model_list$ensemble1 <- ensemble1
# model_list$ensemble2 <- ensemble2
# model_list$ensemble3 <- ensemble3

model_preds_train <- lapply(model_list, predict, newdata = select(training, -match))
conf_train <- lapply(model_preds_train, confusionMatrix, training$match)
model_preds_test <- lapply(model_list, predict, newdata = select(testing, -match))
conf_test <- lapply(model_preds_test, confusionMatrix, testing$match)

get_accuracy_measures <- function(confusion) {
  n <- names(confusion)
  res <- lapply(n, function(i) {
    measures <- confusion[[i]]$byClass
    data_frame(model = i, measure = names(measures), value = unname(measures))
  })
  res %>% bind_rows() %>% spread(measure, value)
}

accuracy_train <- get_accuracy_measures(conf_train)
accuracy_test <- get_accuracy_measures(conf_test)
print(accuracy_test)
print(accuracy_train)

# Find out which predictions were wrong
# bind_cols(testing_references, data_frame(prediction = ens_preds)) %>%
#   filter(match != prediction) %>%
#   View

# all_features <- read_feather("data/all-features.feather")
# sample_predictors <- all_features %>%
#   select(token_count, tfidf, proportion, runs_pval)
#
# res <- lapply(model_list, predict, newdata = sample_predictors) %>%
#   as_data_frame() %>%
#   bind_cols(all_features, .)
# print(res)

saveRDS(model_list$nnet, file = "bin/prediction-model.rds",
        compress = FALSE)

