#' Get Organization
#' @description Gets general information about an organization
#' https://api.qualtrics.com/reference#get-brand-info
#'
#' @param yourdatacenterid Set in .Renviron
#' @param yourapitoken Set in .Renviron
#'
#' @return data.frame
#' @import httr glue jsonlite
#' @export
#'
#' @examples
#' \dontrun{
#' getOrganization(organizationId="hbp")
getOrganization <- function(yourdatacenterid = Sys.getenv("QUALTRICS_DATACENTERID"),
                      yourapitoken = Sys.getenv("QSI_TOKEN"),
                      organizationId
                      ) {

  r <- GET(url = glue::glue("https://{yourdatacenterid}/API/v3/organizations/{organizationId}",
                            organizationId = organizationId),
           add_headers("X-API-TOKEN" = yourapitoken))

  s <- r %>% content("text") %>% fromJSON(simplifyVector = FALSE, simplifyDataFrame = TRUE) %>% .$result %>% unlist %>% t %>% as.data.frame
  return(s)
}
