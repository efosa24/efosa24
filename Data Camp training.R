library(gapminder)
library(dplyr)
gapminder
##filter for one variable
gapminder%>%
  filter(year==2007)
gapminder%>%
  filter(country=="United States")
##filter for 2 variables
gapminder%>%
  filter(year==2007, country=="United States")
##Arrange help sort a tabke based on variables 
gapminder%>%
  arrange(gdpPercap)
##Using filter aand arrange
gapminder%>%
  filter(year==2007)%>%
  arrange(desc(gdpPercap))
##Using mutate
gapminder%>%
  mutate(pop/100000)
####
gapminder%>%
  mutate(gdp=gdpPercap*pop)
###
gapminder%>%
  mutate(gdp=gdpPercap*pop)%>%
  filter(year==2007)%>%
  arrange(desc(gdp))
###Visualizing with ggplot2
gapminder_2007<- gapminder %>%
  filter(year==2007)
gapminder_2007
##To plot
library(ggplot2)
ggplot(gapminder_2007, aes(x=gdpPercap, y= lifeExp))+geom_point()

##To linearize the plot we use log for the x axis
ggplot(gapminder_2007, aes(x=gdpPercap, y= lifeExp))+geom_point()+
  scale_x_log10()
##Using color and size
ggplot(gapminder_2007, aes(x=gdpPercap, y= lifeExp, color= continent,size= gdpPercap))+geom_point()+
  scale_x_log10()
##To divide the data in continent
ggplot(gapminder_2007, aes(x=gdpPercap, y= lifeExp, color= continent))+geom_point()+
  scale_x_log10()+facet_wrap(~ continent)
##To summarize verb
gapminder %>%
  summarise(meanLifeExp= mean(lifeExp))
##Uisng the mean and sum
gapminder%>%
  filter(year==2007)%>%
  summarize(meanlifeExp= mean(lifeExp), totalPop=sum(pop))
##Using the group by
gapminder %>%
  group_by(year)%>%
  summarize(meanLifeExp= mean(lifeExp), totalpop= sum(pop))
##
gapminder %>%
  group_by(continent)%>%
  summarize(meanLifeExp= mean(lifeExp), totalpop= sum(pop))
##
gapminder %>%
  group_by(year,continent)%>%
  summarize(meanLifeExp= mean(lifeExp), totalpop= sum(pop))
##
gapminder%>%
  filter(year==1957)%>%
  group_by(continent)%>%
  summarise(medianLifeExp= median(lifeExp), maxGdpPercap= max(gdpPercap))
###
by_year_continent<- gapminder %>%
  group_by(year, continent)%>%
  summarise(totalpop= sum(pop), meanLifeExp= mean(lifeExp))
by_year_continent
##
ggplot(by_year_continent, aes(x=year, y= totalpop, color= continent))+
  geom_point()+expand_limits(y=0)
##Line plots
ggplot(by_year_continent, aes(x=year, y= totalpop, color= continent))+
  geom_line()+expand_limits(y=0)
####\ using the bar plots
by_continent<- gapminder %>%
  filter(year==2007)%>%
  group_by(continent)%>%
  summarise(meanLifeExp= mean(lifeExp))
by_continent
#######
ggplot(by_continent, aes(x= continent, y= meanLifeExp))+geom_col()
####
ggplot(by_continent, aes(x= meanLifeExp))+geom_histogram()
ggplot(by_continent, aes(x= continent, y= meanLifeExp))+geom_col(binwidth=5)


###Data manipulation with R
##Use glimpse to observe data
##Use select to extract relevant data
counties_selected<- counties%>%
  select(state, county,population,unemployment)
counties_selected

counties_selected%>%
  group_by(state)%>%
  slice_max(unemployment, n=1)

###Joining of table
sets%>%
  inner_join(themes, by=c("theme_id", "id"))

##Customizing the table
sets%>%
  inner_join(themes, by=c("theme_id", "id"), suffix=c("_set", "_theme"))
##Most common theme
sets%>%
  inner_join(themes, by=c("theme_id", "id"), suffix=c("_set", "_theme"))%>%
  count(name_theme, sort=TRUE)

##when they have the same id
sets%>%
  inner_join(themes, by="set_num")

##Joining more than two tables
sets %>%
  inner_join(inventories, by = "set_num")%>%
  inner_join(themes, by = c("theme_id"="id"))

###REPLACE NAs for right join
sets%>%
  count(theme_id, sort=TRUE)%>%
  right_join(themes, by= c("theme_id"="id"))%>%
  replace_na(list(n=0))
##freplacing multiple vraible 
sets%>%
  count(theme_id, sort=TRUE)%>%
  right_join(themes, by= c("theme_id"="id"))%>%
  replace_na(list(nat=0, nat2=0))

##Adding colors names 
batmobile%>%
  full_join(batwing_colors, by="color_id", suffix=c("_batmobile", "-batwing"))%>%
  replace_na(list(total_batmobile=0, total_batwing=0))%>%
  inner_join(colors, by=c("color_id"="id"))
### for histigram
ggplot(aes(time))+geom_histogram(bins=30)

#####Geom smooth
ggplot(diamonds, aes(carat, price, color=clarity))+geom_point()+geom_smooth()
#####geom text
ggplot(mtcars, aes(wt, mpg, color= fcyl))+geom_text(label=rownames(mtcars), color='red')

comics
### Tidyverse
##Using tidy seperate function to seperate the column with more than one varaible
population_df %>%
  seperate(country, into = c("country", "continent"), sep=", ")
####
population_df %>%
  seperate(country, into = c("country", "continent"))
##Combining multiple column into one 
star_wars_df %>%
  unite("name", given_name, family_name, sep=" ")

separate_rows(ingredients, sep="; ")
### How to overwrite NA
moon_df %>%
  replace_na(list(people_on_moon=0L))
##Using the pivot_longer function
nuke_df %>%
  pivot_longer("1945":"1951")
nuke_df %>%
  pivot_longer(-coungtry, names_to= "year", values_to= "n_booms")
##If we dont want missing values
nuke_df %>%
  pivot_longer(-country, 
               names_to= "year", values_to= "n_booms", values_drop_na=TRUE)
#####
nuke_df %>%
  pivot_longer(-country, 
               names_to= "year", values_to= "n_booms", values_drop_na=TRUE,
               names_transform= list(year=as.integer))


##Get regression points generates predictors and residuals
get_regression_points()
##Gets the regression table generates the results of regression
get_regression_table()

## http://bit.ly/modelling_tidyverse

##Reordering factor to soilve the problem of scatter plots 
ggplot(Workchallenge, aes(x= fct_reorder(question, perc_problem),
                          y=perc_problem))+geom_point()+coord_flip()
###How to odrer from top to bottom
ggplot(multiple, aes(x= fct_rev(fct_infreq(EmployerIndustry))))+geom_bar()+
  coord_flip()
##Reodering factors
nlp_freq %>%
  mutate(response= fct_relevel(response, 
                               "often", "Most of the time", after=2))%>%
                                pull(response)%>%
                                levels()
nlp_freq %>%
  mutate(response= fct_relevel(response, 
                               "often", "Most of the time", after=inf))%>%
                                pull(response)%>%
                                levels()

###plotting with labels 
ggplot(mtcars, aes(disp,mpg))+geom_point()+
  labs(x= "x axis label", y="y axis label", title= "my title",
       subtitle= " and subtitle", caption= "even a caption")