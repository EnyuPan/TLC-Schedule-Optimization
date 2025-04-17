setwd("")
BigData<- read.csv("Fall2024.csv")

MediumData<- subset(BigData, Focus == "English")
Data1<- subset(MediumData, Schedule.Title== "200 King E. Tutors - Winter 2024")
Data2<- subset(MediumData, Schedule.Title== "200 King E. Tutors - Spring/Summer 2024")

Data<- merge(Data1, Data2)


##Note that splitting it like this only grabs Winter 2024 Data; not all the
##data we have for 200 King E.
start <-  "2024-01-09"
end <-  "2024-04-17"
##What we need to run this program:
#Data is being put into it; it can be the straight WCO data
##Required: start date and end date, for the date generator.


##Converts the time given into a 24hour format
TimeSwitch <- function(t){
  ##Turn it into a vector of individual characters
  char<- unlist(strsplit(t, split = ""))
  last<- length(char)
  #Find if it is AM or PM
  daytime<- t[last-1:last]
  comb<- 0
  ##Changes PM time to 24 hours
  if(StrEqu(char[last-1:last],"PM")&(StrEqu(char[1:2], "12"))){
    comb <- as.character(as.integer(char[1])+12)
    char <- paste(comb, char[2:last], sep= "")
  }
  newtime<- comb
}
##counts how many appointments occurred at said time and day:
ApptCounter<- function(data, time, date){
  count <- 0
  
  ##Loops through all the appointments
  for (i in 1:length(data)){
    ##Checks if the time and date are the same
    if (StrEqu(data$Appointment.Date, date) & StrEqu(Start.Time, time)){
      count <- count + 1
    }
  }
}
##String equality function
StrEqu <- function(str1, str2){
  state <- FALSE
  ##If the strings aren't the same length, ends early
  if(!((length(str1)==(length(str2))))){
    return(FALSE)
  }
  ##Checks each character manually, ending early if any are different.
  else{
    for(i in 1:length(str1)){
      if (str1[i]==str2[i]){
        state<- TRUE
      }
      else{ 
        state<- FALSE
        break
        }
    }
    return(state)
  }
}
##Checks if an appointment is active 
ongoing<- function(time1, time2, time3){
  ##Time1 is the current time, time2 is the start of an app, time3 is the end
  
  ##setting up the broken up strings
    time1.1<-unlist(strsplit(time1, split = '')) 
    time2.1<-unlist(strsplit(time2, split = '')) 
    time3.1<-unlist(strsplit(time3, split = ''))
    ##Grabbing the lengths of each string for easier storage
    len1 <- length(time1.1)
    len2 <- length(time2.1)
    len3 <- length(time3.1)
    
    time1.2<- c()
    time2.2<- c()
    time3.2<- c()
    
    ##Changing times from 12 hour to 24 hour for easier comparison. Note that 
    ##00 (midnight, and the hour after it) will be represented by 24
    
    ##parsing time1
    ##First check out if it is an AM time
    if(StrEqu(time1.1[(len1-1):len1], c("A", "M"))){
      ##If it is an AM time; take time 12AM to 00:00
      if(StrEqu(time1.1[1:2], c("1", "2"))){
        time <- time1.1[1:2]
        newtime <- "0"
        time1.2 <- c(newtime, time1.1[3:(len1-2)])
      }
      else{
        ##Elsewise; just take off the Am
        time1.2 <- time1.1[1:(len1-2)]
      }
    }
    else{ 
      ##Checks if its twelve; if it is just leave it at 12
      if(StrEqu(time1.1[1:2], c("1", "2"))){
      time1.2 <- time1.1[1:(len1-2)]
    }
    else{
      ##
      time <- time1.1[1]
      newtime <- as.character(as.integer(time)+12) 
      time1.2 <- c(newtime, time1.1[2:(len1-2)])
    }}
    time1.2<- paste(time1.2, collapse = "")
    
    
    ##Parsing time2
    ##First check out if it is an AM time
    if(StrEqu(time2.1[(len2-1):len2], c("A", "M"))){
      ##If it is an AM time; take time 12AM to 00:00
      if(StrEqu(time2.1[1:2], c("1", "2"))){
        time <- time2.1[1:2]
        newtime <- "0"
        time2.2 <- c(newtime, time2.1[3:(len2-2)])
      }
      else{
        ##Elsewise; just take off the Am
        time2.2 <- time2.1[1:(len2-2)]
      }
    }
    else{ 
      ##Checks if its twelve; if it is just leave it at 12
      if(StrEqu(time2.1[1:2], c("1", "2"))){
        time2.2 <- time2.1[1:(len2-2)]
      }
      else{
        ##
        time <- time2.1[1]
        newtime <- as.character(as.integer(time)+12) 
        time2.2 <- c(newtime, time2.1[2:(len2-2)])
      }}
    time2.2<- paste(time2.2, collapse = "")
    
    ##parsing time3
    if(StrEqu(time3.1[(len3-1):len3], c("A", "M"))){
      ##If it is an AM time; take time 12AM to 00:00
      if(StrEqu(time3.1[1:2], c("1", "2"))){
        time <- time3.1[1:2]
        newtime <- "0"
        time3.2 <- c(newtime, time3.1[3:(len3-2)])
      }
      else{
        ##Elsewise; just take off the Am
        time3.2 <- time3.1[1:(len3-2)]
      }
    }
    else{ 
      ##Checks if its twelve; if it is just leave it at 12
      if(StrEqu(time3.1[1:2], c("1", "2"))){
        time3.2 <- time3.1[1:(len3-2)]
      }
      else{
        ##
        time <- time3.1[1]
        newtime <- as.character(as.integer(time)+12) 
        time3.2 <- c(newtime, time3.1[2:(len3-2)])
      }}
    time3.2<- paste(time3.2, collapse = "")
    
    ##Converting into numbers
    time1.3 <- as.integer(unlist(strsplit(time1.2, split = ":")))
    time2.3 <- as.integer(unlist(strsplit(time2.2, split = ":")))
    time3.3 <- as.integer(unlist(strsplit(time3.2, split = ":")))
    
    ##Converting it from 2 seperate numbers; we change it to store as purely hours
    time1.4 <- time1.3[1]+ time1.3[2]/60
    time2.4 <- time2.3[1]+ time2.3[2]/60
    time3.4 <- time3.3[1]+ time3.3[2]/60
    
    
    ##Checks if the current time is a valid check in the appointment.
    if((time2.4<= time1.4)&(time1.4<time3.4)){
      return(TRUE)
    }
    else{
      return(FALSE)
    }
  }
##This function takes in a date from WCO and converts it to a date in R.
dateConvert<- function(date){
  newdate<-unlist(strsplit(date, split = "/"))
  return<- c(newdate[3], newdate[1], newdate[2])
  paste(return, collapse = "-")
}
##Counts the amount of appointments that occur during said time/day
countappointments<- function(date, time){
  count<- 0
  for(k in 1:length(Data$Schedule.Title)){
    if(StrEqu(as.character(as.Date(dateConvert((Data$Appointment.Date[k])))),
              as.character(date)) & 
       (ongoing(time, Data$Start.Time[k], Data$End.Time[k]))){
      count<- count + 1
    }
  }
  return(count)
}
##Checks if they are the same term: As in, term 1 is winter, term 2 is Spring/
##Summer, and term three is Fall.
termChecker <- function(date){
  ##This function takes in a date and determines if it is in a winter term,
  ##spring term or summer term and returns 1, 2, 3 respectively.
  month <- format(date, "%m")
  if (month <5){
    return(1)
  }
  else if (month > 8){
    return(3)
  }
  else{return(2)}
}
##Now; we need to create a new data frame that stores the following information:
# Appointment date and time; #Of appointments happening during that time,
#Time of that appointment, weekday, month

##Generates a sequence of dates.
dateseq<- function(start, end){
  seq.Date(as.Date(start, format = "%Y-%m-%d"), as.Date(end, format = "%Y-%m-%d"), by = 1)
}


datesseq<- dateseq(start,end)

##This creates a sequence of times which we are open; we create one for weekdays
##and one for weekends, since we have reduced hours on weekends
timeseq<- c("9:00 AM", "9:30 AM", "10:00 AM", "10:30 AM", "11:00 AM",
            "11:30 AM", "12:00 PM", "12:30 PM", "1:00 PM", "1:30 PM", "2:00 PM", 
            "2:30 PM", "3:00 PM", "3:30 PM", "4:00 PM", "4:30 PM", "5:00 PM", 
            "5:30 PM", "6:00 PM", "6:30 PM", "7:00 PM", "7:30 PM", "8:00 PM",
            "8:30 PM")

##I never implemented this into the code for weekends
weekend<- c("10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM", "12:00 PM", 
            "12:30 PM", "1:00 PM", "1:30 PM", "2:00 PM", "2:30 PM", "3:00 PM",
            "3:30 PM", "4:00 PM", "4:30 PM", "5:00 PM", "5:30 PM")
##generate the vector for the data frame that has the appointment slots.
createdataarray<- function(dates, times){
  ##I start off by creating different empty vectors to store the information
  ##for each variable.
  AppointmentSlot<- c()
  AppointmentTime<- c()
  AppointmentDate<- c()
  Month<- c()
  Amount<- c()
  Weekday<- c()
  ##Loop through each date and time to create a separate 'slot' for them. Then
  ##we add the input to each of the pre-generated list.
  for(i in 1:length(dates)){
    for(j in 1:length(times)){
      newdate<- paste(as.character(dates[i]), times[j], sep = " ")
      AppointmentSlot <- c(AppointmentSlot, newdate)
      AppointmentTime <- c(AppointmentTime, times[j])
      AppointmentDate <- c(AppointmentDate, dates[i])
      Weekday<- c(Weekday, weekdays(dates[i]))
      Month <- c(Month, format(dates[i], "%m"))
      Amount<- c(Amount, countappointments(as.character(dates[i]), times[j]))
    }
  }
  ##We return a dataframe of the variables for each one. 
  return(data.frame(AppointmentSlot, AppointmentTime, Month,
                    Weekday, Amount))
}

##Creates  the dataframe with the given data
DemandData<- createdataarray(datesseq, timeseq)

##Creates a linear model with Weekday and appointment time as categorical 
##models
testData<- lm(DemandData$Amount ~ as.factor(DemandData$AppointmentTime)
              + as.factor(DemandData$Weekday))