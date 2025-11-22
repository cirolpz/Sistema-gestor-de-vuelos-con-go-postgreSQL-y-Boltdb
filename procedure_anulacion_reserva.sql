create or replace function anulacion_reserva(
    p_id_reserva int,
    p_id_cliente int
) returns boolean as $$
declare
    v_id_error   int;
    v_id_vuelo   int;
    v_estado     char(10);
	v_operacion  text := 'anulacion';
begin
    -- A. verificar que exista la reserva y sea del cliente indicado
    if not exists (
        select 1
        from reserva_pasaje
        where id_reserva = p_id_reserva
          and id_cliente = p_id_cliente
    ) then
        select coalesce(max(id_error), 0) + 1 into v_id_error from error;
        insert into error (
            id_error, operacion, id_reserva, id_cliente, f_error, motivo
        ) values (
            v_id_error, v_operacion, p_id_reserva, p_id_cliente, now(), 'id de reserva no válido'
        );
        return false;
    end if;

    -- obtener estado actual y vuelo
    select estado, id_vuelo
    into v_estado, v_id_vuelo
    from reserva_pasaje
    where id_reserva = p_id_reserva;

    -- B. verificar que el estado sea 'reservado'
    if v_estado != 'reservado' then

        select coalesce(max(id_error), 0) + 1 into v_id_error from error;
        insert into error (
            id_error, operacion, id_reserva, id_cliente, f_error, motivo
        ) values (
            v_id_error, v_operacion, p_id_reserva, p_id_cliente, now(), 'no es posible anular una reserva ya confirmada'
        );
        return false;
    end if;

	-- C. marcar como anulada
    update reserva_pasaje
    set estado = 'anulado'
    where id_reserva = p_id_reserva;

    -- D. Todo ok → liberar un asiento en el vuelo
    update vuelo
    set nro_asientos_disponibles = nro_asientos_disponibles + 1
    where id_vuelo = v_id_vuelo;

    return true;
end;
$$ language plpgsql;

