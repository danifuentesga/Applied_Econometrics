/****************************************************************************************** AUTOR:   Daniel Fuentes (Github: danifuentesga )
* FECHA:   6-sep-2025
* TEMA:    Homologación de bases de datos ENIGH (1992-2024)
* NOTA:    Se trabaja principamente con bases de "CONCENTRADO" Y "POBLACION" de cada año
******************************************************************************************/

***      No hay merge que dure cien años, ni error que lo resista. ****


**************************************************************************
               //#GLOBALS      
**************************************************************************

* Definir ruta principal del proyecto donde están los datos del IMSS
global ENIGH "D:\INVESTIGACION\DATA\ENIGH"

* Ruta de destino de graficas
global graf "D:\INVESTIGACION\DATA\ENIGH\GRAFS_PS_2"


***************************************************************************

                          //# LIMPIEZA ENIGH
					 
***************************************************************************

***************************************************************************

                  //## CONCENTRADOS.dta 1992 A 2024

***************************************************************************	

//======================================================
//### PASO 1: Definir años a procesar (1992-2002)
//======================================================
local anios 1992 1994 1996 1998 2000 2002


//======================================================
//### PASO 2: Loop sobre cada año
//======================================================
foreach x of local anios {

    //--- Abrimos la base original de ese año
    use "$ENIGH/`x'/concentrado_`x'.dta", clear

    //--- Nos quedamos con las variables clave
    keep folio ubica_geo estrato hog edad n_ocup

    //--- Generamos variable year con el valor del año correspondiente
    gen year = `x'

    //--- Homologamos nombres de variables
    rename (folio ubica_geo estrato hog edad n_ocup) ///
           (foliohog ubica_geo tam_loc factor edad_jefe ocupados)

    //--- Creamos folio = foliohog para consistencia
    gen folio = foliohog

    //--- Convertimos a string
    // Nota: en 1992 y 1994 no se incluye foliohog
    if inlist(`x',1992,1994) {
        quietly tostring folio ubica_geo tam_loc year ///
                         factor edad_jefe ocupados, replace
    }
    else {
        quietly tostring folio foliohog ubica_geo tam_loc year ///
                         factor edad_jefe ocupados, replace
    }

    //--- Guardamos con nombre claro en mayúsculas
    save "$ENIGH/`x'/CONCENTRADO_HOM_`x'.dta", replace
}


//======================================================
//### PASO 3: Definir años a procesar (2004–2006)
//======================================================
local anios 2004 2005 2006


//======================================================
//### PASO 4: Loop sobre cada año
//======================================================
foreach x of local anios {

    //--- Abrimos la base original
    use "$ENIGH/`x'/concentrado_`x'.dta", clear

    //--- Nos quedamos con las variables clave (ahora incluyen ed_formal)
    keep folio ubica_geo estrato hog edad ed_formal n_ocup

    //--- Generamos variable year
    gen year = `x'

    //--- Homologamos nombres de variables
    rename (folio ubica_geo estrato hog edad ed_formal n_ocup) ///
           (foliohog ubica_geo tam_loc factor edad_jefe ocupados educa_jefe)

    //--- Creamos folio = foliohog
    gen folio = foliohog

    //--- Convertimos a string (incluyendo educa_jefe)
    quietly tostring folio foliohog ubica_geo year ///
                     tam_loc factor edad_jefe ocupados educa_jefe, replace

    //--- Guardamos con nombre claro en mayúsculas
    save "$ENIGH/`x'/CONCENTRADO_HOM_`x'.dta", replace
}


//======================================================
//### PASO 5: Definir años a procesar (2008–2010)
//======================================================
local anios 2008 2010


//======================================================
//### PASO 6: Loop sobre 2008 y 2010
//======================================================

// Definimos los años a procesar
local anios 2008 2010

foreach x of local anios {

    //--- Abrimos la base original
    use "$ENIGH/`x'/concentrado_`x'.dta", clear

    //--- Variables clave (2008 trae estrato, 2010 trae tam_loc)
    if `x'==2008 {
        keep foliohog folioviv ubica_geo estrato factor sexo edad ed_formal n_ocup
        gen year = 2008
        rename (estrato factor sexo edad ed_formal n_ocup) ///
               (tam_loc factor sexo_jefe edad_jefe educa_jefe ocupados)
    }
    else if `x'==2010 {
        keep foliohog folioviv ubica_geo tam_loc factor sexo edad ed_formal n_ocup
        gen year = 2010
        rename (tam_loc factor sexo edad ed_formal n_ocup) ///
               (tam_loc factor sexo_jefe edad_jefe educa_jefe ocupados)
    }

    //--- Quitar value labels en las variables de interés
    foreach v of varlist foliohog folioviv tam_loc factor sexo_jefe edad_jefe educa_jefe ocupados year {
        capture label values `v'
    }

    //--- Convertir todas a string
    tostring foliohog folioviv tam_loc factor sexo_jefe edad_jefe educa_jefe ocupados year, replace

    //--- Crear identificador folio concatenando vivienda+hogar
    gen folio = folioviv + foliohog

    //--- Guardar base procesada
    save "$ENIGH/`x'/CONCENTRADO_HOM_`x'.dta", replace
}


//======================================================
//### PASO 7: Definir años a procesar (2012–2024)
//======================================================
local anios 2012 2014 2016 2018 2020 2022 2024


//======================================================
//### PASO 8: Loop sobre cada año
//======================================================
foreach x of local anios {

    //--- Abrimos la base original
    use "$ENIGH/`x'/concentrado_`x'.dta", clear

    //--- Condiciones especiales 2012 y 2014 (factor_hog → factor)
    if inlist(`x',2012,2014) {
        keep foliohog folioviv ubica_geo tam_loc factor_hog sexo_jefe edad_jefe educa_jefe ocupados
        gen year = `x'
        rename factor_hog factor
    }
    else {
        keep foliohog folioviv ubica_geo tam_loc factor sexo_jefe edad_jefe educa_jefe ocupados
        gen year = `x'
    }

    //--- Convertimos a string
    tostring foliohog folioviv ubica_geo tam_loc factor sexo_jefe edad_jefe educa_jefe ocupados year, replace

    //--- Creamos folio concatenando vivienda+hogar
    gen folio = folioviv + foliohog

    //--- Guardamos con nombre claro en mayúsculas
    save "$ENIGH/`x'/CONCENTRADO_HOM_`x'.dta", replace
}


****************************************************************************

                 //## POBLACION .dta HOMOLOGACIÓN (1992 -204)
				
****************************************************************************

//======================================================
//### PASO 1: Homologación Población 1992–1994
//======================================================

//---- 1992 ----
use "$ENIGH/1992/poblacion_1992.dta", clear

// Variables de horas trabajadas a numéricas
destring hr_semana hr_sem_sec, replace

// Renombramos variables para homologar
rename (numren edad sexo ed_formal trab_m_p) ///
       (numren edad sexo nivelaprob trabajo_mp)

// Creamos horas totales trabajadas
gen htrab = hr_semana + hr_sem_sec

// Creamos variable year
gen year = 1992

// Nos quedamos con las variables clave
keep folio numren edad sexo nivelaprob trabajo_mp year htrab

// Convertimos a string
tostring folio numren edad sexo nivelaprob trabajo_mp htrab year, replace

// Guardamos con nombre claro
save "$ENIGH/1992/POBLACION_HOM_1992.dta", replace



//---- 1994 ----
use "$ENIGH/1994/poblacion_1994.dta", clear

// Variables de horas trabajadas a numéricas
destring hrs_sem hrs_sec, replace

// Renombramos variables para homologar
rename (num_ren edad sexo ed_formal trabajo) ///
       (numren edad sexo nivelaprob trabajo_mp)

// Creamos horas totales trabajadas
gen htrab = hrs_sem + hrs_sec

// Creamos variable year
gen year = 1994

// Nos quedamos con las variables clave
keep folio numren edad sexo nivelaprob trabajo_mp year htrab

// Convertimos a string
tostring folio numren edad sexo nivelaprob trabajo_mp htrab year, replace

// Guardamos con nombre claro
save "$ENIGH/1994/POBLACION_HOM_1994.dta", replace

//======================================================
//### PASO 2: Homologación Población 1996–2002
//======================================================
local anios 1996 1998 2000 2002

foreach x of local anios {

    //--- Abrimos la base original
    use "$ENIGH/`x'/poblacion_`x'.dta", clear

    //--- Variables de horas trabajadas a numéricas
    destring hrs_sem hrs_sec, replace

    //--- Creamos horas totales trabajadas
    gen htrab = hrs_sem + hrs_sec

    //--- Renombramos variables
    rename (num_ren edad sexo ed_formal trabajo edo_civil) ///
           (numren edad sexo nivelaprob trabajo_mp edo_conyug)

    //--- Creamos variable year
    gen year = `x'

    //--- Nos quedamos con variables clave
    keep folio numren edad sexo nivelaprob trabajo_mp edo_conyug year htrab

    //--- Convertimos a string
    tostring folio numren edad sexo nivelaprob trabajo_mp edo_conyug htrab year, replace

    //--- Guardamos con nombre claro en mayúsculas
    save "$ENIGH/`x'/POBLACION_HOM_`x'.dta", replace
}

//======================================================
//### PASO 4: Homologación Población 2004–2005
//======================================================

//---- 2004 ----
use "$ENIGH/2004/poblacion_2004.dta", clear

rename (num_ren edad sexo n_instr161 trabajo edocony h_sobrev horastrab n_instr162) ///
       (numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob htrab gradoaprob)

gen year = 2004

keep folio numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob year htrab gradoaprob

tostring folio numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob htrab gradoaprob year, replace

save "$ENIGH/2004/POBLACION_HOM_2004.dta", replace



//---- 2005 ----
use "$ENIGH/2005/poblacion_2005.dta", clear

rename (num_ren edad sexo n_instr161 trabajo edocony h_sobrev horas_trab) ///
       (numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob htrab)

gen year = 2005

keep folio numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob year htrab

tostring folio numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob htrab year, replace

save "$ENIGH/2005/POBLACION_HOM_2005.dta", replace

//======================================================
//### PASO 5: Homologación Población 2006
//======================================================

use "$ENIGH/2006/poblacion_2006.dta", clear

// Renombramos variables
rename (num_ren edad sexo n_instr141 trabajo edocony h_sobrev horas_trab n_instr142) ///
       (numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob htrab gradoaprob)

// Generamos variable year
gen year = 2006

// Nos quedamos con las variables clave
keep folio numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob year htrab gradoaprob

// Convertimos a string
tostring folio numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob htrab gradoaprob year, replace

// Guardamos con nombre claro en mayúsculas
save "$ENIGH/2006/POBLACION_HOM_2006.dta", replace

//======================================================
//### PASO 6: Homologación Población 2008–2010
//======================================================

//---- 2008 ----
use "$ENIGH/2008/poblacion_2008.dta", clear

rename (foliohog folioviv numren edad sexo n_instr161 trabajo edocony hijos_sob) ///
       (foliohog folioviv numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob)

gen year = 2008

// Quitar value labels en las variables clave
foreach v of varlist foliohog folioviv numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob year {
    capture label values `v'
}

// Convertimos todas a string
tostring *, replace

// Creamos folio concatenando vivienda y hogar
gen folio = folioviv + foliohog

// Nos quedamos con variables clave
keep folio numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob year

// Guardamos
save "$ENIGH/2008/POBLACION_HOM_2008.dta", replace


//---- 2010 ----
use "$ENIGH/2010/poblacion_2010.dta", clear

rename (foliohog folioviv numren edad sexo nivelaprob trabajo edocony hijos_sob) ///
       (foliohog folioviv numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob)

gen year = 2010

// Quitar value labels en las variables clave
foreach v of varlist foliohog folioviv numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob year {
    capture label values `v'
}

// Convertimos todas a string
tostring *, replace

// Creamos folio concatenando vivienda y hogar
gen folio = folioviv + foliohog

// Nos quedamos con variables clave
keep folio numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob year

// Guardamos
save "$ENIGH/2010/POBLACION_HOM_2010.dta", replace

//======================================================
//### PASO 7: Homologación Población 2012–2024
//======================================================
forvalues x = 2012(2)2024 {

    //--- Abrimos la base original
    use "$ENIGH/`x'/poblacion_`x'.dta", clear

    //--- Convertimos todas las variables a string
    tostring *, replace

    //--- Creamos folio concatenando vivienda y hogar
    gen folio = folioviv + foliohog

    //--- Generamos variable year
    gen year = `x'

    //--- Nos quedamos con variables clave
    keep folio numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob year gradoaprob

    //--- Guardamos con nombre claro en mayúsculas
    save "$ENIGH/`x'/POBLACION_HOM_`x'.dta", replace
}


*************************************************************************

                     //## INGRESOS.dta  HOMOLOGACION
			
**************************************************************************

//======================================================
//### PASO 1: Homologación Ingresos 1992
//======================================================
use "$ENIGH/1992/ingresos_1992.dta", clear

//--- Nos quedamos solo con claves relevantes
keep if inlist(clave, "P001", "P002", "P004", "P006")

//--- Homologamos variable de ingreso
rename ing_mp ing_1

//--- Generamos variable year
gen year = 1992

//--- Nos quedamos con variables clave
keep ing_tri ing_1 folio numren clave year

//--- Convertimos variables a string para consistencia
tostring folio numren year, replace

//--- Colapsamos sumando ingresos por folio, numren y año
collapse (sum) ing_1 ing_tri, by(folio numren year)

//--- Guardamos con nombre claro en mayúsculas
save "$ENIGH/1992/INGRESOS_HOM_1992.dta", replace

//======================================================
//### PASO 2: Homologación Ingresos 1994
//======================================================
use "$ENIGH/1994/ingresos_1994.dta", clear

//--- Nos quedamos solo con claves relevantes
keep if inlist(clave, "P001", "P002", "P004", "P014")

//--- Homologamos variables
rename (num_ren ing1) (numren ing_1)

//--- Generamos variable year
gen year = 1994

//--- Nos quedamos con variables clave
keep ing_tri ing_1 folio numren clave year

//--- Convertimos a string para consistencia
tostring folio numren year, replace

//--- Colapsamos sumando ingresos por folio, numren y año
collapse (sum) ing_1 ing_tri, by(folio numren year)

//--- Guardamos con nombre claro en mayúsculas
save "$ENIGH/1994/INGRESOS_HOM_1994.dta", replace

//======================================================
//### PASO 3: Homologación Ingresos 1996
//======================================================
use "$ENIGH/1996/ingresos_1996.dta", clear

//--- Nos quedamos solo con claves relevantes
keep if inlist(clave, "P001", "P002", "P004", "P014")

//--- Homologamos variables
rename (num_ren ing1) (numren ing_1)

//--- Generamos variable year
gen year = 1996

//--- Nos quedamos con variables clave
keep ing_tri ing_1 folio numren clave year

//--- Convertimos a string para consistencia
tostring folio numren year, replace

//--- Colapsamos sumando ingresos por folio, numren y año
collapse (sum) ing_1 ing_tri, by(folio numren year)

//--- Guardamos con nombre claro en mayúsculas
save "$ENIGH/1996/INGRESOS_HOM_1996.dta", replace

//======================================================
//### PASO 4: Homologación Ingresos 1998
//======================================================
use "$ENIGH/1998/ingresos_1998.dta", clear

//--- Nos quedamos solo con claves relevantes
keep if inlist(clave, "P001", "P002", "P003", "P004", "P006", "P008", "P018")

//--- Homologamos num_ren a numren
rename num_ren numren

//--- Generamos variable year
gen year = 1998

//--- Nos quedamos con variables clave
keep ing_tri ing_1 folio numren clave year

//--- Convertimos a string para consistencia
tostring folio numren year, replace

//--- Colapsamos sumando ingresos por folio, numren y año
collapse (sum) ing_1 ing_tri, by(folio numren year)

//--- Guardamos con nombre claro en mayúsculas
save "$ENIGH/1998/INGRESOS_HOM_1998.dta", replace

//======================================================
//### PASO 5: Homologación Ingresos 2000
//======================================================
use "$ENIGH/2000/ingresos_2000.dta", clear

//--- Nos quedamos con variables necesarias antes del filtro
keep ing_tri ing_1 folio num_ren clave

//--- Generamos variable year
gen year = 2000

//--- Nos quedamos solo con claves relevantes
keep if inlist(clave, "P001", "P002", "P003", "P004", "P006", "P008", "P018")

//--- Homologamos num_ren a numren
rename num_ren numren

//--- Convertimos a string
tostring folio numren year, replace

//--- Colapsamos sumando ingresos por folio, numren y año
collapse (sum) ing_1 ing_tri, by(folio numren year)

//--- Guardamos con nombre claro en mayúsculas
save "$ENIGH/2000/INGRESOS_HOM_2000.dta", replace

//======================================================
//### PASO 6: Homologación Ingresos 2002
//======================================================
use "$ENIGH/2002/ingresos_2002.dta", clear

//--- Nos quedamos con variables necesarias antes del filtro
keep ing_tri ing_1 folio num_ren clave

//--- Generamos variable year
gen year = 2002

//--- Nos quedamos solo con claves relevantes (Stata permite máx 10 en inlist)
keep if inlist(clave, "P001", "P002", "P003", "P004", "P006", "P007", "P008", "P018") ///
    | inlist(clave, "P020", "P022")

//--- Homologamos num_ren a numren
rename num_ren numren

//--- Convertimos a string
tostring folio numren year, replace

//--- Colapsamos sumando ingresos por folio, numren y año
collapse (sum) ing_1 ing_tri, by(folio numren year)

//--- Guardamos con nombre claro en mayúsculas
save "$ENIGH/2002/INGRESOS_HOM_2002.dta", replace

//======================================================
//### PASO 7: Homologación Ingresos 2004
//======================================================
use "$ENIGH/2004/ingresos_2004.dta", clear

//--- Nos quedamos con variables necesarias antes del filtro
keep ing_tri ing_1 folio num_ren clave

//--- Generamos variable year
gen year = 2004

//--- Nos quedamos solo con claves relevantes (dividimos porque son más de 10)
keep if inlist(clave, "P001", "P002", "P003", "P004", "P006", "P007", "P008", "P017") ///
    | inlist(clave, "P019", "P029")

//--- Homologamos num_ren a numren
rename num_ren numren

//--- Convertimos a string
tostring folio numren year, replace

//--- Colapsamos sumando ingresos por folio, numren y año
collapse (sum) ing_1 ing_tri, by(folio numren year)

//--- Guardamos con nombre claro en mayúsculas
save "$ENIGH/2004/INGRESOS_HOM_2004.dta", replace

//======================================================
//### PASO 8: Homologación Ingresos 2005
//======================================================
use "$ENIGH/2005/ingresos_2005.dta", clear

//--- Conservamos variables necesarias antes del filtro
keep ing_tri ing_1 folio num_ren clave

//--- Generamos variable de año
gen year = 2005

//--- Filtramos claves relevantes (dividimos en dos grupos por límite de inlist)
keep if inlist(clave, "P001", "P002", "P003", "P004", "P006", "P007", "P008", "P017") ///
    | inlist(clave, "P019", "P029")

//--- Homologamos num_ren a numren
rename num_ren numren

//--- Convertimos a string
tostring folio numren year, replace

//--- Colapsamos sumando ingresos
collapse (sum) ing_1 ing_tri, by(folio numren year)

//--- Guardamos en versión homologada
save "$ENIGH/2005/INGRESOS_HOM_2005.dta", replace

//======================================================
//### PASO 9: Homologación Ingresos 2006
//======================================================
use "$ENIGH/2006/ingresos_2006.dta", clear

//--- Conservamos variables necesarias
keep ing_tri ing_1 folio num_ren clave

//--- Generamos variable de año
gen year = 2006

//--- Filtramos claves relevantes (idénticas a 2004 y 2005)
keep if inlist(clave, "P001", "P002", "P003", "P004", "P006", "P007", "P008", "P017") ///
    | inlist(clave, "P019", "P029")

//--- Homologamos nombre de variable
rename num_ren numren

//--- Convertimos a string
tostring folio numren year, replace

//--- Colapsamos sumando ingresos
collapse (sum) ing_1 ing_tri, by(folio numren year)

//--- Guardamos en versión homologada
save "$ENIGH/2006/INGRESOS_HOM_2006.dta", replace

//======================================================
//### PASO 10: Homologación Ingresos 2008
//======================================================
use "$ENIGH/2008/ingresos_2008.dta", clear

// Convertimos identificadores a string y creamos folio único
qui tostring folioviv foliohog, replace
gen folio = folioviv + foliohog

// Generamos variable de año explícita
gen year = 2008

// Nos quedamos solo con claves relevantes (partido en grupos cortos)
keep if inlist(clave, "P001", "P002", "P003", "P004", "P005") ///
     | inlist(clave, "P006", "P007", "P011", "P015") ///
     | inlist(clave, "P018", "P020")

// Convertimos identificadores a string para uniformidad
qui tostring folio numren year, replace

// Colapsamos ingresos al nivel persona-año
collapse (sum) ing_1 ing_tri, by(folio numren year)

// Guardamos con nombre homogéneo
save "$ENIGH/2008/INGRESOS_HOM_2008.dta", replace


//======================================================
//### PASO 11: Homologación Ingresos 2010
//======================================================

use "$ENIGH/2010/ingresos_2010.dta", clear

// Convertimos identificadores a string y creamos folio único
qui tostring folioviv foliohog, replace
gen folio = folioviv + foliohog

// Generamos variable de año explícita
gen year = 2010

// Nos quedamos solo con claves relevantes (dividido en grupos cortos)
keep if inlist(clave, "P001", "P002", "P003", "P004", "P005") ///
     | inlist(clave, "P006", "P007", "P011", "P014") ///
     | inlist(clave, "P018", "P021")

// Convertimos identificadores a string
qui tostring folio numren year, replace

// Colapsamos ingresos al nivel persona-año
collapse (sum) ing_1 ing_tri, by(folio numren year)

// Guardamos con nombre homogéneo
save "$ENIGH/2010/INGRESOS_HOM_2010.dta", replace

//======================================================
//### PASO 12: Homologación Ingresos 2012–2024
//======================================================
foreach y in 2012 2014 2016 2018 2020 2022 2024 {

    // Cargar base de ingresos original
    use "$ENIGH/`y'/ingresos_`y'.dta", clear

    // Convertimos identificadores a string
    qui tostring folioviv foliohog numren, replace
    
    // Generamos variable de año explícita
    gen year = `y'

    // Creamos folio único
    gen folio = folioviv + foliohog

    // Nos quedamos con variables relevantes
    keep year folio clave ing_1 ing_tri numren

    // Filtramos claves relevantes (en grupos cortos para evitar error de línea larga)
    keep if inlist(clave, "P001", "P002", "P003", "P004", "P005") ///
         | inlist(clave, "P006", "P007", "P014", "P018") ///
         | inlist(clave, "P021")

    // Colapsamos ingresos al nivel persona-año
    collapse (sum) ing_1 ing_tri, by(folio numren year)

    // Guardamos con nombre homogéneo
    save "$ENIGH/`y'/INGRESOS_HOM_`y'.dta", replace
}


*************************************************************************

                     //## TRABAJOS.dta  HOMOLOGACION
			
**************************************************************************


//### PASO 1: Homologación TRABAJOS 2008–2024
foreach x in 2008 2010 2012 2014 2016 2018 2020 2022 2024 {

    // Cargar base original
    use "$ENIGH/`x'/trabajos_`x'.dta", clear

    // Pasar nombres a minúsculas para homogeneidad
    rename *, lower
    qui compress

    // Generamos variable de año
    gen year = `x'

    // Convertimos identificadores a string y generamos folio único
    qui tostring folioviv foliohog numren year, replace
    gen folio = folioviv + foliohog

    // Colapsamos horas trabajadas por persona-año
    collapse (sum) htrab, by(folio numren year)

    // Aseguramos consistencia en formato
    qui tostring htrab, replace
    keep folio numren htrab year

    // Guardamos con nombre homogéneo
    save "$ENIGH/`x'/TRABAJOS_HOM_`x'.dta", replace
}

*************************************************************************

                     //## MERGE 
			
**************************************************************************
 
//### PASO 1: Merge TRABAJOS + INGRESOS 2008–2024
foreach x in 2008 2010 2012 2014 2016 2018 2020 2022 2024 {

    // Cargar trabajos homologados
    use "$ENIGH/`x'/TRABAJOS_HOM_`x'.dta", clear
    order folio numren
    sort folio numren

    // Forzamos year a numérica
    destring year, replace force

    // Cargamos ingresos en memoria temporal y destring antes de merge
    tempfile ingresos
    use "$ENIGH/`x'/INGRESOS_HOM_`x'.dta", clear
    destring year, replace force
    save `ingresos'

    // Volvemos a la base de trabajos y merge con ingresos limpio
    use "$ENIGH/`x'/TRABAJOS_HOM_`x'.dta", clear
    order folio numren
    sort folio numren
    destring year, replace force
    merge 1:1 folio numren using `ingresos'

    drop if _merge == 1
    drop _merge

    save "$ENIGH/`x'/TRAB_ING_HOM_`x'.dta", replace
}


//### PASO 2: Merge INGRESOS + POBLACION 1992–2006
foreach x in 1992 1994 1996 1998 2000 2002 2004 2005 2006 {

    // Cargar ingresos homologados
    use "$ENIGH/`x'/INGRESOS_HOM_`x'.dta", clear
    order folio numren
    sort folio numren

    // Aseguramos que year sea numérica
    destring year, replace force

    // Preparamos la base de población
    tempfile poblacion
    use "$ENIGH/`x'/POBLACION_HOM_`x'.dta", clear
    destring year, replace force
    save `poblacion'

    // Volvemos a ingresos y hacemos merge 1:m
    use "$ENIGH/`x'/INGRESOS_HOM_`x'.dta", clear
    destring year, replace force
    merge 1:m folio numren using `poblacion'

    // Renombramos variable de control
    rename _merge mergeingpob

    // Guardamos resultado
    save "$ENIGH/`x'/POBLA_ING_HOM_`x'.dta", replace
}

//### PASO 3: Merge TRABAJOS+INGRESOS + POBLACION 2008–2024
foreach x in 2008 2010 2012 2014 2016 2018 2020 2022 2024 {

    // Cargar TRAB+ING homologado
    use "$ENIGH/`x'/TRAB_ING_HOM_`x'.dta", clear
    order folio numren
    sort folio numren

    // Aseguramos year numérico
    destring year, replace force

    // Preparamos población
    tempfile pobla
    use "$ENIGH/`x'/POBLACION_HOM_`x'.dta", clear
    destring year, replace force
    save `pobla'

    // Volvemos a TRAB+ING y hacemos merge
    use "$ENIGH/`x'/TRAB_ING_HOM_`x'.dta", clear
    destring year, replace force
    merge 1:m folio numren using `pobla'

    // Renombramos variable de control
    rename _merge mergeingpob

    // Guardamos resultado final
    save "$ENIGH/`x'/POBLA_ING_HOM_`x'.dta", replace
}



//### PASO 4: Merge POBLA_ING_HOM + CONCENTRADO 1992–2024
foreach x in 1992 1994 1996 1998 2000 2002 2004 2005 2006 ///
             2008 2010 2012 2014 2016 2018 2020 2022 2024 {

    // Cargar población+ingresos (ya homologada)
    use "$ENIGH/`x'/POBLA_ING_HOM_`x'.dta", clear
    order folio
    sort folio
    destring year, replace force

    // Preparamos concentrado
    tempfile conc
    use "$ENIGH/`x'/CONCENTRADO_HOM_`x'.dta", clear
    destring year, replace force
    save `conc'

    // Volvemos a la base poblacional e integramos concentrado
    use "$ENIGH/`x'/POBLA_ING_HOM_`x'.dta", clear
    destring year, replace force
    merge m:1 folio using `conc'

    // Renombramos variable de control de merge
    rename _merge mergepobcon

    // Guardamos resultado final
    save "$ENIGH/`x'/BASE_TRABAJADORES_HOM_`x'.dta", replace
}


//### PASO 5: Append de todas las bases anuales 1992–2024
use "$ENIGH/1992/BASE_TRABAJADORES_HOM_1992.dta", clear

foreach x in 1994 1996 1998 2000 2002 2004 2005 2006 ///
             2008 2010 2012 2014 2016 2018 2020 2022 2024 {

    append using "$ENIGH/`x'/BASE_TRABAJADORES_HOM_`x'.dta", force
}

// Guardamos base final consolidada
save "$ENIGH/ENIGH_TRABAJADORES_FINAL.dta", replace

//==========================================================
//### PASO INPC: Importar y procesar INPC 1992–2024
//==========================================================

// Importar el archivo de INPC (ajusta nombre real del archivo Excel)
import excel "$ENIGH/INPC_1992_2024.xlsx", firstrow clear

// Generamos el año directamente desde la fecha
gen year = year(fecha)

// Colapsamos al promedio anual
collapse (mean) INPC, by(year)

// Guardamos archivo limpio
save "$ENIGH/INPC_1992_2024.dta", replace

//==========================================================
//### PASO INPC: Merge ENIGH_TRABAJADORES_FINAL con INPC anual
//==========================================================

use "$ENIGH/ENIGH_TRABAJADORES_FINAL.dta", clear
order year
sort year

// Merge con INPC anual
merge m:1 year using "$ENIGH/INPC_1992_2024.dta"

// Eliminamos variable de control del merge
drop _merge

// Guardamos la base final con INPC incluido
save "$ENIGH/ENIGH_TRABAJADORES_FINAL.dta", replace


*************************************************************************

                     //## LIMPIEZA PARA REGRESIÓN CUANTIL
			
**************************************************************************

//==================================================
//### PASO 1: Preparación de datos para el año 2000
//==================================================
use "$ENIGH/ENIGH_TRABAJADORES_FINAL.dta", clear

// Ajuste en 2010

replace edad = edad_jefe if year == 2010

// Aseguramos que las variables clave sean numéricas
destring year nivelaprob gradoaprob htrab edad sexo tam_loc factor, replace

// Nos quedamos con población de 25 a 65 años
keep if edad >= 25 & edad <= 65

//--- Generamos años de escolaridad (anios_esc) para 2000
gen anios_esc = . 

// Sin escolaridad o primaria incompleta
replace anios_esc = 0 if (nivelaprob==1 | nivelaprob==2) & year == 2000

// Primaria completa hasta preparatoria incompleta (3 a 11 → 1° de primaria a 3° de preparatoria)
replace anios_esc = nivelaprob - 2 if inrange(nivelaprob, 3, 11) & year == 2000

// Preparatoria completa o técnica (12 y 13)
replace anios_esc = nivelaprob - 1 if inlist(nivelaprob, 12, 13) & year == 2000

// Licenciatura y posgrados (14, 15, 16)
replace anios_esc = nivelaprob + 1 if inlist(nivelaprob, 14, 15, 16) & year == 2000

//==================================================
//### PASO 2: Años de escolaridad (2004)
//==================================================

// Sin instrucción o preescolar
replace anios_esc = 0 if (nivelaprob == 0 | nivelaprob == 1) & year == 2004

// Primaria
replace anios_esc = gradoaprob if nivelaprob == 2 & year == 2004

// Secundaria
replace anios_esc = gradoaprob + 6 if nivelaprob == 3 & year == 2004

// Preparatoria / Bachillerato / Técnico medio
replace anios_esc = gradoaprob + 9 if inlist(nivelaprob, 4, 5, 6) & year == 2004

// Licenciatura
replace anios_esc = gradoaprob + 12 if nivelaprob == 7 & year == 2004

// Maestría
replace anios_esc = gradoaprob + 16 if nivelaprob == 8 & year == 2004

// Doctorado
replace anios_esc = gradoaprob + 18 if nivelaprob == 9 & year == 2004

//==========================================================
//### PASO 3: Años de escolaridad (2006)
//==========================================================

// Sin instrucción o preescolar
replace anios_esc = 0 if (nivelaprob == 0 | nivelaprob == 1) & year == 2006

// Primaria
replace anios_esc = gradoaprob if nivelaprob == 2 & year == 2006

// Secundaria
replace anios_esc = gradoaprob + 6 if nivelaprob == 3 & year == 2006

// Preparatoria / Bachillerato / Técnico medio
replace anios_esc = gradoaprob + 9 if inlist(nivelaprob, 4, 5, 6) & year == 2006

// Licenciatura
replace anios_esc = gradoaprob + 12 if nivelaprob == 7 & year == 2006

// Maestría
replace anios_esc = gradoaprob + 16 if nivelaprob == 8 & year == 2006

// Doctorado
replace anios_esc = gradoaprob + 18 if nivelaprob == 9 & year == 2006

//==========================================================
//### PASO 4: Años de escolaridad (2012–2024)
//==========================================================

// Sin instrucción o preescolar
replace anios_esc = 0 if inlist(nivelaprob, 0, 1) & inrange(year, 2012, 2024)

// Primaria
replace anios_esc = gradoaprob if nivelaprob == 2 & inrange(year, 2012, 2024)

// Secundaria
replace anios_esc = gradoaprob + 6 if nivelaprob == 3 & inrange(year, 2012, 2024)

// Preparatoria / Bachillerato / Técnico medio
replace anios_esc = gradoaprob + 9 if inlist(nivelaprob, 4, 5, 6) & inrange(year, 2012, 2024)

// Licenciatura
replace anios_esc = gradoaprob + 12 if nivelaprob == 7 & inrange(year, 2012, 2024)

// Maestría
replace anios_esc = gradoaprob + 16 if nivelaprob == 8 & inrange(year, 2012, 2024)

// Doctorado
replace anios_esc = gradoaprob + 18 if nivelaprob == 9 & inrange(year, 2012, 2024)

//==========================================================
//### PASO 5: Variables derivadas (factor horas y sexo binario)
//==========================================================

// Creamos un factor ponderado por horas trabajadas
gen fac = factor * htrab

// Variable binaria de sexo: 0 = hombres, 1 = mujeres
gen sex = sexo - 1


//==========================================================
//### PASO 6: Ajustes de ingresos
//==========================================================

// Reemplazamos ingresos inválidos (códigos de no respuesta o cero)
replace ing_tri = . if ing_tri == 999999 | ing_tri == 0

// Creamos dummy de trabajador (1 si tiene ingreso distinto de missing y > 0)
gen trabajadorv = 0
replace trabajadorv = 1 if ing_tri != . & ing_tri > 0

// Ajuste especial para el año 1992 (ingresos reportados en miles)
replace ing_tri = ing_tri/1000 if year == 1992
replace ing_1   = ing_1/1000 if year == 1992

// Eliminamos observaciones sin ingresos laborales
drop if trabajadorv == 0

//==========================================================
//### PASO 7: Ingreso real e ingreso por hora
//==========================================================

// Ingreso en términos reales (deflactado con INPC, base=100)
gen ing = (ing_tri / INPC) * 100

// Ingreso por hora trabajada
// (Ingreso real dividido entre horas trabajadas trimestrales:
// htrab * 4.33 semanas por mes * 3 meses)
gen inghrs = ing / (htrab * 4.33 * 3)

//==========================================================
//### PASO 8: Censoring y logaritmo del ingreso por hora
//==========================================================

// Truncamos ingresos por hora en los extremos
replace inghrs = 1     if inghrs <= 1     & inghrs != .
replace inghrs = 5000  if inghrs >= 5000  & inghrs != .

// Logaritmo del ingreso por hora
gen linghrs = ln(inghrs)

// Eliminamos casos inválidos
drop if linghrs == .
drop if linghrs <= 0

save "$ENIGH\ENIGH_TRABAJADORES_AJUSTADA.dta", replace

************************************************************

                  //#1 ESTADISTICOS RELEVATES
				
************************************************************

//###PASO 1 

use "$ENIGH\ENIGH_TRABAJADORES_FINAL.dta", clear

//### PASO 2: Convertir variables de string a numéricas (si aplica)
destring year sexo edad nivelaprob htrab factor INPC trabajo_mp tam_loc gradoaprob, replace

//### PASO 3: Mantener solo población de 25 a 65 años (edad laboral principal)
keep if edad >= 25 & edad <= 65

//### PASO 4: Reemplazar valores inválidos (999999 o 0) por missing en ingresos
replace ing_1   = . if ing_1   == 999999 | ing_1   == 0
replace ing_tri = . if ing_tri == 999999 | ing_tri == 0

//### PASO 5: Crear indicador de trabajador válido
gen trabajador_valido = (ing_1 != . & ing_tri != . & ing_1 > 0 & ing_tri > 0)

//### PASO 6: Ajustar ingresos para el año 1992 (estaban en miles)
replace ing_tri = ing_tri/1000 if year == 1992
replace ing_1   = ing_1/1000   if year == 1992

//### PASO 7: Generar ingresos en términos reales (deflactados con INPC, base 100)
gen ingreso_mensual_real   = (ing_1   / INPC) * 100
gen ingreso_trimestral_real = (ing_tri / INPC) * 100

//### PASO 8: Construcción de variable de educación (categorías homogéneas entre años)
gen nivel_educacion = .

//#### CATEGORÍA 0: Sin instrucción
replace nivel_educacion = 0 if nivelaprob == 0                          & inrange(year, 1992, 1994)
replace nivel_educacion = 0 if inrange(nivelaprob, 0, 1)                & year == 1996
replace nivel_educacion = 0 if inrange(nivelaprob, 1, 2)                & inrange(year, 1998, 2002)
replace nivel_educacion = 0 if inrange(nivelaprob, 0, 1)                & inrange(year, 2004, 2024)

//#### CATEGORÍA 1: Primaria
replace nivel_educacion = 1 if inrange(nivelaprob, 1, 2)                & inrange(year, 1992, 1994)
replace nivel_educacion = 1 if inrange(nivelaprob, 2, 7)                & year == 1996
replace nivel_educacion = 1 if inrange(nivelaprob, 3, 8)                & inrange(year, 1998, 2002)
replace nivel_educacion = 1 if nivelaprob == 2                          & inrange(year, 2004, 2024)

//#### CATEGORÍA 2: Secundaria
replace nivel_educacion = 2 if inrange(nivelaprob, 3, 4)                & inrange(year, 1992, 1994)
replace nivel_educacion = 2 if inrange(nivelaprob, 8, 10)               & year == 1996
replace nivel_educacion = 2 if inrange(nivelaprob, 9, 11)               & inrange(year, 1998, 2002)
replace nivel_educacion = 2 if nivelaprob == 3                          & inrange(year, 2004, 2024)

//#### CATEGORÍA 3: Media superior (Preparatoria / Bachillerato)
replace nivel_educacion = 3 if inrange(nivelaprob, 5, 6)                & inrange(year, 1992, 1994)
replace nivel_educacion = 3 if inrange(nivelaprob, 11, 12)              & year == 1996
replace nivel_educacion = 3 if inrange(nivelaprob, 12, 13)              & inrange(year, 1998, 2000)
replace nivel_educacion = 3 if inrange(nivelaprob, 12, 20)              & year == 2002
replace nivel_educacion = 3 if inrange(nivelaprob, 4, 6)                & inrange(year, 2004, 2024)

//#### CATEGORÍA 4: Superior (Licenciatura / Universidad)
replace nivel_educacion = 4 if inrange(nivelaprob, 7, 8)                & inrange(year, 1992, 1994)
replace nivel_educacion = 4 if inrange(nivelaprob, 13, 14)              & year == 1996
replace nivel_educacion = 4 if inrange(nivelaprob, 14, 15)              & inrange(year, 1998, 2000)
replace nivel_educacion = 4 if inrange(nivelaprob, 21, 31)              & year == 2002
replace nivel_educacion = 4 if nivelaprob == 7                          & inrange(year, 2004, 2024)

//#### CATEGORÍA 5: Posgrado
replace nivel_educacion = 5 if nivelaprob == 9                          & inrange(year, 1992, 1994)
replace nivel_educacion = 5 if nivelaprob == 15                         & year == 1996
replace nivel_educacion = 5 if nivelaprob == 16                         & inrange(year, 1998, 2000)
replace nivel_educacion = 5 if nivelaprob >= 32                         & year == 2002
replace nivel_educacion = 5 if nivelaprob >= 8                          & inrange(year, 2004, 2024)

//### PASO 9: Variable de género (1 = mujer, 0 = hombre)
gen mujer = (sexo == 2)

//### PASO 10: Asegurar missings donde no hay datos de educación
replace nivel_educacion = . if nivelaprob == .

//### PASO 11: Etiquetas para variable de educación
label define nivel_educ_lbl 0 "Sin instrucción" 1 "Primaria" 2 "Secundaria" ///
                           3 "Media Superior" 4 "Superior" 5 "Posgrado"
label values nivel_educacion nivel_educ_lbl
label variable nivel_educacion "Nivel de educación"

//### PASO 12: Construcción de variable de ocupación
gen ocupado = 0

//#### Criterios de ocupado según año y variable trabajo_mp
replace ocupado = 1 if trabajo_mp == 1 & year >= 2004
replace ocupado = 1 if trabajo_mp == 1 & year == 1992
replace ocupado = 1 if trabajo_mp != 0 & year > 1992 & year < 2004

//#### Ajuste para valores perdidos o categorías específicas
replace ocupado = . if trabajo_mp == .
replace ocupado = 0 if trabajo_mp == 2 | trabajo_mp == 222
replace ocupado = 0 if trabajo_mp >= 22211

//#### Etiquetas para variable de ocupación
label define ocupado_lbl 0 "No ocupado" 1 "Ocupado"
label values ocupado ocupado_lbl
label variable ocupado "Situación laboral"

//### PASO 13: Construcción de variable de localidad (rural vs urbano)
gen localidad_rural = 0
replace localidad_rural = 1 if tam_loc == 4

//#### Etiquetas para variable rural
label define rural_lbl 0 "Urbano" 1 "Rural"
label values localidad_rural rural_lbl
label variable localidad_rural "Tipo de localidad"

//### PASO 14: Estadísticas descriptivas básicas
summarize edad htrab ing_1 ing_tri sexo localidad_rural, detail

//### PASO 15: Construcción de grupos de población según edad, sexo y educación
gen grupo_poblacion = .

//#### GRUPOS de 25 a 45 años
replace grupo_poblacion = 1 if edad >= 25 & edad <= 45 & sexo == 2 & nivel_educacion < 3   // Mujeres, baja educación
replace grupo_poblacion = 2 if edad >= 25 & edad <= 45 & sexo == 1 & nivel_educacion < 3   // Hombres, baja educación
replace grupo_poblacion = 3 if edad >= 25 & edad <= 45 & sexo == 2 & nivel_educacion >= 3  // Mujeres, alta educación
replace grupo_poblacion = 4 if edad >= 25 & edad <= 45 & sexo == 1 & nivel_educacion >= 3  // Hombres, alta educación

//#### GRUPOS de 46 a 65 años
replace grupo_poblacion = 5 if edad >= 46 & edad <= 65 & sexo == 2 & nivel_educacion < 3   // Mujeres, baja educación
replace grupo_poblacion = 6 if edad >= 46 & edad <= 65 & sexo == 1 & nivel_educacion < 3   // Hombres, baja educación
replace grupo_poblacion = 7 if edad >= 46 & edad <= 65 & sexo == 2 & nivel_educacion >= 3  // Mujeres, alta educación
replace grupo_poblacion = 8 if edad >= 46 & edad <= 65 & sexo == 1 & nivel_educacion >= 3  // Hombres, alta educación

//#### Etiquetas de los grupos
label define grupo_lbl 1 "Mujeres 25-45, < Preparatoria"  ///
                      2 "Hombres 25-45, < Preparatoria"  ///
                      3 "Mujeres 25-45, ≥ Preparatoria"  ///
                      4 "Hombres 25-45, ≥ Preparatoria"  ///
                      5 "Mujeres 46-65, < Preparatoria"  ///
                      6 "Hombres 46-65, < Preparatoria"  ///
                      7 "Mujeres 46-65, ≥ Preparatoria"  ///
                      8 "Hombres 46-65, ≥ Preparatoria"
label values grupo_poblacion grupo_lbl
label variable grupo_poblacion "Grupo de población (edad, sexo, educación)"


//### PASO 16: Construcción de años de escolaridad (varía según año de encuesta)
gen anios_escolaridad = .

//### Año 2000
replace anios_escolaridad = 0                     if (nivelaprob == 1 | nivelaprob == 2) & year == 2000
replace anios_escolaridad = nivelaprob - 2        if inrange(nivelaprob, 3, 11)          & year == 2000
replace anios_escolaridad = nivelaprob - 1        if (nivelaprob == 12 | nivelaprob == 13) & year == 2000
replace anios_escolaridad = nivelaprob + 1        if inlist(nivelaprob, 14, 15)          & year == 2000

//### Año 2004
replace anios_escolaridad = 0                     if (nivelaprob == 0 | nivelaprob == 1) & year == 2004
replace anios_escolaridad = gradoaprob            if nivelaprob == 2                     & year == 2004
replace anios_escolaridad = gradoaprob + 6        if nivelaprob == 3                     & year == 2004
replace anios_escolaridad = gradoaprob + 9        if inlist(nivelaprob, 4, 5, 6)         & year == 2004
replace anios_escolaridad = gradoaprob + 12       if nivelaprob == 7                     & year == 2004
replace anios_escolaridad = gradoaprob + 16       if nivelaprob == 8                     & year == 2004
replace anios_escolaridad = gradoaprob + 18       if nivelaprob == 9                     & year == 2004

//### Año 2006
replace anios_escolaridad = 0                     if (nivelaprob == 0 | nivelaprob == 1) & year == 2006
replace anios_escolaridad = gradoaprob            if nivelaprob == 2                     & year == 2006
replace anios_escolaridad = gradoaprob + 6        if nivelaprob == 3                     & year == 2006
replace anios_escolaridad = gradoaprob + 9        if inlist(nivelaprob, 4, 5, 6)         & year == 2006
replace anios_escolaridad = gradoaprob + 12       if nivelaprob == 7                     & year == 2006
replace anios_escolaridad = gradoaprob + 16       if nivelaprob == 8                     & year == 2006
replace anios_escolaridad = gradoaprob + 18       if nivelaprob == 9                     & year == 2006

//### Años 2012 a 2020
replace anios_escolaridad = 0                     if (nivelaprob == 0 | nivelaprob == 1) & inrange(year, 2012, 2024)
replace anios_escolaridad = gradoaprob            if nivelaprob == 2                     & inrange(year, 2012, 2024)
replace anios_escolaridad = 6  + gradoaprob       if nivelaprob == 3                     & inrange(year, 2012, 2024)
replace anios_escolaridad = 9  + gradoaprob       if inlist(nivelaprob, 4, 5, 6)         & inrange(year, 2012, 2024)
replace anios_escolaridad = 12 + gradoaprob       if nivelaprob == 7                     & inrange(year, 2012, 2024)
replace anios_escolaridad = 16 + gradoaprob       if nivelaprob == 8                     & inrange(year, 2012, 2024)
replace anios_escolaridad = 18 + gradoaprob       if nivelaprob == 9                     & inrange(year, 2012, 2024)

//### PASO 17: Construcción de salarios por hora
gen salario_trimestral_hora = ingreso_trimestral_real / (htrab * 4.33 * 3)
gen salario_mensual_hora    = ingreso_mensual_real   / (htrab * 4.33)

//### PASO 18: Censura de valores extremos en salarios horarios
replace salario_mensual_hora    = 1    if salario_mensual_hora <= 1    & salario_mensual_hora != .
replace salario_mensual_hora    = 5000 if salario_mensual_hora >= 5000 & salario_mensual_hora != .
replace salario_trimestral_hora = 1    if salario_trimestral_hora <= 1 & salario_trimestral_hora != .
replace salario_trimestral_hora = 5000 if salario_trimestral_hora >= 5000 & salario_trimestral_hora != .


//### PASO 19: Variables en logaritmo de salarios horarios
gen ln_salario_mensual_hora    = ln(salario_mensual_hora)
gen ln_salario_trimestral_hora = ln(salario_trimestral_hora)

//### PASO 20: Etiquetas para variables descriptivas
label variable edad                     "Edad"
label variable ingreso_mensual_real     "Salario mensual real"
label variable ingreso_trimestral_real  "Salario trimestral real"
label variable htrab                    "Horas de trabajo"
label variable mujer                    "Sexo (1=Mujer)"
label variable localidad_rural          "Urbano o rural"

//## 1.3.1 MEDIA Tabla descriptiva
// ---- Exportar Tabla Descriptiva a LaTeX ----
preserve

// Calcular medias ponderadas por año
collapse (mean) edad nivel_educacion ingreso_mensual_real ingreso_trimestral_real htrab mujer localidad_rural [fw=factor], by(year)

// Abrir archivo .tex
file open tabla using "$graf\ENIGH_STATS_1_3_1.tex", write replace

// Encabezado LaTeX con ajuste de espacio vertical
file write tabla "\renewcommand{\arraystretch}{0.9}" _n
file write tabla "\begin{tabular}{l@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c}" _n
file write tabla "\hline" _n
file write tabla "Año & Edad & \shortstack{Nivel de \\ educación} & \shortstack{Salario \\ mensual real} & \shortstack{Salario \\ trimestral real} & \shortstack{Horas de \\ trabajo} & \shortstack{Sexo \\ (1=Mujer)} & \shortstack{Urbano \\ o rural} \\\\" _n
file write tabla "\hline" _n

// Escribir filas (formato compacto)
quietly {
    forvalues i = 1/`=_N' {
        local y  = year[`i']
        local e  = string(edad[`i'], "%5.2f")
        local n  = string(nivel_educacion[`i'], "%5.2f")
        local sm = string(ingreso_mensual_real[`i'], "%8.2f")
        local st = string(ingreso_trimestral_real[`i'], "%8.2f")
        local h  = string(htrab[`i'], "%5.2f")
        local m  = string(mujer[`i'], "%4.2f")
        local r  = string(localidad_rural[`i'], "%4.2f")
        file write tabla "`y' & `e' & `n' & `sm' & `st' & `h' & `m' & `r' \\\\" _n
    }
}

// Cerrar tabla
file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore

//## 1.3.2 SD Tabla descriptiva 
preserve

// Calcular desviaciones estándar ponderadas por año
collapse (sd) edad nivel_educacion ingreso_mensual_real ingreso_trimestral_real htrab mujer localidad_rural [fw=factor], by(year)

// Abrir archivo .tex
file open tabla using "$graf\ENIGH_STATS_1_3_2.tex", write replace

// Encabezado LaTeX con compactación
file write tabla "\renewcommand{\arraystretch}{0.9}" _n
file write tabla "\setlength{\tabcolsep}{6pt}" _n
file write tabla "\begin{tabular}{lccccccc}" _n
file write tabla "\hline" _n
file write tabla "Año & Edad & \shortstack{Nivel de \\ educación} & \shortstack{Salario \\ mensual real} & \shortstack{Salario \\ trimestral real} & \shortstack{Horas de \\ trabajo} & \shortstack{Sexo \\ (1=Mujer)} & \shortstack{Urbano \\ o rural} \\\\" _n
file write tabla "\hline" _n

// Escribir filas
quietly {
    forvalues i = 1/`=_N' {
        local y  = year[`i']
        local e  = string(edad[`i'], "%5.2f")
        local n  = string(nivel_educacion[`i'], "%5.2f")
        local sm = string(ingreso_mensual_real[`i'], "%8.2f")
        local st = string(ingreso_trimestral_real[`i'], "%8.2f")
        local h  = string(htrab[`i'], "%5.2f")
        local m  = string(mujer[`i'], "%4.2f")
        local r  = string(localidad_rural[`i'], "%4.2f")
        file write tabla "`y' & `e' & `n' & `sm' & `st' & `h' & `m' & `r' \\\\" _n
    }
}

// Cerrar tabla
file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore

//## 1.3.3 MEDIANAS Tabla descriptiva 

preserve

// Calcular medianas ponderadas por año
collapse (p50) edad nivel_educacion ingreso_mensual_real ingreso_trimestral_real htrab mujer localidad_rural [fw=factor], by(year)

// Abrir archivo .tex
file open tabla using "$graf\ENIGH_STATS_1_3_3.tex", write replace

// Encabezado LaTeX con compactación
file write tabla "\renewcommand{\arraystretch}{0.9}" _n
file write tabla "\setlength{\tabcolsep}{6pt}" _n
file write tabla "\begin{tabular}{lccccccc}" _n
file write tabla "\hline" _n
file write tabla "Año & Edad & \shortstack{Nivel de \\ educación} & \shortstack{Salario \\ mensual real} & \shortstack{Salario \\ trimestral real} & \shortstack{Horas de \\ trabajo} & \shortstack{Sexo \\ (1=Mujer)} & \shortstack{Urbano \\ o rural} \\\\" _n
file write tabla "\hline" _n

// Escribir filas
quietly {
    forvalues i = 1/`=_N' {
        local y  = year[`i']
        local e  = string(edad[`i'], "%5.2f")
        local n  = string(nivel_educacion[`i'], "%5.2f")
        local sm = string(ingreso_mensual_real[`i'], "%8.2f")
        local st = string(ingreso_trimestral_real[`i'], "%8.2f")
        local h  = string(htrab[`i'], "%5.2f")
        local m  = string(mujer[`i'], "%4.2f")
        local r  = string(localidad_rural[`i'], "%4.2f")
        file write tabla "`y' & `e' & `n' & `sm' & `st' & `h' & `m' & `r' \\\\" _n
    }
}

// Cerrar tabla
file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore


//## 1.7 BOXPLOTS

//### LN MENSUAL

// Preservar base original
preserve

// Gráfico final con color, puntos y etiquetas claras
graph box ln_salario_mensual_hora [fw=factor] if trabajador_valido == 1, ///
    over(year, label(angle(45) labsize(medium))) ///
    ytitle("Logaritmo del salario mensual por hora") ///
    box(1, color("255 69 0")) ///
    marker(1, mcolor("255 69 0")) ///
    name(ENIGH_BOX_1_7, replace)

// Exportar imagen en alta resolución para mejor visibilidad
graph export "$graf/ENIGH_BOX_1_7.png", replace width(1600) height(900)

// Restaurar base original
restore

//### LN TRIMESTRAL

// Preservar base original
preserve

// Gráfico del log(salario trimestral por hora), con estilo académico
graph box ln_salario_trimestral_hora [fw=factor] if trabajador_valido == 1, ///
    over(year, label(angle(45) labsize(medium))) ///
    ytitle("Logaritmo del salario trimestral por hora") ///
    box(1, color("24 116 205")) ///
    marker(1, mcolor("24 116 205")) ///
    name(ENIGH_BOX_1_7_TRIMESTRAL, replace)

// Exportar imagen en alta resolución
graph export "$graf/ENIGH_BOX_1_7_TRIMESTRAL.png", replace width(1600) height(900)

// Restaurar base original
restore


//### EXTRAS BOX CON LINEA MEDIA

// Paso 1: Preservar base original
preserve

// Paso 2: Guardar datos originales para el boxplot
tempfile basebox
save `basebox'

// Paso 3: Calcular medias por año
collapse (mean) ln_salario_mensual_hora [fw=factor] if trabajador_valido == 1, by(year)
gen media = ln_salario_mensual_hora

// Paso 4: Guardar temporal con medias
tempfile medias
save `medias'

// Paso 5: Volver a la base original para el boxplot
use `basebox', clear

// Paso 6: Crear el gráfico combinado
graph box ln_salario_mensual_hora [fw=factor] if trabajador_valido == 1, ///
    over(year, label(angle(45) labsize(small))) ///
    ytitle("Logaritmo del salario mensual por hora") ///
    box(1, color("255 69 0")) ///
    marker(1, mcolor("255 69 0")) ///
    name(box_sin_media, replace) ///
    saving(box_sin_media, replace)

// Paso 7: Cargar las medias
use `medias', clear

// Paso 8: Crear gráfico con puntos de la media
twoway scatter media year, ///
    msymbol(circle_hollow) msize(small) mcolor("0 0 0") ///
    name(media_puntos, replace) ///
    saving(media_puntos, replace)

// Paso 9: Combinar ambos gráficos
graph use box_sin_media
graph combine box_sin_media.gph media_puntos.gph, ///
    title("Boxplot + Media del logaritmo del salario mensual por hora") ///
    name(box_con_media, replace)

// Paso 10: Exportar
graph export "$graf/ENIGH_BOX_MEDIA_MENSUAL.png", replace width(1800) height(1000)

// Restaurar base original
restore


//## 1.8 TABLAS DE SALARIO EVOLUCION

// --- Tabla de salarios por año ---
preserve

// Mantener solo trabajadores válidos
keep if trabajador_valido == 1

// Colapsar: medias ponderadas por año
collapse (mean) ingreso_trimestral_real ingreso_mensual_real salario_mensual_hora salario_trimestral_hora [fw=factor], by(year)

// Abrir archivo .tex
file open tabla using "$graf\ENIGH_1_8_SALARIOS.tex", write replace
file write tabla "\begin{tabular}{lcccc}" _n
file write tabla "\hline" _n
file write tabla "Año & \shortstack{Salario \\ trimestral} & \shortstack{Salario \\ mensual} & \shortstack{Salario \\ mensual \\ por hora} & \shortstack{Salario \\ trimestral \\ por hora} \\\\" _n
file write tabla "\hline" _n

// Escribir filas compactas
quietly {
    forvalues i = 1/`=_N' {
        local y  = year[`i']
        local st = string(ingreso_trimestral_real[`i'], "%9.2f")
        local sm = string(ingreso_mensual_real[`i'], "%9.2f")
        local smh = string(salario_mensual_hora[`i'], "%9.2f")
        local sth = string(salario_trimestral_hora[`i'], "%9.2f")
        file write tabla "`y' & `st' & `sm' & `smh' & `sth' \\\\" _n
    }
}

// Cerrar tabla
file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore

//## 1.8.1 Crecimiento de salarios por año
preserve
keep if trabajador_valido==1

// Calcular medias ponderadas de salarios reales
collapse (mean) ingreso_trimestral_real ingreso_mensual_real salario_mensual_hora salario_trimestral_hora [fw=factor], by(year)
order year
sort year

// Calcular tasas de crecimiento interanual (%)
gen cambio_st  = ((ingreso_trimestral_real / ingreso_trimestral_real[_n-1]) - 1) * 100
gen cambio_sm  = ((ingreso_mensual_real   / ingreso_mensual_real[_n-1])   - 1) * 100
gen cambio_smh = ((salario_mensual_hora   / salario_mensual_hora[_n-1])   - 1) * 100
gen cambio_sth = ((salario_trimestral_hora/ salario_trimestral_hora[_n-1])- 1) * 100

label variable cambio_st  "Salario trimestral"
label variable cambio_sm  "Salario mensual"
label variable cambio_smh "Salario mensual por hora"
label variable cambio_sth "Salario trimestral por hora"

// ---- Exportar a LaTeX ----
file open tabla using "$graf\ENIGH_1_8_1.tex", write replace
file write tabla "\begin{tabular}{lcccc}" _n
file write tabla "\hline" _n
file write tabla "Año & \shortstack{Salario \\ trimestral} & \shortstack{Salario \\ mensual} & \shortstack{Salario \\ mensual \\ por hora} & \shortstack{Salario \\ trimestral \\ por hora} \\\\" _n
file write tabla "\hline" _n

quietly {
    forvalues i = 2/`=_N' {
        local y  = year[`i']
        local c1 = string(cambio_st[`i'], "%6.2f")
        local c2 = string(cambio_sm[`i'], "%6.2f")
        local c3 = string(cambio_smh[`i'], "%6.2f")
        local c4 = string(cambio_sth[`i'], "%6.2f")
        file write tabla "`y' & `c1'\% & `c2'\% & `c3'\% & `c4'\% \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla
restore

//## 1.8.2 - Tabla de salario mes pasado por grupo
preserve
keep if trabajador_valido==1
label variable year "Año"

// Calcular salario promedio mensual por grupo
collapse (mean) ingreso_mensual_real [fw=factor], by(year grupo_poblacion)

// Quitar observaciones con grupo_poblacion missing
drop if missing(grupo_poblacion)

// Reestructurar: cada grupo en una columna
reshape wide ingreso_mensual_real, i(year) j(grupo_poblacion)

// Etiquetas de columnas
label variable ingreso_mensual_real1 "Grupo 1"
label variable ingreso_mensual_real2 "Grupo 2"
label variable ingreso_mensual_real3 "Grupo 3"
label variable ingreso_mensual_real4 "Grupo 4"
label variable ingreso_mensual_real5 "Grupo 5"
label variable ingreso_mensual_real6 "Grupo 6"
label variable ingreso_mensual_real7 "Grupo 7"
label variable ingreso_mensual_real8 "Grupo 8"

// ---- Exportar a LaTeX ----
file open tabla using "$graf\ENIGH_1_8_2.tex", write replace
file write tabla "\begin{tabular}{lcccccccc}" _n
file write tabla "\hline" _n
file write tabla "Año & \shortstack{Grupo \\ 1} & \shortstack{Grupo \\ 2} & \shortstack{Grupo \\ 3} & \shortstack{Grupo \\ 4} & \shortstack{Grupo \\ 5} & \shortstack{Grupo \\ 6} & \shortstack{Grupo \\ 7} & \shortstack{Grupo \\ 8} \\\\" _n
file write tabla "\hline" _n

quietly {
    forvalues i = 1/`=_N' {
        local y  = year[`i']
        local g1 = string(ingreso_mensual_real1[`i'], "%9.2f")
        local g2 = string(ingreso_mensual_real2[`i'], "%9.2f")
        local g3 = string(ingreso_mensual_real3[`i'], "%9.2f")
        local g4 = string(ingreso_mensual_real4[`i'], "%9.2f")
        local g5 = string(ingreso_mensual_real5[`i'], "%9.2f")
        local g6 = string(ingreso_mensual_real6[`i'], "%9.2f")
        local g7 = string(ingreso_mensual_real7[`i'], "%9.2f")
        local g8 = string(ingreso_mensual_real8[`i'], "%9.2f")
        file write tabla "`y' & `g1' & `g2' & `g3' & `g4' & `g5' & `g6' & `g7' & `g8' \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla
restore


//## 1.8.3 - Tabla de salario trimestral por grupo
preserve
keep if trabajador_valido==1
label variable year "Año"

// Calcular salario promedio trimestral por grupo
collapse (mean) ingreso_trimestral_real [fw=factor], by(year grupo_poblacion)

// Eliminar observaciones sin grupo
drop if missing(grupo_poblacion)

// Reestructurar: cada grupo en una columna
reshape wide ingreso_trimestral_real, i(year) j(grupo_poblacion)

// Etiquetas de columnas
label variable ingreso_trimestral_real1 "Grupo 1"
label variable ingreso_trimestral_real2 "Grupo 2"
label variable ingreso_trimestral_real3 "Grupo 3"
label variable ingreso_trimestral_real4 "Grupo 4"
label variable ingreso_trimestral_real5 "Grupo 5"
label variable ingreso_trimestral_real6 "Grupo 6"
label variable ingreso_trimestral_real7 "Grupo 7"
label variable ingreso_trimestral_real8 "Grupo 8"

// ---- Exportar a LaTeX ----
file open tabla using "$graf\ENIGH_1_8_3.tex", write replace
file write tabla "\begin{tabular}{lcccccccc}" _n
file write tabla "\hline" _n
file write tabla "Año & \shortstack{Grupo \\ 1} & \shortstack{Grupo \\ 2} & \shortstack{Grupo \\ 3} & \shortstack{Grupo \\ 4} & \shortstack{Grupo \\ 5} & \shortstack{Grupo \\ 6} & \shortstack{Grupo \\ 7} & \shortstack{Grupo \\ 8} \\\\" _n
file write tabla "\hline" _n

quietly {
    forvalues i = 1/`=_N' {
        local y  = year[`i']
        local g1 = string(ingreso_trimestral_real1[`i'], "%9.2f")
        local g2 = string(ingreso_trimestral_real2[`i'], "%9.2f")
        local g3 = string(ingreso_trimestral_real3[`i'], "%9.2f")
        local g4 = string(ingreso_trimestral_real4[`i'], "%9.2f")
        local g5 = string(ingreso_trimestral_real5[`i'], "%9.2f")
        local g6 = string(ingreso_trimestral_real6[`i'], "%9.2f")
        local g7 = string(ingreso_trimestral_real7[`i'], "%9.2f")
        local g8 = string(ingreso_trimestral_real8[`i'], "%9.2f")
        file write tabla "`y' & `g1' & `g2' & `g3' & `g4' & `g5' & `g6' & `g7' & `g8' \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla
restore

//## 1.8.4 - Tabla de salario mensual por hora por grupo
preserve
keep if trabajador_valido==1
label variable year "Año"

// Calcular salario mensual por hora promedio por grupo
collapse (mean) salario_mensual_hora [fw=factor], by(year grupo_poblacion)

// Eliminar observaciones sin grupo
drop if missing(grupo_poblacion)

// Reestructurar: cada grupo en una columna
reshape wide salario_mensual_hora, i(year) j(grupo_poblacion)

// Etiquetas de columnas
label variable salario_mensual_hora1 "Grupo 1"
label variable salario_mensual_hora2 "Grupo 2"
label variable salario_mensual_hora3 "Grupo 3"
label variable salario_mensual_hora4 "Grupo 4"
label variable salario_mensual_hora5 "Grupo 5"
label variable salario_mensual_hora6 "Grupo 6"
label variable salario_mensual_hora7 "Grupo 7"
label variable salario_mensual_hora8 "Grupo 8"

// ---- Exportar a LaTeX ----
file open tabla using "$graf\ENIGH_1_8_4.tex", write replace
file write tabla "\begin{tabular}{lcccccccc}" _n
file write tabla "\hline" _n
file write tabla "Año & \shortstack{Grupo \\ 1} & \shortstack{Grupo \\ 2} & \shortstack{Grupo \\ 3} & \shortstack{Grupo \\ 4} & \shortstack{Grupo \\ 5} & \shortstack{Grupo \\ 6} & \shortstack{Grupo \\ 7} & \shortstack{Grupo \\ 8} \\\\" _n
file write tabla "\hline" _n

quietly {
    forvalues i = 1/`=_N' {
        local y  = year[`i']
        local g1 = string(salario_mensual_hora1[`i'], "%9.2f")
        local g2 = string(salario_mensual_hora2[`i'], "%9.2f")
        local g3 = string(salario_mensual_hora3[`i'], "%9.2f")
        local g4 = string(salario_mensual_hora4[`i'], "%9.2f")
        local g5 = string(salario_mensual_hora5[`i'], "%9.2f")
        local g6 = string(salario_mensual_hora6[`i'], "%9.2f")
        local g7 = string(salario_mensual_hora7[`i'], "%9.2f")
        local g8 = string(salario_mensual_hora8[`i'], "%9.2f")
        file write tabla "`y' & `g1' & `g2' & `g3' & `g4' & `g5' & `g6' & `g7' & `g8' \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla
restore

//## 1.8.5 - Tabla de salario trimestral por hora y grupo
preserve
keep if trabajador_valido==1
label variable year "Año"

// Calcular salario promedio trimestral por hora por grupo
collapse (mean) salario_trimestral_hora [fw=factor], by(year grupo_poblacion)

// Eliminar observaciones sin grupo
drop if missing(grupo_poblacion)

// Reestructurar: cada grupo en una columna
reshape wide salario_trimestral_hora, i(year) j(grupo_poblacion)

// Etiquetas de columnas
label variable salario_trimestral_hora1 "Grupo 1"
label variable salario_trimestral_hora2 "Grupo 2"
label variable salario_trimestral_hora3 "Grupo 3"
label variable salario_trimestral_hora4 "Grupo 4"
label variable salario_trimestral_hora5 "Grupo 5"
label variable salario_trimestral_hora6 "Grupo 6"
label variable salario_trimestral_hora7 "Grupo 7"
label variable salario_trimestral_hora8 "Grupo 8"

// ---- Exportar a LaTeX ----
file open tabla using "$graf\ENIGH_1_8_5.tex", write replace
file write tabla "\begin{tabular}{lcccccccc}" _n
file write tabla "\hline" _n
file write tabla "Año & \shortstack{Grupo \\ 1} & \shortstack{Grupo \\ 2} & \shortstack{Grupo \\ 3} & \shortstack{Grupo \\ 4} & \shortstack{Grupo \\ 5} & \shortstack{Grupo \\ 6} & \shortstack{Grupo \\ 7} & \shortstack{Grupo \\ 8} \\\\" _n
file write tabla "\hline" _n

quietly {
    forvalues i = 1/`=_N' {
        local y  = year[`i']
        local g1 = string(salario_trimestral_hora1[`i'], "%9.2f")
        local g2 = string(salario_trimestral_hora2[`i'], "%9.2f")
        local g3 = string(salario_trimestral_hora3[`i'], "%9.2f")
        local g4 = string(salario_trimestral_hora4[`i'], "%9.2f")
        local g5 = string(salario_trimestral_hora5[`i'], "%9.2f")
        local g6 = string(salario_trimestral_hora6[`i'], "%9.2f")
        local g7 = string(salario_trimestral_hora7[`i'], "%9.2f")
        local g8 = string(salario_trimestral_hora8[`i'], "%9.2f")
        file write tabla "`y' & `g1' & `g2' & `g3' & `g4' & `g5' & `g6' & `g7' & `g8' \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla
restore

//## 1.8.6 - Tabla de crecimiento del salario mensual por grupo
preserve
keep if trabajador_valido==1
label variable year "Año"

// Calcular salario mensual promedio por grupo
collapse (mean) ingreso_mensual_real [fw=factor], by(year grupo_poblacion)

// Eliminar observaciones sin grupo
drop if missing(grupo_poblacion)

// Reestructurar: cada grupo en una columna
reshape wide ingreso_mensual_real, i(year) j(grupo_poblacion)

order year
sort year

// Crecimiento porcentual respecto al año previo
gen cambio1 = ((ingreso_mensual_real1[_n]/ingreso_mensual_real1[_n-1])-1)*100
gen cambio2 = ((ingreso_mensual_real2[_n]/ingreso_mensual_real2[_n-1])-1)*100
gen cambio3 = ((ingreso_mensual_real3[_n]/ingreso_mensual_real3[_n-1])-1)*100
gen cambio4 = ((ingreso_mensual_real4[_n]/ingreso_mensual_real4[_n-1])-1)*100
gen cambio5 = ((ingreso_mensual_real5[_n]/ingreso_mensual_real5[_n-1])-1)*100
gen cambio6 = ((ingreso_mensual_real6[_n]/ingreso_mensual_real6[_n-1])-1)*100
gen cambio7 = ((ingreso_mensual_real7[_n]/ingreso_mensual_real7[_n-1])-1)*100
gen cambio8 = ((ingreso_mensual_real8[_n]/ingreso_mensual_real8[_n-1])-1)*100

// Etiquetas
label variable cambio1 "Grupo 1"
label variable cambio2 "Grupo 2"
label variable cambio3 "Grupo 3"
label variable cambio4 "Grupo 4"
label variable cambio5 "Grupo 5"
label variable cambio6 "Grupo 6"
label variable cambio7 "Grupo 7"
label variable cambio8 "Grupo 8"

// ---- Exportar a LaTeX ----
file open tabla using "$graf\ENIGH_1_8_6.tex", write replace
file write tabla "\begin{tabular}{lcccccccc}" _n
file write tabla "\hline" _n
file write tabla "Año & \shortstack{Grupo \\ 1} & \shortstack{Grupo \\ 2} & \shortstack{Grupo \\ 3} & \shortstack{Grupo \\ 4} & \shortstack{Grupo \\ 5} & \shortstack{Grupo \\ 6} & \shortstack{Grupo \\ 7} & \shortstack{Grupo \\ 8} \\\\" _n
file write tabla "\hline" _n

quietly {
    forvalues i = 2/`=_N' {   // desde 2 porque la primera fila no tiene crecimiento
        local y  = year[`i']
        local g1 = string(cambio1[`i'], "%9.2f")
        local g2 = string(cambio2[`i'], "%9.2f")
        local g3 = string(cambio3[`i'], "%9.2f")
        local g4 = string(cambio4[`i'], "%9.2f")
        local g5 = string(cambio5[`i'], "%9.2f")
        local g6 = string(cambio6[`i'], "%9.2f")
        local g7 = string(cambio7[`i'], "%9.2f")
        local g8 = string(cambio8[`i'], "%9.2f")
        file write tabla "`y' & `g1' & `g2' & `g3' & `g4' & `g5' & `g6' & `g7' & `g8' \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla
restore

//## 1.8.7 - Tabla de crecimiento del salario trimestral por grupo
preserve
keep if trabajador_valido==1
label variable year "Año"

// Calcular salario promedio trimestral por grupo
collapse (mean) ingreso_trimestral_real [fw=factor], by(year grupo_poblacion)

// Eliminar observaciones sin grupo
drop if missing(grupo_poblacion)

// Reestructurar: cada grupo en una columna
reshape wide ingreso_trimestral_real, i(year) j(grupo_poblacion)

order year
sort year

// Crecimiento porcentual respecto al año previo
gen cambio1 = ((ingreso_trimestral_real1[_n]/ingreso_trimestral_real1[_n-1])-1)*100
gen cambio2 = ((ingreso_trimestral_real2[_n]/ingreso_trimestral_real2[_n-1])-1)*100
gen cambio3 = ((ingreso_trimestral_real3[_n]/ingreso_trimestral_real3[_n-1])-1)*100
gen cambio4 = ((ingreso_trimestral_real4[_n]/ingreso_trimestral_real4[_n-1])-1)*100
gen cambio5 = ((ingreso_trimestral_real5[_n]/ingreso_trimestral_real5[_n-1])-1)*100
gen cambio6 = ((ingreso_trimestral_real6[_n]/ingreso_trimestral_real6[_n-1])-1)*100
gen cambio7 = ((ingreso_trimestral_real7[_n]/ingreso_trimestral_real7[_n-1])-1)*100
gen cambio8 = ((ingreso_trimestral_real8[_n]/ingreso_trimestral_real8[_n-1])-1)*100

// Etiquetas
label variable cambio1 "Grupo 1"
label variable cambio2 "Grupo 2"
label variable cambio3 "Grupo 3"
label variable cambio4 "Grupo 4"
label variable cambio5 "Grupo 5"
label variable cambio6 "Grupo 6"
label variable cambio7 "Grupo 7"
label variable cambio8 "Grupo 8"

// ---- Exportar a LaTeX ----
file open tabla using "$graf\ENIGH_1_8_7.tex", write replace
file write tabla "\begin{tabular}{lcccccccc}" _n
file write tabla "\hline" _n
file write tabla "Año & \shortstack{Grupo \\ 1} & \shortstack{Grupo \\ 2} & \shortstack{Grupo \\ 3} & \shortstack{Grupo \\ 4} & \shortstack{Grupo \\ 5} & \shortstack{Grupo \\ 6} & \shortstack{Grupo \\ 7} & \shortstack{Grupo \\ 8} \\\\" _n
file write tabla "\hline" _n

quietly {
    forvalues i = 2/`=_N' {   // desde 2 porque la primera fila no tiene crecimiento
        local y  = year[`i']
        local g1 = string(cambio1[`i'], "%9.2f")
        local g2 = string(cambio2[`i'], "%9.2f")
        local g3 = string(cambio3[`i'], "%9.2f")
        local g4 = string(cambio4[`i'], "%9.2f")
        local g5 = string(cambio5[`i'], "%9.2f")
        local g6 = string(cambio6[`i'], "%9.2f")
        local g7 = string(cambio7[`i'], "%9.2f")
        local g8 = string(cambio8[`i'], "%9.2f")
        file write tabla "`y' & `g1' & `g2' & `g3' & `g4' & `g5' & `g6' & `g7' & `g8' \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla
restore

//## 1.8.8 - Tabla de crecimiento del salario mensual por hora por grupo
preserve
keep if trabajador_valido==1
label variable year "Año"

// Calcular salario mensual por hora promedio por grupo
collapse (mean) salario_mensual_hora [fw=factor], by(year grupo_poblacion)

// Eliminar observaciones sin grupo
drop if missing(grupo_poblacion)

// Reestructurar: cada grupo en una columna
reshape wide salario_mensual_hora, i(year) j(grupo_poblacion)

order year
sort year

// Crecimiento porcentual respecto al año previo
gen cambio1 = ((salario_mensual_hora1[_n]/salario_mensual_hora1[_n-1])-1)*100
gen cambio2 = ((salario_mensual_hora2[_n]/salario_mensual_hora2[_n-1])-1)*100
gen cambio3 = ((salario_mensual_hora3[_n]/salario_mensual_hora3[_n-1])-1)*100
gen cambio4 = ((salario_mensual_hora4[_n]/salario_mensual_hora4[_n-1])-1)*100
gen cambio5 = ((salario_mensual_hora5[_n]/salario_mensual_hora5[_n-1])-1)*100
gen cambio6 = ((salario_mensual_hora6[_n]/salario_mensual_hora6[_n-1])-1)*100
gen cambio7 = ((salario_mensual_hora7[_n]/salario_mensual_hora7[_n-1])-1)*100
gen cambio8 = ((salario_mensual_hora8[_n]/salario_mensual_hora8[_n-1])-1)*100

// Etiquetas
label variable cambio1 "Grupo 1"
label variable cambio2 "Grupo 2"
label variable cambio3 "Grupo 3"
label variable cambio4 "Grupo 4"
label variable cambio5 "Grupo 5"
label variable cambio6 "Grupo 6"
label variable cambio7 "Grupo 7"
label variable cambio8 "Grupo 8"

// ---- Exportar a LaTeX ----
file open tabla using "$graf\ENIGH_1_8_8.tex", write replace
file write tabla "\begin{tabular}{lcccccccc}" _n
file write tabla "\hline" _n
file write tabla "Año & \shortstack{Grupo \\ 1} & \shortstack{Grupo \\ 2} & \shortstack{Grupo \\ 3} & \shortstack{Grupo \\ 4} & \shortstack{Grupo \\ 5} & \shortstack{Grupo \\ 6} & \shortstack{Grupo \\ 7} & \shortstack{Grupo \\ 8} \\\\" _n
file write tabla "\hline" _n

quietly {
    forvalues i = 2/`=_N' {   // desde 2 porque la primera fila no tiene crecimiento
        local y  = year[`i']
        local g1 = string(cambio1[`i'], "%9.2f")
        local g2 = string(cambio2[`i'], "%9.2f")
        local g3 = string(cambio3[`i'], "%9.2f")
        local g4 = string(cambio4[`i'], "%9.2f")
        local g5 = string(cambio5[`i'], "%9.2f")
        local g6 = string(cambio6[`i'], "%9.2f")
        local g7 = string(cambio7[`i'], "%9.2f")
        local g8 = string(cambio8[`i'], "%9.2f")
        file write tabla "`y' & `g1' & `g2' & `g3' & `g4' & `g5' & `g6' & `g7' & `g8' \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla
restore

//## 1.8.9 - Tabla de crecimiento del salario trimestral por hora por grupo
preserve
keep if trabajador_valido==1
label variable year "Año"

// Calcular salario trimestral por hora promedio por grupo
collapse (mean) salario_trimestral_hora [fw=factor], by(year grupo_poblacion)

// Eliminar observaciones sin grupo
drop if missing(grupo_poblacion)

// Reestructurar: cada grupo en una columna
reshape wide salario_trimestral_hora, i(year) j(grupo_poblacion)

order year
sort year

// Crecimiento porcentual respecto al año previo
gen cambio1 = ((salario_trimestral_hora1[_n]/salario_trimestral_hora1[_n-1])-1)*100
gen cambio2 = ((salario_trimestral_hora2[_n]/salario_trimestral_hora2[_n-1])-1)*100
gen cambio3 = ((salario_trimestral_hora3[_n]/salario_trimestral_hora3[_n-1])-1)*100
gen cambio4 = ((salario_trimestral_hora4[_n]/salario_trimestral_hora4[_n-1])-1)*100
gen cambio5 = ((salario_trimestral_hora5[_n]/salario_trimestral_hora5[_n-1])-1)*100
gen cambio6 = ((salario_trimestral_hora6[_n]/salario_trimestral_hora6[_n-1])-1)*100
gen cambio7 = ((salario_trimestral_hora7[_n]/salario_trimestral_hora7[_n-1])-1)*100
gen cambio8 = ((salario_trimestral_hora8[_n]/salario_trimestral_hora8[_n-1])-1)*100

// Etiquetas de variables
label variable cambio1 "Grupo 1"
label variable cambio2 "Grupo 2"
label variable cambio3 "Grupo 3"
label variable cambio4 "Grupo 4"
label variable cambio5 "Grupo 5"
label variable cambio6 "Grupo 6"
label variable cambio7 "Grupo 7"
label variable cambio8 "Grupo 8"

// ---- Exportar a LaTeX ----
file open tabla using "$graf\ENIGH_1_8_9.tex", write replace
file write tabla "\begin{tabular}{lcccccccc}" _n
file write tabla "\hline" _n
file write tabla "Año & \shortstack{Grupo \\ 1} & \shortstack{Grupo \\ 2} & \shortstack{Grupo \\ 3} & \shortstack{Grupo \\ 4} & \shortstack{Grupo \\ 5} & \shortstack{Grupo \\ 6} & \shortstack{Grupo \\ 7} & \shortstack{Grupo \\ 8} \\\\" _n
file write tabla "\hline" _n

quietly {
    forvalues i = 2/`=_N' {   // desde 2 porque la primera fila no tiene crecimiento
        local y  = year[`i']
        local g1 = string(cambio1[`i'], "%9.2f")
        local g2 = string(cambio2[`i'], "%9.2f")
        local g3 = string(cambio3[`i'], "%9.2f")
        local g4 = string(cambio4[`i'], "%9.2f")
        local g5 = string(cambio5[`i'], "%9.2f")
        local g6 = string(cambio6[`i'], "%9.2f")
        local g7 = string(cambio7[`i'], "%9.2f")
        local g8 = string(cambio8[`i'], "%9.2f")
        file write tabla "`y' & `g1' & `g2' & `g3' & `g4' & `g5' & `g6' & `g7' & `g8' \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla
restore

//### 1.8. GRAFICA 1 - Índices de salarios (base 1992=100)

preserve
keep if trabajador_valido==1

collapse (mean) ingreso_mensual_real ingreso_trimestral_real salario_mensual_hora salario_trimestral_hora [fw=factor], by(year)

rename ingreso_mensual_real      s1
rename ingreso_trimestral_real   s2
rename salario_mensual_hora      s3
rename salario_trimestral_hora   s4

foreach x in 1 2 3 4 {
    gen w = s`x' if year==1992
    egen w1 = max(w)
    replace s`x' = (s`x'/w1)*100
    drop w w1
}

label variable s1 "Mensual"
label variable s2 "Trimestral"
label variable s3 "Mensual por hora"
label variable s4 "Trimestral por hora"
label variable year "Año"

twoway (connected s1 year, lcolor("255 69 0")    mcolor("255 69 0")    msymbol(circle)  lwidth(medthick)) ///
       (connected s2 year, lcolor("220 20 60")   mcolor("220 20 60")   msymbol(square)  lwidth(medthick)) ///
       (connected s3 year, lcolor("255 105 180") mcolor("255 105 180") msymbol(triangle) lwidth(medthick)) ///
       (connected s4 year, lcolor("255 140 0")   mcolor("255 140 0")   msymbol(diamond) lwidth(medthick)), ///
       yline(100, lcolor("black")  lpattern(dot)) ///
       xtitle("Año") ///
       ytitle("Índice (1992=100)") ///
       legend(order(1 "Mensual" 2 "Trimestral" 3 "Mensual por hora" 4 "Trimestral por hora") pos(12) col(2)) ///
       graphregion(color(white)) bgcolor(white) ///
       ylabel(70(10)120, grid) ///
       xlabel(1990(5)2025, grid)

graph export "$graf\ENIGH_1_8_graf.png", replace
restore

//### 1.8. GRAFICA 2
/// Gráfica índices salario mensual real por grupo (base 1992=100)
preserve
keep if trabajador_valido==1   // tu indicador de trabajadores válidos

collapse (mean) ingreso_mensual_real [fw=factor], by(year grupo_poblacion)
reshape wide ingreso_mensual_real, i(year) j(grupo_poblacion)

foreach x in 1 2 3 4 5 6 7 8 {
    gen w  = ingreso_mensual_real`x' if year==1992
    egen w1 = max(w)
    replace ingreso_mensual_real`x' = (ingreso_mensual_real`x'/w1)*100
    drop w w1
}

label variable ingreso_mensual_real1 "Grupo 1"
label variable ingreso_mensual_real2 "Grupo 2"
label variable ingreso_mensual_real3 "Grupo 3"
label variable ingreso_mensual_real4 "Grupo 4"
label variable ingreso_mensual_real5 "Grupo 5"
label variable ingreso_mensual_real6 "Grupo 6"
label variable ingreso_mensual_real7 "Grupo 7"
label variable ingreso_mensual_real8 "Grupo 8"
label variable year "Año"

* Gráfica con tus colores favoritos
twoway ///
    (connected ingreso_mensual_real1 year, mcolor("255 69 0") lcolor("255 69 0") msymbol(circle)) ///
    (connected ingreso_mensual_real2 year, mcolor("255 99 71") lcolor("255 99 71") msymbol(square)) ///
    (connected ingreso_mensual_real3 year, mcolor("255 140 0") lcolor("255 140 0") msymbol(triangle)) ///
    (connected ingreso_mensual_real4 year, mcolor("255 105 180") lcolor("255 105 180") msymbol(diamond)) ///
    (connected ingreso_mensual_real5 year, mcolor("255 0 127") lcolor("255 0 127") msymbol(circle_hollow)) ///
    (connected ingreso_mensual_real6 year, mcolor("255 20 147") lcolor("255 20 147") msymbol(square_hollow)) ///
    (connected ingreso_mensual_real7 year, mcolor("255 99 200") lcolor("255 99 200") msymbol(triangle_hollow)) ///
    (connected ingreso_mensual_real8 year, mcolor("200 0 100") lcolor("200 0 100") msymbol(diamond_hollow)), ///
    legend(rows(2) cols(4) pos(2) ring(0) region(lstyle(none)) size(small)) ///
    xtitle("Año") ///
    ytitle("Índice (1992=100)") ///
    ylabel(40(20)160, grid) ///
    xlabel(1990(5)2025) ///
    yline(100, lcolor(black) lpattern(dot))

graph export "$graf\ENIGH_1_8_GRAF2.png", replace
restore


//### 1.8.3 GRAFICA 3: Índices de salario trimestral por grupo
preserve
keep if trabajador_valido==1

// Calcular promedio trimestral por grupo
collapse (mean) ingreso_trimestral_real [fw=factor], by(year grupo_poblacion)

// Reestructurar: cada grupo en una columna
reshape wide ingreso_trimestral_real, i(year) j(grupo_poblacion)

// Normalizar con base 1992=100
foreach x in 1 2 3 4 5 6 7 8 {
    gen w = ingreso_trimestral_real`x' if year==1992
    egen w1 = max(w)
    replace ingreso_trimestral_real`x' = (ingreso_trimestral_real`x'/w1)*100
    drop w w1
}

// Etiquetas
label variable ingreso_trimestral_real1 "Grupo 1"
label variable ingreso_trimestral_real2 "Grupo 2"
label variable ingreso_trimestral_real3 "Grupo 3"
label variable ingreso_trimestral_real4 "Grupo 4"
label variable ingreso_trimestral_real5 "Grupo 5"
label variable ingreso_trimestral_real6 "Grupo 6"
label variable ingreso_trimestral_real7 "Grupo 7"
label variable ingreso_trimestral_real8 "Grupo 8"
label variable year "Año"

// Gráfica estilizada
twoway ///
(connected ingreso_trimestral_real1 year, msymbol(circle)  lcolor("255 69 0")  mcolor("255 69 0")) ///
(connected ingreso_trimestral_real2 year, msymbol(square)  lcolor("178 34 34") mcolor("178 34 34")) ///
(connected ingreso_trimestral_real3 year, msymbol(triangle) lcolor("255 99 71") mcolor("255 99 71")) ///
(connected ingreso_trimestral_real4 year, msymbol(diamond)  lcolor("220 20 60") mcolor("220 20 60")) ///
(connected ingreso_trimestral_real5 year, msymbol(circle_hollow)  lcolor("255 105 180") mcolor("255 105 180")) ///
(connected ingreso_trimestral_real6 year, msymbol(square_hollow)  lcolor("199 21 133") mcolor("199 21 133")) ///
(connected ingreso_trimestral_real7 year, msymbol(triangle_hollow) lcolor("255 182 193") mcolor("255 182 193")) ///
(connected ingreso_trimestral_real8 year, msymbol(diamond_hollow)  lcolor("139 0 0") mcolor("139 0 0")) ///
, ///
xtitle("Año") ///
ytitle("Índice (1992=100)") ///
ylabel(40(20)160, nogrid) ///
xlabel(1990(5)2025) ///
legend(size(small) position(2) ring(0) cols(4)) ///
yline(100, lcolor(black) lpattern(dot))

// Exportar
graph export "$graf\ENIGH_1_8_GRAF3.png", replace
restore


//### 1.8.4 GRAFICA 4: Índices de salario por hora trimestral por grupo
preserve
keep if trabajador_valido==1

// Calcular promedio por grupo
collapse (mean) salario_trimestral_hora [fw=factor], by(year grupo_poblacion)

// Reestructurar: cada grupo en una columna
reshape wide salario_trimestral_hora, i(year) j(grupo_poblacion)

// Normalizar con base 1992=100
foreach x in 1 2 3 4 5 6 7 8 {
    gen w  = salario_trimestral_hora`x' if year==1992
    egen w1 = max(w)
    replace salario_trimestral_hora`x' = (salario_trimestral_hora`x'/w1)*100
    drop w w1
}

// Etiquetas
label variable salario_trimestral_hora1 "Grupo 1"
label variable salario_trimestral_hora2 "Grupo 2"
label variable salario_trimestral_hora3 "Grupo 3"
label variable salario_trimestral_hora4 "Grupo 4"
label variable salario_trimestral_hora5 "Grupo 5"
label variable salario_trimestral_hora6 "Grupo 6"
label variable salario_trimestral_hora7 "Grupo 7"
label variable salario_trimestral_hora8 "Grupo 8"
label variable year "Año"

// Gráfica estilizada
twoway ///
(connected salario_trimestral_hora1 year, msymbol(circle)  lcolor("255 69 0")  mcolor("255 69 0")) ///
(connected salario_trimestral_hora2 year, msymbol(square)  lcolor("178 34 34") mcolor("178 34 34")) ///
(connected salario_trimestral_hora3 year, msymbol(triangle) lcolor("255 99 71") mcolor("255 99 71")) ///
(connected salario_trimestral_hora4 year, msymbol(diamond)  lcolor("220 20 60") mcolor("220 20 60")) ///
(connected salario_trimestral_hora5 year, msymbol(circle_hollow)  lcolor("255 105 180") mcolor("255 105 180")) ///
(connected salario_trimestral_hora6 year, msymbol(square_hollow)  lcolor("199 21 133") mcolor("199 21 133")) ///
(connected salario_trimestral_hora7 year, msymbol(triangle_hollow) lcolor("255 182 193") mcolor("255 182 193")) ///
(connected salario_trimestral_hora8 year, msymbol(diamond_hollow)  lcolor("139 0 0") mcolor("139 0 0")) ///
, ///
xtitle("Año") ///
ytitle("Índice (1992=100)") ///
ylabel(40(20)160, nogrid) ///
xlabel(1990(5)2025) ///
legend(size(small) position(12) ring(0) cols(4)) ///
yline(100, lcolor(black) lpattern(dot))

// Exportar
graph export "$graf\ENIGH_1_8_GRAF4.png", replace
restore

//### 1.8.5 GRAFICA 5: Índices de salario real por hora mensual por grupo
preserve
keep if trabajador_valido==1

// Calcular promedio por grupo
collapse (mean) salario_mensual_hora [fw=factor], by(year grupo_poblacion)

// Reestructurar: cada grupo en una columna
reshape wide salario_mensual_hora, i(year) j(grupo_poblacion)

// Normalizar con base 1992=100
foreach x in 1 2 3 4 5 6 7 8 {
    gen w  = salario_mensual_hora`x' if year==1992
    egen w1 = max(w)
    replace salario_mensual_hora`x' = (salario_mensual_hora`x'/w1)*100
    drop w w1
}

// Etiquetas
label variable salario_mensual_hora1 "Grupo 1"
label variable salario_mensual_hora2 "Grupo 2"
label variable salario_mensual_hora3 "Grupo 3"
label variable salario_mensual_hora4 "Grupo 4"
label variable salario_mensual_hora5 "Grupo 5"
label variable salario_mensual_hora6 "Grupo 6"
label variable salario_mensual_hora7 "Grupo 7"
label variable salario_mensual_hora8 "Grupo 8"
label variable year "Año"

// Gráfica estilizada
twoway ///
(connected salario_mensual_hora1 year, msymbol(circle)  lcolor("255 69 0")  mcolor("255 69 0")) ///
(connected salario_mensual_hora2 year, msymbol(square)  lcolor("178 34 34") mcolor("178 34 34")) ///
(connected salario_mensual_hora3 year, msymbol(triangle) lcolor("255 99 71") mcolor("255 99 71")) ///
(connected salario_mensual_hora4 year, msymbol(diamond)  lcolor("220 20 60") mcolor("220 20 60")) ///
(connected salario_mensual_hora5 year, msymbol(circle_hollow)  lcolor("255 105 180") mcolor("255 105 180")) ///
(connected salario_mensual_hora6 year, msymbol(square_hollow)  lcolor("199 21 133") mcolor("199 21 133")) ///
(connected salario_mensual_hora7 year, msymbol(triangle_hollow) lcolor("255 182 193") mcolor("255 182 193")) ///
(connected salario_mensual_hora8 year, msymbol(diamond_hollow)  lcolor("139 0 0") mcolor("139 0 0")) ///
, ///
xtitle("Año") ///
ytitle("Índice (1992=100)") ///
ylabel(40(20)160, nogrid) ///
xlabel(1990(5)2025) ///
legend(size(small) position(2) ring(0) cols(4)) ///
yline(100, lcolor(black) lpattern(dot))

// Exportar
graph export "$graf\ENIGH_1_8_GRAF5.png", replace
restore

//### 1.8.6 GRAFICA 6: Brechas relativas en salario real por hora mensual
preserve
keep if trabajador_valido==1

// Calcular promedios
collapse (mean) salario_mensual_hora [fw=factor], by(year grupo_poblacion)
reshape wide salario_mensual_hora, i(year) j(grupo_poblacion)

// Normalizar con base 1992=100
foreach x in 1 2 3 4 5 6 7 8 {
    gen w = salario_mensual_hora`x' if year==1992
    egen w1 = max(w)
    replace salario_mensual_hora`x' = (salario_mensual_hora`x'/w1)*100
    drop w w1
}

// Calcular brechas respecto al grupo 4 (hombres jóvenes, alta educación)
foreach x in 1 2 3 5 6 7 8 {
    gen Brecha`x' = (salario_mensual_hora`x'/salario_mensual_hora4)*100
}

// Graficar brechas
twoway ///
(connected Brecha1 year, msymbol(circle) lcolor("255 69 0") mcolor("255 69 0")) ///
(connected Brecha2 year, msymbol(square) lcolor("178 34 34") mcolor("178 34 34")) ///
(connected Brecha3 year, msymbol(triangle) lcolor("255 99 71") mcolor("255 99 71")) ///
(connected Brecha5 year, msymbol(diamond) lcolor("220 20 60") mcolor("220 20 60")) ///
(connected Brecha6 year, msymbol(circle_hollow) lcolor("199 21 133") mcolor("199 21 133")) ///
(connected Brecha7 year, msymbol(triangle_hollow) lcolor("255 182 193") mcolor("255 182 193")) ///
(connected Brecha8 year, msymbol(diamond_hollow) lcolor("139 0 0") mcolor("139 0 0")) ///
, ///
xtitle("Año") ///
ytitle("Salario relativo al Grupo 4 (%)") ///
ylabel(40(20)160, nogrid) ///
xlabel(1990(5)2025) ///
legend(size(vsmall) position(4) ring(0) cols(4)) ///
yline(100, lcolor(black) lpattern(longdash))

graph export "$graf\ENIGH_1_8_GRAF6.png", replace
restore

//======================================================
//### 1.8.7 GRAFICA 7 - Distribución del salario mensual por hora
//     Boxplots por grupo de población en un año
//======================================================

preserve
keep if trabajador_valido==1 & year==2024 & ingreso_mensual_real>0 & !missing(ingreso_mensual_real)

// Gráfico boxplot panorámico
graph box ingreso_mensual_real [fw=factor], ///
    over(grupo_poblacion, relabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8") ///
         label(labsize(huge))) ///
    nooutsides ///
    title("2024", size(huge)) ///
    ytitle("Ingreso mensual real", size(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    note("") ///
    box(1, color("255 69 0")) box(2, color("255 69 0")) box(3, color("255 69 0")) ///
    box(4, color("255 69 0")) box(5, color("255 69 0")) box(6, color("255 69 0")) ///
    box(7, color("255 69 0")) box(8, color("255 69 0")) ///
    marker(1, mcolor("255 69 0")) marker(2, mcolor("255 69 0")) ///
    marker(3, mcolor("255 69 0")) marker(4, mcolor("255 69 0")) ///
    marker(5, mcolor("255 69 0")) marker(6, mcolor("255 69 0")) ///
    marker(7, mcolor("255 69 0")) marker(8, mcolor("255 69 0")) ///
    scheme(s1color) ///
    xsize(12) ysize(4)

graph export "$graf/ENIGH_1_8_GRAF7.png", replace width(1800) height(700)
restore


//======================================================
//### 1.8.8 BOX Distribución del salario mensual por hora
//     Boxplots por grupo de población en un año
//======================================================

preserve
keep if trabajador_valido==1 & inlist(year,2016,2018,2020,2022) ///
    & ingreso_mensual_real>0 & !missing(ingreso_mensual_real)

// Definir colores de la paleta
local col2016 "255 69 0"      // naranja rojizo
local col2018 "178 34 34"     // rojo vino
local col2020 "255 99 71"     // tomato
local col2022 "220 20 60"     // crimson

// Loop para generar y exportar cada gráfico
foreach y in 2016 2018 2020 2022 {
    local color = cond(`y'==2016, "`col2016'", ///
                 cond(`y'==2018, "`col2018'", ///
                 cond(`y'==2020, "`col2020'", "`col2022'")))
    
    graph box ingreso_mensual_real [fw=factor] if year==`y', ///
        over(grupo_poblacion, relabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8") ///
             label(labsize(huge))) ///
        nooutsides ///
        title("`y'", size(huge)) ///
        ytitle("Ingreso mensual real", size(huge)) ///
        ylabel(, labsize(huge) angle(horizontal) grid) ///
        note("") ///
        box(1, color("`color'")) box(2, color("`color'")) box(3, color("`color'")) ///
        box(4, color("`color'")) box(5, color("`color'")) box(6, color("`color'")) ///
        box(7, color("`color'")) box(8, color("`color'")) ///
        marker(1, mcolor("`color'")) marker(2, mcolor("`color'")) ///
        marker(3, mcolor("`color'")) marker(4, mcolor("`color'")) ///
        marker(5, mcolor("`color'")) marker(6, mcolor("`color'")) ///
        marker(7, mcolor("`color'")) marker(8, mcolor("`color'")) ///
        scheme(s1color) ///
        xsize(12) ysize(4)

    // Exportar cada gráfico con su nombre
    graph export "$graf/ENIGH_1_8_GRAF7_`y'.png", replace width(1800) height(700)
}

restore


//## 1.9 PROPRCIÓN DE TRABJADORES

//======================================================
//### 1.9 - Tabla de proporción de trabajadores en la población
//======================================================
preserve
keep if !missing(grupo_poblacion) & !missing(trabajador_valido)

// Calcular proporción ponderada de trabajadores por grupo y año
collapse (mean) trabajador_valido [fw=factor], by(year grupo_poblacion)

// Pasar a formato wide (cada grupo como columna)
reshape wide trabajador_valido, i(year) j(grupo_poblacion)

// Etiquetas
label variable year "Año"
label variable trabajador_valido1 "Grupo 1"
label variable trabajador_valido2 "Grupo 2"
label variable trabajador_valido3 "Grupo 3"
label variable trabajador_valido4 "Grupo 4"
label variable trabajador_valido5 "Grupo 5"
label variable trabajador_valido6 "Grupo 6"
label variable trabajador_valido7 "Grupo 7"
label variable trabajador_valido8 "Grupo 8"

// ---- Exportar a LaTeX ----
file open tabla using "$graf\ENIGH_1_9.tex", write replace
file write tabla "\begin{tabular}{lcccccccc}" _n
file write tabla "\hline" _n
file write tabla "Año & \shortstack{Grupo \\ 1} & \shortstack{Grupo \\ 2} & \shortstack{Grupo \\ 3} & \shortstack{Grupo \\ 4} & \shortstack{Grupo \\ 5} & \shortstack{Grupo \\ 6} & \shortstack{Grupo \\ 7} & \shortstack{Grupo \\ 8} \\\\" _n
file write tabla "\hline" _n

quietly {
    forvalues i = 1/`=_N' {
        local y  = year[`i']
        local g1 = string(trabajador_valido1[`i']*100, "%9.2f")
        local g2 = string(trabajador_valido2[`i']*100, "%9.2f")
        local g3 = string(trabajador_valido3[`i']*100, "%9.2f")
        local g4 = string(trabajador_valido4[`i']*100, "%9.2f")
        local g5 = string(trabajador_valido5[`i']*100, "%9.2f")
        local g6 = string(trabajador_valido6[`i']*100, "%9.2f")
        local g7 = string(trabajador_valido7[`i']*100, "%9.2f")
        local g8 = string(trabajador_valido8[`i']*100, "%9.2f")
        file write tabla "`y' & `g1' & `g2' & `g3' & `g4' & `g5' & `g6' & `g7' & `g8' \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla
restore

//### 1.9.1 - Proporción total de trabajadores en la población por año
preserve
keep if !missing(trabajador_valido)

// Crear indicador de trabajador válido (1=trabajador, 0=no trabajador)
gen trab = trabajador_valido==1

// Calcular proporción ponderada de trabajadores por año
collapse (mean) trab [iw=factor], by(year)
replace trab = trab*100   // pasar a porcentaje

label variable year "Año"
label variable trab "Proporción de trabajadores (%)"

// ---- Exportar a LaTeX ----
file open tabla using "$graf\ENIGH_1_9_TOT.tex", write replace
file write tabla "\begin{tabular}{lc}" _n
file write tabla "\hline" _n
file write tabla "Año & \shortstack{Proporción de \\ trabajadores (\%)} \\\\" _n
file write tabla "\hline" _n

quietly {
    forvalues i = 1/`=_N' {
        local y = year[`i']
        local p = string(trab[`i'], "%9.2f")
        file write tabla "`y' & `p' \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla
restore

//### 1.9.2 BUBBLE PLOT

preserve
keep if year == 2024 & inrange(grupo_poblacion,1,8) & !missing(trabajador_valido)

* Calcular proporción y número de válidos
collapse (mean) prop_trab = trabajador_valido ///
         (sum)  n_validos = trabajador_valido, by(grupo_poblacion)

* Graficar: usar n_validos como weight
twoway scatter prop_trab grupo_poblacion [aweight = n_validos], ///
    msymbol(O) mcolor("255 69 0") ///
    xlabel(1(1)8) ///
    ylabel(0(.1)1) yscale(range(0 1)) ///
    title("2024") ///
    xtitle("Grupo") ///
    ytitle("Proporción de Trabajadores Válidos") ///
    legend(off)

* Exportar a carpeta definida en global grf
graph export "$graf/ENIGH_1_9_BUBBLE.png", replace
restore



//### 1.9.3 BUBBLE PLOT con relleno semitransparente y contorno sólido

preserve
keep if inlist(grupo_poblacion,1,7) & trabajador_valido == 1 & inrange(year, 1992, 2024)

collapse (mean) salario_mensual = ingreso_mensual ///
         (count) n_validos = ingreso_mensual, by(year grupo_poblacion)

twoway ///
    (scatter salario_mensual year if grupo_poblacion==1 [aweight = n_validos], ///
        msymbol(O) mcolor("255 69 0%50") mlcolor("255 69 0")) ///
    (scatter salario_mensual year if grupo_poblacion==7 [aweight = n_validos], ///
        msymbol(O) mcolor("30 144 255%50") mlcolor("30 144 255")), ///
    xlabel(1992(2)2024, angle(45)) ///
    xtitle("Año") ///
    ytitle("Salario Real Mensual") ///
    legend(order(1 "Grupo 1" 2 "Grupo 7") row(1) pos(2) ring(0) region(lstyle(none)))

graph export "$graf/ENIGH_BUBBLE_SALARIO_G1_G7.png", replace
restore


//### 1.9.4 Bubble Scatter: Mujeres baja educación, 25–45 vs. 46–65

preserve
keep if inlist(grupo_poblacion,1,5) & trabajador_valido == 1 & inrange(year, 1992, 2024)

collapse (mean) salario_mensual = ingreso_mensual ///
         (count) n_validas = ingreso_mensual, by(year grupo_poblacion)

twoway ///
    (scatter salario_mensual year if grupo_poblacion==1 [aweight = n_validas], ///
        msymbol(O) mcolor("255 69 0%50") mlcolor("255 69 0")) ///
    (scatter salario_mensual year if grupo_poblacion==5 [aweight = n_validas], ///
        msymbol(O) mcolor("30 144 255%50") mlcolor("30 144 255")), ///
    xlabel(1992(2)2024, angle(45)) ///
    xtitle("Año") ///
    ytitle("Salario Real Mensual") ///
    legend(order(1 "Grupo 1" 2 "Grupo 5") ///
           row(1) pos(2) ring(0) region(lstyle(none)))

graph export "$graf/ENIGH_BUBBLE_SALARIO_G1_G5.png", replace
restore








************************************************************

                  //#3 REGRESION CUANTIL , baby
				
************************************************************

//===============================================================
//### PASO 1: Cargar base ajustada y quedarnos solo con 2018 y 2024
//===============================================================
use "$ENIGH/ENIGH_TRABAJADORES_AJUSTADA.dta", clear

* Nos quedamos únicamente con 2018 y 2024
keep if year == 2018 | year == 2024


//===============================================================
//### PASO 2: Generar cuantiles del log salario por hora (por sexo)
//===============================================================
* xtile genera cuantiles (1–100) ponderando por fac
foreach x in 2018 2024 {
    xtile q`x'_h = linghrs [aw=fac] if year == `x' & sex == 0, nq(100)   // hombres
    xtile q`x'_m = linghrs [aw=fac] if year == `x' & sex == 1, nq(100)   // mujeres
}


//===============================================================
//### PASO 3: Unificar cuantiles en una sola variable
//===============================================================
gen cuantil = .
foreach x in 2018 2024 {
    replace cuantil = q`x'_h if year == `x' & sex == 0
    replace cuantil = q`x'_m if year == `x' & sex == 1
}


//===============================================================
//### PASO 4: Colapsar log salario por hora por cuantil, sexo y año
//===============================================================
* Promedio del log salario por hora en cada cuantil y sexo
collapse (mean) linghrs, by(cuantil sex year)

* Reestructuramos para tener columnas por año
reshape wide linghrs, i(cuantil sex) j(year)

* Ordenamos
sort sex cuantil
drop if cuantil == .


//===============================================================
//### PASO 5: Ajuste de valores faltantes
//===============================================================
* Rellenamos valores faltantes de forma local con promedios vecinos
foreach var in linghrs2018 linghrs2024 {
    replace `var' = (`var'[_n-1]+`var'[_n+1])/2 if ///
        `var' == . & `var'[_n-1] != . & `var'[_n+1] != .
    replace `var' = (`var'[_n-1]+`var'[_n+2])/2 if ///
        `var' == . & `var'[_n-1]!=. & `var'[_n+2]!=.
    replace `var' = (`var'[_n-1]+`var'[_n+1])/2 if ///
        `var' == . & `var'[_n-1]!=. & `var'[_n+1]!=.
}


//===============================================================
//### PASO 6: Calcular diferencias entre 2018 y 2024
//===============================================================
gen dlw = (linghrs2024 - linghrs2018) * 100


******************************************************************
//## 3.3 GRAFICAS DE LOGS DE SALARIO 2018 VS 2024 PERCENTILES

******************************************************************


//### PASO 7: Gráfica del cambio en log salario por hora (2018–2024) HOMBRES

preserve


capture drop y_top y_bot
gen y_top = 50  // techo del eje Y
gen y_bot = -10   // piso del eje Y


twoway ///
    (rarea y_top y_bot cuantil if sex==0 & inrange(cuantil,0,10), ///
        fcolor(gs12%25) lcolor(white)) ///
    (rarea y_top y_bot cuantil if sex==0 & inrange(cuantil,90,100), ///
        fcolor(gs12%25) lcolor(white)) ///
    (connected dlw cuantil if sex==0, ///
        lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(vthin) msize(0.4)) ///
    (lowess dlw cuantil if sex==0, ///
        lcolor("24 116 205%25") lwidth(medthick)), ///
    xtitle("Cuantiles", size(medium)) ///
    ytitle("Δ Log salario por hora (2018–2024)", size(medium)) ///
    xlabel(0(10)100, labsize(small)) ///
    ylabel(, labsize(small) angle(horizontal) grid) ///
    legend(off) ///
    graphregion(color(white)) plotregion(lstyle(none)) ///
    xline(50, lcolor(red) lpattern(dot))

graph export "$graf/ENIGH_3_3_HOMBRES.png", replace


restore

//### PASO 8: Versión simplificada MUJERES
preserve

capture drop y_top y_bot
gen y_top = 50   // techo del eje Y
gen y_bot = -10    // piso del eje Y


twoway ///
    (rarea y_top y_bot cuantil if sex==1 & inrange(cuantil,0,10), ///
        fcolor(gs12%25) lcolor(white)) ///
    (rarea y_top y_bot cuantil if sex==1 & inrange(cuantil,90,100), ///
        fcolor(gs12%25) lcolor(white)) ///
    (connected dlw cuantil if sex==1, ///
        lcolor("25 175 0") mcolor("25 175 0") lwidth(vthin) msize(0.4)) ///
    (lowess dlw cuantil if sex==1, ///
        lcolor("24 116 205%25") lwidth(medthick)), ///
    xtitle("Cuantiles", size(medium)) ///
    ytitle("Δ Log salario por hora (2018–2024)", size(medium)) ///
    xlabel(0(10)100, labsize(small)) ///
    ylabel(, labsize(small) angle(horizontal) grid) ///
    legend(off) ///
    graphregion(color(white)) plotregion(lstyle(none)) ///
    xline(50, lcolor(red) lpattern(dot))

graph export "$graf/ENIGH_3_3_MUJERES.png", replace


restore

//#### PASO 8A Gráfica conjunta Hombres Mujeres
preserve

capture drop y_top y_bot
gen y_top = 50   // techo del eje Y
gen y_bot = -10  // piso del eje Y

twoway ///
    (rarea y_top y_bot cuantil if sex==0 & inrange(cuantil,0,10), ///
        fcolor(gs12%25) lcolor(white)) ///
    (rarea y_top y_bot cuantil if sex==0 & inrange(cuantil,90,100), ///
        fcolor(gs12%25) lcolor(white)) ///
    (connected dlw cuantil if sex==0, ///
        lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(thick) msize(2)) ///
    (lowess dlw cuantil if sex==0, ///
        lcolor("255 69 0%25") lwidth(medthick)), ///
    xtitle("Cuantil" , size(huge)) ///
    ytitle("Δ Log salario por hora (2018–2024)", size(huge)) ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(3 "Hombres") position(12) ring(0) cols(1) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none)) ///
    xline(50, lcolor(red) lpattern(dot) lwidth(thick))

graph save "$graf/ENIGH_HOMBRES.gph", replace


//#### PASO 8B Gráfica MUJERES (sin títulos de ejes)

capture drop y_top y_bot
gen y_top = 50   // techo del eje Y
gen y_bot = -10  // piso del eje Y

twoway ///
    (rarea y_top y_bot cuantil if sex==1 & inrange(cuantil,0,10), ///
        fcolor(gs12%25) lcolor(white)) ///
    (rarea y_top y_bot cuantil if sex==1 & inrange(cuantil,90,100), ///
        fcolor(gs12%25) lcolor(white)) ///
    (connected dlw cuantil if sex==1, ///
        lcolor("24 116 205") mcolor("24 116 205") ///
        lwidth(thick) msize(2)) ///
    (lowess dlw cuantil if sex==1, ///
        lcolor("24 116 205%25") lwidth(medthick)), ///
    xtitle("Cuantil", size(huge)) ///
    ytitle("") ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(3 "Mujeres") position(12) ring(0) cols(1) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none)) ///
    xline(50, lcolor(red) lpattern(dot) lwidth(thick))

graph save "$graf/ENIGH_MUJERES.gph", replace



//### PASO FINAL: Combinar gráficas HOMBRES y MUJERES

graph combine "$graf/ENIGH_HOMBRES.gph" "$graf/ENIGH_MUJERES.gph", ///
    col(2) graphregion(color(white)) ///
    ycommon xcommon imargin(0 0 0 0) ///
    ysize(4) xsize(12) ///
    name(GrafConjunta, replace)

// Exportar en PNG
graph export "$graf/ENIGH_3_3_MH.png", replace width(2000)

restore

//### PASO GRAFICA CONJUNTA 

preserve

capture drop y_top y_bot
gen y_top = 50   // techo del eje Y
gen y_bot = -10  // piso del eje Y

twoway ///
    (rarea y_top y_bot cuantil if inrange(cuantil,0,10), ///
        fcolor(gs12%25) lcolor(white)) ///
    (rarea y_top y_bot cuantil if inrange(cuantil,90,100), ///
        fcolor(gs12%25) lcolor(white)) ///
    (connected dlw cuantil if sex==0, ///
        lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(vthin) msize(0.6)) ///
    (lowess dlw cuantil if sex==0, ///
        lcolor("255 69 0%40") lwidth(medthick)) ///
    (connected dlw cuantil if sex==1, ///
        lcolor("24 116 205") mcolor("24 116 205") ///
        lwidth(vthin) msize(0.6)) ///
    (lowess dlw cuantil if sex==1, ///
        lcolor("24 116 205%40") lwidth(medthick)), ///
    xtitle("Cuantiles", size(large)) ///
    ytitle("Δ Log salario por hora (2018–2024)", size(large)) ///
    xlabel(0(10)100, labsize(large)) ///
    ylabel(, labsize(large) angle(horizontal) grid) ///
    legend(order(3 "Hombres" 5 "Mujeres") ///
           position(12) ring(0) cols(2) size(medsmall)) ///
    graphregion(color(white)) plotregion(lstyle(none)) ///
    xline(50, lcolor(red) lpattern(dot)) ///
yline(0, lcolor(red) lpattern(dot) lwidth(thick))


graph export "$graf/ENIGH_3_31_HOMBRES_MUJERES.png", replace

restore

******************************************************************
//## 3.4 REGRESION QUANTIL
******************************************************************

//==========================================================
//### PASO 1: Cargar base ajustada y filtrar años de interés
//==========================================================
use "$ENIGH\ENIGH_TRABAJADORES_AJUSTADA.dta", clear
keep if inlist(year, 2018, 2024)

//==========================================================
//### PASO 2: Variables explicativas
//==========================================================

// Edad al cuadrado
capture confirm variable edad2
if _rc gen edad2 = edad^2

// Rural: 1 si tam_loc==4, 0 en otro caso
destring tam_loc, replace
qui gen rural = 0
qui replace rural = 1 if tam_loc==4

// Female: 1 si sex==1, 0 en otro caso
qui gen female = 0
qui replace female = 1 if sex==1

// Eliminamos missings en variable dependiente
drop if missing(linghrs)

// Lista de regresores
global X "anios_esc edad edad2 rural female"

//==========================================================
//### PASO 2.1: OLS robusto por AÑO con preserve/restore
//==========================================================
foreach y of numlist 2018 2024 {
    preserve
        reg linghrs $X [fw=factor] if year==`y', robust

        esttab using "$graf/OLS_`y'.tex", replace ///
            label booktabs fragment nomtitles ///
            cells("b(fmt(3) star) se(fmt(3)) t(fmt(2)) p(fmt(3)) ci(fmt(3))") ///
            collabels("Coeficiente" "Error Est." "t" "p" "[95\% CI]") ///
            alignment(l|c|c|c|c|c) ///
            varlabels(anios_esc "Escolaridad" ///
                      edad "Edad" ///
                      edad2 "Edad$^2$" ///
                      rural "Rural" ///
                      female "Mujer" ///
                      _cons "Constante") ///
            stats(N r2, labels("N" "R$^2$") fmt(0 3))

        di as text "OLS `y' exportado a $graf/OLS_`y'.tex"
    restore
}




//==========================================================
//### PASO 3: Construir variable de cuantiles (1..100) por año
//==========================================================
quietly foreach y of numlist 2018 2024 {
    xtile q`y'_h = linghrs [aw=factor] if year==`y', nq(100)
}

gen quant = .
replace quant = q2018_h if year==2018
replace quant = q2024_h if year==2024
drop q2018_h q2024_h
drop if missing(quant)

//==========================================================
//### PASO 4: Crear base de resultados
//==========================================================
preserve
keep year quant
duplicates drop
// Betas y SE de cada variable
gen beta_ols_anios_esc = .
gen beta_q_anios_esc   = .
gen se_q_anios_esc     = .
gen beta_ols_edad      = .
gen beta_q_edad        = .
gen se_q_edad          = .
gen beta_ols_edad2     = .
gen beta_q_edad2       = .
gen se_q_edad2         = .
gen beta_ols_female    = .
gen beta_q_female      = .
gen se_q_female        = .
gen beta_ols_rural     = .
gen beta_q_rural       = .
gen se_q_rural         = .
save "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", replace
restore   // volvemos a la base ajustada con factor (pero nunca la guardamos)

//==========================================================
//### PASO 5: Estimar OLS por año y guardar resultados
//==========================================================
foreach y of numlist 2018 2024 {
    reg linghrs $X [fw=factor] if year==`y', robust

    // abrir base de resultados y actualizar
    use "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", clear
    replace beta_ols_anios_esc = _b[anios_esc] if year==`y'
    replace beta_ols_edad      = _b[edad]      if year==`y'
    replace beta_ols_edad2     = _b[edad2]     if year==`y'
    replace beta_ols_female    = _b[female]    if year==`y'
    replace beta_ols_rural     = _b[rural]     if year==`y'
    save "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", replace

    // volver a la base ajustada sin modificarla
    use "$ENIGH\ENIGH_TRABAJADORES_AJUSTADA.dta", clear
    keep if inlist(year, 2018, 2024)
    capture confirm variable edad2
    if _rc gen edad2 = edad^2
    destring tam_loc, replace
    qui gen rural = 0
    qui replace rural = 1 if tam_loc==4
    qui gen female = 0
    qui replace female = 1 if sex==1

    di as text "`y' OLS listo"
}

//==========================================================
//### PASO 6: Estimar regresiones cuantílicas y guardar
//==========================================================
forvalues q = 1/99 {
    local tau = `q'/100
    foreach y of numlist 2018 2024 {
        // usar base ajustada limpia
        use "$ENIGH\ENIGH_TRABAJADORES_AJUSTADA.dta", clear
        keep if inlist(year, 2018, 2024)
        capture confirm variable edad2
        if _rc gen edad2 = edad^2
        destring tam_loc, replace
        qui gen rural = 0
        qui replace rural = 1 if tam_loc==4
        qui gen female = 0
        qui replace female = 1 if sex==1

        quietly qreg linghrs $X [pw=factor] if year==`y', q(`tau') vce(robust)

        // abrir base de resultados y actualizar
        use "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", clear
        replace beta_q_anios_esc = _b[anios_esc] if year==`y' & quant==`q'
        replace se_q_anios_esc   = _se[anios_esc] if year==`y' & quant==`q'
        replace beta_q_edad      = _b[edad]      if year==`y' & quant==`q'
        replace se_q_edad        = _se[edad]     if year==`y' & quant==`q'
        replace beta_q_edad2     = _b[edad2]     if year==`y' & quant==`q'
        replace se_q_edad2       = _se[edad2]    if year==`y' & quant==`q'
        replace beta_q_female    = _b[female]    if year==`y' & quant==`q'
        replace se_q_female      = _se[female]   if year==`y' & quant==`q'
        replace beta_q_rural     = _b[rural]     if year==`y' & quant==`q'
        replace se_q_rural       = _se[rural]    if year==`y' & quant==`q'
        save "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", replace

        di as text "`y' cuantil `q' listo"
    }
}

//==========================================================
//### PASO 7: Ordenar y etiquetar dataset final
//==========================================================
use "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", clear

order year quant beta_ols_* beta_q_* se_q_*
sort year quant

label var year  "Año"
label var quant "Cuantil (1-99)"

save "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", replace



//==========================================================
//##3.6 GRAFICAS REG QUANTIL ESCOLARIDAD GENERO
//==========================================================



//###2018 Grafica de Reg Cuantil Escolaridad

use "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", clear
keep if year==2018

// Intervalos de confianza 95% para escolaridad (solo cuantiles)
gen lb_q_escol = beta_q_anios_esc - 1.96*se_q_anios_esc
gen hb_q_escol = beta_q_anios_esc + 1.96*se_q_anios_esc

// Graficar
twoway ///
    (rarea lb_q_escol hb_q_escol quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_anios_esc quant, ///
        lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_anios_esc quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medthin)), ///
    xtitle("Cuantil") ///
    ytitle("Cambio en el ln del salario por hora") ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(13) ring(0) cols(3)) ///
    note(" ")

// Guardar
graph export "$graf\QUANTIL_ESC_3_6_2018.png", replace


//###2018 Grafica de Reg Cuantil Female

use "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", clear
keep if year==2018

// Intervalos de confianza 95% para female (solo cuantiles)
gen lb_q_fem = beta_q_female - 1.96*se_q_female
gen hb_q_fem = beta_q_female + 1.96*se_q_female

// Graficar
twoway ///
    (rarea lb_q_fem hb_q_fem quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_female quant, ///
        lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_female quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medthin)), ///
    xtitle("Cuantil") ///
    ytitle("Cambio en el ln del salario por hora") ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(10) ring(0) cols(3)) ///
    note(" ")

// Guardar
graph export "$graf\QUANTIL_FEM_3_6_2018.png", replace


//###2018 Grafica de Reg Cuantil Rural

use "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", clear
keep if year==2018

// Intervalos de confianza 95% para rural (solo cuantiles)
gen lb_q_rural = beta_q_rural - 1.96*se_q_rural
gen hb_q_rural = beta_q_rural + 1.96*se_q_rural

// Graficar
twoway ///
    (rarea lb_q_rural hb_q_rural quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_rural quant, ///
        lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_rural quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medthin)), ///
    xtitle("Cuantil") ///
    ytitle("Cambio en el ln del salario por hora") ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(11) ring(0) cols(3)) ///
    note(" ")

// Guardar
graph export "$graf\QUANTIL_RURAL_3_6_2018.png", replace


//###2018 Grafica de Reg Cuantil Edad

use "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", clear
keep if year==2018

// Intervalos de confianza 95% para edad (solo cuantiles)
gen lb_q_edad = beta_q_edad - 1.96*se_q_edad
gen hb_q_edad = beta_q_edad + 1.96*se_q_edad

// Graficar
twoway ///
    (rarea lb_q_edad hb_q_edad quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_edad quant, ///
        lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(vthin) msize(0.3)) ///
    (connected beta_ols_edad quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medthin)), ///
    xtitle("Cuantil") ///
    ytitle("Cambio en el ln del salario por hora") ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(1) ring(0) cols(1)) ///
    note(" ")

// Guardar
graph export "$graf\QUANTIL_EDAD_3_6_2018.png", replace



//###2018 Grafica de Reg Cuantil Edad^2

use "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", clear
keep if year==2018

// Intervalos de confianza 95% para edad2 (solo cuantiles)
gen lb_q_edad2 = beta_q_edad2 - 1.96*se_q_edad2
gen hb_q_edad2 = beta_q_edad2 + 1.96*se_q_edad2

// Graficar
twoway ///
    (rarea lb_q_edad2 hb_q_edad2 quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_edad2 quant, ///
        lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(vthin) msize(0.3)) ///
    (connected beta_ols_edad2 quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medthin)), ///
    xtitle("Cuantil") ///
    ytitle("Cambio en el ln del salario por hora") ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(1) ring(0) cols(1)) ///
    note(" ")

// Guardar
graph export "$graf\QUANTIL_EDAD2_3_6_2018.png", replace

//###2024 Grafica de Reg Cuantil Escolaridad (2024)

use "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", clear
keep if year==2024

// Intervalos de confianza 95% para escolaridad (solo cuantiles)
gen lb_q_escol = beta_q_anios_esc - 1.96*se_q_anios_esc
gen hb_q_escol = beta_q_anios_esc + 1.96*se_q_anios_esc

// Graficar
twoway ///
    (rarea lb_q_escol hb_q_escol quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_anios_esc quant, ///
        lcolor("24 116 205") mcolor("24 116 205") ///
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_anios_esc quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medthin)), ///
    xtitle("Cuantil") ///
    ytitle("Cambio en el ln del salario por hora") ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(1) ring(0) cols(3)) ///
    note(" ")

// Guardar
graph export "$graf\QUANTIL_ESC_2024.png", replace

//###2024 Grafica de Reg Cuantil Female (2024)

use "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", clear
keep if year==2024

// Intervalos de confianza 95% para female (solo cuantiles)
gen lb_q_fem = beta_q_female - 1.96*se_q_female
gen hb_q_fem = beta_q_female + 1.96*se_q_female

// Graficar
twoway ///
    (rarea lb_q_fem hb_q_fem quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_female quant, ///
        lcolor("24 116 205") mcolor("24 116 205") ///
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_female quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medthin)), ///
    xtitle("Cuantil") ///
    ytitle("Cambio en el ln del salario por hora") ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(5) ring(0) cols(3)) ///
    note(" ")

// Guardar
graph export "$graf\QUANTIL_FEM_2024.png", replace

//###2024 Grafica de Reg Cuantil Rural (2024)

use "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", clear
keep if year==2024

// Intervalos de confianza 95% para rural (solo cuantiles)
gen lb_q_rural = beta_q_rural - 1.96*se_q_rural
gen hb_q_rural = beta_q_rural + 1.96*se_q_rural

// Graficar
twoway ///
    (rarea lb_q_rural hb_q_rural quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_rural quant, ///
        lcolor("24 116 205") mcolor("24 116 205") ///
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_rural quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medthin)), ///
    xtitle("Cuantil") ///
    ytitle("Cambio en el ln del salario por hora") ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(11) ring(0) cols(3)) ///
    note(" ")

// Guardar
graph export "$graf\QUANTIL_RURAL_2024.png", replace


//###2024 Grafica de Reg Cuantil Edad (2024)

use "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", clear
keep if year==2024

// Intervalos de confianza 95% para edad (solo cuantiles)
gen lb_q_edad = beta_q_edad - 1.96*se_q_edad
gen hb_q_edad = beta_q_edad + 1.96*se_q_edad

// Graficar
twoway ///
    (rarea lb_q_edad hb_q_edad quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_edad quant, ///
        lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(vthin) msize(0.3)) ///
    (connected beta_ols_edad quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medthin)), ///
    xtitle("Cuantil") ///
    ytitle("Cambio en el ln del salario por hora") ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(1) ring(0) cols(1)) ///
    note(" ")

// Guardar
graph export "$graf\QUANTIL_EDAD_2024.png", replace

//###2024 Grafica de Reg Cuantil Edad^2 (2024)

use "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", clear
keep if year==2024

// Intervalos de confianza 95% para edad2 (solo cuantiles)
gen lb_q_edad2 = beta_q_edad2 - 1.96*se_q_edad2
gen hb_q_edad2 = beta_q_edad2 + 1.96*se_q_edad2

// Graficar
twoway ///
    (rarea lb_q_edad2 hb_q_edad2 quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_edad2 quant, ///
        lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(vthin) msize(0.3)) ///
    (connected beta_ols_edad2 quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medthin)), ///
    xtitle("Cuantil") ///
    ytitle("Cambio en el ln del salario por hora") ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(1) ring(0) cols(1)) ///
    note(" ")

// Guardar
graph export "$graf\QUANTIL_EDAD2_2024.png", replace



//==========================================================
//### 2018 vs 2024 ESCOLARIDAD
//==========================================================

//#### 2018 ESCOLARIDAD
use "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", clear
keep if year==2018

gen lb_q_escol = beta_q_anios_esc - 1.96*se_q_anios_esc
gen hb_q_escol = beta_q_anios_esc + 1.96*se_q_anios_esc

twoway ///
    (rarea lb_q_escol hb_q_escol quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_anios_esc quant, ///
        lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_anios_esc quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2018 ", size(huge)) ///
    ytitle("Cambio en el ln del salario por hora", size(huge)) ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(12) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/ESC_2018.gph", replace


//#### 2024 ESCOLARIDAD
use "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", clear
keep if year==2024

gen lb_q_escol = beta_q_anios_esc - 1.96*se_q_anios_esc
gen hb_q_escol = beta_q_anios_esc + 1.96*se_q_anios_esc

twoway ///
    (rarea lb_q_escol hb_q_escol quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_anios_esc quant, ///
        lcolor("24 116 205") mcolor("24 116 205") ///
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_anios_esc quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2024", size(huge)) ///
    ytitle("") /// ← sin título de Y en la derecha
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
	legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(12) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/ESC_2024.gph", replace


//#### COMBINADA ESCOLARIDAD
graph combine "$graf/ESC_2018.gph" "$graf/ESC_2024.gph", ///
    col(2) graphregion(color(white)) ///
    ycommon xcommon imargin(0 0 0 0) ///
    ysize(5) xsize(13) ///
    name(Graf_ESC_Conjunta, replace)

graph export "$graf/ESC_2018_2024.png", replace width(4000)


//==========================================================
//### 2018 vs 2024 FEMALE
//==========================================================

//#### 2018 FEMALE
use "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", clear
keep if year==2018

gen lb_q_fem = beta_q_female - 1.96*se_q_female
gen hb_q_fem = beta_q_female + 1.96*se_q_female

twoway ///
    (rarea lb_q_fem hb_q_fem quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_female quant, ///
        lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_female quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2018", size(huge)) ///
    ytitle("Cambio en el ln del salario por hora", size(huge)) ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(12) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/FEM_2018.gph", replace


//#### 2024 FEMALE
use "$ENIGH\REGRESION_CUANTIL_2018_2024.dta", clear
keep if year==2024

gen lb_q_fem = beta_q_female - 1.96*se_q_female
gen hb_q_fem = beta_q_female + 1.96*se_q_female

twoway ///
    (rarea lb_q_fem hb_q_fem quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_female quant, ///
        lcolor("24 116 205") mcolor("24 116 205") ///
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_female quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2024", size(huge)) ///
    ytitle("") ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(12) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/FEM_2024.gph", replace


//#### COMBINADA FEMALE
graph combine "$graf/FEM_2018.gph" "$graf/FEM_2024.gph", ///
    col(2) graphregion(color(white)) ///
    ycommon xcommon imargin(0 0 0 0) ///
    ysize(5) xsize(13) ///
    name(Graf_FEM_Conjunta, replace)

graph export "$graf/FEM_2018_2024.png", replace width(4000)


************************************************************

                  //#4 BOOTSTRAP
				
************************************************************

//## LIMPIEZA

clear
use "$ENIGH\ENIGH_TRABAJADORES_AJUSTADA.dta", clear
keep if year == 2024

* Ajustar factores si fuera necesario
rename factor factorhog, replace
rename fac factor, replace

* Crear edad^2
gen edad2 = edad^2

* Crear dummy rural
gen rural = 0
replace rural = 1 if tam_loc==4

* Crear dummy female (1 si mujer, 0 si hombre)
gen female = 0
replace female = 1 if sexo==2

* Guardar base lista para bootstrap
save "$ENIGH\BOOTS.dta", replace

//==========================================================
//## TABLA DE ERRORES ESTANDAR
//==========================================================

//### PASO 1: Abrir base ajustada (BOOTS.dta)
clear
use "$ENIGH\BOOTS.dta", clear

//### PASO 2: Estimar MCO con errores estándar robustos
collect clear
collect: regress linghrs anios_esc edad edad2 rural female [aw=factor], robust

//### PASO 3: Diseñar tabla con coef, se, z, p, IC
collect layout (colname) (result[_r_b _r_se _r_z _r_p _r_ci]) (cmdset)
collect style cell, nformat(%5.4f)

//### PASO 4: Exportar tabla minimalista a LaTeX en $graf
collect export "$graf\ENIGH_4.tex", replace tableonly



//## A) BOOTS 100 : Bootstrap no paramétrico con 100 repeticiones
//=============================================================


//### PASO 1: OLS robusto

use "$ENIGH\BOOTS.dta", clear
reg linghrs anios_esc edad edad2 rural female, robust

//### PASO 2: CAPTURAR MANUALMENTE

//### PASO 3: Bootstrap no paramétrico con 100 repeticiones
use "$ENIGH\BOOTS.dta", clear

bootstrap, seed(123) reps(100): ///
    reg linghrs anios_esc edad edad2 rural female, robust

*CAPTURAR MANUALMENTE COLUMNS SE Bootstrap

//### PASO 4: Intervalo de confianza método Percentil
estat bootstrap, percentile

*CAPTURAR MANUALMENTE COLUMNS IC

//### PASO 5: Intervalos de confianza percentil-t (95%)
foreach v in anios_esc edad edad2 rural female _cons {
    
    * 1. Recargamos la base y corremos OLS robusto
    use "$ENIGH\BOOTS.dta", clear
    reg linghrs anios_esc edad edad2 rural female, robust
    local b  = _b[`v']
    local se = _se[`v']

    * 2. Bootstrap de t-star
    bootstrap tstar=((_b[`v']-`b')/`se'), reps(100) seed(123) nodots ///
        saving(bt_t, replace): reg linghrs anios_esc edad edad2 rural female, robust

    * 3. Abrimos resultados bootstrap y sacamos percentiles
    use bt_t, clear
    _pctile tstar, p(2.5,97.5)

    * 4. Mostramos intervalo percentil-t en pantalla
    di as text "Variable: `v'"
    di "IC 95% percentil-t: [" %9.4f (`b' - r(r1)*`se') ", " %9.4f (`b' + r(r2)*`se') "]"
    di "----------------------------------------------------"
}

//### RESULTADO

*\begin{tabular}{lccccc}
*\hline
*Variable & SE OLS & t OLS & SE Boot & IC Percentil & IC Percentil-t \\
*\hline
*Escolaridad & 0.0006436 & 114.41 & 0.0006854 & [0.072084, 0.074939] & [0.0749, 0.0751] \\
*Edad        & 0.0019738 & 22.04  & 0.0020745 & [0.039907, 0.047339] & [0.0471, 0.0473] \\
*Edad$^2$    & 0.0000230 & -18.83 & 0.0000246 & [-0.0004783, -0.0003912] & [-0.0004, -0.0004] \\
*Rural       & 0.0057146 & -36.50 & 0.0054705 & [-0.218812, -0.197038] & [-0.1984, -0.1970] \\
*Mujer       & 0.0050933 & -32.57 & 0.0057067 & [-0.178634, -0.153747] & [-0.1537, -0.1531] \\
*Constante   & 0.04145   & 43.55  & 0.0428207 & [1.725324, 1.890684] & [1.8848, 1.8907] \\
*\hline
*\end{tabular}


//## B) BOOTS 1000 : Bootstrap no paramétrico con 100 repeticiones
//=============================================================


//### PASO 1: OLS robusto

use "$ENIGH\BOOTS.dta", clear
reg linghrs anios_esc edad edad2 rural female, robust

//### PASO 2: CAPTURAR MANUALMENTE

//### PASO 3: Bootstrap no paramétrico con 100 repeticiones
use "$ENIGH\BOOTS.dta", clear

bootstrap, seed(123) reps(1000): ///
    reg linghrs anios_esc edad edad2 rural female, robust

*CAPTURAR MANUALMENTE COLUMNS SE Bootstrap

//### PASO 4: Intervalo de confianza método Percentil
estat bootstrap, percentile

*CAPTURAR MANUALMENTE COLUMNS IC

//### PASO 5: Intervalos de confianza percentil-t (95%)
foreach v in anios_esc edad edad2 rural female _cons {
    
    * 1. Recargamos la base y corremos OLS robusto
    use "$ENIGH\BOOTS.dta", clear
    reg linghrs anios_esc edad edad2 rural female, robust
    local b  = _b[`v']
    local se = _se[`v']

    * 2. Bootstrap de t-star
    bootstrap tstar=((_b[`v']-`b')/`se'), reps(1000) seed(123) nodots ///
        saving(bt_t, replace): reg linghrs anios_esc edad edad2 rural female, robust

    * 3. Abrimos resultados bootstrap y sacamos percentiles
    use bt_t, clear
    _pctile tstar, p(2.5,97.5)

    * 4. Mostramos intervalo percentil-t en pantalla
    di as text "Variable: `v'"
    di "IC 95% percentil-t: [" %9.4f (`b' - r(r1)*`se') ", " %9.4f (`b' + r(r2)*`se') "]"
    di "----------------------------------------------------"
}

//### RESULTADO

/*
\begin{tabular}{lccccc}
\hline
Variable    & SE OLS   & t OLS  & SE Boot & IC Percentil & IC Percentil-t \\
\hline
Escolaridad & 0.0006436 & 114.41 & 0.0006466 & [0.072375, 0.074911] & [0.0749, 0.0749] \\
Edad        & 0.0019738 & 22.04  & 0.0020076 & [0.039454, 0.047273] & [0.0476, 0.0473] \\
Edad$^2$    & 0.0000230 & -18.83 & 0.0000233 & [-0.000478, -0.000387] & [-0.0004, -0.0004] \\
Rural       & 0.0057146 & -36.50 & 0.0057608 & [-0.219654, -0.197463] & [-0.1975, -0.1975] \\
Mujer       & 0.0050933 & -32.57 & 0.0051215 & [-0.175884, -0.155636] & [-0.1559, -0.1556] \\
Constante   & 0.04145   & 43.55  & 0.0421016 & [1.725285, 1.890959] & [1.8850, 1.8910] \\
\hline
\end{tabular}

*/


//## C) JACKKNIFE
//=============================================================


//### PASO 1: OLS robusto

use "$ENIGH\BOOTS.dta", clear
reg linghrs anios_esc edad edad2 rural female, robust

//### PASO 2: CAPTURAR MANUALMENTE

//### PASO 3: Jackknife
use "$ENIGH\BOOTS.dta", clear

jackknife, dots(10): reg linghrs anios_esc edad edad2 rural female, robust

//### RESULTADOS

/*
\begin{tabular}{lcccc}
\hline
Variable & SE OLS & SE Boot (100) & SE Boot (1000) & SE Jackknife \\
\hline
Escolaridad & 0.0006436 & 0.0006854 & 0.0006466 & 0.0006436 \\
Edad        & 0.0019738 & 0.0020745 & 0.0020076 & 0.0019740 \\
Edad$^2$    & 0.0000230 & 0.0000246 & 0.0000233 & 0.0000230 \\
Rural       & 0.0057146 & 0.0054705 & 0.0057608 & 0.0057148 \\
Mujer       & 0.0050933 & 0.0057067 & 0.0051215 & 0.0050935 \\
Constante   & 0.0414500 & 0.0428207 & 0.0421016 & 0.0414528 \\
\hline
\end{tabular}

*/ 

//## D) 25%N BOOT 100
//=============================================================

//### PASO 1: OLS robusto
use "$ENIGH\BOOTS.dta", clear
reg linghrs anios_esc edad edad2 rural female, robust

//### PASO 2: CAPTURAR MANUALMENTE

//### PASO 3: Bootstrap con 100 repeticiones y tamaño 0.25*N
use "$ENIGH\BOOTS.dta", clear

bootstrap, seed(123) reps(100) size(21385): ///
    reg linghrs anios_esc edad edad2 rural female, robust

*CAPTURAR MANUALMENTE COLUMNAS SE Bootstrap

//### PASO 4: Intervalo de confianza método Percentil
estat bootstrap, percentile

*CAPTURAR MANUALMENTE COLUMNAS IC

//### PASO 5: Intervalos de confianza percentil-t (95%)
foreach v in anios_esc edad edad2 rural female _cons {
    
    * 1. Recargamos la base y corremos OLS robusto
    use "$ENIGH\BOOTS.dta", clear
    reg linghrs anios_esc edad edad2 rural female, robust
    local b  = _b[`v']
    local se = _se[`v']

    * 2. Bootstrap de t-star con tamaño reducido
    bootstrap tstar=((_b[`v']-`b')/`se'), reps(100) seed(123) nodots size(21385) ///
        saving(bt_t, replace): reg linghrs anios_esc edad edad2 rural female, robust

    * 3. Abrimos resultados bootstrap y sacamos percentiles
    use bt_t, clear
    _pctile tstar, p(2.5,97.5)

    * 4. Mostramos intervalo percentil-t en pantalla
    di as text "Variable: `v'"
    di "IC 95% percentil-t (0.25N): [" %9.4f (`b' - r(r1)*`se') ", " %9.4f (`b' + r(r2)*`se') "]"
    di "----------------------------------------------------"
}

//### RESULTADO

/*
\begin{tabular}{lccccc}
\hline
Variable & SE OLS & t OLS & SE Boot (25\%N) & IC Percentil & IC Percentil-t \\
\hline
Escolaridad & 0.0006436 & 114.41 & 0.0011828 & [0.0713257, 0.0756924] & [0.0759, 0.0757] \\
Edad        & 0.0019738 & 22.04  & 0.0036963 & [0.0370895, 0.0509931] & [0.0499, 0.0510] \\
Edad$^2$    & 0.0000230 & -18.83 & 0.00004297 & [-0.0005175, -0.0003542] & [-0.0003, -0.0004] \\
Rural       & 0.0057146 & -36.50 & 0.0120161 & [-0.2351936, -0.1885310] & [-0.1820, -0.1885] \\
Mujer       & 0.0050933 & -32.57 & 0.0091484 & [-0.185307, -0.148839] & [-0.1464, -0.1488] \\
Constante   & 0.04145   & 43.55  & 0.0781931 & [1.658345, 1.948811] & [1.9518, 1.9488] \\
\hline
\end{tabular}
*/


//## E) 25%N BOOT 1000
//=============================================================

//### PASO 1: OLS robusto
use "$ENIGH\BOOTS.dta", clear
reg linghrs anios_esc edad edad2 rural female, robust

//### PASO 2: CAPTURAR MANUALMENTE

//### PASO 3: Bootstrap con 100 repeticiones y tamaño 0.25*N
use "$ENIGH\BOOTS.dta", clear

bootstrap, seed(123) reps(1000) size(21385): ///
    reg linghrs anios_esc edad edad2 rural female, robust

*CAPTURAR MANUALMENTE COLUMNAS SE Bootstrap

//### PASO 4: Intervalo de confianza método Percentil
estat bootstrap, percentile

*CAPTURAR MANUALMENTE COLUMNAS IC

//### PASO 5: Intervalos de confianza percentil-t (95%)
foreach v in anios_esc edad edad2 rural female _cons {
    
    * 1. Recargamos la base y corremos OLS robusto
    use "$ENIGH\BOOTS.dta", clear
    reg linghrs anios_esc edad edad2 rural female, robust
    local b  = _b[`v']
    local se = _se[`v']

    * 2. Bootstrap de t-star con tamaño reducido
    bootstrap tstar=((_b[`v']-`b')/`se'), reps(1000) seed(123) nodots size(21385) ///
        saving(bt_t, replace): reg linghrs anios_esc edad edad2 rural female, robust

    * 3. Abrimos resultados bootstrap y sacamos percentiles
    use bt_t, clear
    _pctile tstar, p(2.5,97.5)

    * 4. Mostramos intervalo percentil-t en pantalla
    di as text "Variable: `v'"
    di "IC 95% percentil-t (0.25N): [" %9.4f (`b' - r(r1)*`se') ", " %9.4f (`b' + r(r2)*`se') "]"
    di "----------------------------------------------------"
}

//### RESULTADO

/*
\begin{tabular}{lccccc}
\hline
Variable    & SE OLS   & t OLS  & SE Boot (0.25N, 1000) & IC Percentil (95\%) & IC Percentil-t (95\%) \\
\hline
Escolaridad & 0.0006436 & 114.41 & 0.0012379 & [0.071258, 0.076091] & [0.0760, 0.0760] \\
Edad        & 0.0019738 & 22.04  & 0.0038497 & [0.0359348, 0.0509946] & [0.0511, 0.0510] \\
Edad$^2$    & 0.0000230 & -18.83 & 0.0000448 & [-0.0005210, -0.0003457] & [-0.0003, -0.0003] \\
Rural       & 0.0057146 & -36.50 & 0.0111338 & [-0.2308166, -0.1853507] & [-0.1863, -0.1854] \\
Mujer       & 0.0050933 & -32.57 & 0.0101277 & [-0.1848533, -0.1450079] & [-0.1469, -0.1450] \\
Constante   & 0.04145   & 43.55  & 0.0807424 & [1.655066, 1.959103] & [1.9551, 1.9591] \\
\hline
\end{tabular}
*/


//## 4.2


//### A) BSAMPLE MANUAL 100


//#### PASO 1 
clear
use "$ENIGH\BOOTS.dta", clear
save "$ENIGH\temporalsample.dta", replace

forval q=1/100 {
    quietly use "$ENIGH\temporalsample.dta", clear
    quietly bsample
    quietly reg linghrs anios_esc edad edad2 rural female, robust

    // Matriz de resultados (coef, se, t, etc.)
    matrix M = r(table)

    // Coeficientes
    matrix b_ = M[1,1..6]
    svmat b_, names(b_)
    rename b_1 b_anios_esc
    rename b_2 b_edad
    rename b_3 b_edad2
    rename b_4 b_rural
    rename b_5 b_female
    rename b_6 b_cons

    // Error estándar
    matrix se_ = M[2,1..6]
    svmat se_, names(se_)
    rename se_1 se_anios_esc
    rename se_2 se_edad
    rename se_3 se_edad2
    rename se_4 se_rural
    rename se_5 se_female
    rename se_6 se_cons

    // Estadística t
    matrix t_ = M[3,1..6]
    svmat t_, names(t_)
    rename t_1 t_anios_esc
    rename t_2 t_edad
    rename t_3 t_edad2
    rename t_4 t_rural
    rename t_5 t_female
    rename t_6 t_cons

    gen rep = `q'
    keep rep b_* se_* t_*
    keep if _n==1

    if `q'==1 {
        save "$ENIGH\BOOSTRAP_MANUAL_100.dta", replace
    }
    else {
        append using "$ENIGH\BOOSTRAP_MANUAL_100.dta"
        save "$ENIGH\BOOSTRAP_MANUAL_100.dta", replace
    }
}

//#### PASO 2

// Abrir la base de resultados bootstrap manual
use "$ENIGH\BOOSTRAP_MANUAL_100.dta", clear

// Calcular medias y errores estándar bootstrap de cada coeficiente
collapse (mean) mean_b_anios_esc=b_anios_esc ///
         (sd)   se_boot_anios_esc=b_anios_esc ///
         (mean) mean_b_edad=b_edad (sd) se_boot_edad=b_edad ///
         (mean) mean_b_edad2=b_edad2 (sd) se_boot_edad2=b_edad2 ///
         (mean) mean_b_rural=b_rural (sd) se_boot_rural=b_rural ///
         (mean) mean_b_female=b_female (sd) se_boot_female=b_female ///
         (mean) mean_b_cons=b_cons (sd) se_boot_cons=b_cons

list, noobs abbrev(20)

//#### PASO 3 

// Abrir base de resultados bootstrap manual
use "$ENIGH\BOOSTRAP_MANUAL_100.dta", clear

// Calcular intervalos percentil 95% para cada variable
foreach v in anios_esc edad edad2 rural female cons {
    _pctile b_`v', p(2.5 97.5)
    local li = r(r1)
    local ls = r(r2)

    di as text "Variable: `v'"
    di as result "IC 95% Percentil: [" %9.4f `li' " , " %9.4f `ls' "]"
    di "-------------------------------------------"
}

//#### PASO 4: Intervalos de confianza percentil-t usando base manual

// 1. Estimación original en la muestra completa
use "$ENIGH\BOOTS.dta", clear
reg linghrs anios_esc edad edad2 rural female, robust

// Guardar coeficientes y errores estándar originales
foreach v in anios_esc edad edad2 rural female _cons {
    local b0_`v'  = _b[`v']
    local se0_`v' = _se[`v']
}

// 2. Abrir base de resultados bootstrap manual
use "$ENIGH\BOOSTRAP_MANUAL_100.dta", clear

// Arreglar nombre de la constante para que coincida con _cons
rename t_cons t__cons

// 3. Calcular intervalos percentil-t
foreach v in anios_esc edad edad2 rural female _cons {
    _pctile t_`v', p(2.5 97.5)
    local tL = r(r1)
    local tU = r(r2)

    di as text "Variable: `v'"
    di as result "IC 95% percentil-t: [" ///
        %9.4f (`b0_`v'' - `tU'*`se0_`v'') " , " ///
        %9.4f (`b0_`v'' - `tL'*`se0_`v'') "]"
    di "---------------------------------------------"
}



//### B) BSAMPLE MANUAL 1000


//#### PASO 1 
clear
use "$ENIGH\BOOTS.dta", clear
save "$ENIGH\temporalsample.dta", replace

forval q=1/1000 {
    quietly use "$ENIGH\temporalsample.dta", clear
    quietly bsample
    quietly reg linghrs anios_esc edad edad2 rural female, robust

    // Matriz de resultados (coef, se, t, etc.)
    matrix M = r(table)

    // Coeficientes
    matrix b_ = M[1,1..6]
    svmat b_, names(b_)
    rename b_1 b_anios_esc
    rename b_2 b_edad
    rename b_3 b_edad2
    rename b_4 b_rural
    rename b_5 b_female
    rename b_6 b_cons

    // Error estándar
    matrix se_ = M[2,1..6]
    svmat se_, names(se_)
    rename se_1 se_anios_esc
    rename se_2 se_edad
    rename se_3 se_edad2
    rename se_4 se_rural
    rename se_5 se_female
    rename se_6 se_cons

    // Estadística t
    matrix t_ = M[3,1..6]
    svmat t_, names(t_)
    rename t_1 t_anios_esc
    rename t_2 t_edad
    rename t_3 t_edad2
    rename t_4 t_rural
    rename t_5 t_female
    rename t_6 t_cons

    gen rep = `q'
    keep rep b_* se_* t_*
    keep if _n==1

    if `q'==1 {
        save "$ENIGH\BOOSTRAP_MANUAL_1000.dta", replace
    }
    else {
        append using "$ENIGH\BOOSTRAP_MANUAL_1000.dta"
        save "$ENIGH\BOOSTRAP_MANUAL_1000.dta", replace
    }
}

//#### PASO 2

// Abrir la base de resultados bootstrap manual
use "$ENIGH\BOOSTRAP_MANUAL_1000.dta", clear

// Calcular medias y errores estándar bootstrap de cada coeficiente
collapse (mean) mean_b_anios_esc=b_anios_esc ///
         (sd)   se_boot_anios_esc=b_anios_esc ///
         (mean) mean_b_edad=b_edad (sd) se_boot_edad=b_edad ///
         (mean) mean_b_edad2=b_edad2 (sd) se_boot_edad2=b_edad2 ///
         (mean) mean_b_rural=b_rural (sd) se_boot_rural=b_rural ///
         (mean) mean_b_female=b_female (sd) se_boot_female=b_female ///
         (mean) mean_b_cons=b_cons (sd) se_boot_cons=b_cons

list, noobs abbrev(20)

//#### PASO 3 

// Abrir base de resultados bootstrap manual
use "$ENIGH\BOOSTRAP_MANUAL_1000.dta", clear

// Calcular intervalos percentil 95% para cada variable
foreach v in anios_esc edad edad2 rural female cons {
    _pctile b_`v', p(2.5 97.5)
    local li = r(r1)
    local ls = r(r2)

    di as text "Variable: `v'"
    di as result "IC 95% Percentil: [" %9.4f `li' " , " %9.4f `ls' "]"
    di "-------------------------------------------"
}

//#### PASO 4: Intervalos de confianza percentil-t usando base manual

// 1. Estimación original en la muestra completa
use "$ENIGH\BOOTS.dta", clear
reg linghrs anios_esc edad edad2 rural female, robust

// Guardar coeficientes y errores estándar originales
foreach v in anios_esc edad edad2 rural female _cons {
    local b0_`v'  = _b[`v']
    local se0_`v' = _se[`v']
}

// 2. Abrir base de resultados bootstrap manual
use "$ENIGH\BOOSTRAP_MANUAL_1000.dta", clear

// Arreglar nombre de la constante para que coincida con _cons
rename t_cons t__cons

// 3. Calcular intervalos percentil-t
foreach v in anios_esc edad edad2 rural female _cons {
    _pctile t_`v', p(2.5 97.5)
    local tL = r(r1)
    local tU = r(r2)

    di as text "Variable: `v'"
    di as result "IC 95% percentil-t: [" ///
        %9.4f (`b0_`v'' - `tU'*`se0_`v'') " , " ///
        %9.4f (`b0_`v'' - `tL'*`se0_`v'') "]"
    di "---------------------------------------------"
}


//### C) BSAMPLE MANUAL 100 (25% de la muestra)

//#### PASO 1 
clear
use "$ENIGH\BOOTS.dta", clear
save "$ENIGH\temporalsample.dta", replace

forval q=1/100 {
    quietly use "$ENIGH\temporalsample.dta", clear
    quietly bsample 21385   // <-- solo 25% de la muestra
    quietly reg linghrs anios_esc edad edad2 rural female, robust

    // Matriz de resultados (coef, se, t, etc.)
    matrix M = r(table)

    // Coeficientes
    matrix b_ = M[1,1..6]
    svmat b_, names(b_)
    rename b_1 b_anios_esc
    rename b_2 b_edad
    rename b_3 b_edad2
    rename b_4 b_rural
    rename b_5 b_female
    rename b_6 b_cons

    // Error estándar
    matrix se_ = M[2,1..6]
    svmat se_, names(se_)
    rename se_1 se_anios_esc
    rename se_2 se_edad
    rename se_3 se_edad2
    rename se_4 se_rural
    rename se_5 se_female
    rename se_6 se_cons

    // Estadística t
    matrix t_ = M[3,1..6]
    svmat t_, names(t_)
    rename t_1 t_anios_esc
    rename t_2 t_edad
    rename t_3 t_edad2
    rename t_4 t_rural
    rename t_5 t_female
    rename t_6 t_cons

    gen rep = `q'
    keep rep b_* se_* t_*
    keep if _n==1

    if `q'==1 {
        save "$ENIGH\BOOSTRAP_MANUAL_100_25N.dta", replace
    }
    else {
        append using "$ENIGH\BOOSTRAP_MANUAL_100_25N.dta"
        save "$ENIGH\BOOSTRAP_MANUAL_100_25N.dta", replace
    }
}

//#### PASO 2

// Abrir la base de resultados bootstrap manual
use "$ENIGH\BOOSTRAP_MANUAL_100_25N.dta", clear

// Calcular medias y errores estándar bootstrap de cada coeficiente
collapse (mean) mean_b_anios_esc=b_anios_esc ///
         (sd)   se_boot_anios_esc=b_anios_esc ///
         (mean) mean_b_edad=b_edad (sd) se_boot_edad=b_edad ///
         (mean) mean_b_edad2=b_edad2 (sd) se_boot_edad2=b_edad2 ///
         (mean) mean_b_rural=b_rural (sd) se_boot_rural=b_rural ///
         (mean) mean_b_female=b_female (sd) se_boot_female=b_female ///
         (mean) mean_b_cons=b_cons (sd) se_boot_cons=b_cons

list, noobs abbrev(20)


//#### PASO 3 

// Abrir base de resultados bootstrap manual
use "$ENIGH\BOOSTRAP_MANUAL_100_25N.dta", clear

// Calcular intervalos percentil 95% para cada variable
foreach v in anios_esc edad edad2 rural female cons {
    _pctile b_`v', p(2.5 97.5)
    local li = r(r1)
    local ls = r(r2)

    di as text "Variable: `v'"
    di as result "IC 95% Percentil: [" %9.4f `li' " , " %9.4f `ls' "]"
    di "-------------------------------------------"
}


//#### PASO 4: Intervalos de confianza percentil-t usando base manual

// 1. Estimación original en la muestra completa
use "$ENIGH\BOOTS.dta", clear
reg linghrs anios_esc edad edad2 rural female, robust

// Guardar coeficientes y errores estándar originales
foreach v in anios_esc edad edad2 rural female _cons {
    local b0_`v'  = _b[`v']
    local se0_`v' = _se[`v']
}

// 2. Abrir base de resultados bootstrap manual
use "$ENIGH\BOOSTRAP_MANUAL_100_25N.dta", clear

// Arreglar nombre de la constante para que coincida con _cons
rename t_cons t__cons

// 3. Calcular intervalos percentil-t
foreach v in anios_esc edad edad2 rural female _cons {
    _pctile t_`v', p(2.5 97.5)
    local tL = r(r1)
    local tU = r(r2)

    di as text "Variable: `v'"
    di as result "IC 95% percentil-t: [" ///
        %9.4f (`b0_`v'' - `tU'*`se0_`v'') " , " ///
        %9.4f (`b0_`v'' - `tL'*`se0_`v'') "]"
    di "---------------------------------------------"
}

//### D) BSAMPLE MANUAL 1000 (25% de la muestra)

//#### PASO 1 
clear
use "$ENIGH\BOOTS.dta", clear
save "$ENIGH\temporalsample.dta", replace

forval q=1/1000 {
    quietly use "$ENIGH\temporalsample.dta", clear
    quietly bsample 21385   // <-- solo 25% de la muestra
    quietly reg linghrs anios_esc edad edad2 rural female, robust

    // Matriz de resultados (coef, se, t, etc.)
    matrix M = r(table)

    // Coeficientes
    matrix b_ = M[1,1..6]
    svmat b_, names(b_)
    rename b_1 b_anios_esc
    rename b_2 b_edad
    rename b_3 b_edad2
    rename b_4 b_rural
    rename b_5 b_female
    rename b_6 b_cons

    // Error estándar
    matrix se_ = M[2,1..6]
    svmat se_, names(se_)
    rename se_1 se_anios_esc
    rename se_2 se_edad
    rename se_3 se_edad2
    rename se_4 se_rural
    rename se_5 se_female
    rename se_6 se_cons

    // Estadística t
    matrix t_ = M[3,1..6]
    svmat t_, names(t_)
    rename t_1 t_anios_esc
    rename t_2 t_edad
    rename t_3 t_edad2
    rename t_4 t_rural
    rename t_5 t_female
    rename t_6 t_cons

    gen rep = `q'
    keep rep b_* se_* t_*
    keep if _n==1

    if `q'==1 {
        save "$ENIGH\BOOSTRAP_MANUAL_1000_25N.dta", replace
    }
    else {
        append using "$ENIGH\BOOSTRAP_MANUAL_1000_25N.dta"
        save "$ENIGH\BOOSTRAP_MANUAL_1000_25N.dta", replace
    }
}

//#### PASO 2

// Abrir la base de resultados bootstrap manual
use "$ENIGH\BOOSTRAP_MANUAL_1000_25N.dta", clear

// Calcular medias y errores estándar bootstrap de cada coeficiente
collapse (mean) mean_b_anios_esc=b_anios_esc ///
         (sd)   se_boot_anios_esc=b_anios_esc ///
         (mean) mean_b_edad=b_edad (sd) se_boot_edad=b_edad ///
         (mean) mean_b_edad2=b_edad2 (sd) se_boot_edad2=b_edad2 ///
         (mean) mean_b_rural=b_rural (sd) se_boot_rural=b_rural ///
         (mean) mean_b_female=b_female (sd) se_boot_female=b_female ///
         (mean) mean_b_cons=b_cons (sd) se_boot_cons=b_cons

list, noobs abbrev(20)


//#### PASO 3 

// Abrir base de resultados bootstrap manual
use "$ENIGH\BOOSTRAP_MANUAL_1000_25N.dta", clear

// Calcular intervalos percentil 95% para cada variable
foreach v in anios_esc edad edad2 rural female cons {
    _pctile b_`v', p(2.5 97.5)
    local li = r(r1)
    local ls = r(r2)

    di as text "Variable: `v'"
    di as result "IC 95% Percentil: [" %9.4f `li' " , " %9.4f `ls' "]"
    di "-------------------------------------------"
}


//#### PASO 4: Intervalos de confianza percentil-t usando base manual

// 1. Estimación original en la muestra completa
use "$ENIGH\BOOTS.dta", clear
reg linghrs anios_esc edad edad2 rural female, robust

// Guardar coeficientes y errores estándar originales
foreach v in anios_esc edad edad2 rural female _cons {
    local b0_`v'  = _b[`v']
    local se0_`v' = _se[`v']
}

// 2. Abrir base de resultados bootstrap manual
use "$ENIGH\BOOSTRAP_MANUAL_1000_25N.dta", clear

// Arreglar nombre de la constante para que coincida con _cons
rename t_cons t__cons

// 3. Calcular intervalos percentil-t
foreach v in anios_esc edad edad2 rural female _cons {
    _pctile t_`v', p(2.5 97.5)
    local tL = r(r1)
    local tU = r(r2)

    di as text "Variable: `v'"
    di as result "IC 95% percentil-t: [" ///
        %9.4f (`b0_`v'' - `tU'*`se0_`v'') " , " ///
        %9.4f (`b0_`v'' - `tL'*`se0_`v'') "]"
    di "---------------------------------------------"
}





************************************************************

                  //#5 NON PARAMETRICS , baby
				
************************************************************


//==========================================================
//### PASO 1 Preparación de base
//==========================================================

// Cargar base ajustada
use "$ENIGH\ENIGH_TRABAJADORES_AJUSTADA.dta", clear

// Crear dummy rural (1 si tam_loc == 4, 0 en otro caso)
gen rural = 0
replace rural = 1 if tam_loc == 4

// Renombrar ponderador de la ENIGH
rename fac w


//==========================================================
//## 5.2  KDENSITY SALARIO
//==========================================================

//### PASO 2

* Loop en todos los años pares 1992–2024

local years 1992 1994 1996 1998 2000 2002 2004 2005 2006 2008 2010 2012 2014 2016 2018 2020 2022 2024

foreach A of local years {
    quietly sum inghrs if year==`A' [aw=w], detail
    local bw = min(r(sd), ((r(p75)-r(p25))/1.349)) * (r(N)^(-1/5)) * 1.3643 * 1.7188
    local bw = round(`bw')

    // grid 0–300 (paso 1) para evaluar la densidad
    range xgrid 0 300 301
    tempvar d
    quietly kdensity inghrs if year==`A' [aw=w], ///
        kernel(epan2) bwidth(`bw') at(xgrid) ///
        generate(`d')

    local nota "BW: `bw'"
    twoway (area `d' xgrid, fcolor("255 165 0%50") lcolor("255 69 0") lwidth(medthick)), ///
        ytitle("Density") xtitle("Ingreso por hora") ///
        title("`A'", pos(12) ring(0)) ///
        ylabel(0 .01 .02 .03, labsize(medium)) ///
        yscale(range(0 .03)) ///
        xlabel(0 100 200 300, labsize(medium)) ///
        xscale(range(0 300)) ///
        note("`nota'") ///
        name(G`A', replace)

    drop xgrid `d'
}



//==========================================================
//### PASO 3 COMBINA GRAFICAS DE 1992 A 2006
//==========================================================

// Combinar primeros 9 años en un grid 3x3
graph combine G1992 G1994 G1996 G1998 G2000 G2002 G2004 G2005 G2006, ///
    cols(3) rows(3) ycommon xcommon ///
    xsize(12) ysize(13) imargin(small) ///
    name(KDENS_ING_pt1, replace)

// Exportar al global $GRAF en dos formatos
graph export "$graf\KDENS_ING_pt1.png", replace width(3000)
graph export "$graf\KDENS_ING_pt1.emf", replace

//==========================================================
//### PASO 4 COMBINA GRAFICAS DE 2008 A 2024
//==========================================================

// Combinar en un grid 3x3
graph combine G2008 G2010 G2012 G2014 G2016 G2018 G2020 G2022 G2024, ///
    cols(3) rows(3) ycommon xcommon ///
    xsize(12) ysize(13) imargin(small) ///
    name(KDENS_ING_pt2, replace)

// Exportar al global $graf en dos formatos
graph export "$graf\KDENS_ING_pt2.png", replace width(3000)
graph export "$graf\KDENS_ING_pt2.emf", replace



//==========================================================
//## 5.2.1  KDENSITY LOG SALARIO
//==========================================================

local years 1992 1994 1996 1998 2000 2002 2004 2005 2006 2008 2010 2012 2014 2016 2018 2020 2022 2024

foreach A of local years {
    quietly sum linghrs if year==`A' [aw=w], detail
    // Bandwidth sin redondear + piso para evitar que sea 0
    local bw_raw = min(r(sd), ((r(p75)-r(p25))/1.349)) * (r(N)^(-1/5)) * 1.3643 * 1.7188
    local bw     = max(0.02, `bw_raw')   // BW mínimo = 0.02

    // grid 0–8 (log salario en rango razonable)
    range xgrid 0 8 501
    tempvar d
    quietly kdensity linghrs if year==`A' [aw=w], ///
        kernel(epan2) bwidth(`bw') at(xgrid) ///
        generate(`d')

    // Nota con BW en 2 decimales
    local nota : display "BW: " %4.2f `bw'

    twoway (area `d' xgrid, fcolor("24 116 205%50") lcolor("24 116 205") lwidth(medthick)), ///
        ytitle("Density") xtitle("Log Ingreso por Hora") ///
        title("`A'", pos(12) ring(0)) ///
        ylabel(0(.2).8, labsize(medium)) yscale(range(0 .8)) ///
        xlabel(0(2)8, labsize(medium))  xscale(range(0 8)) ///
        note("`nota'") ///
        name(GL`A', replace)

    drop xgrid `d'
}

//==========================================================
//### PASO 3 COMBINA GRAFICAS DE 1992 A 2006
//==========================================================

graph combine GL1992 GL1994 GL1996 GL1998 GL2000 GL2002 GL2004 GL2005 GL2006, ///
    cols(3) rows(3) ycommon xcommon ///
    xsize(10) ysize(12) imargin(small) ///
    name(KDENS_LOG_pt1, replace)

graph export "$graf\KDENS_LOG_pt1.png", replace width(3000)
graph export "$graf\KDENS_LOG_pt1.emf", replace

//==========================================================
//### PASO 4 COMBINA GRAFICAS DE 2008 A 2024
//==========================================================

graph combine GL2008 GL2010 GL2012 GL2014 GL2016 GL2018 GL2020 GL2022 GL2024, ///
    cols(3) rows(3) ycommon xcommon ///
    xsize(10) ysize(12) imargin(small) ///
    name(KDENS_LOG_pt2, replace)

graph export "$graf\KDENS_LOG_pt2.png", replace width(3000)
graph export "$graf\KDENS_LOG_pt2.emf", replace


//==========================================================
//## 5.3 Bandwidth y Kernels en kdensity (ejemplo: año 2018)
//==========================================================

// Fijamos año de análisis
local A 2018

// Calcular estadísticos básicos
quietly sum linghrs if year==`A' [aw=w], detail
local bw0 = min(r(sd), ((r(p75)-r(p25))/1.349)) * (r(N)^(-1/5)) * 1.3643 * 1.7188
local bw0 = round(`bw0', .01)   // Bandwidth "óptimo"
local bw_low = `bw0'/4          // Bandwidth pequeño
local bw_high = `bw0'*4         // Bandwidth grande

//===========================
// (1) Comparar Bandwidth
//===========================
range xgrid 0 8 501
tempvar d1 d2 d3

kdensity linghrs if year==`A' [aw=w], kernel(epan2) bwidth(`bw_low') at(xgrid) generate(`d1')
kdensity linghrs if year==`A' [aw=w], kernel(epan2) bwidth(`bw0')   at(xgrid) generate(`d2')
kdensity linghrs if year==`A' [aw=w], kernel(epan2) bwidth(`bw_high') at(xgrid) generate(`d3')

twoway (line `d1' xgrid, lcolor("255 69 0%20") lwidth(medthick) lpattern(solid)) ///
       (line `d2' xgrid, lcolor("255 69 0") lwidth(medthick)) ///
       (line `d3' xgrid, lcolor("pink") lwidth(medthick) lpattern(dash)), ///
       title(" ") ///
       ytitle("Density") xtitle("Log Ingreso por Hora") ///
       legend(order(1 "BW bajo" 2 "BW óptimo" 3 "BW alto") ring(0) pos(1)) ///
       name(CAMBIO_BW, replace)

// Exportar
graph export "$graf\CAMBIO_BW.png", replace width(3000)
graph export "$graf\CAMBIO_BW.emf", replace

drop xgrid `d1' `d2' `d3'


//===========================
// (2) Comparar Kernels
//===========================
range xgrid 0 8 501
tempvar k1 k2

kdensity linghrs if year==`A' [aw=w], kernel(epan2)    bwidth(`bw0') at(xgrid) generate(`k1')
kdensity linghrs if year==`A' [aw=w], kernel(gaussian) bwidth(`bw0') at(xgrid) generate(`k2')

twoway (line `k1' xgrid, lcolor("255 69 0%20") lwidth(medthick)) ///
       (line `k2' xgrid, lcolor("255 69 0") lwidth(medthick) lpattern(dash)), ///
       title(" ") ///
       ytitle("Density") xtitle("Log Ingreso por Hora") ///
       legend(order(1 "Epanechnikov" 2 "Gaussiano") ring(0) pos(1)) ///
       name(CAMBIO_KERNEL, replace)

// Exportar
graph export "$graf\CAMBIO_KERNEL.png", replace width(3000)
graph export "$graf\CAMBIO_KERNEL.emf", replace

drop xgrid `k1' `k2'


//==========================================================
//## 5.4 b) 2018
//==========================================================

//=============================
//### LPOLY HOMBRES 2018 - Edad 
//=============================
local A 2018

twoway ///
    (scatter linghrs edad if (year == `A' & sex == 0), ///
        mcolor("135 206 250%2") msymbol(O) ) ///   // rosa con transparencia
    (lpoly linghrs edad if (year == `A' & sex == 0) [aweight = w], ///
        kernel(gaussian) bwidth(0.8) ///
        lcolor("0 255 127") lwidth(medthick)) ///   // azul paleta
    (lowess linghrs edad if (year == `A' & sex == 0), ///
        lcolor("black") lwidth(medium) lpattern(solid)), ///   // naranja paleta
    legend(cols(3) position(2) ring(0)) ///
    legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
    yline(0, lcolor(gs12) lpattern(dash)) ///
    xscale(range(25 65)) xlabel(25(10)65) ///
    ytitle("Log salario por hora") ///
    xtitle("Edad") ///
    name(LPOLY_HOMBRES, replace)

// Exportar
graph export "$graf\LPOLY_HOMBRES.png", replace width(3000)
graph export "$graf\LPOLY_HOMBRES.emf", replace


//=============================
//### LPOLY MUJERES 2018 - Edad 
//=============================
local A 2018

twoway ///
    (scatter linghrs edad if (year == `A' & sex == 1), ///
        mcolor("255 192 203%2") msymbol(O) ) ///   // rosa con transparencia
    (lpoly linghrs edad if (year == `A' & sex == 1) [aweight = w], ///
        kernel(gaussian) bwidth(0.8) ///
        lcolor("0 255 127") lwidth(medthick)) ///   // azul paleta
    (lowess linghrs edad if (year == `A' & sex == 1), ///
        lcolor("black") lwidth(medium) lpattern(solid)), ///   // naranja paleta
    legend(cols(3) position(2) ring(0)) ///
    legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
    yline(0, lcolor(gs12) lpattern(dash)) ///
    xscale(range(25 65)) xlabel(25(10)65) ///
    ytitle("Log salario por hora") ///
    xtitle("Edad") ///
    name(LPOLY_MUJERES, replace)

// Exportar
graph export "$graf\LPOLY_MUJERES.png", replace width(3000)
graph export "$graf\LPOLY_MUJERES.emf", replace


//=============================
//### LPOLY HOMBRES 2018 - Escolaridad 
//=============================
local A 2018

twoway ///
    (scatter linghrs anios_esc if (year == `A' & sex == 0), ///
        mcolor("135 206 250%40") msymbol(O)) ///   // rosa claro con transparencia
    (lpoly linghrs anios_esc if (year == `A' & sex == 0) [aweight = w], ///
        kernel(gaussian) bwidth(0.8) ///
        lcolor("0 255 127") lwidth(medthick)) ///   // verde fosforescente metálico
    (lowess linghrs anios_esc if (year == `A' & sex == 0), ///
        lcolor("black") lwidth(medthick) lpattern(dot)), ///   // azul claro
    legend(cols(3) position(2) ring(0)) ///
    legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
    yline(0, lcolor(gs12) lpattern(dash)) ///
    xscale(range(0 22)) xlabel(0(4)22) ///
    ytitle("Log salario por hora") ///
    xtitle("Años de escolaridad") ///
    name(LPOLY_HOMBRES_ESC, replace)

// Exportar
graph export "$graf\LPOLY_HOMBRES_ESC.png", replace width(3000)
graph export "$graf\LPOLY_HOMBRES_ESC.emf", replace


//=============================
//### LPOLY MUJERES 2018 - Escolaridad 
//=============================
local A 2018

twoway ///
    (scatter linghrs anios_esc if (year == `A' & sex == 1), ///
        mcolor("255 192 203%10") msymbol(O)) ///   // rosa claro con transparencia
    (lpoly linghrs anios_esc if (year == `A' & sex == 1) [aweight = w], ///
        kernel(gaussian) bwidth(0.8) ///
        lcolor("0 255 127") lwidth(medthick)) ///   // verde fosforescente metálico
    (lowess linghrs anios_esc if (year == `A' & sex == 1), ///
        lcolor("black") lwidth(medthick) lpattern(dot)), ///   // azul claro
    legend(cols(3) position(2) ring(0)) ///
    legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
    yline(0, lcolor(gs12) lpattern(dash)) ///
    xscale(range(0 22)) xlabel(0(4)22) ///
    ytitle("Log salario por hora") ///
    xtitle("Años de escolaridad") ///
    name(LPOLY_MUJERES_ESC, replace)

// Exportar
graph export "$graf\LPOLY_MUJERES_ESC.png", replace width(3000)
graph export "$graf\LPOLY_MUJERES_ESC.emf", replace


//==========================================================
//## 5.4 c) 2024
//==========================================================

//=============================
//### LPOLY HOMBRES 2024 - Edad 
//=============================
local A 2024

twoway ///
    (scatter linghrs edad if (year == `A' & sex == 0), ///
        mcolor("135 206 250%2") msymbol(O) ) ///   // rosa con transparencia
    (lpoly linghrs edad if (year == `A' & sex == 0) [aweight = w], ///
        kernel(gaussian) bwidth(0.8) ///
        lcolor("0 255 127") lwidth(medthick)) ///   // azul paleta
    (lowess linghrs edad if (year == `A' & sex == 0), ///
        lcolor("black") lwidth(medium) lpattern(solid)), ///   // naranja paleta
    legend(cols(3) position(2) ring(0)) ///
    legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
    yline(0, lcolor(gs12) lpattern(dash)) ///
    xscale(range(25 65)) xlabel(25(10)65) ///
    ytitle("Log salario por hora") ///
    xtitle("Edad") ///
    name(LPOLY_HOMBRES_2024, replace)

// Exportar
graph export "$graf\LPOLY_HOMBRES_2024.png", replace width(3000)
graph export "$graf\LPOLY_HOMBRES_2024.emf", replace

//=============================
//### LPOLY MUJERES 2024 - Edad 
//=============================
local A 2024

twoway ///
    (scatter linghrs edad if (year == `A' & sex == 1), ///
        mcolor("255 192 203%2") msymbol(O) ) ///   // rosa con transparencia
    (lpoly linghrs edad if (year == `A' & sex == 1) [aweight = w], ///
        kernel(gaussian) bwidth(0.8) ///
        lcolor("0 255 127") lwidth(medthick)) ///   // azul paleta
    (lowess linghrs edad if (year == `A' & sex == 1), ///
        lcolor("black") lwidth(medium) lpattern(solid)), ///   // naranja paleta
    legend(cols(3) position(2) ring(0)) ///
    legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
    yline(0, lcolor(gs12) lpattern(dash)) ///
    xscale(range(25 65)) xlabel(25(10)65) ///
    ytitle("Log salario por hora") ///
    xtitle("Edad") ///
    name(LPOLY_MUJERES_2024, replace)

// Exportar
graph export "$graf\LPOLY_MUJERES_2024.png", replace width(3000)
graph export "$graf\LPOLY_MUJERES_2024.emf", replace

//=============================
//### LPOLY HOMBRES 2024 - Escolaridad 
//=============================
local A 2024

twoway ///
    (scatter linghrs anios_esc if (year == `A' & sex == 0), ///
        mcolor("135 206 250%40") msymbol(O)) ///   // rosa claro con transparencia
    (lpoly linghrs anios_esc if (year == `A' & sex == 0) [aweight = w], ///
        kernel(gaussian) bwidth(0.8) ///
        lcolor("0 255 127") lwidth(medthick)) ///   // verde fosforescente metálico
    (lowess linghrs anios_esc if (year == `A' & sex == 0), ///
        lcolor("black") lwidth(medthick) lpattern(dot)), ///   // azul claro
    legend(cols(3) position(2) ring(0)) ///
    legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
    yline(0, lcolor(gs12) lpattern(dash)) ///
    xscale(range(0 22)) xlabel(0(4)22) ///
    ytitle("Log salario por hora") ///
    xtitle("Años de escolaridad") ///
    name(LPOLY_HOMBRES_ESC_2024, replace)

// Exportar
graph export "$graf\LPOLY_HOMBRES_ESC_2024.png", replace width(3000)
graph export "$graf\LPOLY_HOMBRES_ESC_2024.emf", replace

//=============================
//### LPOLY MUJERES 2024 - Escolaridad 
//=============================
local A 2024

twoway ///
    (scatter linghrs anios_esc if (year == `A' & sex == 1), ///
        mcolor("255 192 203%10") msymbol(O)) ///   // rosa claro con transparencia
    (lpoly linghrs anios_esc if (year == `A' & sex == 1) [aweight = w], ///
        kernel(gaussian) bwidth(0.8) ///
        lcolor("0 255 127") lwidth(medthick)) ///   // verde fosforescente metálico
    (lowess linghrs anios_esc if (year == `A' & sex == 1), ///
        lcolor("black") lwidth(medthick) lpattern(dot)), ///   // azul claro
    legend(cols(3) position(2) ring(0)) ///
    legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
    yline(0, lcolor(gs12) lpattern(dash)) ///
    xscale(range(0 22)) xlabel(0(4)22) ///
    ytitle("Log salario por hora") ///
    xtitle("Años de escolaridad") ///
    name(LPOLY_MUJERES_ESC_2024, replace)

// Exportar
graph export "$graf\LPOLY_MUJERES_ESC_2024.png", replace width(3000)
graph export "$graf\LPOLY_MUJERES_ESC_2024.emf", replace



//==========================================================
//## 5.4 e) ii)
//==========================================================

//### 2018

preserve
    keep if year==2018
    
    reg linghrs sex rural anios_esc [aw=w]
    predict res_wage18, resid
    
    reg edad sex rural anios_esc [aw=w]
    predict res_edad18, resid
    
    twoway ///
        (scatter res_wage18 res_edad18, mcolor("135 206 250%10") msymbol(O)) ///
        (lpoly res_wage18 res_edad18 [aw=w], kernel(gaussian) bwidth(0.8) lcolor("255 69 0") lwidth(medthick)) ///
        (lowess res_wage18 res_edad18, lcolor("black") lwidth(medium) lpattern(dot)), ///
        legend(cols(3) position(2) ring(0)) ///
        legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
        yline(0, lcolor(gs12) lpattern(dash)) ///
        xtitle("Edad (residualizada)") ///
        ytitle("Log salario por hora (residualizado)") ///
        name(RESID_2018, replace)
    
    graph export "$graf\RESID_2018.png", replace width(3000)
    graph export "$graf\RESID_2018.emf", replace
restore

//### 2022

preserve
    keep if year==2022
    
    reg linghrs sex rural anios_esc [aw=w]
    predict res_wage22, resid
    
    reg edad sex rural anios_esc [aw=w]
    predict res_edad22, resid
    
    twoway ///
        (scatter res_wage22 res_edad22, mcolor("135 206 250%10") msymbol(O)) ///
        (lpoly res_wage22 res_edad22 [aw=w], kernel(gaussian) bwidth(0.8) lcolor("255 69 0") lwidth(medthick)) ///
        (lowess res_wage22 res_edad22, lcolor("black") lwidth(medium) lpattern(dot)), ///
        legend(cols(3) position(2) ring(0)) ///
        legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
        yline(0, lcolor(gs12) lpattern(dash)) ///
        xtitle("Edad (residualizada)") ///
        ytitle("Log salario por hora (residualizado)") ///
        name(RESID_2022, replace)
    
    graph export "$graf\RESID_2022.png", replace width(3000)
    graph export "$graf\RESID_2022.emf", replace
restore



//==========================================================
//## 5.4 e) iiI)
//==========================================================

//=============================
//#### plreg 2018
//=============================

net from http://www.stata-journal.com/software/sj6-3
net install st0109

preserve
    keep if year==2018

    * Estimar PLR y guardar la parte no paramétrica de edad
    plreg linghrs sex rural anios_esc, nlf(edad) generate(g_edad)

    * Ordenar por edad antes de graficar (clave para evitar "abanico")
    sort edad

    * Graficar curva no paramétrica
    twoway line g_edad edad, sort ///
        xscale(range(25 65)) xlabel(25(10)65) ///
        ytitle("Log ingreso por hora") xtitle("Edad") ///
        lcolor("255 69 0") lwidth(medthick) ///
        name(PLREG_RESI_18, replace)

    graph export "$graf\PLREG_RESI_18.png", replace width(3000)
    graph export "$graf\PLREG_RESI_18.emf", replace
restore


//=============================
//#### plreg 2022
//=============================

preserve
    keep if year==2022

    * Estimar PLR y guardar la parte no paramétrica de edad
    plreg linghrs sex rural anios_esc, nlf(edad) generate(g_edad)

    * Ordenar por edad antes de graficar (clave para evitar "abanico")
    sort edad

    * Graficar curva no paramétrica
    twoway line g_edad edad, sort ///
        xscale(range(25 65)) xlabel(25(10)65) ///
        ytitle("Log ingreso por hora") xtitle("Edad") ///
        lcolor("255 69 0") lwidth(medthick) ///
        name(PLREG_RESI_22, replace)

    graph export "$graf\PLREG_RESI_22.png", replace width(3000)
    graph export "$graf\PLREG_RESI_22.emf", replace
restore


























































