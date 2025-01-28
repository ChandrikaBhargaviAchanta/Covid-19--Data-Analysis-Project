#show variables like "secure_file_priv";  #used when secure_file_priv error was thrown, as i did not put my .csv file in the exact MySQL directory.
#show variables like "local_infile";  # will show if local_infile is by default is off or on. 
#set global local_infile = 1;   # local_infile will be on 


CREATE DATABASE PortfolioProject;
USE PortfolioProject;

drop table CovidVaccinations;

CREATE TABLE CovidVaccinations (
iso_code  TEXT NOT NULL,
continent	TEXT,
location TEXT,
date	DATE,
new_tests	varchar(10),
total_tests	 varchar(10),
total_tests_per_thousand varchar(10),
new_tests_per_thousand	varchar(10),
new_tests_smoothed	varchar(10),
new_tests_smoothed_per_thousand	varchar(10),
positive_rate	varchar(10),
tests_per_case	varchar(10),
tests_units	 TEXT,
total_vaccinations	varchar(10),
people_vaccinated	varchar(10),
people_fully_vaccinated	varchar(10),
total_boosters	varchar(10),
new_vaccinations varchar(10),
new_vaccinations_smoothed	varchar(10),
total_vaccinations_per_hundred	varchar(10),
people_vaccinated_per_hundred	varchar(10),
people_fully_vaccinated_per_hundred	varchar(10),
total_boosters_per_hundred	varchar(10),
new_vaccinations_smoothed_per_million	varchar(10),
new_people_vaccinated_smoothed	varchar(10),
new_people_vaccinated_smoothed_per_hundred	varchar(10),
stringency_index	varchar(10),
population_density	varchar(10),
median_age	varchar(10),
aged_65_older	varchar(10),
aged_70_older	varchar(10),
gdp_per_capita	varchar(10),
extreme_poverty	 varchar(10),
cardiovasc_death_rate	varchar(10),
diabetes_prevalence	varchar(10),
female_smokers	varchar(10),
male_smokers	varchar(10),
handwashing_facilities	varchar(10),
hospital_beds_per_thousand	varchar(10),
life_expectancy	varchar(10),
human_development_index	varchar(10),
excess_mortality_cumulative_absolute varchar(10),
excess_mortality_cumulative	varchar(10),
excess_mortality	varchar(10),
excess_mortality_cumulative_per_million varchar(100)
);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/CovidVaccinations.csv"
INTO TABLE CovidVaccinations
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * from covidvaccinations;

drop table coviddeaths;
CREATE TABLE covidDeaths (
iso_code text not null,
continent	text,
location	text,
date	date,
population	varchar(10),
total_cases	varchar(10),
new_cases	varchar(10),
new_cases_smoothed	varchar(10),
total_deaths	varchar(10),
new_deaths	varchar(10),
new_deaths_smoothed	varchar(10),
total_cases_per_million	varchar(10),
new_cases_per_million	varchar(10),
new_cases_smoothed_per_million	varchar(10),
total_deaths_per_million	varchar(10),
new_deaths_per_million	varchar(10),
new_deaths_smoothed_per_million	 varchar(10),
reproduction_rate	varchar(10),
icu_patients	varchar(10),
icu_patients_per_million	varchar(10),
hosp_patients	varchar(10),
hosp_patients_per_million	varchar(10),
weekly_icu_admissions	varchar(10),
weekly_icu_admissions_per_million	varchar(10),
weekly_hosp_admissions	varchar(10),
weekly_hosp_admissions_per_million varchar(10)
);

LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/CovidDeaths.csv"
INTO TABLE CovidDeaths
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from portfolioproject.coviddeaths
where continent is not null
order by 3,4;

#selecting data that we will use 
Select location, date, total_cases, new_cases, total_deaths, population 
from portfolioproject.coviddeaths
order by 1,2;

#looking at total cases vs total deaths in India
#likelihood of dying if you get covid in India
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as percentage_of_deaths
from portfolioproject.coviddeaths
where location like "india"
order by 1,2;

#looking at the total cases with respect to population in India
Select location, date, population, total_cases,  (total_cases/ population)*100 as TotalCases_Percentage
from portfolioproject.coviddeaths
where location like "%ind%"
order by 1,2;

#looking at countries with highest infection rate wrt population
Select location, population, MAX(total_cases) as HighestInfectionCount,  MAX((total_cases/ population))*100 as INFECTION_PERCENTAGE
from portfolioproject.coviddeaths
#where location like "%ind%"
group by location, population
order by INFECTION_PERCENTAGE desc;

#looking at countries with max death count wrt population
Select location, MAX(CAST(total_deaths as decimal)) as HighestDeathCount  #type casting to decimal/int as we are not getting proper values since total_Deaths is in varchar format
from portfolioproject.coviddeaths
group by location
order by HighestDeathCount desc;

Select continent, MAX(CAST(total_deaths as decimal)) as HighestDeathCount  #type casting to decimal/int as we are not getting proper values since total_Deaths is in varchar format
from portfolioproject.coviddeaths
where continent IS NOT NULL 
group by continent
order by HighestDeathCount desc;

#Number of new cases and new deaths each day in a particular country
Select location, date, SUM(new_cases) as new_cases_each_day, SUM(new_deaths) as new_deaths_each_day, (sum(new_deaths)/sum(new_cases))*100 as percentage_of_new_deaths
from portfolioproject.coviddeaths
where location like "%ind%" 
group by date
order by 1,2;

#looking at total population vs vaccinations
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccine.new_vaccinations,
SUM(convert(vaccine.new_vaccinations, decimal)) over (partition by deaths.location order by deaths.location, deaths.date) vaccinations_until_theDate  #partition by(specify col on which we need to perform aggregation) location is used as for every new location, the count should change and not just keep adding 
#(vaccinations_until_theDate/deaths.population)*100
from portfolioproject.coviddeaths deaths
JOIN portfolioproject.covidvaccinations vaccine
on deaths.location = vaccine.location
and deaths.date = vaccine.date
where deaths.continent is not null
order by 2,3;

#To calculate total population vs number of vaccines, we need to use the vaccinations_until_theDate col, but we cannot implement a new column in a calculation
#in order to do so, we should create a temp table/ CTE(common table expression- with) and add the new col to it and then perform the required operations.

#CTE
With PopVsVac (Continent, location, date, population, new_vaccinations, vaccinations_until_theDate)
as
( 
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccine.new_vaccinations, 
SUM(convert(vaccine.new_vaccinations, decimal)) over (partition by deaths.location order by deaths.location, deaths.date) vaccinations_until_theDate #partition by(specify col on which we need to perform aggregation) location is used as for every new location, the count should change and not just keep adding 
from portfolioproject.coviddeaths deaths
JOIN portfolioproject.covidvaccinations vaccine
on deaths.location = vaccine.location
and deaths.date = vaccine.date
where deaths.continent is not null
)
select *, (vaccinations_until_theDate/population)*100 Percentage_pop_vac from PopVsVac;


#temp table

CREATE TABLE PercentPopulationVaccinated
( 
continent nvarchar(255), 
location nvarchar(10), 
date datetime, 
population numeric, 
new_vaccinations numeric,
vaccinations_until_theDate numeric
);

INSERT INTO PercentPopulationVaccinated

select deaths.continent, deaths.location, deaths.date, deaths.population, vaccine.new_vaccinations, 
SUM(convert(vaccine.new_vaccinations, decimal)) over (partition by deaths.location order by deaths.location, deaths.date) vaccinations_until_theDate #partition by(specify col on which we need to perform aggregation) location is used as for every new location, the count should change and not just keep adding 
from portfolioproject.coviddeaths deaths
JOIN portfolioproject.covidvaccinations vaccine
on deaths.location = vaccine.location
and deaths.date = vaccine.date
where deaths.continent is not null;
select *, (vaccinations_until_theDate/population)*100 Percentage_pop_vac from PercentPopulationVaccinated;


#CREATING VIEWS (to create a virtual table, to save in DB server, to increase the security and to only show the data which is required and not the whole table)

create view PopulationVaccinated 
as
select deaths.continent, deaths.location, deaths.date, deaths.population, vaccine.new_vaccinations, 
SUM(convert(vaccine.new_vaccinations, decimal)) over (partition by deaths.location order by deaths.location, deaths.date) vaccinations_until_theDate #partition by(specify col on which we need to perform aggregation) location is used as for every new location, the count should change and not just keep adding 
from portfolioproject.coviddeaths deaths
JOIN portfolioproject.covidvaccinations vaccine
on deaths.location = vaccine.location
and deaths.date = vaccine.date
where deaths.continent is not null;

