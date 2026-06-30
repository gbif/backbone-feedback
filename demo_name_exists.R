library(gbifbf)

# Demo: name_exists() now returns both existence status and COL ID

cat("=== Demo: name_exists() with COL ID ===\n\n")

# Example 1: Accepted name
cat("1. Checking accepted name:\n")
result <- name_exists("Trichopria aequata (Thomson, 1858)")
cat("   Name: Trichopria aequata (Thomson, 1858)\n")
cat("   Exists:", result$exists, "\n")
cat("   COL ID:", result$id, "\n\n")

# Example 2: Synonym
cat("2. Checking synonym:\n")
result <- name_exists("Trichopria carinata (Thomson, 1858)")
cat("   Name: Trichopria carinata (Thomson, 1858)\n")
cat("   Exists:", result$exists, "\n")
cat("   COL ID:", result$id, "\n\n")

# Example 3: Non-existent name
cat("3. Checking non-existent name:\n")
result <- name_exists("Fakeus nonexistus Smith, 2099")
cat("   Name: Fakeus nonexistus Smith, 2099\n")
cat("   Exists:", result$exists, "\n")
cat("   COL ID:", result$id, "\n\n")

# Example 4: Using the ID to get more info
cat("4. Using the COL ID to fetch full details:\n")
result <- name_exists("Trichopria carinata (Thomson, 1858)")
if(result$exists) {
  cat("   Found name with ID:", result$id, "\n")
  details <- cb_name_usage_search(result$id)
  cat("   Full details:\n")
  cat("     Name:", details$result$name[1], "\n")
  cat("     Status:", details$result$status[1], "\n")
  cat("     Rank:", details$result$rank[1], "\n")
}
