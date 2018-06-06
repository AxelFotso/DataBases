a-b)
CREATE TRIGGER CheckNewMeasure
AFTER INSERT ON EVENT-LOG
FOR EACH ROW
WHEN (NEW.EventType = 'M')
DECLARE
  GH number;
  TOTSENSOR number;
  x number;
  y number;
  Loc varchar(10);
BEGIN
  -- insert the new measure in the measure table
  INSERT INTO MEASURE(SCode, TimeStamp, Value)
  VALUES(:NEW.SCode, :NEW.TimeStamp, :NEW.Value);
  
  -- read the total number of sensors in the greenhouse:
  -- 1. read the code of the greenhouse
  SELECT GHCode INTO GH
  FROM SENSOR
  WHERE SCode = :NEW.SCode;
  
  -- 2. read the number of sensors
  SELECT Sensor#, Location INTO TOTSENSORS, Loc
  FROM GREENHOUSE
  WHERE GHCode = GH;
  
  {-- alternative solution
  SELECT GHCode, Sensor#, Location INTO GH, TOTSENSORS, Loc
  FROM SENSOR SE, GREENHOUSE G
  WHERE SE.SCode = :NEW.SCode AND SE.GHCode = G.GHCode;}
  
  SELECT COUNT(*) INTO x
  FROM SENSOR SE, SENSOR-DAILY-SUMMARY S, MEASURE M
  WHERE SE.GHCode = GH AND S.Date = DATE(:NEW.TimeStamp) AND SE.SCode = S.SCode AND DATE(M.TimeStamp) = DATE(:NEW.TimeStamp) AND M.SCode = SE.SCode AND M.TimeStamp = (SELECT MAX(TimeStamp)
  FROM MEASURE M1
  WHERE M1.SCode = M.SCode)
  AND M.Value - S.AVGValue > SE.CriticalOffset;
  
  IF (x > TOTSENSORS / 2)
  THEN
    -- insert the new notification
    SELECT MAX(NCode) INTO y
    FROM NOTIFICATION;
  
    {-- alternative, BUT tuples could be removed from the NOTIFICATION table!
    SELECT COUNT(*) INTO y
    FROM NOTIFICATION;}
    
    IF (y IS NULL) THEN
      y := 0;
    END IF;x
    
    INSERT INTO NOTIFICATION(NCode, GHCode, Location, Message)
    VALUES(y+1, GH, Loc, 'Critical condition');
  END IF;
END;

c)
CREATE TRIGGER CheckCorrectValue
BEFORE INSERT ON EVENT_LOG
FOR EACH ROW
WHEN (NEW.EventType == 'M' AND NEW.Value < -50)
DECLARE
  x varchar[];
BEGIN
  -- read the measurement for the sensor
  SELECT Measurement INTO x
  FROM SENSOR
  WHERE SCode = :NEW.SCode;
  IF (Measurement == 'Temperature')
  THEN -- the constraint is violated -> the compensative action is implemented
    :NEW.Value := -50;
  -- ELSE -- the sensor doesn't measure the temperature or the sensor does not exist
  END IF;
END;

CREATE TRIGGER CheckGreenhouse
AFTER INSERT OR UPDATE OF CriticalOffset, GHCode ON SENSOR
DECLARE
  N number;
BEGIN
  SELECT COUNT(*) into N
  FROM GREENHOUSE
  WHERE GHCode IN (SELECT GHCode
				  FROM SENSOR
				  WHERE CriticalOffset > 50
				  GROUP BY GHCode
				  HAVING COUNT(*) > 200);
  IF (N <> 0)
  THEN
    RAISE_APPLICATION_ERROR(xxx, 'Constraint violated');
  END IF;
END;