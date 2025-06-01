
/*Ojo, crear las tablas en este orden, y también los procedures salu2 
*/
-- 1. Tabla temporal para carga del CSV
CREATE TABLE temp_global_health (
    country_name             VARCHAR2(100 BYTE),
    year                     NUMBER(4,0),
    per_capita_income        NUMBER(10,0),
    education_index          NUMBER(3,2),
    urbanization_rate        NUMBER(5,2),
    healthcare_access        NUMBER(5,2),
    doctor_per_1000          NUMBER(5,2),
    hospital_beds_per_1000   NUMBER(5,2),
    disease_category_name    VARCHAR2(100 BYTE),
    disease_name             VARCHAR2(150 BYTE),
    treatment_type           VARCHAR2(100 BYTE),
    avg_treatment_cost       NUMBER(10,0),
    vacciness_disponibility  CHAR(3 BYTE),
    age_group                VARCHAR2(10 BYTE),
    gender                   VARCHAR2(10 BYTE),
    prevalence_rate          NUMBER(5,2),
    incidence_rate           NUMBER(5,2),
    mortality_rate           NUMBER(5,2),
    population_affected      NUMBER(10,0),
    recovery_rate            NUMBER(5,2),
    dalys                    NUMBER(10,0),
    five_year_improvement    NUMBER(5,2)
)
TABLESPACE ts_datos;

-- 2. Tabla de control de cargas
CREATE TABLE procesos_carga_control (
    nombre_tabla       VARCHAR2(100 BYTE),
    filas_afectadas    NUMBER,
    operacion          VARCHAR2(10 BYTE),
    fecha_proceso      DATE,
    usuario_proceso    VARCHAR2(50 BYTE)
)
TABLESPACE ts_datos;

--CREACION DE SECUENCIAS

CREATE SEQUENCE seq_health_stats_id
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE seq_disease_id
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE seq_disease_category_id
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE seq_disease_treatment_id
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE seq_countries_stats_id
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

-- 3. Procedimiento de carga countries_stats
create or replace PROCEDURE cargar_tabla_countries_stats IS
    v_filas_afectadas NUMBER;
    v_usuario         VARCHAR2(50);
BEGIN

    -- Obtener el usuario actual
    SELECT USER INTO v_usuario FROM dual;

    -- Insertar datos
    INSERT INTO Countries_stats (
        COUNTRIES_STATS_ID,
        COUNTRY_NAME,
        YEAR,
        PER_CAPITA_INCOME,
        EDUCATION_INDEX,
        URBANIZATION_RATE,
        HEALTHCARE_ACCESS,
        DOCTOR_PER_1000,
        HOSPITAL_BEDS_PER_1000
    )
    SELECT
        seq_countries_stats_id.NEXTVAL,
        COUNTRY_NAME,
        YEAR,
        PER_CAPITA_INCOME,
        EDUCATION_INDEX,
        URBANIZATION_RATE,
        HEALTHCARE_ACCESS,
        DOCTOR_PER_1000,
        HOSPITAL_BEDS_PER_1000
    FROM temp_global_health;

    -- Obtener número de filas afectadas
    v_filas_afectadas := SQL%ROWCOUNT;

    -- Insertar en la tabla de control
    INSERT INTO procesos_carga_control (
        nombre_tabla,
        filas_afectadas,
        operacion,
        fecha_proceso,
        usuario_proceso
    )
    VALUES (
        'Countries_stats',
        v_filas_afectadas,
        'INSERT',
        SYSDATE,
        v_usuario
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;

-- 4. Procedimiento de carga para DISEASE_TREATMENT
create or replace PROCEDURE cargar_tabla_disease_treatment IS
    v_filas_afectadas NUMBER;
    v_usuario         VARCHAR2(50);
BEGIN
    -- No limpiar la tabla de control para mantener histórico

    -- Borrar datos anteriores de la tabla destino
    DELETE FROM disease_treatment;

    -- Obtener usuario actual
    SELECT USER INTO v_usuario FROM dual;

    -- Insertar con IDs generados desde secuencia
    FOR reg IN (
        SELECT
            treatment_type,
            ROUND(AVG(avg_treatment_cost), 2) AS avg_treatment_cost,
            CASE 
                WHEN LOWER(treatment_type) = 'vaccination' THEN
                    CASE 
                        WHEN MAX(LOWER(TRIM(vacciness_disponibility))) = 'yes' THEN 'Y'
                        ELSE 'N'
                    END
                ELSE NULL
            END AS vacciness_disponibility
        FROM temp_global_health
        WHERE treatment_type IS NOT NULL
        GROUP BY treatment_type
    ) LOOP
        INSERT INTO disease_treatment (
            disease_t_id,
            treatment_type,
            avg_treatment_cost,
            vacciness_disponibility
        )
        VALUES (
            seq_disease_treatment_id.NEXTVAL,
            reg.treatment_type,
            reg.avg_treatment_cost,
            reg.vacciness_disponibility
        );

        v_filas_afectadas := NVL(v_filas_afectadas, 0) + 1;
    END LOOP;

    -- Registrar en la tabla de control
    INSERT INTO procesos_carga_control (
        nombre_tabla,
        filas_afectadas,
        operacion,
        fecha_proceso,
        usuario_proceso
    )
    VALUES (
        'DISEASE_TREATMENT',
        v_filas_afectadas,
        'INSERT',
        SYSDATE,
        v_usuario
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;


--5.Procedimiento de cargar para Disease_category
create or replace PROCEDURE cargar_tabla_disease_category IS
    v_filas_afectadas NUMBER := 0;
    v_usuario         VARCHAR2(50);
BEGIN
    -- Borrar datos anteriores de la tabla destino
    DELETE FROM disease_category;

    -- Obtener el usuario actual
    SELECT USER INTO v_usuario FROM dual;

    -- Insertar valores únicos desde la tabla temporal
    FOR reg IN (
        SELECT DISTINCT TRIM(disease_category_name) AS disease_category_name
        FROM temp_global_health
        WHERE disease_category_name IS NOT NULL
    ) LOOP
        INSERT INTO disease_category (
            disease_category_id,
            disease_category_name
        )
        VALUES (
            seq_disease_category_id.NEXTVAL,
            reg.disease_category_name
        );

        v_filas_afectadas := v_filas_afectadas + 1;
    END LOOP;

    -- Registrar en la tabla de control
    INSERT INTO procesos_carga_control (
        nombre_tabla,
        filas_afectadas,
        operacion,
        fecha_proceso,
        usuario_proceso
    ) VALUES (
        'DISEASE_CATEGORY',
        v_filas_afectadas,
        'INSERT',
        SYSDATE,
        v_usuario
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;


-- 6. Procedimiento de carga para DISEASE
create or replace PROCEDURE cargar_tabla_disease IS
    v_filas_afectadas NUMBER := 0;
    v_usuario         VARCHAR2(50);
BEGIN
    -- Limpiar datos anteriores
    DELETE FROM disease;

    -- Obtener usuario actual
    SELECT USER INTO v_usuario FROM dual;

    -- Insertar enfermedades únicas con los IDs correctos
    FOR reg IN (
        SELECT DISTINCT 
            gh.disease_name,
            dc.disease_category_id,
            dt.disease_t_id
        FROM temp_global_health gh
        JOIN disease_category dc
            ON LOWER(TRIM(gh.disease_category_name)) = LOWER(TRIM(dc.disease_category_name))
        JOIN disease_treatment dt
            ON LOWER(TRIM(gh.treatment_type)) = LOWER(TRIM(dt.treatment_type))
        WHERE gh.disease_name IS NOT NULL
    ) LOOP
        INSERT INTO disease (
            disease_id,
            disease_category_id,
            disease_t_id,
            disease_name
        )
        VALUES (
            seq_disease_id.NEXTVAL,
            reg.disease_category_id,
            reg.disease_t_id,
            reg.disease_name
        );

        v_filas_afectadas := v_filas_afectadas + 1;
    END LOOP;

    -- Registrar en tabla de control
    INSERT INTO procesos_carga_control (
        nombre_tabla,
        filas_afectadas,
        operacion,
        fecha_proceso,
        usuario_proceso
    ) VALUES (
        'DISEASE',
        v_filas_afectadas,
        'INSERT',
        SYSDATE,
        v_usuario
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;

-- 7. Procedimiento de carga para HEALTH_STATS (ESTA MAL)
create or replace PROCEDURE cargar_tabla_health_stats IS
    v_filas_afectadas NUMBER := 0;
    v_usuario         VARCHAR2(50);
BEGIN
    -- Limpiar datos anteriores
    DELETE FROM health_stats;

    -- Obtener usuario actual
    SELECT USER INTO v_usuario FROM dual;

    -- Insertar datos en health_stats desde temp_global_health
    FOR reg IN (
        SELECT 
            gh.age_group,
            gh.gender,
            gh.prevalence_rate,
            gh.mortality_rate,
            gh.incidence_rate,
            gh.population_affected,
            gh.recovery_rate,
            gh.dalys,
            gh.five_year_improvement,
            cs.countries_stats_id,
            d.disease_id
        FROM temp_global_health gh
        JOIN countries_stats cs
            ON LOWER(TRIM(gh.country_name)) = LOWER(TRIM(cs.country_name))
           AND gh.year = cs.year
        JOIN disease d
            ON LOWER(TRIM(gh.disease_name)) = LOWER(TRIM(d.disease_name))
        WHERE gh.disease_name IS NOT NULL
          AND gh.country_name IS NOT NULL
          AND gh.year IS NOT NULL
    ) LOOP
        INSERT INTO health_stats (
            health_stats_id,
            age_group,
            gender,
            prevalence_rate,
            mortality_rate,
            incidence_rate,
            population_affected,
            recovery_rate,
            dalys,
            five_year_improvement,
            countries_stats_id,
            disease_id
        ) VALUES (
            seq_health_stats_id.NEXTVAL,
            reg.age_group,
            reg.gender,
            reg.prevalence_rate,
            reg.mortality_rate,
            reg.incidence_rate,
            reg.population_affected,
            reg.recovery_rate,
            reg.dalys,
            reg.five_year_improvement,
            reg.countries_stats_id,
            reg.disease_id
        );

        v_filas_afectadas := v_filas_afectadas + 1;
    END LOOP;

    -- Registrar en tabla de control
    INSERT INTO procesos_carga_control (
        nombre_tabla,
        filas_afectadas,
        operacion,
        fecha_proceso,
        usuario_proceso
    ) VALUES (
        'HEALTH_STATS',
        v_filas_afectadas,
        'INSERT',
        SYSDATE,
        v_usuario
    );

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;

-- 8. Procedimiento de limpieza general (truncate)
CREATE OR REPLACE PROCEDURE purge_all_data IS
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE HEALTH_STATS';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE COUNTRIES_STATS';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE DISEASE';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE DISEASE_TREATMENT';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE DISEASE_CATEGORY';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE LOAD_CONTROL';
  COMMIT;
END purge_all_data;
/