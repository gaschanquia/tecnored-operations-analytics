
-- ============================================================
-- TECNORED OPERATIONS ANALYTICS
-- 03_validacion_limpieza.sql
--
-- Objetivo:
-- Evaluar la calidad de los datos cargados en MySQL,
-- identificar inconsistencias y aplicar correcciones puntuales.
--
-- Incluye consultas de diagnóstico, normalizaciones y
-- comprobaciones posteriores.
--
-- No elimina registros.
--
-- IMPORTANTE:
-- Ejecutar después de 02_carga_datos.sql y antes de las
-- consultas de negocio.
-- ============================================================

USE tecnored_operations;


-- ============================================================
-- BLOQUE 1. PERFILADO INICIAL
-- ============================================================

-- 1. VOLUMEN DE REGISTROS POR TABLA

SELECT 'clientes' AS tabla, COUNT(*) AS registros FROM clientes
UNION ALL
SELECT 'productos', COUNT(*) FROM productos
UNION ALL
SELECT 'sucursales', COUNT(*) FROM sucursales
UNION ALL
SELECT 'ventas', COUNT(*) FROM ventas
UNION ALL
SELECT 'devoluciones', COUNT(*) FROM devoluciones;

-- Resultado esperado:
-- 1200 clientes, 120 productos, 8 sucursales,
-- 6000 ventas y 320 devoluciones.


-- 2. DISTRIBUCIÓN DE VENTAS POR ESTADO

SELECT
    estado,
    COUNT(*) AS cantidad_ventas
FROM ventas
GROUP BY estado
ORDER BY cantidad_ventas DESC;

-- RESULTADO:
-- confirmada: 5623
-- cancelada:   253
-- pendiente:   124


-- 3. DISTRIBUCIÓN DE DEVOLUCIONES POR ESTADO

SELECT
    estado,
    COUNT(*) AS cantidad_devoluciones
FROM devoluciones
GROUP BY estado
ORDER BY cantidad_devoluciones DESC;

-- RESULTADO:
-- reintegrada: 266
-- en_revision:  32
-- rechazada:    22


-- 4. PERÍODO DE OPERACIONES

SELECT
    MIN(fecha) AS primera_venta,
    MAX(fecha) AS ultima_venta
FROM ventas;

SELECT
    MIN(fecha_devolucion) AS primera_devolucion,
    MAX(fecha_devolucion) AS ultima_devolucion
FROM devoluciones;

-- RESULTADO:
-- Ventas:       2024-01-01 a 2026-08-31.
-- Devoluciones: 2024-01-10 a 2026-09-19.


-- ============================================================
-- BLOQUE 2. CONTROL DE CLIENTES
-- ============================================================

-- 5. CONTROL DE POSIBLES CLIENTES DUPLICADOS
--
-- Criterio exploratorio:
-- coincidencia de nombre, apellido y fecha de nacimiento.
-- No constituye una identificación definitiva de duplicados.

SELECT
    nombre,
    apellido,
    fecha_nacimiento,
    COUNT(*) AS cantidad
FROM clientes
GROUP BY
    nombre,
    apellido,
    fecha_nacimiento
HAVING COUNT(*) > 1
ORDER BY cantidad DESC;

-- RESULTADO:
-- 0 posibles duplicados según el criterio utilizado.


-- 6. CONTROL DE EDAD ACTUAL

SELECT
    COUNT(*) AS clientes_menores_18
FROM clientes
WHERE TIMESTAMPDIFF(
    YEAR,
    fecha_nacimiento,
    CURDATE()
) < 18;

-- RESULTADO:
-- Se detectaron 483 registros.
--
-- Este resultado requiere contrastar las fechas de nacimiento
-- y alta antes de interpretar las edades como válidas.


-- 7. CONTROL DE EDAD AL MOMENTO DEL ALTA

SELECT
    COUNT(*) AS clientes_menores_al_alta
FROM clientes
WHERE TIMESTAMPDIFF(
    YEAR,
    fecha_nacimiento,
    fecha_alta
) < 18;

-- RESULTADO:
-- 483 registros.
--
-- Se realiza un control adicional para determinar si las
-- fechas son cronológicamente coherentes.


-- 8. CONTROL CRUZADO DE FECHAS

SELECT
    COUNT(*) AS total_clientes,

    SUM(
        fecha_alta < fecha_nacimiento
    ) AS altas_antes_nacimiento,

    SUM(
        fecha_alta >= fecha_nacimiento
        AND TIMESTAMPDIFF(
            YEAR,
            fecha_nacimiento,
            fecha_alta
        ) < 18
    ) AS menores_con_fechas_coherentes

FROM clientes;

-- RESULTADO:
-- Total de clientes: 1200.
-- Altas anteriores al nacimiento: 483.
-- Menores con fechas cronológicamente coherentes: 0.
--
-- HALLAZGO:
-- El 40,25% de los registros presenta una fecha de alta
-- anterior a la fecha de nacimiento.
--
-- ACCIÓN:
-- Se conservan los registros originales.
-- No se modifican fechas sin una fuente válida de referencia.
-- La inconsistencia queda documentada para revisión.


-- 9. CONTROL GENERAL DE DATOS FALTANTES

SELECT
    COUNT(*) AS total_clientes,

    SUM(
        nombre IS NULL OR TRIM(nombre) = ''
    ) AS nombres_faltantes,

    SUM(
        apellido IS NULL OR TRIM(apellido) = ''
    ) AS apellidos_faltantes,

    SUM(
        email IS NULL OR TRIM(email) = ''
    ) AS emails_faltantes,

    SUM(
        region IS NULL OR TRIM(region) = ''
    ) AS regiones_faltantes

FROM clientes;

-- RESULTADO:
-- 1200 clientes.
-- 2 nombres faltantes.
-- 0 apellidos faltantes.
-- 2 emails faltantes.
-- 0 regiones faltantes.


-- 10. IDENTIFICACIÓN DE CLIENTES CON DATOS FALTANTES

SELECT
    cliente_id,
    nombre,
    apellido,
    email,
    region
FROM clientes
WHERE nombre IS NULL
   OR TRIM(nombre) = ''
   OR email IS NULL
   OR TRIM(email) = '';

-- RESULTADO:
-- 4 clientes con datos faltantes.


-- 11. NORMALIZACIÓN DE NOMBRES FALTANTES

UPDATE clientes
SET nombre = 'Sin informar'
WHERE nombre IS NULL
   OR TRIM(nombre) = '';

-- RESULTADO:
-- 2 nombres normalizados como 'Sin informar'.
--
-- Los 2 emails faltantes se conservan sin inventar información.


-- ============================================================
-- BLOQUE 3. CONTROL DE PRODUCTOS
-- ============================================================

-- 12. CONTROL GENERAL DE CALIDAD

SELECT
    COUNT(*) AS total_productos,

    SUM(
        categoria IS NULL OR TRIM(categoria) = ''
    ) AS categorias_faltantes,

    SUM(
        subcategoria IS NULL OR TRIM(subcategoria) = ''
    ) AS subcategorias_faltantes,

    SUM(
        costo IS NULL OR costo <= 0
    ) AS costos_invalidos,

    SUM(
        precio_lista IS NULL OR precio_lista <= 0
    ) AS precios_invalidos,

    SUM(
        stock IS NULL OR stock < 0
    ) AS stock_invalido,

    SUM(
        stock_minimo IS NULL OR stock_minimo < 0
    ) AS stock_minimo_invalido

FROM productos;

-- RESULTADO:
-- 120 productos.
-- 1 categoría faltante.
-- 1 subcategoría faltante.
-- 0 valores inválidos en los campos numéricos evaluados.


-- 13. IDENTIFICACIÓN DE PRODUCTOS SIN CLASIFICACIÓN

SELECT
    producto_id,
    nombre_producto,
    categoria,
    subcategoria
FROM productos
WHERE categoria IS NULL
   OR TRIM(categoria) = ''
   OR subcategoria IS NULL
   OR TRIM(subcategoria) = '';

-- RESULTADO:
-- Producto 7039:
-- Gaming Rig RTX 4060 Gris Serie 039.
-- Categoría y subcategoría faltantes.


-- 14. NORMALIZACIÓN DE LA CLASIFICACIÓN

UPDATE productos
SET
    categoria = 'Sin clasificar',
    subcategoria = 'Sin clasificar'
WHERE producto_id = 7039
  AND (categoria IS NULL OR TRIM(categoria) = '')
  AND (subcategoria IS NULL OR TRIM(subcategoria) = '');

-- Se utiliza una categoría explícita para no inventar
-- una clasificación comercial.


-- 15. COMPROBACIÓN DE LA CORRECCIÓN

SELECT
    producto_id,
    nombre_producto,
    categoria,
    subcategoria
FROM productos
WHERE producto_id = 7039;

-- RESULTADO:
-- Categoría:    Sin clasificar.
-- Subcategoría: Sin clasificar.
-- Se conservan los 120 productos originales.


-- ============================================================
-- BLOQUE 4. CONTROL DE VENTAS
-- ============================================================

-- 16. CONTROL GENERAL DE CALIDAD

SELECT
    COUNT(*) AS total_ventas,

    SUM(fecha IS NULL) AS fechas_faltantes,

    SUM(
        cantidad IS NULL OR cantidad <= 0
    ) AS cantidades_invalidas,

    SUM(
        precio_unitario IS NULL OR precio_unitario <= 0
    ) AS precios_invalidos,

    SUM(
        canal IS NULL OR TRIM(canal) = ''
    ) AS canales_faltantes,

    SUM(
        medio_pago IS NULL OR TRIM(medio_pago) = ''
    ) AS medios_pago_faltantes,

    SUM(
        estado IS NULL OR TRIM(estado) = ''
    ) AS estados_faltantes

FROM ventas;

-- RESULTADO:
-- 6000 ventas verificadas.
-- 0 incidencias en los controles realizados.


-- 17. CONTROL DE CATEGORÍAS EN MEDIOS DE PAGO

SELECT
    medio_pago,
    COUNT(*) AS cantidad_ventas
FROM ventas
GROUP BY medio_pago
ORDER BY cantidad_ventas DESC;

-- RESULTADO INICIAL:
-- tarjeta_credito: 2524
-- tarjeta_debito:  1498
-- transferencia:   1192
-- billetera:        773
-- tarjeta credito:    8
-- tarjeta debito:     5
--
-- Se detectaron 13 registros con nomenclatura inconsistente.


-- 18. NORMALIZACIÓN DE MEDIOS DE PAGO

UPDATE ventas
SET medio_pago = 'tarjeta_credito'
WHERE medio_pago = 'tarjeta credito';

UPDATE ventas
SET medio_pago = 'tarjeta_debito'
WHERE medio_pago = 'tarjeta debito';


-- 19. COMPROBACIÓN POSTERIOR

SELECT
    medio_pago,
    COUNT(*) AS cantidad_ventas
FROM ventas
GROUP BY medio_pago
ORDER BY cantidad_ventas DESC;

-- RESULTADO FINAL:
-- tarjeta_credito: 2532
-- tarjeta_debito:  1503
-- transferencia:   1192
-- billetera:        773
--
-- 13 registros normalizados.
-- Se pasó de 6 categorías a 4 categorías válidas.
-- Total de ventas conservado: 6000.


-- ============================================================
-- BLOQUE 5. CONTROL DE SUCURSALES
-- ============================================================

-- 20. CONTROL GENERAL DE CALIDAD

SELECT
    COUNT(*) AS total_sucursales,

    SUM(
        sucursal IS NULL OR TRIM(sucursal) = ''
    ) AS nombres_faltantes,

    SUM(
        ciudad IS NULL OR TRIM(ciudad) = ''
    ) AS ciudades_faltantes,

    SUM(
        provincia IS NULL OR TRIM(provincia) = ''
    ) AS provincias_faltantes,

    SUM(
        region IS NULL OR TRIM(region) = ''
    ) AS regiones_faltantes,

    SUM(
        fecha_alta IS NULL
    ) AS fechas_faltantes

FROM sucursales;

-- RESULTADO:
-- 8 sucursales verificadas.
-- 0 incidencias en los campos evaluados.
-- No requiere correcciones.


-- ============================================================
-- BLOQUE 6. CONTROL DE DEVOLUCIONES
-- ============================================================

-- 21. CONTROL GENERAL DE CALIDAD

SELECT
    COUNT(*) AS total_devoluciones,

    SUM(
        fecha_devolucion IS NULL
    ) AS fechas_faltantes,

    SUM(
        cantidad_devuelta IS NULL OR cantidad_devuelta <= 0
    ) AS cantidades_invalidas,

    SUM(
        motivo IS NULL OR TRIM(motivo) = ''
    ) AS motivos_faltantes,

    SUM(
        estado IS NULL OR TRIM(estado) = ''
    ) AS estados_faltantes,

    SUM(
        importe_reintegrado IS NULL OR importe_reintegrado < 0
    ) AS importes_invalidos

FROM devoluciones;

-- RESULTADO:
-- 320 devoluciones verificadas.
-- 0 incidencias en los campos evaluados.


-- 22. CONTROL DE INTEGRIDAD ENTRE DEVOLUCIONES Y VENTAS
--
-- Se comprueba que cada devolución corresponda a una venta
-- con el mismo cliente, producto y sucursal.
--
-- Las claves foráneas verifican la existencia de referencias,
-- pero no garantizan por sí solas esta coherencia cruzada.

SELECT
    COUNT(*) AS total_devoluciones,

    SUM(
        CASE
            WHEN v.venta_id IS NOT NULL
             AND d.cliente_id <=> v.cliente_id
             AND d.producto_id <=> v.producto_id
             AND d.sucursal_id <=> v.sucursal_id
            THEN 1
            ELSE 0
        END
    ) AS registros_correctos,

    SUM(
        CASE
            WHEN v.venta_id IS NULL
              OR NOT (d.cliente_id <=> v.cliente_id)
              OR NOT (d.producto_id <=> v.producto_id)
              OR NOT (d.sucursal_id <=> v.sucursal_id)
            THEN 1
            ELSE 0
        END
    ) AS registros_con_diferencias

FROM devoluciones d

LEFT JOIN ventas v
    ON d.venta_id = v.venta_id;

-- RESULTADO:
-- 320 devoluciones verificadas.
-- 320 registros correctos.
-- 0 diferencias detectadas.
--
-- Integridad comprobada: 100% para los campos evaluados.


-- ============================================================
-- FIN DE LA ETAPA DE VALIDACIÓN Y LIMPIEZA
-- ============================================================
