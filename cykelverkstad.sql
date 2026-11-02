-- DEL C: SKAPA TABELLER
-- Cykelverkstaden Trampen

-- TABELL 1: KUND

-- Skapar en tabell för verkstadens kunder
CREATE TABLE kund (

    -- Unikt kund-ID som primärnyckel (PK)
    kund_id INTEGER PRIMARY KEY,

    -- Kundens namn måste anges
    kund_namn TEXT NOT NULL,

    -- E-post måste anges och får inte förekomma hos flera kunder
    kund_epost TEXT NOT NULL UNIQUE,

    -- Kundens första telefonnummer (frivilligt)
    kund_telefon_1 TEXT,

    -- Kundens andra telefonnummer (frivilligt)
    kund_telefon_2 TEXT
);

-- DEL A: MIGRATIONSSATS
-- Lägger till en kolumn som anger om kunden samtycker till SMS
ALTER TABLE kund
ADD COLUMN sms_samtycke BOOLEAN;

-- TABELL 2: CYKEL

-- Skapar en tabell med information om kundernas cyklar
CREATE TABLE cykel (

    -- Ramnumret identifierar varje cykel och är primärnyckel (PK)
    cykel_ramnr TEXT PRIMARY KEY,

    -- Cykelns märke måste anges
    cykel_marke TEXT NOT NULL,

    -- Cykelns modell måste anges
    cykel_modell TEXT NOT NULL
);


-- TABELL 3: MEKANIKERNIVA

-- Skapar en tabell för mekanikernivåer och deras timpriser
CREATE TABLE mekanikerniva (

    -- Nivån är primärnyckel (PK), exempelvis Junior eller Senior
    mekaniker_niva TEXT PRIMARY KEY,

    -- Timpriset måste anges och får ha två decimaler
    timpris NUMERIC(8,2) NOT NULL,

    -- Säkerställer att timpriset alltid är större än noll
    CONSTRAINT kontrollera_timpris CHECK (timpris > 0)
);


-- TABELL 4: MEKANIKER

-- Skapar en tabell med information om varje mekaniker
CREATE TABLE mekaniker (

    -- Unikt ID för varje mekaniker, primärnyckel (PK)
    mekaniker_id INTEGER PRIMARY KEY,

    -- Mekanikerns namn måste anges
    mekaniker_namn TEXT NOT NULL,

    -- Anger mekanikerns nivå
    mekaniker_niva TEXT NOT NULL,

    -- Främmande nyckel (FK) som kopplar till mekanikerniva
    FOREIGN KEY (mekaniker_niva)
        REFERENCES mekanikerniva (mekaniker_niva)
);


-- TABELL 5: LEVERANTOR

-- Skapar en tabell med information om leverantörer
CREATE TABLE leverantor (

    -- Unikt ID för varje leverantör, primärnyckel (PK)
    leverantor_id INTEGER PRIMARY KEY,

    -- Leverantörens namn måste anges
    leverantor_namn TEXT NOT NULL,

    -- Leverantörens ort måste anges
    leverantor_ort TEXT NOT NULL
);


-- TABELL 6: ARTIKEL

-- Skapar en tabell med information om artiklar
CREATE TABLE artikel (

    -- Artikelnumret identifierar varje artikel och är primärnyckel (PK)
    artikel_nr TEXT PRIMARY KEY,

    -- Artikelns namn måste anges
    artikel_namn TEXT NOT NULL,

    -- Anger vilken leverantör som säljer artikeln
    leverantor_id INTEGER NOT NULL,

    -- Främmande nyckel (FK) som kopplar artikeln till en leverantör
    FOREIGN KEY (leverantor_id)
        REFERENCES leverantor (leverantor_id)
);


-- TABELL 7: ARBETSORDER

-- Skapar en tabell för verkstadens arbetsordrar
CREATE TABLE arbetsorder (

    -- Ordernumret identifierar varje arbetsorder, primärnyckel (PK)
    order_nr INTEGER PRIMARY KEY,

    -- Datumet då arbetsordern skapades
    order_datum DATE NOT NULL,

    -- Anger vilken kund som äger arbetsordern
    kund_id INTEGER NOT NULL,

    -- Anger vilken cykel som ska repareras
    cykel_ramnr TEXT NOT NULL,

    -- Anger vilken mekaniker som utför arbetet
    mekaniker_id INTEGER NOT NULL,

    -- Arbetstiden anges i minuter och måste vara större än noll
    arbetstid_min INTEGER NOT NULL CHECK (arbetstid_min > 0),

    -- Främmande nyckel (FK) till kunden
    FOREIGN KEY (kund_id)
        REFERENCES kund (kund_id),

    -- Främmande nyckel (FK) till cykeln
    FOREIGN KEY (cykel_ramnr)
        REFERENCES cykel (cykel_ramnr),

    -- Främmande nyckel (FK) till mekanikern
    FOREIGN KEY (mekaniker_id)
        REFERENCES mekaniker (mekaniker_id)
);


-- TABELL 8: ARBETSORDERARTIKEL

-- Kopplingstabell mellan arbetsordrar och artiklar.
-- Löser många-till-många-relationen (M:N).
CREATE TABLE arbetsorderartikel (

    -- Anger vilken arbetsorder artikeln tillhör
    order_nr INTEGER NOT NULL,

    -- Anger vilken artikel som ingår i arbetsordern
    artikel_nr TEXT NOT NULL,

    -- Antalet artiklar måste vara större än noll
    antal INTEGER NOT NULL CHECK (antal > 0),

    -- Styckpriset måste vara större än noll
    styckpris NUMERIC(8,2) NOT NULL CHECK (styckpris > 0),

    -- Kombinationen av ordernummer och artikelnummer är primärnyckel (PK)
    PRIMARY KEY (order_nr, artikel_nr),

    -- Främmande nyckel (FK) till arbetsordern
    FOREIGN KEY (order_nr)
        REFERENCES arbetsorder (order_nr),

    -- Främmande nyckel (FK) till artikeln
    FOREIGN KEY (artikel_nr)
        REFERENCES artikel (artikel_nr)
);

-- Kontrollera hur många rader som finns i arbetsorder
SELECT COUNT(*) FROM arbetsorder;

-- Kontrollera hur många rader som finns i kund
SELECT COUNT(*) FROM kund;

DELETE FROM kund;

-- Importera unika kunder från arbetsorder_export
INSERT INTO public.kund (
    kund_id,
    kund_namn,
    kund_epost,
    kund_telefon_1,
    kund_telefon_2
)
SELECT
    -- Skapa ett löpnummer för varje unik kund
    ROW_NUMBER() OVER (ORDER BY kund_epost)::INTEGER,
    kund_namn,
    kund_epost,
    kund_telefon_1,
    kund_telefon_2
FROM (
    -- Välj en rad per unik e-postadress
    SELECT DISTINCT ON (kund_epost)
        kund_epost,
        kund_namn,
        kund_telefon_1,
        kund_telefon_2
    FROM arbetsorder_export
    ORDER BY kund_epost
) AS unika_kunder;

-- Kontrollera hur många unika kunder som har lagts in
SELECT COUNT(*) FROM kund;

-- Visa de tre importerade kunderna
SELECT *
FROM kund
ORDER BY kund_id;


-- Importera unika cyklar från källdatan
INSERT INTO public.cykel (
    cykel_ramnr,
    cykel_marke,
    cykel_modell
)
SELECT DISTINCT
    cykel_ramnr,
    cykel_marke,
    cykel_modell
FROM arbetsorder_export;

-- Visa alla importerade cyklar
SELECT *
FROM cykel
ORDER BY cykel_ramnr;

-- Importera unika mekanikernivåer från källdatan
INSERT INTO public.mekanikerniva (
    mekaniker_niva,
    timpris
)
SELECT DISTINCT
    mekaniker_niva,
    timpris
FROM arbetsorder_export;

-- Visa de importerade mekanikernivåerna och deras timpriser
SELECT *
FROM mekanikerniva
ORDER BY mekaniker_niva;

-- Importera unika mekaniker från källdatan
INSERT INTO public.mekaniker (
    mekaniker_id,
    mekaniker_namn,
    mekaniker_niva
)
SELECT
    -- Skapa ett unikt ID för varje mekaniker
    ROW_NUMBER() OVER (ORDER BY mekaniker_namn)::INTEGER,
    mekaniker_namn,
    mekaniker_niva
FROM (
    -- Hämta varje mekaniker en gång
    SELECT DISTINCT
        mekaniker_namn,
        mekaniker_niva
    FROM arbetsorder_export
) AS unika_mekaniker;

-- Visa mekanikerna och deras nivåer
SELECT
    mekaniker_id,
    mekaniker_namn,
    mekaniker_niva
FROM mekaniker
ORDER BY mekaniker_id;

-- Importera unika leverantörer från källdatan
INSERT INTO public.leverantor (
    leverantor_id,
    leverantor_namn,
    leverantor_ort
)
SELECT
    -- Skapa ett unikt ID för varje leverantör
    ROW_NUMBER() OVER (ORDER BY leverantor)::INTEGER,
    leverantor,
    leverantor_ort
FROM (
    -- Hämta varje leverantör och ort en gång
    SELECT DISTINCT
        leverantor,
        leverantor_ort
    FROM arbetsorder_export
    WHERE leverantor IS NOT NULL
) AS unika_leverantorer;

-- Visa alla importerade leverantörer
SELECT *
FROM leverantor
ORDER BY leverantor_id;

-- Importera unika artiklar från källdatan
INSERT INTO public.artikel (
    artikel_nr,
    artikel_namn,
    leverantor_id
)
SELECT DISTINCT
    ae.artikel_nr,
    ae.artikel_namn,
    l.leverantor_id
FROM arbetsorder_export AS ae
-- Koppla artikeln till rätt leverantör via leverantörens namn och ort
JOIN public.leverantor AS l
    ON ae.leverantor = l.leverantor_namn
    AND ae.leverantor_ort = l.leverantor_ort
-- Hoppa över rader där artikel saknas
WHERE ae.artikel_nr IS NOT NULL;

-- Visa artiklarna tillsammans med deras leverantörer
SELECT
    a.artikel_nr,
    a.artikel_namn,
    l.leverantor_namn,
    l.leverantor_ort
FROM artikel AS a
-- Koppla varje artikel till dess leverantör
JOIN leverantor AS l
    ON a.leverantor_id = l.leverantor_id
ORDER BY a.artikel_nr;

-- Importera arbetsordrar från källdatan
INSERT INTO public.arbetsorder (
    order_nr,
    order_datum,
    kund_id,
    cykel_ramnr,
    mekaniker_id,
    arbetstid_min
)
SELECT DISTINCT
    ae.order_nr,
    ae.order_datum,
    k.kund_id,
    ae.cykel_ramnr,
    m.mekaniker_id,
    ae.arbetstid_min
FROM arbetsorder_export AS ae

-- Hitta rätt kund genom kundens e-postadress
JOIN public.kund AS k
    ON ae.kund_epost = k.kund_epost

-- Hitta rätt mekaniker genom mekanikerns namn
JOIN public.mekaniker AS m
    ON ae.mekaniker_namn = m.mekaniker_namn;

-- Importera artiklar som hör till respektive arbetsorder
INSERT INTO public.arbetsorderartikel (
    order_nr,
    artikel_nr,
    antal,
    styckpris
)
SELECT DISTINCT
    ae.order_nr,
    ae.artikel_nr,
    ae.antal,
    ae.styckpris
FROM arbetsorder_export AS ae

-- Ta bara med rader där en artikel faktiskt finns
WHERE ae.artikel_nr IS NOT NULL;


-- FRÅGA 4: Verifiera dataflytten med JOIN
-- LEFT JOIN gör att arbetsorder 1003 också visas trots att den saknar artikel

SELECT
    ao.order_nr,
    ao.order_datum,
    k.kund_namn,
    k.kund_epost,
    ao.cykel_ramnr,
    c.cykel_marke,
    c.cykel_modell,
    m.mekaniker_namn,
    ao.arbetstid_min,
    a.artikel_nr,
    a.artikel_namn,
    a.leverantor_id,
    aa.antal,
    aa.styckpris

FROM arbetsorder AS ao

-- Hämta information om kunden
JOIN kund AS k
    ON ao.kund_id = k.kund_id

-- Hämta information om cykeln
JOIN cykel AS c
    ON ao.cykel_ramnr = c.cykel_ramnr

-- Hämta information om mekanikern
JOIN mekaniker AS m
    ON ao.mekaniker_id = m.mekaniker_id

-- Hämta eventuella artiklar till arbetsordern
LEFT JOIN arbetsorderartikel AS aa
    ON ao.order_nr = aa.order_nr

-- Hämta artikelns namn och nummer
LEFT JOIN artikel AS a
    ON aa.artikel_nr = a.artikel_nr

-- Sortera resultatet efter arbetsordernummer
ORDER BY ao.order_nr, a.artikel_nr;


-- FRÅGA 5: Testa CHECK-regeln för timpris
-- Försöker lägga in ett timpris på 0, vilket inte är tillåtet
INSERT INTO public.mekanikerniva (
    mekaniker_niva,
    timpris
)
VALUES (
    'Testnivå',
    0
);

-- FRÅGA 5: Testa FK-regeln för kund_id
-- Försöker skapa en arbetsorder med en kund som inte finns
INSERT INTO public.arbetsorder (
    order_nr,
    order_datum,
    kund_id,
    cykel_ramnr,
    mekaniker_id,
    arbetstid_min
)
VALUES (
    9999,
    '2026-10-01',
    9999,
    'WSBC-4411',
    1,
    30
);
