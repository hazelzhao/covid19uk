library(ggplot2)

# download https://www.gstatic.com/covid19/mobility/Global_Mobility_Report.csv
gm = read.csv("~/Desktop/data/google_mobility/Global_Mobility_Report.csv")
uk = gm[gm$country_region_code == "GB",]
# turn dates into POSIXct
uk = uk[!is.na(uk$date),]
uk$date = as.POSIXct(uk$date)
# manchester as example
# man = uk[grep("manchester", uk$sub_region_1, ignore.case = T),]
# p = ggplot(man, aes(date, retail_and_recreation_percent_change_from_baseline, 
                # group=1)) + geom_line() + ylab("Retail+Recreation") 

# get covid data
source("phe.R")
utlasWithCases = addCasesToUTLAs(utlas, json)
# order by totalCases
utlasWithCases = utlasWithCases[order(utlasWithCases$totalCases, decreasing = TRUE),]
 
m = match(utlas$ctyua19nm, uk$sub_region_1)
m = m[!is.na(m)]

# all those in the gm
# x = uk[grep(uk$sub_region_1[m], uk$sub_region_1, ignore.case = T),]

# the country changes in one category
# namely retail_and_recreation_percent_change_from_baseline
ggplot(uk, 
       aes(date, retail_and_recreation_percent_change_from_baseline, 
              group=sub_region_1)) + geom_line() + ylab("Retail+Recreation") 
# ggplot(uk, 
#        aes(date, grocery_and_pharmacy_percent_change_from_baseline, 
#            group=sub_region_1)) + geom_line() + ylab("grocery_and_pharmacy")

# calculate mean of all categories
df = na.omit(setDT(uk), names(uk)[6:11])
df$meanMobility = rowMeans(df[, 6:11])
# p = ggplot(df, aes(date, all)) + geom_line() 

# function brrowed from README.Rmd
cityWithDaily = function(name = "Leeds", total = FALSE) {
  la = utlas$ctyua19cd[utlas$ctyua19nm == name]
  la = json$utlas[[la]]
  if(is.null(la)) return(NULL)
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
# can show city dailycases
# cityWithDaily(name = "Manchester", total = T) %>% 
#   ggplot(aes(date,cases)) +
#   geom_line() + ggtitle("Manchester total cases")

# top affected regions
x = utlasWithCases$ctyua19nm[1:10] # top affected utlas
# bottom 10
y = utlasWithCases$ctyua19nm[(nrow(utlasWithCases)-30):(nrow(utlasWithCases)-20)] 

generate_Plots <- function(cities) {
  stopifnot(exists("cities"))
  # combine based on date?
  citiesWithCases = data.frame()
  for (e in cities) {
    newdf = cityWithDaily(name=e, total = TRUE)
    if(!is.null(newdf)) {
      citiesWithCases = rbind(citiesWithCases, newdf)
    }
  }
  # same cities all traffic change
  citiesMobility = df[df$sub_region_1 %in% cities, ]
  citiesMobility = citiesMobility[, c("sub_region_1", "date", "meanMobility")]
  # merge on dates?
  citiesWithBoth = merge(citiesMobility, citiesWithCases, 
        by.x = c("sub_region_1","date"), by.y = c("name", "date"))
  c2 = ggplot(citiesWithBoth) + aes(date, meanMobility, group=sub_region_1, col = sub_region_1) + 
    geom_line()
  t2 = ggplot(citiesWithBoth) + aes(date, cases, group=sub_region_1, col = sub_region_1) + 
    geom_line()
  return(c(c1,t1))
}
# gridExtra::grid.arrange(c1,t1,c2,t2, nrow =2)
 