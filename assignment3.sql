-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- COMP6720 Advanced Database Systems
-- Assignment 3: Query Performance Analysis and Optimization
-- Topic: Disaster Relief Management System
-- Group Members: Christopher Morgan, Chris-San Williams, 
-- Jelani Smith, Shanika Williams-Maxwell, Shaunna-Lee Edwards
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- -----------------------------------------------------------
-- INITIAL SETUP
-- -----------------------------------------------------------
-- Enabling local file loading so we can import CSV files.
SET GLOBAL local_infile = 1;
SHOW GLOBAL VARIABLES LIKE 'local_infile';
SHOW VARIABLES LIKE 'secure_file_priv';

-- Setting up the session  
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";
SET NAMES utf8mb4;

-- -----------------------------------------------------------
-- DATABASE SETUP AND SCHEMA CREATION
-- -----------------------------------------------------------
-- Creating and using the Disaster Relief Database if it doesn't exist
CREATE DATABASE IF NOT EXISTS disaster_relief_db;  
USE disaster_relief_db;

-- Dropping the tables if they exist in the order of foreign key dependencies.
DROP TABLE IF EXISTS resource_allocation;
DROP TABLE IF EXISTS relief_center;
DROP TABLE IF EXISTS site;
DROP TABLE IF EXISTS incident_report;
DROP TABLE IF EXISTS community;
DROP TABLE IF EXISTS parish;
DROP TABLE IF EXISTS cash_donation;
DROP TABLE IF EXISTS aid_organization;


-- Creating the aid_organization table to store organizations
CREATE TABLE aid_organization (
	org_id INT NOT NULL,
    org_name VARCHAR(100) NOT NULL,
    org_type VARCHAR(20) NOT NULL,
    country VARCHAR(50) NOT NULL,
    PRIMARY KEY (org_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- Creating the cash_donation table to record monetary contributions
CREATE TABLE cash_donation (
    donation_id INT NOT NULL,
    org_id INT NOT NULL,
    amount DECIMAL(18,2) NOT NULL,
    donation_date DATE NOT NULL,
    PRIMARY KEY (donation_id),
    CONSTRAINT fk_cash_donation_org
        FOREIGN KEY (org_id)
        REFERENCES aid_organization (org_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- Creating the parish table to store parish-level information
CREATE TABLE parish (
    parish_id INT NOT NULL,
    parish_name VARCHAR(50) NOT NULL,
    county VARCHAR(20) NOT NULL,
    population INT,
    PRIMARY KEY (parish_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- Creating the community table to store communities within parishes
CREATE TABLE community (
    community_id INT NOT NULL,
    parish_id INT NOT NULL,
    community_name VARCHAR(100) NOT NULL,
    is_coastal TINYINT NOT NULL,
    PRIMARY KEY (community_id),
    CONSTRAINT fk_community_parish
        FOREIGN KEY (parish_id)
        REFERENCES parish (parish_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- Creating the incident_report table to record disaster incidents per community
CREATE TABLE incident_report (
    report_id INT NOT NULL,
    community_id INT NOT NULL,
    report_date DATE NOT NULL,
    category VARCHAR(100) NOT NULL,
    severity_level TINYINT NOT NULL,
    households_affected INT NOT NULL,
    statuses VARCHAR(20) NOT NULL,
    PRIMARY KEY (report_id),
    CONSTRAINT fk_incident_community
        FOREIGN KEY (community_id)
        REFERENCES community (community_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- Creating the site table to store affected sites within communities
CREATE TABLE site (
    site_id INT NOT NULL,
    community_id INT NOT NULL,
    site_name VARCHAR(200) NOT NULL,
    site_type VARCHAR(50) NOT NULL,
    is_infrastructure TINYINT NOT NULL,
    damage_category TINYINT NOT NULL,
    estimated_repair_cost DECIMAL(18,2) NOT NULL,
    power_restored TINYINT NOT NULL,
    PRIMARY KEY (site_id),
    CONSTRAINT fk_site_community
        FOREIGN KEY (community_id)
        REFERENCES community (community_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- Creating the relief_center table to store shelters/relief centers
CREATE TABLE relief_center (
    center_id INT NOT NULL,
    parish_id INT NOT NULL,
    center_name VARCHAR(100) NOT NULL,
    center_type VARCHAR(50) NOT NULL,
    capacity INT NOT NULL,
    is_active TINYINT NOT NULL,
    PRIMARY KEY (center_id),
    CONSTRAINT fk_center_parish
        FOREIGN KEY (parish_id)
        REFERENCES parish (parish_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- Creating the resource_allocation table to track resources assigned to sites
CREATE TABLE resource_allocation (
	allocation_id INT NOT NULL,
    site_id INT NOT NULL,
    org_id INT NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    allocation_date DATE NOT NULL,
    quantity INT NOT NULL,
    unit_value DECIMAL(18,2) NOT NULL,
    total_value DECIMAL(18,2) NOT NULL,
    PRIMARY KEY (allocation_id),
    CONSTRAINT fk_alloc_site
        FOREIGN KEY (site_id)
        REFERENCES site (site_id),
    CONSTRAINT fk_alloc_org
        FOREIGN KEY (org_id)
        REFERENCES aid_organization (org_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- -----------------------------------------------------------
-- POPULATE TABLES WITH DATA
-- -----------------------------------------------------------

-- Load base lookup tables first

-- aid_organization
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Disaster_Relief/aid_organization.csv'
INTO TABLE aid_organization
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(org_id, org_name, org_type, country);

-- parish
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Disaster_Relief/parish.csv'
INTO TABLE parish
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(parish_id, parish_name, county, population);

-- community (depends on parish)
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Disaster_Relief/community.csv'
INTO TABLE community
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(community_id, parish_id, community_name, is_coastal);

-- incident_report (depends on community)
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Disaster_Relief/incident_report.csv'
INTO TABLE incident_report
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(report_id, community_id, @raw_date, category,
 severity_level, households_affected, statuses)
SET report_date = STR_TO_DATE(TRIM(@raw_date), '%d/%m/%Y');

-- site (depends on community)
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Disaster_Relief/site.csv'
INTO TABLE site
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(site_id, community_id, site_name, site_type, is_infrastructure,
 damage_category, estimated_repair_cost, power_restored);

-- relief_center (depends on parish)
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Disaster_Relief/relief_center.csv'
INTO TABLE relief_center
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(center_id, parish_id, center_name, center_type, capacity, is_active);

-- cash_donation (depends on aid_organization)
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Disaster_Relief/cash_donation.csv'
INTO TABLE cash_donation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(donation_id, org_id, amount, @raw_date)
SET donation_date = STR_TO_DATE(TRIM(@raw_date), '%d/%m/%Y');

-- resource_allocation (depends on site + aid_organization)
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Disaster_Relief/resource_allocation.csv'
INTO TABLE resource_allocation
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(allocation_id, site_id, org_id, resource_type, @raw_date, quantity, unit_value, total_value)
SET allocation_date = STR_TO_DATE(TRIM(@raw_date), '%d/%m/%Y');

COMMIT;

-- -----------------------------------------------------------
-- VIEW POPULATED TABLES WITH DATA
-- -----------------------------------------------------------
SELECT * FROM aid_organization;
SELECT * FROM parish;
SELECT * FROM community;
SELECT * FROM incident_report;
SELECT * FROM site;
SELECT * FROM relief_center;
SELECT * FROM cash_donation;

-- -------------------------------------------------------------------------------
-- QUERY ANALYSIS
-- -------------------------------------------------------------------------------

-- QUERY 1: LEVEL 5 DAMAGED SITES IN WESTMORELAND PARISH
-- ═══════════════════════════════════════════════════════════════════════════════
-- Finds all communities in Westmoreland that experienced level 5 hurricane damage 
-- and sums up the total estimated repair cost per community. It helps us see which 
-- parts of the parish were most heavily affected and how much funding would be needed 
-- for rebuilding efforts. 
-- Sort: Total repair cost (descending)



-- QUERY 2: TOP 5 AID ORGANIZATIONS SUPPORTING SITES WITHOUT POWER
-- ═══════════════════════════════════════════════════════════════════════════════
-- Identifies the top five aid organizations that have provided the highest total 
-- dollar value of resources to sites that are still without electricity. 
-- It highlights which organizations are leading the ongoing recovery efforts in 
-- areas where basic utilities haven’t been restored. 
-- Sort: Total resource value (descending)



-- QUERY 3: ROOFING MATERIAL SHORTAGE ANALYSIS BY PARISH
-- ═══════════════════════════════════════════════════════════════════════════════
-- Compares how many roofing materials were allocated to each parish against the
-- total number of damaged sites in that parish. Here we are checking whether 
-- resource distribution has been fair. If the total roofing materials allocated 
-- are less than the number of sites, the parish likely has a shortage, meaning 
-- reconstruction will be delayed. 
-- Sort: Shortage size (ascending - biggest shortages first)



-- QUERY 4: HIGH-SUPPORT DONORS 
-- ═══════════════════════════════════════════════════════════════════════════════
-- Focuses on aid organizations that supported over 100 damaged sites through 
-- resource allocation, then calculates their average cash donation amount. 
-- The goal is to understand whether those organizations directly helping on the 
-- ground are also the biggest financial donors. 
-- Sort: Average donation (descending)




-- QUERY 5: CORNWALL COUNTY VS REST OF JAMAICA
-- ═══════════════════════════════════════════════════════════════════════════════
-- Compares the county of Cornwall to the rest of the island in terms of total 
-- repair cost, number of damaged sites, relief centre capacity, and population 
-- coverage. It’s used to measure how much strain Cornwall is under after the 
-- hurricane, thus asking, “Is Cornwall dealing with more damage relative to its 
-- available relief resources and population size?” By grouping data by county, 
-- we can see whether the western region’s infrastructure and shelters are 
-- sufficient or if additional national support is needed.
-- Sort: Total repair cost (descending)





-- -----------------------------------------------------------
-- QUERY OPTIMIZATION
-- -----------------------------------------------------------






/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;