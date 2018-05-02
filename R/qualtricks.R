
#' Scrape Qualtrics Creative and Intercept list for ids to use in API calls
#'
#' @param creativeHomeURL URL for creative project list on legacy UI
#' @param interceptHomeURL URL for intercept list on new UI
#' @param interceptZoneId Qualtrics Zone ID
#'
#' @return data.frame called creatives and data.frame called intercepts
#' @export
#'
#' @examples listProjects()
listProjects <- function(creativeHomeURL = Sys.getenv("CREATIVE_HOME_URL"),
                         interceptHomeURL = Sys.getenv("INTERCEPT_HOME_URL"),
                         interceptZoneId = Sys.getenv("INTERCEPT_ZONE_ID")) {
  if(Sys.getenv("QUALTRICS_PW") == "") { stop("QUALTRICS_PW missing in .Renviron")  }

  rD <- rsDriver(browser = c("chrome"))
  remDr <- rD[['client']]

  # LOGIN ############################################################################################
  remDr$navigate(creativeHomeURL)

  webElem <- remDr$findElement(using = "css selector", value = "input[placeholder='Username']")
  webElem$clearElement()
  webElem$sendKeysToElement(list(Sys.getenv("QSI_USER")))

  webElem <- remDr$findElement(using = "css selector", value = "input[placeholder='Password']")
  webElem$clearElement()
  webElem$sendKeysToElement(list(Sys.getenv("QUALTRICS_PW")))

  remDr$findElement(using = "css selector", value = "button[id='loginButton']")$clickElement()

  Sys.sleep(5)

  # GET CREATIVES  ###################################################################################
  remDr$navigate(creativeHomeURL)
  Sys.sleep(5)

  elem <- remDr$findElement(using = "css selector", value = "tr[creatives='creatives']")

  script <- paste0(readLines(paste0(path.package("qualtricks"), "/scrape_qsi_creative.js"), warn = FALSE), collapse = "\n")

  creatives <- remDr$executeScript(script, args = list(elem))
  creatives <<- bind_rows(lapply(creatives, data.frame, stringsAsFactors = FALSE))

  # GET INTERCEPTS  ############################################################################################
  # New UI doesn't seem to have the IDs yet

  remDr$navigate(interceptHomeURL)
  Sys.sleep(5)

  remDr$findElement(using = "css selector", value = "span[id='ButtonInner_ZoneSelector']")$clickElement()
  remDr$findElement(using = "css selector", value = paste0("a[mouseupcallback='SiteInterceptTools.setCurrentZone(", interceptZoneId, ")']"))$clickElement()
  Sys.sleep(5)

  elem <- remDr$findElement(using = "css selector", value = "ul[class='ElementList InterceptList']")

  # Source this from another file so can change as needed
  script <- paste0(readLines(paste0(path.package("qualtricks"), "/scrape_qsi_intercept.js"), warn = FALSE), collapse = "\n")

  intercepts <- remDr$executeScript(script, args = list(elem))
  intercepts <<- bind_rows(lapply(intercepts, data.frame, stringsAsFactors = FALSE)) %>% separate("title", into =c("title", "id"), " - SI_") %>% mutate(id = paste0("SI_", id))

  remDr$close()
  rD$server$stop()
  }

#' Wrapper for getCreativeStats and getInterceptStats API calls
#'
#' @param user
#' @param token
#' @param format
#' @param projectId
#' @param startDate
#' @param endDate
#' @param timeZone
#' @param dataType
#' @param interval
#'
#' @return
#' @export
#'
#' @examples
getProjectStats <-  function(user=Sys.getenv("QSI_USER"), token=Sys.getenv("QSI_TOKEN"), format="JSON", projectId, startDate, endDate, timeZone="America%2FNew_York", dataType, interval) {
  if(Sys.getenv("QSI_USER") == "") { stop("QSI_USER missing in .Renviron")  }
  if(Sys.getenv("QSI_TOKEN") == "") { stop("QSI_TOKEN missing in .Renviron")  }

  url <- paste0("https://survey.qualtrics.com/WRAPI/SiteIntercept/api.php?API_SELECT=SiteIntercept&Version=2.4&Request=getCreativeStats",
                "&User=", gsub("@", "%40", user),
                "&Token=", token,
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

