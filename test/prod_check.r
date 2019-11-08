library(R.utils)
library(readr)
library(dplyr)

# User-entered params -----------------------------------------------------

set.seed(777)
out_file <- file.path(Sys.getenv("DDIR"), "methylation.csv")
ddir     <- file.path(Sys.getenv("DDIR"), "methyl-seq-data")
n_checks <- 1000L

# Process Raw Files -------------------------------------------------------

files <- list.files(ddir, pattern = '.*\\.tsv(\\.gz)?$', full.names = TRUE)
file_names <- strcapture("(GSM.*?)_", files, proto = list(character(1)))[,1]

# Process output file -----------------------------------------------------

n_keys <- countLines(out_file)
check_keys <- sort(sample(seq(2, n_keys), n_checks))

subset_chunk <- function(x, pos) {
  x[seq(from = pos, along.with = x) %in% check_keys]
}
check_lines <- read_lines_chunked(
  out_file,
  callback = ListCallback$new(subset_chunk),
  chunk_size = 1e5)

check_data <- read.csv(
  header = FALSE,
  stringsAsFactors = FALSE,
  text = do.call('c', check_lines))

names(check_data) <- scan(
  out_file,
  what = character(),
  sep = ",",
  nlines = 1,
  quiet = TRUE)

# Get sample lines --------------------------------------------------------
semi_join_chunk <- function(x, pos) semi_join(x, check_data, by = c("chrom", "pos", "strand", "mc_class"))

read_samples <- function(x) {
  read_tsv_chunked(
      files[x],
      callback = DataFrameCallback$new(semi_join_chunk),
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

if ( require(doParallel) ) {
  cluster <- makeCluster(detectCores() - 1L)
  registerDoParallel(cluster)
  dat <- foreach(
    f = seq_along(files),
    #.combine = "bind_rows",
    #.inorder = FALSE,
    #.multicombine = TRUE,
    .packages = c("dplyr","readr"),
    .export = c(
      "files",
      "file_names",
      "check_data",
      "read_samples",
      "semi_join_chunk")
  ) %dopar% { read_samples(f) }
  stopCluster(cluster)
} else {
  dat <- lapply(seq_along(files), read_samples)
}

ref <-
  Reduce(
    function(x,y) full_join(x, y, by = c("chrom", "pos", "strand", "mc_class")),
    dat
  ) %>%
  arrange(chrom, pos, strand, mc_class) %>%
  as.data.frame

# Check if equal ----------------------------------------------------------

all.equal(check_data, ref)
