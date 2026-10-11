
-- ============================================================
-- TECNORED OPERATIONS ANALYTICS
-- 01_creacion.sql
--
-- Creación de la base de datos y definición de las cinco tablas.
--
-- Ejecutar antes de cargar los CSV.
-- Este script no elimina bases de datos ni registros existentes.
--
-- IMPORTANTE:
-- IF NOT EXISTS evita errores si los objetos ya existen,
-- pero no modifica estructuras creadas previamente.
-- ============================================================


-- ============================================================
-- 1. CREACIÓN DE LA BASE DE DATOS
-- ============================================================

CREATE DATABASE IF NOT EXISTS tecnored_operations;

USE tecnored_operations;


-- ============================================================
-- 2. TABLAS MAESTRAS
-- ============================================================

-- CLIENTES

CREATE TABLE IF NOT EXISTS clientes (
    cliente_id       INT PRIMARY KEY,
    nombre           VARCHAR(50),
    apellido         VARCHAR(50),
    dni              VARCHAR(10),
    fecha_nacimiento DATE,
    email            VARCHAR(100),
    telefono         VARCHAR(20),
    direccion        VARCHAR(100),
    ciudad           VARCHAR(30),
    provincia        VARCHAR(30),
    region           VARCHAR(30),
    fecha_alta       DATE,
    estado           VARCHAR(30)
);


-- PRODUCTOS

CREATE TABLE IF NOT EXISTS productos (
    producto_id     INT PRIMARY KEY,
    nombre_producto VARCHAR(100),
    categoria       VARCHAR(50),
    subcategoria    VARCHAR(50),
    sku             VARCHAR(30) NOT NULL UNIQUE,
    costo           DECIMAL(12,2),
    precio_lista    DECIMAL(12,2),
    stock           INT,
    stock_minimo    INT,
    fecha_alta      DATE,
    estado          VARCHAR(30)
);


-- SUCURSALES

CREATE TABLE IF NOT EXISTS sucursales (
    sucursal_id INT PRIMARY KEY,
    sucursal    VARCHAR(30),
    ciudad      VARCHAR(30),
    provincia   VARCHAR(30),
    region      VARCHAR(30),
    direccion   VARCHAR(100),
    fecha_alta  DATE,
    estado      VARCHAR(30)
);


-- ============================================================
-- 3. TABLAS TRANSACCIONALES
-- ============================================================

-- VENTAS

CREATE TABLE IF NOT EXISTS ventas (
    venta_id        INT PRIMARY KEY,
    fecha           DATE,
    cliente_id      INT,
    producto_id     INT,
    sucursal_id     INT,
    cantidad        INT,
    precio_unitario DECIMAL(12,2),
    canal           VARCHAR(30),
    medio_pago      VARCHAR(30),
    estado          VARCHAR(30),

    FOREIGN KEY (cliente_id)
        REFERENCES clientes(cliente_id),

    FOREIGN KEY (producto_id)
        REFERENCES productos(producto_id),

    FOREIGN KEY (sucursal_id)
        REFERENCES sucursales(sucursal_id)
);


-- DEVOLUCIONES

CREATE TABLE IF NOT EXISTS devoluciones (
    devolucion_id       INT PRIMARY KEY,
    fecha_devolucion    DATE,
    venta_id            INT,
    cliente_id          INT,
    producto_id         INT,
    sucursal_id         INT,
    cantidad_devuelta   INT,
    motivo              VARCHAR(100),
    estado              VARCHAR(30),
    importe_reintegrado DECIMAL(12,2),

    FOREIGN KEY (venta_id)
        REFERENCES ventas(venta_id),

    FOREIGN KEY (cliente_id)
        REFERENCES clientes(cliente_id),

    FOREIGN KEY (producto_id)
        REFERENCES productos(producto_id),

    FOREIGN KEY (sucursal_id)
        REFERENCES sucursales(sucursal_id)
);


-- ============================================================
-- 4. COMPROBACIÓN DE LA ESTRUCTURA
-- ============================================================

SHOW TABLES;

-- Resultado esperado: cinco tablas.
-- clientes, productos, sucursales, ventas y devoluciones.
