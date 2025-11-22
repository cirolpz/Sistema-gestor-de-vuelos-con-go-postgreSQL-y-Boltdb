create or replace function reserva_pasaje(
	p_id_vuelo int,
	p_id_cliente int
) returns int as $$
declare
	v_id_reserva int;
	v_id_error int;
	v_operacion text := 'reserva';
	asientos_disponibles int;
begin
	-- A. Validar que exista el id de vuelo
	if not exists (select 1 from vuelo where id_vuelo = p_id_vuelo) then
		select coalesce(max(id_error),0) + 1 into v_id_error from error;
		insert into error (id_error, operacion, nro_ruta, f_salida_vuelo, nro_asientos_totales, id_vuelo, id_reserva, id_cliente, nro_asiento, f_error, motivo) 
		values (v_id_error,v_operacion,null, null, null, p_id_vuelo, null, p_id_cliente, null, now(), 'id de vuelo no válido');
		return -1;
	end if;

	-- B. Validar que exista el id cliente
	if not exists (select 1 from cliente where id_cliente = p_id_cliente) then
		select coalesce(max(id_error),0) + 1 into v_id_error from error;
		insert into error (id_error, operacion, nro_ruta, f_salida_vuelo, nro_asientos_totales, id_vuelo, id_reserva, id_cliente, nro_asiento, f_error, motivo) 
		values (v_id_error, v_operacion, null, null, null, p_id_vuelo, null, p_id_cliente, null, now(), 'id de cliente no válido');
		return -1;
	end if;

	-- C. Validar que haya asientos disponibles
	select nro_asientos_disponibles into asientos_disponibles from vuelo where id_vuelo = p_id_vuelo;

	if asientos_disponibles <=0 then
		select coalesce(max(id_error),0) + 1 into v_id_error from error;
		insert into error (id_error, operacion, nro_ruta, f_salida_vuelo, nro_asientos_totales, id_vuelo, id_reserva, id_cliente, nro_asiento, f_error, motivo) 
		values (v_id_error,v_operacion, null, null, null, p_id_vuelo, null, p_id_cliente, null, now(), 'el vuelo ya está completo');
		return -1;
	end if;

	-- Todo ok → genero reserva + Actualizo asientos
	select coalesce(max(id_reserva),0) + 1 into v_id_reserva from reserva_pasaje;
	
	insert into reserva_pasaje(id_reserva, id_vuelo, id_cliente, f_reserva, nro_asiento, f_check_in, estado)
	values (v_id_reserva, p_id_vuelo, p_id_cliente, now(), null, null, 'reservado');

	update vuelo set nro_asientos_disponibles = nro_asientos_disponibles - 1
	where id_vuelo = p_id_vuelo;

	return v_id_reserva;
end;
$$ language plpgsql;