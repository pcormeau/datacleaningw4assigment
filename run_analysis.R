library(dplyr)
library(readr)

datapath <- "."

#Load activity labels
activitylabels <- read_delim(file.path(datapath,"activity_labels.txt"),
                             delim = " ",
                             col_names = c("activityid","activity"))

#Load features labels
featurelabels <- read_delim(file.path(datapath,"features.txt"),
                            delim = " ",
                            col_names = c("col","label"))
#make feature labels unique as there are some duplicate names
featurelabels <- mutate(featurelabels,
                        uniquelabel = make.unique(label, sep = "#"))

#define a function to load a set of data (train or test) and merge subject and activity
loadset <- function (dataset) {
        subject <- read_table(file.path(datapath,dataset,
                                        paste0("subject_", dataset,".txt")),
                              col_names = "subjectid")

        activity <- read_table(file.path(datapath,dataset,
                                         paste0("y_", dataset,".txt")),
                               col_names = "activityid")

        data <- read_table(file.path(datapath,dataset,
                                     paste0("X_", dataset,".txt")),
                           col_names = featurelabels$uniquelabel)
        return(bind_cols(subject,activity,data))
}

#merge train and test data by loading each set and combining them
alldata <- bind_rows(loadset("train"),
                     loadset("test"))


#Select only mean and standard deviation columns
datasubset <- select(alldata, subjectid, activityid, matches("mean\\()|std\\()"))

#Add activity label, reoder variables and remove activityid
datasubset <- inner_join(datasubset, activitylabels)
datasubset <- select(datasubset, subjectid, activity, everything(), -activityid)

#remove symbols from variable names
names(datasubset) <- gsub("[\\()-]", "", names(datasubset))

#Create a new dataframe with the means for each subject and activity
datasubsetmeans <- summarise_all(group_by(datasubset, subjectid, activity), mean)
