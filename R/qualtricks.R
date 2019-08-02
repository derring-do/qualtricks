#' INTERNAL: Check for requisite .Renviron variables; alert if missing
#' @keywords internal
checkRenviron <- function(var) {
  if(Sys.getenv(var) == "") { stop(paste0("You need to add ", var, "to .Renviron (and start a new session after doing so)"))  }
}

#' INTERNAL: Log in to Qualtrics from institutional URL
#' @keywords internal
qualtricsLogin <- function() {
  checkRenviron("QUALTRICS_LOGIN_URL")
  checkRenviron("QSI_USER")
  checkRenviron("QUALTRICS_PW")

  rD <<- rsDriver(browser = c("chrome"))
  remDr <<- rD[['client']]

  remDr$navigate(Sys.getenv("QUALTRICS_LOGIN_URL"))

  webElem <- remDr$findElement(using = "css selector", value = "input[placeholder='Username']")
  webElem$clearElement()
  webElem$sendKeysToElement(list(Sys.getenv("QSI_USER")))

  webElem <- remDr$findElement(using = "css selector", value = "input[placeholder='Password']")
  webElem$clearElement()
  webElem$sendKeysToElement(list(Sys.getenv("QUALTRICS_PW")))

  remDr$findElement(using = "css selector", value = "button[id='loginButton']")$clickElement()
}


#' Scrape Qualtrics Site Intercept creative ids and names for use in API call
#'
#' Uses Experience Management UI
#'
#' @param creativeHomeURL URL for creative project list on legacy UI; defaults to .Renviron
#' @param cssSelector CSS Selector matching an individual creative
#' @param script Path to text file containing JavaScript to execute on page to wrangle the creatives into an array
#'
#' @return data.frame
#' @export
#'
#' @examples listCreatives()

listCreatives <- function(creativeHomeURL = Sys.getenv("CREATIVE_HOME_URL"),
                          cssSelector = "tr[creatives='creatives']",
                          script = paste0(readLines(paste0(path.package("qualtricks"), "/scrape_qsi_creative.js"), warn = FALSE), collapse = "\n")
                          ) {
  qualtricsLogin()
  Sys.sleep(5)
  remDr$navigate(creativeHomeURL)
  Sys.sleep(5)

  elem <- remDr$findElement(using = "css selector", value = cssSelector)
  creatives <- remDr$executeScript(script, args = list(elem))
  creatives <- bind_rows(lapply(creatives, data.frame, stringsAsFactors = FALSE))

  remDr$close()
  rD$server$stop()

  return(creatives)
}

#' @title Scrape Qualtrics Site Intercept intercept ids and names for use in API call
#'
#' @description
#' Uses legacy UI (not Experience Management)
#' Currently less flexible than listCreatives() since more selectors are needed for zone nav and they're still hardcoded
#'
#' @param interceptHomeURL defaults to .Renviron
#' @param interceptZoneId defaults to .Renviron
#'
#' @return data.frame
#' @export
#'
#' @examples listIntercepts()
listIntercepts <- function(interceptHomeURL = Sys.getenv("INTERCEPT_HOME_URL"),
                           interceptZoneId = Sys.getenv("INTERCEPT_ZONE_ID")
                           ) {
  qualtricsLogin()
  Sys.sleep(5)
  remDr$navigate(interceptHomeURL)
  Sys.sleep(5)

  remDr$findElement(using = "css selector", value = "span[id='ButtonInner_ZoneSelector']")$clickElement()
  remDr$findElement(using = "css selector", value = paste0("a[mouseupcallback='SiteInterceptTools.setCurrentZone(", interceptZoneId, ")']"))$clickElement()
  Sys.sleep(5)

  elem <- remDr$findElement(using = "css selector", value = "ul[class='ElementList InterceptList']")

  script <- paste0(readLines(paste0(path.package("qualtricks"), "/scrape_qsi_intercept.js"), warn = FALSE), collapse = "\n")

  intercepts <- remDr$executeScript(script, args = list(elem))
  intercepts <- bind_rows(lapply(intercepts, data.frame, stringsAsFactors = FALSE)) %>% separate("title", into =c("title", "id"), " - SI_") %>% mutate(id = paste0("SI_", id))

  remDr$close()
  rD$server$stop()

  return(intercepts)
  }


#' Wrapper for getCreativeStats and getInterceptStats API calls
#'
#' https://survey.qualtrics.com/WRAPI/SiteIntercept/docs.php#getInterceptStats_2.4
#'
#' @param projectId Intercept ID or Creative ID; appropriate call will be determined from this string
#' @param startDate YYYY-MM-DD
#' @param endDate YYYY-MM-DD
#' @param timeZone The timezone to aggregate responses relative to. http://php.net/manual/en/timezones.php
#' @param dataType Impressions, Clicks
#' @param interval Hour (default), Day, Month
#'
#' @return data.frame
#' @export
#'
#' @examples getProjectStats(projectId="SI_12345", "2018-01-01", "2018-02-02", dataType="Impressions")

getProjectStats <- function(projectId, startDate, endDate, timeZone="America%2FNew_York", dataType, interval="Hour") {

  checkRenviron("QSI_USER")
  checkRenviron("QSI_TOKEN")

  url <- paste0("https://survey.qualtrics.com/WRAPI/SiteIntercept/api.php?API_SELECT=SiteIntercept&Version=2.4&Request=getCreativeStats",
                "&User=", gsub("@", "%40", Sys.getenv("QSI_USER")),
                "&Token=", Sys.getenv("QSI_TOKEN"),
                "&Format=JSON",
                "&CreativeID=", projectId,
                "&StartDate=", startDate,
                "&EndDate=", endDate,
                "&DataType=", dataType,
                "&TimeZone=", timeZone,
                "&Interval=", interval)
  if(grepl("^SI_", projectId)) {
    url <- gsub("CreativeID", "InterceptID", url)
    url <- gsub("getCreativeStats", "getInterceptStats", url)
  }
  message(url)
  resp <- fromJSON(url)$Result$Data
  setNames(data.frame(projectId, names(resp), unlist(resp), row.names = NULL, stringsAsFactors = FALSE), c("projectId", "date", dataType))
}

#' Update Survey
#'
#' @param surveyId String. Survey ID
#' @param name String. New survey name
#' @param isActive Boolean. Survey status
#' @param expirationStartDate String. Defines the active time range for the survey. Example: {"startDate":"2016-01-01T01:00:00Z", "endDate":"2016-03-01T01:00:00Z"}. See Dates and Times for more information on the date and time format.
#' @param expirationEndDate String. See expirationStartDate
#' @param yourapitoken String from renviron
#' @param ownerID String. The new owner of the survey. Note that the caller must own the survey to set a new owner.
#'
#' @description
#' https://api.qualtrics.com/reference#update-survey
#' @return response() object
#' @export
#'
#' @examples
#' \dontrun{
#' updateSurvey(surveyId="SV_012345678901234", isActive=FALSE)
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
