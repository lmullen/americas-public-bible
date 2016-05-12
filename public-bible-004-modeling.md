---
title: "Create models"
project: "public-bible"
tags:
- computation
- text-analysis
- Bible
- Chronicling America
---

---
project: 'public-bible'
tags:
- computation
- 'text-analysis'
- Bible
- Chronicling America
title: Create models
---

``` {.r}
library(feather)
library(dplyr)
```

    ## 
    ## Attaching package: 'dplyr'

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

``` {.r}
labeled_data <- read_feather("data/labeled-features.feather")
```

Test correlation

``` {.r}
replace_na <- function(x, replace) {
  ifelse(is.na(x), replace, x)
}

predictors <- labeled_data %>% 
  select(-reference, -page, -match) %>% 
  mutate(position_sd = replace_na(position_sd, 10e3))

cor(predictors) %>% knitr::kable()
```

                      token\_count        tfidf           tf   probability   position\_range   position\_sd
  ----------------- -------------- ------------ ------------ ------------- ----------------- --------------
  token\_count           1.0000000    0.8346178    0.8353773     0.8195414         0.1692972     -0.4359461
  tfidf                  0.8346178    1.0000000    0.9995234     0.9617048         0.1632751     -0.4966479
  tf                     0.8353773    0.9995234    1.0000000     0.9617400         0.1638535     -0.5016620
  probability            0.8195414    0.9617048    0.9617400     1.0000000         0.0463445     -0.5315270
  position\_range        0.1692972    0.1632751    0.1638535     0.0463445         1.0000000     -0.0220395
  position\_sd          -0.4359461   -0.4966479   -0.5016620    -0.5315270        -0.0220395      1.0000000

The aim of this notebook it to create models with our training data.

Types of models to try: SVM logistic regression tree based model knn

Predictors to try: All the predictors so far All the non-correlated
predictors All the non-correlated predictors minus range and sd All the
predictors minus range and sd
