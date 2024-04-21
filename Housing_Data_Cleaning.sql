use portfolioproject;

Drop Table if exists Nashville;

Create Table Nashville(
UniqueID int PRIMARY KEY,
ParcelID varchar(20),
LandUse varchar(50),
PropertyAddress varchar(80),
SaleDate varchar(50),
SalePrice int,
LegalReference varchar(50),
SoldAsVacant varchar(10),
OwnerName varchar(50),
OwnerAddress varchar(80),
Acreage float,
TaxDistrict varchar(50),
LandValue int,
BuildingValue int,
TotalValue int,
YearBuilt int,
Bedrooms int,
FullBath int,
HalfBath int);

set global local_infile = 1;

show global variables;

load data local infile "C:/Users/Dhruv/Documents/SQL/Projects/Project 2/Nashville Housing Data for Data Cleaning.csv"
into TABLE Nashville
fields terminated by ','
Enclosed by '"'
lines terminated by '\n'
ignore 1 lines
(UniqueID, ParcelID, LandUse, PropertyAddress, SaleDate, SalePrice, LegalReference, SoldAsVacant, OwnerName, 
OwnerAddress, Acreage, TaxDistrict, LandValue, BuildingValue, TotalValue, YearBuilt, Bedrooms, FullBath, HalfBath);

select count(*) from Nashville;

select * from Nashville;

select saledate, str_to_date(saledate, '%M %d, %Y')
from Nashville;

SET SQL_SAFE_UPDATES = 0;

-- Saledate from string to date
update Nashville
set saledate = str_to_date(saledate, '%M %d, %Y');

describe  Nashville;

select count(distinct uniqueID)
from Nashville;

--  Populate Property address
update Nashville
set PropertyAddress = null
where PropertyAddress like '';

select * from Nashville where PropertyAddress is NULL;

select * from Nashville order by ParcelID;

select * from Nashville
where ParcelId in (
	select ParcelId
    from Nashville
    group by ParcelID
    having count(ParcelID) > 1
)
order by ParcelID;

select distinct a.uniqueID, b.propertyAddress
from Nashville a
inner join Nashville b
on a.ParcelID = b.ParcelID
where a.PropertyAddress is NULL and b.PropertyAddress is NOT NULL
order by 1;

update Nashville a
inner join Nashville b
on a.ParcelID = b.ParcelID and a.UniqueID <> b.UniqueID
set a.PropertyAddress = coalesce(a.propertyAddress, b.propertyAddress)
where a.PropertyAddress is NULL and b.PropertyAddress is NOT NULL;

select * from Nashville 
where PropertyAddress is NULL;

-- Breaking out Address into Address, City and State

select propertyAddress, substring_index(propertyAddress, ',', 1) as Address,
trim(substring_index(propertyAddress, ',', -1)) as City
from Nashville;

Alter Table Nashville
Add PropertySplitAddress Varchar(100);

Alter Table Nashville
Add PropertySplitCity Varchar(100);

Update Nashville b
SET PropertySplitAddress = substring_index(propertyAddress, ',', 1);

Update Nashville b
SET PropertySplitCity = trim(substring_index(propertyAddress, ',', -1));

select * from Nashville;

select OwnerAddress, substring_index(OWNERAddress, ',', 1) as Address,
trim(substring_index(substring_index(OWNERAddress, ',', -2), ',', 1)) as City,
trim(substring_index(OWNERAddress, ',', -1)) as State
from Nashville;

Alter Table Nashville
Add OwnerSplitAddress Varchar(100);

Update Nashville
SET OwnerSplitAddress = trim(substring_index(OwnerAddress, ',', 1));

Alter Table Nashville
Add OwnerSplitCity Varchar(100);

Update Nashville
SET OwnerSplitCity = trim(substring_index(substring_index(OWNERAddress, ',', -2), ',', 1));

Alter Table Nashville
Add OwnerSplitState Varchar(100);

Update Nashville
SET OwnerSplitState = trim(substring_index(OWNERAddress, ',', -1));

select * from Nashville;

-- Replace Y with Yes and N with No in SoldAsVacant

select distinct SoldAsVacant, count(*) 
from Nashville
group by SoldAsVacant;

Update Nashville
Set SoldAsVacant = 
case 
when SoldAsVacant = 'Y' then 'Yes'
when SoldAsVacant = 'N' then 'No'
Else SoldAsVacant
end;


-- Remove Duplicates
-- Error Code: 1288. The target table cte of the DELETE is not updatable

with cte as (

select *, 
row_number() OVER(partition by ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference order by uniqueID) as row_num
from Nashville)

select * from cte
where row_num >1;

Delete 
FROM Nashville where uniqueID in
(
select uniqueID from(
select *, 
row_number() OVER(partition by ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference order by uniqueID) as row_num
from Nashville) as a
where row_num = 2);

select count(distinct LegalReference)
from Nashville;

-- DROP unwanted columns 

Alter Table Nashville
DROP column PropertyAddress, DROP column  OwnerAddress, DROP column  TaxDistrict;

select * from Nashville;