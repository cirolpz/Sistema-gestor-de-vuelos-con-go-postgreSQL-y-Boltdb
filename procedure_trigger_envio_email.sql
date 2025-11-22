create or replace function tg_enviar_email() returns trigger as $$
declare
	v_id_email int;
	v_asunto text;
	v_cuerpo text := '';                                        
	v_origen aeropuerto%rowtype;
	v_destino aeropuerto%rowtype;
	v_ruta ruta%rowtype;
	v_vuelo vuelo%rowtype;
	v_cliente cliente%rowtype;
begin
	select coalesce(max(id_email),0)+1 into v_id_email from envio_email;

    -- Asunto según el estado nuevo
	v_asunto := case new.estado
		when 'reservado'  then 'CheapFlights - reserva de pasaje'
		when 'confirmado' then 'CheapFlights - check-in de asiento'
		when 'anulado'    then 'CheapFlights - anulación de reserva'
	end;

    --Traer datos
	select * into v_cliente from cliente where id_cliente = new.id_cliente;
	select * into v_vuelo from vuelo where id_vuelo = new.id_vuelo;
	select * into v_ruta from ruta where nro_ruta = v_vuelo.nro_ruta;
	select * into v_origen from aeropuerto where id_aeropuerto = v_ruta.id_aeropuerto_origen;
	select * into v_destino from aeropuerto where id_aeropuerto = v_ruta.id_aeropuerto_destino;
	
	v_cuerpo := v_cuerpo || 'Hola ' || v_cliente.nombre || ' ' || v_cliente.apellido || E'\n\n';
	v_cuerpo := v_cuerpo || 'Detalles del vuelo:' || E'\n' ||               -- ← E'\n'
            'ID Reserva: ' || new.id_reserva || E'\n' ||
            'ID Vuelo: ' || new.id_vuelo || E'\n' ||
            'Origen: ' || v_origen.nombre || ' (' || v_origen.id_aeropuerto || ') - ' || v_origen.localidad || ', ' || v_origen.provincia || E'\n' ||
            'Destino: ' || v_destino.nombre || ' (' || v_destino.id_aeropuerto || ') - ' || v_destino.localidad || ', ' || v_destino.provincia || E'\n' ||
            'Fecha salida: ' || v_vuelo.fecha_salida || E'\n' ||
            'Hora salida: ' || v_vuelo.hora_salida || E'\n';

	-- Solo agregar número de asiento si es check-in
	if new.estado = 'confirmado' then
	    v_cuerpo := v_cuerpo || E'\n' || 'Número de asiento: ' || new.nro_asiento;
	end if;
	v_cuerpo := v_cuerpo || E'\n\n';

	insert into envio_email(id_email, f_generacion, email_cliente, asunto, cuerpo, f_envio, estado) 
	values (v_id_email, now(), v_cliente.email, v_asunto, v_cuerpo, null, 'pendiente');

	return new;
end;
$$ language plpgsql;

create or replace trigger tg_enviar_email_on_insert
after insert on reserva_pasaje
for each row
when (new.estado = 'reservado')
execute function tg_enviar_email();

create or replace trigger tg_enviar_email_on_update
after update on reserva_pasaje
for each row
when (new.estado in ('confirmado', 'anulado') and old.estado != new.estado )
execute function tg_enviar_email();