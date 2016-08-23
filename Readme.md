#Readme.md
##Data Source

The data used came from the course website and were originally collected from the accelerometers from the Samsung Galaxy S smartphone. A full description is available at the site where the data was originally obtained:

[http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones](http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones)

For reason of reproducibility the data for the project as been downloaded from the course web site:

[https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip](https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip)

##Process Steps
1. Merges the training and the test sets to create one data set.
2. Extracts only the measurements on the mean and standard deviation for each measurement.
3. Uses descriptive activity names to name the activities in the data set
4. Appropriately labels the data set with descriptive variable names.
5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

##Prerequisite
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

###External Packages

the [dplyr](https://cran.r-project.org/web/packages/dplyr/index.html) and [readr](https://cran.r-project.org/web/packages/readr/index.html) packages were used as they were able to provide a better readability of the code while achieving better performance than the standard libraries.
The following non standard function where used:
* read_delim, read_table: Work as their siblings standard function read.delim and read.table. Parameter col_names is equivalent to col.names in these functions.
* mutate: allow to alter a data frame by adding new variable
* bind_cols, bind_rows: bind two or more data frame by combining their respective column or rows similarly to the standard cbind and rbind function.
* select: allow to reorder or remove columns by names in a data frame.
* inner_join: allow to join to data frame by performing a join based on key columns
* group_by: allow to define one or more columns to be used when call to aggregate (like summarise, summarise_all) or mutate function are used.
* summarise_all: allow to compute one or more aggregate function on all variable of a data frame. If group were defined by the group_by function, they are used to break downs the aggregate based on these. These group by columns are not aggregated.


##Detailed Script Process

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
###2. Extracts only the measurements on the mean and standard deviation for each measurement.
The dplyr **select** function allows is easy selection based on pattern matching.
```
#Select only mean and standard deviation columns
datasubset <- select(alldata, subjectid, activityid, matches("mean\\()|std\\()"))
```
###3. Uses descriptive activity names to name the activities in the data set
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
###4. Appropriately labels the data set with descriptive variable names.
As the columns have already been named in the previous step there is no much to do. To make the variable name more compliant with the R syntax, we remove all the symbols from the names.
```
#remove symbols from variable names
names(datasubset) <- gsub("[\\()-]", "", names(datasubset))
```
###5. From the data set in step 4, creates a second, independent tidy data set with the average of each variable for each activity and each subject.
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