-- Video Recorded on 01-March-2021

use portfolioproject;

SET SQL_SAFE_UPDATES = 0;

DROP Table IF EXISTS CovidDeaths;
Create Table IF NOT EXISTS CovidDeaths(
	iso_code varchar(10),
    continent varchar(20),
	location varchar(50),
    date datetime,
    population int,
    total_cases int,
    new_cases int,
    total_deaths int,
    new_deaths int
);


show global variables like 'local_infile';
SHOW VARIABLES LIKE 'local_inflie';

SET GLOBAL local_infile = 1;

load data local INFILE 'C:/Users/Dhruv/Documents/SQL/Projects/CovidDeaths.csv'
INTO TABLE portfolioproject.CovidDeaths
fields terminated BY ','
ENCLOSED BY '"'
lines terminated BY '\n'
ignore 1 lines
(iso_code, continent, location, date,  population, total_cases, new_cases, total_deaths, new_deaths);

select distinct location
from CovidDeaths
where continent like '';

Update CovidDeaths
SET continent = NULL
where continent like '';

select * from CovidDeaths  order by total_cases desc, total_deaths desc, new_deaths desc;

select count(*) from CovidDeaths;

DROP Table IF EXISTS CovidVaccinations;
Create Table IF NOT EXISTS CovidVaccinations(
	iso_code varchar(10),
    continent varchar(20),
	location varchar(50),
    date datetime,
    new_vaccinations int,
    total_vaccinations int,
    people_vaccinated int,
    new_cases int,
    total_deaths int,
    new_deaths int
);

load data local INFILE 'C:/Users/Dhruv/Documents/SQL/Projects/CovidVaccinations.csv'
INTO TABLE portfolioproject.CovidVaccinations
fields terminated BY ','
ENCLOSED BY '"'
lines terminated BY '\n'
ignore 1 lines
(iso_code, continent, location, date,  new_vaccinations, total_vaccinations, people_vaccinated, new_cases, total_deaths, new_deaths);

select distinct location
from CovidVaccinations
where continent like '';

Update CovidVaccinations
SET continent = NULL
where continent like '';

select distinct location
from CovidVaccinations
where continent is NULL;

select * from CovidVaccinations;

select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths;

-- Total Cases vs Total Deaths for India
-- Likelihood of dying if you get Covid in your country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths 
where location = 'India'
order by date desc;

select distinct location from CovidDeaths;

-- Looking for Latest Deaths due to Covid in a country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths 
where total_cases != 0
order by date desc, DeathPercentage;

-- Looking at Total Cases vs Population
select location, date, total_cases, population, (total_cases/population)*100 as CovidPercentage
from CovidDeaths
where location = 'India'
order by date desc;

-- Looking for country with Highest Population infected in a day
select location, population, max(total_cases) as HighestInfectionCount,  max((total_cases/population))*100 as PercentPopulationInfected
from CovidDeaths
group by 1,2
order by 4 desc;

-- Country with Highest Death Count per Population 
select location, Max(total_deaths) as TotalDeathCount
from CovidDeaths
where continent is not NULL
group by location
order by TotalDeathCount desc;


-- Continent with Highest Death Count per Population 
select continent, SUM(TotalDeathCount) as TotalDeaths
from
(select location, continent, Max(total_deaths) as TotalDeathCount
from CovidDeaths
where continent is not NULL
group by continent, location) a
group by continent
order by TotalDeaths desc;

select location, Max(total_deaths) as TotalDeathCount
from CovidDeaths
where continent is NULL
group by location
order by TotalDeathCount desc;

-- continue from timestamp 41:00

-- Continents with the highest death count per population
select location, Max(total_deaths) as TotalDeaths, 
MAX(population) as TotalPopulation, 
Max(total_deaths/population)*100 as DeathPercentage
from CovidDeaths
where continent is NULL
group by location
order by DeathPercentage desc;


-- Global Numbers
-- Deaths per Covid Cases on a date
select date, total_deaths, total_cases, (total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths
where location = 'World'
order by date;

-- select sum(deaths_per_day) over(order by date asc) as total_deaths
-- from
-- (select date, 
-- sum(new_deaths) as deaths_per_day
-- from CovidDeaths
-- where continent is not null
-- group by date
-- order by date) as a;

select max(total_cases), max(total_deaths), max(total_deaths)/max(total_cases)*100 as DeathPercentage
from CovidDeaths;

Drop Table if exists SmallCovidDeaths;
Create Temporary Table SmallCovidDeaths
(
	iso_code varchar(10),
    continent varchar(20),
	location varchar(50),
    date datetime,
    population int,
    total_cases int,
    new_cases int,
    total_deaths int,
    new_deaths int,
    rn int
);

Insert INTO SmallCovidDeaths 
select * from(
select *, row_number() over(Partition by location order by date) as rn
from 
CovidDeaths) as a
where rn between 1 and 1000;

select count(*) from SmallCovidDeaths;

Drop Table if exists SmallCovidVaccinations;
Create Temporary Table SmallCovidVaccinations
(
	iso_code varchar(10),
    continent varchar(20),
	location varchar(50),
    date datetime,
    new_vaccinations int,
    new_cases int,
    total_vaccinations int,
    people_vaccinated int,
    total_deaths int,
    new_deaths int,
    rn int
);

Insert INTO SmallCovidVaccinations 
select iso_code ,
    continent ,
	location ,
    date ,
    new_vaccinations ,
    new_cases ,
    total_vaccinations ,
    people_vaccinated ,
    total_deaths ,
    new_deaths,
    rn from(
select iso_code ,
    continent ,
	location ,
    date ,
    new_vaccinations ,
    new_cases ,
    total_vaccinations ,
    people_vaccinated ,
    total_deaths ,
    new_deaths , row_number() over(Partition by location order by date) as rn
from 
CovidVaccinations) as a
where rn between 1 and 1000;

select count(*) from SmallCovidVaccinations;

/*select * from
(select dea.continent, dea.location, dea.date, dea.population,
vac.new_vaccinations,
SUM(vac.new_vaccinations) over(partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from smallcoviddeaths dea
join covidvaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null) a
where new_vaccinations != 0; */

select distinct location from smallcoviddeaths
where continent is NULL;

-- use cte
/* With PopvsVac (Continent, Location, Date, Population, Vaccinations, RollingPeopleVaccinated)
as
(
	select dea.continent, dea.location, dea.date, dea.population,
vac.new_vaccinations,
SUM(vac.new_vaccinations) over(partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from smallcoviddeaths dea
join covidvaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
) */

select date, People_vaccinated 
from smallcovidvaccinations
where location = 'India';


With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, People_Vaccinated, RollingPeopleVaccinated)
as 
(select dea.continent, dea.location, dea.date, dea.population,
vac.new_vaccinations,
vac.people_vaccinated,
SUM(vac.new_vaccinations) over(partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from smallcoviddeaths dea
join smallcovidvaccinations vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null)

select *, (People_Vaccinated / Population)*100 as PercentVaccinated
from PopvsVac 
where new_vaccinations != 0 and Location = 'India';

-- Creatign View to store data for later visualizations

Create View SmallCovidDeathsView as
select * from(
select *, row_number() over(Partition by location order by date) as rn
from 
CovidDeaths) as a
where rn between 1 and 1000;

Create View SmallCovidVaccinationsView as
select * from(
select *, row_number() over(Partition by location order by date) as rn
from 
CovidVaccinations) as a
where rn between 1 and 1000;

Drop view if exists percentpolulationvaccinated;

Create View PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population,
vac.new_vaccinations,
vac.people_vaccinated,
SUM(vac.new_vaccinations) over(partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from smallcoviddeathsview dea
join smallcovidvaccinationsview vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null;

select *, (People_Vaccinated / Population)*100 as PercentVaccinated
from PercentPopulationVaccinated
where new_vaccinations != 0 and Location = 'India';








