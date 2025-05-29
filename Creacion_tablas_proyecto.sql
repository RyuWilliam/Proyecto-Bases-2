--Tabla de estadísticas de país

CREATE TABLE COUNTRIES_STATS (
    countries_stats_id     NUMBER,
    country_name           VARCHAR2(150),
    year                   NUMBER(4),
    per_capita_income      NUMBER(10,2),
    education_index        NUMBER(3,2),
    urbanization_rate      NUMBER(5,2),
    healthcare_access      NUMBER(5,2),
    doctor_per_1000        NUMBER(4,2),
    hospital_beds_per_1000 NUMBER(4,2)
)
TABLESPACE ts_datos;

--Tabla categoria de enfermedad

CREATE TABLE DISEASE_CATEGORY (
    disease_category_id    NUMBER,
    disease_category_name  VARCHAR2(100)
)
TABLESPACE ts_datos;

--Tabla tratamiento de la enfermedad

CREATE TABLE DISEASE_TREATMENT (
    disease_T_id            NUMBER,
    treatment_type          VARCHAR2(100),
    avg_treatment_cost      NUMBER(10,2),
    vacciness_disponibility CHAR(1)
)
TABLESPACE ts_datos;

--Tabla enfermedad

CREATE TABLE DISEASE (
    disease_id           NUMBER,
    disease_category_id  NUMBER(5),
    disease_T_id         NUMBER,
    disease_name         VARCHAR2(150)
)
TABLESPACE ts_datos;

--Tabla de estadísticas de salud

CREATE TABLE HEALTH_STATS (
    health_stats_id        NUMBER,
    age_group              VARCHAR2(20),
    gender                 VARCHAR2(10),
    prevalence_rate        NUMBER(10,2),
    mortality_rate         NUMBER(10,2),
    incidence_rate         NUMBER(10,2),
    population_affected    NUMBER(10),
    recovery_rate          NUMBER(10,2),
    dalys                  NUMBER(8),
    five_year_improvement  NUMBER(5,2),
    countries_stats_id     NUMBER,
    disease_id             NUMBER
)
TABLESPACE ts_datos;
