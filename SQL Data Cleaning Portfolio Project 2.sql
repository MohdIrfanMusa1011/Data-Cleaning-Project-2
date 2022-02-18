/* 

Queries for Data Cleaning

*/

SELECT * FROM nashvillehousing

------------------------------------------------------------------------------------------------------------------------------------------------

--Standardize the date format


SELECT saledate, CONVERT (date, saledate)
FROM nashvillehousing

--Note that we have to create another column (using ALTER TABLE + ADD) then we can update the new column using our new converted column

ALTER TABLE nashvillehousing
ADD SaleDateConvert date

UPDATE nashvillehousing
SET SaleDateConvert = CONVERT (date, saledate)

SELECT saledate, saledateconvert
FROM nashvillehousing

------------------------------------------------------------------------------------------------------------------------------------------------

--Populate Property Address Data

SELECT propertyaddress
FROM nashvillehousing
WHERE propertyaddress is null
--This shows there is null values in the address

SELECT *
FROM nashvillehousing
order by parcelid
--Found out that the null values of PropertyAddress has the same ParcelID pattern
--So we can populate the null propertyaddress by referring to the ParcelID
--We can see this through self join (join the 2 tables) below

SELECT a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress
FROM nashvillehousing a
JOIN nashvillehousing b
ON a.parcelid = b.parcelid
AND a.uniqueID <> b.uniqueID
WHERE a.propertyaddress is null

/*We use the above query to see that each parcel ID has the specific property address, so in conclusion the null values in propertyaddress
can be replace with the same address*/

--Then in order to populate we use ISNULL statement

SELECT a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress, ISNULL(a.propertyaddress,b.propertyaddress)
FROM nashvillehousing a
JOIN nashvillehousing b
ON a.parcelid = b.parcelid
AND a.uniqueID <> b.uniqueID
WHERE a.propertyaddress is null

--Use UPDATE statement to make changes

UPDATE a
SET propertyaddress = ISNULL(a.propertyaddress,b.propertyaddress)
FROM nashvillehousing a
JOIN nashvillehousing b
ON a.parcelid = b.parcelid
AND a.uniqueID <> b.uniqueID
WHERE a.propertyaddress is null

--We can also populate the null propertyaddress with a text string (optional) using the below query

UPDATE a
SET propertyaddress = ISNULL(a.propertyaddress,'No Address')
FROM nashvillehousing a
JOIN nashvillehousing b
ON a.parcelid = b.parcelid
AND a.uniqueID <> b.uniqueID
WHERE a.propertyaddress is null


------------------------------------------------------------------------------------------------------------------------------------------------


--Seperating the Address into Individual Columns (Address, City, State)
--Using SUBSTRING and CHARINDEX

SELECT propertyaddress, substring (propertyaddress, 1, CHARINDEX(',',Propertyaddress))
FROM nashvillehousing

--There is a coma after the above query

SELECT
substring (propertyaddress, 1, CHARINDEX(',',Propertyaddress)-1)
FROM nashvillehousing

/* the -1 on the propertyaddress is to go back 1 position before the ',' in order to remove the coma.
 The below queries can show that charindex actually shows the position number, thats why we can use -1 to remove the coma */

SELECT
substring (propertyaddress, 1, CHARINDEX(',',Propertyaddress)), CHARINDEX(',',Propertyaddress)
FROM nashvillehousing


 /* The second substring query (+1) is to go to the actual coma position and to seperate the address after the coma  */

SELECT
substring (propertyaddress, 1, CHARINDEX(',',Propertyaddress)-1) as Address,
substring (propertyaddress, CHARINDEX(',',Propertyaddress)+1, LEN (propertyaddress)) as Address
FROM nashvillehousing

--This below query is for the property address
ALTER TABLE nashvillehousing
ADD PropertySplitAddress NVARCHAR(300)

UPDATE nashvillehousing
SET PropertySplitAddress = substring (propertyaddress, 1, CHARINDEX(',',Propertyaddress)-1)

--This query is for the City that we split
ALTER TABLE nashvillehousing
ADD CityAddress NVARCHAR(300)

UPDATE nashvillehousing
SET CityAddress = substring (propertyaddress, CHARINDEX(',',Propertyaddress)+1, LEN (propertyaddress))

SELECT * FROM nashvillehousing


------------------------------------------------------------------------------------------------------------------------------------------------



--We are seperating the OwnerAddress Column using PARSENAME statement

SELECT PARSENAME (REPLACE (OwnerAddress, ',', '.'), 1),
PARSENAME (REPLACE (OwnerAddress, ',', '.'), 2),
PARSENAME (REPLACE (OwnerAddress, ',', '.'), 3)
FROM nashvillehousing

--PARSENAME is doing the seperation from the back
--So we need to change the position

SELECT PARSENAME (REPLACE (OwnerAddress, ',', '.'), 3),
PARSENAME (REPLACE (OwnerAddress, ',', '.'), 2),
PARSENAME (REPLACE (OwnerAddress, ',', '.'), 1)
FROM nashvillehousing

ALTER TABLE nashvillehousing
ADD OwnerSplitAddress NVARCHAR(300)

UPDATE nashvillehousing
SET OwnerSplitAddress = PARSENAME (REPLACE (OwnerAddress, ',', '.'), 3)

ALTER TABLE nashvillehousing
ADD OwnerSplitCity NVARCHAR(300)

UPDATE nashvillehousing
SET OwnerSplitCity = PARSENAME (REPLACE (OwnerAddress, ',', '.'), 2)

ALTER TABLE nashvillehousing
ADD OwnerSplitState NVARCHAR(300)

UPDATE nashvillehousing
SET OwnerSplitState = PARSENAME (REPLACE (OwnerAddress, ',', '.'), 1)

SELECT * FROM nashvillehousing


------------------------------------------------------------------------------------------------------------------------------------------------


--Change the Y and N to "Yes" and "No" in SoldAsVacant
--We can check & see the data is not uniform format base on the below query

SELECT distinct(SoldAsVacant), COUNT (SoldAsVacant) 
FROM nashvillehousing
GROUP BY SoldAsVacant
Order by 2

--We can change the data using CASE statement

SELECT SoldAsVacant,
CASE When SoldAsVacant = 'Y' THEN 'Yes'
	 When SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM nashvillehousing

--Update the data 

UPDATE nashvillehousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	 When SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END

--We can check the count of Yes & No using the 1st query that we use to check



------------------------------------------------------------------------------------------------------------------------------------------------


--Removing Duplicates
--Note that it is not a standard practice to delete data in database, but in some cases we do have to remove it
--We're gonna use CTE 
--We need to use PARTITION BY , to output the same ParcelID, Property, SalePrice, etc. 
--But we're gonna use RowNumber on the ParcelID, Property, SalePrice, etc. to show the same row that has same info
--We could to identify DUPLICATE ROWS using multiple ways such as Rank, OrderRank, DenseRank, RowNumber
--When we run the query we can see num_row has 2 rows that has exactly same info, so thats how we detect the duplicate row
--We can quickly identify the duplicate rows using "WHERE row_num > 1", but we cant use the WHERE statement, we can only use it with CTE

SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID ) row_num
FROM nashvillehousing
--WHERE row_num > 1 (need to be used with CTE)
ORDER BY ParcelID

--CTE

WITH RowNumCTE
AS ( 
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID ) row_num
FROM nashvillehousing
--ORDER BY ParcelID
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress

--To delete duplicate rows we use DELETE, then WHERE row_num > 1

WITH RowNumCTE
AS ( 
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID ) row_num
FROM nashvillehousing
--ORDER BY ParcelID
)
DELETE
FROM RowNumCTE
WHERE row_num > 1

--After that we can run the first CTE to check if there is anymore duplicate, if it does not show results then there is no more duplicate


------------------------------------------------------------------------------------------------------------------------------------------------


/* DELETE UNUSED COLUMNS */

--Not to used on Raw Date
--Maybe for the unnecessary column that we created and not column from raw data

SELECT *
FROM nashvillehousing

ALTER TABLE nashvillehousing
DROP COLUMN OwnerAddress, SaleDate, TaxDistrict, PropertyAddress
