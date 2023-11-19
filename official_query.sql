
--ktore osobniki sa chore
DROP VIEW chorzy;

CREATE VIEW chorzy AS 
SELECT K.zwierze_id,
		K.data data_kontroli,
		Z.imie,
		Z.gatunek,
		Z.plec,
		Z.wiek,
		W.weterynarz_id,
		W.nr_telefonu nr_tel_weterynarza
FROM dbo.KONTROLA_WETERYNARYJNA K 
inner join
(
  SELECT max(data) mxdata, zwierze_id
  FROM dbo.KONTROLA_WETERYNARYJNA
  GROUP BY zwierze_id
  
) K2
  ON K.zwierze_id = K2.zwierze_id
  and K.data = K2.mxdata
  inner join dbo.ZWIERZETA Z ON K.zwierze_id = Z.zwierze_id
  inner join dbo.WETERYNARZE W ON K.weterynarz_id = W.weterynarz_id
  WHERE K.zdrowy = 0;

SELECT * FROM chorzy;


--informacje dla sponsorow
CREATE VIEW dla_sponsorow AS
SELECT Z.sponsor_id,
Z.zwierze_id,
Z.gatunek,
Z.imie,
Z.wiek,
Z.plec,
Z.opiekun_id,
K.kdata data_ostatniego_posilku,
W.wdata data_ostatniej_kontroli_weterynaryjnej
FROM dbo.ZWIERZETA Z

inner join 
(
SELECT
wybieg_id,
 max(data) kdata
FROM
dbo.KARMIENIE
GROUP BY wybieg_id
) K
ON Z.wybieg_id = K.wybieg_id

inner join 
(
SELECT 
zwierze_id,
 max(data) wdata
FROM
dbo.KONTROLA_WETERYNARYJNA
GROUP BY zwierze_id
) W
ON Z.zwierze_id = W.zwierze_id

WHERE Z.sponsor_id IS NOT NULL;

SELECT * FROM dla_sponsorow
WHERE sponsor_id=1;

--indeksy
CREATE INDEX index_gatunek ON dbo.ZWIERZETA (gatunek);
CREATE INDEX index_stanowisko ON dbo.OPIEKUNOWIE (stanowisko);
CREATE INDEX index_opiekun_imie_nazwisko ON dbo.OPIEKUNOWIE (imie, nazwisko);
CREATE INDEX index_weterynarz_imie_nazwisko ON dbo.WETERYNARZE (imie, nazwisko);
CREATE INDEX index_kontrola_data ON dbo.KONTROLA_WETERYNARYJNA (data);
CREATE INDEX index_czyszczenie_data ON dbo.CZYSZCZENIE (data);

DROP INDEX index_gatunek ON dbo.ZWIERZETA;
DROP INDEX index_stanowisko ON dbo.OPIEKUNOWIE;
DROP INDEX index_opiekun_imie_nazwisko ON dbo.OPIEKUNOWIE;
DROP INDEX index_weterynarz_imie_nazwisko ON dbo.WETERYNARZE;
DROP INDEX index_kontrola_data ON dbo.KONTROLA_WETERYNARYJNA;
DROP INDEX index_czyszczenie_data ON dbo.CZYSZCZENIE;



--czesc 2-----------------------------------------------------------------
DROP VIEW CzestoscCzyszczenia;
CREATE VIEW CzestoscCzyszczenia AS
SELECT 
C.czestosc_czyszczenia,
C.wybieg_id,
Z.gatunek
FROM 
(
SELECT COUNT(czyszczenie_id) czestosc_czyszczenia,
wybieg_id
FROM dbo.CZYSZCZENIE
WHERE data>= '2022-10-01' and data<='2022-10-31'
GROUP BY wybieg_id
) C
inner join dbo.ZWIERZETA Z ON C.wybieg_id = Z.wybieg_id
GROUP BY Z.gatunek, C.czestosc_czyszczenia, C.wybieg_id;

CREATE VIEW CzestoscKarmienia AS
SELECT KZ.nazwa_posilku,
P.czestosc_podawania,
KZ.gatunek
FROM
(
SELECT nazwa_posilku,
gatunek
FROM
(
SELECT nazwa_posilku,
wybieg_id
FROM dbo.KARMIENIE
GROUP BY nazwa_posilku, wybieg_id
) K
inner join dbo.ZWIERZETA Z ON K.wybieg_id = Z.wybieg_id
GROUP BY nazwa_posilku, gatunek
)KZ
inner join
(
SELECT nazwa_posilku,
COUNT(nazwa_posilku) czestosc_podawania
FROM dbo.KARMIENIE
WHERE data >= '2022-10-01' and data<='2022-10-31'
GROUP BY nazwa_posilku
) P
ON KZ.nazwa_posilku = P.nazwa_posilku;



---funkcje------
DROP FUNCTION SponsorInfo;
CREATE FUNCTION SponsorInfo (@sponsor INT)
RETURNS TABLE AS
RETURN (
		SELECT Z.sponsor_id,
		Z.zwierze_id,
		Z.gatunek,
		Z.imie,
		Z.wiek,
		Z.plec,
		Z.opiekun_id,
		K.kdata data_ostatniego_posilku,
		W.wdata data_ostatniej_kontroli_weterynaryjnej
		FROM dbo.ZWIERZETA Z

		inner join 
		(
		SELECT
		wybieg_id,
		 max(data) kdata
		FROM
		dbo.KARMIENIE
		GROUP BY wybieg_id
		) K
		ON Z.wybieg_id = K.wybieg_id

		inner join 
		(
		SELECT 
		zwierze_id,
		 max(data) wdata
		FROM
		dbo.KONTROLA_WETERYNARYJNA
		GROUP BY zwierze_id
		) W
		ON Z.zwierze_id = W.zwierze_id

		WHERE Z.sponsor_id = @sponsor
		);

SELECT * FROM SponsorInfo(2);

DROP FUNCTION ZwierzeInfo;
CREATE FUNCTION ZwierzeInfo (@opiekun INT)
RETURNS TABLE AS
RETURN (
SELECT 
Z.zwierze_id,
Z.gatunek,
Z.imie,
Z.wiek,
Z.plec,
Z.sponsor_id,
K.kdata data_ostatniego_posilku,
C.cdata data_ostatniego_sprz¹tania,
W.wdata data_ostatniej_kontroli_weterynaryjnej,
WW.zdrowy,
WE.weterynarz_id,
WE.nr_telefonu nr_tel_weterynarza
FROM dbo.ZWIERZETA Z

inner join 
(
SELECT
wybieg_id,
 max(data) kdata
FROM
dbo.KARMIENIE
GROUP BY wybieg_id
) K
ON Z.wybieg_id = K.wybieg_id

inner join 
(
SELECT
wybieg_id,
 max(data) cdata
FROM
dbo.CZYSZCZENIE
GROUP BY wybieg_id
) C
ON Z.wybieg_id = C.wybieg_id

inner join 
(
SELECT 
zwierze_id,
max(data) wdata
FROM
dbo.KONTROLA_WETERYNARYJNA
GROUP BY zwierze_id
)W
ON Z.zwierze_id = W.zwierze_id

inner join
(
SELECT weterynarz_id,
zdrowy,
data
FROM dbo.KONTROLA_WETERYNARYJNA
) WW
ON W.wdata = WW.data

inner join dbo.WETERYNARZE WE on WW.weterynarz_id = WE.weterynarz_id

WHERE Z.opiekun_id = @opiekun
GROUP BY Z.zwierze_id, Z.gatunek, Z.imie, Z.wiek, Z.plec, Z.sponsor_id, 
K.kdata, C.cdata, W.wdata, WE.weterynarz_id, WE.nr_telefonu, WW.zdrowy

);

SELECT * FROM ZwierzeInfo (2);


-----procedury----

DROP PROCEDURE CzyszczenieAdd;
CREATE PROCEDURE CzyszczenieAdd @opiekun INT
AS 

DECLARE @id_c AS INT
SELECT @id_c = max(czyszczenie_id) FROM dbo.CZYSZCZENIE

DECLARE @id_w AS INT
SELECT @id_w = wybieg_id
FROM dbo.ZWIERZETA
WHERE opiekun_id = @opiekun


BEGIN TRAN T1
INSERT INTO dbo.CZYSZCZENIE(czyszczenie_id, data, wybieg_id, opiekun_id)
VALUES (@id_c+1, GETDATE(), @id_w, @opiekun)
IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION
        return 10
    END
COMMIT TRAN T1;

EXEC CzyszczenieAdd @opiekun = 1;
SELECT * FROM dbo.CZYSZCZENIE;

DROP PROCEDURE KarmienieAdd;
CREATE PROCEDURE KarmienieAdd @opiekun INT, @posilek VARCHAR(64)
AS 

DECLARE @id_k AS INT
SELECT @id_k = max(karmienie_id) FROM dbo.KARMIENIE

DECLARE @id_w AS VARCHAR(64)
SELECT @id_w = wybieg_id
FROM dbo.ZWIERZETA
WHERE opiekun_id = @opiekun


BEGIN TRAN T1
INSERT INTO dbo.KARMIENIE(karmienie_id, nazwa_posilku, data, godzina, wybieg_id, opiekun_id)
VALUES (@id_k+1, @posilek, GETDATE(), CAST (GETDATE() AS TIME), @id_w, @opiekun)
IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION
        return 10
    END
COMMIT TRAN T1;

EXEC KarmienieAdd @opiekun = 1, @posilek = 'wo³owina';


DROP PROCEDURE KontrolaAdd;
CREATE PROCEDURE KontrolaAdd @weterynarz INT, @zwierze INT, @zdrowy bit
AS 

BEGIN TRAN T1
INSERT INTO dbo.KONTROLA_WETERYNARYJNA(data, zdrowy, zwierze_id, weterynarz_id)
VALUES (GETDATE(), @zdrowy, @zwierze, @weterynarz)
IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION
        return 10
    END
COMMIT TRAN T1
GO;

EXEC KontrolaAdd @weterynarz = 1, @zwierze = 1, @zdrowy = 1;

DROP PROCEDURE KarmienieUpdate;
CREATE PROCEDURE KarmienieUpdate @opiekun INT, @posilek VARCHAR(64)
AS 
BEGIN TRANSACTION

DECLARE @id AS INT
SELECT @id = max(karmienie_id)
FROM
dbo.KARMIENIE
where opiekun_id = @opiekun

UPDATE dbo.KARMIENIE
SET nazwa_posilku='stek'
WHERE karmienie_id = @id

IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION
        return 11
    END
COMMIT TRANSACTION;

EXEC KarmienieUpdate @opiekun = 1, @posilek = 'stek';

DROP PROCEDURE KontrolaUpdate;
CREATE PROCEDURE KontrolaUpdate @weterynarz INT, @zwierze INT, @zdrowy bit
AS 
BEGIN TRANSACTION

DECLARE @id AS INT
SELECT @id = max(kontrola_id)
FROM
dbo.KONTROLA_WETERYNARYJNA
where weterynarz_id = @weterynarz

UPDATE dbo.KONTROLA_WETERYNARYJNA
SET zdrowy= @zdrowy, zwierze_id = @zwierze
WHERE kontrola_id = @id

IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION
        return 11
    END
COMMIT TRANSACTION;

EXEC KontrolaUpdate @weterynarz = 1, @zwierze = 1, @zdrowy = 0;

DROP PROCEDURE SponsorAdd;
CREATE PROCEDURE SponsorAdd @nazwa VARCHAR(64), @ulica VARCHAR(64), @miasto VARCHAR(64)
AS 

BEGIN TRAN T1
INSERT INTO dbo.SPONSORZY(nazwa_spolki, ulica, miasto)
VALUES (@nazwa, @ulica, @miasto)
IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION
        return 10
    END
COMMIT TRAN T1;

EXEC SponsorAdd @nazwa = '¿abka', @ulica = 'Jasna 6', @miasto = 'Warszawa';

DROP PROCEDURE SponsorUpdate;
CREATE PROCEDURE SponsorUpdate @nazwa VARCHAR(64), @ulica VARCHAR(64), @miasto VARCHAR(64)
AS 

BEGIN TRAN T1
UPDATE dbo.SPONSORZY
SET ulica= @ulica, miasto = @miasto
WHERE nazwa_spolki = @nazwa
IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION
        return 11
    END
COMMIT TRAN T1
GO;

EXEC SponsorUpdate @nazwa = '¿abka', @ulica = 'Jasna 6', @miasto = 'Warszawa';

DROP PROCEDURE ZwierzeAdd;
CREATE PROCEDURE ZwierzeAdd @gatunek VARCHAR(64), @imie VARCHAR(64), @wiek INT, @plec VARCHAR(8), @opiekun INT, @wybieg INT
AS 

BEGIN TRAN T1

IF @plec NOT IN ('samiec', 'samica')
	BEGIN
        ROLLBACK TRANSACTION
        PRINT 'Podana b³êdna p³eæ, wybierz samiec lub samica'
        return 11
    END
INSERT INTO dbo.ZWIERZETA(gatunek, imie, wiek, plec, opiekun_id, wybieg_id, sponsor_id)
VALUES (@gatunek, @imie, @wiek, @plec, @opiekun, @wybieg, NULL)
IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION
        return 11
    END

COMMIT TRAN T1
GO;

EXEC ZwierzeAdd @gatunek = 'lew', @imie = 'Nana', @wiek = 6, @plec = 'samica', @opiekun = 1, @wybieg = 1;

DROP PROCEDURE ZwierzeUpdate;
CREATE PROCEDURE ZwierzeUpdate @gatunek VARCHAR(64), @imie VARCHAR(64), @kolumna VARCHAR(64), @wartosc VARCHAR(64)
AS 

BEGIN TRAN T1

DECLARE @id AS INT
SELECT @id = zwierze_id
from ZWIERZETA
where gatunek = @gatunek and imie = @imie


IF @kolumna IN ('wiek', 'plec', 'opiekun', 'wybieg', 'sponsor')
	BEGIN
	IF @kolumna = 'wiek' 
		UPDATE dbo.ZWIERZETA SET wiek= CAST(@wartosc AS INT) WHERE zwierze_id = @id
	IF @kolumna = 'plec'
		BEGIN
			IF @wartosc NOT IN ('samiec', 'samica')
				BEGIN
					ROLLBACK TRANSACTION
					   PRINT 'Podana b³êdna p³eæ, wybierz samiec lub samica'
					return 11
				END
		UPDATE dbo.ZWIERZETA SET plec= @wartosc WHERE zwierze_id = @id
		END
	IF @kolumna = 'opiekun'
		UPDATE dbo.ZWIERZETA SET opiekun_id = CAST(@wartosc AS INT) WHERE zwierze_id = @id
	IF @kolumna = 'wybieg'
		UPDATE dbo.ZWIERZETA SET wybieg_id= CAST(@wartosc AS INT) WHERE zwierze_id = @id
	IF @kolumna = 'sponsor'
		UPDATE dbo.ZWIERZETA SET sponsor_id= CAST(@wartosc AS INT) WHERE zwierze_id = @id
	END
ELSE 
	BEGIN
		ROLLBACK TRANSACTION
		PRINT 'Podana b³êdna nazwa kolumny. Do wyboru: wiek, plec, opiekun, wybieg, sponsor'
		return 11
	END


IF @@ERROR <> 0
    BEGIN
        ROLLBACK TRANSACTION
        return 11
    END

COMMIT TRAN T1;


EXEC ZwierzeUpdate @gatunek = 'lew', @imie = 'Nina', @kolumna = 'wiek', @wartosc = '6';
SELECT * FROM ZWIERZETA;

DELETE FROM ZWIERZETA WHERE zwierze_id = 16;

------wyzwalacze---
DROP TRIGGER czestosc_karmienia;
CREATE TRIGGER czestosc_karmienia
ON dbo.KARMIENIE
FOR INSERT, UPDATE
AS
BEGIN
	DECLARE @cnt AS INT
	SELECT 
	@cnt = count(K.wybieg_id)
	from dbo.KARMIENIE K
	inner join
	inserted I on K.wybieg_id = I.wybieg_id
	WHERE DATEPART(week, K.data) = DATEPART(week, GETDATE())
	and I.wybieg_id = K.wybieg_id

	DECLARE @gat AS VARCHAR(64)
	SELECT @gat = Z.gatunek
	FROM dbo.ZWIERZETA Z
	inner join 
	inserted I ON Z.wybieg_id = I.wybieg_id
	WHERE Z.wybieg_id = I.wybieg_id

	BEGIN
		PRINT @gat + ' by³ karmiony ' + CAST(@cnt AS VARCHAR(64)) + ' razy w tym tygodniu'
	END
END;

EXEC KarmienieAdd @opiekun = 1, @posilek = 'wo³owina';

DROP TABLE ZWIERZETA_ZMIANY;
CREATE TABLE ZWIERZETA_ZMIANY
(    
id_zmiany int IDENTITY,   
opis text,
data DATE
);

DROP TRIGGER zwierzeta_zmiany_add;
CREATE TRIGGER zwierzeta_zmiany_add
ON ZWIERZETA  
after INSERT, UPDATE, DELETE
AS  
BEGIN
DECLARE @zmiana VARCHAR(64)
SET @zmiana = CASE
        WHEN EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted)
            THEN 'Zmienione'
        WHEN EXISTS(SELECT * FROM inserted)
            THEN 'Nowe'
        WHEN EXISTS(SELECT * FROM deleted)
            THEN 'Usuniête'
		END

Declare @id int  
SELECT @id = zwierze_id from inserted  
INSERT INTO dbo.ZWIERZETA_ZMIANY(opis, data) 
VALUES (@zmiana + ' zwierze z id = ' + CAST(@id AS VARCHAR(64)), Getdate())  
END; 

EXEC ZwierzeUpdate @gatunek = 'lew', @imie = 'Nina', @kolumna = 'wieku', @wartosc = '6';
SELECT * FROM dbo.ZWIERZETA_ZMIANY

 

SELECT *
FROM   [zoo].[zoo].[public].[zwierzeta]

select * from ZWIERZETA


SET IDENTITY_INSERT dbo.ZWIERZETA ON

INSERT INTO dbo.ZWIERZETA(zwierze_id, gatunek, imie, wiek, plec, opiekun_id, wybieg_id, sponsor_id)
select * from [zoo].[zoo].[public].[zwierzeta] where zwierze_id not in (
select Z.zwierze_id from dbo.ZWIERZETA Z
    join [zoo].[zoo].[public].[zwierzeta] Z2 on Z.zwierze_id = Z2.zwierze_id)



delete from dbo.ZWIERZETA where zwierze_id not in (
select Z2.zwierze_id from dbo.ZWIERZETA Z
    right join [zoo].[zoo].[public].[zwierzeta] Z2 on Z.zwierze_id = Z2.zwierze_id)



update Z set Z.gatunek=Z2.gatunek, Z.imie=Z2.imie, Z.wiek=Z2.wiek, Z.plec=Z2.plec, 
Z.opiekun_id=Z2.opiekun_id, Z.wybieg_id=Z2.wybieg_id, Z.sponsor_id=Z2.sponsor_id
from dbo.ZWIERZETA Z
    join [zoo].[zoo].[public].[zwierzeta] Z2 on Z.zwierze_id = Z2.zwierze_id
    where Z.gatunek!=Z2.gatunek or Z.imie!=Z2.imie or Z.wiek!=Z2.wiek or Z.plec!=Z2.plec
	or Z.opiekun_id!=Z2.opiekun_id or Z.wybieg_id!=Z2.wybieg_id or Z.sponsor_id!=Z2.sponsor_id

BACKUP DATABASE zoo
TO Disk ='D:\studia\magisterka\sem2\zaawansowane_bazy_danych\proj2\backup_log\zoo.bak'