##############################################################
########## Density estimates of occurence data ###############
##############################################################

setwd("C:/GitHub/is-it/.it-is/udemy-ecology-in-r/Lesson 2 Occurence and species Density")

# For this excersise we will do some simple plotting techniques 
# to provide densities of Trimeresurus spp. (Green pit vipers)
# in Southeast Asia based on example data we will pull from GBIF
# typically this will be done with your own data using your own 
# polygons and shapefiles for your study area, however, this tutorial
# should prepare you for that

# First we will install some new packages, and open existing ones
install.r raster usdm GIStools maps RcolorBrewer ggspatial

install.packages("raster")
install.packages("usdm")
install.packages("GIStools")
install.packages("maps")
install.packages("RcolorBrewer")
install.packages("ggspatial")

install.packages("pacman")
install.packages("maptools")
install.packages("regos")

zipfile <- "C:/Users/cheun/Downloads/rego_1.5.2.zip"
install.packages(zipfile, repos = NULL, type = "source", lib = "C:/Users/cheun/AppData/Local/R/win-library/4.2")



pacman::p_load(sp,raster,usdm,mapview,rgbif,scrubr,GISTools,maps,ggplot2,RColorBrewer,ggspatial)

library(sp)
library(raster)
library(usdm)
library(mapview)
library(rgbif)
library(scrubr)
library(GISTools)
library(maps)
library(ggplot2)
library(RColorBrewer)
library(ggspatial)

# first we will query a large dataset of 6,000 occurence records
# from GBIF. Be patient, this may take a few minutes.
key <- name_suggest(q = "Trimeresurus", rank = "genus")$data$key[1]
occ_search(taxonKey=key, limit=0)$meta$count
dat.all <- occ_search(taxonKey = key, return = "data", limit = 6000)
dat.all <- dat.all$data


# select the data we want to keep for the excersise
dat <- select(dat.all, decimalLongitude, decimalLatitude, species)
# woops! there's an error. Let's try forcing the function by calling
# it through the dplyr package itself. Sometimes this happens
dat <- dplyr::select(dat.all, decimalLongitude, decimalLatitude, species)#sucess!

colnames(dat) <- c("longitude", "latitude", "species")

# now omit any NA values
dat <- na.omit(dat)
#clean the occurence records
dat<-dframe(dat) %>% coord_impossible()
dat<-dframe(dat) %>% coord_unlikely()

# now let's make our spatial data object just as we did in the last lesson
spdat <- SpatialPoints(coords = cbind(dat$longitude, dat$latitude),
                       proj4string = CRS("+init=epsg:4326"))
# and now we re-add our species data
spdat$species <- dat$species

#now lets quickly map our species data. I really like how the 
# NAt Geo map looks, so we will map with that as the background
# also we will reduce the "alpha" which is the opacity of the points
# alpha = 0 is transparent, 0.5 is transluscent, and 1 is opaque
mapview(spdat, map.types = "Esri.NatGeoWorldMap", layer.name = "Species",
        alpha = 0.5)


# ~~~~~~~~~~~~~~~~~~~~ GET YOUR MAP SHAPEFILES ~~~~~~~~~~~~~~~~~~~~~~~~~~


# Great, so now that we have all of our occurence points, we will now get
# some raster shapefiles for countries in Southeast Asia
# to do this, we will use the "getData()" function from the raster package
# the getData() function is incredibly usefull, it can pull raster date such
# as map shapefile, global climate data, and elevation data.
?getData
Thailand<-raster::getData('GADM', country='THA', level=0)
Malaysia<-raster::getData('GADM', country='MYS', level=0)
Indonesia<-raster::getData('GADM', country='IDN', level=0)
Cambodia<-raster::getData('GADM', country='KHM', level=0)
Vietnam<-raster::getData('GADM', country='VNM', level=0)
Myanmar<-raster::getData('GADM', country='MMR', level=0)
Laos<-raster::getData('GADM', country='LAO', level=0)

# match the raster CRS projection with the spatial data
# ignore the warnings, they are just acknowledging new assignment
proj4string(Thailand) <- projection(spdat)
proj4string(Malaysia) <- projection(spdat)
proj4string(Indonesia) <- projection(spdat)
proj4string(Cambodia) <- projection(spdat)
proj4string(Vietnam) <- projection(spdat)
proj4string(Myanmar) <- projection(spdat)
proj4string(Laos) <- projection(spdat)

# Quickly plot one of the the shape files to see what we'eve imported
plot(Thailand) 


#~~~~~~~~~~~~~~~~~~~~~~~ NOW TO CALCULATE DENSITY ~~~~~~~~~~~~~~~~~~~~~~~~~

# First we will use the poly.counts() function in the GIStools package to
# calculate how many occurence points fall in each polygon (country)
# these counts will be stored as "Values" in the global environment window
# on the top right of R studios, when you scroll down to the bottom.

countsindo <- poly.counts(spdat, Indonesia) 
countsmalay <- poly.counts(spdat, Malaysia)
countsthai<- poly.counts(spdat, Thailand)
countsviet<- poly.counts(spdat, Vietnam)
countslaos<- poly.counts(spdat, Laos)
countscamb<- poly.counts(spdat, Cambodia)
countsmyan<- poly.counts(spdat, Myanmar)


# Now we are going to extract the total area from each polygon. 
# To do this, we will call the raster package and use the "area()" 
# function. The output of this will be in meters, since the density
# formula requires km sq, we will divide our output by 1000
ThaiArea <- raster::area(Thailand)/1000000
VietArea <- raster::area(Vietnam)/1000000
LaosArea <- raster::area(Laos)/1000000
MyanArea <- raster::area(Myanmar)/1000000
CambArea <- raster::area(Cambodia)/1000000
IndoArea <- raster::area(Indonesia)/1000000
MalayArea <- raster::area(Malaysia)/1000000


# find density of individuals in each country (individuals/km2)
# using the counts/area values we derived priot to this
densThai <- countsthai / ThaiArea
densViet <- countsviet / VietArea
densLaos <- countslaos / LaosArea
densMyan <- countsmyan / MyanArea
densCamb <- countscamb / CambArea
densIndo <- countsindo / IndoArea
densMalay <- countsmalay / MalayArea


# Now we will create a dataframe for plotting our results
countries<-c("Thailand", "Vietnam", "Laos", "Myanmar", "Cambodia", "Indonesia", "Malaysia")
denscount<-c(densThai, densViet, densLaos, densMyan, densCamb, densIndo, densMalay)
densplot<-data.frame(countries, denscount)
View(densplot) # view our dataframe


# Before we plot the results, lets make an extra row in the data frame
# that represents the percentage value for the total value of density
# represented by each country to see where the largest concentration
# of Trimeresurus spp. are located (according to GBIF records)
densplot$Perc <- densplot$denscount / sum(densplot$denscount) * 100
densplot$Perc <- round(densplot$Perc, digits = 2)
densplot$Perc <- paste(densplot$Perc, "%")


# ~~~~~~~~~~~~~~~~~~~ PLOTTING OUR DATA ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# lets make a plot using ggplot and store it in an object called "densp"

densp <- ggplot(densplot, aes(x=countries, y=denscount, fill = countries))+
  #mwe outline the bar color in black for aesthetic
  geom_bar(stat="identity", color = "black")+ 
  # we will use the function "paste()" after our subtitle text to automatically
  # generate the number of records or "length" of our spdat data
  labs(title = "Density of Trimeresurus Albolabris Observations in SE Asia",
       subtitle = paste("GBIF Records n =", length(spdat),""),
       color = "Percentage",
       fill = "Percentage")+
  theme_minimal()+
  xlab("Countries")+ 
  ylab("Density")+
  theme(plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5),
        text = element_text(size=11))+
  scale_fill_brewer(palette="Greens")+
  geom_text(aes(label = densplot$Perc), vjust = -.5, hjust=0.3) 

# Again, if you wish to expand the plot window, press the "Zoom" button on
# the plot. From there you can copy, save, or modify the size of the figure. 
densp


#~~~~~~~~~~~~~~~~~~~~~~~~~MAPPING OUR DATA~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# For this part of the excersise we will use the highest density location
# which we see from the plot is Vietnam.
# First we will create quadrats within to compute ind/sqkm
# by rasterizing (converting to raster layer) the Vietnam polygon
rViet <- raster(Vietnam)
# next, we will add a standard 0.3 resolution to the raster layer
# we can increase or decrease the resolution between 0 - 1 if we 
# want to make the quadrats smaller or larger
res(rViet) <- 0.3
rViet #check the raster to see what was done


# Now we will create add our Vietnam polygon to the raster layer
# as an additional attribute 
rViet <- rasterize(Vietnam, rViet)
# let's check what we've done
plot(rViet)
# Now lets turn our quadrat raster into a spatial polygon object 
quadrat <- as(rViet, 'SpatialPolygons')
# Quickly check what we've done by converting the quadrat to polygon
plot(quadrat, add=TRUE)
# Now lets add our species occurence points
points(spdat, col='red', cex=.5)


# Summarize the density of points in each cell by "rasterizing"
# the occurences and the polygon grid and counting them
pdViet <- rasterize(coordinates(spdat), rViet, fun='count', background=0)
# plot our density with a scale bar showing high to low density
plot(pdViet)
# plot our Vietnam shapefile outline
plot(Vietnam, add=TRUE)

# Exclude points outside of the study area by using the mask()
# function. This isolates the objects that we want to focus on
mask.points <- mask(pdViet, rViet)
# plot only the points and areas we want to visualize
plot(mask.points)
# plot our outline
plot(Vietnam, add=TRUE)


# ~~~~~~~~~~~~~~~~~~~~~~~Summary Statistics~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# For this part of the excersise, we will keep all of the SE Asian countries
# an analyse the point data within them 
SE.Asia <- rbind(Thailand, Vietnam, Cambodia, Myanmar,
                 Malaysia, Indonesia, Laos, makeUniqueIDs = TRUE) 
# Lets reduce the size of the object by turning it into a spatialpolygon
SE.Asia <- as(SE.Asia, 'SpatialPolygons')
# check the ploygons 
# athough the size is reduced, this may take a few seconds to plot
plot(SE.Asia)


# we will also use only the lat/lon coordinates, so we will convert the spdat
# spatial object to a simpler obect called xy. Note that when extracting a 
# dataframe from an object that contains multiple dataframes like a spatialpoints
# object, we use the "@" symbol to target the specific data, similar to when
# we use the "$" symbol to call upon columns in a data frame
xy <- SpatialPoints(spdat@coords, proj4string = CRS("+init=epsg:4326"))
# We only want points inside the SE.Asia polygon, and not outside
# we do this by usig the "over()" function calling the points 
# first and then the polygon. then we use the !is.na (is not) 
# to remove points outside of the polygon
xy <- xy[!is.na(over(xy, SE.Asia)),]


# We start with our analysis by getting density frequencies
# plot the frequencies of our grid densities 
SEA.freq <- freq(mask.points, useNA='no')
# use the head() function to view the first few rows of
# any data set
head(SEA.freq)
# show a plot of our frequency data
plot(SEA.freq, pch=20)


#plot average number of points per quadrat
# number of quadrats
quad.num <- sum(SEA.freq[,2])
# number of occurences
occ.num<- sum(SEA.freq[,1] * SEA.freq[,2])
muSEA <- occ.num / quad.num
muSEA


#generate a table 
SEA.tab <- data.frame(SEA.freq)
colnames(SEA.tab) <- c('K', 'X')
SEA.tab$Kmu <- SEA.tab$K - muSEA
SEA.tab$Kmu2 <- SEA.tab$Kmu^2
SEA.tab$XKmu2 <- SEA.tab$Kmu2 * SEA.tab$X
head(SEA.tab)

# Find the observed variance Sigma^2 of the point densities
s2SEA <- sum(SEA.tab$XKmu2) / (sum(SEA.tab$X)-1)
s2SEA

# Find the Variance to Mean Ratio (VMR) of the point densities
VMR.SEA <- s2SEA / muSEA
VMR.SEA


#when a dat object in R has multiple data frame, we must use 
# the "@" symbol to call the individual data frame, similar to 
# using the "$" symbol for columns. 
# Find the distance between pairs of points using the coordinate
# pairs from the xy object
d <- dist(xy@coords)
class(d)

# coerce (convert) the dist object into a matrix of values and ignore
# distances from each point to itself
dist.mat <- as.matrix(d)
dist.mat[1:5, 1:5]
diag(dist.mat) <- NA
dist.mat[1:5, 1:5]

# get the minimum distance for each point in the matrix using the 
# apply() function and the "min" function argument
dist.min <- apply(dist.mat, 1, min, na.rm=TRUE)
head(dist.min)

# Get the mean nearest neighbor distance
mean.dist.nn <- mean(dist.min)

# identify which points are the nearest neighbors
dist.min.w <- apply(dist.mat, 1, which.min)



# the purpose of finding these points with near and far corresponding
# points or "neighbors" is that it helps us to identify areas that may need
# work or research. If this were a personal study and we were trying to locate
# areas that are data deficient for our study species, or areas that have 
# minimal occurences based on our surveys. This would be one of the best
# ways to form a management directive and improve surveys based on imperfect
# detection theory.
# a management 
# which are the most isolated classes? Furthest from
# What are the Nearest neighbors? Plot the top 25
plot(SE.Asia)
# plot all of our points
points(xy, cex=0.5, col = "black")
# reverse the order of our points to find the largest distances first
ord <- rev(order(dist.min))
# find the top 25 points
far25 <- ord[1:25]
# find the minimum nearest neighbor values
neighbors <- dist.min.w[far25]
# plot the 25 farthest points in blue (points which are isolated)
points(xy@coords[far25, ], col='blue', pch=20)
# plot points which have many points close to them
points(xy[neighbors, ], col='red')

#---------------------------------------------------------

# We can reproduce this simple plot using mapview
# first we will turn our points into spatialpoint objects
# for maping purposes
# Note that sometimes when mapview is producing a visual of
# large files, it will open the map in your browser instead of in
# the Rstudio environment. Don't be alarmed by this. 
far <- SpatialPoints(xy@coords[far25, ], proj4string = CRS("+init=epsg:4326"))
near <- SpatialPoints(xy[neighbors, ], proj4string = CRS("+init=epsg:4326"))
              
mapview(SE.Asia) + mapview(xy, col.regions = "black") + 
  mapview(far, col.regions = "blue") + mapview(near, col.regions = "red")


# ------------------ REPRODUCE THE PLOT IN GGPLOT

# Again, I personally prefer ggplot. The plots look much nicer than base R
# and the themes are much more customizable than base and mapview

ggplot() +
  #geom_spatial_polygon() from the ggspatial package plots polygons
  # we change the alpha to reduce visibility
  geom_spatial_polygon(data = SE.Asia, aes(x = long, y = lat, group = group,
                        fill="dark green"), size = 0.5, 
                       alpha = 0.2, linetype = 1, color = "black") +
  #geompoint plots the points, pch is the shape of the point
  geom_point(data = as.data.frame(xy),
             aes(x = coords.x1, y = coords.x2, colour = "black"),
             pch = 16, size = 1.5, alpha=0.5) + 
  geom_point(data = as.data.frame(near),
             aes(x = coords.x1, y = coords.x2, colour = "red"),
             pch = 16, size = 1.5, alpha=0.5) + 
  geom_point(data = as.data.frame(far),
             aes(x = coords.x1, y = coords.x2, colour = "blue"),
             pch = 16, size = 1.5, alpha=0.5) + 
  #set themes (fonts and text size dynamics) and labels
  theme_bw() +
  #set manual fil for polygons to be read into the legend
  scale_fill_manual(name=NULL, values = c("dark green" = "dark green"),
                     labels = c("SE Asia")) +
  #set manual color for points to be read into the legend
  scale_color_manual(name=NULL,values = c("black" = "black","blue"="blue","red"="red"),
                     labels = c("points", "furthest","nearest neighbors")) +
  #set themes, fonts, text sizes, legend placement, etc.
  labs(x = "Longitude", y = "Latitude",title = "Trimerueus spp. SE Asia")+
  theme(panel.background = element_rect(fill = "white"),
        plot.background = element_blank(),
        axis.text.y = element_text(face = 2, size = 9, colour = "black",
                                   margin = margin(t = 0, r = 3, b = 0, l = 10)),
        axis.text.x = element_text(face = 2, size = 9, colour = "black",
                                   margin = margin(t = 3, r = 0, b = 5, l = 0)),
        axis.title.y = element_text(face = 2),
        axis.title.x = element_text(face = 2),
        plot.title = element_text(hjust = 0.5),
        axis.ticks = element_line(colour = "black"),
        legend.position = "bottom")


#------------------------------------------------------------------------

# A simple alternative to visualizing desity (without the accompanying analyses)
# is to plot using ggplot an the stat_density2d() function

# first, lets take our overall points and isolate the occurences in Taiwan
# to use for this example

# First, we will get a Taiwan Raster
Taiwan <- raster::getData("GADM", country = "TWN", level = 1)
table(dat.all$country)

# Then we will subset our total GBIF occurences from only Taiwan
dat.dens <- subset(dat.all, country == "Taiwan, Province of China")
dat.dens <- dplyr::select(dat.dens, decimalLongitude, decimalLatitude, species)
colnames(dat.dens) <- c("longitude", "latitude", "species")
dat.dens <- na.omit(dat.dens)
dat.dens.sp <- SpatialPoints(cbind(dat.dens$longitude, dat.dens$latitude),
                             proj4string = CRS("+init=epsg:4326"))
dat.dens.sp$species <- dat.dens$species


# create a mask around the Taiwan polygon
oceanmask <- poly.outer(Taiwan,Taiwan)


# plot the map overall
TWN.Dens <- ggplot() +
  geom_polygon(data = Taiwan, aes(x = long, y = lat, group = group), 
               size = 0.5, fill="white", alpha = 0.5, 
               linetype = 1, color = "black") +
  stat_density2d(data = data.frame(dat.dens.sp), 
                 aes(x = coords.x1, y = coords.x2, 
                     fill = ..level.., alpha = ..level..),
                 size = 0.01, bins = 16, geom = 'polygon') +
  geom_spatial_polygon(data = oceanmask, aes(x = long, y = lat, group = group), 
               size = 0.5, fill="light blue", alpha = 1, 
               linetype = 1) +
  geom_polygon(data = Taiwan, aes(x = long, y = lat, group = group), 
               size = 0.5, fill=NA, alpha = 0.5, 
               linetype = 1, color = "black") +
  scale_fill_gradient(low = "green", high = "red") +
  scale_alpha(range = c(0.00, 0.25), guide = FALSE) +
  theme(legend.position = "none", text = element_text(size = 12),
        plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5))+
  labs(title = "Trimeresurus spp. density Taiwan",
       subtitle = "n = 517") +
  # manually set coordinates
  coord_cartesian(xlim=c(119.5, 122.1), ylim=c(21, 26))
TWN.Dens


# plot by species
TWN.Dens.sp <- ggplot() +
  geom_polygon(data = Taiwan, aes(x = long, y = lat, group = group), 
               size = 0.5, fill="white", alpha = 0.5, 
               linetype = 1, color = "black") +
  stat_density2d(data = data.frame(dat.dens.sp), 
                 aes(x = coords.x1, y = coords.x2, 
                     fill = ..level.., alpha = ..level..),
                 size = 0.01, bins = 16, geom = 'polygon') +
  geom_spatial_polygon(data = oceanmask, aes(x = long, y = lat, group = group), 
                       size = 0.5, fill="light blue", alpha = 1, 
                       linetype = 1) +
  geom_polygon(data = Taiwan, aes(x = long, y = lat, group = group), 
               size = 0.5, fill=NA, alpha = 0.5, 
               linetype = 1, color = "black") +
  scale_fill_gradient(low = "green", high = "red") +
  scale_alpha(range = c(0.00, 0.25), guide = FALSE) +
  theme(legend.position = "none", text = element_text(size = 12),
        plot.title = element_text(hjust = 0.5),
        plot.subtitle = element_text(hjust = 0.5))+
  labs(title = "Trimeresurus spp. density Taiwan",
       subtitle = "n = 517")+
  # manually set coordinates
  coord_cartesian(xlim=c(119.5, 122.1), ylim=c(21, 26))+
  facet_wrap(~species)
TWN.Dens.sp


