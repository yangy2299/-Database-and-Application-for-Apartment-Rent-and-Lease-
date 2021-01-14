-- Reprot Query 1

SELECT AVG(A.MonthRent) AS AverageRent, A.NumBed AS NumBed, A.NumBath AS NumBath, C.CityName AS CityName
FROM Proj.Apartments A 
   INNER JOIN Proj.Buildings B ON A.BuildingID = B.BuildingID
   INNER JOIN Proj.Cities C ON B.CityID = C.CityID
GROUP BY A.NumBed, A.NumBath, C.CityName
ORDER BY C.CityName, A.NumBed, A.NumBath;


-- Reprot Query 2

DECLARE @AvgRS INT = 
   (
      SELECT AVG(A.AvgReviewScores)
      FROM Proj.Apartments A
      WHERE A.ReviewCount > 0
	);

With AptCTE(ApartmentID, BuildingID, ReviewCount,AvgReviewScores,AptNumber,NumBed,NumBath,MonthRent,Deposit,Sizesqf,AvailableTime,NumOfParking,FloorType,FloorColor,
CarpetType,CarpetColor, CreatedOn, UpdatedOn) AS
   (
      SELECT *
      FROM Proj.Apartments A 
      WHERE A.AvgReviewScores > @AvgRS
   )
SElECT 
   (
      SELECT TOP 1 AC.FloorType AS FloorType
      FROM AptCTE AC
      GROUP BY AC.FloorType
      ORDER BY COUNT(AC.FloorType) DESC) AS FloorType, 
   (
      SELECT TOP 1 AC.FloorColor AS FloorColor
      FROM AptCTE AC
      GROUP BY AC.FloorColor
     ORDER BY COUNT(AC.FloorColor) DESC) AS FloorColor,
   (
      SELECT TOP 1 AC.CarpetType AS CarpetType
      FROM AptCTE AC
      GROUP BY AC.CarpetType
      ORDER BY COUNT(AC.CarpetType) DESC) AS CarpetType, 
   (
      SELECT TOP 1 AC.CarpetColor AS CarpetColor
      FROM AptCTE AC
      GROUP BY AC.CarpetColor
     ORDER BY COUNT(AC.CarpetColor) DESC) AS CarpetColor,
   (
      SELECT TOP 1 B.HeatingType AS HeatingType
      FROM Proj.Buildings B
         INNER JOIN Proj.Apartments A ON A.BuildingID = B.BuildingID
            AND A.AvgReviewScores > @AvgRS
      GROUP BY B.HeatingType
      ORDER BY COUNT(DISTINCT B.HeatingType) DESC) AS HeatingType
Go


-- Reprot Query 3

DECLARE @AvgRS INT = 
   (
      SELECT AVG(A.AvgReviewScores)
      FROM Proj.Apartments A
      WHERE A.ReviewCount > 0
	);
SELECT RANK() OVER(ORDER BY AVG(A.AvgReviewScores) DESC) AS [Rank], 
O.Name, AVG(A.AvgReviewScores) AS AvgReviewScores
FROM Proj.Owners O
   INNER JOIN Proj.Buildings B ON O.OwnerID = B.OwnerID
   INNER JOIN Proj.Apartments A ON B.BuildingID = A.BuildingID
      AND A.AvgReviewScores >= @AvgRS
GROUP BY O.Name
ORDER BY AvgReviewScores DESC


-- Reprot Query 4

SELECT COUNT(ApartmentID) As NumApt, C.CityName AS City
FROM Proj.Apartments A 
   INNER JOIN Proj.Buildings B ON B.BuildingID = A.BuildingID
      AND B.BuildingID IN 
	     ( 
            SELECT DISTINCT BuildingID 
            FROM Proj.BuildingFeatures  
         )
   INNER JOIN Proj.Cities C ON B.CityID = C.CityID
WHERE A.ApartmentID IN 
   (
      SELECT DISTINCT ApartmentID 
      FROM Proj.ApartmentFeatures
      WHERE FeatureAID= 2
   )
GROUP BY C.CityName
ORDER BY NumApt DESC


-- Qestion Query

DECLARE @Rentlo INT = 500,
        @Renthi INT = 1000,
		@NumBed INT = 2,
		@NumBath INT = 1,
		@AvailableDate DATE = NULL,
		@CityName NVARCHAR(64) = 'Haysville',
		@Bus NVARCHAR(64) = NULL,
		@FeatureA1 INT= 1,
		@FeatureA2 INT= NULL,
		@FeatureA3 INT= 3,
		@FeatureB1 INT= 1,
		@FeatureB2 INT= NULL;

WITH QCTE(ApartmentID, BuildingID, ReviewCount, AvgReviewScores, AptNumber, NumBed, NumBath, MonthRent, Deposit, Sizesqf, AvailableDate, 
           NumOfParking, FloorType, FloorColor, CarpetType, CarpetColor) AS
   (
      SELECT A.ApartmentID, A.BuildingID, A.ReviewCount, A.AvgReviewScores, A.AptNumber, A.NumBed, A.NumBath, 
	  A.MonthRent, A.Deposit, A.Sizesqf, A.AvailableDate, A.NumOfParking, A.FloorType, A.FloorColor, A.CarpetType, A.CarpetColor
      FROM Proj.Apartments A
         INNER JOIN Proj.Buildings B ON A.BuildingID = B.BuildingID
      WHERE (@Rentlo <= A.MonthRent and A.MonthRent <= @Renthi OR @Renthi IS NULL)
         AND (A.NumBed = @NumBed OR @NumBed IS NULL)
         AND (A.NumBath = @NumBath OR @NumBath IS NULL)
		 AND (A.AvailableDate >= @AvailableDate OR @AvailableDate IS NULL)
         AND (((@FeatureA1 IS NULL) AND (@FeatureA2 IS NULL) AND (@FeatureA3 IS NULL)) OR A.ApartmentID IN 
              (
               SELECT DISTINCT A1.ApartmentID 
               FROM Proj.ApartmentFeatures A1
	              INNER JOIN Proj.ApartmentFeatures A2 ON A1.ApartmentID = A2.ApartmentID
	              INNER JOIN Proj.ApartmentFeatures A3 ON A2.ApartmentID = A3.ApartmentID
               WHERE (A1.FeatureAID = @FeatureA1 OR @FeatureA1 IS NULL) 
			      AND (A2.FeatureAID = @FeatureA2 OR @FeatureA2 IS NULL) 
			      AND (A3.FeatureAID = @FeatureA3 OR @FeatureA3 IS NULL)
              ))
         AND (((@FeatureB1 IS NULL) AND (@FeatureB2 IS NULL)) OR B.BuildingID IN 
              (
               SELECT DISTINCT B1.BuildingID 
               FROM Proj.BuildingFeatures B1
	              INNER JOIN Proj.BuildingFeatures B2 ON B1.BuildingID = B2.BuildingID
               WHERE (B1.FeatureBID = @FeatureB1 OR @FeatureB1 IS NULL) 
			      AND (B2.FeatureBID = @FeatureB2 OR @FeatureB2 IS NULL)
              ))
   )
SELECT Q.ApartmentID AS ApartmentID, B.Address AS Address, CityName AS City, Q.NumBed AS NumOfBedroom, Q.NumBath AS NumOfBathroom, 
                        B.TimeToBusStop,  Q.AvailableDate AS AvailableDate, Q.MonthRent AS MonthRent, Q.AvgReviewScores AS AvgReviewScores
FROM QCTE Q 
   INNER JOIN Proj.Buildings B ON Q.BuildingID = B.BuildingID
   INNER JOIN Proj.Cities C ON B.CityID = C.CityID
WHERE (C.CityName = @CityName OR @CityName IS NULL)
   AND (B.TimeToBusStop = @Bus OR @Bus IS NULL)
ORDER BY ApartmentID, C.CityName, MonthRent ASC