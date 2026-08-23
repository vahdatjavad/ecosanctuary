# Set this to the question-index.csv file in your question-bank repository.
index_file <- "/path/to/question-bank/question-index.csv"

# Choose explicit IDs, or leave NULL and use n/seed/filters below.
selected_ids <- NULL

ecosanctuary::build_quiz(
  index_file = index_file,
  title = "My course quiz",
  ids = selected_ids,
  n = NULL,
  seed = NULL,
  topics = NULL,
  difficulties = NULL,
  category = "My course question bank",
  replicates = 1
)
