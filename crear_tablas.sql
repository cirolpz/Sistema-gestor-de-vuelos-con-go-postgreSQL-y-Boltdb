
create table aeropuerto (
		id_aeropuerto char(3),
		nombre text,
		localidad text,
		provincia text
);

create table ruta (
		nro_ruta int, 
		id_aeropuerto_origen char(3), 
		id_aeropuerto_destino char(3), 
		duracion interval
);

create table vuelo (
		id_vuelo int, 
		nro_ruta int, 
		fecha_salida date, 
		hora_salida time, 
		nro_asientos_totales int, 
		nro_asientos_disponibles int
);

create table  reserva_pasaje(
		id_reserva int, 
		id_vuelo int, 
		id_cliente int, 
		f_reserva timestamp, 
		nro_asiento int, 
		f_check_in timestamp, 
		estado char(10)
);

create table cliente (
		id_cliente int, 
		nombre text, 
		apellido text, 
		dni int, 
		fecha_nacimiento date, 
		telefono char(12), 
		email text
);

create table error (
		id_error int, 
		operacion char(10), 
		nro_ruta int, 
		f_salida_vuelo timestamp, 
		nro_asientos_totales int, 
		id_vuelo int, 
		id_reserva int, 
		id_cliente int, 
		nro_asiento int, 
		f_error timestamp, 
		motivo varchar(80)
);

create table envio_email (
		id_email int, 
		f_generacion timestamp, 
		email_cliente text, 
		asunto text, 
		cuerpo text, 
		f_envio timestamp, 
		estado char(10)
);

create table datos_de_prueba (
		id_orden int, 
		operacion char(10), 
		nro_ruta int, 
		f_salida_vuelo timestamp, 
		nro_asientos_totales int, 
		id_vuelo int , 
		id_cliente int, 
		id_reserva int, 
		nro_asiento int
);
