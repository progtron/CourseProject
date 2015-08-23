# See https://github.com/progtron/CourseProject/blob/master/README.md for a detailed description
# of how this script works.

print("===")
print("Assumptions:")
print("1.. Data fetched & unzipped");
print("2.. UCI HAR Dataset folder in working directory of this script")
print("---")
flush.console()

# Check that the 'UCI HAR Dataset' folder is present; if not, exit with an error message
if (!dir.exists("UCI HAR Dataset")) {
  print("***ERROR:")
  print("UCI HAR Dataset not in working directory!")
  print("As noted in project instructions, please ensure that UCI HAR Dataset is")
  print("fetched, unzipped, and located in the working directory - thanks!")
  print("***")
  flush.console()
}

# To observe progress, updates & info are printed to the console

# Install needed packages, in case they are not present
packages_used <- c("dplyr", "tidyr")
packages_to_install <- packages_used[!(packages_used %in% installed.packages()[,"Package"])]
if(length(packages_to_install)) { install.packages(packages_to_install) }

# Read the data sets. The files have no header and use whitespace separators (1 or 2,
# depending on whether the next reading is negative or not).
test <- read.csv("./UCI HAR Dataset/test/X_test.txt", header = FALSE, sep = "")

print("===")
print("Initial load:")
print(sprintf("Test data has %s observations of %s variables", dim(test)[1], dim(test)[2]))
print("---")
flush.console()

train <- read.csv("./UCI HAR Dataset/train/X_train.txt", header = FALSE, sep = "")

print(sprintf("Train data has %s observations of %s variables", dim(train)[1], dim(train)[2]))
print("---")
flush.console()

# No column headers yet. We can add them from features.txt.
# First, store the list of features into a character vector:
features <- read.delim("./UCI HAR Dataset/features.txt", sep = " ", header = FALSE)

# Name the columns (not strictly necessary, but seems like a good practice)
names(features) <- c("seq", "name")

# Assign names to the columns of the merged data set:
names(test) <- features$name
names(train) <- features$name

# For each data set add columns for activity & subject. Further we also need to replace
# activity codes with descriptive names. We might as well do that up front before adding
# the column.

# Use activity_labels.txt to rename activity codes with user-friendly names.

# Read the labels
activity_labels <-
  read.delim("./UCI HAR Dataset/activity_labels.txt", sep = " ", header = FALSE,
             stringsAsFactors = FALSE)

# Name the columns
names(activity_labels) <- c("code", "name")

# Set up a function which returns the name, given a code
use_activity_label <- function(x) {activity_labels[x,]$name}

# Note that this approach is general enough to handle changes to the activity labels
# i.e. it does not rely on the fact that the current set has 6 labels.

# Start by doing this for the 'test' data set
test_activity_codes <- as.data.frame(readLines("./UCI HAR Dataset/test/y_test.txt"))

# Apply this function & name the new column sensibly
test_activity_names <- as.data.frame(sapply(test_activity_codes, use_activity_label))
names(test_activity_names) <- c("activity")

print("===")
print("Descriptive activity names in data frame: test_activity_names")
print("ASSIGNMENT STEP 3 Completed")
print("---")
flush.console()

# Read the subject data
test_subjects <- as.data.frame(readLines("./UCI HAR Dataset/test/subject_test.txt"))
names(test_subjects) <- c("subject")

# Add the column
test <- cbind(test_activity_names, test_subjects, test)

# Do the same for 'train'
train_activity_codes <- as.data.frame(readLines("./UCI HAR Dataset/train/y_train.txt"))
train_activity_names <- as.data.frame(sapply(train_activity_codes, use_activity_label))
names(train_activity_names) <- c("activity")
train_subjects <- as.data.frame(readLines("./UCI HAR Dataset/train/subject_train.txt"))
names(train_subjects) <- c("subject")
train <- cbind(train_activity_names, train_subjects, train)

# Both data frames now have 563 identically labeled columns
print("===")
print("Merged with activity & subject data:")
print(sprintf("Test data now has %s observations of %s variables", dim(test)[1], dim(test)[2]))
flush.console()
print(sprintf("Train data now has %s observations of %s variables", dim(train)[1], dim(train)[2]))
flush.console()

# Let's merge (concatenate) them.
full <- rbind(test, train)

print("===")
print("Test & train data sets merged into data frame: full")
print("ASSIGNMENT STEP 1 Completed")
print("---")
flush.console()

# We need to extract measurements only for mean and standard deviation. From inspection
# of features_info.txt and features.txt, I will only look for variables which contain
# -mean() and -std(). I'm avoiding meanFreq and some angle measurements which happen
# to have the 'mean' pattern in their names.

# Keep only columns which match the above patterns, plus 'activity' & 'subject' columns.
# This is the requested data frame for all mean's and std's.
means_sds <- full[, grepl("subject|activity|-std\\(\\)|-mean\\(\\)", names(full))]

# We've combined rows from both data sets and cut down to 68 columns.
print("===")
print("Extracted mean- and sd- columns")
print(sprintf("Means & SD data has %s observations of %s variables",
              dim(means_sds)[1], dim(means_sds)[2]))
flush.console()

print("===")
print("Mean & SD values extracted into data frame: means_sds")
print("ASSIGNMENT STEP 2 Completed")
print("---")
flush.console()

# We need to clean up variable names in the data set with mean's & sd's.

# From the features doc and preview of 'means_sds', we should apply the following
# clean-up. I'm trying to make a balance between making a term recognizable and
# expanding it out completely -> unwieldy.
# -- expand prefix t -> time
# -- expand prefix f -> frequency -> freq
# -- expand Acc -> Acceleration -> Accel
# -- expand Mag -> Magnitude
# -- de-duplicate BodyBody -> Body
# Finally, for variables which do not specify an axis, use NA

# I will use a suffix approach for the measure (mean, sd) and axis (X, Y, Z).
# E.g. std()-Y -> sd.Y; mean()-Z -> mean.Z

# Implement clean-up with a series of substitutions.
# I'm choosing substitute strings which are easy to split on (for subsequent tidying)
names(means_sds) <- sub("^t", "time_", names(means_sds))
names(means_sds) <- sub("^f", "freq_", names(means_sds))
names(means_sds) <- sub("Acc", "Accel", names(means_sds))
names(means_sds) <- sub("Mag", "Magnitude", names(means_sds))
names(means_sds) <- sub("BodyBody", "Body", names(means_sds))
names(means_sds) <- sub("-mean\\(\\)-", "\\_mean_", names(means_sds))
names(means_sds) <- sub("-mean\\(\\)$", "\\_mean_NA", names(means_sds))
names(means_sds) <- sub("-std\\(\\)-", "\\_sd_", names(means_sds))
names(means_sds) <- sub("-std\\(\\)$", "\\_sd_NA", names(means_sds))

print("===")
print("Assigned descriptive variable names in data frame: means_sds")
print("ASSIGNMENT STEP 4 Completed")
print("---")
flush.console()

# For the final step we need to generate the mean value of each variable per activity,
# per subject. This data has 3 dimensions:
# 6 activities
# 30 subjects
# 66 variables (68 columns minus activity minus subject)

# We need the mean values for all 66 variables, for every combination of activity & subject.

# So the result will contain 6*30 => 180 rows. Each row will contain the specific
# activity, subject, and 66 mean values for each of the variables => 68 columns.

# dplyr is my friend
library(dplyr)

# convert to dplyr-compatible class
means_sds_tbl <- tbl_df(means_sds)

# Generate the requisite data set:
# -- change subject values from numeric to the form Subject-##
# -- group by activity & subject
# -- summarize by each activity-subject pair (group) across all variables 
activity_subject_means <-
  means_sds_tbl %>%
    mutate(subject = sprintf("Subject-%02d", subject)) %>%
      group_by(activity, subject) %>%
        summarise_each(funs(mean))

print("===")
print("Computed grouped (activity-subject) means for all columns")
print(sprintf("Activity-Subject means have %s observations of %s variables",
              dim(activity_subject_means)[1], dim(activity_subject_means)[2]))
flush.console()

# Time to bring out tidyr
library(tidyr)

# Based on prior inspection of the data, we had introduced "_" separators
# for the various facets of each variable. We will use these now to create
# separate columns
tidy_result <-
  activity_subject_means %>%
    gather(key, value, -activity, -subject) %>%
      extract(key, c("measure", "metric", "func", "axis"), "^(.*)_(.*)_(.*)_(.*)$")

# Except for the mean values, change column types to factor
tidy_result$subject = as.factor(tidy_result$subject)
tidy_result$measure = as.factor(tidy_result$measure)
tidy_result$metric = as.factor(tidy_result$metric)
tidy_result$func = as.factor(tidy_result$func)
tidy_result$axis = as.factor(tidy_result$axis)

print("===")
print("Tidied the result by decomposing variable names into multiple columns")
print(sprintf("The result has %s observations of %s variables",
              dim(tidy_result)[1], dim(tidy_result)[2]))
print("---")
print(tidy_result)
print("---")
flush.console()

str(tidy_result)

print("===")
print("Final tidy table: tidy_result")
print("If you're using RStudio, run 'View(tidy_result)' to inspect the result")
print("ASSIGNMENT STEP 5 Completed")
print("---")
flush.console()
