alter table cliente add constraint cliente_pk primary key (id_cliente);
alter table aeropuerto add constraint aeropuerto_pk primary key (id_aeropuerto);
alter table ruta  add constraint ruta_pk primary key (nro_ruta);
alter table vuelo  add constraint vuelo_pk primary key (id_vuelo);
alter table reserva_pasaje  add constraint reserva_pasaje_pk primary key (id_reserva);
alter table error  add constraint error_pk primary key (id_error);
alter table envio_email add constraint envio_email_pk primary key (id_email);
alter table datos_de_prueba add constraint datos_de_prueba_pk primary key (id_orden);

-- ruta -> aeropurto
alter table ruta add constraint ruta_origen_fk foreign key (id_aeropuerto_origen) references aeropuerto(id_aeropuerto);
alter table ruta add constraint ruta_destino_fk foreign key (id_aeropuerto_destino) references  aeropuerto(id_aeropuerto);
-- vuelo -> ruta
alter table vuelo add constraint vuelo_ruta_fk foreign key (nro_ruta) references  ruta(nro_ruta);
-- reserva_pasaje -> vuelo
alter table reserva_pasaje add constraint reserva_vuelo_fk foreign key (id_vuelo) references vuelo(id_vuelo);
-- reserva_pasaje -> cliente
alter table reserva_pasaje add constraint reserva_cliente_fk foreign key (id_cliente) references cliente(id_cliente);
