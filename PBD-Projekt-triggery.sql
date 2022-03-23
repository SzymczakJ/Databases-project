-- uniemozliwia dodanie wiecej niz 1 wiersz do factors
CREATE TRIGGER OnlyOneFactors
ON Factors
INSTEAD OF INSERT
AS
BEGIN
	IF ((SELECT COUNT(*) FROM Factors) > 0)
	BEGIN
		RAISERROR ('No such reservationId', -1, -1)
        RETURN
	END
	ELSE
	BEGIN
		
	END
END

-- to byc moze do poprawy
CREATE TRIGGER InvalidateMenuOnInsertion 
ON Menus 
AFTER UPDATE, INSERT 
AS
BEGIN
    DECLARE @menuId AS INT
    SET @menuId = (SELECT menuId FROM Menus)
    UPDATE Menus SET isValid = 0 WHER menuId = @menuId
END

-- jedzenie owoce morza
CREATE TRIGGER DishesWithSeafood
ON OrderDetails
INSTEAD OF INSERT
AS
BEGIN
	IF (SELECT D.Category FROM Dishes AS D WHERE D.itemId = (SELECT itemId FROM INSERTED))
	BEGIN
		DECLARE @receiveDate AS smalldatetime
		SET @receiveDate = SELECT O.receiveDate FROM Orders AS O WHERE O.orderId = (SELECT orderId FROM INSERTED)

		IF (DATENAME(WEEKDAY, @receiveDate) NOT IN ('Thursday','Friday','Saturday'))
		BEGIN
			RAISERROR ('Cannot order Seafood on that day of the week', -1, -1)
            RETURN
		END

		DECLARE @orderDate AS smalldatetime
		SET @orderDate = SELECT O.orderDate FROM Orders AS O WHERE O.orderId = (SELECT orderId FROM INSERTED)

		IF (DATENAME(WEEKDAY, @receiveDate) = 'Thursday')
		BEGIN
			IF (@orderDate > DATEADD(DAY, -3, @receiveDate)
			BEGIN
				RAISERROR ('When ordering Seafood, must order before Monday of that week', -1, -1)
				RETURN
			END
		END
		IF (DATENAME(WEEKDAY, @receiveDate) = 'Friday')
		BEGIN
			IF (@orderDate > DATEADD(DAY, -4, @receiveDate)
			BEGIN
				RAISERROR ('When ordering Seafood, must order before Monday of that week', -1, -1)
				RETURN
			END
		END
		IF (DATENAME(WEEKDAY, @receiveDate) = 'Saturday')
		BEGIN
			IF (@orderDate > DATEADD(DAY, -5, @receiveDate)
			BEGIN
				RAISERROR ('When ordering Seafood, must order before Monday of that week', -1, -1)
				RETURN
			END
		END

		INSERT INTO OrderDetails
		VALUES -- TODO

	END

END

CREATE TRIGGER OrderDateBeforeReceiveDate ON Orders FOR UPDATE AS
BEGIN
    DECLARE @orderId AS INT
    SET @orderID = (SELECT orderId FROM Orders)
    
    DECLARE @orderDate AS SMALLDATETIME
    SET @orderDate = (SELECT orderDate FROM Orders WHERE orderId = @orderID
    
    DECLARE @receiveDate AS SMALLDATETIME
    SET @receiveDate = (SELECT receiveDate FROM Orders WHERE orderId = @orderID
    
    IF (@orderDate > @receiveDate)
    BEGIN
        RAISERROR('Order date cannot be higher than receiveDate.', -1, -1);
        ROLLBACK TRANSACTION
    END
END 

CREATE TRIGGER CheckOverlappingMenus
    ON Menus
    FOR INSERT AS
BEGIN
    DECLARE @inDate SMALLDATETIME
    SET @inDate = (SELECT inDate FROM inserted)

    DECLARE @outDate SMALLDATETIME
    SET @outDate = (SELECT outDate FROM inserted)

    IF (EXISTS(SELECT *
               FROM Menus
               WHERE (mojinDate < inDate < mojoutDate < outDate)
                  OR (inDate < mojinDate < outDate < mojoutDate)
                  OR (inDate < mojinDate < mojoutDate < outDate)
                  OR (mojinDate < inDate < outDate < mojoutDate)))
    BEGIN
        RAISERROR ('Menus are overlapping.', -1, -1)
        ROLLBACK TRANSACTION 
    END
END