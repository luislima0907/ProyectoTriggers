ALTER TRIGGER trg_CambiarSalario
ON Salarios
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @IdEmpleadoEjecutor INT;

     BEGIN TRY

        SELECT @IdEmpleadoEjecutor = IdEmpleado
        FROM Empleado
        WHERE Usuario = SYSTEM_USER;

        IF @IdEmpleadoEjecutor IS NULL
        BEGIN
            ROLLBACK;
            THROW 50000, 'Usuario no registrado como empleado', 1;
        END;

        IF NOT EXISTS (
            SELECT 1
            FROM PersonasAutorizadas
            WHERE IdEmpleado = @IdEmpleadoEjecutor
        )
        BEGIN
            ROLLBACK;
            THROW 50000, 'Empleado no autorizado para cambiar salario', 1;
        END;
        INSERT INTO RegistroModificacionSalario (
            UsuarioCambio, 
            SalarioAnterior, 
            SalarioNuevo,
            IdEmpleado
        )
        SELECT 
            CONCAT('Empleado ', @IdEmpleadoEjecutor,' ', SYSTEM_USER),
            d.SalarioActual,
            i.SalarioActual,
            i.IdEmpleado
        FROM deleted d
        INNER JOIN inserted i 
            ON d.IdEmpleado = i.IdEmpleado;

        RAISERROR('Salario modificado exitosamente', 0, 1) WITH NOWAIT;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
