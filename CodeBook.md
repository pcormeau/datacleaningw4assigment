# CodeBook.md
## Datasource
The data used in this analysis came from experiments that have been carried out with a group of 30 volunteers within an age bracket of 19-48 years. Each person performed six activities (WALKING, WALKING_UPSTAIRS, WALKING_DOWNSTAIRS, SITTING, STANDING, LAYING) wearing a smartphone (Samsung Galaxy S II) on the waist. Using its embedded accelerometer and gyroscope, we captured 3-axial linear acceleration and 3-axial angular velocity at a constant rate of 50Hz. The experiments have been video-recorded to label the data manually. The obtained dataset has been randomly partitioned into two sets, where 70% of the volunteers was selected for generating the training data and 30% the test data.

The sensor signals (accelerometer and gyroscope) were pre-processed by applying noise filters and then sampled in fixed-width sliding windows of 2.56 sec and 50% overlap (128 readings/window). The sensor acceleration signal, which has gravitational and body motion components, was separated using a Butterworth low-pass filter into body acceleration and gravity. The gravitational force is assumed to have only low frequency components, therefore a filter with 0.3 Hz cutoff frequency was used. From each window, a vector of features was obtained by calculating variables from the time and frequency domain.

The data were taken from the *Human Activity Recognition Using Smartphones Data Set* on the [UCI Machine Learning Repository website](http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones)

Only means and standard deviation of the measurements where used in this analysis (original features with mean() or std() in their names)

The means of these variables have been calculated by activity and subject.
The resulting dataset include the following variables :
```
mean.subjectid : Subject ID (there was 30 subjects in the experiments).

mean.activity : Activity performed during the measurements.
- Possible values : WALKING, WALKING_UPSTAIRS, WALKING_DOWNSTAIRS, SITTING, STANDING, LAYING.

Mean of the original measurements variables :
mean.tBodyAcc.mean.X, mean.tBodyAcc.mean.Y, mean.tBodyAcc.mean.Z
mean.tBodyAcc.std.X, mean.tBodyAcc.std.Y, mean.tBodyAcc.std.Z
mean.tGravityAcc.mean.X, mean.tGravityAcc.mean.Y, mean.tGravityAcc.mean.Z
mean.tGravityAcc.std.X, mean.tGravityAcc.std.Y, mean.tGravityAcc.std.Z
mean.tBodyAccJerk.mean.X, mean.tBodyAccJerk.mean.Y, mean.tBodyAccJerk.mean.Z
mean.tBodyAccJerk.std.X, mean.tBodyAccJerk.std.Y, mean.tBodyAccJerk.std.Z
mean.tBodyGyro.mean.X, mean.tBodyGyro.mean.Y, mean.tBodyGyro.mean.Z
mean.tBodyGyro.std.X, mean.tBodyGyro.std.Y, mean.tBodyGyro.std.Z
mean.tBodyGyroJerk.mean.X, mean.tBodyGyroJerk.mean.Y, mean.tBodyGyroJerk.mean.Z
mean.tBodyGyroJerk.std.X, mean.tBodyGyroJerk.std.Y, mean.tBodyGyroJerk.std.Z
mean.tBodyAccMag.mean, mean.tBodyAccMag.std, mean.tGravityAccMag.mean
mean.tGravityAccMag.std, mean.tBodyAccJerkMag.mean, mean.tBodyAccJerkMag.std
mean.tBodyGyroMag.mean, mean.tBodyGyroMag.std,
mean.tBodyGyroJerkMag.mean, mean.tBodyGyroJerkMag.std,
mean.fBodyAcc.mean.X, mean.fBodyAcc.mean.Y, mean.fBodyAcc.mean.Z
mean.fBodyAcc.std.X, mean.fBodyAcc.std.Y, mean.fBodyAcc.std.Z
mean.fBodyAccJerk.mean.X, mean.fBodyAccJerk.mean.Y, mean.fBodyAccJerk.mean.Z
mean.fBodyAccJerk.std.X, mean.fBodyAccJerk.std.Y, mean.fBodyAccJerk.std.Z
mean.fBodyGyro.mean.X, mean.fBodyGyro.mean.Y, mean.fBodyGyro.mean.Z
mean.fBodyGyro.std.X, mean.fBodyGyro.std.Y, mean.fBodyGyro.std.Z
mean.fBodyAccMag.mean, mean.fBodyAccMag.std
mean.fBodyBodyAccJerkMag.mean, mean.fBodyBodyAccJerkMag.std
mean.fBodyBodyGyroMag.mean, mean.fBodyBodyGyroMag.std
mean.fBodyBodyGyroJerkMag.mean, mean.fBodyBodyGyroJerkMag.std

There is no units for these variables.
```
The original Codebook and variables description are in the files :
original_README.txt, original_features_info.txt and original_features.txt

# Steps to reproduce the results
## Prerequisite
### Data files
The data must have been download and and the file extracted of their archive by keeping the internal folder structure. The R working directory should be set where the file have been extracted. The following files are needed for the analysis.

R Working Directory - set by setwd() :

        activity_labels.txt
        features.txt
        test
            subject_test.txt
            X_test.txt
            y_test.txt
        train
            subject_train.txt
            X_train.txt
            y_train.txt

### External Packages

the [dplyr](https://cran.r-project.org/web/packages/dplyr/index.html) and [readr](https://cran.r-project.org/web/packages/readr/index.html) packages were used as they were able to provide a better readability of the code while achieving better performance than the standard libraries.
The following non standard function where used:
* read_delim, read_table: Work as their siblings standard function read.delim and read.table. Parameter col_names is equivalent to col.names in these functions.
* mutate: allow to alter a data frame by adding new variable
* bind_cols, bind_rows: bind two or more data frame by combining their respective column or rows similarly to the standard cbind and rbind function.
* select: allow to reorder or remove columns by names in a data frame.
* inner_join: allow to join to data frame by performing a join based on key columns
* group_by: allow to define one or more columns to be used when call to aggregate (like summarise, summarise_all) or mutate function are used.
* summarise_all: allow to compute one or more aggregate function on all variable of a data frame. If group were defined by the group_by function, they are used to break downs the aggregate based on these. These group by columns are not aggregated.

```
if(!require(dplyr)){
        install.packages("dplyr")
        library(dplyr)
}

if(!require(readr)){
        install.packages("readr")
        library(readr)
}
```

## Detailed Script Process

### 1. Merges the training and the test sets to create one data set.
#### 1.1 Read the features labels and make them unique so we can label the columns during import correctly  

```
#Load features labels
featurelabls <- read_delim("features.txt",
                            delim = " ",
                            col_names = c("colnum","label"))
#make feature labels unique as there are some duplicate names
featurelabels <- mutate(featurelabels,
                        uniquelabel = make.unique(label, sep = "#"))
```
#### 1.2 Create a function to process the 'train' or 'test' subfolder as their structure are identical.
The function will load the subject ids, the activities ids and the measurements and merge the three data in one data frame before returning it. The path to the coressponding set of data is passed as a parameter ("train" and "test").
```
#define a function to load a set of data (train or test) and merge subject and activity
loadset <- function (dataset) {
        subject <- read_table(file.path(dataset,
                                        paste0("subject_", dataset,".txt")),
                              col_names = "subjectid")

        activity <- read_table(file.path(dataset,
                                         paste0("y_", dataset,".txt")),
                               col_names = "activityid")

        data <- read_table(file.path(dataset,
                                     paste0("X_", dataset,".txt")),
                           col_names = featurelabels$uniquelabel)
        return(bind_cols(subject,activity,data))
}
```
#### 1.3 Merge the Train and Test data
The previously created function is called twice (for respectively the "train" and the "test" data set) and the resulting data frames are merged together. the column label data (*featurelabels*) are discarded as they are no longer needed.
```
#merge train and test data by loading each set and combining them
alldata <- bind_rows(loadset("train"),
                     loadset("test"))
rm(featurelabels)
```
### 2. Extracts only the measurements on the mean and standard deviation for each measurement.
The dplyr **select** function allows an easy selection of field name based on pattern matching.
```
#Select only mean and standard deviation columns
datasubset <- select(alldata, subjectid, activityid, matches("mean\\()|std\\()"))
```
### 3. Uses descriptive activity names to name the activities in the data set
We load the activity labels and then merge the data by using the dplyr function **inner_join** to add a column with the activity text (as the two data frame contain *activityid*, this one is used to join the two data frames). We then use the dplyr **select** function to reorder the columns and remove the non longer needed *activityid* column (**everything()** in the **select** function add all columns that were not previously mentioned in the select statement. A minus sign, remove a column). The *activitylabels* data frame is dropped as it is no longer needed.
```
#Add activity label, reoder variables and remove activityid
#Load activity labels
activitylabels <- read_delim("activity_labels.txt",
                             delim = " ",
                             col_names = c("activityid","activity"))

datasubset <- inner_join(datasubset, activitylabels)
datasubset <- select(datasubset, subjectid, activity, everything(), -activityid)
rm(activitylabels)
```
### 4. Appropriately labels the data set with descriptive variable names.
As the columns have already been named in the previous step there is no much to do. To make the variable name more compliant with the R syntax, we remove all the parentheses from the names then call the standard make.names function.
```
#remove symbols from variable names
names(datasubset) <- make.names(paste("mean",
                                      gsub("[\\()]", "", #Remove Parentheses
                                           names(datasubset)
                                           )
                                      )
                                )
```
### 5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.
We use the dplyr **group_by** function to add the grouping attribute *subjectid* and *activity* to the data frame then we use the dplyr **summarise_all** function to compute the mean on all other columns. We store the result in a new data frame.
```
#Create a new dataframe with the means for each subject and activity
datasubsetmeans <- summarise_all(group_by(datasubset, subjectid, activity), mean)
```
### Finalizing
We write out the resulting data frame to a txt file.
```
#Write the new dataframe to disk
write.table(datasubsetmeans, "datasubsetmeans.txt", row.names = FALSE)
```
