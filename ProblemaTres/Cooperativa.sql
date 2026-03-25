CREATE DATABASE CooperativaHorizonte
go
USE CooperativaHorizonte
go
CREATE TABLE Cuenta (
    IDCuenta INT PRIMARY KEY,
    Saldo DECIMAL(18,2) NOT NULL
)

CREATE TABLE Transferencia (
    IDTransferencia INT PRIMARY KEY,
    CuentaOrigen INT NOT NULL,
    CuentaDestino INT NOT NULL,
    Monto DECIMAL(18,2) NOT NULL,
    Fecha DATETIME NOT NULL,

    CONSTRAINT FK_Transferencia_Origen
        FOREIGN KEY (CuentaOrigen)
        REFERENCES Cuenta(IDCuenta),

    CONSTRAINT FK_Transferencia_Destino
        FOREIGN KEY (CuentaDestino)
        REFERENCES Cuenta(IDCuenta),

    CONSTRAINT CK_Transferencia_Monto
        CHECK (Monto > 0)
)

CREATE TABLE AuditoriaTransferencias (
    IDAuditoria INT PRIMARY KEY,
    IDTransferencia INT NOT NULL,
    FechaCambio DATETIME NOT NULL,
    Usuario VARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    MontoAnterior DECIMAL(18,2) NOT NULL,
    MontoNuevo DECIMAL(18,2) NOT NULL,
    SaldoOrigenAntes DECIMAL(18,2) NOT NULL,
    SaldoOrigenDespues DECIMAL(18,2) NOT NULL,
    SaldoDestinoAntes DECIMAL(18,2) NOT NULL,
    SaldoDestinoDespues DECIMAL(18,2) NOT NULL,

    CONSTRAINT FK_Auditoria_Transferencia
        FOREIGN KEY (IDTransferencia)
        REFERENCES Transferencia(IDTransferencia)
)

CREATE SEQUENCE SeqAuditoriaTransferencias
START WITH 1
INCREMENT BY 1
go
CREATE OR ALTER TRIGGER TR_NoActualizar_Auditoria
ON AuditoriaTransferencias
INSTEAD OF UPDATE
AS
BEGIN
    SELECT 'No se permite actualizar la auditoría.'
END
GO

CREATE OR ALTER TRIGGER TR_NoBorrar_Auditoria
ON AuditoriaTransferencias
INSTEAD OF DELETE
AS
BEGIN
    SELECT 'No se permite eliminar la auditoría.'
END
GO

CREATE OR ALTER TRIGGER TR_Actualizar_Transferencia
ON Transferencia
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- No permitir cambiar cuentas
        IF EXISTS (
            SELECT 1
            FROM inserted AS i
            INNER JOIN deleted AS d 
            ON i.IDTransferencia = d.IDTransferencia
            WHERE i.CuentaOrigen != d.CuentaOrigen
               OR i.CuentaDestino != d.CuentaDestino
        )
        BEGIN
            ;THROW 50000, 'No se pueden modificar las cuentas en una transferencia.', 1
        END

        -- Validar que no quede saldo negativo
        IF EXISTS (
            SELECT 1
            FROM inserted AS i
            INNER JOIN deleted AS d 
            ON i.IDTransferencia = d.IDTransferencia
            INNER JOIN Cuenta AS co 
            ON co.IDCuenta = i.CuentaOrigen
            WHERE (co.Saldo + d.Monto - i.Monto) < 0
        )
        BEGIN
            ;THROW 50000, 'Saldo insuficiente en cuenta origen.', 1
        END

        -- Auditoría
        INSERT INTO AuditoriaTransferencias (
            IDAuditoria,
            IDTransferencia,
            FechaCambio,
            Usuario,
            MontoAnterior,
            MontoNuevo,
            SaldoOrigenAntes,
            SaldoOrigenDespues,
            SaldoDestinoAntes,
            SaldoDestinoDespues
        )
        SELECT 
            NEXT VALUE FOR SeqAuditoriaTransferencias,
            i.IDTransferencia,
            GETDATE(),
            SYSTEM_USER,
            d.Monto,
            i.Monto,
            co.Saldo,
            co.Saldo + d.Monto - i.Monto,
            cd.Saldo,
            cd.Saldo - d.Monto + i.Monto
        FROM inserted AS i
        INNER JOIN deleted AS d 
        ON i.IDTransferencia = d.IDTransferencia
        INNER JOIN Cuenta AS co 
        ON co.IDCuenta = i.CuentaOrigen
        INNER JOIN Cuenta AS cd 
        ON cd.IDCuenta = i.CuentaDestino;

        -- Revertir monto anterior y aplicar nuevo
        -- Cuenta origen
        UPDATE Cuenta
        SET Saldo = Saldo + d.Monto - i.Monto
        FROM Cuenta AS c
        INNER JOIN inserted AS i 
        ON c.IDCuenta = i.CuentaOrigen
        INNER JOIN deleted AS d 
        ON i.IDTransferencia = d.IDTransferencia

        -- Cuenta destino
        UPDATE Cuenta
        SET Saldo = Saldo - d.Monto + i.Monto
        FROM Cuenta AS c
        INNER JOIN inserted AS i 
        ON c.IDCuenta = i.CuentaDestino
        INNER JOIN deleted AS d 
        ON i.IDTransferencia = d.IDTransferencia

    END TRY
    BEGIN CATCH
        ;THROW

        SELECT 
            'ERROR' AS Estado,
            ERROR_MESSAGE() AS Mensaje,
            SYSTEM_USER AS Usuario,
            GETDATE() AS Fecha
    END CATCH
END
GO

-- Cuentas
INSERT INTO Cuenta VALUES (1, 1000)
INSERT INTO Cuenta VALUES (2, 500)
INSERT INTO Cuenta VALUES (3, 300)

-- Transferencias
INSERT INTO Transferencia VALUES (1, 3, 2, 100, GETDATE())

-- Intentar actualizar monto
UPDATE Transferencia
SET Monto = 300
WHERE IDTransferencia = 1

-- Intentar cambiar cuentas
UPDATE Transferencia
SET CuentaOrigen = 2, CuentaDestino = 2
WHERE IDTransferencia = 1

SELECT * FROM Transferencia

-- Saldo insuficiente
UPDATE Transferencia
SET Monto = 100000
WHERE IDTransferencia = 1

-- Para actualizar auditoria
UPDATE AuditoriaTransferencias
SET MontoNuevo = 900
WHERE IDAuditoria = 1

-- Para eliminar auditoria
DELETE FROM AuditoriaTransferencias


SELECT * FROM Cuenta
SELECT * FROM Transferencia
SELECT * FROM AuditoriaTransferencias

