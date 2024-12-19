/*

Cleaning Data in SQL Queries

*/

Select*
From PortfolioProject..NashvilleHousing



--Standardize Date Format 

Select SaleDateConverted, Convert(date,SaleDate)
From PortfolioProject..NashvilleHousing

Update NashvilleHousing 
SET SaleDate = Convert(date,Saledate)

ALTER TABLE NashvilleHousing 
Add SaleDateConverted Date;


Update NashvilleHousing 
SET SaleDateConverted = Convert(date,Saledate)


-----------------------------------------------------------------------------------------------------------------------------

--Populate Property Address data

Select *
From PortfolioProject..NashvilleHousing
--WHERE PropertyAddress is NULL
ORDER BY ParcelID


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is NULL

Update a 
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is NULL



----------------------------------------------------------------------------------------------------------------

--Breaking out Address into Individual Columns (Address, City, State)

Select PropertyAddress
From PortfolioProject..NashvilleHousing
--WHERE PropertyAddress is NULL
--ORDER BY ParcelID

Select PropertyAddress,
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as City
FROM PortfolioProject..NashvilleHousing


ALTER TABLE NashvilleHousing 
Add PropertySplitAddress nvarchar(255)

Update NashvilleHousing
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)


ALTER TABLE NashvilleHousing 
Add PropertySplitCity nvarchar(255)

Update NashvilleHousing
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))



Select *
From PortfolioProject..NashvilleHousing




Select OwnerAddress
From PortfolioProject..NashvilleHousing


Select 
PARSENAME(Replace(OwnerAddress, ',', '.'), 3),
PARSENAME(Replace(OwnerAddress, ',', '.'), 2),
PARSENAME(Replace(OwnerAddress, ',', '.'), 1)
From PortfolioProject..NashvilleHousing


ALTER TABLE NashvilleHousing 
Add OwnerSplitAddress nvarchar(255)

Update NashvilleHousing
Set OwnerSplitAddress = PARSENAME(Replace(OwnerAddress, ',', '.'), 3)


ALTER TABLE NashvilleHousing 
Add OwnerSplitCity nvarchar(255)

Update NashvilleHousing
Set OwnerSplitCity = PARSENAME(Replace(OwnerAddress, ',', '.'), 2)


ALTER TABLE NashvilleHousing 
Add OwnerSplitState nvarchar(255)

Update NashvilleHousing
Set OwnerSplitState = PARSENAME(Replace(OwnerAddress, ',', '.'), 1)


Select *
From PortfolioProject..NashvilleHousing




--------------------------------------------------------------------------------------------------

--Change Y and N to Yes and No in "Sold as Vacant" field 

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From PortfolioProject..NashvilleHousing
Group By SoldAsVacant
Order by 2




Select SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant 
	 END
From PortfolioProject..NashvilleHousing




Update NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant 
	 END


------------------------------------------------------------------------------------------------

--Remove Duplicates 

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER(
	Partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order By UniqueID) as row_num
From PortfolioProject..NashvilleHousing
)
Select *
From RowNumCTE
WHERE row_num > 1
Order by PropertyAddress




--------------------------------------------------------------------------------------------

--Delete Unused Columns
Select *
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN SaleDate





 