library(xml2)
library(sf)
library(jsonlite)
library(magrittr)

xmlURL = 'https://publicdashacc.blob.core.windows.net/publicdata?restype=container&comp=list'
dataURL = 'https://c19pub.azureedge.net/'

xml = xml2::read_xml(xmlURL)
xml = xml %>% xml_find_all("//Blob") %>% xml_find_all("//Name") %>% 
  xml_text()
data = xml[grep("data_", xml)]
geojson = xml[grep(".geojson", xml)]

utlas = st_read(paste0(dataURL, xml[grep("utlas", xml)]), stringsAsFactors = F)
# zipped json from url
tmp = file.path(tempdir(),"data.json")
download.file(paste0(dataURL, data[length(data)]),destfile = tmp)
json = readLines(tmp) %>% fromJSON()

json$lastUpdatedAt
# json$utlas[[1]]$name$value
addCasesToUTLAs <- function(utlas, json, d = NA) {
  tmp = utlas
  tmp$totalCases = NA
  for (x in utlas$ctyua19nm) {
    for (y in json$utlas) {
      if(y$name$value == x) {
        if(!is.na(d)) {
          for (v in y$dailyTotalConfirmedCases$date) {
            if(v == d) {
              tmp$totalCases[tmp$ctyua19nm == x] = 
                y$dailyTotalConfirmedCases[
                  y$dailyTotalConfirmedCases$date == d, "value"
                ]
            }
          }
        } else {
          tmp$totalCases[tmp$ctyua19nm == x] =
            unname(unlist(y$totalCases))
        }
      }
    }
  }
  tmp
}
