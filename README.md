# CourseProject
Course Project for Coursera: Getting and Cleaning Data (August 2015)

Let's begin with a look at the project:

You should create one R script called run_analysis.R that does the following.

1. Merges the training and the test sets to create one data set.
2. Extracts only the measurements on the mean and standard deviation for each measurement. 
3. Uses descriptive activity names to name the activities in the data set
4. Appropriately labels the data set with descriptive variable names. 
5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

Unzip the data. There are a bunch of info files at the top level and two dirs: `test`, `train`. OK. Presumably these contain the sets to be merged.

There are 30 subjects: 21 in the training set and 9 in the test set. The data set contains observations across 561 variables (`features.txt`) for 6 activities (`activity_labels.txt`). The goal of the published project was to train an SVM with the training set and make predictions for the test set. That's not relevant to our exercise but provides context.

The discussion forum contains a [note](https://class.coursera.org/getdata-031/forum/thread?thread_id=28) from Course TA David Hood to ignore `Inertial Signals` (4th bullet).

`/test`
* 2947 observations of 561 variables (`X_test.txt`)
* 9 subjects (`subject_test.txt`)
* 6 labels (`y_test.txt`)

`/train`
* 7352 observations of 561 variables (`X_train.txt`)
* 21 subjects (`subject_train.txt`)
* 6 labels (`y_train.txt`)

The 561 variables are described in `features.txt`.

My approach is described below. I will complete all steps but not necessarily in the order specified. In `run_analysis.R` I have included `print` statements to inform about progress while it runs.

### Assumptions about data location
1. Data fetched & unzipped
2. UCI HAR Dataset folder in working directory of this script

The proper location of the data files is essential to the success of this script. Check that the `UCI HAR Dataset` folder is present where expected; if not, issue an error message.  
```
if (!dir.exists("UCI HAR Dataset")) {
  print("***ERROR:")
  print("UCI HAR Dataset not in working directory!")
  print("As noted in project instructions, please ensure that UCI HAR Dataset is")
  print("fetched, unzipped, and located in the working directory - thanks!")
  print("***")
  flush.console()
}
```

Begin by installing needed packages, in case they are not present.  
`packages_used <- c("dplyr", "tidyr")`  
`packages_to_install <- packages_used[!(packages_used %in% installed.packages()[,"Package"])]`  
`if(length(packages_to_install)) install.packages(packages_to_install)`

Read the data sets. The files have no header and use whitespace separators (1 or 2, depending on whether the next reading is negative or not).  
`test <- read.csv("./UCI HAR Dataset/test/X_test.txt", header = FALSE, sep = "")`  
`train <- read.csv("./UCI HAR Dataset/train/X_train.txt", header = FALSE, sep = "")`

No column headers yet. We can add them from `features.txt`. First, store the list of features into a character vector.  
`features <- read.delim("./UCI HAR Dataset/features.txt", sep = " ", header = FALSE)`

Name the columns (not strictly necessary, but seems like a good practice).  
`names(features) <- c("seq", "name")`

Assign names to the columns of the merged data set.  
`names(test) <- features$name`  
`names(train) <- features$name`

For each data set add columns for `activity` & `subject`. Further we also need to replace activity codes with descriptive names. We might as well do that up front before adding the column.

Use `activity_labels.txt` to rename activity codes with user-friendly names.

Read the labels.  
```
activity_labels <-  
  read.delim("./UCI HAR Dataset/activity_labels.txt", sep = " ", header = FALSE,  
             stringsAsFactors = FALSE)`
```

Name the columns.  
`names(activity_labels) <- c("code", "name")`

Set up a function which returns the name, given a code.  
`use_activity_label <- function(x) {activity_labels[x,]$name}`

Note that this approach is general enough to handle changes to the activity labels i.e. it does not rely on the fact that the current set has 6 labels.

Start by doing this for the `test` data set.  
`test_activity_codes <- as.data.frame(readLines("./UCI HAR Dataset/test/y_test.txt"))`

Apply this function & name the new column sensibly (`activity`).  
`test_activity_names <- as.data.frame(sapply(test_activity_codes, use_activity_label))`  
`names(test_activity_names) <- c("activity")`

#### Descriptive activity names in data frame: `test_activity_names`
### This completes STEP 3 of the assignment.

Read the subject data & name the column `subject`.  
`test_subjects <- as.data.frame(readLines("./UCI HAR Dataset/test/subject_test.txt"))`  
`names(test_subjects) <- c("subject")`

Add the column.  
`test <- cbind(test_activity_names, test_subjects, test)`

Do the same for `train`.  
`train_activity_codes <- as.data.frame(readLines("./UCI HAR Dataset/train/y_train.txt"))`  
`train_activity_names <- as.data.frame(sapply(train_activity_codes, use_activity_label))`  
`names(train_activity_names) <- c("activity")`  
`train_subjects <- as.data.frame(readLines("./UCI HAR Dataset/train/subject_train.txt"))`  
`names(train_subjects) <- c("subject")`  
`train <- cbind(train_activity_names, train_subjects, train)`

`test` and `train` data frames are now combined with their respective activity & subject info and now have 563 identically labeled columns.

Let's merge (concatenate) them.  
`full <- rbind(test, train)`

#### Test & train data sets merged into data frame: `full`
### This completes STEP 1 of the assignment.

We need to extract measurements only for mean and standard deviation. From inspection of `features_info.txt` and `features.txt`, I will only look for variables which contain '-mean()' and '-std()'. I'm avoiding 'meanFreq' and some angle measurements which happen to have the 'mean' pattern in their names.

Keep only columns which match the above patterns, plus 'activity' & 'subject' columns. This is the requested data frame for all mean's and std's.  
`means_sds <- full[, grepl("subject|activity|-std\\(\\)|-mean\\(\\)", names(full))]`

We've combined rows from both data sets and cut down to 68 columns by extracting only the mean- and sd- columns. These are visible in the data frame `means_sds`.

#### Mean & SD values extracted into data frame: `means_sds`
### This completes STEP 2 of the assignment.

We need to clean up variable names in the data set with mean's & sd's.

From the features docs and preview of `means_sds`, we should apply the following clean-up. I'm trying to make a balance between making a term recognizable and expanding it out completely which can make the names unwieldy.
* Expand prefix `t` -> `time`
* Expand prefix `f` -> frequency -> `freq`
* Expand `Acc` -> Acceleration -> `Accel`
* Expand `Mag` -> `Magnitude`
* De-duplicate `BodyBody` -> `Body`
* Finally, for variables which do not specify an axis, use `NA`

I will use a suffix approach for the measure (mean, sd) and axis (X, Y, Z). e.g. `std()-Y` -> `sd_Y`; `mean()-Z` -> `mean_Z`

The only package I could find which could accept find & replace vectors was rather obscure and had a bunch of dependencies (`qdap`). So we'll simply implement clean-up with a series of substitutions. I'm choosing substitute strings which are easy to split on (for subsequent tidying).  
`names(means_sds) <- sub("^t", "time_", names(means_sds))`  
`names(means_sds) <- sub("^f", "freq_", names(means_sds))`  
`names(means_sds) <- sub("Acc", "Accel", names(means_sds))`  
`names(means_sds) <- sub("Mag", "Magnitude", names(means_sds))`  
`names(means_sds) <- sub("BodyBody", "Body", names(means_sds))`  
`names(means_sds) <- sub("-mean\\(\\)-", "\\_mean_", names(means_sds))`  
`names(means_sds) <- sub("-mean\\(\\)$", "\\_mean_NA", names(means_sds))`  
`names(means_sds) <- sub("-std\\(\\)-", "\\_sd_", names(means_sds))`  
`names(means_sds) <- sub("-std\\(\\)$", "\\_sd_NA", names(means_sds))`

#### Assigned descriptive variable names in data frame: `means_sds`
### This completes STEP 4 of the assignment.

For the final step we need to generate the mean value of each variable per activity, per subject. This data has 3 dimensions:

1. 6 activities
2. 30 subjects
3. 66 variables (68 columns minus `activity` minus `subject`)

We need the mean values for all 66 variables, for every combination of activity & subject.

So the end result will contain 6*30 => 180 rows. Each row will contain the specific activity, subject, and 66 mean values for each of the variables => 68 columns.

`dplyr` is my friend.  
`library(dplyr)`

Convert to dplyr-compatible class.  
`means_sds_tbl <- tbl_df(means_sds)`

Generate the requisite data set:
* Change subject values from numeric to the form Subject-##
* Group by activity & subject
* Summarize by each activity-subject pair (group) across all variables:
```
activity_subject_means <-
  means_sds_tbl %>%
    mutate(subject = sprintf("Subject-%02d", subject)) %>%
      group_by(activity, subject) %>%
        summarise_each(funs(mean))
```

At this point we've computed the grouped (activity-subject) means for all columns in table `activity_subject_means`

Time to bring out tidyr!  
`library(tidyr)`

Based on prior inspection of the data, we had introduced '_' separators for the various facets of each variable. We will use these now to create separate columns.
```
tidy_result <-
  activity_subject_means %>%
    gather(key, value, -activity, -subject) %>%
      extract(key, c("measure", "metric", "func", "axis"), "^(.*)_(.*)_(.*)_(.*)$")
```

Final clean-up. Except for the mean values, change column types to factor.  
`tidy_result$subject = as.factor(tidy_result$subject)`
`tidy_result$measure = as.factor(tidy_result$measure)`
`tidy_result$metric = as.factor(tidy_result$metric)`
`tidy_result$func = as.factor(tidy_result$func)`
`tidy_result$axis = as.factor(tidy_result$axis)`

We've tidied the result by decomposing variable names into multiple columns in the table `tidy_result`.

Print the summary of this table.  
`str(tidy_result)`

#### Final tidy table: `tidy_result`
### This completes STEP 5 of the assignment, the final step.

Here's what `tidy_result` looks like:
```
Source: local data frame [11,880 x 7]

   activity    subject measure    metric func axis     value
1    LAYING Subject-01    time BodyAccel mean    X 0.2802306
2    LAYING Subject-02    time BodyAccel mean    X 0.2601134
3    LAYING Subject-03    time BodyAccel mean    X 0.2767164
4    LAYING Subject-04    time BodyAccel mean    X 0.2746916
5    LAYING Subject-05    time BodyAccel mean    X 0.2813734
6    LAYING Subject-06    time BodyAccel mean    X 0.2395079
7    LAYING Subject-07    time BodyAccel mean    X 0.2728505
8    LAYING Subject-08    time BodyAccel mean    X 0.2635592
9    LAYING Subject-09    time BodyAccel mean    X 0.2591955
10   LAYING Subject-10    time BodyAccel mean    X 0.2215982
..      ...        ...     ...       ...  ...  ...       ...
```
`str(tidy_result)`
```
Classes ‘tbl_df’, ‘tbl’ and 'data.frame':	11880 obs. of  7 variables:
 $ activity: Factor w/ 6 levels "LAYING","SITTING",..: 1 1 1 1 1 1 1 1 1 1 ...
 $ subject : Factor w/ 30 levels "Subject-01","Subject-02",..: 1 2 3 4 5 6 7 8 9 10 ...
 $ measure : Factor w/ 2 levels "freq","time": 2 2 2 2 2 2 2 2 2 2 ...
 $ metric  : Factor w/ 10 levels "BodyAccel","BodyAccelJerk",..: 1 1 1 1 1 1 1 1 1 1 ...
 $ func    : Factor w/ 2 levels "mean","sd": 1 1 1 1 1 1 1 1 1 1 ...
 $ axis    : Factor w/ 4 levels "NA","X","Y","Z": 2 2 2 2 2 2 2 2 2 2 ...
 $ value   : num  0.28 0.26 0.277 0.275 0.281 ...
 ```
