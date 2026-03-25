CREATE DATABASE LogisticaNorte;
GO
USE LogisticaNorte;
GO

CREATE TABLE Categoria (
    IdCategoria INT PRIMARY KEY IDENTITY(1,1),
    Nombre VARCHAR(50) NOT NULL,
    Descripcion VARCHAR(200)
);

CREATE TABLE Producto (
    IdProducto INT PRIMARY KEY IDENTITY(1,1),
    Nombre VARCHAR(100) NOT NULL,
    IdCategoria INT FOREIGN KEY REFERENCES Categoria(IdCategoria),
    PrecioUnitario DECIMAL(18,2) NOT NULL CHECK (PrecioUnitario > 0),
    StockActual INT DEFAULT 0 CHECK (StockActual >= 0),
    PuntoReorden INT DEFAULT 10
);

CREATE TABLE Cliente (
    IdCliente INT PRIMARY KEY IDENTITY(1,1),
    NombreEmpresa VARCHAR(150) NOT NULL,
    RTN CHAR(14) UNIQUE,
    Telefono VARCHAR(20),
    Estado BIT DEFAULT 1
);

CREATE TABLE Pedido (
    IdPedido INT PRIMARY KEY IDENTITY(1000,1),
    IdCliente INT FOREIGN KEY REFERENCES Cliente(IdCliente),
    FechaPedido DATETIME DEFAULT GETDATE(),
    EstadoPedido VARCHAR(20) DEFAULT 'PROCESAMIENTO'
        CHECK (EstadoPedido IN ('PROCESAMIENTO', 'DESPACHADO', 'ENTREGADO', 'ANULADO')),
    TotalPedido DECIMAL(18,2) DEFAULT 0
);

CREATE TABLE DetallePedido (
    IdDetalle INT PRIMARY KEY IDENTITY(1,1),
    IdPedido INT FOREIGN KEY REFERENCES Pedido(IdPedido),
    IdProducto INT FOREIGN KEY REFERENCES Producto(IdProducto),
    Cantidad INT NOT NULL CHECK (Cantidad > 0),
    PrecioVenta DECIMAL(18,2) NOT NULL
);

CREATE TABLE EliminacionPedidoBitacora (
    IdLog INT PRIMARY KEY IDENTITY(1,1),
    IdPedido INT NOT NULL,
    FechaIntento DATETIME DEFAULT GETDATE(),
    UsuarioSQL VARCHAR(100) DEFAULT SYSTEM_USER,
    Terminal VARCHAR(100) DEFAULT HOST_NAME(),
    DetalleRegistroXML XML,
    MotivoBloqueo VARCHAR(255) DEFAULT 'BLOQUEO POR POLÍTICA DE INMUTABILIDAD LN-001'
);
GO

CREATE OR ALTER TRIGGER trg_Pedido_ProteccionTotal
ON Pedido
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
   
    INSERT INTO EliminacionPedidoBitacora (IdPedido, DetalleRegistroXML)
    SELECT 
        d.IdPedido,
        (SELECT * FROM deleted d2 WHERE d2.IdPedido = d.IdPedido FOR XML PATH('Pedido'))
    FROM deleted d;

    PRINT 'Registrando intento en bitácora...';
    RAISERROR ('ERROR DE SEGURIDAD: Borrado no permitido. Intento registrado.', 16, 1);
END;
GO


INSERT INTO Categoria (Nombre, Descripcion) VALUES 
('Electrónica', 'Equipos de computación y gadgets'),
('Seguridad Industrial', 'Equipo de protección personal'),
('Material de Oficina', 'Papelería y consumibles');

INSERT INTO Producto (Nombre, IdCategoria, PrecioUnitario, StockActual, PuntoReorden) VALUES 
('Laptop Dell Latitude', 1, 18500.00, 15, 5),
('Monitor HP 24"', 1, 3200.00, 10, 3),
('Casco de Seguridad', 2, 450.00, 100, 20),
('Guantes de Nitrilo', 2, 85.00, 500, 50),
('Resma Papel Bond', 3, 115.00, 200, 30);

INSERT INTO Cliente (NombreEmpresa, RTN, Telefono) VALUES 
('Constructora Horizonte', '08011990123456', '2240-0000'),
('Banco del Norte', '01011980999888', '2550-1111'),
('Suministros Globales', '05011975444333', '2232-4455');

INSERT INTO Pedido (IdCliente, EstadoPedido, TotalPedido) VALUES (1, 'ENTREGADO', 19400.00);
INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioVenta) VALUES 
(1000, 1, 1, 18500.00),
(1000, 3, 2, 450.00);

INSERT INTO Pedido (IdCliente, EstadoPedido, TotalPedido) VALUES (2, 'PROCESAMIENTO', 6400.00);
INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioVenta) VALUES 
(1001, 2, 2, 3200.00);

INSERT INTO Pedido (IdCliente, EstadoPedido, TotalPedido) VALUES (1, 'PROCESAMIENTO', 5350.00);
INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioVenta) VALUES 
(1002, 3, 10, 450.00), 
(1002, 4, 10, 85.00);   

INSERT INTO Pedido (IdCliente, EstadoPedido, TotalPedido) VALUES (2, 'DESPACHADO', 1150.00);
INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioVenta) VALUES 
(1003, 5, 10, 115.00);  


INSERT INTO Pedido (IdCliente, EstadoPedido, TotalPedido) VALUES (3, 'ENTREGADO', 21700.00);
INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioVenta) VALUES 
(1004, 1, 1, 18500.00), 
(1004, 2, 1, 3200.00);  

INSERT INTO Pedido (IdCliente, EstadoPedido, TotalPedido) VALUES (1, 'PROCESAMIENTO', 9000.00);
INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioVenta) VALUES 
(1005, 3, 20, 450.00);  

INSERT INTO Pedido (IdCliente, EstadoPedido, TotalPedido) VALUES (3, 'PROCESAMIENTO', 575.00);
INSERT INTO DetallePedido (IdPedido, IdProducto, Cantidad, PrecioVenta) VALUES 
(1006, 5, 5, 115.00);   
GO

CREATE OR ALTER VIEW v_ResumenPedidos AS
SELECT 
    P.IdPedido,
    C.NombreEmpresa AS Cliente,
    P.FechaPedido,
    P.EstadoPedido,
    P.TotalPedido AS [Total Neto]
FROM Pedido P
JOIN Cliente C ON P.IdCliente = C.IdCliente;
GO


SELECT * FROM v_ResumenPedidos;


DELETE FROM Pedido WHERE IdPedido = 1001;


SELECT * FROM EliminacionPedidoBitacora;


SELECT IdPedido FROM Pedido;