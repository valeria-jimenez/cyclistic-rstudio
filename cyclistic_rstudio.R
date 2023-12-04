library(tidyverse)
library(janitor)
library(lubridate)
library(ggplot2)
library(viridis)
# import CSVs

jan2021 <- read_csv('divvy_monthlytripdata/202101-divvy-tripdata.csv')
feb2021 <- read_csv('divvy_monthlytripdata/202102-divvy-tripdata.csv')
mar2021 <- read_csv('divvy_monthlytripdata/202103-divvy-tripdata.csv')
apr2021 <- read_csv('divvy_monthlytripdata/202104-divvy-tripdata.csv')
may2021 <- read_csv('divvy_monthlytripdata/202105-divvy-tripdata.csv')
jun2021 <- read_csv('divvy_monthlytripdata/202106-divvy-tripdata.csv')
jul2021 <- read_csv('divvy_monthlytripdata/202107-divvy-tripdata.csv')
aug2021 <- read_csv('divvy_monthlytripdata/202108-divvy-tripdata.csv')
sep2021 <- read_csv('divvy_monthlytripdata/202109-divvy-tripdata.csv')
oct2021 <- read_csv('divvy_monthlytripdata/202110-divvy-tripdata.csv')
nov2021 <- read_csv('divvy_monthlytripdata/202111-divvy-tripdata.csv')
dec2021 <- read_csv('divvy_monthlytripdata/202112-divvy-tripdata.csv')

entire_dataset <- list(jan2021, feb2021, mar2021, apr2021, may2021, jun2021, jul2021, aug2021, sep2021, oct2021, nov2021, dec2021)

# get info

for (dataset in entire_dataset) {
  str(dataset)
}

# create dataframe

merged_df <- bind_rows(entire_dataset)
merged_df <- clean_names(merged_df)
merged_df <- remove_empty(merged_df, which = c()) # c() selects rows and columns

# add features

merged_df$day_of_week <- wday(merged_df$started_at, label = T, abbr = T)
merged_df$starting_hour <- format(as.POSIXct(merged_df$started_at), '%H')
merged_df$month <- format(as.Date(merged_df$started_at), '%m')
merged_df$ride_length <- difftime(merged_df$ended_at, merged_df$started_at, units = 'sec')

# clean ride length

clean_df <- merged_df[!(merged_df$ride_length <= 0),]

# export to allow for analyses in Tableau and/or PowerBI

write.csv(clean_df, file = 'cyclistic_df.csv')

##
##
##

# main question: how do casual riders differ from members?

my_colors <- c("#94a1ca", "#49538d")
my_fill <- scale_fill_manual(values = my_colors)

# Number of rides per week

ggplot(data = clean_df) +
  aes(x = day_of_week, fill = member_casual) +
  geom_bar(position = 'dodge', color = "#1d2138", size = 0.3) +
  scale_y_continuous(labels = scales::number_format(scale = 1e-3, suffix = "k")) +
  my_fill +
  labs(x = 'Day of Week', y = 'Number of Rides', fill = 'Member Type', title = 'Number of Rides per Week') +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("number_of_rides_per_week.png")

##

# Number of rides per month

ggplot(data = clean_df) +
  aes(x=month, fill=member_casual) +
  geom_bar(position = 'dodge', color = "#1d2138", size = 0.3) +
  my_fill +
  labs(x = 'Month', y = 'Number of Rides', fill = 'Member Type', title = 'Number of Rides per Month') +
  scale_y_continuous(labels = scales::number_format(scale = 1e-3, suffix = "k")) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_x_discrete(labels = c('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'))

ggsave("number_of_rides_per_month.png")

##

# Hourly number of rides per weekday

ggplot(data = clean_df) +
  aes(x = starting_hour, fill = member_casual) +
  facet_wrap(~day_of_week) +
  geom_bar(color = '#1d2138', size = 0.2) +
  my_fill +
  labs(x = 'Starting Hour', y = 'Number of Rides', fill = 'Member Type', title = 'Hourly Rides per Weekday') +
  scale_y_continuous(labels = scales::number_format(scale = 1e-3, suffix = "k")) +
  theme_minimal() +
  theme(axis.text = element_text(size = 5),
        axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("hourly_rides_per_weekday.png")

##

# Average ride length per weekday

grouped_df <- clean_df %>%
  group_by(day_of_week, member_casual) %>%
  summarize(avg_duration = mean(ride_length, na.rm = TRUE)) %>%
  ungroup()

ggplot(data = grouped_df) +
  aes(x = day_of_week, y = avg_duration, fill = member_casual) +
  geom_bar(stat = "identity", position = "dodge", color = "#1d2138", size = 0.3) +
  my_fill +
  labs(x = 'Day of Week', y = 'Average Trip Duration (seconds)', fill = 'Member Type', title = 'Average Trip Duration for Casual Riders and Members') +
  theme_minimal() +
  theme(axis.text = element_text(size = 10),
        axis.text.x = element_text(angle = 45, hjust = 1)) 

ggsave("avg_ride_length.png")

## 

# Find the most popular stations

# drop null values
filtered_data <- clean_df %>%
  filter(!is.na(start_station_name) & !is.na(end_station_name))

top_start_stations <- filtered_data %>%
  count(start_station_name, sort = TRUE) %>%
  head(10)

top_end_stations <- filtered_data %>%
  count(end_station_name, sort = TRUE) %>%
  head(10)

top_stations <- bind_rows(
  mutate(top_start_stations, type = "Start"),
  mutate(top_end_stations, type = "End")
)

top_stations <- mutate(top_stations, station = coalesce(start_station_name, end_station_name))

ggplot(top_stations, aes(x = reorder(as.factor(station), n), y = n, fill = type)) +
  geom_bar(stat = "identity", position = "dodge", color = "#1d2138", size = 0.3) +
  my_fill +
  labs(x = 'Station', y = 'Number of Rides', fill = 'Station', title = 'Top Start and End Stations') +
  scale_y_continuous(labels = scales::number_format(scale = 1e-3, suffix = "k")) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))

ggsave("top_start_end_stations.png")

# separate members and casual riders
# members

filtered_members <- clean_df %>%
  filter(!is.na(start_station_name) & !is.na(end_station_name) & member_casual == 'member')

top_start_stations_members <- filtered_members %>%
  count(start_station_name, sort = TRUE) %>%
  head(10)

top_end_stations_members <- filtered_members %>%
  count(end_station_name, sort = TRUE) %>%
  head(10)

top_stations_members <- bind_rows(
  mutate(top_start_stations_members, type = "Start"),
  mutate(top_end_stations_members, type = "End")
)
top_stations_members <- mutate(top_stations_members, station = coalesce(start_station_name, end_station_name))

ggplot(top_stations_members, aes(x = reorder(as.factor(station), n), y = n, fill = type)) +
  geom_bar(stat = "identity", position = "dodge", color = "#1d2138", size = 0.3) +
  my_fill +
  labs(x = 'Station', y = 'Number of Rides', fill = 'Type', title = 'Top Start and End Stations (Members)') +
  scale_y_continuous(labels = scales::number_format(scale = 1e-3, suffix = "k")) +
  theme_minimal() + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))

ggsave("top_start_end_stations_members.png")

# casual riders

filtered_casual <- clean_df %>%
  filter(!is.na(start_station_name) & !is.na(end_station_name) & member_casual == 'casual')

top_start_stations_casual <- filtered_casual %>%
  count(start_station_name, sort = TRUE) %>%
  head(10)

top_end_stations_casual <- filtered_casual %>%
  count(end_station_name, sort = TRUE) %>%
  head(10)

top_stations_casual <- bind_rows(
  mutate(top_start_stations_casual, type = "Start"),
  mutate(top_end_stations_casual, type = "End")
)
top_stations_casual <- mutate(top_stations_casual, station = coalesce(start_station_name, end_station_name))

ggplot(top_stations_casual, aes(x = reorder(as.factor(station), n), y = n, fill = type)) +
  geom_bar(stat = "identity", position = "dodge", color = "#1d2138", size = 0.3) +
  my_fill +
  labs(x = 'Station', y = 'Number of Rides', fill = 'Type', title = 'Top Start and End Stations (Casual)') +
  scale_y_continuous(labels = scales::number_format(scale = 1e-3, suffix = "k")) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1))

ggsave("Top_Start_End_Stations_Casual.png")

# rides per month of year

ride_counts <- clean_df %>%
  group_by(month, member_casual) %>%
  summarize(ride_count = n())

ggplot(ride_counts, aes(x = month, y = ride_count, color = member_casual)) +
  geom_line(aes(group = member_casual), size = 1.13) +
  labs(x = 'Month of the Year', y = 'Number of Rides', color = 'Member Type', title = 'Number of Rides by Month') +
  scale_x_discrete(labels = c('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec')) +
  scale_y_continuous(labels = scales::number_format(scale = 1e-3, suffix = "k")) + 
  theme_minimal() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1)
  ) +
  scale_color_manual(values = c("#94a1ca", "#3a4271"))
  

ggsave("rides_by_month.png")
