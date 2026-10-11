-- ============================================================
-- TECNORED OPERATIONS ANALYTICS
-- 04_consultas_negocio.sql
--
-- Objetivo:
-- Responder preguntas comerciales mediante SQL,
-- complementando el análisis desarrollado en Excel.
--
-- Nivel: SQL básico e intermedio inicial.
-- Las consultas no modifican los datos.
--
-- Ejecutar después de 03_validacion_limpieza.sql.
-- ============================================================
USE tecnored_operations;
-- ============================================================

-- BLOQUE 1. EVOLUCIÓN COMERCIAL
-- ============================================================

-- 1.1 ¿CÓMO EVOLUCIONA LA FACTURACIÓN MES A MES?
--
-- Se consideran únicamente las ventas confirmadas.
-- Se utiliza LAG() para comparar cada mes con el anterior.

WITH facturacion_mensual AS (
    SELECT
        DATE_FORMAT(fecha, '%Y-%m') AS mes,
        ROUND(SUM(cantidad * precio_unitario), 2) AS facturacion
    FROM ventas
    WHERE estado = 'confirmada'
    GROUP BY DATE_FORMAT(fecha, '%Y-%m')
),
comparativa AS (
    SELECT
        mes,
        facturacion,
        LAG(facturacion) OVER (
            ORDER BY mes
        ) AS facturacion_mes_anterior
    FROM facturacion_mensual
)

SELECT
    mes,
    facturacion,
    facturacion_mes_anterior,
    ROUND(
        (facturacion - facturacion_mes_anterior)
        / NULLIF(facturacion_mes_anterior, 0) * 100,
        2
    ) AS variacion_porcentual
FROM comparativa
ORDER BY mes;

-- HALLAZGOS:
-- Se analizaron 32 meses de facturación efectiva:
-- desde enero de 2024 hasta agosto de 2026.
--
-- Mayor crecimiento mensual:
-- Abril de 2024: +48,14%.
--
-- Mayor caída mensual:
-- Julio de 2026: -25,39%.
--
-- Agosto de 2026 presentó una recuperación del +29,39%.
--

-- INTERPRETACIÓN:
-- La facturación presenta fluctuaciones mensuales relevantes.
-- Se recomienda investigar posibles factores comerciales,
-- como estacionalidad, promociones o disponibilidad de stock.
--
-- Los datos disponibles no permiten confirmar esas causas.
-- ============================================================

-- BLOQUE 2. COMPORTAMIENTO DE CLIENTES
-- ============================================================

-- 2.1 ¿QUÉ CLIENTES NO REGISTRARON COMPRAS CONFIRMADAS?
--
-- Se utiliza LEFT JOIN para incluir también a los clientes
-- que no tienen operaciones registradas.

SELECT
    c.cliente_id,
    c.nombre,
    c.apellido,
    c.region,
    COUNT(v.venta_id) AS compras_confirmadas
FROM clientes c
LEFT JOIN ventas v
    ON c.cliente_id = v.cliente_id
    AND v.estado = 'confirmada'
GROUP BY
    c.cliente_id,
    c.nombre,
    c.apellido,
    c.region
HAVING COUNT(v.venta_id) = 0
ORDER BY c.cliente_id;

-- HALLAZGOS:
-- Se identificaron 16 clientes sin compras confirmadas.
-- Representan el 1,33% de los 1200 clientes registrados.
--

-- INTERPRETACIÓN:
-- Constituyen un segmento potencial para acciones de activación.
-- Antes de definir una campaña, conviene revisar si registraron
-- operaciones pendientes o canceladas.
-- ------------------------------------------------------------

-- 2.2 ¿CUÁL ES LA SITUACIÓN DE ESOS CLIENTES?
--
-- Se diferencia entre clientes sin operaciones,
-- con operaciones pendientes o canceladas.
-- ------------------------------------------------------------

SELECT
    c.cliente_id,
    c.nombre,
    c.apellido,
    COUNT(v.venta_id) AS operaciones_totales,
    SUM(
        CASE
            WHEN v.estado = 'pendiente' THEN 1
            ELSE 0
        END
    ) AS pendientes,
    SUM(
        CASE
            WHEN v.estado = 'cancelada' THEN 1
            ELSE 0
        END
    ) AS canceladas
FROM clientes c
LEFT JOIN ventas v
    ON c.cliente_id = v.cliente_id
GROUP BY
    c.cliente_id,
    c.nombre,
    c.apellido
HAVING SUM(
    CASE
        WHEN v.estado = 'confirmada' THEN 1
        ELSE 0
    END
) = 0
ORDER BY
    operaciones_totales DESC,
    c.cliente_id;

-- HALLAZGOS:
-- De los 16 clientes sin compras confirmadas:
--
-- 11 nunca registraron operaciones.
--  3 tienen una operación pendiente.
--  2 tienen una operación cancelada.
--

-- INTERPRETACIÓN:
-- Se identificaron tres segmentos comerciales diferenciados:
--

-- 1. Clientes sin operaciones: posible acción de primera compra.

-- 2. Clientes con pendientes: seguimiento comercial.

-- 3. Clientes con cancelaciones: revisión de motivos.
--
-- Los datos permiten identificar estos segmentos,
-- pero no determinar las causas de las operaciones no concretadas.
-- ------------------------------------------------------------

-- 2.3 ¿QUÉ CLIENTES PRESENTAN MAYOR RECURRENCIA DE COMPRA?
--
-- Objetivo:
-- Identificar clientes frecuentes que podrían ser considerados
-- para campañas de fidelización o beneficios comerciales.
--
-- Clasificación propuesta:
-- Alta recurrencia: 10 o más compras confirmadas.
-- Recurrente: entre 3 y 9 compras confirmadas.
-- Baja recurrencia: 1 o 2 compras confirmadas.
--
-- Se utiliza RANK() para ordenar a los clientes según
-- la cantidad de compras realizadas.
-- ------------------------------------------------------------

WITH compras_clientes AS (
    SELECT
        c.cliente_id,
        c.nombre,
        c.apellido,
        c.region,
        COUNT(v.venta_id) AS compras_confirmadas,
        ROUND(
            SUM(v.cantidad * v.precio_unitario),
            2
        ) AS facturacion_total,
        MIN(v.fecha) AS primera_compra,
        MAX(v.fecha) AS ultima_compra
    FROM clientes c
    INNER JOIN ventas v
        ON c.cliente_id = v.cliente_id
    WHERE v.estado = 'confirmada'
    GROUP BY
        c.cliente_id,
        c.nombre,
        c.apellido,
        c.region
)

SELECT
    RANK() OVER (
        ORDER BY compras_confirmadas DESC
    ) AS ranking_recurrencia,
    cliente_id,
    nombre,
    apellido,
    region,
    compras_confirmadas,
    facturacion_total,
    CASE
        WHEN compras_confirmadas >= 10 THEN 'Alta recurrencia'
        WHEN compras_confirmadas >= 3 THEN 'Recurrente'
        ELSE 'Baja recurrencia'
    END AS segmento_cliente,
    primera_compra,
    ultima_compra
FROM compras_clientes
ORDER BY
    ranking_recurrencia,
    facturacion_total DESC,
    cliente_id;

-- HALLAZGOS:
--
-- Se identificaron 25 clientes de alta recurrencia
-- (10 o más compras confirmadas).
--
-- La mayor frecuencia registrada fue de 14 compras,
-- alcanzada por dos clientes.
--
-- La recurrencia no implica necesariamente una mayor
-- facturación individual: existen clientes con menos
-- operaciones que generan ingresos superiores.
--

-- INTERPRETACIÓN DE NEGOCIO:
--
-- Los clientes de alta recurrencia constituyen un segmento
-- potencial para campañas de fidelización, promociones
-- exclusivas o beneficios comerciales.
--
-- Para seleccionar a los destinatarios se recomienda
-- considerar tanto la cantidad de compras como la
-- facturación histórica.
--
-- Los umbrales de segmentación son criterios propuestos
-- para este proyecto, no políticas reales de TecnoRed.
-- ============================================================

-- BLOQUE 3. PRODUCTOS Y STOCK
-- ============================================================

-- 3.1 ¿QUÉ PRODUCTOS COMBINAN VENTAS Y STOCK CRÍTICO?
--
-- Se identifican productos con stock igual o inferior
-- al mínimo establecido y con ventas confirmadas.
--
-- Las ventas corresponden a todo el período histórico.

SELECT
    p.producto_id,
    p.nombre_producto,
    p.categoria,
    p.stock,
    p.stock_minimo,
    COUNT(v.venta_id) AS operaciones_confirmadas,
    SUM(v.cantidad) AS unidades_vendidas,
    ROUND(
        SUM(v.cantidad * v.precio_unitario),
        2
    ) AS facturacion
FROM productos p
INNER JOIN ventas v
    ON p.producto_id = v.producto_id
WHERE
    v.estado = 'confirmada'
    AND p.stock <= p.stock_minimo
GROUP BY
    p.producto_id,
    p.nombre_producto,
    p.categoria,
    p.stock,
    p.stock_minimo
ORDER BY
    unidades_vendidas DESC,
    p.stock ASC;

-- HALLAZGOS:
-- Se identificaron 4 productos con ventas confirmadas
-- y stock actual igual o inferior al mínimo establecido.
--
-- Producto 7057 (RoboClean Pro):
-- Stock actual: 4 unidades.
-- Stock mínimo: 17 unidades.
-- Unidades vendidas en el período histórico: 66.
--

-- INTERPRETACIÓN:
-- Los productos identificados requieren revisión de reposición.
-- Sin embargo, las ventas históricas no representan
-- necesariamente la demanda actual.
--
-- Por eso se incorpora una segunda consulta con una
-- ventana temporal más reciente.
-- ------------------------------------------------------------

-- 3.2 ¿QUÉ PRODUCTOS CON STOCK CRÍTICO TIENEN DEMANDA RECIENTE?
--
-- Se analizan las ventas confirmadas en una ventana que comienza
-- 90 días antes de la última fecha registrada en ventas.
--
-- No se utiliza CURDATE() porque el dataset es histórico.
-- BETWEEN incluye ambos extremos: para fechas sin hora,
-- el intervalo abarca 91 fechas calendario.
-- ------------------------------------------------------------

SELECT
    p.producto_id,
    p.nombre_producto,
    p.stock,
    p.stock_minimo,
    p.stock_minimo - p.stock AS faltante_para_minimo,
    COUNT(v.venta_id) AS operaciones_periodo_reciente,
    COALESCE(
        SUM(v.cantidad),
        0
    ) AS unidades_periodo_reciente
FROM productos p
LEFT JOIN ventas v
    ON p.producto_id = v.producto_id
    AND v.estado = 'confirmada'
    AND v.fecha BETWEEN
        DATE_SUB(
            (SELECT MAX(fecha) FROM ventas),
            INTERVAL 90 DAY
        )
        AND (SELECT MAX(fecha) FROM ventas)
WHERE p.stock <= p.stock_minimo
GROUP BY
    p.producto_id,
    p.nombre_producto,
    p.stock,
    p.stock_minimo
ORDER BY
    unidades_periodo_reciente DESC,
    faltante_para_minimo DESC;

-- HALLAZGOS:
--
-- Se identificaron 4 productos con stock crítico
-- y ventas confirmadas durante la ventana analizada.
--
-- Producto 7057 - RoboClean:
-- Stock: 4 | Mínimo: 17 | Vendidas: 11 | Faltante: 13
--
-- Producto 7347 - ClearView:
-- Stock: 13 | Mínimo: 34 | Vendidas: 10 | Faltante: 21
--
-- Producto 7166 - VisionMax:
-- Stock: 23 | Mínimo: 34 | Vendidas: 9 | Faltante: 11
--
-- Producto 7191 - AIO TouchScreen:
-- Stock: 11 | Mínimo: 20 | Vendidas: 9 | Faltante: 9
--
-- Se necesitan 54 unidades en conjunto para alcanzar
-- los stocks mínimos establecidos.
--

-- CONCLUSIÓN DE NEGOCIO:
--
-- RoboClean presenta la mayor demanda reciente
-- y el menor stock disponible.
--
-- ClearView requiere el mayor volumen de reposición.
--
-- Esta consulta permite priorizar la revisión de compras
-- combinando nivel de stock y comportamiento comercial reciente,
-- en lugar de analizar únicamente el inventario.
--

-- LIMITACIÓN:
-- Se utiliza el stock informado en el maestro de productos.
-- No se reconstruyen movimientos históricos de inventario.
-- ============================================================

-- FIN DE LAS CONSULTAS DE NEGOCIO
-- ============================================================
