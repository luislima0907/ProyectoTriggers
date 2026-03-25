ALTER TRIGGER trg_no_cambiar_borrar_registro
ON RegistroModificacionSalario
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ROLLBACK;
    THROW 50001, 'No se permite modificar ni borrar registros de auditoría', 1;
END;