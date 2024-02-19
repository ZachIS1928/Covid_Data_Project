SELECT *
FROM CovidPortfolioProject..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 3,4;


SELECT *
FROM CovidPortfolioProject..CovidVaccinations
ORDER BY 3,4;


--Select Data that we are going to be using

SELECT Location, date, total_deaths, new_cases, total_deaths, population
FROM CovidPortfolioProject..CovidDeaths
ORDER BY 1,2;

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS mortality_rate 
FROM CovidPortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2;


DROP VIEW IF exists SurvivalOutlookperCountry;
GO

CREATE VIEW SurvivalOutlookperCountry AS
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as mortality_rate 
FROM CovidPortfolioProject..CovidDeaths;
GO


--columns total cases and total deaths in wrong format for arithmetic leading to error for above statement^
--alter table CovidDeaths alter column total_deaths numeric null
--alter table CovidDeaths alter column total_cases numeric null

--Looking at total cases vs population
--Shows what percentage of population that got Covid
SELECT Location, date, Population, total_cases, (total_cases/population)*100 as Degree_of_Outbreak
FROM CovidPortfolioProject..CovidDeaths
--where location like 'U% S%'
ORDER BY 1, 2;

DROP VIEW IF exists SpreadWithinCountry;
GO
CREATE VIEW SpreadWithinCountry AS
SELECT Location, date, Population, total_cases, (total_cases/population)*100 AS Degree_of_Outbreak
FROM CovidPortfolioProject..CovidDeaths;
GO

--Looking at Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionOutbreak, MAX((total_cases/population))*100 AS Degree_of_Outbreak
FROM CovidPortfolioProject..CovidDeaths
--where location like 'U% S%'
GROUP BY location, population
ORDER BY Degree_of_Outbreak DESC;

DROP VIEW if exists GreatestOutbreakperCountry;
GO
CREATE VIEW GreatestOutbreakperCountry AS
SELECT Location, Population, MAX(total_cases) AS HighestInfectionOutbreak, MAX((total_cases/population))*100 AS Degree_of_Outbreak
FROM CovidPortfolioProject..CovidDeaths
--where location like 'U% S%'
GROUP BY location, population;
GO

--Showing Countries with Highest Death Count per Population
-- If column total_deaths was not reformatted earlier, could use CAST as INT function to perform calc

SELECT Location, MAX(total_deaths) AS TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
--where location like 'U% S%'
WHERE continent is not null
GROUP BY location
--order by TotalDeathCount desc
;

DROP VIEW if exists CumulativeDeathCount_per_Country;
GO
CREATE VIEW CumulativeDeathCount_per_Country AS
SELECT Location, MAX(total_deaths) AS TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
--where location like 'U% S%'
WHERE continent is NOT NULL
GROUP BY location;
GO

--categorized by Continent
--showing the continent with highest death count

DROP VIEW if exists CumulativeDeathCount_per_Continent;
GO
CREATE VIEW CumulativeDeathCount_per_Continent AS
SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
--where location like 'U% S%'
WHERE continent is not null
GROUP BY continent
--order by TotalDeathCount desc
;
GO

SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM CovidPortfolioProject..CovidDeaths
--where location like 'U% S%'
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount DESC;

--Global numbers

DROP VIEW if exists GlobalStatistics;
GO
CREATE VIEW GlobalStatistics AS
SELECT date, SUM(total_deaths) as CumulativeDeathsGlobal, SUM(total_cases)CumulativeCasesGlobal, SUM(new_cases) AS DailyCases, SUM(new_deaths) AS DailyDeaths, CASE WHEN SUM(new_cases) = 0 THEN 0 ELSE SUM(new_deaths)/SUM(New_Cases) *100 END AS daily_mortality_rate 
FROM CovidPortfolioProject..CovidDeaths
--where location like '%states%'
WHERE continent is not null
GROUP BY date
--order by 1,2
;
GO

SELECT SUM(new_cases) AS DailyCases, SUM(new_deaths) AS DailyDeaths, CASE WHEN SUM(new_cases) = 0 THEN 0 ELSE SUM(new_deaths)/SUM(New_Cases) *100 END AS mortality_rate 
FROM CovidPortfolioProject..CovidDeaths
--where location like '%states%'
WHERE continent is not null
--group by date
ORDER BY 1,2;

--Looking at Total Spread and Degree of Outbreak vs Deaths as a % of population
--Shows possibility of Herd Immunity taking effect

DROP VIEW if exists Cumulative_Outbreak_vs_Deaths_as_Percent_of_Population;
GO
CREATE VIEW Cumulative_Outbreak_vs_Deaths_as_Percent_of_Population AS
SELECT Location, Population, MAX(total_cases) AS HighestInfectionOutbreak, MAX((total_cases/population))*100 AS Degree_of_Outbreak, MAX((total_deaths/population))*100 AS Deaths_as_Perc_of_Pop
FROM CovidPortfolioProject..CovidDeaths
--where location like 'U% S%'
WHERE continent is not null
GROUP BY location, population
--order by Degree_of_Outbreak desc, Deaths_as_Perc_of_Pop desc
;
GO

--Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccinations
--, (CumulativeVaccinations/population0*100  /* this is causing error due to being a new aggregate row */
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
ORDER BY 2,3;

--Fix by using CTE

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, CumulativeVaccinations)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(new_vaccinations AS bigint)) OVER (PARTITION BY dea.location order by dea.location, dea.date) AS CumulativeVaccinations
--, (CumulativeVaccinations/population0*100  /* this is causing error due to being a new aggregate row */
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
--order by 2,3
)
SELECT *, (CumulativeVaccinations/Population)*100 AS PercentofPopImmunized
FROM PopvsVac;

--Shows only final vaccinated population

DROP VIEW if exists VaccinationsPerCountry_VS_VaccinationsGlobal;
GO
CREATE VIEW VaccinationsPerCountry_VS_VaccinationsGlobal AS
WITH PopvsVac (Continent, Location, Population, Total_Vaccinations_Per_Country, CumulativeVaccinations)
AS (
SELECT dea.continent, dea.location, dea.population, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY vac.location) AS total_new_vac_per_country
, SUM(CAST(new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.continent, dea.date) AS CumulativeVaccinations
--, (CumulativeVaccinations/population0*100  /* this is causing error due to being a new aggregate row */
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--order by 2,3
)
SELECT *
FROM PopvsVac;
GO

--Fix using temp table

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
CumulativeVaccinations numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(new_vaccinations AS bigint)) OVER (PARTITION BY dea.location order by dea.location, dea.date) AS CumulativeVaccinations
--, (CumulativeVaccinations/population0*100  /* this is causing error due to being a new aggregate row */
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--where dea.continent is not null
--order by 2,3

SELECT *, (CumulativeVaccinations/Population)*100
FROM #PercentPopulationVaccinated;


--Creating View to store data for later visualizations

DROP VIEW if exists PercentPopulationVaccinated;
GO
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumulativeVaccinations
--, (CumulativeVaccinations/population0*100  /* this is causing error due to being a new aggregate row */
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL
--order by 2,3
;
GO

SELECT * 
FROM PercentPopulationVaccinated;


--Shows vaccinations vs cases vs deaths
DROP VIEW if exists Deaths_Cases_Since_Vaccine;
GO
CREATE VIEW Deaths_Cases_Since_Vaccines AS
SELECT dea.location, SUM(dea.new_deaths) AS Cumulative_Deaths_Since_Vaccine
, SUM(dea.new_cases) AS Cumulative_Cases_Since_Vaccine
, SUM(CONVERT(bigint,vac.new_vaccinations))AS Cumulative_Vaccinated_Population
, (SUM(dea.new_deaths)/MAX(dea.population))*100 AS Percent_Dying_After_Vaccine
, (SUM(dea.new_cases)/MAX(dea.population))*100 AS Percent_Cases_After_Vaccine
, MIN(dea.date) AS Date_Of_Vaccine_Rollout
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL AND vac.new_vaccinations >=1
GROUP BY dea.location
--ORDER BY 1
;
GO

DROP VIEW if exists Deaths_Cases_Before_Vaccine;
GO
CREATE VIEW Deaths_Cases_Before_Vaccines AS
SELECT dea.location, SUM(dea.new_deaths) AS Cumulative_Deaths_Before_Vaccine
, SUM(dea.new_cases) AS Cumulative_Cases_Before_Vaccine
, SUM(CONVERT(bigint,vac.new_vaccinations))AS Cumulative_Vaccinated_Population
, (SUM(dea.new_deaths)/MAX(dea.population))*100 AS Percent_Dying_Before_Vaccine
, (SUM(dea.new_cases)/MAX(dea.population))*100 AS Percent_Cases_Before_Vaccine
, MIN(dea.date) AS Date_Of_First_Case
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is NOT NULL AND vac.new_vaccinations <1 OR vac.new_vaccinations is NULL
GROUP BY dea.location
--ORDER BY 1
;

