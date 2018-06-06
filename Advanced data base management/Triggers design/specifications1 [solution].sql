CREATE TRIGGER Rental_Cancellation
AFTER INSERT ON RENTAL-CANCELLATION
FOR EACH ROW

DECLARE
  N number;
  Req number;
  StartDate number;
  EndDate number;
  MemberCode number;

BEGIN
  SELECT COUNT(*) INTO N
  FROM RENTAL
  WHERE BCode = :NEW.BCode AND StartDate = :NEW.RentalStartDate AND MemberCode = :NEW.MemberCode;

  IF (N > 0)
  THEN

    -- I want to consider also the waiting rentals that end after the end date of the rental being canceled,
    -- so for each waiting rental I have to check if there is already a rental, for the boat that is becoming free, that starts before the end date of the waiting rental.
    SELECT ReqCode, RentalStartDate, RentalEndDate, MemberCode INTO Req, StartDate, EndDate, MemberCode -- There will be a single ReqCode by hypothesis.
    FROM WAITING-RENTAL W
    WHERE W.Model = (SELECT Model
	FROM BOAT
	WHERE BCode = :NEW.BCode) AND W.RentalStartDate > :NEW.CancDate AND W.RentalStartDate < (SELECT EndDate
	FROM RENTAL
	WHERE BCode = :NEW.BCode AND StartDate = :NEW.RentalStartDate) AND NOT EXISTS (SELECT *
	FROM RENTAL R1
	WHERE R1.BCode = :NEW.BCode AND R1.StartDate > (SELECT R2.EndDate
	    FROM RENTAL R2
	    WHERE R2.BCode = :NEW.BCode AND R2.StartDate = :NEW.RentalStartDate) AND R1.StartDate < W.RentalEndDate);

    DELETE FROM RENTAL
    WHERE BCode = :NEW.BCode AND StartDate = :NEW.RentalStartDate; -- MemberCode is not needed anymore because it is not in the primary key.

    INSERT INTO RENTAL(BCode, StartDate, EndDate, MemberCode)
    VALUES(:NEW.BCode, StartDate, EndDate, MemberCode);

    DELETE FROM WAITING-RENTAL(ReqCode, ReqDate, MemberCode, RentalStartDate, RentalEndDate, Model)
    WHERE ReqCode = Req;
  END IF;
END;
