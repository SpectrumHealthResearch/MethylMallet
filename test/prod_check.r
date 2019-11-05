library(R.utils)
library(readr)
library(dplyr)

# User-entered params -----------------------------------------------------

out_file <- "../working/test.csv"
ddir <- "../dat/"
n_checks <- 100L
set.seed(777)

# Process Raw Files -------------------------------------------------------

files <- list.files(ddir, full.names = TRUE)
file_names <- strcapture("(GSM.*?)_", files, proto = list(character(1)))[,1]

# Process output file -----------------------------------------------------

n_keys <- countLines(out_file)
check_keys <- sort(sample(seq(2, n_keys), n_checks))

check_lines <- character(n_checks)
for ( i in seq_along(check_keys) ) {
  check_lines[i] <- read_lines(out_file, skip = check_keys[i], n_max = 1)
}

check_data <- read.csv(
  header = FALSE,
  stringsAsFactors = FALSE,
  text = check_lines)

names(check_data) <- scan(
  out_file,
  what = character(),
  sep = ",",
  nlines = 1,
  quiet = TRUE)

# Get sample lines --------------------------------------------------------
f <- function(x, pos) semi_join(x, check_data,
      by = c("chrom"="V1", "pos"="V2", "strand"="V3", "mc_class"="V4"))

read_samples <- function(x) {
  read_tsv_chunked(
      files[x],
      callback = DataFrameCallback$new(f),
      chunk_size = 1e5,
      col_types = list(
        col_integer(),
        col_integer(),
        col_character(),
        col_character(),
        col_skip(),
        col_skip(),
        col_integer())
    ) %>%
    rename_at(vars(methylation_call), list(function(unused) file_names[x]))
}

dat <- lapply(seq_along(files), read_samples)

ref <-
  Reduce(
    function(x,y) full_join(x, y, by = c("chrom", "pos", "strand", "mc_class")),
    dat
  ) %>%
  arrange(chrom, pos, strand, mc_class) %>%
  as.data.frame

# Check if equal ----------------------------------------------------------

all.equal(check_data, ref)
