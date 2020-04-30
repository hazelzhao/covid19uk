


# covid19uk

![.github/workflows/main.yml](https://github.com/layik/covid19uk/workflows/.github/workflows/main.yml/badge.svg)

Some basic analysis to go with the eAtlas covid19UK application.

Currently the date released by PHE in their dashboard can be found under
their React app which is made of two API endpoints. These are:

  - [XML](https://publicdashacc.blob.core.windows.net/publicdata?restype=container&comp=list)
    of data released.
  - [actual](https://c19pub.azureedge.net/) endpoint to the data.

Understanding the structure of the data released:

``` r
# see phe.R for details of the code.
source("phe.R")
```

``` r
# data from phe is
names(json)
```

    ## [1] "lastUpdatedAt" "disclaimer"    "overview"      "countries"    
    ## [5] "regions"       "utlas"         "ltlas"

``` r
# so last released data is
json$lastUpdatedAt
```

    ## [1] "2020-04-29T21:32:34.352917Z"

Nicely, they also release geometries and we can generate maps. For
example to get thee latest figures of the regions:

``` r
utlasWithCases = addCasesToUTLAs(utlas, json)
plot(utlasWithCases[,"totalCases"])
```

![](README_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->

A simple function in the `phe.R` file can also take a specific date, the
data starts from `31st of Jan`. So lets use the lockdown date of
`2020-3-23` and seee what the UK looked liek back then:

``` r
date = "2020-03-20"
utlasWithCases = addCasesToUTLAs(utlas, json, date)
plot(utlasWithCases[,"totalCases"], main = date)
```

![](README_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

The greater London:

``` r
date = "2020-03-23"
utlasWithCases = addCasesToUTLAs(utlas, json, date)
bbx = osmdata::getbb('Greater London, U.K.') 
bbx = c(xmin = bbx[1,1], ymin = bbx[2,1], xmax = bbx[1,2], ymax = bbx[2,2])
london = st_crop(utlasWithCases, bbx)
```

    ## although coordinates are longitude/latitude, st_intersection assumes that they are planar

``` r
plot(london[,"totalCases"], main = paste0("London on ", date))
```

![](README_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->

And we can see a line chart of, say Leeds:

``` r
library(ggplot2)
cityWithDaily = function(name = "Leeds", total = FALSE) {
  la = utlas$ctyua19cd[utlas$ctyua19nm == name]
  la = json$utlas[[la]]
  cc = as.data.frame(la$dailyConfirmedCases)
  if(total) {
      cc = la$dailyTotalConfirmedCases
  }
  # cc = data.frame(matrix(unlist(cc), nrow=length(cc), byrow=T))
  names(cc) = c("date", "cases")
  cc$date = as.POSIXct(as.character(cc$date))
  cc$cases = as.numeric(as.character(cc$cases))
  cc$name = name
  cc
}
# cityWithDaily() %>% ggplot(aes(date,cases)) + geom_bar(stat="identity")
cityWithDaily(total = T) %>% ggplot(aes(date,cases)) + geom_line() + ggtitle("Leeds total cases")

cityWithDaily() %>% ggplot(aes(date,cases)) + geom_line()
```

<img src="README_files/figure-gfm/leeds-1.png" width="50%" /><img src="README_files/figure-gfm/leeds-2.png" width="50%" />
Total cases for Leeds on the left and daily ones on the right.

Lets get some population data:

``` r
popFile = file.path(tempdir(), "ukmidyearestimates20182019ladcodes.xls")
url = "https://www.ons.gov.uk/file?uri=%2fpeoplepopulationandcommunity%2fpopulationandmigration%2fpopulationestimates%2fdatasets%2fpopulationestimatesforukenglandandwalesscotlandandnorthernireland%2fmid20182019laboundaries/ukmidyearestimates20182019ladcodes.xls"
download.file(url, destfile = popFile)
pop = readxl::read_xls(popFile, sheet = 6)
names(pop) = pop[4,]
pop = pop[5:nrow(pop),]
pop = pop[!is.na(pop$`All ages`), ]
# are they in here?
m = match(utlasWithCases$ctyua19cd, pop$Code)
# length m = nrow(utlasWithCases) == 173
pop$`All ages` = as.numeric(pop$`All ages`)
# pop[pop$Name == "Leeds","All ages"]
# boxplot(pop[pop$Geography1 == "Unitary Authority", "All ages"])
```

Now we can calculate the infection rate of (1/100K) for each of them

``` r
utlasWithCases = addCasesToUTLAs(utlas, json)
utlasWithCases$population = pop[m,][["All ages"]]
utlasWithCases$ir = utlasWithCases$totalCases/(utlasWithCases$population/1e5)
plot(utlasWithCases[,"ir"], main = paste0("Infection rate per 100k on ", Sys.Date()))
```

![](README_files/figure-gfm/unnamed-chunk-7-1.png)<!-- -->

Get countries data?

``` r
countriesWithCases = addCasesToUTLAs(countries, json, geo = "countries")
```

## Google Mobility

We could look at the Google mobility data released
[here](https://www.google.com/covid19/mobility/). Upon a an initial
look, I could not see any obvious correlation between total case numbers
in a local authority and amount of drop in mobility. That is to see if
areas with less compliance with lockdown leading to more cases.

The code can be found here in the repo. The following image was
generated from the code and shows the top hotpspots in the UK on 29th
April 2020 and corresponding Google mobility data. Also, the not so hot
spots with the same corresponding traffic flow drop rates.
![](https://pbs.twimg.com/media/EWyBxLYWkAE5MBO?format=jpg&name=medium)

## Apple Mobility

Quick look at the Apple Mobility data here on 30th April 2020, the
granularity is an issue and is only useful for a national level
analytics.

``` r
# download https://www.apple.com/covid19/mobility
am = read.csv("applemobilitytrends-2020-04-28.csv")
length(am[am$region =="England",])
#> 1
# dates start from 2020.01.13 to ...
```
