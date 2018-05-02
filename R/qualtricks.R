#' INTERNAL: Check for requisite .Renviron variables; alert if missing
#'
#' @param var
#'
#' @return
#' @export
#'
#' @examples
#' @keywords internal
checkRenviron <- function(var) {
  if(Sys.getenv(var) == "") { stop(paste0("You need to add ", var, "to .Renviron (and start a new session after doing so)"))  }
}

#' INTERNAL: Log in to Qualtrics from institutional URL
#'
#' @return
#' @export
#'
#' @examples
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
#' Uses Experience Management UI
#'
#' @param creativeHomeURL URL for creative project list on legacy UI; defaults to .Renviron
#' @param cssSelector CSS Selector matching an individual creative
#' @param script Path to text file containing JavaScript to execute on page to wrangle the creatives into an array
#'
#' @return data.frame called creatives and data.frame called intercepts
#' @export
#'
#' @examples

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

#' Scrape Qualtrics Site Intercept intercept ids and names for use in API call
#' Uses legacy UI (not Experience Management)
#' Currently less flexible than listCreatives() since more selectors are needed for zone nav and they're still hardcoded
#'
#' @param interceptHomeURL
#' @param interceptZoneId
#'
#' @return
#' @export
#'
#' @examples
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
#' https://survey.qualtrics.com/WRAPI/SiteIntercept/docs.php#getInterceptStats_2.4
#'
#' @param projectId Intercept ID or Creative ID; appropriate call will be determined from this string
#' @param startDate YYYY-MM-DD
#' @param endDate YYYY-MM-DD
#' @param timeZone The timezone to aggregate responses relative to. http://php.net/manual/en/timezones.php
#' @param dataType Impressions, Clicks
#' @param interval Hour (default), Day, Month
#'
#' @return
#' @export
#'
#' @examples
getProjectStats <- function(projectId, startDate, endDate, timeZone="America%2FNew_York", dataType, interval="Hour") {

  checkRenviron("QSI_USER")
  checkRenviron("QSI_TOKEN")

  url <- paste0("https://survey.qualtrics.com/WRAPI/SiteIntercept/api.php?API_SELECT=SiteIntercept&Version=2.4&Request=getCreativeStats",
                "&User=", gsub("@", "%40", Sys.getenv("QSI_USER")),
                "&Token=", Sys.getenv("QSI_TOKEN"),
                "&Format=", format,
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
  resp <- fromJSON(url)$Result$Data
  setNames(data.frame(projectId, names(resp), unlist(resp), row.names = NULL, stringsAsFactors = FALSE), c("projectId", "date", dataType))
}

