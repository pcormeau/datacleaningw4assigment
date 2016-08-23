if(!require(dplyr)){
        install.packages("dplyr")
        library(dplyr)
}

if(!require(readr)){
        install.packages("readr")
        library(readr)
}

#Load features labels
featurelabels <- read_delim("features.txt",
                            delim = " ",
                            col_names = c("colnum","label"))

#make feature labels unique as there are some duplicate names
featurelabels <- mutate(featurelabels,
                        uniquelabel = make.unique(label, sep = "#"))

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

#merge train and test data by loading each set and combining them
alldata <- bind_rows(loadset("train"),
                     loadset("test"))
rm(featurelabels)

#Select only mean and standard deviation columns
datasubset <- select(alldata, subjectid, activityid, matches("mean\\()|std\\()"))


#Add activity label, reoder variables and remove activityid
#Load activity labels
activitylabels <- read_delim("activity_labels.txt",
                             delim = " ",
                             col_names = c("activityid","activity"))

datasubset <- inner_join(datasubset, activitylabels)
datasubset <- select(datasubset, subjectid, activity, everything(), -activityid)
rm(activitylabels)

#remove symbols from variable names
names(datasubset) <- gsub("[\\()-]", "", names(datasubset))

#Create a new dataframe with the means for each subject and activity
datasubsetmeans <- summarise_all(group_by(datasubset, subjectid, activity), mean)

#Write the new dataframe to disk
write.table(datasubsetmeans, "datasubsetmeans", row.names = FALSE)
