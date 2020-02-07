#' Start a selenium server and browser with or without Docker
#'
#' @param browser defaults to chrome
#' @param useDocker probably don't need this
#'
#' @return remDr
#' @import RSelenium
startSelServer <- function(browser = "chrome", useDocker = FALSE) {
  if(useDocker == TRUE) {
    userDocker <<- TRUE  # for later stop
    shell("docker run --rm -d -p 4445:4444 selenium/standalone-chrome")
    Sys.sleep(1)
    docker.container.id <- gsub(" ", "", strsplit(shell("docker ps -a", intern = TRUE)[2], "selenium")[[1]][1])
    remDr <<- remoteDriver(remoteServerAddr = "localhost", port = 4445L, browserName = "chrome")
    Sys.sleep(1)
    remDr$open()
  } else {
    rD <- rsDriver(browser = c(browser))
    remDr <<- rD[['client']]
  }
}

#' Stop Selenium server
#'
#' @param useDocker ?
stopSelServer <- function(useDocker = useDocker) {
  if(useDocker == TRUE) {
    remDr$close()
    shell(paste("docker kill", gsub(" ", "", strsplit(shell("docker ps -a", intern = TRUE)[2], "selenium")[[1]][1])))
  } else {
    rD$server$stop()
  }
}

#' Format JavaScript bookmarklet that triggers Qualtrics Intercept Edit Preview
#'
#' @param interceptId string
#' @param zoneURL string
#' @return character
formatInterceptBookmarklet <- function(interceptId, zoneURL = Sys.getenv("QSI_ZONE_URL")) {

  script <- "var id='INTERCEPT_ID';
  c='INTERCEPT_ID_container';
  var o=document.getElementById(c);
  if(o) { o.innerHTML='';var d=o; } else { var d=document.createElement('div'); d.id=c; }

  var s=document.createElement('script');
  s.type='text/javascript';
  s.src='https://QSI_ZONE_URL/WRSiteInterceptEngine/?Q_SIID=INTERCEPT_ID&Q_VERSION=0&Q_LOC=\"encodeURIComponent(window.location.href)\"&Q_BOOKMARKLET';
  if(document.body){document.body.appendChild(s);document.body.appendChild(d);}
  console.log('QSI run');"

  script <- gsub("QSI_ZONE_URL", zoneURL, script)
  gsub("INTERCEPT_ID", interceptId, script)
}


