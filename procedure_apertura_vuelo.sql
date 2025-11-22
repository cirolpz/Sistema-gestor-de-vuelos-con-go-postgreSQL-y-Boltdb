create or replace function apertura_vuelo (
	p_nro_ruta int,
	p_f_salida timestamp,
	p_asientos_totales int
) returns int as $$
declare
	v_id_vuelo int;
	v_id_error int;
	v_operacion text := 'apertura';
begin
	-- A. validar que el número de ruta exista
	if not exists(select 1 from ruta where nro_ruta = p_nro_ruta) then 
		select coalesce(max(id_error),0) + 1 into v_id_error from error;
		insert into error (id_error, operacion, nro_ruta, f_salida_vuelo, nro_asientos_totales, id_vuelo, id_reserva, id_cliente, nro_asiento, f_error, motivo) 
		values (v_id_error,v_operacion,p_nro_ruta, p_f_salida, p_asientos_totales, null, null, null, null, now(), 'número de ruta no válido');
		return -1;
	end if;
	
	-- B. validar que la fecha/hora de salida sea posterior a la actual
	if p_f_salida < now() then
		select coalesce(max(id_error),0) + 1 into v_id_error from error;
		insert into error (id_error, operacion, nro_ruta, f_salida_vuelo, nro_asientos_totales, id_vuelo, id_reserva, id_cliente, nro_asiento, f_error, motivo) 
		values (v_id_error,v_operacion,p_nro_ruta, p_f_salida, p_asientos_totales, null, null, null, null, now(), 'no se permite abrir un nuevo vuelo con retroactividad');
		return -1;
	end if;
		
	-- C. validar que la cantidad de asientos sea > 0
	if p_asientos_totales <= 0 then
		select coalesce(max(id_error),0) + 1 into v_id_error from error;
		insert into error (id_error, operacion, nro_ruta, f_salida_vuelo, nro_asientos_totales, id_vuelo, id_reserva, id_cliente, nro_asiento, f_error, motivo) 
		values (v_id_error,v_operacion,p_nro_ruta, p_f_salida, p_asientos_totales, null, null, null, null, now(), 'no se permite abrir un vuelo sin asientos disponibles');
		return -1;
	end if;
	
	-- Todo ok → insertar en tabla vuelo
	select coalesce(max(id_vuelo), 0) + 1 into v_id_vuelo from vuelo;
	insert into vuelo (id_vuelo, nro_ruta, fecha_salida, hora_salida, nro_asientos_totales, nro_asientos_disponibles)
	values (v_id_vuelo, p_nro_ruta, date(p_f_salida), p_f_salida::time, p_asientos_totales, p_asientos_totales);
	return v_id_vuelo;
end;
$$ language plpgsql;