#' Update Survey
#' @description
#' Updates a survey \cr
#' https://api.qualtrics.com/reference#update-survey
#' [] not all args handled atm
#' @param surveyId String. Survey ID
#' @param name String. New survey name
#' @param isActive Boolean. Survey status
#' @param expirationStartDate String. Defines the active time range for the survey. Example: {"startDate":"2016-01-01T01:00:00Z", "endDate":"2016-03-01T01:00:00Z"}. See Dates and Times for more information on the date and time format.
#' @param expirationEndDate String. See expirationStartDate
#' @param yourapitoken String from renviron
#' @param ownerID String. The new owner of the survey. Note that the caller must own the survey to set a new owner.
#'
#' @return response() object
#' @export
#'
#' @examples
#' \dontrun{
#' library(qualtRics)
#' to_deactivate <- all_surveys() %>%
#'   mutate(lastMod = as.Date(lastModified)) %>%
#'   filter(isActive == TRUE & lastMod <= "2017-01-01")
#'
#' updateSurvey(to_deactivate$id[1], isActive=FALSE)
#' }
updateSurvey <- function(surveyId, name=NULL, isActive=c(TRUE, FALSE), expirationStartDate=NULL, expirationEndDate=NULL,  ownerID=NULL, yourapitoken = Sys.getenv("QSI_TOKEN")) {
  checkRenviron("QSI_TOKEN")
  checkRenviron("QUALTRICS_DATACENTERID")

  message(surveyId)

  url <- paste0("https://", Sys.getenv("QUALTRICS_DATACENTERID"), "/API/v3/surveys/", surveyId)
  data <- list()

  if(!is.null(name)) {
    data <- append(data, c(name=name))
  }

  if(!is.null(isActive)) {
    data <- append(data, c(isActive=isActive))
  }

  if(!is.null(ownerId)) {
    data <- append(data, c(ownerId=ownerId))
  }

  r <- PUT(url = url,
           add_headers(
             "Content-Type" = "application/json",
             "X-API-TOKEN" = yourapitoken,
           ),
           body = data,
           encode = "json"
  )
  return(r)
}
