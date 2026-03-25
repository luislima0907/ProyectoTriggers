--1. Se ejecuta para dejar todos nullos
UPDATE Empleado SET Usuario = NULL;

--2 se asigna el usuario actual a un empleado específico
UPDATE Empleado
SET Usuario = SYSTEM_USER
WHERE IdEmpleado = 1;

--3. Se autoriza a un empleado específico para modificar su salario
UPDATE Salarios
SET SalarioActual = 10000
WHERE IdEmpleado = 3;

SELECT*FROM Empleado
SELECT*FROM PersonasAutorizadas
SELECT*FROM RegistroModificacionSalario