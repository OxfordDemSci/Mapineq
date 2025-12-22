x <- as.data.frame(lavInspect(fit, "coverage"))
avg_coverage <- colMeans(x)

# Identify variables where the average coverage is less than 10%
low_avg_vars <- names(avg_coverage[avg_coverage < 0.10])
print(low_avg_vars)




low_cov_matrix <- x < 0.10

# Extract the names of variables that have ANY pair below 10%
problem_vars <- colnames(x)[apply(low_cov_matrix, 2, any)]

# View the problem variables and their specific low-coverage counts
print(problem_vars)

# Optional: See exactly how many "bad pairs" each variable has
sort(colSums(low_cov_matrix), decreasing = TRUE)


# 1. Get the coverage matrix
cov_mat <- lavInspect(fit, "coverage")

# 2. Find indices where coverage is > 0 but < 0.10
# (We exclude 0 because those are often structural, but < 0.10 is the warning zone)
low_pairs <- which(cov_mat < 0.10 & cov_mat > 0, arr.ind = TRUE)

# 3. Format into a readable table
bad_pairs_list <- data.frame(
  Var1 = rownames(cov_mat)[low_pairs[, 1]],
  Var2 = colnames(cov_mat)[low_pairs[, 2]],
  Coverage = cov_mat[low_pairs]
)

# 4. Remove duplicates (since the matrix is symmetrical)
bad_pairs_list <- bad_pairs_list[low_pairs[, 1] < low_pairs[, 2], ]

print(bad_pairs_list)
