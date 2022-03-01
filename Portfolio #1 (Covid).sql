UPDATE covid.cdeaths SET covid_date = str_to_date(covid_date, '%m/%d/%Y');
UPDATE covid.cvaccinations SET covid_date = str_to_date(covid_date, '%m/%d/%Y');

-- Looking at core data columns for Covid Deaths table
Select location, covid_date, total_cases, new_cases, total_deaths, population
from covid.cdeaths
order by 2;

-- Calculating death percentage is USA 

SELECT covid_date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathpercentage
from covid.cdeaths
order by 2;

SELECT covid_date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathpercentage
from covid.cdeaths
order by 4 desc; -- Highest percentage 10.91% on March 2, 2020 (6 deaths for 55 cases)

SELECT avg((total_deaths/total_cases))*100 as deathpercentage
from covid.cdeaths; -- Average death percentage in USA for covid 2.54%

-- looking at Total Cases vs Population

SELECT covid_date, total_cases, population, (total_cases/population)*100 as percentinfected
FROM covid.cdeaths
ORDER BY 1 desc; -- Up until 11/16/2021 roughly 47 million cases have been reported, approximately 14.21% of USA population

-- Looking at highest Total Cases, Deaths and Hospitalized Patients due to Covid
 
 SELECT population, MAX(total_cases), Max(cast(total_deaths as double)) as totaldeathcount, max(hosp_patients)
 from covid.cdeaths; -- approx. 47million cases, 766,000 deaths and 99,000 hospitalizations

-- Joining Covid Deaths and Vaccinations tables

SELECT * FROM covid.cdeaths dea join covid.cvaccinations vac 
on dea.location = vac.location and dea.covid_date = vac.covid_date;

-- Looking at Population vs Vaccinations

SELECT dea.covid_date, dea.location, dea.population, vac.new_vaccinations
FROM covid.cdeaths dea join covid.cvaccinations vac 
on dea.location = vac.location and dea.covid_date = vac.covid_date
ORDER BY 1;

SELECT dea.covid_date, dea.location, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as DOUBLE)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.covid_date)
as Rolling_Vaccinations
FROM covid.cdeaths dea join covid.cvaccinations vac 
on dea.location = vac.location and dea.covid_date = vac.covid_date
ORDER BY 1; -- 433,739,116 total vaccinations made in USA by 11/16/21
-- For data with multiple countries Partition By 'Location' is needed (Reminder)

-- Creating a CTE to look at Rolling Vaccinations vs Population

WITH PopvsVac (Location, Covid_Date, Population, New_Vaccinations, RollingVaccinations)
as
(
SELECT dea.covid_date, dea.location, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as DOUBLE)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.covid_date)
as Rolling_Vaccinations
FROM covid.cdeaths dea join covid.cvaccinations vac 
on dea.location = vac.location and dea.covid_date = vac.covid_date
ORDER BY 1
)
SELECT *, (RollingVaccinations/Population)*100 as VaccinationsvsPopulation
FROM PopvsVac;

WITH VaccsRates (Population, New_Vaccinations, People_Vaccinated, People_Fully_Vaccinated, Hosp_Patients, Total_Deaths, Rolling_Vaccinations, Rolling_HospPatients, Total_Cases)
as(
SELECT dea.population, vac.new_vaccinations, vac.people_vaccinated, vac.people_fully_vaccinated, dea.hosp_patients, dea.total_deaths, 
sum(cast(vac.new_vaccinations as DOUBLE)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.covid_date),
sum(cast(dea.hosp_patients as DOUBLE)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.covid_date)
as Rolling_HospPatients, dea.total_cases
FROM covid.cdeaths dea join covid.cvaccinations vac 
on dea.location = vac.location and dea.covid_date = vac.covid_date
)
SELECT (People_Vaccinated/Population)*100 as VacRate, (People_Fully_Vaccinated/Population)*100 as FullVacRate,
(Rolling_HospPatients/Population)*100 as HospRate, (Total_Deaths/Total_Cases)*100 as DeathRate
FROM VaccsRates;

SELECT covid_date, population 
FROM covid.cdeaths
ORDER BY 1;

-- Using Temp Table
DROP TABLE IF EXISTS VaccinationsperPop;
CREATE TABLE VaccinationsperPop
(
Covid_Date DATETIME,
Location VARCHAR(255),
Population DOUBLE,
New_vaccinations TEXT,
RollingVaccinations DOUBLE
);
insert into world.VaccinationsperPop
SELECT dea.covid_date, dea.location, dea.population, vac.new_vaccinations, 
sum(cast(vac.new_vaccinations as DOUBLE)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.covid_date)
as Rolling_Vaccinations
FROM covid.cdeaths dea join covid.cvaccinations vac 
on dea.location = vac.location and dea.covid_date = vac.covid_date;

SELECT *, (RollingVaccinations/Population)*100 as VaccinationsvsPopulation
FROM VaccinationsperPop

