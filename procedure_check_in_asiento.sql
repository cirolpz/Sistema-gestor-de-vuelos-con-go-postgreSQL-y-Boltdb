create or replace function check_in_asiento(
	p_id_reserva int,
	p_id_cliente int, 
	p_nro_asiento int
) returns boolean as $$
declare
    v_id_vuelo int;
    v_estado_actual char(10);
    v_asientos_totales int;
    v_asiento_ocupado int;
    v_id_error int;
    v_operacion text := 'check-in';
begin
    -- A. Validar que exista la reserva y que pertenezca al cliente
    if not exists (
        select 1 from reserva_pasaje 
        where id_reserva = p_id_reserva
		and id_cliente = p_id_cliente
    ) then
        select coalesce(max(id_error),0) + 1 into v_id_error from error;
        insert into error (id_error, operacion, nro_ruta, f_salida_vuelo, nro_asientos_totales, id_vuelo, id_reserva, id_cliente, nro_asiento, f_error, motivo)
        values (v_id_error, v_operacion, null, null, null, v_id_vuelo, p_id_reserva, p_id_cliente, p_nro_asiento, now(), 'id de reserva no válido');
        return false;
    end if;

    -- B. Validar que el estado actual sea 'reservado'
	select id_vuelo, estado into v_id_vuelo, v_estado_actual
    from reserva_pasaje where id_reserva = p_id_reserva;

    -- C. validar rango del número de asiento   
    if v_estado_actual <> 'reservado' then
    	select coalesce(max(id_error),0) + 1 into v_id_error from error;
        insert into error (id_error, operacion, nro_ruta, f_salida_vuelo, nro_asientos_totales, id_vuelo, id_reserva, id_cliente, nro_asiento, f_error, motivo)
        values (v_id_error, v_operacion, null, null, null, v_id_vuelo, p_id_reserva, p_id_cliente, null, now(),'check-in ya realizado para el id de reserva');
        return false;
    end if;

    -- D. Validar que el asiento no esté ya ocupado
    select nro_asientos_totales into v_asientos_totales
    from vuelo where id_vuelo = v_id_vuelo;

    if p_nro_asiento < 1 or p_nro_asiento > v_asientos_totales then
        select coalesce(max(id_error),0) + 1 into v_id_error from error;
        insert into error (id_error, operacion, nro_ruta, f_salida_vuelo, nro_asientos_totales, id_vuelo, id_reserva, id_cliente, nro_asiento, f_error, motivo)
        values (v_id_error, v_operacion, null, null, v_asientos_totales, v_id_vuelo, p_id_reserva, p_id_cliente, p_nro_asiento, now(), 'número de asiento inexistente');
        return false;
    end if;

    -- D. Validar que el asiento no esté ya ocupado
    select 1 into v_asiento_ocupado
    from reserva_pasaje
    where id_vuelo = v_id_vuelo
    and nro_asiento = p_nro_asiento
    and estado = 'confirmado';

    if found then
        select coalesce(max(id_error),0) + 1 into v_id_error from error;
        insert into error (id_error, operacion, nro_ruta, f_salida_vuelo, nro_asientos_totales, id_vuelo, id_reserva, id_cliente, nro_asiento, f_error, motivo)
        values (v_id_error, v_operacion,null,null,v_asientos_totales,v_id_vuelo,p_id_reserva,p_id_cliente,p_nro_asiento,now(),'número de asiento ya ocupado');
        return false;
    end if;
    

    -- Todo ok → realizar el check-in
    update reserva_pasaje
    set nro_asiento = p_nro_asiento,
        f_check_in = now(),
        estado = 'confirmado'
    where id_reserva = p_id_reserva;

    return true;
end;
$$ language plpgsql;