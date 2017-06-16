# ===========================================
# === Book Sentiment Analysis in Parallel ===
# ===========================================

# gutenberg_works() %>% View()

# doAzureParallel imports
library(dplyr)
library(devtools)
library(doAzureParallel)

## Local parallel development
# library(doParallel)
# install.packages(c("dplyr", "gutenbergr", "tibble", "tidyr", "tidytext"))
# cl <- parallel::makeCluster(4)
# parallel::makeCluster(cl)
# parallel::detectCores()

## Azure runtime at scale
## Install packages via cluster config
setCredentials("credentials.json")
cluster <- doAzureParallel::makeCluster("cluster.json")
registerDoAzureParallel(cluster)
getDoParWorkers()
opt <- list(chunkSize = 5)

summary <- foreach(i = 1:1000, .combine = rbind, .options.azure = opt, .packages = c("dplyr", "gutenbergr", "tibble", "tidyr", "tidytext")) %dopar% {
  result <- tryCatch({
    gutenberg_works(gutenberg_id == i)$title

    book <- gutenberg_download(i)
    tidyBook <- book %>% unnest_tokens(word, text)

    # Remove uninteresting words and count common words again
    tidyBook <- tidyBook %>% anti_join(stop_words)

    # Initialize sentiments
    sentiment <- get_sentiments('bing')

    # Is treasure island text mostly positive or negative?
    sentimentResults <- tidyBook %>%
      inner_join(sentiment) %>%
      count(sentiment, sort = TRUE) %>%
      spread(sentiment, n, fill = 0)        # Transpose data

    # Get the ration of positive to negtive sentiments
    pos <- sentimentResults$positive / mean( c(sentimentResults$positive, sentimentResults$negative))
    neg <- sentimentResults$negative / mean( c(sentimentResults$positive, sentimentResults$negative))

    # Return a data frame with results
    df <- data.frame(
      title = gutenbergr::gutenberg_works(gutenberg_id == i)$title,
      bookshelf = gutenbergr::gutenberg_works(gutenberg_id == i)$gutenberg_bookshelf,
      positive = pos / 2,
      negative = neg / 2)

    df
  }, warning = function(e) {
    # do nothing
  }, error = function(e) {
    # do nothing
  })
}

summary[,c(2,3,4)]

summary[,c(2,3,4)] %>% group_by(bookshelf) %>%
  summarise(
    n = n(),
    meanPositive = mean(positive)) %>%
  arrange(desc(meanPositive))
