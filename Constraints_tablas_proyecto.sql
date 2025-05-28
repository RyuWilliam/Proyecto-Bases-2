--Constraints tabla countries_stats

--Clave primaria
ALTER TABLE COUNTRIES_STATS
ADD CONSTRAINT pk_countries_stats
PRIMARY KEY (countries_stats_id)
USING INDEX
  TABLESPACE ts_indices;
  
--Constraints tabla Disease_category

-- Clave primaria
ALTER TABLE DISEASE_CATEGORY
ADD CONSTRAINT pk_disease_category
PRIMARY KEY (disease_category_id)
USING INDEX TABLESPACE ts_indices;

--Nombre único para la categoría
ALTER TABLE DISEASE_CATEGORY
ADD CONSTRAINT uq_disease_category_name
UNIQUE (disease_category_name)
USING INDEX TABLESPACE ts_indices;

--Constraints tabla Disease_treatment

-- Clave primaria
ALTER TABLE DISEASE_TREATMENT
ADD CONSTRAINT pk_disease_treatment
PRIMARY KEY (disease_T_id)
USING INDEX TABLESPACE ts_indices;

-- CHECK para validar 'Y' o 'N' como valores válidos
ALTER TABLE DISEASE_TREATMENT
ADD CONSTRAINT chk_vaccines_disp
CHECK (vacciness_disponibility IN ('Y', 'N'));


--Contraints tabla Disease

-- Clave primaria
ALTER TABLE DISEASE
ADD CONSTRAINT pk_disease
PRIMARY KEY (disease_id)
USING INDEX TABLESPACE ts_indices;

-- Clave foránea a tabla de categorías
ALTER TABLE DISEASE
ADD CONSTRAINT fk_disease_category
FOREIGN KEY (disease_category_id)
REFERENCES DISEASE_CATEGORY (disease_category_id);

-- Clave foránea a tratamientos
ALTER TABLE DISEASE
ADD CONSTRAINT fk_disease_treatment
FOREIGN KEY (disease_T_id)
REFERENCES DISEASE_TREATMENT (disease_T_id);

--Constraints health_stats

-- Clave primaria
ALTER TABLE HEALTH_STATS
ADD CONSTRAINT pk_health_stats
PRIMARY KEY (health_stats_id)
USING INDEX TABLESPACE ts_indices;

-- Agregar CHECK constraint para gender
ALTER TABLE HEALTH_STATS
ADD CONSTRAINT chk_gender
CHECK (gender IN ('Male', 'Female', 'Other'));

-- Clave foránea a COUNTRIES_STATS
ALTER TABLE HEALTH_STATS
ADD CONSTRAINT fk_health_countries
FOREIGN KEY (countries_stats_id)
REFERENCES COUNTRIES_STATS (countries_stats_id);

-- Clave foránea a DISEASES 
ALTER TABLE HEALTH_STATS
ADD CONSTRAINT fk_health_disease
FOREIGN KEY (disease_id)
REFERENCES DISEASES (disease_id);
