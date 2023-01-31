library(sf)
library(readr)
library(tidyverse)
library(patchwork)

##import data
#paygap data
paygap <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2022/2022-06-28/paygap.csv')

#postcodes

National_Statistics_Postcode_Lookup_UK_Coordinates <- read_csv("C:/Users/Tan/Downloads/National_Statistics_Postcode_Lookup_UK_Coordinates.csv", 
                                                               col_types = cols(`Postcode 1` = col_skip(), 
                                                                                `Postcode 2` = col_skip(), Easting = col_skip(), 
                                                                                Northing = col_skip(), `Positional Quality` = col_skip(), 
                                                                                `Spatial Accuracy` = col_skip(), 
                                                                                `Last Uploaded` = col_skip(), `Socrata ID` = col_skip()))
View(National_Statistics_Postcode_Lookup_UK_Coordinates)

## reduce size of df
paygap_mini <- select(paygap, post_code, diff_mean_hourly_percent, diff_mean_bonus_percent)

## remove nulls NAs
paygap_mini <- paygap_mini[complete.cases(paygap_mini),]

#rename post code colmn for merge
National_Statistics_Postcode_Lookup_UK_Coordinates <-  National_Statistics_Postcode_Lookup_UK_Coordinates %>% 
  rename(
    post_code = `Postcode 3`
  )

#Join postcodes with paygap data
paygap_join <- inner_join(paygap_mini, National_Statistics_Postcode_Lookup_UK_Coordinates)

## summary of local authorities
paygap_regions <- paygap_join |> group_by(paygap_join[4]) |> 
  summarise(
    avg_hourly= round(mean(diff_mean_hourly_percent),2),
    avg_bonus = round(mean(diff_mean_bonus_percent),2)
  )

## import local authority shapefile

mymap <-st_read("LAD_DEC_2022_UK_BFC.shp", stringsAsFactors = FALSE)

#rename for merge
mymap <- mymap |> 
  rename(
    'Local Authority Name' = LAD22NM
  )

# merge tables
map_and_data <- inner_join(mymap,paygap_regions)

## plot map of hourly
p1 <- ggplot(map_and_data) +
  geom_sf(aes(fill = avg_hourly),lwd = 0.1) +
  theme_void() + 
  scale_fill_distiller(palette='RdYlGn', n.breaks = 8)+
  labs(fill = "Mean % difference\nin hourly pay")+
  theme(legend.title = element_text(size=8),
        legend.text = element_text(size=8))

## plot of bonus
p2 <- ggplot(map_and_data) +
  geom_sf(aes(fill = avg_bonus),lwd = 0.1) +
  theme_void() + 
  scale_fill_distiller(palette='YlGnBu', n.breaks = 8)+
  labs(fill = "Mean % difference\nin bonus pay")+
  theme(legend.title = element_text(size=8),
        legend.text = element_text(size=8))

#join plots
patchwork <- p1+p2

## plot everything & add titles
patchwork + plot_annotation(
  title = 'UK Paygap Data',
  subtitle = "These maps show the mean % difference between male and female hourly & bonus pay\nNegative values indicate women's mean pay is higher",
  caption = "Source: https://gender-pay-gap.service.gov.uk/") & theme(plot.title = element_text(face="bold"))

## save
ggsave("myplot.jpg", width = 12, height = 10, units = "in", dpi = 300)