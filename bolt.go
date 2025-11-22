package main

import(
	"database/sql"
	"encoding/json"
	"strconv"
	"fmt"
	bolt "go.etcd.io/bbolt"
)
//estructura para serializar de json a boltdb
type Cliente struct {
    IDCliente       int    `json:"id_cliente"`
    Nombre          string `json:"nombre"`
    Apellido        string `json:"apellido"`
    DNI             int    `json:"dni"`
    FechaNacimiento string `json:"fecha_nacimiento"`
    Telefono        string `json:"telefono"`
    Email           string `json:"email"`
}

type Aeropuerto struct {
    IDAeropuerto string `json:"id_aeropuerto"`
    Nombre       string `json:"nombre"`
    Localidad    string `json:"localidad"`
    Provincia    string `json:"provincia"`
}

type Ruta struct {
    NroRuta            int    `json:"nro_ruta"`
    AeropuertoOrigen   string `json:"aeropuerto_origen"`
    AeropuertoDestino  string `json:"aeropuerto_destino"`
    Duracion           string `json:"duracion"`
}

type Vuelo struct {
    IDVuelo              int    `json:"id_vuelo"`
    NroRuta              int    `json:"nro_ruta"`
    FechaSalida          string `json:"fecha_salida"`
    HoraSalida           string `json:"hora_salida"`
    AsientosTotales      int    `json:"asientos_totales"`
    AsientosDisponibles  int    `json:"asientos_disponibles"`
}

type Reserva struct {
    IDReserva    int    `json:"id_reserva"`
    IDVuelo      int    `json:"id_vuelo"`
    IDCliente    int    `json:"id_cliente"`
    FechaReserva string `json:"f_reserva"`
    NroAsiento   int   `json:"nro_asiento"`     
    FechaCheckIn string `json:"f_check-in"` 
    Estado       string `json:"estado"`
}

//crea / actualiza una clave en un bucket(tabla)
func CreateUpdate(db *bolt.DB, bucketName string, key []byte, val []byte) error {
    // abre transacción de escritura
    tx, err := db.Begin(true)
    if err != nil {
        return err
    }
    defer tx.Rollback()
    b, _ := tx.CreateBucketIfNotExists([]byte(bucketName))
    err = b.Put(key, val)
    if err != nil {
        return err
    }
    // cierra transacción
    if err := tx.Commit(); err != nil {
        return err
    }
    return nil
}

func MostrarContenidoBolt(db *bolt.DB) error {
	//abre una transaccion de lectura
    err:= db.View(func(tx *bolt.Tx) error {
        //tx.foreach recorro todos los buckets de la base de bolt y te devuelve el nombre y lo que contiene
        return tx.ForEach(func(bucketName []byte, b *bolt.Bucket) error {
            //se imprime el nombre del bucket
            fmt.Printf("\n=== BUCKET: %s ===\n", bucketName)
            //se recorre todos lo que contiene el buckets con b.foreach b=contien el bucket en si
            return b.ForEach(func(k, v []byte) error {
                //imprime clave y valor que hay dentro de cada bucket
                fmt.Printf("key: %s\nvalue: %s\n\n", k, v)
                return nil
            })
        })
    })
    return err
}



func ExportClientes(pg *sql.DB, boltDB *bolt.DB) error {
    rows, err := pg.Query(`select id_cliente, nombre, apellido, dni, fecha_nacimiento, telefono, email from cliente`)
    if err != nil { 
		return err 
		}
    defer rows.Close()

    for rows.Next() {
        var c Cliente
        if err := rows.Scan(&c.IDCliente, &c.Nombre, &c.Apellido, &c.DNI, &c.FechaNacimiento, &c.Telefono, &c.Email); 
        err != nil {
            return err
        }

        key := []byte(strconv.Itoa(c.IDCliente))
        val, _ := json.Marshal(c)

        if err := CreateUpdate(boltDB, "clientes", key, val); 
        err != nil {
            return err
        }
    }
    return nil
}

func ExportAeropuertos(pg *sql.DB, boltDB *bolt.DB) error {
    rows, err := pg.Query(`select id_aeropuerto, nombre, localidad, provincia from aeropuerto`)
    if err != nil { 
		return err 
		}
    defer rows.Close()

    for rows.Next() {
        var a Aeropuerto
        if err := rows.Scan(&a.IDAeropuerto, &a.Nombre, &a.Localidad, &a.Provincia);
        err != nil {
            return err
        }

        key := []byte(a.IDAeropuerto)
        val, _ := json.Marshal(a)

        if err := CreateUpdate(boltDB, "aeropuertos", key, val); 
        err != nil {
            return err
        }
    }
    return nil
}
func ExportRutas(pg *sql.DB, boltDB *bolt.DB) error {
    rows, err := pg.Query(`select nro_ruta, id_aeropuerto_origen, id_aeropuerto_destino, duracion from ruta`)
    if err != nil { 
		return err 
		}
    defer rows.Close()

    for rows.Next() {
        var r Ruta
        if err := rows.Scan(&r.NroRuta, &r.AeropuertoOrigen, &r.AeropuertoDestino, &r.Duracion); 
        err != nil {
            return err
        }

        key := []byte(strconv.Itoa(r.NroRuta))
        val, _ := json.Marshal(r)

        if err := CreateUpdate(boltDB, "rutas", key, val); 
        err != nil {
            return err
        }
    }
    return nil
}

func ExportVuelos(pg *sql.DB, boltDB *bolt.DB) error {
    rows, err := pg.Query(`select id_vuelo, nro_ruta, fecha_salida, hora_salida, nro_asientos_totales, nro_asientos_disponibles from vuelo limit 3`)
    if err != nil { 
		return err 
		}
    defer rows.Close()

    for rows.Next() {
        var v Vuelo
        if err := rows.Scan(&v.IDVuelo, &v.NroRuta, &v.FechaSalida, &v.HoraSalida,&v.AsientosTotales, &v.AsientosDisponibles); 
        err != nil {
            return err
        }

        key := []byte(strconv.Itoa(v.IDVuelo))
        val, _ := json.Marshal(v)

        if err := CreateUpdate(boltDB, "vuelos", key, val); 
        err != nil {
            return err
        }
    }
    return nil
}

func ExportReservasReservadas(pg *sql.DB, boltDB *bolt.DB) error {
    rows, err := pg.Query(`select id_reserva, id_vuelo, id_cliente, f_reserva, coalesce (nro_asiento,0), coalesce (f_check_in::text,''), estado from reserva_pasaje where estado = 'reservado' limit 2`)
    if err != nil {
        return err
    }
    defer rows.Close()

    for rows.Next() {
        var r Reserva
        if err := rows.Scan(&r.IDReserva, &r.IDVuelo, &r.IDCliente, &r.FechaReserva, &r.NroAsiento, &r.FechaCheckIn, &r.Estado); 
        err != nil {
            return err
        }
        key := []byte(strconv.Itoa(r.IDReserva))
        val, err := json.Marshal(r)
        if err != nil {
            return err
        }

        if err := CreateUpdate(boltDB, "reservas_reservadas", key, val); 
        err != nil {
            return err
        }
    }
    return nil
}

func ExportReservasConfirmadas(pg *sql.DB, boltDB *bolt.DB) error {
    rows, err := pg.Query(`select id_reserva, id_vuelo, id_cliente, f_reserva, nro_asiento, f_check_in, estado from reserva_pasaje where nro_asiento is not null limit 3`)
    if err != nil {
        return err
    }
    defer rows.Close()

    for rows.Next() {
        var r Reserva
        // r es una variable de tipo Reserva 
        if err := rows.Scan( &r.IDReserva, &r.IDVuelo, &r.IDCliente, &r.FechaReserva, &r.NroAsiento, &r.FechaCheckIn, &r.Estado); 
            err != nil {
            return err
        }

        // key usamos el id_reserva como clave 
        key := []byte(strconv.Itoa(r.IDReserva))

        // val el struct Reserva serializado a JSON
        val, err := json.Marshal(r)
        if err != nil {
            return err
        }

        if err := CreateUpdate(boltDB, "reservas_confirmadas", key, val); err != nil {
            return err
        }
    }
    return nil
}
