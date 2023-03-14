--SELECT * FROM CovidVaccinations
--Select the data I want to use
SELECT Location, date, total_cases, total_deaths,population
FROM
CovidDeaths
ORDER BY 1,2

--total cases vs total deaths
--Likelihood of death if covid is contracted in the US

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM
CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2


--Total cases vs population
--% of population with covid in the US

SELECT Location,total_cases,population, (total_cases/population)*100 as DeathPercentage
FROM
CovidDeaths
WHERE location LIKE '%states%'
ORDER BY 1,2

-- Countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount,MAX((total_cases/population)*100) as InfectionRate
FROM
CovidDeaths
--WHERE location LIKE '%states%'
Group BY location,population
ORDER BY InfectionRate DESC 

--Countries with highest death count per population

SELECT location, population, MAX(total_deaths)as HighestDeath, MAX((total_deaths/population)*100) as DeathToPopulation
FROM CovidDeaths
WHERE continent is not null
AND total_deaths is not null
Group By location,population
ORDER BY DeathToPopulation DESC

-- Continent with highest death count

SELECT continent, MAX(cast(total_deaths as int))as HighestDeath, MAX((total_deaths/population)*100) as DeathToPopulation
FROM CovidDeaths
WHERE continent is not null
AND total_deaths is not null
Group By continent
ORDER BY HighestDeath DESC

----Creating Views--
--CREATE VIEW 
--FView AS
--SELECT location, population, MAX(total_cases) AS HighestInfectionCount,MAX((total_cases/population)*100) as InfectionRate
--FROM
--CovidDeaths
----WHERE location LIKE '%states%'
--Group BY location,population

--SELECT * FROM FView

-- GLOBAL NUMBERS
SELECT date, SUM(new_cases) as Total_New_Cases, SUM(Cast(new_deaths as int)) AS Total_New_Death,
SUM(Cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE continent is not null
Group By date
ORDER BY 1,2 

-- Across The World
SELECT SUM(new_cases) as Total_New_Cases, SUM(Cast(new_deaths as int)) AS Total_New_Death,
SUM(Cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE continent is not null
ORDER BY 1,2 

--COVID VACCINATIONS

SELECT * FROM CovidVaccinations

-- JOIN CovidDeaths AND CovidVccinations

SELECT * FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
   AND dea.date = vac.date

 --CREATE CTE
With PopvsVac (Continent, Location,Date,population,New_Vaccination, RollingPeopleVaccinated)
AS
(SELECT dea.continent, dea.location,dea.date,dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
Select *, (RollingPeopleVaccinated/population)*100 AS VacRatio FROM PopvsVac

--Total population vs Vaccination

SELECT dea.continent, dea.location,dea.date,dea.population, vac.new_vaccinations
,
SUM(cast(vac.new_vaccinations as int)) over 
(Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated,
(RollingPeopleVaccinated/population)*100 as VacPercent
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date


--TEMP TABLE
DROP TABLE IF EXISTS #VacPercent
CREATE TABLE #VacPercent (
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccination numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #VacPercent
Select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.Date)
AS RollingPeopleVaccinated
FROM CovidDeaths dea
    JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.Date = vac.Date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Query the Data
Select * , (RollingPeopleVaccinated/Population)*100 AS PercentVaccinated
FROM #VacPercent

--CREATE A VIEW TO STORE DATA FOR LATER VISUALIZATION

CREATE VIEW PercentVaccinated AS
Select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.Date)
AS RollingPeopleVaccinated
FROM CovidDeaths dea
    JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.Date = vac.Date
WHERE dea.continent IS NOT NULL

--View the data

SELECT * FROM PercentVaccinated
