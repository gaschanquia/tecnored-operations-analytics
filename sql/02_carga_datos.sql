
-- ============================================================
-- TECNORED OPERATIONS ANALYTICS
-- 02_carga_datos.sql
--
-- Importación de los cinco archivos CSV a las tablas creadas
-- previamente en 01_creacion.sql.
--
-- IMPORTANTE:
-- Ejecutar con las tablas vacías.
-- Este script no elimina ni reemplaza registros existentes.
-- No debe ejecutarse nuevamente sobre datos ya cargados,
-- porque produciría conflictos por claves primarias duplicadas.
--
-- Requiere habilitar LOAD DATA LOCAL INFILE en MySQL.
-- Las rutas de los CSV deben adaptarse al equipo donde se ejecute.
--
-- Ejemplo desde la terminal del sistema:
-- mysql --local-infile=1 -u root -p < sql/02_carga_datos.sql
-- ============================================================

USE tecnored_operations;


-- ============================================================
-- 1. CARGA DE TABLAS MAESTRAS
-- ============================================================

-- SUCURSALES

LOAD DATA LOCAL INFILE '/Users/gastonchanquia/proy_data/tecnored_operations_analytics/data/sucursales.csv'
INTO TABLE sucursales
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


-- CLIENTES

LOAD DATA LOCAL INFILE '/Users/gastonchanquia/proy_data/tecnored_operations_analytics/data/clientes.csv'
INTO TABLE clientes
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


-- PRODUCTOS

LOAD DATA LOCAL INFILE '/Users/gastonchanquia/proy_data/tecnored_operations_analytics/data/productos.csv'
INTO TABLE productos
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


-- ============================================================
-- 2. CARGA DE TABLAS TRANSACCIONALES
-- ============================================================

-- VENTAS

LOAD DATA LOCAL INFILE '/Users/gastonchanquia/proy_data/tecnored_operations_analytics/data/ventas.csv'
INTO TABLE ventas
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


-- DEVOLUCIONES

LOAD DATA LOCAL INFILE '/Users/gastonchanquia/proy_data/tecnored_operations_analytics/data/devoluciones.csv'
INTO TABLE devoluciones
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 LINES;


-- ============================================================
-- 3. COMPROBACIÓN DE LA CARGA
-- ============================================================

SELECT 'clientes' AS tabla, COUNT(*) AS registros FROM clientes

UNION ALL
SELECT 'productos', COUNT(*) FROM productos

UNION ALL
SELECT 'sucursales', COUNT(*) FROM sucursales

UNION ALL
SELECT 'ventas', COUNT(*) FROM ventas

UNION ALL
SELECT 'devoluciones', COUNT(*) FROM devoluciones;


-- RESULTADO ESPERADO:
--
-- clientes       1200
-- productos       120
-- sucursales        8
-- ventas         6000
-- devoluciones    320
--
-- Total: 7648 registros.
