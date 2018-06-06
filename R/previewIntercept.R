#' Start a selenium server and browser with or without Docker
#'
#' @return Opens empty browser window
#' @export
#'
#' @examples
startSelServer <- function(browser = "chrome", useDocker = FALSE) {
  if(useDocker == TRUE) {
    shell("docker run --rm -d -p 4445:4444 selenium/standalone-chrome")
    docker.container.id <- gsub(" ", "", strsplit(shell("docker ps -a", intern = TRUE)[2], "selenium")[[1]][1])
    remDr <- remoteDriver(remoteServerAddr = "localhost", port = 4445L, browserName = "chrome")
    remDr$open()
  } else {
    rD <- rsDriver(browser = c(browser))
    remDr <- rD[['client']]
  }
}

