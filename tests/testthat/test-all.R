library(testthat)
library(RSocrata)
library(httr)
library(jsonlite)
library(mime)

## Credentials for testing private dataset and update dataset functionality ##
socrataEmail <- Sys.getenv("SOCRATA_EMAIL", "mark.silverberg+soda.demo@socrata.com")
socrataPassword <- Sys.getenv("SOCRATA_PASSWORD", "7vFDsGFDUG")

context("posixify function")

test_that("posixify returns Long format", {
  df <- read.socrata('http://soda.demo.socrata.com/resource/4334-bgaj.csv')
  dt <- posixify("09/14/2012 10:38:01 PM")
  expect_equal(dt, df$Datetime[1])  ## Check that download matches test
  
  expect_equal("POSIXct", class(dt)[1], label="Long format date data type")
  expect_equal("2012", format(dt, "%Y"), label="year")
  expect_equal("09", format(dt, "%m"), label="month")
  expect_equal("14", format(dt, "%d"), label="day")
  expect_equal("22", format(dt, "%H"), label="hours")
  expect_equal("38", format(dt, "%M"), label="minutes")
  expect_equal("01", format(dt, "%S"), label="seconds")
})


test_that("posixify returns Short format", {
  dt <- posixify("09/14/2012")
  expect_equal("POSIXct", class(dt)[1], label="Short format date data type")
  expect_equal("2012", format(dt, "%Y"), label="year")
  expect_equal("09", format(dt, "%m"), label="month")
  expect_equal("14", format(dt, "%d"), label="day")
  expect_equal("00", format(dt, "%H"), label="hours")
  expect_equal("00", format(dt, "%M"), label="minutes")
  expect_equal("00", format(dt, "%S"), label="seconds")
})

context("Socrata Calendar")

test_that("Calendar Date Short", {
  df <- read.socrata('http://data.cityofchicago.org/resource/y93d-d9e3.csv?$order=debarment_date')
  dt <- df$DEBARMENT.DATE[1] # "05/21/1981"
  expect_equal("POSIXct", class(dt)[1], label="data type of a date")
  expect_equal("81", format(dt, "%y"), label="year")
  expect_equal("05", format(dt, "%m"), label="month")
  expect_equal("21", format(dt, "%d"), label="day")
  expect_equal("00", format(dt, "%H"), label="hours")
  expect_equal("00", format(dt, "%M"), label="minutes")
  expect_equal("00", format(dt, "%S"), label="seconds")
})

test_that("Date is not entirely NA if the first record is bad (issue 68)", {
  
  ## Define and test issue 68
  # df <- read.socrata('http://data.cityofchicago.org/resource/me59-5fac.csv')
  # expect_false(object = all(is.na(df$Creation.Date)),
  #              "Testing issue 68 https://github.com/Chicago/RSocrata/issues/68")
  
  df <- read.socrata("https://data.cityofchicago.org/resource/4h87-zdcp.csv")
  expect_false(object = all(is.na(df$DATE.RECEIVED)),
               "Testing issue 68 https://github.com/Chicago/RSocrata/issues/68")
  
  
  ## Define smaller tests
  dates_clean <- posixify(c("01/01/2011", "01/01/2011", "01/01/2011"))
  dates_mixed <- posixify(c("Date", "01/01/2011", "01/01/2011"))
  dates_dirty <- posixify(c("Date", "junk", "junk"))
  
  ## Execute smaller tests
  expect_true(all(!is.na(dates_clean)))  ## Nothing should be NA
  expect_true(any(is.na(dates_mixed)))   ## Some should be NA
  expect_true(any(!is.na(dates_mixed)))  ## Some should not be NA
  expect_true(all(is.na(dates_dirty)))   ## Everything should be NA
})

context("change money to numeric")

test_that("Fields with currency symbols remove the symbol and convert to money", {
  deniro <- "$15325.65"
  deniro <- no_deniro(deniro)
  expect_equal(15325.65, deniro, label="dollars")
  expect_equal("numeric", class(deniro), label="output of money fields")
})

context("read Socrata")

test_that("read Socrata CSV as default", {
  df <- read.socrata('https://soda.demo.socrata.com/resource/4334-bgaj.csv')
  expect_equal("data.frame", class(df), label="class")
  expect_equal(1007, nrow(df), label="rows")
  expect_equal(9, ncol(df), label="columns")
  expect_equal(c("character", "character", "character", "POSIXct", "numeric", 
                 "numeric", "integer", "character", "character"), 
               unname(sapply(sapply(df, class),`[`, 1)), 
               label="testing column CSV classes with defaults")
})

test_that("read Socrata CSV as character", {
  df <- read.socrata('https://soda.demo.socrata.com/resource/4334-bgaj.csv',
                     stringsAsFactors = FALSE)
  expect_equal("data.frame", class(df), label="class")
  expect_equal(1007, nrow(df), label="rows")
  expect_equal(9, ncol(df), label="columns")
  expect_equal(c("character", "character", "character", "POSIXct", "numeric", 
                 "numeric", "integer", "character", "character"), 
               unname(sapply(sapply(df, class),`[`, 1)))
})

test_that("read Socrata CSV as factor", {
  df <- read.socrata('https://soda.demo.socrata.com/resource/4334-bgaj.csv',
                     stringsAsFactors = TRUE)
  expect_equal("data.frame", class(df), label="class")
  expect_equal(1007, nrow(df), label="rows")
  expect_equal(9, ncol(df), label="columns")
  expect_equal(c("factor", "factor", "factor", "POSIXct", "numeric", "numeric", 
                 "integer", "factor", "factor"), 
               unname(sapply(sapply(df, class),`[`, 1)))
})


test_that("read Socrata JSON as default", {
  df <- read.socrata('https://soda.demo.socrata.com/resource/4334-bgaj.json')
  expect_equal("data.frame", class(df), label="class")
  expect_equal(1007, nrow(df), label="rows")
  expect_equal(11, ncol(df), label="columns")
  expect_equal(c("character", "character", "character", "character", "character", 
                 "character", "character", "character", "character", "character", 
                 "character"), 
               unname(sapply(sapply(df, class),`[`, 1)))
})

test_that("read Socrata JSON as character", {
  df <- read.socrata('https://soda.demo.socrata.com/resource/4334-bgaj.json',
                     stringsAsFactors = FALSE)
  expect_equal("data.frame", class(df), label="class")
  expect_equal(1007, nrow(df), label="rows")
  expect_equal(11, ncol(df), label="columns")
  expect_equal(c("character", "character", "character", "character", "character", 
                 "character", "character", "character", "character", "character", 
                 "character"), 
               unname(sapply(sapply(df, class),`[`, 1)))
})

test_that("read Socrata JSON as factor", {
  df <- read.socrata('https://soda.demo.socrata.com/resource/4334-bgaj.json',
                     stringsAsFactors = TRUE)
  expect_equal("data.frame", class(df), label="class")
  expect_equal(1007, nrow(df), label="rows")
  expect_equal(11, ncol(df), label="columns")
  expect_equal(c("factor", "factor", "factor", "factor", "factor", "factor", 
                 "factor", "factor", "factor", "factor", "factor"), 
               unname(sapply(sapply(df, class),`[`, 1)))
})


test_that("read Socrata No Scheme", {
  expect_error(read.socrata('soda.demo.socrata.com/resource/4334-bgaj.csv'))
})

test_that("readSoQL", {
  df <- read.socrata('http://soda.demo.socrata.com/resource/4334-bgaj.csv?$select=region')
  expect_equal(1007, nrow(df), label="rows")
  expect_equal(1, ncol(df), label="columns")
})

test_that("readSoQLColumnNotFound (will fail)", {
  # SoQL API uses field names, not human names
  expect_error(read.socrata('http://soda.demo.socrata.com/resource/4334-bgaj.csv?$select=Region'))
})

test_that("URL is private (Unauthorized) (will fail)", {
  expect_error(read.socrata('http://data.cityofchicago.org/resource/j8vp-2qpg.json'))
})

test_that("readSocrataHumanReadable", {
  df <- read.socrata('https://soda.demo.socrata.com/dataset/USGS-Earthquake-Reports/4334-bgaj')
  expect_equal(1007, nrow(df), label="rows")
  expect_equal(9, ncol(df), label="columns")
})

test_that("Read data with missing dates", { # See issue #24 & #27 
  # Query below will pull Boston's 311 requests from early July 2011. Contains NA dates.
  df <- read.socrata("https://data.cityofboston.gov/resource/awu8-dc52.csv?$where=case_enquiry_id< 101000295717")
  expect_equal(99, nrow(df), label="rows")
  na_time_rows <- df[is.na(df$TARGET_DT), ]
  expect_equal(33, length(na_time_rows), label="rows with missing TARGET_DT dates")
})

test_that("format is not supported", {
  # Unsupported data formats
  expect_error(read.socrata('http://soda.demo.socrata.com/resource/4334-bgaj.xml'))
})


context("Checks the validity of 4x4")

test_that("is 4x4", {
  expect_true(isFourByFour("4334-bgaj"), label="ok")
  expect_false(isFourByFour("4334c-bgajc"), label="11 characters instead of 9")
  expect_false(isFourByFour("433-bga"), label="7 characters instead of 9")
  expect_false(isFourByFour("433-bgaj"), label="3 characters before dash instead of 4")
  expect_false(isFourByFour("4334-!gaj"), label="non-alphanumeric character")
})


test_that("is 4x4 URL", {
  expect_error(read.socrata("https://soda.demo.socrata.com/api/views/4334c-bgajc"), "4334c-bgajc is not a valid Socrata dataset unique identifier", label="11 characters instead of 9")
  expect_error(read.socrata("https://soda.demo.socrata.com/api/views/433-bga"), "433-bga is not a valid Socrata dataset unique identifier", label="7 characters instead of 9")
  expect_error(read.socrata("https://soda.demo.socrata.com/api/views/433-bgaj"), "433-bgaj is not a valid Socrata dataset unique identifier", label="3 characters before dash instead of 4")
  expect_error(read.socrata("https://soda.demo.socrata.com/api/views/4334-!gaj"), "4334-!gaj is not a valid Socrata dataset unique identifier", label="non-alphanumeric character")
})

test_that("Invalid URL", {
  expect_error(read.socrata("a.fake.url.being.tested"), "a.fake.url.being.tested does not appear to be a valid URL", label="invalid url")
})

context("Test Socrata with Token")

test_that("CSV with Token", {
  df <- read.socrata('https://soda.demo.socrata.com/resource/4334-bgaj.csv', app_token="ew2rEMuESuzWPqMkyPfOSGJgE")
  expect_equal(1007, nrow(df), label="rows")
  expect_equal(9, ncol(df), label="columns")  
})


test_that("readSocrataHumanReadableToken", {
  df <- read.socrata('https://soda.demo.socrata.com/dataset/USGS-Earthquake-Reports/4334-bgaj', app_token="ew2rEMuESuzWPqMkyPfOSGJgE")
  expect_equal(1007, nrow(df), label="rows")
  expect_equal(9, ncol(df), label="columns")  
})

test_that("API Conflict", {
  df <- read.socrata('https://soda.demo.socrata.com/resource/4334-bgaj.csv?$$app_token=ew2rEMuESuzWPqMkyPfOSGJgE', app_token="ew2rEMuESuzWPqMkyPfOSUSER")
  expect_equal(1007, nrow(df), label="rows")
  expect_equal(9, ncol(df), label="columns")
  # Check that function is calling the API token specified in url
  expect_true(substr(validateUrl('https://soda.demo.socrata.com/resource/4334-bgaj.csv?$$app_token=ew2rEMuESuzWPqMkyPfOSGJgE', app_token="ew2rEMuESuzWPqMkyPfOSUSER"), 70, 94)=="ew2rEMuESuzWPqMkyPfOSGJgE")
})

test_that("readAPIConflictHumanReadable", {
  df <- read.socrata('https://soda.demo.socrata.com/dataset/USGS-Earthquake-Reports/4334-bgaj?$$app_token=ew2rEMuESuzWPqMkyPfOSGJgE', app_token="ew2rEMuESuzWPqMkyPfOSUSER")
  expect_equal(1007, nrow(df), label="rows")
  expect_equal(9, ncol(df), label="columns")
  # Check that function is calling the API token specified in url
  expect_true(substr(validateUrl('https://soda.demo.socrata.com/dataset/USGS-Earthquake-Reports/4334-bgaj?$$app_token=ew2rEMuESuzWPqMkyPfOSGJgE', app_token="ew2rEMuESuzWPqMkyPfOSUSER"), 70, 94)=="ew2rEMuESuzWPqMkyPfOSGJgE")
})

test_that("incorrect API Query", {
  # The query below is missing a $ before app_token.
  expect_error(read.socrata("https://soda.demo.socrata.com/resource/4334-bgaj.csv?$app_token=ew2rEMuESuzWPqMkyPfOSGJgE"))
  # Check that it was only because of missing $  
  df <- read.socrata("https://soda.demo.socrata.com/resource/4334-bgaj.csv?$$app_token=ew2rEMuESuzWPqMkyPfOSGJgE")
  expect_equal(1007, nrow(df), label="rows")
  expect_equal(9, ncol(df), label="columns") 
})

test_that("incorrect API Query Human Readable", {
  # The query below is missing a $ before app_token.
  expect_error(read.socrata("https://soda.demo.socrata.com/dataset/USGS-Earthquake-Reports/4334-bgaj?$app_token=ew2rEMuESuzWPqMkyPfOSGJgE"))
  # Check that it was only because of missing $  
  df <- read.socrata("https://soda.demo.socrata.com/dataset/USGS-Earthquake-Reports/4334-bgaj?$$app_token=ew2rEMuESuzWPqMkyPfOSGJgE")
  expect_equal(1007, nrow(df), label="rows")
  expect_equal(9, ncol(df), label="columns") 
})

test_that("List datasets available from a Socrata domain", {
  # Makes some potentially erroneous assumptions about availability
  # of soda.demo.socrata.com
  df <- ls.socrata("https://soda.demo.socrata.com")
  expect_equal(TRUE, nrow(df) > 0)
  # Test comparing columns against data.json specifications:
  # https://project-open-data.cio.gov/v1.1/schema/
  core_names <- as.character(c("issued", "modified", "keyword", "@type", "landingPage", "theme", 
                               "title", "accessLevel", "distribution", "description", 
                               "identifier", "publisher", "contactPoint", "license"))
  expect_equal(as.logical(rep(TRUE, length(core_names))), core_names %in% names(df))
  # Check that all names in data.json are accounted for in ls.socrata return
  expect_equal(as.logical(rep(TRUE, length(names(df)))), names(df) %in% c(core_names))
})


context("Test reading private Socrata dataset with email and password")

privateResourceToReadCsvUrl <- "https://soda.demo.socrata.com/resource/a9g2-feh2.csv"
privateResourceToReadJsonUrl <- "https://soda.demo.socrata.com/resource/a9g2-feh2.json"

test_that("read Socrata CSV that requires a login", {
  # should error when no email and password are sent with the request
  expect_error(read.socrata(url = privateResourceToReadCsvUrl))
  # try again, this time with email and password in the request
  df <- read.socrata(url = privateResourceToReadCsvUrl, email = socrataEmail, password = socrataPassword)
  # tests
  expect_equal(2, ncol(df), label="columns")
  expect_equal(3, nrow(df), label="rows")
})

test_that("read Socrata JSON that requires a login", {
  # should error when no email and password are sent with the request
  expect_error(read.socrata(url = privateResourceToReadJsonUrl))
  # try again, this time with email and password in the request
  df <- read.socrata(url = privateResourceToReadJsonUrl, email = socrataEmail, password = socrataPassword)
  # tests
  expect_equal(2, ncol(df), label="columns")
  expect_equal(3, nrow(df), label="rows")
})

test_that("converts money fields to numeric", {
  # Manual check 
  money <- "$15000"
  numeric_money <- no_deniro(money)
  expect_equal(15000, numeric_money, label="dollars")
  # Use data from Socrata
  df <- read.socrata("https://data.cityofchicago.org/Administration-Finance/Current-Employee-Names-Salaries-and-Position-Title/xzkq-xp2w")
  expect_equal("numeric", class(df$Employee.Annual.Salary))
})
  
context("write Socrata datasets")

test_that("add a row to a dataset", {
  datasetToAddToUrl <- "https://soda.demo.socrata.com/resource/xh6g-yugi.json"

  # populate df_in with two columns, each with a random number
  x <- sample(-1000:1000, 1)
  y <- sample(-1000:1000, 1)
  df_in <- data.frame(x,y)

  # write to dataset
  write.socrata(df_in,datasetToAddToUrl,"UPSERT",socrataEmail,socrataPassword)

  # read from dataset and store last (most recent) row for comparisons / tests
  df_out <- read.socrata(url = datasetToAddToUrl, email = socrataEmail, password = socrataPassword)
  df_out_last_row <- tail(df_out, n=1)

  expect_equal(df_in$x, as.numeric(df_out_last_row$x), label = "x value")
  expect_equal(df_in$y, as.numeric(df_out_last_row$y), label = "y value")
})


test_that("fully replace a dataset", {
  datasetToReplaceUrl <- "https://soda.demo.socrata.com/resource/kc76-ybeq.json"

  # populate df_in with two columns of random numbers
  x <- sample(-1000:1000, 5)
  y <- sample(-1000:1000, 5)
  df_in <- data.frame(x,y)

  # write to dataset
  write.socrata(df_in,datasetToReplaceUrl,"REPLACE",socrataEmail,socrataPassword)

  # read from dataset for comparisons / tests
  df_out <- read.socrata(url = datasetToReplaceUrl, email = socrataEmail, password = socrataPassword)

  expect_equal(ncol(df_in), ncol(df_out), label="columns")
  expect_equal(nrow(df_in), nrow(df_out), label="rows")
  expect_equal(df_in$x, as.numeric(df_out$x), label = "x values")
  expect_equal(df_in$y, as.numeric(df_out$y), label = "y values")
})
