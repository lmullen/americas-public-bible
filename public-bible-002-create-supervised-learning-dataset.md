---
title: "Create the supervised learning dataset"
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
title: Create the supervised learning dataset
---

``` {.r}
library(dplyr)
library(feather)
library(tokenizers)
library(stringr)
library(purrr)
library(readr)
library(text2vec)
library(Matrix)

scores <- read_feather("temp/all-features.feather")
load("data/bible.rda")
```

``` {.r}
set.seed(3442)
assign_likelihood <- function(p) {
  ifelse(p >= 0.20, "yes", ifelse(p <= 0.05, "no", "possibly"))
}
sample_matches <- scores %>% 
  mutate(likely = assign_likelihood(probability)) %>% 
  group_by(likely) %>% 
  sample_n(400) %>% 
  ungroup() %>% 
  sample_frac(1) 
```

``` {.r}
my_stops <- c(stopwords(), "he", "his", "him", "them", "have", "do", "from", 
              "which", "who", "she", "her", "hers", "they", "theirs")
get_url_words <- function(x) {
  words <- tokenize_words(x, stopwords = my_stops)
  map_chr(words, str_c, collapse = "+")
}

chronam_url <- function(page, words) {
  base <- "http://chroniclingamerica.loc.gov/lccn/"
  str_c(base, page, "#words=", words, collapse = TRUE)
}

bible_verses <- bible_verses %>% 
  mutate(words = get_url_words(verse))

sample_matches <- sample_matches %>%
  left_join(bible_verses, by = "reference")

urls <- map2_chr(sample_matches$page, sample_matches$words, chronam_url)
```

Create most unusual phrases.

``` {.r}
page_id_to_path <- function(x) {
  x %>% 
    str_replace("-", "/") %>% str_replace("-", "/") %>% 
    str_c("data/sample/", ., "ocr.txt")
}

page_paths <- sample_matches$page %>% page_id_to_path()

newspaper_text <- data_frame(
  page = sample_matches$page,
  text = map_chr(page_paths, read_file)
  )

pages_it <- itoken(newspaper_text$text, tokenizer = bible_tokenizer)
newspaper_dtm <- create_dtm(pages_it, vocab_vectorizer(bible_vocab)) %>% 
  transform_tfidf()
```

    ## idf scaling matrix not provided, calculating it form input matrix

``` {.r}
rownames(newspaper_dtm) <- newspaper_text$page

most_unusual_phrase <- function(page, reference) {
  message(page, " ", reference)
  matching_tokens <- bible_verses[bible_verses$reference == reference, ]$tokens[[1]]
  matching_columns <- which(colnames(newspaper_dtm) %in% matching_tokens)
  tokens <- newspaper_dtm[page, matching_columns, drop = TRUE] 
  names(which.max(tokens))
}

mups <- map2_chr(sample_matches$page, sample_matches$reference, most_unusual_phrase)
```

    ## sn83040198/1903-06-12/ed-1/seq-2/ 2 Timothy 1:18

    ## sn85033429/1869-08-26/ed-1/seq-4/ Matthew 22:30

    ## sn88067030/1858-12-25/ed-1/seq-2/ 2 Corinthians 10:3

    ## sn84026788/1867-08-20/ed-1/seq-2/ John 3:9

    ## sn83025186/1903-03-20/ed-1/seq-2/ Luke 23:14

    ## sn82014635/1897-01-15/ed-1/seq-2/ James 2:7

    ## sn84026688/1903-01-29/ed-1/seq-1/ Genesis 15:4

    ## sn86079088/1873-05-03/ed-1/seq-2/ Ezra 2:10

    ## sn97067613/1889-02-14/ed-1/seq-2/ Proverbs 24:10

    ## sn82015387/1921-02-19/ed-1/seq-2/ 2 Chronicles 31:10

    ## sn84020109/1875-01-21/ed-1/seq-2/ Daniel 3:2

    ## sn86071377/1850-05-02/ed-1/seq-1/ Ezekiel 37:17

    ## sn82016419/1874-02-27/ed-1/seq-3/ Ephesians 4:3

    ## sn96090256/1889-06-14/ed-1/seq-3/ Genesis 11:18

    ## sn88076523/1911-07-14/ed-1/seq-7/ 2 Samuel 11:25

    ## sn83016925/1887-09-28/ed-1/seq-2/ Luke 1:56

    ## sn97067613/1889-12-19/ed-1/seq-2/ Ecclesiastes 1:2

    ## sn85025584/1858-05-27/ed-1/seq-3/ 1 Samuel 2:16

    ## sn84024558/1867-01-17/ed-1/seq-3/ 1 Chronicles 29:3

    ## sn83016474/1840-04-02/ed-1/seq-1/ Isaiah 1:24

    ## sn83025459/1885-01-29/ed-1/seq-4/ John 6:11

    ## sn82006687/1908-04-16/ed-1/seq-3/ Philippians 2:8

    ## sn89058007/1903-09-04/ed-1/seq-1/ Mark 14:7

    ## sn85034235/1883-11-22/ed-1/seq-4/ Ezra 8:35

    ## sn93067846/1894-07-18/ed-1/seq-3/ Jeremiah 20:16

    ## sn89058128/1889-12-26/ed-1/seq-3/ Psalm 119:176

    ## sn85025007/1860-11-29/ed-1/seq-2/ Nehemiah 7:38

    ## sn84020558/1898-05-26/ed-1/seq-5/ Colossians 4:11

    ## sn91068084/1889-12-06/ed-1/seq-6/ Song of Solomon 2:13

    ## sn84026259/1875-05-06/ed-1/seq-3/ Nehemiah 7:22

    ## sn88077573/1907-12-14/ed-1/seq-19/ Luke 2:14

    ## sn83025293/1864-10-22/ed-1/seq-2/ 1 Samuel 4:22

    ## sn84024718/1869-06-29/ed-1/seq-1/ Nehemiah 9:33

    ## sn86086632/1898-04-16/ed-1/seq-7/ Matthew 17:2

    ## sn85032938/1898-05-18/ed-1/seq-3/ Luke 22:28

    ## sn86072143/1870-12-09/ed-1/seq-2/ Matthew 19:24

    ## sn84020104/1853-09-29/ed-1/seq-2/ Deuteronomy 1:17

    ## sn94052364/1890-12-20/ed-1/seq-4/ Ezra 4:19

    ## sn86086632/1898-02-26/ed-1/seq-7/ Acts of the Apostles 10:38

    ## sn85034467/1859-05-05/ed-1/seq-1/ 2 Kings 11:21

    ## sn86063662/1880-02-05/ed-1/seq-3/ 1 Peter 4:8

    ## sn83016925/1887-03-30/ed-1/seq-4/ John 12:32

    ## sn87076843/1893-05-13/ed-1/seq-7/ Daniel 4:3

    ## sn82015486/1865-08-24/ed-1/seq-2/ Exodus 20:7

    ## sn83016925/1887-01-19/ed-1/seq-2/ Ezra 2:15

    ## sn89067274/1895-08-08/ed-1/seq-2/ Psalm 53:1

    ## sn82006687/1872-01-11/ed-1/seq-1/ Psalm 119:115

    ## sn2006060001/1888-06-14/ed-1/seq-3/ Ephesians 5:11

    ## sn88064181/1914-03-27/ed-1/seq-7/ Luke 12:34

    ## sn82016419/1880-07-09/ed-1/seq-4/ Acts of the Apostles 19:2

    ## sn87065462/1912-12-19/ed-1/seq-1/ John 6:6

    ## sn85038145/1875-02-04/ed-1/seq-3/ Matthew 25:17

    ## sn96086441/1881-03-11/ed-1/seq-4/ Mark 8:36

    ## sn85052141/1874-08-01/ed-1/seq-2/ Daniel 5:4

    ## sn84026918/1882-06-30/ed-2/seq-2/ 2 Corinthians 10:3

    ## sn94060041/1890-03-15/ed-1/seq-6/ Luke 5:2

    ## sn86083264/1905-01-26/ed-1/seq-1/ Acts of the Apostles 20:2

    ## sn82015485/1917-12-20/ed-1/seq-4/ Joshua 23:8

    ## sn97067613/1889-08-29/ed-1/seq-4/ Isaiah 40:6

    ## sn85025620/1883-04-26/ed-1/seq-2/ Galatians 4:15

    ## sn86054033/1898-12-29/ed-1/seq-2/ Psalm 34:20

    ## sn90061052/1922-11-02/ed-1/seq-2/ Joshua 5:6

    ## sn88064176/1900-07-21/ed-1/seq-3/ Exodus 26:31

    ## sn84028820/1856-12-11/ed-1/seq-1/ Proverbs 31:12

    ## sn84024716/1908-08-19/ed-1/seq-4/ John 15:9

    ## sn84026688/1903-01-29/ed-1/seq-1/ Leviticus 16:7

    ## sn88085523/1901-07-25/ed-1/seq-3/ Matthew 5:8

    ## sn84026688/1898-10-27/ed-1/seq-1/ Job 39:20

    ## sn84024718/1873-04-15/ed-1/seq-3/ Ezekiel 48:17

    ## sn85050913/1914-05-26/ed-1/seq-1/ Psalm 8:4

    ## sn85038115/1881-06-28/ed-1/seq-4/ 2 Corinthians 4:1

    ## sn83045784/1864-11-03/ed-1/seq-2/ Numbers 26:10

    ## 2010218519/1914-03-28/ed-1/seq-1/ 1 Kings 19:12

    ## sn85033964/1884-01-24/ed-1/seq-4/ Nehemiah 7:34

    ## sn88064402/1905-12-29/ed-1/seq-2/ Judges 3:27

    ## sn85047084/1885-03-26/ed-1/seq-4/ Job 39:21

    ## sn98069867/1919-01-06/ed-1/seq-8/ 1 Samuel 1:28

    ## sn84026897/1869-07-07/ed-1/seq-5/ 2 Corinthians 11:6

    ## sn95069780/1902-08-07/ed-1/seq-5/ 1 Corinthians 8:7

    ## sn83035174/1869-05-12/ed-1/seq-1/ Isaiah 29:15

    ## sn84026536/1868-11-27/ed-1/seq-1/ Ezra 2:4

    ## sn99063954/1893-08-21/ed-1/seq-3/ Jeremiah 48:4

    ## sn84036012/1898-01-10/ed-1/seq-3/ Matthew 8:8

    ## sn88064122/1910-06-11/ed-1/seq-5/ Psalm 116:2

    ## sn90059522/1884-03-22/ed-1/seq-6/ 1 Chronicles 9:24

    ## sn83030193/1887-10-10/ed-1/seq-3/ Psalm 73:14

    ## sn93067976/1852-01-16/ed-1/seq-2/ Luke 12:44

    ## sn83032199/1877-01-17/ed-1/seq-2/ Mark 8:21

    ## sn86072143/1876-06-30/ed-1/seq-2/ 1 Thessalonians 1:8

    ## sn85025584/1858-06-24/ed-1/seq-1/ Matthew 26:72

    ## sn86083274/1889-12-13/ed-1/seq-3/ Hebrews 1:4

    ## sn84026688/1903-09-17/ed-1/seq-4/ Hebrews 13:9

    ## sn84026912/1921-01-26/ed-1/seq-3/ John 5:46

    ## sn86053696/1881-07-16/ed-1/seq-4/ Nehemiah 7:12

    ## sn84024518/1852-04-10/ed-1/seq-2/ Ezekiel 48:17

    ## sn85025431/1898-11-23/ed-1/seq-8/ 2 Samuel 24:13

    ## sn83035565/1913-11-27/ed-1/seq-3/ Genesis 31:49

    ## sn97067613/1889-08-29/ed-1/seq-4/ Isaiah 40:8

    ## sn88056164/1900-12-14/ed-1/seq-2/ John 10:1

    ## sn83045784/1857-03-28/ed-1/seq-5/ Nehemiah 7:17

    ## sn85038078/1846-07-23/ed-1/seq-3/ 1 Chronicles 5:21

    ## sn83030272/1868-09-12/ed-1/seq-1/ 1 Corinthians 9:5

    ## sn89067274/1886-06-24/ed-1/seq-1/ Psalm 148:12

    ## sn91066782/1906-06-08/ed-1/seq-1/ Mark 16:14

    ## sn86072143/1876-12-01/ed-1/seq-1/ Matthew 6:13

    ## sn89066651/1919-12-11/ed-1/seq-29/ John 3:15

    ## sn84020714/1884-11-14/ed-1/seq-1/ 1 Thessalonians 5:21

    ## sn85025620/1883-05-24/ed-1/seq-4/ Proverbs 29:20

    ## sn84024718/1869-06-29/ed-1/seq-1/ Matthew 5:29

    ## sn85025584/1858-07-22/ed-2/seq-2/ Ezekiel 24:19

    ## sn86069867/1899-12-10/ed-1/seq-4/ 1 Timothy 2:12

    ## sn86069867/1899-12-10/ed-1/seq-2/ 2 Kings 2:24

    ## sn86069620/1897-07-08/ed-1/seq-3/ Psalm 72:5

    ## sn83032199/1867-10-03/ed-1/seq-4/ Isaiah 12:1

    ## sn85030287/1910-05-19/ed-1/seq-6/ John 12:1

    ## sn88064122/1910-06-11/ed-1/seq-7/ Ezra 2:10

    ## sn86053634/1882-09-20/ed-1/seq-4/ Genesis 23:9

    ## sn85033371/1865-11-24/ed-1/seq-2/ Matthew 23:30

    ## sn82015015/1842-05-17/ed-1/seq-1/ John 10:37

    ## sn85026941/1898-06-03/ed-1/seq-1/ Job 33:24

    ## sn86053954/1852-07-08/ed-1/seq-3/ Hebrews 10:25

    ## sn84024558/1856-06-14/ed-1/seq-1/ Job 31:18

    ## sn86069675/1921-02-24/ed-1/seq-7/ 2 Corinthians 13:8

    ## sn84026925/1879-11-27/ed-1/seq-4/ Ephesians 4:5

    ## sn86071197/1894-01-22/ed-1/seq-7/ Mark 9:24

    ## sn86058890/1848-02-22/ed-1/seq-3/ 2 Kings 20:11

    ## sn86053634/1882-02-01/ed-1/seq-4/ Acts of the Apostles 24:9

    ## sn88064020/1911-03-16/ed-1/seq-4/ Luke 11:13

    ## sn86064205/1889-08-10/ed-1/seq-4/ 2 Samuel 24:9

    ## sn86069620/1899-01-26/ed-1/seq-4/ 1 Samuel 10:15

    ## sn97065089/1856-06-14/ed-1/seq-1/ 2 Chronicles 36:21

    ## sn83016474/1840-04-28/ed-1/seq-3/ Nehemiah 7:32

    ## sn86071197/1901-12-16/ed-1/seq-6/ Ephesians 4:5

    ## sn83016475/1840-11-14/ed-1/seq-2/ Proverbs 4:21

    ## sn86072143/1876-08-25/ed-1/seq-2/ Mark 1:3

    ## sn86086633/1912-04-16/ed-1/seq-7/ Matthew 26:9

    ## sn97067613/1889-08-29/ed-1/seq-4/ 1 Samuel 17:40

    ## sn93055779/1908-05-30/ed-1/seq-2/ Judges 20:46

    ## sn83045784/1863-07-16/ed-1/seq-4/ Deuteronomy 31:13

    ## sn88064175/1877-06-09/ed-1/seq-1/ Acts of the Apostles 11:19

    ## sn94052364/1890-08-30/ed-1/seq-4/ Luke 8:8

    ## sn84038125/1876-03-03/ed-1/seq-3/ Ezra 2:5

    ## sn97067589/1910-02-11/ed-1/seq-4/ Revelation 10:4

    ## sn85042907/1911-05-20/ed-1/seq-2/ Philippians 4:7

    ## sn89058370/1887-10-05/ed-1/seq-3/ Matthew 11:23

    ## sn94060041/1894-05-12/ed-1/seq-1/ Romans 8:32

    ## sn84028385/1866-02-14/ed-1/seq-1/ Romans 9:14

    ## sn94056446/1908-06-12/ed-1/seq-2/ Hosea 6:4

    ## sn85033429/1869-08-26/ed-1/seq-3/ Hosea 4:17

    ## sn88064328/1913-03-01/ed-1/seq-6/ Ezra 2:4

    ## sn84024718/1873-03-18/ed-1/seq-1/ Proverbs 23:31

    ## sn83016925/1887-03-30/ed-1/seq-4/ Deuteronomy 11:1

    ## sn84026925/1892-05-04/ed-1/seq-4/ Mark 14:45

    ## sn97067613/1889-08-29/ed-1/seq-4/ 1 Samuel 17:48

    ## sn78000395/1903-08-29/ed-1/seq-2/ Ezra 2:12

    ## sn84026909/1884-03-13/ed-1/seq-3/ Job 5:7

    ## sn84020109/1875-10-07/ed-1/seq-1/ Matthew 12:25

    ## sn86072143/1872-04-05/ed-1/seq-3/ Romans 10:9

    ## sn89058128/1899-03-16/ed-1/seq-2/ Job 3:17

    ## sn83035595/1860-05-18/ed-1/seq-1/ Matthew 5:14

    ## sn85033781/1896-02-26/ed-1/seq-6/ Luke 9:25

    ## sn88064020/1921-07-28/ed-1/seq-7/ Romans 8:16

    ## sn88064537/1892-06-04/ed-1/seq-3/ Leviticus 10:16

    ## sn84026409/1892-09-21/ed-1/seq-1/ Exodus 20:3

    ## sn84024738/1856-04-29/ed-1/seq-2/ Nehemiah 7:30

    ## sn85038102/1898-01-14/ed-1/seq-6/ Numbers 23:10

    ## sn83025323/1914-06-25/ed-1/seq-1/ Ephesians 1:2

    ## sn87075048/1900-06-21/ed-1/seq-2/ Mark 8:36

    ## sn88061077/1868-03-13/ed-1/seq-3/ Matthew 5:8

    ## sn88064317/1913-02-06/ed-1/seq-2/ Romans 6:6

    ## sn86071045/1881-04-27/ed-1/seq-3/ Matthew 5:37

    ## sn85052141/1874-08-14/ed-1/seq-3/ John 5:5

    ## sn83004226/1912-09-27/ed-1/seq-6/ Proverbs 22:1

    ## sn85033386/1873-09-05/ed-1/seq-4/ 1 Samuel 17:20

    ## sn88056164/1900-02-02/ed-1/seq-4/ Matthew 26:11

    ## sn90059228/1881-06-01/ed-1/seq-2/ Psalm 46:2

    ## sn82016014/1917-02-01/ed-1/seq-8/ Psalm 4:5

    ## sn85052141/1916-10-12/ed-1/seq-6/ Hebrews 10:23

    ## sn84030186/1861-09-26/ed-1/seq-2/ Luke 2:15

    ## sn84024718/1873-02-11/ed-1/seq-2/ Luke 18:29

    ## sn83021327/1877-05-31/ed-1/seq-2/ Deuteronomy 12:19

    ## sn94060041/1894-03-03/ed-1/seq-1/ Revelation 1:5

    ## sn85038145/1868-07-30/ed-1/seq-1/ Genesis 2:25

    ## sn93061428/1910-10-21/ed-1/seq-1/ Job 12:3

    ## sn88064181/1914-03-06/ed-1/seq-7/ Luke 12:41

    ## sn94060041/1894-03-03/ed-1/seq-1/ Revelation 20:11

    ## sn85025182/1866-01-10/ed-1/seq-2/ 1 Corinthians 5:2

    ## sn84024283/1910-08-11/ed-1/seq-7/ 1 Corinthians 11:31

    ## sn82005159/1858-01-08/ed-1/seq-3/ 1 Thessalonians 5:13

    ## sn84038034/1858-04-29/ed-1/seq-2/ Deuteronomy 1:32

    ## sn83030313/1846-04-05/ed-1/seq-1/ 1 Samuel 25:28

    ## sn86091188/1920-10-15/ed-1/seq-8/ Ezekiel 1:6

    ## sn84020109/1875-03-04/ed-1/seq-1/ Matthew 23:30

    ## sn85038121/1876-07-27/ed-1/seq-4/ Job 42:10

    ## sn84020558/1908-02-10/ed-1/seq-3/ John 21:22

    ## sn84028272/1891-11-25/ed-1/seq-7/ Ephesians 6:12

    ## sn84024718/1873-04-15/ed-1/seq-3/ Nehemiah 7:12

    ## sn83045784/1857-03-21/ed-1/seq-7/ Isaiah 5:6

    ## sn84038034/1858-03-25/ed-1/seq-1/ Psalm 22:11

    ## sn85038158/1876-05-11/ed-1/seq-3/ Ezra 2:28

    ## sn84023209/1867-04-24/ed-1/seq-3/ 2 Corinthians 11:4

    ## sn85038615/1910-11-23/ed-1/seq-9/ Ezekiel 16:47

    ## sn84038582/1874-06-27/ed-1/seq-4/ Hebrews 11:15

    ## sn89066996/1917-09-14/ed-1/seq-5/ Leviticus 7:10

    ## sn84024718/1869-11-09/ed-1/seq-1/ Matthew 6:11

    ## sn83016475/1840-11-14/ed-1/seq-2/ Joshua 9:4

    ## sn83025313/1913-11-21/ed-1/seq-6/ Proverbs 8:11

    ## sn88064181/1914-03-27/ed-1/seq-7/ Luke 12:43

    ## sn82016419/1877-07-27/ed-1/seq-1/ Romans 6:8

    ## sn86083264/1905-09-21/ed-1/seq-3/ 1 Corinthians 9:5

    ## sn85038088/1882-03-09/ed-1/seq-4/ Luke 4:16

    ## sn85042907/1911-05-20/ed-1/seq-2/ John 4:24

    ## sn87070038/1852-04-01/ed-1/seq-2/ Ezra 2:7

    ## sn82005159/1858-12-24/ed-1/seq-2/ Nehemiah 7:38

    ## sn83035143/1865-02-14/ed-1/seq-4/ Psalm 136:1

    ## sn97067613/1901-03-13/ed-1/seq-6/ Proverbs 17:22

    ## sn83032231/1877-12-29/ed-1/seq-1/ Colossians 3:14

    ## sn83016810/1905-04-29/ed-1/seq-9/ Nehemiah 7:41

    ## sn86081895/1901-08-01/ed-1/seq-6/ Zechariah 5:5

    ## sn84024558/1867-02-21/ed-1/seq-3/ Romans 5:1

    ## sn89058370/1899-09-16/ed-1/seq-3/ John 5:3

    ## sn83045462/1860-12-19/ed-1/seq-2/ Jeremiah 42:5

    ## sn85053089/1910-07-22/ed-1/seq-4/ Acts of the Apostles 13:1

    ## sn84024738/1861-04-16/ed-1/seq-4/ Judges 10:2

    ## sn88061071/1890-03-10/ed-1/seq-3/ Job 2:7

    ## sn94049698/1901-03-21/ed-1/seq-2/ John 9:5

    ## sn89066129/1911-06-23/ed-1/seq-6/ John 18:30

    ## sn85038158/1876-12-21/ed-1/seq-3/ Judges 13:23

    ## sn94060041/1890-03-15/ed-1/seq-6/ Luke 14:33

    ## sn85033964/1884-06-12/ed-1/seq-3/ Acts of the Apostles 11:22

    ## sn84026688/1903-02-05/ed-1/seq-1/ Ephesians 2:17

    ## sn85034374/1900-04-21/ed-1/seq-6/ John 1:37

    ## sn82015418/1882-08-26/ed-1/seq-5/ Psalm 22:11

    ## sn87065532/1893-11-10/ed-1/seq-4/ Song of Solomon 8:8

    ## sn86088296/1891-07-16/ed-1/seq-4/ Psalm 34:20

    ## sn86053370/1864-06-22/ed-1/seq-4/ Acts of the Apostles 2:33

    ## sn83030214/1871-12-27/ed-1/seq-2/ Romans 7:25

    ## sn81004761/1869-03-17/ed-1/seq-2/ Matthew 23:30

    ## sn84026403/1863-01-17/ed-1/seq-3/ 1 Kings 19:14

    ## sn89081022/1903-07-29/ed-1/seq-7/ John 17:22

    ## sn84026688/1903-09-17/ed-1/seq-4/ Galatians 6:14

    ## sn86074011/1918-08-30/ed-1/seq-7/ Ezra 2:17

    ## 2010270501/1919-11-13/ed-1/seq-2/ Acts of the Apostles 24:26

    ## sn85027003/1859-12-08/ed-1/seq-2/ 1 Corinthians 5:2

    ## sn86071377/1850-12-26/ed-1/seq-2/ Ezra 2:5

    ## sn84030186/1861-09-26/ed-1/seq-2/ Genesis 42:17

    ## sn85038102/1898-03-11/ed-1/seq-1/ Mark 16:3

    ## sn86069313/1913-06-06/ed-1/seq-3/ Luke 18:13

    ## sn87052143/1882-03-11/ed-1/seq-3/ Job 21:29

    ## sn89066651/1919-08-14/ed-1/seq-1/ Matthew 25:40

    ## sn92053943/1884-07-19/ed-1/seq-1/ Exodus 37:24

    ## sn83016758/1895-08-29/ed-1/seq-2/ 1 Kings 22:42

    ## sn89058154/1922-09-29/ed-1/seq-2/ Isaiah 10:33

    ## sn82014296/1869-07-07/ed-1/seq-1/ 2 Corinthians 13:8

    ## sn86069675/1892-11-22/ed-1/seq-9/ John 15:13

    ## sn84026897/1869-07-07/ed-1/seq-7/ Psalm 129:5

    ## sn84026897/1843-11-29/ed-1/seq-2/ Ezra 2:19

    ## sn86083264/1905-10-19/ed-1/seq-4/ Hosea 10:3

    ## sn84026707/1866-09-20/ed-1/seq-1/ Zechariah 11:10

    ## sn85038145/1873-07-10/ed-1/seq-1/ Ecclesiastes 7:6

    ## sn90061663/1907-07-11/ed-1/seq-1/ Job 27:6

    ## sn83045217/1921-12-19/ed-1/seq-7/ 1 Corinthians 3:16

    ## sn84025841/1896-06-13/ed-1/seq-2/ Psalm 137:6

    ## sn84026853/1878-05-15/ed-1/seq-3/ Proverbs 9:10

    ## sn85042399/1918-03-14/ed-1/seq-6/ Numbers 26:14

    ## sn92070564/1913-05-30/ed-1/seq-1/ Ezra 2:12

    ## sn88064181/1914-02-27/ed-1/seq-7/ Luke 12:34

    ## sn84026912/1878-07-25/ed-1/seq-2/ Proverbs 25:11

    ## sn88064402/1905-12-29/ed-1/seq-2/ Exodus 20:18

    ## sn84028820/1856-12-11/ed-1/seq-1/ 1 Thessalonians 5:21

    ## sn82003410/1846-03-20/ed-1/seq-3/ Nehemiah 7:41

    ## sn84026853/1876-02-23/ed-1/seq-1/ Psalm 105:15

    ## sn85053323/1899-01-21/ed-1/seq-3/ Psalm 106:11

    ## sn84026688/1903-07-23/ed-1/seq-4/ Judges 5:5

    ## sn85052141/1874-08-01/ed-1/seq-2/ Numbers 31:22

    ## sn84026925/1879-07-10/ed-1/seq-1/ Matthew 10:37

    ## sn88085187/1915-10-28/ed-1/seq-5/ Hebrews 6:1

    ## sn87062234/1900-02-06/ed-1/seq-3/ Job 14:1

    ## sn83035487/1845-11-14/ed-1/seq-3/ Isaiah 1:16

    ## sn83016925/1887-03-30/ed-1/seq-4/ Genesis 7:1

    ## sn83045462/1886-01-16/ed-1/seq-5/ Judges 10:2

    ## sn91068402/1891-01-15/ed-1/seq-3/ Numbers 20:17

    ## sn83004710/1915-05-21/ed-1/seq-4/ 2 Samuel 1:23

    ## sn97071110/1904-09-08/ed-1/seq-4/ 1 Corinthians 12:19

    ## sn87052128/1878-07-05/ed-1/seq-7/ Luke 10:8

    ## sn82003410/1846-12-01/ed-1/seq-2/ Deuteronomy 1:17

    ## sn83045462/1860-10-29/ed-1/seq-1/ Habakkuk 2:20

    ## sn89058354/1916-03-31/ed-1/seq-1/ Nehemiah 2:1

    ## sn84024718/1869-06-29/ed-1/seq-1/ Matthew 18:9

    ## sn83045784/1857-10-17/ed-1/seq-3/ Nehemiah 7:34

    ## sn2006060001/1892-02-05/ed-1/seq-6/ Numbers 36:4

    ## sn84026788/1900-03-06/ed-1/seq-1/ Proverbs 31:31

    ## sn85034248/1904-08-20/ed-1/seq-6/ Hebrews 11:6

    ## sn84024735/1852-10-12/ed-1/seq-2/ 1 John 1:3

    ## sn84024518/1852-04-10/ed-1/seq-2/ Nehemiah 7:44

    ## sn85042414/1921-11-24/ed-1/seq-1/ Deuteronomy 32:15

    ## sn86063662/1884-07-10/ed-1/seq-2/ Luke 6:24

    ## sn84025891/1894-06-09/ed-1/seq-4/ Job 27:6

    ## sn84026900/1854-07-19/ed-1/seq-1/ Psalm 84:11

    ## sn85025431/1890-07-30/ed-1/seq-2/ Judges 10:2

    ## sn85038158/1876-08-17/ed-1/seq-3/ Psalm 83:4

    ## sn84026399/1855-10-25/ed-1/seq-1/ Job 38:11

    ## sn84024283/1888-04-26/ed-1/seq-7/ Mark 12:33

    ## sn85038523/1863-01-05/ed-1/seq-2/ Acts of the Apostles 7:5

    ## sn84028820/1856-11-06/ed-1/seq-1/ Jeremiah 38:5

    ## sn86088296/1891-11-19/ed-1/seq-8/ Romans 7:1

    ## sn85042399/1918-03-14/ed-1/seq-6/ Nehemiah 7:34

    ## sn83035595/1867-01-18/ed-1/seq-1/ 2 Kings 3:8

    ## sn85038158/1876-05-11/ed-1/seq-3/ 2 Corinthians 13:8

    ## sn83025186/1903-05-08/ed-1/seq-2/ 1 Samuel 10:27

    ## 2010270501/1903-12-11/ed-1/seq-6/ Luke 2:11

    ## sn88076514/1889-02-16/ed-1/seq-4/ 2 Samuel 13:22

    ## sn97067613/1889-08-29/ed-1/seq-4/ 1 Samuel 17:42

    ## sn94060041/1894-03-03/ed-1/seq-1/ Revelation 1:6

    ## sn83004710/1915-05-21/ed-1/seq-4/ 1 Kings 4:1

    ## sn89058007/1895-01-11/ed-1/seq-4/ Amos 3:10

    ## sn98069867/1919-08-29/ed-1/seq-7/ Daniel 1:8

    ## sn86061215/1912-06-01/ed-1/seq-4/ Romans 6:1

    ## sn89058007/1903-09-04/ed-1/seq-1/ Matthew 11:4

    ## sn84026688/1903-02-05/ed-1/seq-1/ 2 Corinthians 8:12

    ## sn85066387/1901-07-19/ed-1/seq-3/ Genesis 44:1

    ## sn82015486/1865-05-11/ed-1/seq-1/ Job 28:1

    ## sn89080032/1850-06-04/ed-1/seq-1/ Lamentations 2:16

    ## sn87052181/1875-07-22/ed-1/seq-6/ Proverbs 19:24

    ## sn85038088/1882-03-09/ed-1/seq-2/ Proverbs 28:22

    ## sn86086632/1898-04-16/ed-1/seq-7/ Matthew 17:1

    ## sn83035487/1861-04-27/ed-1/seq-2/ Jeremiah 7:3

    ## sn84026925/1892-08-10/ed-1/seq-1/ Luke 19:10

    ## sn89081022/1908-06-03/ed-1/seq-8/ Ezekiel 17:24

    ## sn82007642/1917-12-20/ed-1/seq-2/ Numbers 13:32

    ## sn86063778/1909-02-04/ed-1/seq-4/ Deuteronomy 1:17

    ## sn88064327/1902-02-22/ed-1/seq-1/ Nehemiah 7:12

    ## sn85033781/1896-02-26/ed-1/seq-6/ Matthew 10:39

    ## sn82016419/1874-06-19/ed-1/seq-1/ Matthew 16:7

    ## sn83045784/1863-02-05/ed-1/seq-4/ 1 John 3:14

    ## sn83016872/1849-06-16/ed-1/seq-3/ Matthew 7:20

    ## sn2006060001/1888-06-14/ed-1/seq-3/ Matthew 28:18

    ## sn88064454/1908-09-12/ed-1/seq-4/ Numbers 26:14

    ## sn93067656/1883-11-23/ed-1/seq-1/ 1 Timothy 1:10

    ## sn85034235/1910-12-29/ed-1/seq-4/ Luke 17:15

    ## sn82014086/1916-03-03/ed-1/seq-8/ Acts of the Apostles 11:22

    ## sn83016475/1840-07-16/ed-1/seq-2/ Galatians 3:21

    ## sn84029386/1911-09-28/ed-1/seq-12/ 1 Kings 19:20

    ## sn82015679/1894-08-28/ed-1/seq-3/ Exodus 9:2

    ## sn86061215/1912-06-01/ed-1/seq-4/ James 1:18

    ## sn87062234/1900-06-12/ed-1/seq-5/ Genesis 43:7

    ## sn85038158/1877-03-01/ed-1/seq-2/ 1 Samuel 5:8

    ## sn85034235/1910-01-13/ed-1/seq-1/ Mark 8:24

    ## sn84028820/1856-08-21/ed-1/seq-4/ Hebrews 11:15

    ## sn85038115/1873-02-25/ed-1/seq-2/ Psalm 19:14

    ## sn87090373/1884-09-19/ed-1/seq-1/ 2 John 1:8

    ## sn96090259/1908-01-24/ed-1/seq-1/ 2 Kings 8:17

    ## sn83016925/1887-03-30/ed-1/seq-4/ John 3:15

    ## sn85050913/1912-08-06/ed-1/seq-2/ Ezra 2:33

    ## sn84026788/1867-07-09/ed-1/seq-4/ Mark 8:36

    ## sn95077631/1894-09-12/ed-1/seq-4/ Nehemiah 7:10

    ## sn90059228/1881-04-13/ed-1/seq-3/ Romans 4:1

    ## sn94052320/1914-12-18/ed-1/seq-1/ Luke 2:14

    ## sn87008085/1909-04-29/ed-1/seq-4/ Genesis 3:4

    ## sn84026688/1903-01-29/ed-1/seq-1/ Hebrews 9:14

    ## sn85034248/1906-09-08/ed-1/seq-2/ Psalm 106:11

    ## sn86069620/1899-02-09/ed-1/seq-4/ Revelation 22:16

    ## sn86063790/1917-10-04/ed-1/seq-4/ Ecclesiastes 2:13

    ## sn85038158/1877-08-30/ed-1/seq-4/ Proverbs 11:25

    ## sn86053569/1838-02-03/ed-1/seq-3/ John 12:39

    ## sn82015485/1917-12-20/ed-1/seq-4/ Matthew 25:40

    ## sn83025661/1840-11-25/ed-1/seq-1/ Hebrews 9:28

    ## sn93051669/1898-05-17/ed-1/seq-18/ Acts of the Apostles 10:47

    ## sn83025661/1840-01-01/ed-1/seq-2/ Revelation 11:6

    ## sn85025431/1898-12-07/ed-1/seq-5/ 2 Chronicles 26:12

    ## sn83035143/1865-02-14/ed-1/seq-4/ Psalm 118:1

    ## sn85034357/1918-07-12/ed-1/seq-2/ Matthew 17:9

    ## sn85025620/1900-08-24/ed-1/seq-7/ Deuteronomy 28:32

    ## sn84038125/1876-07-14/ed-1/seq-1/ Proverbs 14:34

    ## sn87078321/1893-10-11/ed-1/seq-2/ Ezekiel 1:6

    ## sn84024735/1852-10-12/ed-1/seq-2/ Hebrews 4:2

    ## sn84022644/1876-06-02/ed-1/seq-1/ Luke 5:9

    ## sn94060041/1890-03-15/ed-1/seq-6/ Acts of the Apostles 9:6

    ## sn86063579/1921-12-27/ed-1/seq-4/ Genesis 26:32

    ## sn83016925/1887-07-06/ed-1/seq-4/ 1 Corinthians 1:27

    ## sn86061215/1912-06-01/ed-1/seq-4/ Romans 6:2

    ## sn86069620/1899-03-02/ed-1/seq-4/ Luke 10:32

    ## sn82014899/1873-09-20/ed-1/seq-1/ Romans 13:3

    ## sn87075048/1900-09-27/ed-1/seq-6/ Luke 1:50

    ## sn89074274/1918-04-25/ed-1/seq-2/ Psalm 135:17

    ## sn88064176/1900-07-21/ed-1/seq-3/ Exodus 28:15

    ## sn85025182/1866-01-17/ed-1/seq-3/ Ezra 2:33

    ## sn84026900/1854-07-26/ed-1/seq-1/ Deuteronomy 20:8

    ## sn85033386/1873-01-17/ed-1/seq-1/ Matthew 18:10

    ## sn85032801/1893-03-03/ed-1/seq-10/ Genesis 26:23

    ## sn83045784/1864-09-08/ed-1/seq-2/ Nehemiah 7:37

    ## sn88085460/1901-07-12/ed-1/seq-4/ Numbers 31:53

    ## sn85032938/1895-03-13/ed-1/seq-2/ Hosea 2:15

    ## sn85042588/1889-03-29/ed-1/seq-2/ Mark 10:15

    ## sn93067841/1917-04-12/ed-1/seq-6/ Jeremiah 30:22

    ## sn94060041/1890-03-15/ed-1/seq-6/ Luke 5:11

    ## sn83045217/1921-12-19/ed-1/seq-7/ Luke 2:7

    ## sn83004710/1895-09-10/ed-1/seq-2/ 2 Timothy 4:6

    ## sn88064020/1921-07-14/ed-1/seq-2/ 2 Samuel 11:25

    ## sn83021327/1883-02-15/ed-1/seq-2/ Matthew 25:42

    ## sn94060041/1890-03-15/ed-1/seq-6/ Matthew 4:19

    ## sn2006060001/1888-06-14/ed-1/seq-3/ Matthew 28:17

    ## sn85034235/1910-12-29/ed-1/seq-4/ Luke 12:40

    ## sn84038125/1876-10-27/ed-1/seq-3/ Ezra 2:7

    ## sn86089977/1907-01-26/ed-1/seq-3/ 1 Samuel 20:31

    ## sn84027691/1874-01-29/ed-1/seq-2/ 1 Timothy 6:16

    ## sn83035487/1845-11-14/ed-1/seq-3/ Isaiah 1:11

    ## sn88085770/1916-05-11/ed-1/seq-2/ Galatians 3:21

    ## sn85053121/1914-09-25/ed-1/seq-3/ John 18:30

    ## sn82014434/1853-06-27/ed-1/seq-4/ Psalm 72:7

    ## sn88076514/1889-03-09/ed-1/seq-4/ Luke 14:4

    ## sn82016187/1910-07-07/ed-1/seq-4/ Deuteronomy 31:13

    ## sn83016475/1840-07-01/ed-1/seq-4/ Psalm 104:33

    ## sn92053945/1889-10-21/ed-1/seq-4/ 1 Chronicles 12:26

    ## sn85034235/1883-11-01/ed-1/seq-2/ 2 Corinthians 10:9

    ## sn85034374/1900-08-11/ed-1/seq-7/ Matthew 25:23

    ## sn86053569/1838-11-24/ed-1/seq-1/ Philippians 3:16

    ## sn84024716/1908-10-14/ed-1/seq-4/ Titus 3:4

    ## sn84026853/1886-04-28/ed-1/seq-1/ 1 Corinthians 1:22

    ## sn85033781/1876-10-20/ed-1/seq-7/ Psalm 135:8

    ## sn85033781/1876-07-21/ed-1/seq-3/ Matthew 24:41

    ## sn85025007/1860-08-27/ed-1/seq-2/ Mark 8:21

    ## sn82015015/1842-07-30/ed-1/seq-4/ Luke 1:62

    ## sn84026749/1920-09-17/ed-1/seq-19/ Ephesians 3:12

    ## sn84028820/1856-11-06/ed-1/seq-1/ Matthew 13:46

    ## sn97067613/1889-08-29/ed-1/seq-4/ Ezekiel 37:28

    ## sn84036256/1921-09-02/ed-1/seq-2/ 2 Thessalonians 3:18

    ## sn84026526/1860-11-16/ed-1/seq-3/ Romans 7:19

    ## sn90061783/1909-08-12/ed-1/seq-7/ Acts of the Apostles 18:27

    ## sn84026912/1851-02-01/ed-1/seq-3/ Psalm 145:18

    ## sn83040592/1919-03-28/ed-1/seq-6/ Revelation 21:2

    ## sn86064239/1915-10-29/ed-1/seq-8/ Isaiah 28:15

    ## sn84025890/1883-02-17/ed-1/seq-1/ Genesis 5:18

    ## sn83040198/1903-10-16/ed-1/seq-6/ Luke 4:16

    ## sn84024718/1873-02-11/ed-1/seq-2/ 1 Chronicles 16:36

    ## sn92065637/1896-06-24/ed-1/seq-5/ Genesis 37:28

    ## sn90061663/1903-02-26/ed-1/seq-4/ 1 Timothy 1:8

    ## sn87065532/1893-08-18/ed-1/seq-1/ Deuteronomy 12:21

    ## sn83045433/1918-02-01/ed-1/seq-8/ John 7:17

    ## sn84020109/1875-02-25/ed-1/seq-1/ 2 Corinthians 10:9

    ## sn84027621/1900-11-16/ed-1/seq-3/ Luke 19:10

    ## sn86069620/1897-03-04/ed-1/seq-2/ Isaiah 40:31

    ## sn86063623/1901-07-27/ed-1/seq-2/ Deuteronomy 31:13

    ## sn89074109/1907-12-26/ed-1/seq-3/ Acts of the Apostles 21:33

    ## sn85026050/1864-11-04/ed-1/seq-1/ Psalm 39:8

    ## sn83045784/1857-10-10/ed-1/seq-2/ Proverbs 25:25

    ## sn88085460/1901-07-12/ed-1/seq-4/ Matthew 26:9

    ## sn85033681/1875-01-06/ed-1/seq-4/ Esther 2:6

    ## sn84023963/1909-05-28/ed-1/seq-2/ James 2:16

    ## sn84026788/1898-06-21/ed-1/seq-2/ Judges 18:9

    ## sn95079154/1911-04-06/ed-1/seq-2/ Luke 24:31

    ## sn85025182/1866-01-31/ed-1/seq-1/ Mark 3:20

    ## sn84024716/1908-03-25/ed-1/seq-4/ Proverbs 8:35

    ## sn84024558/1856-04-19/ed-1/seq-2/ Psalm 49:20

    ## sn84026788/1900-03-06/ed-1/seq-1/ Proverbs 31:30

    ## sn89058007/1903-10-02/ed-1/seq-4/ Psalm 126:6

    ## sn84021912/1897-03-13/ed-1/seq-1/ Genesis 2:8

    ## sn84026853/1886-04-28/ed-1/seq-1/ Romans 8:34

    ## sn84026925/1892-02-24/ed-1/seq-4/ Nehemiah 7:20

    ## sn84026853/1876-10-18/ed-1/seq-4/ Jeremiah 48:34

    ## sn85033781/1896-02-26/ed-1/seq-6/ Luke 9:23

    ## sn84024718/1873-02-04/ed-1/seq-3/ Mark 4:26

    ## sn83016474/1840-04-02/ed-1/seq-1/ Isaiah 1:22

    ## sn93067659/1904-09-28/ed-1/seq-7/ Matthew 11:25

    ## sn93061777/1916-07-21/ed-1/seq-7/ Numbers 8:16

    ## sn83035487/1845-11-21/ed-1/seq-2/ James 1:8

    ## sn97067613/1889-02-14/ed-1/seq-2/ Matthew 25:21

    ## sn85033681/1875-04-14/ed-1/seq-1/ Ezra 2:10

    ## sn83016474/1840-04-02/ed-1/seq-1/ Isaiah 1:25

    ## sn92065637/1896-06-24/ed-1/seq-4/ Matthew 9:12

    ## sn85052141/1874-07-18/ed-1/seq-1/ Matthew 12:16

    ## sn85033781/1895-04-19/ed-1/seq-7/ Ezra 2:31

    ## sn85025620/1900-06-29/ed-1/seq-2/ Luke 17:10

    ## sn78000395/1916-04-22/ed-1/seq-6/ Zechariah 14:9

    ## sn83026389/1867-07-27/ed-2/seq-2/ Matthew 5:46

    ## sn83035487/1845-11-14/ed-1/seq-3/ Isaiah 1:13

    ## sn86069867/1899-12-10/ed-1/seq-4/ James 5:15

    ## sn85025182/1866-01-03/ed-1/seq-1/ Ecclesiastes 3:11

    ## sn82015015/1842-03-24/ed-1/seq-4/ Nehemiah 7:17

    ## sn84020104/1853-10-27/ed-1/seq-3/ Psalm 148:12

    ## sn84020712/1861-03-05/ed-1/seq-1/ 2 Samuel 5:4

    ## sn96086441/1889-04-26/ed-1/seq-3/ Job 30:16

    ## sn84020109/1875-12-02/ed-1/seq-1/ Mark 6:19

    ## sn88064020/1914-06-11/ed-1/seq-3/ Ezra 7:25

    ## sn84038125/1876-02-18/ed-1/seq-3/ 1 John 5:21

    ## sn97067613/1889-04-04/ed-1/seq-4/ Psalm 89:48

    ## sn86083264/1905-01-05/ed-1/seq-2/ 2 Kings 11:21

    ## sn85038119/1894-09-27/ed-1/seq-1/ 2 Timothy 1:6

    ## sn85033395/1861-10-03/ed-1/seq-4/ Leviticus 13:2

    ## sn87056600/1884-11-12/ed-1/seq-2/ Luke 8:19

    ## sn84024720/1907-11-29/ed-1/seq-2/ Proverbs 1:29

    ## sn97067613/1889-02-14/ed-1/seq-2/ Matthew 25:23

    ## sn85033781/1896-02-26/ed-1/seq-6/ 1 Corinthians 15:4

    ## sn82015080/1881-11-03/ed-1/seq-1/ Judges 10:2

    ## sn87090131/1919-05-30/ed-1/seq-3/ 1 Corinthians 11:16

    ## sn89074274/1918-02-21/ed-1/seq-3/ Mark 6:31

    ## sn82015485/1890-06-28/ed-1/seq-1/ 1 Thessalonians 4:2

    ## sn84022278/1873-05-03/ed-1/seq-2/ Ezekiel 48:17

    ## sn82014086/1916-05-24/ed-1/seq-4/ 2 Samuel 17:12

    ## sn89067274/1886-08-19/ed-1/seq-2/ Luke 24:50

    ## sn84026403/1863-05-16/ed-1/seq-2/ Mark 6:44

    ## sn85025431/1890-12-03/ed-1/seq-2/ Numbers 9:6

    ## sn84026497/1889-05-22/ed-1/seq-6/ 1 Thessalonians 4:5

    ## sn94060041/1894-03-03/ed-1/seq-1/ 1 Peter 5:11

    ## sn89055113/1900-10-01/ed-1/seq-1/ Jeremiah 15:10

    ## sn84026909/1874-02-11/ed-1/seq-4/ Luke 14:17

    ## sn85042147/1842-03-02/ed-1/seq-4/ Psalm 14:1

    ## sn85038121/1876-03-30/ed-1/seq-4/ Isaiah 51:23

    ## sn85038119/1894-09-27/ed-1/seq-1/ John 11:32

    ## sn84026853/1886-04-28/ed-1/seq-1/ Job 19:26

    ## sn89074109/1907-12-12/ed-1/seq-6/ Psalm 22:11

    ## sn87056243/1901-06-20/ed-1/seq-1/ 1 Corinthians 15:15

    ## sn89058128/1891-08-13/ed-1/seq-7/ 1 Thessalonians 5:21

    ## sn84038582/1879-03-22/ed-1/seq-4/ Genesis 44:26

    ## sn84020109/1875-01-07/ed-1/seq-1/ Job 14:1

    ## sn85026941/1898-06-24/ed-1/seq-1/ Judges 16:25

    ## sn85033781/1896-02-26/ed-1/seq-6/ Mark 8:28

    ## sn83021327/1883-02-01/ed-1/seq-2/ Psalm 107:31

    ## sn89081022/1896-04-07/ed-1/seq-6/ Jeremiah 50:27

    ## sn84026909/1874-08-19/ed-2/seq-1/ Luke 8:47

    ## sn85038115/1882-12-26/ed-1/seq-3/ Luke 2:13

    ## sn87052128/1878-07-19/ed-1/seq-7/ Psalm 22:11

    ## sn84036256/1921-09-02/ed-1/seq-2/ Psalm 34:7

    ## sn90061783/1909-10-21/ed-1/seq-4/ Deuteronomy 5:26

    ## sn83045784/1857-10-17/ed-1/seq-4/ Job 4:8

    ## sn86061215/1912-08-20/ed-1/seq-3/ Hebrews 2:1

    ## sn91068415/1919-10-09/ed-1/seq-1/ Philippians 4:8

    ## sn87065296/1839-09-21/ed-1/seq-1/ Mark 14:5

    ## sn91068084/1889-06-28/ed-1/seq-4/ Revelation 17:2

    ## sn95060791/1921-07-08/ed-1/seq-2/ Matthew 26:72

    ## sn97067613/1889-12-12/ed-1/seq-3/ Colossians 3:19

    ## sn92070405/1899-01-20/ed-1/seq-2/ John 11:29

    ## sn93067846/1911-12-20/ed-1/seq-3/ Malachi 3:17

    ## sn94052364/1890-05-03/ed-1/seq-2/ Matthew 26:70

    ## sn84024718/1869-06-29/ed-1/seq-1/ John 9:4

    ## sn83016926/1881-10-13/ed-1/seq-3/ Joshua 23:8

    ## sn84022644/1876-01-28/ed-1/seq-1/ Matthew 18:16

    ## sn85038158/1877-09-20/ed-1/seq-2/ 1 Samuel 25:34

    ## sn85042588/1889-03-29/ed-1/seq-2/ Romans 10:3

    ## sn85026050/1854-07-21/ed-1/seq-4/ Numbers 26:14

    ## sn83045462/1860-07-07/ed-1/seq-1/ Song of Solomon 4:12

    ## sn85033386/1873-05-30/ed-1/seq-2/ Acts of the Apostles 23:13

    ## sn90059180/1898-01-28/ed-1/seq-3/ Matthew 28:17

    ## sn84026688/1903-10-29/ed-1/seq-1/ Revelation 1:2

    ## sn84020109/1875-01-21/ed-1/seq-2/ Deuteronomy 20:8

    ## sn85026050/1864-08-12/ed-1/seq-3/ Nehemiah 7:20

    ## sn83040340/1880-02-06/ed-1/seq-4/ Psalm 113:2

    ## sn85053148/1880-03-05/ed-1/seq-2/ Matthew 26:72

    ## sn83016632/1879-07-05/ed-1/seq-2/ 1 John 4:16

    ## sn94060041/1907-10-19/ed-1/seq-2/ 2 Timothy 4:6

    ## sn84024443/1850-08-02/ed-1/seq-1/ Numbers 3:28

    ## sn89066163/1866-08-24/ed-1/seq-1/ Nehemiah 7:22

    ## sn90061308/1917-04-27/ed-1/seq-5/ 1 Chronicles 12:26

    ## sn86064259/1911-02-10/ed-1/seq-5/ John 6:11

    ## sn82014689/1906-01-20/ed-1/seq-2/ Ephesians 3:12

    ## sn89058370/1887-10-05/ed-1/seq-3/ Matthew 5:10

    ## sn86063381/1908-03-25/ed-1/seq-4/ Genesis 3:7

    ## 2013271051/1890-01-18/ed-1/seq-4/ Habakkuk 2:17

    ## sn86069873/1907-07-05/ed-1/seq-5/ Job 3:11

    ## sn84026707/1866-09-06/ed-1/seq-1/ Ezekiel 40:6

    ## sn85038158/1876-04-20/ed-1/seq-2/ Luke 24:42

    ## sn82015015/1842-08-13/ed-1/seq-4/ Ezekiel 47:14

    ## sn85038102/1907-04-19/ed-1/seq-6/ Luke 22:11

    ## sn89064939/1887-04-06/ed-1/seq-1/ Galatians 6:7

    ## sn85025007/1860-08-20/ed-1/seq-2/ Mark 1:42

    ## sn85042623/1875-09-08/ed-1/seq-4/ Jeremiah 32:23

    ## sn84024716/1908-08-19/ed-1/seq-4/ 1 Samuel 20:33

    ## sn82015486/1865-05-04/ed-1/seq-1/ Genesis 26:23

    ## sn86088529/1886-05-21/ed-1/seq-7/ John 9:5

    ## sn85032801/1893-09-29/ed-1/seq-1/ Acts of the Apostles 21:26

    ## sn85025007/1860-05-23/ed-1/seq-5/ Luke 3:12

    ## sn88064384/1916-02-05/ed-1/seq-6/ Numbers 26:14

    ## sn88061082/1884-04-05/ed-1/seq-1/ 1 Samuel 30:4

    ## sn84023127/1856-04-25/ed-1/seq-3/ Numbers 33:39

    ## sn87056250/1895-12-18/ed-1/seq-6/ Psalm 7:5

    ## sn85042460/1888-01-12/ed-1/seq-1/ Matthew 21:17

    ## sn87052128/1878-04-05/ed-1/seq-6/ Genesis 3:23

    ## sn87052181/1875-07-08/ed-1/seq-5/ 2 Corinthians 10:3

    ## sn84026912/1879-12-25/ed-1/seq-1/ Jeremiah 11:5

    ## sn86081895/1901-08-01/ed-1/seq-6/ Genesis 13:1

    ## sn88064537/1892-07-02/ed-1/seq-3/ Psalm 9:17

    ## sn84022835/1904-09-16/ed-1/seq-12/ Galatians 4:1

    ## sn86069873/1900-12-14/ed-1/seq-5/ Psalm 135:8

    ## sn96088004/1920-12-22/ed-1/seq-1/ Isaiah 65:12

    ## sn85033306/1888-03-23/ed-1/seq-1/ James 2:20

    ## sn85052141/1885-07-17/ed-1/seq-1/ Mark 12:8

    ## sn83035312/1844-05-28/ed-1/seq-1/ Deuteronomy 3:20

    ## sn94055463/1901-01-17/ed-1/seq-4/ Matthew 18:25

    ## sn84023963/1889-06-14/ed-1/seq-6/ Ezekiel 48:17

    ## sn82014593/1852-07-13/ed-1/seq-1/ Jeremiah 10:7

    ## sn85050913/1914-11-03/ed-1/seq-1/ John 9:4

    ## sn86086632/1898-02-26/ed-1/seq-7/ John 3:35

    ## sn82016413/1905-08-23/ed-1/seq-3/ Job 19:23

    ## sn86069309/1904-12-21/ed-1/seq-8/ Exodus 6:7

    ## sn86061215/1912-06-01/ed-1/seq-4/ Romans 9:14

    ## sn86053067/1869-07-22/ed-1/seq-1/ Mark 15:30

    ## sn84026817/1877-03-08/ed-1/seq-3/ Romans 7:17

    ## sn85026941/1898-06-03/ed-1/seq-1/ Leviticus 14:5

    ## sn87075163/1860-01-12/ed-1/seq-3/ Ezra 2:17

    ## sn85033637/1878-12-10/ed-1/seq-1/ Matthew 6:26

    ## sn86063823/1906-11-06/ed-1/seq-2/ Deuteronomy 14:12

    ## sn84026925/1892-08-10/ed-1/seq-1/ Luke 2:47

    ## sn84023209/1867-12-25/ed-1/seq-4/ Luke 9:13

    ## 2010270511/1893-06-25/ed-1/seq-1/ Ezekiel 3:6

    ## sn86069313/1913-12-19/ed-1/seq-6/ Luke 12:28

    ## sn85038102/1912-08-02/ed-1/seq-2/ 2 Peter 3:13

    ## sn84038628/1866-10-03/ed-1/seq-2/ Exodus 10:11

    ## sn83032199/1867-02-07/ed-1/seq-1/ Numbers 25:9

    ## sn83030272/1899-04-23/ed-1/seq-21/ Leviticus 14:48

    ## sn84024082/1862-07-29/ed-1/seq-2/ Nehemiah 7:16

    ## sn92070405/1899-04-14/ed-1/seq-3/ Job 20:13

    ## sn88085523/1901-03-28/ed-1/seq-5/ Colossians 3:14

    ## sn90059522/1891-03-02/ed-1/seq-4/ Acts of the Apostles 10:11

    ## sn91068402/1911-01-05/ed-1/seq-2/ Nehemiah 7:12

    ## sn85033395/1861-03-14/ed-1/seq-4/ John 14:14

    ## sn84026409/1892-06-22/ed-1/seq-2/ Mark 14:57

    ## sn85026050/1866-02-09/ed-1/seq-4/ Deuteronomy 12:19

    ## sn85034357/1901-04-12/ed-1/seq-1/ Luke 21:1

    ## sn94051044/1867-12-13/ed-1/seq-4/ Isaiah 11:6

    ## sn84026536/1868-07-10/ed-1/seq-5/ Psalm 72:3

    ## sn85026050/1864-11-04/ed-1/seq-1/ Nehemiah 7:69

    ## sn88064384/1903-08-08/ed-1/seq-1/ Deuteronomy 20:8

    ## sn82016187/1910-01-13/ed-1/seq-4/ Proverbs 6:7

    ## sn85034235/1910-12-29/ed-1/seq-4/ Luke 17:8

    ## sn86086632/1898-04-16/ed-1/seq-7/ Matthew 17:8

    ## sn86053712/1867-05-29/ed-1/seq-2/ Psalm 124:2

    ## sn84022770/1883-02-16/ed-1/seq-1/ Luke 18:11

    ## sn85034438/1894-08-31/ed-1/seq-4/ Acts of the Apostles 28:15

    ## sn84024779/1886-08-05/ed-1/seq-8/ Matthew 26:9

    ## sn88064250/1892-01-30/ed-1/seq-2/ Luke 12:27

    ## sn84038125/1876-02-18/ed-1/seq-3/ Isaiah 1:3

    ## sn89058133/1919-12-04/ed-1/seq-4/ Ezra 2:12

    ## sn83016810/1905-07-08/ed-1/seq-2/ Daniel 5:25

    ## sn85033673/1867-10-10/ed-1/seq-2/ Mark 8:21

    ## sn78000395/1916-11-25/ed-1/seq-5/ Nehemiah 7:17

    ## sn85033429/1869-08-26/ed-1/seq-4/ 1 John 1:1

    ## sn84025828/1908-04-25/ed-1/seq-6/ Lamentations 5:6

    ## sn87056248/1860-08-16/ed-1/seq-1/ Leviticus 25:37

    ## sn83025661/1840-09-23/ed-1/seq-3/ Hebrews 4:2

    ## sn86053573/1873-07-14/ed-1/seq-3/ Ezra 1:11

    ## sn84026788/1867-05-21/ed-1/seq-3/ Romans 12:18

    ## sn83016475/1840-05-30/ed-1/seq-2/ Job 21:5

    ## sn85025007/1860-08-31/ed-1/seq-1/ Numbers 26:14

    ## sn88064181/1914-09-18/ed-1/seq-7/ Ephesians 3:12

    ## sn84023416/1892-04-29/ed-1/seq-1/ Genesis 44:26

    ## sn86063758/1918-07-05/ed-1/seq-8/ 2 Corinthians 11:4

    ## sn82014635/1896-04-11/ed-1/seq-2/ Exodus 4:23

    ## sn94060041/1894-08-25/ed-1/seq-1/ John 1:3

    ## sn82015485/1890-06-07/ed-1/seq-5/ Joshua 2:11

    ## sn89058248/1895-01-17/ed-1/seq-1/ Psalm 35:14

    ## sn84020109/1875-08-05/ed-1/seq-4/ Acts of the Apostles 19:21

    ## sn89058154/1922-11-24/ed-1/seq-2/ Luke 4:14

    ## sn86063615/1899-11-12/ed-1/seq-21/ Nehemiah 7:34

    ## 45043535/1895-04-01/ed-1/seq-11/ 2 Kings 11:21

    ## sn84022770/1883-01-26/ed-1/seq-2/ Psalm 106:11

    ## sn85053148/1880-08-20/ed-1/seq-3/ John 18:10

    ## sn83045706/1858-12-15/ed-1/seq-4/ Nehemiah 7:38

    ## sn83016884/1840-02-25/ed-1/seq-4/ Isaiah 13:17

    ## sn88076514/1889-03-02/ed-1/seq-4/ Luke 17:10

    ## sn94056415/1887-04-07/ed-1/seq-6/ Mark 10:40

    ## sn83040198/1903-01-02/ed-1/seq-2/ Philippians 3:13

    ## sn90061308/1917-01-05/ed-1/seq-2/ 2 Kings 22:19

    ## sn85033386/1873-06-27/ed-1/seq-1/ 2 Samuel 11:25

    ## sn85042588/1889-03-29/ed-1/seq-2/ Mark 10:13

    ## sn96090259/1908-11-13/ed-1/seq-4/ Ezra 10:9

    ## sn90061663/1903-12-31/ed-1/seq-4/ Exodus 16:22

    ## sn93055779/1908-02-17/ed-1/seq-8/ Proverbs 14:34

    ## sn84022770/1899-04-28/ed-1/seq-3/ Ezra 8:30

    ## sn84027691/1874-02-26/ed-1/seq-2/ Ezekiel 24:22

    ## sn88085488/1889-11-09/ed-1/seq-4/ Psalm 78:70

    ## sn84022835/1904-04-15/ed-1/seq-3/ Revelation 16:20

    ## sn84026688/1903-03-05/ed-1/seq-4/ Luke 7:22

    ## sn85032575/1883-10-04/ed-1/seq-6/ John 9:5

    ## sn93067853/1901-02-15/ed-1/seq-1/ Psalm 84:10

    ## sn85033781/1874-05-15/ed-1/seq-8/ Nehemiah 7:36

    ## sn84024718/1864-01-26/ed-1/seq-2/ Obadiah 1:18

    ## sn86088572/1913-04-24/ed-1/seq-4/ 1 Corinthians 14:37

    ## sn84026688/1903-01-29/ed-1/seq-1/ Genesis 15:11

    ## sn85038115/1885-03-17/ed-1/seq-2/ 2 Corinthians 9:9

    ## sn83032058/1873-05-15/ed-1/seq-3/ Luke 18:16

    ## sn83016925/1887-06-15/ed-1/seq-4/ Acts of the Apostles 7:58

    ## sn86090049/1903-09-23/ed-1/seq-8/ Matthew 26:9

    ## sn83035143/1865-02-14/ed-1/seq-4/ Psalm 105:1

    ## sn94051044/1867-11-22/ed-1/seq-2/ Jeremiah 25:8

    ## sn86069867/1899-12-10/ed-1/seq-4/ 1 Kings 14:14

    ## sn85033781/1896-02-26/ed-1/seq-6/ Matthew 16:17

    ## sn85038119/1894-09-27/ed-1/seq-1/ John 11:21

    ## sn85034039/1866-10-19/ed-1/seq-1/ Ecclesiastes 2:13

    ## sn85038145/1875-01-28/ed-1/seq-1/ Numbers 26:14

    ## sn85038088/1882-05-18/ed-1/seq-1/ Matthew 6:9

    ## sn85042588/1889-03-29/ed-1/seq-2/ Mark 10:24

    ## sn94060041/1905-04-01/ed-1/seq-1/ Luke 13:3

    ## sn89058248/1897-11-26/ed-1/seq-2/ Matthew 2:16

    ## sn95047324/1922-07-21/ed-1/seq-3/ 1 Chronicles 12:30

    ## sn86053370/1864-01-13/ed-1/seq-2/ John 12:39

    ## sn91068402/1911-02-09/ed-1/seq-2/ Luke 3:18

    ## sn89058370/1887-10-05/ed-1/seq-3/ Genesis 41:41

    ## sn84024718/1864-04-26/ed-1/seq-1/ Acts of the Apostles 23:27

    ## sn84026853/1878-05-15/ed-1/seq-3/ 2 John 1:5

    ## sn84022687/1847-02-11/ed-1/seq-4/ Deuteronomy 10:16

    ## sn85025584/1858-06-24/ed-1/seq-3/ 1 Corinthians 5:6

    ## sn85033781/1895-10-25/ed-1/seq-6/ Psalm 103:8

    ## sn86079088/1873-10-18/ed-1/seq-2/ Malachi 3:16

    ## sn83025121/1918-04-16/ed-1/seq-3/ Acts of the Apostles 6:10

    ## sn82016187/1911-02-02/ed-1/seq-8/ Psalm 124:2

    ## sn85033386/1873-11-21/ed-1/seq-1/ Mark 9:6

    ## sn84025811/1900-07-06/ed-1/seq-3/ Matthew 5:39

    ## sn86081895/1901-08-01/ed-1/seq-6/ Genesis 13:6

    ## sn84026925/1892-01-13/ed-1/seq-2/ Romans 6:4

    ## sn85053181/1913-04-04/ed-1/seq-1/ Matthew 18:20

    ## sn87052181/1875-05-27/ed-1/seq-4/ Psalm 22:11

    ## sn85052020/1897-04-30/ed-1/seq-3/ Nehemiah 5:8

    ## sn84026788/1900-06-12/ed-1/seq-2/ Hosea 10:3

    ## sn82014593/1852-03-27/ed-1/seq-3/ Nehemiah 7:30

    ## 46032385/1919-01-01/ed-1/seq-4/ Numbers 18:9

    ## sn83016926/1881-08-04/ed-1/seq-1/ Genesis 29:22

    ## 2010270501/1903-12-11/ed-1/seq-6/ Acts of the Apostles 21:13

    ## sn86089977/1907-01-26/ed-1/seq-4/ Genesis 4:4

    ## sn86090383/1910-09-28/ed-1/seq-6/ Luke 16:12

    ## sn83016925/1887-06-01/ed-1/seq-1/ Luke 20:40

    ## sn85038292/1871-08-10/ed-1/seq-1/ Mark 8:36

    ## sn85038078/1846-02-05/ed-1/seq-4/ 1 John 1:6

    ## sn85033964/1884-01-24/ed-1/seq-3/ Psalm 4:5

    ## sn94060041/1905-04-22/ed-1/seq-3/ Esther 2:6

    ## sn87093353/1917-07-28/ed-1/seq-2/ 2 Samuel 11:25

    ## sn99021999/1889-02-17/ed-1/seq-4/ Nehemiah 2:1

    ## sn84036012/1898-01-10/ed-1/seq-3/ Luke 3:14

    ## sn96093062/1905-04-21/ed-1/seq-3/ Mark 3:33

    ## sn86088296/1891-10-15/ed-1/seq-7/ 2 Kings 3:15

    ## sn84026399/1872-02-29/ed-1/seq-1/ Ezra 2:8

    ## sn86053696/1881-08-27/ed-1/seq-4/ Psalm 90:12

    ## sn85038121/1862-04-10/ed-1/seq-2/ Job 29:16

    ## sn86086632/1898-02-26/ed-1/seq-7/ Acts of the Apostles 17:31

    ## sn92053945/1889-10-21/ed-1/seq-4/ Luke 24:16

    ## sn85038709/1914-01-01/ed-1/seq-6/ Hebrews 4:2

    ## sn83025661/1840-09-02/ed-1/seq-2/ Psalm 137:6

    ## sn82015015/1842-08-16/ed-1/seq-3/ Exodus 32:28

    ## sn88061077/1868-01-31/ed-1/seq-3/ Nehemiah 7:34

    ## sn82015408/1845-04-26/ed-1/seq-2/ Mark 8:36

    ## sn84023209/1858-07-15/ed-1/seq-4/ John 14:27

    ## sn82015015/1842-04-26/ed-1/seq-4/ Philippians 1:5

    ## sn90061556/1915-12-18/ed-1/seq-1/ John 14:15

    ## sn84025891/1890-03-22/ed-1/seq-2/ 1 Corinthians 16:14

    ## sn86072143/1872-01-19/ed-1/seq-2/ 2 Corinthians 5:1

    ## sn82014593/1852-05-06/ed-1/seq-4/ Deuteronomy 5:26

    ## sn85033964/1867-02-15/ed-1/seq-2/ Leviticus 26:35

    ## sn84036207/1901-04-17/ed-1/seq-5/ Revelation 1:14

    ## sn84026688/1898-10-27/ed-1/seq-1/ Job 39:21

    ## sn83025294/1903-02-07/ed-1/seq-4/ Romans 15:27

    ## sn92070446/1901-12-06/ed-1/seq-2/ Genesis 16:12

    ## sn83016474/1840-04-28/ed-1/seq-3/ Ezra 2:19

    ## sn85033535/1874-06-27/ed-1/seq-2/ 1 Samuel 22:2

    ## sn92065503/1918-10-30/ed-1/seq-5/ 2 Samuel 11:25

    ## sn85038078/1846-11-12/ed-1/seq-1/ 2 Peter 1:17

    ## sn86053573/1873-05-30/ed-1/seq-4/ Ezra 2:3

    ## sn84023963/1909-02-05/ed-1/seq-6/ Acts of the Apostles 5:5

    ## sn89058370/1887-10-05/ed-1/seq-3/ Proverbs 6:7

    ## sn92053934/1894-09-05/ed-1/seq-3/ Deuteronomy 1:17

    ## sn85033673/1867-12-18/ed-1/seq-3/ John 6:11

    ## sn93067659/1904-08-17/ed-1/seq-7/ Leviticus 25:37

    ## sn85042588/1889-03-29/ed-1/seq-2/ Matthew 19:17

    ## sn85050913/1912-01-23/ed-1/seq-2/ 1 Corinthians 2:10

    ## sn82014760/1862-07-30/ed-1/seq-1/ Numbers 26:14

    ## sn83021327/1877-04-19/ed-1/seq-1/ Revelation 3:16

    ## sn91068415/1921-08-04/ed-1/seq-1/ Esther 2:6

    ## sn84026788/1900-03-06/ed-1/seq-1/ Psalm 25:12

    ## sn90061417/1900-03-02/ed-1/seq-4/ John 6:51

    ## sn84029853/1907-03-14/ed-1/seq-4/ Hebrews 13:10

    ## sn84026497/1912-12-04/ed-1/seq-5/ Genesis 5:18

    ## sn91068247/1892-08-05/ed-1/seq-1/ Psalm 55:22

    ## sn84026688/1903-01-29/ed-1/seq-1/ Exodus 29:10

    ## sn85038102/1898-01-14/ed-1/seq-6/ Romans 11:4

    ## sn83045784/1863-02-12/ed-1/seq-4/ Psalm 73:7

    ## sn86086632/1898-02-26/ed-1/seq-7/ Matthew 11:30

    ## sn86069620/1899-04-06/ed-1/seq-4/ Genesis 44:28

    ## sn85033681/1882-12-06/ed-1/seq-1/ Genesis 26:29

    ## sn83045784/1864-02-04/ed-1/seq-3/ Hebrews 12:28

    ## sn88064491/1911-03-11/ed-1/seq-3/ Matthew 26:72

    ## sn92053943/1884-03-17/ed-1/seq-2/ Numbers 33:39

    ## sn85034248/1904-08-20/ed-1/seq-6/ Philippians 3:13

    ## sn84025841/1896-10-03/ed-1/seq-3/ Matthew 7:20

    ## sn92070581/1912-05-06/ed-1/seq-2/ 1 Samuel 6:4

    ## sn85038161/1914-09-17/ed-1/seq-6/ Deuteronomy 14:3

    ## sn88064181/1914-03-27/ed-1/seq-7/ Matthew 24:46

    ## sn86063662/1880-08-19/ed-1/seq-1/ Acts of the Apostles 19:25

    ## sn84026912/1878-02-21/ed-1/seq-4/ Matthew 13:35

    ## sn89067274/1888-08-23/ed-1/seq-3/ Genesis 1:2

    ## sn84026526/1860-02-24/ed-1/seq-2/ Revelation 21:21

    ## sn84024718/1864-01-26/ed-1/seq-2/ Joshua 1:5

    ## sn86069161/1890-01-01/ed-1/seq-2/ Matthew 7:20

    ## sn84026912/1921-01-26/ed-1/seq-3/ John 5:39

    ## sn84026688/1903-01-29/ed-1/seq-1/ Numbers 26:1

    ## sn87052143/1877-07-21/ed-1/seq-1/ Luke 7:14

    ## sn82005159/1858-05-07/ed-1/seq-1/ Ezra 2:31

    ## sn85025584/1858-06-24/ed-1/seq-1/ 1 Corinthians 2:16

    ## sn83025661/1840-04-22/ed-1/seq-1/ Exodus 13:13

    ## sn85053148/1880-11-05/ed-1/seq-5/ Deuteronomy 1:17

    ## sn84028645/1861-12-20/ed-1/seq-2/ Psalm 53:4

    ## sn91068402/1891-08-13/ed-1/seq-1/ Lamentations 5:6

    ## sn85033535/1874-06-06/ed-1/seq-3/ Micah 4:3

    ## sn84022770/1899-09-08/ed-1/seq-3/ Lamentations 5:6

    ## sn85042448/1893-03-21/ed-1/seq-3/ Matthew 2:18

    ## sn84026749/1920-02-29/ed-1/seq-3/ 2 Corinthians 7:2

    ## sn84022355/1843-04-18/ed-1/seq-4/ John 20:28

    ## sn84026844/1891-07-17/ed-1/seq-8/ Matthew 14:17

    ## sn86091039/1908-12-22/ed-1/seq-6/ 2 Corinthians 13:8

    ## sn84024720/1907-03-15/ed-1/seq-2/ John 1:23

    ## sn84036290/1919-06-07/ed-1/seq-4/ Habakkuk 2:15

    ## sn93067853/1901-04-26/ed-1/seq-5/ Proverbs 31:28

    ## sn84022355/1843-09-28/ed-1/seq-2/ Psalm 34:20

    ## sn83035312/1844-04-23/ed-1/seq-1/ Ezra 2:35

    ## sn85032801/1895-02-28/ed-1/seq-2/ Luke 1:56

    ## sn84025890/1883-11-10/ed-1/seq-4/ 1 Samuel 30:16

    ## sn86072143/1872-03-15/ed-1/seq-3/ Deuteronomy 32:30

    ## sn83025440/1879-03-06/ed-1/seq-3/ Proverbs 1:29

    ## sn84022135/1887-04-22/ed-1/seq-3/ Isaiah 52:1

    ## sn82016014/1909-10-30/ed-1/seq-20/ James 3:2

    ## sn84026909/1874-11-11/ed-1/seq-1/ John 4:30

    ## sn98069867/1919-01-06/ed-1/seq-8/ 2 Corinthians 13:8

    ## sn84025891/1894-06-02/ed-1/seq-1/ Matthew 13:17

    ## sn86064205/1886-07-29/ed-1/seq-8/ Jeremiah 26:10

    ## sn98069146/1901-12-20/ed-1/seq-11/ Ezekiel 5:9

    ## sn82003410/1846-03-17/ed-1/seq-2/ John 13:12

    ## sn88076421/1914-05-28/ed-1/seq-20/ 2 Kings 4:28

    ## sn87093353/1920-01-24/ed-1/seq-3/ 1 Peter 3:6

    ## sn84026925/1892-02-17/ed-1/seq-4/ Judges 11:10

    ## sn84023127/1856-11-28/ed-1/seq-3/ 2 Kings 2:18

    ## sn83025010/1900-08-23/ed-1/seq-5/ John 4:14

    ## sn85042448/1893-03-21/ed-1/seq-3/ Acts of the Apostles 10:47

    ## sn84024558/1867-05-16/ed-1/seq-4/ Ezekiel 47:14

    ## sn83016957/1842-04-16/ed-1/seq-4/ Exodus 6:2

    ## sn93063557/1919-08-29/ed-1/seq-1/ Acts of the Apostles 23:13

    ## sn82016413/1905-09-23/ed-1/seq-12/ Exodus 4:23

    ## sn92070405/1893-01-20/ed-1/seq-3/ Leviticus 26:34

    ## sn94060041/1905-06-10/ed-1/seq-1/ Proverbs 6:6

    ## sn83040198/1903-01-02/ed-1/seq-2/ Philippians 1:3

    ## sn86069643/1912-03-07/ed-1/seq-1/ John 14:16

    ## sn86069867/1899-12-10/ed-1/seq-4/ 1 Timothy 2:11

    ## sn83045706/1858-12-15/ed-1/seq-4/ Genesis 25:17

    ## sn83025661/1840-04-22/ed-1/seq-1/ Exodus 13:11

    ## sn83045433/1918-02-01/ed-1/seq-8/ Genesis 2:7

    ## sn93067659/1904-10-12/ed-1/seq-6/ Psalm 124:1

    ## sn94060041/1890-03-15/ed-1/seq-6/ Matthew 4:23

    ## sn83032058/1873-05-15/ed-1/seq-3/ Mark 10:14

    ## sn85033386/1873-11-14/ed-1/seq-1/ 2 Samuel 19:4

    ## sn89058013/1891-07-10/ed-1/seq-4/ John 13:18

    ## sn84026897/1843-02-22/ed-1/seq-2/ 1 Corinthians 9:5

    ## sn89066129/1911-09-29/ed-1/seq-3/ Ezekiel 3:17

    ## sn82003383/1843-05-20/ed-1/seq-2/ Nehemiah 13:10

    ## sn84024283/1910-05-05/ed-1/seq-3/ Luke 20:40

    ## sn85038158/1877-05-31/ed-1/seq-3/ Nehemiah 7:34

    ## sn94060041/1894-06-02/ed-1/seq-1/ Psalm 104:8

    ## sn88084272/1910-12-14/ed-1/seq-14/ Nehemiah 8:2

    ## sn85049804/1917-03-30/ed-1/seq-4/ Psalm 47:7

    ## sn84026853/1876-04-05/ed-1/seq-3/ Matthew 25:21

    ## sn83025667/1852-10-27/ed-1/seq-1/ Ezra 2:7

    ## sn83045217/1921-12-19/ed-1/seq-7/ Acts of the Apostles 17:26

    ## sn86088529/1886-05-21/ed-1/seq-7/ Matthew 26:72

    ## sn91068245/1898-07-14/ed-1/seq-4/ Nehemiah 6:7

    ## sn83035487/1845-07-25/ed-1/seq-2/ 2 Corinthians 10:4

    ## sn86081853/1889-08-23/ed-1/seq-1/ Isaiah 27:5

    ## sn87056244/1907-08-22/ed-1/seq-3/ 1 Samuel 12:5

    ## sn87078321/1905-06-28/ed-1/seq-8/ Exodus 20:3

    ## sn85042461/1894-09-30/ed-1/seq-16/ Mark 16:18

    ## sn90061783/1909-12-09/ed-1/seq-3/ 2 Timothy 4:4

    ## sn85053040/1882-09-23/ed-1/seq-1/ Acts of the Apostles 7:5

    ## sn94060041/1894-03-03/ed-1/seq-1/ Ecclesiastes 8:1

    ## sn86069620/1897-02-04/ed-1/seq-1/ Deuteronomy 20:8

    ## sn85038158/1877-09-20/ed-1/seq-3/ Numbers 26:14

    ## sn85054616/1854-08-16/ed-1/seq-1/ 2 Chronicles 36:5

    ## sn86071377/1850-08-01/ed-1/seq-3/ 2 Kings 11:21

    ## sn85038115/1879-09-23/ed-1/seq-2/ Ephesians 3:12

    ## sn93067853/1898-01-21/ed-1/seq-4/ Proverbs 6:28

    ## sn86063381/1908-06-24/ed-1/seq-1/ Psalm 119:14

    ## sn85038115/1882-09-19/ed-1/seq-1/ 1 Chronicles 9:24

    ## sn97067589/1910-02-04/ed-1/seq-6/ Jeremiah 13:3

    ## sn85050913/1912-08-06/ed-1/seq-2/ Nehemiah 7:10

    ## sn90059180/1898-09-02/ed-1/seq-1/ 2 Samuel 11:25

    ## sn82014434/1853-03-17/ed-1/seq-4/ Deuteronomy 20:8

    ## sn83040052/1898-02-04/ed-1/seq-5/ Luke 1:56

    ## sn86069620/1897-03-11/ed-1/seq-1/ 1 Samuel 30:30

    ## sn85066387/1901-07-19/ed-1/seq-3/ 2 Corinthians 13:8

    ## sn84026497/1912-01-31/ed-1/seq-3/ Ezra 2:1

    ## sn84022835/1904-09-30/ed-1/seq-10/ Nehemiah 7:9

    ## sn86086632/1898-01-19/ed-1/seq-7/ Philippians 3:15

    ## sn89058370/1899-04-15/ed-1/seq-2/ Proverbs 22:2

    ## sn83035595/1860-02-03/ed-1/seq-2/ Luke 6:24

    ## sn83032040/1902-08-07/ed-1/seq-3/ Judges 14:15

    ## sn82015387/1898-12-24/ed-1/seq-2/ Proverbs 3:17

    ## sn85027003/1859-06-30/ed-1/seq-1/ Matthew 20:27

    ## sn86053370/1864-06-22/ed-1/seq-4/ Romans 10:14

    ## sn84023209/1874-02-04/ed-1/seq-2/ Jeremiah 4:21

    ## sn83025661/1840-11-25/ed-1/seq-1/ Acts of the Apostles 20:21

    ## sn85033386/1873-11-21/ed-1/seq-1/ Jeremiah 22:12

    ## sn84026853/1886-04-28/ed-1/seq-1/ Matthew 27:54

    ## sn83035595/1861-06-14/ed-1/seq-1/ Exodus 21:7

    ## sn83035143/1865-01-13/ed-1/seq-3/ 1 John 1:10

    ## sn94056446/1908-07-03/ed-1/seq-5/ 1 Chronicles 24:28

    ## sn83016925/1887-03-30/ed-1/seq-4/ John 3:16

    ## sn86063381/1918-05-31/ed-1/seq-1/ Luke 3:18

    ## sn83030214/1922-10-22/ed-1/seq-21/ 2 Corinthians 10:9

    ## sn86069161/1890-07-09/ed-1/seq-2/ 1 John 3:14

    ## sn85038145/1875-01-28/ed-1/seq-3/ Jeremiah 34:16

    ## sn84024082/1862-07-01/ed-1/seq-1/ John 14:15

    ## sn83032058/1873-11-27/ed-1/seq-3/ Ezra 2:5

    ## sn82014296/1869-06-30/ed-1/seq-1/ 2 Samuel 11:25

    ## sn84024738/1856-01-19/ed-1/seq-2/ 2 Thessalonians 3:9

    ## sn86091484/1896-05-02/ed-1/seq-6/ 1 Samuel 18:9

    ## sn84045030/1853-02-16/ed-1/seq-3/ Psalm 97:2

    ## sn90061556/1915-12-18/ed-1/seq-1/ 1 Corinthians 13:13

    ## sn95069778/1897-01-14/ed-1/seq-6/ 1 Samuel 26:8

    ## sn83045217/1921-12-19/ed-1/seq-7/ Proverbs 23:26

    ## sn84023416/1916-07-14/ed-1/seq-6/ 1 Samuel 2:21

    ## sn84023209/1874-07-15/ed-1/seq-1/ Isaiah 13:18

    ## sn82014086/1916-04-24/ed-1/seq-8/ Matthew 28:9

    ## sn94060041/1894-08-25/ed-1/seq-1/ Revelation 22:13

    ## sn82007642/1917-08-16/ed-1/seq-3/ Acts of the Apostles 23:13

    ## sn84026526/1860-02-24/ed-1/seq-1/ 2 Corinthians 2:1

    ## sn85032801/1898-06-02/ed-1/seq-5/ 1 Samuel 29:4

    ## sn86053634/1882-06-21/ed-1/seq-2/ Ezra 2:35

    ## sn96086441/1881-03-11/ed-1/seq-4/ Luke 24:16

    ## sn85033781/1895-10-25/ed-1/seq-6/ Isaiah 6:8

    ## sn86071377/1850-12-26/ed-1/seq-2/ Deuteronomy 1:28

    ## sn85038158/1876-04-27/ed-1/seq-4/ Numbers 20:12

    ## sn84036256/1921-09-02/ed-1/seq-2/ Revelation 22:21

    ## sn82007023/1878-11-15/ed-1/seq-2/ Psalm 106:11

    ## sn85042588/1889-03-29/ed-1/seq-2/ Mark 10:16

    ## sn88064020/1911-01-12/ed-1/seq-4/ Deuteronomy 1:18

    ## sn84026925/1892-01-20/ed-1/seq-2/ John 11:37

    ## sn83016811/1888-02-18/ed-1/seq-2/ Exodus 36:33

    ## sn85025584/1858-05-13/ed-1/seq-2/ Deuteronomy 29:16

    ## sn84026925/1879-12-04/ed-1/seq-4/ Leviticus 17:5

    ## sn95073194/1911-06-21/ed-1/seq-6/ Micah 6:8

    ## sn89058133/1919-12-04/ed-1/seq-4/ Ezra 2:7

    ## sn83025779/1920-06-12/ed-1/seq-12/ John 15:1

    ## sn85053121/1914-11-02/ed-1/seq-4/ 1 Samuel 21:5

    ## sn84024082/1862-03-04/ed-1/seq-1/ Amos 6:10

    ## sn86088296/1890-09-04/ed-1/seq-3/ 2 Chronicles 20:31

    ## sn85038102/1898-01-21/ed-1/seq-4/ 1 Thessalonians 4:6

    ## sn85053121/1914-11-02/ed-1/seq-4/ Song of Solomon 3:4

    ## sn93067846/1911-04-15/ed-1/seq-4/ Luke 22:45

    ## sn89066163/1866-09-07/ed-1/seq-2/ Matthew 26:9

    ## sn93067790/1872-08-07/ed-1/seq-6/ Proverbs 4:15

    ## sn83045784/1857-03-28/ed-1/seq-5/ 2 Chronicles 7:20

    ## sn88064020/1914-08-20/ed-1/seq-3/ 1 Chronicles 9:25

    ## sn85032801/1893-12-29/ed-1/seq-8/ Job 1:21

    ## sn85038121/1862-11-13/ed-1/seq-1/ Matthew 12:16

    ## sn84026853/1921-12-05/ed-1/seq-6/ Mark 14:21

    ## sn84024558/1856-08-21/ed-1/seq-1/ 2 Peter 3:12

    ## sn86090528/1900-11-05/ed-1/seq-3/ Song of Solomon 4:2

    ## sn83016810/1905-04-29/ed-1/seq-9/ Jeremiah 23:40

    ## sn87065028/1912-12-15/ed-1/seq-10/ Psalm 145:18

    ## sn90061556/1915-12-18/ed-1/seq-1/ Exodus 20:6

    ## sn98066406/1922-07-27/ed-1/seq-7/ 2 Samuel 22:13

    ## sn85042623/1875-05-05/ed-1/seq-3/ Matthew 25:17

    ## sn85038102/1898-09-09/ed-1/seq-3/ Matthew 13:35

    ## sn84024720/1907-08-23/ed-1/seq-4/ Luke 23:8

    ## sn84026925/1892-01-13/ed-1/seq-2/ Romans 10:14

    ## sn86069162/1903-02-04/ed-1/seq-4/ Luke 3:18

    ## sn83035487/1845-11-14/ed-1/seq-3/ Isaiah 1:17

    ## sn83016943/1895-02-16/ed-1/seq-1/ John 9:33

    ## sn85038088/1882-05-18/ed-1/seq-1/ Mark 6:44

    ## sn84029853/1907-09-19/ed-1/seq-3/ Deuteronomy 6:5

    ## sn84022278/1873-03-01/ed-1/seq-2/ Matthew 21:39

    ## sn91068402/1897-07-08/ed-1/seq-2/ 1 Timothy 6:7

    ## sn86061215/1912-06-01/ed-1/seq-4/ Ephesians 2:9

    ## sn85033637/1878-11-26/ed-1/seq-1/ Matthew 25:28

    ## sn83045784/1863-04-30/ed-1/seq-1/ 2 Chronicles 20:12

    ## sn84026925/1879-03-20/ed-1/seq-4/ Luke 9:24

    ## sn85033637/1854-09-12/ed-1/seq-1/ Ezra 2:33

    ## sn85030287/1912-08-29/ed-1/seq-2/ 1 Kings 7:22

    ## sn84026925/1892-01-20/ed-1/seq-2/ Ezekiel 12:7

    ## sn82016419/1880-08-06/ed-1/seq-2/ John 9:5

    ## sn85038119/1892-02-04/ed-1/seq-1/ John 15:22

    ## sn89058013/1891-06-19/ed-1/seq-2/ John 9:5

    ## sn84026844/1891-11-28/ed-1/seq-2/ Deuteronomy 1:17

    ## sn84026853/1876-02-09/ed-1/seq-2/ Psalm 71:9

    ## sn83045784/1857-06-27/ed-1/seq-2/ Genesis 5:28

    ## sn82015485/1917-06-21/ed-1/seq-2/ John 8:32

    ## sn85025181/1862-06-28/ed-1/seq-3/ Luke 2:3

    ## sn86081895/1901-08-01/ed-1/seq-6/ Genesis 13:14

    ## sn84036207/1904-10-26/ed-1/seq-12/ Romans 12:18

    ## sn85033964/1884-12-25/ed-1/seq-2/ Lamentations 1:12

    ## sn84026707/1866-09-20/ed-1/seq-1/ Psalm 34:20

    ## sn84026909/1874-08-26/ed-2/seq-2/ Ezra 2:12

    ## sn84026900/1854-07-12/ed-1/seq-1/ Revelation 6:11

    ## sn83035565/1913-09-18/ed-1/seq-2/ Mark 3:33

    ## sn84024718/1869-11-09/ed-1/seq-1/ Psalm 119:60

    ## sn82015015/1842-04-26/ed-1/seq-4/ Ephesians 4:5

    ## sn88064069/1922-04-27/ed-1/seq-7/ Jeremiah 48:34

    ## sn84022770/1881-07-01/ed-1/seq-3/ Nehemiah 7:72

    ## sn85032801/1898-09-08/ed-1/seq-2/ Romans 12:4

    ## sn85030287/1912-11-21/ed-1/seq-7/ Psalm 45:1

    ## sn84024738/1861-11-21/ed-1/seq-3/ 2 Corinthians 10:14

    ## sn86089977/1907-01-12/ed-1/seq-4/ Psalm 8:5

    ## sn85034438/1891-05-26/ed-1/seq-2/ 1 Samuel 5:4

    ## sn85033100/1857-12-10/ed-1/seq-2/ Genesis 7:12

    ## sn84024283/1888-05-03/ed-1/seq-4/ Ezra 2:19

    ## sn84024716/1908-08-05/ed-1/seq-4/ 1 Chronicles 29:26

    ## sn89066350/1883-01-11/ed-1/seq-2/ Mark 3:20

    ## sn97067613/1889-02-07/ed-1/seq-4/ Mark 5:8

    ## sn83026389/1870-11-19/ed-2/seq-1/ Proverbs 8:24

    ## sn85054616/1854-06-15/ed-1/seq-1/ Deuteronomy 3:20

    ## sn86069643/1912-12-05/ed-1/seq-1/ Romans 15:27

    ## sn89064515/1907-05-31/ed-1/seq-6/ Nehemiah 7:62

    ## sn84026925/1892-01-13/ed-1/seq-2/ Matthew 7:20

    ## sn85033386/1873-11-07/ed-1/seq-3/ Deuteronomy 3:20

    ## sn87060190/1899-02-14/ed-1/seq-1/ Acts of the Apostles 27:39

    ## sn85038078/1846-02-19/ed-1/seq-2/ Job 13:17

    ## sn88064176/1900-07-21/ed-1/seq-3/ Exodus 28:16

    ## sn84026853/1886-04-28/ed-1/seq-1/ Matthew 27:52

    ## sn86086632/1898-04-16/ed-1/seq-7/ Matthew 15:15

    ## sn86090383/1910-08-03/ed-1/seq-5/ Revelation 1:14

    ## sn84026688/1903-09-17/ed-1/seq-4/ 1 Peter 4:7

    ## sn84022770/1881-10-07/ed-1/seq-4/ Psalm 124:2

    ## sn84026912/1878-09-26/ed-1/seq-4/ 1 Samuel 13:12

    ## sn85054845/1864-02-11/ed-1/seq-1/ Joshua 9:23

    ## sn83045462/1860-12-28/ed-1/seq-1/ Psalm 62:10

    ## sn84024716/1908-10-14/ed-1/seq-4/ Psalm 72:4

    ## sn85038709/1914-02-05/ed-1/seq-7/ Jeremiah 33:8

    ## sn88064249/1919-11-08/ed-1/seq-23/ Mark 15:30

    ## sn85034235/1910-10-20/ed-1/seq-1/ Micah 6:12

    ## sn85033781/1896-02-26/ed-1/seq-6/ Luke 9:18

    ## sn87060190/1899-08-08/ed-1/seq-2/ 2 Chronicles 36:5

    ## sn96091104/1898-12-02/ed-1/seq-5/ Mark 10:14

    ## sn88064181/1914-03-27/ed-1/seq-7/ Micah 6:8

    ## sn86063381/1908-08-14/ed-1/seq-3/ John 4:43

    ## sn85033306/1888-02-10/ed-1/seq-3/ Colossians 3:14

    ## sn84026925/1879-09-04/ed-1/seq-2/ Psalm 100:1

    ## sn85033964/1867-03-22/ed-1/seq-3/ Psalm 48:8

    ## sn87093407/1903-11-24/ed-1/seq-8/ Proverbs 23:31

    ## sn86053240/1846-12-23/ed-1/seq-1/ Lamentations 5:6

    ## sn87052181/1875-12-16/ed-1/seq-6/ Luke 4:16

    ## sn89081022/1903-04-25/ed-1/seq-7/ Leviticus 18:19

    ## sn85034248/1904-11-05/ed-1/seq-6/ Psalm 83:4

    ## sn89081022/1908-08-26/ed-1/seq-6/ Matthew 16:25

    ## sn87093407/1916-03-24/ed-1/seq-3/ John 9:5

    ## sn88085947/1904-12-12/ed-1/seq-2/ 1 Thessalonians 3:12

    ## sn83016925/1887-06-29/ed-1/seq-1/ Mark 6:9

    ## sn85027003/1859-12-08/ed-1/seq-2/ Isaiah 17:1

    ## sn82014681/1883-11-10/ed-1/seq-4/ Job 10:19

    ## sn82016419/1880-05-28/ed-1/seq-4/ 2 Kings 24:7

    ## sn83016474/1840-05-01/ed-1/seq-2/ Ezekiel 5:9

    ## sn98066406/1903-10-02/ed-1/seq-7/ 1 Samuel 20:31

    ## sn86081895/1901-01-31/ed-1/seq-7/ Matthew 25:7

    ## sn85033781/1896-04-29/ed-1/seq-6/ Luke 17:17

    ## sn85058394/1909-01-10/ed-1/seq-15/ Proverbs 21:26

    ## sn94060041/1890-10-25/ed-1/seq-1/ Luke 10:30

    ## sn85033781/1896-02-26/ed-1/seq-6/ Luke 9:26

    ## sn85026050/1864-07-01/ed-1/seq-3/ Psalm 147:8

    ## sn89058248/1897-09-03/ed-1/seq-3/ Isaiah 26:18

    ## sn84026707/1866-05-03/ed-1/seq-2/ 1 Corinthians 5:1

    ## sn94052364/1890-10-11/ed-1/seq-1/ Job 2:4

    ## sn97067613/1889-02-07/ed-1/seq-4/ Psalm 1:1

    ## sn87056250/1895-12-04/ed-1/seq-5/ Psalm 124:2

    ## sn84023127/1856-09-26/ed-1/seq-1/ 1 Corinthians 12:19

    ## sn93061428/1910-10-07/ed-1/seq-3/ Luke 1:56

    ## sn83032199/1867-10-03/ed-1/seq-4/ Psalm 33:18

    ## sn85042344/1917-10-17/ed-1/seq-10/ Colossians 4:11

    ## sn82015133/1883-11-03/ed-1/seq-4/ Job 15:9

    ## sn84024718/1869-11-09/ed-1/seq-1/ Luke 11:3

    ## sn84026688/1898-11-17/ed-1/seq-2/ Hebrews 4:15

    ## sn89081128/1894-11-14/ed-1/seq-6/ Mark 4:33

    ## sn86053569/1838-05-12/ed-1/seq-1/ Psalm 116:2

    ## sn84026259/1875-05-06/ed-1/seq-3/ Nehemiah 7:17

    ## sn84024738/1856-04-29/ed-1/seq-2/ Ezra 2:26

    ## sn86053370/1864-06-22/ed-1/seq-4/ 2 Timothy 2:2

    ## sn83040340/1880-08-27/ed-1/seq-3/ Jeremiah 3:19

    ## sn89064939/1882-11-01/ed-1/seq-2/ Ezra 2:17

    ## sn86090474/1885-01-17/ed-1/seq-1/ Romans 15:2

    ## sn87065028/1903-02-10/ed-1/seq-3/ 2 Corinthians 5:20

    ## sn87065462/1912-02-01/ed-1/seq-3/ Job 1:2

    ## sn78000395/1916-02-12/ed-1/seq-1/ Deuteronomy 6:22

    ## sn82016419/1874-01-23/ed-1/seq-3/ Nehemiah 5:5

    ## sn84026536/1868-11-27/ed-1/seq-1/ Nehemiah 7:9

    ## sn86069620/1899-01-26/ed-1/seq-4/ Psalm 37:25

    ## sn85038145/1875-09-23/ed-1/seq-4/ Ezra 2:26

    ## sn85042588/1889-03-29/ed-1/seq-2/ Mark 10:17

    ## sn94060041/1890-03-15/ed-1/seq-6/ Luke 5:10

    ## sn86081895/1901-01-31/ed-1/seq-7/ Matthew 25:13

    ## sn84020682/1885-10-28/ed-1/seq-2/ Matthew 17:16

    ## sn83016942/1838-05-26/ed-1/seq-4/ 2 Kings 7:4

    ## sn87075048/1900-01-04/ed-1/seq-3/ Luke 2:14

    ## sn83025661/1840-04-08/ed-1/seq-1/ Acts of the Apostles 19:2

    ## sn84022770/1909-10-22/ed-1/seq-2/ Jeremiah 25:32

    ## sn84024718/1864-03-08/ed-1/seq-1/ Proverbs 22:16

    ## sn83045160/1864-01-06/ed-1/seq-1/ Psalm 68:14

    ## sn86058890/1848-01-11/ed-1/seq-2/ Matthew 23:30

    ## sn85038158/1876-06-08/ed-1/seq-2/ 1 Samuel 14:6

    ## sn88076421/1914-03-26/ed-1/seq-9/ Esther 4:11

    ## sn86069161/1890-01-22/ed-1/seq-1/ Psalm 37:36

    ## sn94060041/1907-04-13/ed-1/seq-1/ 1 Corinthians 8:13

    ## sn84026912/1921-12-07/ed-1/seq-3/ John 15:16

    ## sn90061417/1900-02-16/ed-1/seq-4/ Nehemiah 2:1

    ## sn83040592/1919-01-03/ed-1/seq-1/ Mark 14:5

    ## sn84020714/1884-10-03/ed-1/seq-3/ Joshua 22:17

    ## sn89074109/1907-12-12/ed-1/seq-6/ 2 Chronicles 33:10

    ## sn90061417/1900-08-24/ed-1/seq-4/ Jeremiah 44:7

    ## sn84045030/1853-05-18/ed-1/seq-4/ Ezra 2:4

    ## sn85042460/1888-09-12/ed-1/seq-4/ Psalm 7:15

    ## sn85026050/1866-05-18/ed-1/seq-2/ Job 37:5

    ## sn82015485/1890-01-04/ed-1/seq-3/ Psalm 68:14

    ## sn85033781/1876-03-24/ed-1/seq-3/ Luke 14:12

    ## sn94059373/1907-12-06/ed-1/seq-3/ 2 Corinthians 5:10

    ## sn85034467/1859-03-03/ed-1/seq-2/ Ezra 2:7

    ## sn84027621/1902-07-07/ed-1/seq-3/ Psalm 103:12

    ## sn85025584/1858-05-27/ed-1/seq-3/ Proverbs 3:17

    ## sn85026941/1898-05-13/ed-1/seq-1/ Exodus 3:1

    ## sn84038628/1866-10-03/ed-1/seq-2/ 2 Chronicles 33:10

    ## sn86069873/1907-02-19/ed-1/seq-8/ 1 Chronicles 7:2

    ## sn86086632/1898-04-16/ed-1/seq-7/ Mark 9:2

    ## sn95069778/1897-03-25/ed-1/seq-2/ 2 Chronicles 1:10

    ## sn88085770/1916-02-17/ed-1/seq-3/ Proverbs 4:19

    ## sn96088004/1920-06-16/ed-1/seq-4/ Judges 16:17

    ## sn83025010/1900-08-23/ed-1/seq-5/ Jeremiah 32:34

    ## sn89064939/1887-06-15/ed-1/seq-8/ 1 John 1:8

    ## sn91068415/1921-09-15/ed-1/seq-3/ 1 Corinthians 10:24

    ## sn88085012/1912-02-22/ed-1/seq-5/ Luke 7:28

    ## sn84023127/1856-03-28/ed-1/seq-1/ 2 Kings 13:5

    ## sn84038582/1879-11-08/ed-1/seq-1/ Luke 24:44

    ## sn83035487/1845-07-25/ed-1/seq-2/ 1 Thessalonians 5:21

    ## sn83016926/1881-02-17/ed-1/seq-2/ 1 Thessalonians 1:8

    ## sn84028272/1891-11-25/ed-1/seq-7/ Acts of the Apostles 17:31

    ## sn88064402/1918-07-05/ed-1/seq-3/ Esther 3:9

    ## sn88064181/1914-04-03/ed-1/seq-3/ Daniel 4:14

    ## sn85033549/1884-12-03/ed-1/seq-2/ Ezekiel 48:16

    ## sn86088572/1913-04-24/ed-1/seq-4/ 1 Corinthians 11:1

    ## sn87008085/1909-01-21/ed-1/seq-3/ Daniel 1:21

    ## sn84024738/1861-03-18/ed-1/seq-4/ 1 Chronicles 24:28

    ## sn85027003/1859-06-16/ed-1/seq-3/ Numbers 2:23

    ## sn93067804/1877-10-06/ed-1/seq-2/ Job 12:3

    ## sn84038125/1876-06-16/ed-1/seq-2/ Psalm 99:2

    ## sn85042147/1842-05-25/ed-1/seq-3/ John 18:30

    ## sn82015679/1894-12-24/ed-1/seq-6/ Nehemiah 4:22

    ## sn84024718/1869-03-16/ed-1/seq-4/ Deuteronomy 3:19

    ## sn84022770/1899-09-29/ed-1/seq-1/ Deuteronomy 31:2

    ## sn94060041/1905-03-18/ed-1/seq-1/ 2 Samuel 11:25

    ## sn83045160/1864-06-16/ed-1/seq-1/ Mark 8:16

    ## sn86074011/1909-09-24/ed-1/seq-2/ Romans 6:5

    ## sn84036256/1921-09-02/ed-1/seq-2/ Philippians 4:23

    ## sn85030287/1910-01-06/ed-1/seq-3/ Lamentations 5:6

    ## sn84020558/1898-08-08/ed-1/seq-6/ 2 Corinthians 13:2

    ## sn84030186/1861-12-26/ed-1/seq-4/ John 16:16

    ## sn2006060001/1888-06-14/ed-1/seq-3/ Matthew 28:19

    ## sn84026788/1900-06-12/ed-1/seq-2/ 2 Chronicles 27:1

    ## sn94060041/1894-03-03/ed-1/seq-1/ Proverbs 31:10

    ## sn89074109/1914-12-18/ed-1/seq-6/ 1 Samuel 20:42

    ## sn88064402/1905-12-29/ed-1/seq-2/ Numbers 29:12

    ## sn84026497/1912-01-17/ed-1/seq-4/ Jeremiah 13:20

    ## sn84020104/1853-11-20/ed-1/seq-4/ Hebrews 4:2

    ## sn84020751/1892-09-29/ed-1/seq-3/ Genesis 5:15

    ## sn84024828/1917-09-29/ed-1/seq-6/ Ezra 2:13

    ## sn85033964/1867-01-11/ed-1/seq-2/ 1 Corinthians 15:55

    ## sn85026050/1854-09-01/ed-1/seq-4/ 1 Timothy 5:16

    ## sn83016475/1840-11-30/ed-1/seq-3/ Proverbs 4:19

    ## sn85038121/1876-06-15/ed-1/seq-3/ Job 9:24

    ## sn85034248/1904-09-17/ed-1/seq-4/ Ezekiel 29:17

    ## sn85033964/1867-01-11/ed-1/seq-2/ Psalm 23:1

    ## sn84023963/1909-06-25/ed-1/seq-3/ Romans 13:13

    ## sn83035565/1913-12-25/ed-1/seq-8/ Deuteronomy 30:6

    ## sn83045784/1863-04-30/ed-1/seq-4/ Ezekiel 4:10

    ## sn84038582/1879-01-04/ed-1/seq-4/ Matthew 11:23

    ## sn84026688/1903-07-23/ed-1/seq-4/ Luke 10:19

    ## sn86069867/1899-12-10/ed-1/seq-3/ Ezekiel 20:14

    ## sn82005159/1858-01-08/ed-1/seq-3/ Philippians 4:19

    ## sn85033781/1896-02-26/ed-1/seq-6/ Luke 9:27

    ## sn82007642/1917-12-20/ed-1/seq-1/ Job 29:5

    ## sn86071045/1881-03-23/ed-1/seq-2/ Proverbs 21:1

    ## sn84024283/1888-02-16/ed-1/seq-5/ Hebrews 6:19

    ## sn85034235/1910-12-29/ed-1/seq-4/ Job 34:31

    ## sn86090383/1910-07-21/ed-1/seq-1/ 1 Kings 19:10

    ## sn83016926/1881-03-31/ed-1/seq-2/ Genesis 19:8

    ## sn94060041/1905-05-20/ed-1/seq-1/ Luke 14:26

    ## sn87052143/1882-08-26/ed-1/seq-1/ Psalm 60:11

    ## sn86088181/1888-02-02/ed-1/seq-2/ Matthew 6:20

    ## sn83025661/1840-07-29/ed-1/seq-1/ Hebrews 9:11

    ## sn97070614/1898-10-07/ed-1/seq-7/ Deuteronomy 20:8

    ## sn87091222/1891-12-11/ed-1/seq-2/ John 9:33

    ## sn85033964/1884-01-24/ed-1/seq-4/ 2 Kings 11:21

    ## sn85034235/1910-12-29/ed-1/seq-4/ Luke 17:16

    ## sn84026688/1898-04-28/ed-1/seq-1/ Luke 21:18

    ## sn84023963/1909-05-28/ed-1/seq-2/ James 2:17

    ## sn89066651/1919-08-14/ed-1/seq-1/ Joshua 23:8

    ## sn85042147/1842-06-01/ed-1/seq-1/ 1 Corinthians 2:8

    ## sn83045462/1879-02-14/ed-1/seq-4/ 2 Samuel 1:15

    ## sn84045030/1853-02-16/ed-1/seq-1/ Daniel 9:18

    ## sn86069620/1897-04-01/ed-1/seq-4/ Job 14:1

    ## sn85038121/1862-03-13/ed-1/seq-3/ 1 John 1:5

    ## sn83032058/1873-10-02/ed-1/seq-3/ Psalm 96:2

    ## sn86053569/1838-12-22/ed-1/seq-4/ Proverbs 19:17

    ## sn89066996/1917-07-27/ed-1/seq-1/ Matthew 26:9

    ## sn86072143/1872-02-16/ed-1/seq-1/ John 9:5

    ## sn85038121/1876-02-24/ed-1/seq-3/ 1 Kings 22:1

    ## sn96091104/1885-07-10/ed-1/seq-2/ Luke 12:27

    ## sn83032040/1902-11-06/ed-1/seq-1/ Isaiah 35:3

    ## sn85033781/1899-08-09/ed-1/seq-1/ 2 Timothy 4:6

    ## sn97067613/1889-12-12/ed-1/seq-3/ Colossians 3:21

    ## sn89058007/1895-07-19/ed-1/seq-1/ Proverbs 3:17

    ## sn84025890/1883-03-03/ed-1/seq-2/ Exodus 20:2

    ## sn83016758/1895-08-15/ed-1/seq-7/ Proverbs 1:24

``` {.r}
sample_matches <- sample_matches %>% mutate(most_unusual_phrase = mups)
```

And put data in final form for checking matches.

``` {.r}
sample_matches <- sample_matches %>% 
  mutate(url = urls,
         match = "") %>% 
  select(reference, verse, url, match, likely, most_unusual_phrase, token_count,
         probability, tfidf, tf,  position_range, position_sd, everything()) %>% 
  select(-words, -tokens)
```

``` {.r}
write_csv(sample_matches, "data/matches-for-model-training.csv")
```
