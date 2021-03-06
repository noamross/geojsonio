#' Convert spatial data files to GeoJSON from various formats.
#'
#' You can use a web interface called Ogre, or do conversions locally using the
#' rgdal package.
#'
#' @importFrom httr GET POST content stop_for_status upload_file
#' @importFrom maptools readShapeSpatial
#' @importFrom rgdal readOGR writeOGR ogrListLayers
#' @importFrom plyr rbind.fill
#' @export
#' @param input The file being uploaded, path to the file on your machine.
#' @param method One of web or local. Matches on partial strings.
#' @param output Destination for output geojson file. Defaults to root directory \code{~/}
#' @param parse (logical) To parse geojson to data.frame like structures if possible. 
#' Default: \code{FALSE}
#' @description
#' The web option uses the Ogre web API. Ogre currently has an output size limit of 15MB.
#' See here \url{http://ogre.adc4gis.com/} for info on the Ogre web API.
#' The local option uses the function \code{\link{writeOGR}} from the package rgdal.
#'
#' Note that for Shapefiles, GML, MapInfo, and VRT, you need to send zip files
#' to Ogre. For other file types (.bna, .csv, .dgn, .dxf, .gxt, .txt, .json,
#' .geojson, .rss, .georss, .xml, .gmt, .kml, .kmz) you send the actual file with
#' that file extension.
#'
#' If you're having trouble rendering geoJSON files, ensure you have a valid
#' geoJSON file by running it through a geoJSON linter \url{http://geojsonlint.com/}.
#' @examples \dontrun{
#' file <- system.file("examples", "norway_maple.kml", package = "geojsonio")
#'
#' # KML type file - using the web method
#' file_to_geojson(input=file, method='web', output='kml_web')
#' ## read into memory
#' file_to_geojson(input=file, method='web', output = ":memory:")
#' file_to_geojson(input=file, method='local', output = ":memory:")
#'
#' # KML type file - using the local method
#' file_to_geojson(input=file, method='local', output='~/kml_local')
#'
#' # Shp type file - using the web method - input is a zipped shp bundle
#' file <- system.file("examples", "bison.zip", package = "geojsonio")
#' file_to_geojson(file, method='web', output='shp_web')
#'
#' # Shp type file - using the local method - input is the actual .shp file
#' file <- system.file("examples", "bison.zip", package = "geojsonio")
#' dir <- tempdir()
#' unzip(file, exdir = dir)
#' list.files(dir)
#' shpfile <- file.path(dir, "bison-Bison_bison-20130704-120856.shp")
#' file_to_geojson(shpfile, method='local', output='shp_local')
#' file_to_geojson(shpfile, method='local', output=':memory:')
#'
#' # Get data and save map data
#' splist <- c('Accipiter erythronemius', 'Junco hyemalis', 'Aix sponsa')
#' keys <- sapply(splist, function(x) gbif_lookup(name=x, kingdom='plants')$speciesKey,
#'    USE.NAMES=FALSE)
#' out <- occ_search(keys, georeferenced=TRUE, limit=50, return='data')
#' dat <- ldply(out)
#' datgeojson <- spocc_stylegeojson(input=dat, var='name',
#'    color=c('#976AAE','#6B944D','#BD5945'), size=c('small','medium','large'))
#'
#' # Put into a github repo to view on the web
#' write.csv(datgeojson, '~/github/sac/mygeojson/rgbif_data.csv')
#' file <- '~/github/sac/mygeojson/rgbif_data.csv'
#' file_to_geojson(file, method='web', destpath='~/github/sac/mygeojson/', output='rgbif_data')
#'
#' # Neighborhoods in the US
#' url <- 'http://www.nws.noaa.gov/geodata/catalog/national/data/ci08au12.zip'
#' out <- file_to_geojson(input=url, method='web', output='cities')
#' }

file_to_geojson <- function(input, method = "web", output = "~/", parse = FALSE) {
  method <- match.arg(method, choices = c("web", "local"))
  if (method == "web") {
    url <- "http://ogre.adc4gis.com/convert"
    input <- handle_remote(input)
    tt <- POST(url, body = list(upload = upload_file(input)))
    stop_for_status(tt)
    out <- content(tt, as = "text")
    if (output == ":memory:") {
      jsonlite::fromJSON(out, parse)
    } else {
      fileConn <- file(paste0(output, ".geojson"))
      writeLines(out, fileConn)
      close(fileConn)
      message(paste0("Success! File is at ", output, ".geojson"))
      invisible(paste0(path.expand(output), ".geojson"))
    }
  } else {
    fileext <- ftype(input)
    mem <- ifelse(output == ":memory:", TRUE, FALSE)
    output <- ifelse(output == ":memory:", tempfile(), output)
    output <- path.expand(output)
    if (fileext == "kml") {
      my_layer <- ogrListLayers(input)
      x <- readOGR(input, layer = my_layer[1], drop_unsupported_fields = TRUE)
      unlink(paste0(output, ".geojson"))
      writeOGR(x, paste0(output, ".geojson"), basename(output), driver = "GeoJSON", check_exists = FALSE)
      if (mem) {
        jsonlite::fromJSON(paste0(output, ".geojson"), parse)
      } else {
        message(paste0("Success! File is at ", output, ".geojson"))
        invisible(paste0(output, ".geojson"))
      }
    } else if (fileext == "shp") {
      x <- readShapeSpatial(input)
      unlink(paste0(output, ".geojson"))
      writeOGR(x, paste0(output, ".geojson"), basename(output), driver = "GeoJSON", check_exists = FALSE)
      if (mem) {
        jsonlite::fromJSON(paste0(output, ".geojson"), parse)
      } else {
        message(paste0("Success! File is at ", output, ".geojson"))
        invisible(paste0(output, ".geojson"))
      }
    } else if (fileext == "url") {
      unlink(paste0(output, ".geojson"))
      x <- readOGR(input, ogrListLayers(input))
      unlink(paste0(output, ".geojson"))
      writeOGR(x, paste0(output, ".geojson"), basename(output), driver = "GeoJSON", check_exists = FALSE)
      if (mem) {
        jsonlite::fromJSON(paste0(output, ".geojson"), parse)
      } else {
        message(paste0("Success! File is at ", output, ".geojson"))
        invisible(paste0(output, ".geojson"))
      }
    } else {
      stop("only .shp, .kml, and url's are supported")
    }
  }
}

ftype <- function(z) {
  if (is.url(z)) {
    "url"
  } else {
    fileext <- strsplit(z, "\\.")[[1]]
    fileext[length(z)]
  }
}

is.url <- function(x){
  grepl("https?://", x)
}

# If given a url for a zip file, download it give back a path to the temporary file
handle_remote <- function(x){
  if (!grepl('http://', x)) { 
    x 
  } else {
    tfile <- tempfile(fileext = ".zip")
    download.file(x, destfile = tfile)
    tfile
  }
}
