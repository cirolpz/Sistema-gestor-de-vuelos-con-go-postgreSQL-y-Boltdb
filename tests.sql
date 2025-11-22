--------------------------------------------------------------------
-- APERTURA DE VUELOS (1-5)
--------------------------------------------------------------------

-- id-orden 1: apertura con fecha retroactiva → debe fallar
-- Entrada: apertura_vuelo(nro_ruta=5051, fecha_salida='2025-10-28 15:00', asientos_totales=170)
do $$
declare 
valor int;
begin
	valor:= apertura_vuelo(5051, timestamp '2025-10-28 15:00:00', 170); 
	if valor <> -1 then
		raise exception 'FALLO 1: no se permite abrir un vuelo con retroactividad → debía devolver -1 y devolvió %', valor;
	end if;
end $$;


-- id-orden 2: apertura con cero asientos → debe fallar
-- Entrada: apertura_vuelo(nro_ruta=5051, fecha_salida='2025-11-29 15:00', asientos_totales=0)
do $$
declare 
	valor int;
begin
	valor := apertura_vuelo(5051, timestamp '2025-11-29 15:00:00', 0);
	if valor <> -1 then
		raise exception 'FALLO 2: no se permite abrir un vuelo sin asientos disponibles → debía devolver -1 y devolvió %', valor;
	end if;
end $$;	

-- Test 3: número de ruta inexistente → debe fallar
-- Entrada: apertura_vuelo(nro_ruta=5000, fecha_salida='2025-11-29  15:00', asientos_totales=170)
do $$
declare 
valor int;
begin
	valor:= apertura_vuelo(5000, timestamp '2025-11-29 15:00:00', 170); 
	if valor <> -1 then
		raise exception 'FALLO 3: número de ruta no válido → debía devolver -1 y devolvió %', valor;
	end if;
end $$;

-- id_orden 4-5: apertura correcta (AEP → MDZ)
-- Entrada: apertura_vuelo(nro_ruta=5050, fecha_salida='2025-11-30 14:00', asientos_totales=170), apertura_vuelo(nro_ruta=5161, fecha_salida='2025-11-30 15:00', asientos_totales=2)
do $$
declare 
	valor int;
	valor2 int;
begin
	valor := apertura_vuelo(5050, timestamp '2025-11-30 14:00:00', 170);
	valor2 := apertura_vuelo(5161, timestamp '2025-11-30 15:00:00',2);
	if valor < 1 or valor2 < 1 then
		raise exception 'FALLO 4-5: apertura correcta → debía devolver id_vuelo > 0 y devolvió % % ', valor, valor2;
	end if;
end $$;

--------------------------------------------------------------------
-- RESERVA DE PASAJES (6-9)
--------------------------------------------------------------------

-- id_orden 6: reserva correcta → cliente 15 en vuelo 2
-- Entrada: reserva_pasaje(id_vuelo=2, id_cliente=15)
do $$
declare 
	valor int;
begin
	valor := reserva_pasaje(2, 15); 
	if valor < 1 then
		raise exception 'FALLO 6: reserva de pasaje válida → debía devolver id_reserva > 0 y devolvió % ', valor;
	end if;
end $$;

-- id_orden 7: reserva correcta → cliente 10 en vuelo 1
-- Entrada: reserva_pasaje(id_vuelo=1, id_cliente=10)
do $$
declare 
	valor int;
begin
	valor := reserva_pasaje(1, 10); 
	if valor < 1 then
		raise exception 'FALLO 7: reserva de pasaje válida → debía devolver id_reserva > 0  y devolvió % ', valor;
	end if;
end $$;
	
-- id_orden 8: reserva correcta → cliente 20 en vuelo 2 (completa el vuelo)
-- Entrada: reserva_pasaje(id_vuelo=2, id_cliente=20)
do $$
declare 
	valor int;
begin
	valor := reserva_pasaje(2, 20); 
	if valor < 1 then
		raise exception 'FALLO 8: reserva de pasaje válida → debía devolver id_reserva > 0 y devolvió % ', valor;
	end if;
end $$;

-- id_orden 9: id_vuelo inexistente
-- Entrada: reserva_pasaje(id_vuelo=3, id_cliente=10)
do $$
declare 
	valor int;
begin
	valor := reserva_pasaje(3, 10); 
	if valor <> -1 then
		raise exception 'FALLO 9: id de vuelo no válido → debía devolver -1 y devolvió % ', valor;
	end if;
end $$;

--------------------------------------------------------------------
-- CHECK-IN DE ASIENTOS (10-15)
--------------------------------------------------------------------

-- Sabemos por las reservas anteriores:
-- reserva 1 -> vuelo 2 (2 asientos)
-- reserva 2 -> vuelo 1 (170 asientos)
-- reserva 3 -> vuelo 2 (2 asientos)

-- id_orden 10: asiento inexistente en vuelo de 2 asientos → FALSE
-- Entrada: check_in_asiento(id_reserva=1, id_cliente=15, nro_asiento=3)
do $$
declare
    valor boolean;
begin
    valor := check_in_asiento(1, 15, 3);
    if valor then
    raise exception 'FALLO 10: asiento inexistente → debía devolver FALSE (asiento inexistente) y devolvió % ', valor;
    end if;
end $$;

-- id_orden 11: check-in válido (primer asiento) → TRUE
-- Entrada: check_in_asiento(id_reserva=1, id_cliente=15, nro_asiento=1)
do $$
declare
    valor boolean;
begin
    valor := check_in_asiento(1, 15, 1);
    if not valor then
    	raise exception 'FALLO 11: check-in válido → se esperaba TRUE (check-in OK) y devolvió FALSE';
    end if;
end $$;

-- id_orden 12: check-in válido → TRUE
-- Entrada: check_in_asiento(id_reserva=2, id_cliente=10, nro_asiento=40)
do $$
declare
    valor boolean;
begin
    valor := check_in_asiento(2, 10, 40);
    if not valor then
    	raise exception 'FALLO 12: check-in de asiento válido → se esperaba TRUE y devolvió FALSE';
	end if;
end $$;

-- id_orden 13: Reserva 1 ya hizo check-in en el orden 11 → FALSE debe fallar con check-in ya realizado
-- Entrada: check_in_asiento(id_reserva=1, id_cliente=15, nro_asiento=2)
do $$
declare
    valor boolean;
begin
    valor := check_in_asiento(1, 15, 2);
    if valor then
    	raise exception 'FALLO 13: check-in ya realizadose → se esperaba FALSE y devolvió TRUE';
    end if;
end $$;

-- id_orden 14: asiento ya ocupado → FALSE
-- Entrada: check_in_asiento(id_reserva=3, id_cliente=20, nro_asiento=1)
do $$
declare
    valor boolean;
begin
    valor := check_in_asiento(3, 20, 1);
    if valor then
    	raise exception 'FALLO 14: número de asiento ya ocupado → se esperaba FALSE y devolvió TRUE';
	end if;
end $$;

-- id_orden 15: check-in válido del último asiento libre → TRUE
-- Entrada: check_in_asiento(id_reserva=3, id_cliente=20, nro_asiento=2)
do $$
declare
    valor boolean;
begin
    valor := check_in_asiento(3, 20, 2);
    if not valor then
    	raise exception 'FALLO 15: check-in de asiento válido → se esperaba TRUE  y devolvió FALSE';
    end if;
end $$;


--------------------------------------------------------------------
-- RESERVA (16-17)
--------------------------------------------------------------------

-- id_orden 16: vuelo 2 ya está completo
-- Entrada: reserva_pasaje(id_vuelo=2, id_cliente=5)
do $$
declare
    valor int;
begin
    valor := reserva_pasaje(2, 5);
    if valor <> -1 then 
		raise exception 'FALLO 16: el vuelo ya está completo → debía devolver -1 y devolvió %', valor;
	end if;
end $$;

-- id_orden 17: reserva válida, aún hay lugar en vuelo 1)
-- Entrada: reserva_pasaje(id_vuelo=1, id_cliente=5)
do $$
declare
    valor int;
begin
    valor := reserva_pasaje(1, 5);
    if valor = -1 then 
		raise exception 'FALLO 17: reserva de pasaje válida → debía devolver id_reserva';
    end if;
end $$;

--------------------------------------------------------------------
-- ANULACIÓN DE RESERVAS (18-20)
--------------------------------------------------------------------


-- id_orden 18: Anular reserva ya confirmada (reserva 3 está confirmada) → falla
-- Entrada: anulacion_reserva(id_reserva=3, id_cliente=20)
do $$
declare
    valor boolean;
begin
    valor := anulacion_reserva(3, 20);
    if valor then
        raise exception 'FALLO 18: no es posible anular una reserva ya confirmada → debía devolver FALSE';
	end if;
end $$;


-- id_orden  19: id_reserva inválido (no existe reserva 3 para cliente 5) → falla
-- Entrada: anulacion_reserva(id_reserva=3, id_cliente=5)
do $$
declare
    valor boolean;
begin
    valor := anulacion_reserva(3, 5);
    if  valor then 
		raise exception 'FALLO 19: id de reserva no válido → debía devolver FALSE';
    end if;
end $$;

-- id_orden 20: anulación correcta de reserva 4 con estado reservado
-- Entrada: anulacion_reserva(id_reserva=4, id_cliente=5)
do $$
declare
    valor boolean;
begin
    valor := anulacion_reserva(4, 5);
    if not valor then
		raise exception 'FALLO 20: anulación válida debía devolver TRUE';
	end if;
end $$;