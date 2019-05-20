library(qualtRics)
library(qualtricks)
library(dplyr)
library(purrr)

all <- all_surveys()

to_deactivate <- all %>%
  mutate(lastMod = as.Date(lastModified)) %>% 
  # filter(isActive == TRUE & ownerId == Sys.getenv("QUALTRICS_USERID") & lastMod == "2019-01-14") %>%
  # filter(isActive==TRUE & ownerId != Sys.getenv("QUALTRICS_USERID"))

# updateSurvey(to_deactivate$id[1], isActive=FALSE)

to_deactivate$id %>% map(function(x) {updateSurvey(x, isActive=FALSE)})

