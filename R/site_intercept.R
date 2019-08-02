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


#' List Intercepts and Creatives
#' @description
#' Scrape intercept and creative ids and names from admin Summary Report page for use in API calls\cr
#' Uses RSelenium to open and scrape Chrome
#'
#' @param summaryReportURL String. URL for license summary report
#' @param pageScript String. Javascript to scrape the tables
#'
#' @return data.frame
#' @export
#' @import RSelenium dplyr
#'
#' @examples
#' #' \dontrun{
#' listInterceptsAndCreatives()
#' }

listInterceptsAndCreatives <- function(summaryReportURL = Sys.getenv("QUALTRICS_SUMMARY_REPORT_URL"),
                                       pageScript = 'var c = [];
                                   document.querySelectorAll("table.StatsTable tbody tr td:nth-of-type(1) a").forEach(function(x) {c.push(x.getAttribute("clickcallback"))})
                                   return c') {
  qualtricsLogin()
  Sys.sleep(5)
  remDr$navigate(summaryReportURL)
  Sys.sleep(5)

  ids <- remDr$executeScript(pageScript) %>% unlist

  projectInfo <- str_match(ids, "CR_[[:print:]]+,|SI_[[:print:]]+,") %>%
    strsplit(",") %>%
    unlist %>%
    matrix(ncol = 2, byrow = TRUE) %>%
    data.frame(stringsAsFactors = FALSE) %>%
    setNames(c("id", "name"))

  remDr$close()
  rD$server$stop()

  return(projectInfo)
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
#' @examples
#' \dontrun{
#' projects <- listInterceptsAndCreatives()
#' getProjectStats(projectId=projects$id[1], Sys.Date()-365, Sys.Date(), dataType = "Impressions", interval="Month")
#' }

getProjectStats <- function(projectId, startDate, endDate, timeZone="America%2FNew_York", dataType = c("Impressions, Clicks"), interval=c("Hour", "Day", "Month")) {
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
