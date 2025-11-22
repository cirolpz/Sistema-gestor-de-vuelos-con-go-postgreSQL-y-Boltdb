package main

import (
	"database/sql"
    "fmt"
	"os"
   _ "github.com/lib/pq"
	"log"
	bolt "go.etcd.io/bbolt"
	
)

const tpDBName = "gomez_lopez_ramos_scabini_db1"
var db *sql.DB
func main() {
	db = connectToDB(tpDBName)
	defer db.Close()
	var opcion int = -1
	for {
        fmt.Println("\n##############################################")
        fmt.Println("#          SELECCIONE UNA OPCIÓN             #")
        fmt.Println("##############################################")
        fmt.Println("#  [1] : CREAR BD                            #")
        fmt.Println("#  [2] : CREAR TABLAS                        #")
        fmt.Println("#  [3] : AGREGAR PKs y FKs                   #")
        fmt.Println("#  [4] : ELIMINAR PKs y FKs                  #")
        fmt.Println("#  [5] : CARGAR DATOS                        #")
        fmt.Println("#  [6] : CREAR STORED PROCEDURES Y TRIGGERS  #")
        fmt.Println("#  [7] : INICIAR PRUEBAS                     #")
        fmt.Println("#  [8] : CARGAR DATOS DE BOLTDB              #")
        fmt.Println("#  [0] : SALIR                               #")
        fmt.Println("##############################################")
        fmt.Print("→ ")
        fmt.Scan(&opcion)

        switch opcion {
        case 0:
            fmt.Println("[OK] Ha salido!")
            return
        case 1:
            tmp := connectToDB("postgres")
            deleteDB(tmp)
            createDB(tmp)
            tmp.Close()
        case 2:
            createTables(db)
        case 3:
			removeKeysToDB(db)
            addKeysToDB(db)
        case 4:
            removeKeysToDB(db)
        case 5:
            insertToDB(db)
        case 6:
            runStoreProceduresAndTriggers(db,"procedure_apertura_vuelo.sql")
            runStoreProceduresAndTriggers(db,"procedure_reserva_pasaje.sql")
            runStoreProceduresAndTriggers(db,"procedure_check_in_asiento.sql")
            runStoreProceduresAndTriggers(db,"procedure_anulacion_reserva.sql")
            runStoreProceduresAndTriggers(db,"procedure_trigger_envio_email.sql")
        case 7:
            runTests(db)
        case 8:
            insertToDBFromBoltDB()
        default:
            fmt.Println("INGRESE UNA OPCIÓN VÁLIDA")
        }
    }
}

func readSQLFile(filename string) string {
	data, err := os.ReadFile(filename)
	if err != nil {
		if os.IsNotExist(err) {
			log.Fatalf("[x ERROR] No se encontro el archivo %s", filename)
		} else {
			log.Fatalf("[X ERROR] No se pudo leer el archivoo %s: %v", filename, err)
		}
	}
	return string(data)
}

func connectToDB(dbName string) *sql.DB{
    db, err := sql.Open("postgres", "user=postgres host=localhost dbname="+ dbName +" sslmode=disable")
	if err != nil {
        log.Fatal(err)
		fmt.Println("[X ERROR] No se pudo crear la base de datos")
    }
	fmt.Println("[OK] BD conectada! - "+dbName+"")
	return db
}

func deleteDB(db *sql.DB){
	_, err := db.Exec( "drop database if exists "+ tpDBName +"")
    if err != nil {
        log.Fatal("[X ERROR] No se pudo eliminar la base de datos: "+  tpDBName + "", err)
    }
    fmt.Println("[OK] Base de datos eliminada (si existía)! - " + tpDBName +"")
}

func createDB(db *sql.DB) {
    _, err := db.Exec("create database " + tpDBName +"")
    if err != nil {
        log.Fatal(err)
		fmt.Println("[X ERROR] No se pudo crear la base de datos - " + tpDBName +"")
    } else{
		fmt.Println("[OK] Creación exitosa de la base de datos - " + tpDBName +"")
	}
}

func createTables(db *sql.DB){
    sql := readSQLFile("crear_tablas.sql")
    _, err := db.Exec(sql)
    if err != nil {
        log.Fatal("[X ERROR] No se pudo crear las tablas ", err)
    }
    fmt.Println("[OK] Tablas creadas!")
}

func addKeysToDB(db *sql.DB){
    sql := readSQLFile("crear_claves.sql")
    _, err := db.Exec(sql)
    if err != nil {
        log.Fatal("[X ERROR] No se pudo agregar las claves ", err)
    }
    fmt.Println("[OK] Claves agregadas!")
}

func removeKeysToDB(db *sql.DB){
    sql := readSQLFile("borrar_claves.sql")
    _, err := db.Exec(sql)
    if err != nil {
        log.Fatal("[X ERROR] No se pudo eliminar las keys ", err)
    }
    fmt.Println("[OK] keys eliminadas!")
}

func insertToDB(db *sql.DB){
    sql := readSQLFile("insertar_datos_json.sql")
    _, err := db.Exec(sql)
    if err != nil {
        log.Fatal("[X ERROR] No se pudo insertaar los datos", err)
    }
    fmt.Println("[OK] Datos cargados!")
}

func runStoreProceduresAndTriggers(db *sql.DB, procedureFileName string) {
    sql := readSQLFile(procedureFileName)
    _, err := db.Exec(sql)
    if err != nil {
        log.Fatal("[X ERROR] No se pudo ejecutar los Store procedures & triggers "+ procedureFileName +" ", err)
    }
    fmt.Println("[OK] Store procedures & triggers ejecutados! - " + procedureFileName +" ")
}

func runTests(db *sql.DB){
    sql := readSQLFile("tests.sql")
    _, err := db.Exec(sql)
    if err != nil {
        log.Fatal("[X ERROR] No se pudo ejecutar los tests ", err)
    }
	fmt.Println("[OK] Test ejecutados!")
}

func insertToDBFromBoltDB() {
    // Abrir BoltDB
    boltDB, err := bolt.Open("tp_db1_bolt.db", 0600, nil)
    if err != nil {
        log.Fatal("[X ERROR] No se pudo abrir la base BoltDB: ", err)
    }
    defer boltDB.Close()

    // Exportar CLIENTES
    if err := ExportClientes(db, boltDB); err != nil {
        log.Fatal("[X ERROR] No se pudieron exportar clientes a BoltDB: ", err)
    }

    // Exportar AEROPUERTOS
    if err := ExportAeropuertos(db, boltDB); err != nil {
        log.Fatal("[X ERROR] No se pudieron exportar aeropuertos a BoltDB: ", err)
    }

    //  Exportar RUTAS
    if err := ExportRutas(db, boltDB); err != nil {
        log.Fatal("[X ERROR] No se pudieron exportar rutas a BoltDB: ", err)
    }

    //  Exportar VUELOS
    if err := ExportVuelos(db, boltDB); err != nil {
        log.Fatal("[X ERROR] No se pudieron exportar vuelos a BoltDB: ", err)
    }

    // Exportar RESERVAS
     if err := ExportReservasReservadas(db, boltDB); 
     err != nil {
        log.Fatal("[X ERROR] No se pudieron exportar reservas reservadas a BoltDB: ", err)
    }

     if err := ExportReservasConfirmadas(db, boltDB); err != nil {
         log.Fatal("[X ERROR] No se pudieron exportar reservas confirmadas a BoltDB: ", err)
    }
        
	MostrarContenidoBolt(boltDB)
	
    fmt.Println("[OK] Datos cargados en BoltDB (clientes, aeropuertos, rutas, vuelos y reservas)!")
}
