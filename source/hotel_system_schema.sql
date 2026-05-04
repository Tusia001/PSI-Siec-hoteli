-- =========================================================
-- SYSTEM: System zarządzania siecią hoteli
-- BAZA: PostgreSQL (wersja 12+)
--
-- CHARAKTERYSTYKA:
-- - Wykorzystano PostgreSQL-specific features:
--   * GENERATED ALWAYS AS IDENTITY (zamiast SERIAL)
--   * ENUM dla statusów i typów
-- - Model zgodny z 3NF (z wyjątkiem kontrolowanej denormalizacji: kwota w DokumentFiskalny)
-- - Zaimplementowano klucze główne, obce, ograniczenia CHECK oraz indeksy
-- =========================================================


-- =========================================================
-- TYPES (ENUMY)
-- =========================================================
CREATE TYPE status_rezerwacji AS ENUM ('utworzona', 'potwierdzona', 'oplacona', 'zakonczona', 'anulowana');
CREATE TYPE status_platnosci  AS ENUM ('oczekujaca', 'zrealizowana', 'odrzucona');
CREATE TYPE typ_dokumentu     AS ENUM ('paragon', 'faktura');


-- =========================================================
-- TABELA: Uzytkownik
-- =========================================================
CREATE TABLE uzytkownik (
    id        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    login     VARCHAR(100) NOT NULL UNIQUE,
    haslo     VARCHAR(255) NOT NULL,
    aktywny   BOOLEAN NOT NULL DEFAULT TRUE
);


-- =========================================================
-- TABELA: Gosc
-- =========================================================
CREATE TABLE gosc (
    id               INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    imie             VARCHAR(100) NOT NULL,
    nazwisko         VARCHAR(100) NOT NULL,
    email            VARCHAR(255) NOT NULL UNIQUE,
    uzytkownik_id    INT NOT NULL UNIQUE,
    CONSTRAINT fk_gosc_uzytkownik
        FOREIGN KEY (uzytkownik_id)
        REFERENCES uzytkownik(id)
        ON DELETE CASCADE
);


-- =========================================================
-- TABELA: Recepcjonista
-- =========================================================
CREATE TABLE recepcjonista (
    id               INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    imie             VARCHAR(100) NOT NULL,
    nazwisko         VARCHAR(100) NOT NULL,
    uzytkownik_id    INT NOT NULL UNIQUE,
    CONSTRAINT fk_recepcjonista_uzytkownik
        FOREIGN KEY (uzytkownik_id)
        REFERENCES uzytkownik(id)
        ON DELETE CASCADE
);


-- =========================================================
-- TABELA: Hotel
-- =========================================================
CREATE TABLE hotel (
    id           INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nazwa        VARCHAR(255) NOT NULL,
    lokalizacja  VARCHAR(255) NOT NULL
);


-- =========================================================
-- TABELA: Pokoj
-- =========================================================
CREATE TABLE pokoj (
    id         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    numer      INT NOT NULL,
    standard   VARCHAR(100) NOT NULL,
    cena       NUMERIC(10,2) NOT NULL CHECK (cena >= 0),
    hotel_id   INT NOT NULL,
    CONSTRAINT fk_pokoj_hotel
        FOREIGN KEY (hotel_id)
        REFERENCES hotel(id)
        ON DELETE CASCADE,
    CONSTRAINT uq_pokoj_hotel_numer UNIQUE (hotel_id, numer)
);


-- =========================================================
-- TABELA: Rezerwacja
-- =========================================================
CREATE TABLE rezerwacja (
    id                  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    data_od             DATE NOT NULL,
    data_do             DATE NOT NULL,
    status              status_rezerwacji NOT NULL,
    gosc_id             INT NOT NULL,
    pokoj_id            INT NOT NULL,
    recepcjonista_id    INT NULL,
    CONSTRAINT fk_rezerwacja_gosc
        FOREIGN KEY (gosc_id)
        REFERENCES gosc(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_rezerwacja_pokoj
        FOREIGN KEY (pokoj_id)
        REFERENCES pokoj(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_rezerwacja_recepcjonista
        FOREIGN KEY (recepcjonista_id)
        REFERENCES recepcjonista(id)
        ON DELETE SET NULL,
    CONSTRAINT chk_daty_rezerwacji CHECK (data_od < data_do)
);


-- =========================================================
-- TABELA: OperatorPlatnosci
-- =========================================================
CREATE TABLE operator_platnosci (
    id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nazwa   VARCHAR(100) NOT NULL
);


-- =========================================================
-- TABELA: Platnosc
-- =========================================================
CREATE TABLE platnosc (
    id               INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kwota            NUMERIC(10,2) NOT NULL CHECK (kwota >= 0),
    status           status_platnosci NOT NULL,
    data             TIMESTAMP NOT NULL,
    rezerwacja_id    INT NOT NULL,
    operator_id      INT NOT NULL,
    CONSTRAINT fk_platnosc_rezerwacja
        FOREIGN KEY (rezerwacja_id)
        REFERENCES rezerwacja(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_platnosc_operator
        FOREIGN KEY (operator_id)
        REFERENCES operator_platnosci(id)
);


-- =========================================================
-- TABELA: DokumentFiskalny
-- =========================================================
CREATE TABLE dokument_fiskalny (
    id               INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    typ              typ_dokumentu NOT NULL,
    kwota            NUMERIC(10,2) NOT NULL CHECK (kwota >= 0),
    rezerwacja_id    INT NOT NULL UNIQUE,
    CONSTRAINT fk_dokument_rezerwacja
        FOREIGN KEY (rezerwacja_id)
        REFERENCES rezerwacja(id)
        ON DELETE CASCADE
);


-- =========================================================
-- INDEKSY (wydajność)
-- =========================================================
CREATE INDEX idx_rezerwacja_gosc       ON rezerwacja(gosc_id);
CREATE INDEX idx_rezerwacja_pokoj      ON rezerwacja(pokoj_id);
CREATE INDEX idx_platnosc_rezerwacja   ON platnosc(rezerwacja_id);
CREATE INDEX idx_pokoj_hotel           ON pokoj(hotel_id);