﻿-- MCIC-BD-PROYECTO FINAL

-- Christopher Giovanny Ortiz Montero 		Código: 20201495006
-- Joaquín Eduardo Caicedo Navarro		Código: 20201495001
-- Thomas Daniel Ávila Blenkey			Código: 20151020012

--------------------------------------
-- FACULTAD DE CIENCIAS Y EDUCACIÓN --
--------------------------------------

-- En este punto es necesario ubicar las consultas sobre la base de datos "ciencias".

-- Se crean los esquemas de los proyectos curriculares.
CREATE SCHEMA lic_biologia;
CREATE SCHEMA lic_c_sociales;
CREATE SCHEMA lic_fisica;
CREATE SCHEMA lic_matematicas;
CREATE SCHEMA lic_quimica;

-- Se instala la extensión dblink para la conexión con otras bases de datos.
CREATE EXTENSION dblink;

---------------------------------------------------------------
-- CREACIÓN DE TABLAS DE LA FACULTAD DE CIENCIAS Y EDUCACIÓN --
---------------------------------------------------------------
-- Se ubica en el esquema "public" para la creación de las tablas generales de la facultad.
SET search_path TO public;

CREATE TABLE carreras (
	id_carr bigint PRIMARY KEY CHECK (id_carr >= 0),
	nom_carr varchar(70) NOT NULL UNIQUE,
    reg_cal bigint NOT NULL CHECK (reg_cal >= 0) UNIQUE
);

CREATE TABLE asignaturas (
	cod_a bigint PRIMARY KEY CHECK (cod_a >= 0),
	nom_a varchar(70) NOT NULL UNIQUE,
	int_h smallint NOT NULL CHECK (int_h >= 0),
	creditos smallint NOT NULL CHECK (creditos >= 0)
);

CREATE TABLE profesores (
	id_p bigint PRIMARY KEY CHECK (id_p >= 0),
	nom_p varchar(70) NOT NULL,
	dir_p varchar(70) NOT NULL,
	tel_p int NULL CHECK (tel_p >= 0),
	profesion varchar(70) NOT NULL
);

CREATE TABLE imparte (
	id_p bigint REFERENCES profesores (id_p),
	cod_a bigint REFERENCES asignaturas (cod_a),	
	grupo smallint CHECK (grupo >= 0),
    salon smallint NOT NULL CHECK (salon >= 0),
	horario varchar(70) NOT NULL,
	PRIMARY KEY (id_p, cod_a, grupo)
);

CREATE TABLE referencia (
	cod_a bigint REFERENCES asignaturas (cod_a),
	isbn bigint,
	PRIMARY KEY (cod_a, isbn)
);

---------------------------------------------------------------------------
-- Función para crear la tabla "estudiantes" de cada proyecto curricular --
---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION crear_estudiantes(esquema text) RETURNS text AS $$
	DECLARE
		msg_out text DEFAULT 'Tabla estudiantes creada con éxito';
	BEGIN
		EXECUTE 'SET search_path TO ' || esquema;
		CREATE TABLE estudiantes (
			cod_e bigint PRIMARY KEY CHECK (cod_e >= 0),
			nom_e varchar NOT NULL,	
			dir_e varchar NOT NULL,
			tel_e int NULL CHECK (tel_e >= 0),
			fech_nac date NOT NULL CHECK (fech_nac BETWEEN '1900-01-01' AND NOW()),
			id_carr bigint NOT NULL REFERENCES public.carreras (id_carr)
		);
		SET search_path TO public;
		RETURN msg_out;
	END;
	$$ LANGUAGE plpgsql;

---------------------------------------------------------------------------
-- Función para crear la tabla "inscribe" de cada proyecto curricular --
---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION crear_inscribe(esquema varchar) RETURNS text AS $$
	DECLARE
		msg_out text DEFAULT 'Tabla inscribe creada con éxito';
	BEGIN
		EXECUTE 'SET search_path TO ' || esquema;
		CREATE TABLE inscribe (
			cod_e bigint REFERENCES estudiantes (cod_e),
			id_p bigint,
			cod_a bigint,
			grupo smallint,
			n1 numeric(2,1) NULL CHECK (n1 BETWEEN 0 AND 5),
			n2 numeric(2,1) NULL CHECK (n2 BETWEEN 0 AND 5),
			n3 numeric(2,1) NULL CHECK (n3 BETWEEN 0 AND 5),
			PRIMARY KEY (cod_e, id_p, cod_a, grupo),
			FOREIGN KEY (id_p, cod_a, grupo) REFERENCES public.imparte (id_p, cod_a, grupo) ON UPDATE CASCADE ON DELETE CASCADE,
			UNIQUE(cod_e, cod_a)
		);
		SET search_path TO public;
		RETURN msg_out;
	END;
	$$ LANGUAGE plpgsql;


-------------------------------------------
-- Tablas de la licenciatura en biología --
-------------------------------------------
-- Se crean las tablas "estudiantes" e "inscribe" con las funciones creadas.
SELECT * FROM crear_estudiantes('lic_biologia');
SELECT * FROM crear_inscribe('lic_biologia');

----------------------------------------------------
-- Tablas de la licenciatura en ciencias sociales --
----------------------------------------------------
-- Se crean las tablas "estudiantes" e "inscribe" con las funciones creadas.
SELECT * FROM crear_estudiantes('lic_c_sociales');
SELECT * FROM crear_inscribe('lic_c_sociales');

-----------------------------------------
-- Tablas de la licenciatura en física --
-----------------------------------------
-- Se crean las tablas "estudiantes" e "inscribe" con las funciones creadas.
SELECT * FROM crear_estudiantes('lic_fisica');
SELECT * FROM crear_inscribe('lic_fisica');

----------------------------------------------
-- Tablas de la licenciatura en matemáticas --
----------------------------------------------
-- Se crean las tablas "estudiantes" e "inscribe" con las funciones creadas.
SELECT * FROM crear_estudiantes('lic_matematicas');
SELECT * FROM crear_inscribe('lic_matematicas');

------------------------------------------
-- Tablas de la licenciatura en química --
------------------------------------------
-- Se ubica el esquema "lic_quimica".
-- Se crean las tablas "estudiantes" e "inscribe" con las funciones creadas.
SELECT * FROM crear_estudiantes('lic_quimica');
SELECT * FROM crear_inscribe('lic_quimica');

---------------------------------------------------------------

---------------------------------------------------------------
-- CREACIÓN DE VISTAS DE LA FACULTAD DE CIENCIAS Y EDUCACIÓN --
---------------------------------------------------------------

-----------------------
-- Vista Estudiantes --
-----------------------
-- Vista de todos los estudiantes (ciencias y educación).
CREATE VIEW estudiantes_ciencias AS
	SELECT * FROM lic_biologia.estudiantes
	UNION
	SELECT * FROM lic_c_sociales.estudiantes
	UNION
	SELECT * FROM lic_fisica.estudiantes
	UNION
	SELECT * FROM lic_matematicas.estudiantes
	UNION
	SELECT * FROM lic_quimica.estudiantes;

--------------------
-- Vista Inscribe --
--------------------
-- Vista de las materias inscritas por todos los estudiantes (ciencias y educación).
CREATE VIEW inscribe_ciencias AS
	SELECT * FROM lic_biologia.inscribe
	UNION
	SELECT * FROM lic_c_sociales.inscribe
	UNION
	SELECT * FROM lic_fisica.inscribe
	UNION
	SELECT * FROM lic_matematicas.inscribe
	UNION
	SELECT * FROM lic_quimica.inscribe;

-----------------
-- Vista Notas --
-----------------
-- Para que cada estudiante pueda ver sus propias notas
create view notas_ciencias as
	select cod_e, nom_e, id_carr, cod_a, nom_a, grupo, n1, n2, n3, 
	coalesce(n1,0)*.35+coalesce(n2,0)*.35+coalesce(n3,0)*.3 def, 
	case coalesce(n1,0)*.35+coalesce(n2,0)*.35+coalesce(n3,0)*.3>=3 when true then 'aprobado' else 'reprobado' end as concepto
	from inscribe_ciencias natural join estudiantes_ciencias natural join asignaturas
	where cod_e::text = (select current_user) ;
	
------------------------
-- Vista Lista Clases --
------------------------
-- Para que cada profesor pueda ver las clases que tiene asignadas
create view lista_clases_ciencias as
	select id_p, nom_p, cod_a, nom_a, grupo, id_carr, cod_e, nom_e, n1, n2, n3
	from profesores natural join inscribe_ciencias natural join estudiantes_ciencias natural join asignaturas
	where id_p::text = (select current_user) ;

----------------------------------------------------
-- Consulta Coordinador: Profesores de la Carrera --
----------------------------------------------------
-- Para que el coordinador pueda ver la lista de los profesores de la carrera
create view lista_coordinador as
	select id_p, nom_p, cod_a, nom_a, grupo, id_carr, cod_e, nom_e, n1, n2, n3
	from profesores natural join inscribe_ciencias natural join estudiantes_ciencias natural join asignaturas
	where id_carr::text = (select current_user);

-----------------------------------------------------
-- Consulta Coordinador: Referencias de la Carrera --
-----------------------------------------------------
-- Vista con las asignaturas, libros y referencias específicas para la carrera del coordinador
create view referencias_coordinador as
	select distinct cod_a, nom_a, isbn, id_carr from inscribe_ciencias natural join asignaturas 
	natural join referencia natural join estudiantes_ciencias natural join carreras
	where id_carr::text = (select current_user);

------------------------------------------------
-- Consulta Decano: Profesores de la Facultad --
------------------------------------------------
-- Para que el decano pueda ver la lista de los profesores de la facultad
create view lista_profesores as
	select id_p, nom_p, cod_a, nom_a, grupo, id_carr, cod_e, nom_e, n1, n2, n3
	from profesores natural join inscribe_ciencias natural join estudiantes_ciencias natural join asignaturas;

----------------------------------------------------------------
-- Vista para obtener los libros de la facultad de ingenieria --
----------------------------------------------------------------
create view libros as
	select e.* from
	dblink('dbname=fac_ingenieria port=5432 user='||(select current_user)||' password='||(select current_user),
		'select * from public.libros') e (isbn bigint, titulo varchar, edicion smallint, editorial varchar);

-----------------------------------------------------------------
-- Vista para obtener los autores de la facultad de ingenieria --
-----------------------------------------------------------------
create view autores as
	select e.* from
	dblink('dbname=fac_ingenieria port=5432 user='||(select current_user)||' password='||(select current_user),
		'select * from public.autores') e (id_a bigint, nom_autor varchar, nacionalidad varchar);

----------------------------------------------------------------------
-- Vista para obtener la tabla escribe de la facultad de ingenieria --
----------------------------------------------------------------------
create view escribe as
	select e.* from
	dblink('dbname=fac_ingenieria port=5432 user='||(select current_user)||' password='||(select current_user),
		'select * from public.escribe') e (id_a bigint, isbn bigint);

-----------------------------------------------------
-- Vista para obtener los prestamos del estudiante --
-----------------------------------------------------
create view prestamos_estudiante as
	select e.* from
	dblink('dbname=fac_ingenieria port=5432 user='||(select current_user)||' password='||(select current_user),
		'select * from public.prestamos_estudiante')
		e (cod_e bigint, isbn bigint, num_ej integer, fecha_p date, fecha_d date);

-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- CREACIÓN DE USUARIOS Y ACCESOS PARA LA FACULTAD DE CIENCIAS Y EDUCACIÓN --
-----------------------------------------------------------------------------

--------------------------------------------
-- Función para crear los roles genéricos --
---------------------------------------------
CREATE OR REPLACE FUNCTION crear_roles_genericos() RETURNS void AS
	$crear_roles_genericos$
	DECLARE
		codigos RECORD;
	BEGIN
		IF (
			SELECT COUNT(rolname) FROM pg_roles 
			WHERE rolname='estudiante' 
		) = 0
		THEN	
		EXECUTE 'CREATE ROLE estudiante LOGIN';
		END IF;

		IF (
			SELECT count(rolname) FROM pg_roles WHERE rolname='profesor'  
		) = 0
		THEN
		EXECUTE 'CREATE ROLE profesor LOGIN';
		END IF;

		IF (
			SELECT COUNT(rolname) FROM pg_roles WHERE rolname='coordinador'  
		) = 0
		THEN
		EXECUTE 'CREATE ROLE coordinador WITH LOGIN CREATEROLE';
		END IF;
		IF (
			SELECT COUNT(rolname) FROM pg_roles WHERE rolname='bibliotecario'  
		) = 0
		THEN
		EXECUTE 'CREATE USER bibliotecario PASSWORD ''bibliotecario''';	
		END IF;
	END;
	$crear_roles_genericos$ LANGUAGE plpgsql;

-- Se crean los roles de usuario genéricos.
SELECT * FROM crear_roles_genericos();

-----------------------
--Politicas de acceso--
-----------------------
------------------
--Rol Profesores--
------------------
--Politica de acceso profesores (consulta)
CREATE POLICY info_profes_sel ON profesores FOR SELECT TO profesor USING (id_p::varchar = CURRENT_USER);
--Politica de acceso profesores (actualiza)
CREATE POLICY info_profes_upd ON profesores FOR UPDATE TO profesor USING (id_p::varchar = CURRENT_USER);
--Habilito el RLS
ALTER TABLE profesores ENABLE ROW LEVEL SECURITY;
--Concede acceso al profesor en vista/tabla libros
grant select on libros to profesor;
--Concede acceso al profesor en vista/tabla autores
grant select on autores to profesor;
--Concede acceso al profesor en vista/tabla escribe
grant select on escribe to profesor;
--Concede acceso al profesor en vista escribe
grant select on lista_clases_ciencias to profesor;

-------------------
--Rol Coordinador--
-------------------
--Concede acceso al coordinador en vista/tabla libros
grant select on libros to coordinador;
--Concede acceso al coordinador en vista/tabla autores
grant select on autores to coordinador;
--Concede acceso al coordinador en vista/tabla escribe
grant select on escribe to coordinador;


--Concede acceso al coordinador en tabla imparte
grant insert, update, delete on public.imparte to coordinador;
--Concede acceso al coordinador en vista estudiantes_ambiental
grant select on public.estudiantes_ciencias to coordinador;
--Concede acceso al coordinador en vista inscribe_ambiental
grant select on public.inscribe_ciencias to coordinador;
--Concede acceso al coordinador en vista lista_coordinador
grant select on public.lista_coordinador to coordinador;
--Concede acceso al coordinador en tabla referencia (puede actualizar, insertar y borrar, pero sólo las de su carrera. Esto es controlado con triggers)
grant update,insert, delete on public.referencia to coordinador; ----------- CAMBIO, SE QUITÓ EL GRANT ALL
--Concede acceso al coordinador en vista referencias_coordinador (ver las referencias sólo de su carrera)
grant select on public.referencias_coordinador to coordinador;

-------------------
--Rol Estudiantes--
-------------------
--Concede acceso al estudiante en vista notas
GRANT SELECT ON notas_ciencias TO estudiante;
--Concede acceso al estudiante en vista/tabla libros
grant select on libros to estudiante;
--Concede acceso al estudiante en vista/tabla autores
grant select on autores to estudiante;
--Concede acceso al estudiante en vista/tabla escribe
grant select on escribe to estudiante;
--Concede acceso al estudiante en vista prestamos_estudiante
grant select on prestamos_estudiante to estudiante;

---------------------
--Rol Bibliotecario--
---------------------
--Concede acceso al estudiante en vista/tabla libros
grant select on libros to bibliotecario;
--Concede acceso al estudiante en vista/tabla autores
grant select on autores to bibliotecario;
--Concede acceso al estudiante en vista/tabla escribe
grant select on escribe to bibliotecario;

-----------------------------------------------
-- Trigger para crear roles de coordinadores --
-----------------------------------------------

CREATE OR REPLACE FUNCTION crear_rol_coordinador() RETURNS TRIGGER AS
	$crear_rol_coordinador$
	DECLARE
		proyecto text;
	BEGIN
		EXECUTE 'CREATE USER "' || NEW.id_carr::varchar || '" WITH CREATEROLE PASSWORD ''' || NEW.id_carr::varchar || '''';
		EXECUTE 'GRANT coordinador TO "' || NEW.id_carr::varchar  || '"';

		IF (lower(NEW.nom_carr) like '%biologia%') THEN
			proyecto := 'lic_biologia';
		ELSIF (lower(NEW.nom_carr) like '%sociales%') THEN
			proyecto := 'lic_c_sociales';
		ELSIF (lower(NEW.nom_carr) like '%fisica%') THEN
			proyecto := 'lic_fisica';
		ELSIF (lower(NEW.nom_carr) like '%matematicas%') THEN
			proyecto := 'lic_matematicas';
		ELSIF (lower(NEW.nom_carr) like '%quimica%') THEN
			proyecto := 'lic_quimica';
		END IF;	
		EXECUTE 'GRANT USAGE ON SCHEMA '||proyecto||' to "'||NEW.id_carr::varchar||'"';
		EXECUTE 'GRANT SELECT, INSERT, DELETE, UPDATE ON '||proyecto||'.estudiantes TO "'||NEW.id_carr::varchar||'"';
		EXECUTE 'GRANT SELECT, UPDATE, DELETE ON '||proyecto||'.inscribe TO "'||NEW.id_carr::varchar||'"';
		RETURN NULL;
	END;
	$crear_rol_coordinador$ LANGUAGE plpgsql;

CREATE TRIGGER crear_rol_coordinador AFTER INSERT
	ON carreras FOR EACH ROW EXECUTE PROCEDURE crear_rol_coordinador();

--------------------------------------------
-- Trigger para crear roles de profesores --
--------------------------------------------

CREATE OR REPLACE FUNCTION crear_rol_profesor() RETURNS TRIGGER AS
	$crear_rol_profesor$
	BEGIN
		EXECUTE 'CREATE USER "' || NEW.id_p::varchar || '" PASSWORD ''' || NEW.id_p::varchar || '''';
		EXECUTE 'GRANT profesor TO "' || NEW.id_p::varchar  || '"';
		RETURN NULL;
	END;
	$crear_rol_profesor$ LANGUAGE plpgsql;

CREATE TRIGGER crear_rol_profesor AFTER INSERT
	ON profesores FOR EACH ROW EXECUTE PROCEDURE crear_rol_profesor();
	
---------------------------------------------
-- Trigger para crear roles de estudiantes --
---------------------------------------------

CREATE OR REPLACE FUNCTION crear_rol_estudiante() RETURNS TRIGGER AS
	$crear_rol_estudiante$
	BEGIN
		EXECUTE 'CREATE USER "' || NEW.cod_e::varchar || '" PASSWORD ''' || NEW.cod_e::varchar || '''';
		EXECUTE 'GRANT estudiante TO "' || NEW.cod_e::varchar  || '"';
		RETURN NULL;
	END;
	$crear_rol_estudiante$ LANGUAGE plpgsql;

CREATE TRIGGER crear_rol_estudiante AFTER INSERT
	ON lic_biologia.estudiantes FOR EACH ROW EXECUTE PROCEDURE crear_rol_estudiante();
	
CREATE TRIGGER crear_rol_estudiante AFTER INSERT
	ON lic_c_sociales.estudiantes FOR EACH ROW EXECUTE PROCEDURE crear_rol_estudiante();
	
CREATE TRIGGER crear_rol_estudiante AFTER INSERT
	ON lic_fisica.estudiantes FOR EACH ROW EXECUTE PROCEDURE crear_rol_estudiante();
	
CREATE TRIGGER crear_rol_estudiante AFTER INSERT
	ON lic_matematicas.estudiantes FOR EACH ROW EXECUTE PROCEDURE crear_rol_estudiante();
	
CREATE TRIGGER crear_rol_estudiante AFTER INSERT
	ON lic_quimica.estudiantes FOR EACH ROW EXECUTE PROCEDURE crear_rol_estudiante();

-------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
-- CREACIÓN DE PROCEDIMIENTOS ALMACENADOS PARA LA FACULTAD DE CIENCIAS Y EDUCACIÓN --
-------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Función para registrar préstamos de libros desde facultades diferentes a ingeniería --
-----------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION registrar_prestamo (
	IN codigo bigint, IN ejemplar int, IN cod_libro bigint, IN fecha_p varchar) 
	RETURNS text AS $$
	BEGIN
		RETURN (
			SELECT e.* FROM
				dblink('dbname=fac_ingenieria port=5432 user='||(select current_user)||' password='||(select current_user), 
					   'INSERT INTO presta VALUES (' || codigo || ',' || ejemplar || ',' 
					   || cod_libro || ',''' || fecha_p || ''', NULL)') e(salida text)
		);
	END; $$
	LANGUAGE plpgsql;

--------------------------------------------------------------------------------------------
-- Función para registrar devoluciones de libros desde facultades diferentes a ingeniería --
--------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION registrar_devolucion (
	IN codigo bigint, IN ejemplar int, IN cod_libro bigint, IN fecha_p varchar, IN fecha_d varchar) 
	RETURNS text AS $$
	BEGIN
		RETURN (
			SELECT e.* FROM
			dblink('dbname=fac_ingenieria port=5432 user='||(select current_user)||' password='||(select current_user), 
				   'UPDATE presta SET fech_d = ''' || fecha_d || 
				   ''' WHERE cod_e = ' || codigo || ' AND num_ej = ' || ejemplar || ' AND isbn = ' ||
				   cod_libro || ' AND fech_p = ''' || fecha_p || '''')  e(salida text)
		);
	END; $$
	LANGUAGE plpgsql;

--------------------------------------------------------------------------
-- Función para agregar libros desde facultades diferentes a ingeniería --
--------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION agregar_libro (
	IN cod_libro bigint, IN titul varchar, IN edic int, IN edit varchar) 
	RETURNS text AS $$
	BEGIN
		RETURN (
			SELECT e.* FROM
				dblink('dbname=fac_ingenieria port=5432 user='||(select current_user)||' password='||(select current_user),
					   'INSERT INTO libros VALUES (' || cod_libro || ',''' || titul 
					   || ''',' || edic || ',''' || edit || ''')') e(salida text)
		);
	END; $$
	LANGUAGE plpgsql;

---------------------------------------------------------------------------
-- Función para agregar autores desde facultades diferentes a ingeniería --
---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION agregar_autor (
	IN id_aut bigint, IN nom_aut varchar, IN nacion varchar) 
	RETURNS text AS $$
	BEGIN
		RETURN (
			SELECT e.* FROM
				dblink('dbname=fac_ingenieria port=5432 user='||(select current_user)||' password='||(select current_user), 
					   'INSERT INTO autores VALUES (' || id_aut || ',''' || nom_aut 
					   || ''',''' || nacion || ''')') e(salida text)
		);
	END; $$
	LANGUAGE plpgsql;

---------------------------------------------------------------------------------------------------------------
-- Función para agregar "escribe" (relación entre autores y libros) desde facultades diferentes a ingeniería --
---------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION agregar_escribe (
	IN id_aut bigint, IN cod_libro bigint) 
	RETURNS text AS $$
	BEGIN
		RETURN (
			SELECT e.* FROM
				dblink('dbname=fac_ingenieria port=5432 user='||(select current_user)||' password='||(select current_user),
					   'INSERT INTO escribe VALUES (' || id_aut || ',' || cod_libro || ')') e(salida text)
		);
	END; $$
	LANGUAGE plpgsql;
	
------------------------------------------------------------
-- Coordinador: Trigger para administrar la tabla imparte --
------------------------------------------------------------

--COORDINADOR: Administra la información de las asignaturas que imparten los profesores y los grupos
-- Verifica que el registro a modificar/borrar sea parte de la carrera del coordinador
CREATE OR REPLACE FUNCTION actualizar_imparte_coordinador ()
	RETURNS TRIGGER AS $actualizar_imparte_coordinador$
	BEGIN
		IF (	
			select count(id_p) from public.lista_coordinador 
			where id_p = old.id_p
			and cod_a = old.cod_a
			and grupo = old.grupo
		) <> 0 
		THEN
			IF TG_OP = 'UPDATE' THEN
				RETURN NEW;
			ELSIF TG_OP = 'DELETE' THEN
				RETURN OLD;
			END IF;
		ELSE
			RETURN NULL;
		END IF;
	END;
	$actualizar_imparte_coordinador$ LANGUAGE plpgsql;

CREATE TRIGGER actualizar_imparte_coordinador BEFORE UPDATE OR DELETE
	ON public.imparte FOR EACH ROW
	EXECUTE PROCEDURE actualizar_imparte_coordinador();

-----------------------------------------------------------
-- Coordinador: Trigger para administrar las referencias --
-----------------------------------------------------------
-- Verifica que el registro a modificar/borrar sea parte de referencias de las asignaturas del coordinador
CREATE OR REPLACE FUNCTION actualizar_referencias_coordinador ()
	RETURNS TRIGGER AS $actualizar_referencias_coordinador$
	BEGIN
		IF (	
			select count(*) from public.referencias_coordinador 
			where cod_a = old.cod_a
			and isbn = old.isbn
		) <> 0 
		THEN
			IF TG_OP = 'UPDATE' THEN
				IF ( SELECT count(isbn) FROM libros WHERE isbn = NEW.isbn ) <> 0
				THEN
					RETURN NEW;
				ELSE
					RETURN NULL;
				END IF;
			ELSIF TG_OP = 'DELETE' THEN
				RETURN OLD;
			END IF;
		ELSE
			RETURN NULL;
		END IF;
	END;
	$actualizar_referencias_coordinador$ LANGUAGE plpgsql;

CREATE TRIGGER actualizar_referencias_coordinador BEFORE UPDATE OR DELETE
	ON public.referencia FOR EACH ROW
	EXECUTE PROCEDURE actualizar_referencias_coordinador();


----------------------------------------------
-- Trigger Verificar Ingreso de Referencia  --
----------------------------------------------

-- Trigger ejecutado cuando se ingresa una referencia, para verificar que el libro exista
CREATE OR REPLACE FUNCTION trigger_ingresar_referencia ()
	RETURNS TRIGGER AS $trigger_ingresar_referencia$
	BEGIN
		IF ( SELECT count(isbn) FROM libros WHERE isbn = NEW.isbn ) <> 0
			THEN
				RETURN NEW;
			ELSE
				RETURN NULL;
		END IF;

	END;
	$trigger_ingresar_referencia$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ingresar_referencia BEFORE INSERT
	ON public.referencia FOR EACH ROW
	EXECUTE PROCEDURE trigger_ingresar_referencia();


-----------------------------------------------
-- PRIVILEGIOS EN PROCEDIMIENTOS ALMACENADOS --
-----------------------------------------------

-------------------
-- BIBLIOTECARIO --
-------------------

grant execute on function registrar_prestamo(bigint, int, bigint, varchar) to bibliotecario;
grant execute on function registrar_devolucion(bigint, int, bigint, varchar, varchar) to bibliotecario;
grant execute on function agregar_libro(bigint,varchar,int,varchar) to bibliotecario;
grant execute on function agregar_autor(bigint,varchar,varchar) to bibliotecario;
grant execute on function agregar_escribe(bigint, bigint) to bibliotecario;

-----------------
-- COORDINADOR --
-----------------
grant execute on function agregar_libro(bigint,varchar,int,varchar) to coordinador;
grant execute on function agregar_autor(bigint,varchar,varchar) to coordinador;
grant execute on function agregar_escribe(bigint, bigint) to coordinador;

---------------------------------------------------------------------------------------------------------------