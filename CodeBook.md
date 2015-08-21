This document describes the columns in the `tidy_result` table created for the Course Project. This is followed by a walk through the process by which this table was created with intermediate structures and transformations.

Please see [README.md](https://github.com/progtron/CourseProject/blob/master/README.md) for an in-depth description of the processing script.

### Data dictionary

#### activity
Factors with the 6 values from `UCI HAR Dataset/activity_labels.txt`. These represent the activities which were measured.

1. LAYING
2. SITTING
3. STANDING
4. WALKING
5. WALKING_DOWNSTAIRS
6. WALKING_UPSTAIRS

#### subject
#### measure
#### metric
#### func
#### axis
#### value

### Data classes & transformations

The script needs the `dplyr` and `tidyr` libraries. We defined these in vector `packages_used` and compared against installed packages to determine which ones should be installed: `packages_to_install`.

We start with two data sets for Test and Train. These were initially loaded into the `test` and `train` data frames. Column labels for these data sets were loaded from `features.txt` into data frame `features`.

The activities corresponding to each row in these data sets was present in `y_test.txt` and `y_train.txt`. These were stored as numeric codes and loaded into data frames `test_activity_codes` and `train_activity_codes`, respectively. These columnar data were first combined with the data sets. To make them more descriptive, we replaced the codes with labels. Activity Labels were loaded from `activity_labels.txt` into data frame `activity_labels`. The function `use_activity_label` was applied and the equivalent columns with labels were created in data frames `test_activity_names` and `train_activity_names`, respectively.

Similar to activities, we combine the columnar list of subject ID's (1-30) to the data sets, first storing them in data frames `test_subjects` and `train_subjects`.

The two datasets are then merged (concatenated) into the data frame `full`.

Columns containing mean and standard deviation functions are extracted into data frame `means_sds`. This aggregate data is now summarized into a set of means for every `activity`-`subject` pair, into data frame `activity_subject_means`. For these steps we use `dplyr` functions.

We use `tidyr` for the final reshaping. This requires that the data frame `activity_subject_means` be converted to a table, named `means_sds_tbl`. Finally, with some careful decomposition of column names, the data is gathered into `tidy_result`.
