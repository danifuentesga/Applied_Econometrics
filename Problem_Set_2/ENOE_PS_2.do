/****************************************************************************************** AUTOR:   Daniel Fuentes (Github: danifuentesga )
* FECHA:   6-sep-2025
* TEMA:    Homologación de bases de datos ENOE (2005-2025 2do trim)
* NOTA:    
******************************************************************************************/

** “Life is like a box of do-files… nunca sabes qué error te va a tocar.” – Forrest Gump**

**************************************************************************
               //#GLOBALS      
**************************************************************************

* Definir ruta principal del proyecto donde están los datos del IMSS Y ENOE
global ENOE "D:\INVESTIGACION\DATA\ENOE"
global IMSS_2018 "D:\INVESTIGACION\DATA\IMSS\2018"
global IMSS_2025 "D:\INVESTIGACION\DATA\IMSS\2025"


* Ruta de destino de graficas
global graf "D:\INVESTIGACION\DATA\ENOE\GRAFS_PS_2"

******************************************************
//# 1 

******************************************************

//## LIMPIEMZA Y MERGE DE INPC

**************************************************************************
//### PASO 1 . Importar archivo mensual
**************************************************************************
import excel "$ENOE\INPC_TRIM.xlsx", sheet("Hoja1") firstrow clear

* Variables importadas:
*   - date : fecha en Excel (numérica tipo 01/01/2005)
*   - INPC : índice mensual

**************************************************************************
//### PASO 2. Convertir fecha a formato trimestral
**************************************************************************
* Si la variable "date" es numérica (como suele pasar desde Excel):
capture confirm numeric variable date
if _rc==0 {
    gen fecha_trim = qofd(date)    // convierte fecha diaria a trimestral
}
else {
    gen fecha_d = date(date,"DMY") // si viniera como string tipo "01/01/2005"
    format fecha_d %td
    gen fecha_trim = qofd(fecha_d)
}

format fecha_trim %tq   // formato trimestral (yq)

**************************************************************************
//### PASO 3. Colapsar INPC al promedio trimestral
**************************************************************************
collapse (mean) INPC, by(fecha_trim)

* Renombrar para mantener consistencia
rename fecha_trim date

**************************************************************************
//### PASO 4. Eliminar observación de 2025q3 (dato incompleto)
**************************************************************************
drop if date==yq(2025,3)

**************************************************************************
//### PASO 5. Guardar base final
**************************************************************************
save "$ENOE\INPC_TRIM.dta", replace


/******************************************************************************************
* PASO 6: Merge ENOE + INPC trimestral
******************************************************************************************/

* 1. Abrir base ENOE
use "$ENOE\Base_ENOE_SDEM_2005_2025.dta", clear

* 2. Ordenar por fecha trimestral
order date
sort date

* 3. Hacer merge con INPC trimestral
merge m:1 date using "$ENOE\INPC_TRIM.dta"

* 4. Limpiar merges
drop if _merge==2   // elimina registros que están en INPC pero no en ENOE
drop _merge

* 5. Guardar reemplazando el archivo original
save "$ENOE\Base_ENOE_SDEM_2005_2025.dta", replace

**************************************************************************
//## FILTRO DE EDAD
**************************************************************************

* 1. Abrir base ENOE final con INPC ya mergeado
use "$ENOE\Base_ENOE_SDEM_2005_2025.dta", clear

//### PASO 1 Eliminamos observaciones no válidas
keep if eda >= 15 & eda <= 98
keep if r_def == 00
keep if c_res == 1 | c_res == 3
format date %tq

* Restricción de edad activa
keep if eda >= 25 & eda <= 65

**************************************************************************
//## FILTRO EDUCACIÓN

//### PASO 1 Recodificación de variables clave
**************************************************************************
* Trabajo válido e ingresos reales
replace ingocup   = . if ingocup   == 999999 | ingocup   == 0
replace ing_x_hrs = . if ing_x_hrs == 999999 | ing_x_hrs == 0

gen trabajadorv = 0
replace trabajadorv = 1 if ingocup != . & ing_x_hrs != . & ingocup > 0 & ing_x_hrs > 0

* Ingresos reales deflactados por INPC (base 2010=100)
gen sm  = (ingocup  / INPC) * 100
gen smh = (ing_x_hrs/ INPC) * 100

//### PASO 2 Educación
gen educacion = .

replace educacion = 0 if cs_p13_1 == 00
replace educacion = 0 if cs_p13_1 == 01
replace educacion = 1 if cs_p13_1 == 2
replace educacion = 2 if cs_p13_1 == 3
replace educacion = 3 if cs_p13_1 == 4
replace educacion = 3 if cs_p13_1 == 5
replace educacion = 3 if cs_p13_1 == 6
replace educacion = 4 if cs_p13_1 == 7
replace educacion = 5 if cs_p13_1 == 8
replace educacion = 5 if cs_p13_1 == 9

label define educn 0 "Sin instrucción" 1 "Primaria" 2 "Secundaria" ///
                  3 "Media Superior"  4 "Superior"  5 "Posgrado"

label values educacion educn
label variable educacion "Nivel educativo"

**************************************************************************
* Clasificación rural / urbano
**************************************************************************
gen rural = 0
replace rural = 1 if t_loc == 4
replace rural = . if missing(t_loc)

label define etirur 0 "Urbano" 1 "Rural"
label values rural etirur
label variable rural "Tipo de localidad"


//## FILTRO GRUPOS DE POBLACIÓN 

//### PASO 1

* Generamos grupos según edad, sexo y educación
gen grupo = .

/// mujeres, 25 a 45, menos de preparatoria
replace grupo = 1 if eda >= 25 & eda <= 45 & sex == 2 & educacion < 3

/// hombres, 25 a 45, menos de preparatoria
replace grupo = 2 if eda >= 25 & eda <= 45 & sex == 1 & educacion < 3

/// mujeres, 25 a 45, más de preparatoria
replace grupo = 3 if eda >= 25 & eda <= 45 & sex == 2 & educacion >= 3

/// hombres, 25 a 45, más de preparatoria
replace grupo = 4 if eda >= 25 & eda <= 45 & sex == 1 & educacion >= 3

/// mujeres, 46 a 65, menos de preparatoria
replace grupo = 5 if eda >= 46 & eda <= 65 & sex == 2 & educacion < 3

/// hombres, 46 a 65, menos de preparatoria
replace grupo = 6 if eda >= 46 & eda <= 65 & sex == 1 & educacion < 3

/// mujeres, 46 a 65, más de preparatoria
replace grupo = 7 if eda >= 46 & eda <= 65 & sex == 2 & educacion >= 3

/// hombres, 46 a 65, más de preparatoria
replace grupo = 8 if eda >= 46 & eda <= 65 & sex == 1 & educacion >= 3

label define grupolbl 1 "Mujer 25-45 < Preparatoria" ///
                     2 "Hombre 25-45 < Preparatoria" ///
                     3 "Mujer 25-45 ≥ Preparatoria" ///
                     4 "Hombre 25-45 ≥ Preparatoria" ///
                     5 "Mujer 46-65 < Preparatoria" ///
                     6 "Hombre 46-65 < Preparatoria" ///
                     7 "Mujer 46-65 ≥ Preparatoria" ///
                     8 "Hombre 46-65 ≥ Preparatoria"

label values grupo grupolbl
label variable grupo "Grupos de población (edad, sexo, educación)"

**************************************************************************
* Variable de sexo en formato binario
**************************************************************************
gen female = sex - 1   // sex==2 → 1 (mujer), sex==1 → 0 (hombre)
label define sexlbl 0 "Hombre" 1 "Mujer"
label values female sexlbl
label variable female "Sexo (0=Hombre, 1=Mujer)"


//## FILTRO DE SALARIO POR HORA (CENSORING) 
******************************************************************************

//### PASO 1

* 1. Censura inferior y superior del salario por hora real (smh)
replace smh = 1     if smh <= 1    & smh != .
replace smh = 5000  if smh >= 5000 & smh != .

* 2. Logaritmo natural del salario por hora
gen lingmh = ln(smh)
label variable lingmh "Logaritmo salario horario real"

**************************************************************************
* Estadísticas descriptivas
**************************************************************************
label variable eda       "Edad"
label variable ingocup   "Ingreso mensual"
label variable ing_x_hrs "Ingreso por hora"
label variable hrsocup   "Horas de trabajo"
label variable female    "Sexo (0=Hombre, 1=Mujer)"
label variable rural     "Urbano o rural"

* Revisión rápida
summarize eda ingocup ing_x_hrs sm smh lingmh hrsocup if trabajadorv==1
tab female
tab rural
tab grupo

//#1.3 ESTADISTICAS DESCRIPTIVAS

//## 1.3.1 MEDIA Tabla descriptiva
// ---- Exportar Tabla Descriptiva a LaTeX ----
preserve

// Calcular medias ponderadas por año
collapse (mean) eda educacion ingocup ing_x_hrs hrsocup female rural [fw=fac], by(year)

// Abrir archivo .tex
file open tabla using "$graf\ENOE_STATS_1_3_1.tex", write replace

// Encabezado LaTeX con ajuste de espacio vertical
file write tabla "\renewcommand{\arraystretch}{0.9}" _n
file write tabla "\begin{tabular}{l@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c}" _n
file write tabla "\hline" _n
file write tabla "Año & Edad & \shortstack{Nivel de \\ educación} & \shortstack{Ingreso \\ mensual} & \shortstack{Ingreso \\ por hora} & \shortstack{Horas de \\ trabajo} & \shortstack{Sexo \\ (1=Mujer)} & \shortstack{Urbano \\ o rural} \\\\" _n
file write tabla "\hline" _n

// Escribir filas (formato compacto)
quietly {
    forvalues i = 1/`=_N' {
        local y  = year[`i']
        local e  = string(eda[`i'], "%5.2f")
        local n  = string(educacion[`i'], "%5.2f")
        local sm = string(ingocup[`i'], "%8.2f")
        local sh = string(ing_x_hrs[`i'], "%8.2f")
        local h  = string(hrsocup[`i'], "%5.2f")
        local m  = string(female[`i'], "%4.2f")
        local r  = string(rural[`i'], "%4.2f")
        file write tabla "`y' & `e' & `n' & `sm' & `sh' & `h' & `m' & `r' \\\\" _n
    }
}

// Cerrar tabla
file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore

//## 1.3.2 DESVIACIÓN ESTÁNDAR Tabla descriptiva
// ---- Exportar Tabla de Desviaciones a LaTeX ----
preserve

// Calcular desviaciones estándar ponderadas por año
collapse (sd) eda educacion ingocup ing_x_hrs hrsocup female rural [fw=fac], by(year)

// Abrir archivo .tex
file open tabla using "$graf\ENOE_STATS_1_3_2.tex", write replace

// Encabezado LaTeX con ajuste de espacio vertical
file write tabla "\renewcommand{\arraystretch}{0.9}" _n
file write tabla "\begin{tabular}{l@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c}" _n
file write tabla "\hline" _n
file write tabla "Año & Edad & \shortstack{Nivel de \\ educación} & \shortstack{Ingreso \\ mensual} & \shortstack{Ingreso \\ por hora} & \shortstack{Horas de \\ trabajo} & \shortstack{Sexo \\ (1=Mujer)} & \shortstack{Urbano \\ o rural} \\\\" _n
file write tabla "\hline" _n

// Escribir filas (formato compacto)
quietly {
    forvalues i = 1/`=_N' {
        local y  = year[`i']
        local e  = string(eda[`i'], "%5.2f")
        local n  = string(educacion[`i'], "%5.2f")
        local sm = string(ingocup[`i'], "%8.2f")
        local sh = string(ing_x_hrs[`i'], "%8.2f")
        local h  = string(hrsocup[`i'], "%5.2f")
        local m  = string(female[`i'], "%4.2f")
        local r  = string(rural[`i'], "%4.2f")
        file write tabla "`y' & `e' & `n' & `sm' & `sh' & `h' & `m' & `r' \\\\" _n
    }
}

// Cerrar tabla
file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore

//## 1.3.4 MEDIANA Tabla descriptiva
// ---- Exportar Tabla de Medianas a LaTeX ----
preserve

// Calcular medianas ponderadas por año
collapse (median) eda educacion ingocup ing_x_hrs hrsocup female rural [fw=fac], by(year)

// Abrir archivo .tex
file open tabla using "$graf\ENOE_STATS_1_3_4.tex", write replace

// Encabezado LaTeX con ajuste de espacio vertical
file write tabla "\renewcommand{\arraystretch}{0.9}" _n
file write tabla "\begin{tabular}{l@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c}" _n
file write tabla "\hline" _n
file write tabla "Año & Edad & \shortstack{Nivel de \\ educación} & \shortstack{Ingreso \\ mensual} & \shortstack{Ingreso \\ por hora} & \shortstack{Horas de \\ trabajo} & \shortstack{Sexo \\ (1=Mujer)} & \shortstack{Urbano \\ o rural} \\\\" _n
file write tabla "\hline" _n

// Escribir filas (formato compacto)
quietly {
    forvalues i = 1/`=_N' {
        local y  = year[`i']
        local e  = string(eda[`i'], "%5.2f")
        local n  = string(educacion[`i'], "%5.2f")
        local sm = string(ingocup[`i'], "%8.2f")
        local sh = string(ing_x_hrs[`i'], "%8.2f")
        local h  = string(hrsocup[`i'], "%5.2f")
        local m  = string(female[`i'], "%4.2f")
        local r  = string(rural[`i'], "%4.2f")
        file write tabla "`y' & `e' & `n' & `sm' & `sh' & `h' & `m' & `r' \\\\" _n
    }
}

// Cerrar tabla
file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore

//## 1.3.5 PERCENTIL 10 Tabla descriptiva
// ---- Exportar Tabla del P10 a LaTeX ----
preserve

// Calcular percentil 10 ponderado por año
collapse (p10) eda educacion ingocup ing_x_hrs hrsocup female rural [fw=fac], by(year)

// Abrir archivo .tex
file open tabla using "$graf\ENOE_STATS_1_3_5_P10.tex", write replace

// Encabezado LaTeX con ajuste de espacio vertical
file write tabla "\renewcommand{\arraystretch}{0.9}" _n
file write tabla "\begin{tabular}{l@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c@{\hskip 8pt}c}" _n
file write tabla "\hline" _n
file write tabla "Año & Edad & \shortstack{Nivel de \\ educación} & \shortstack{Ingreso \\ mensual} & \shortstack{Ingreso \\ por hora} & \shortstack{Horas de \\ trabajo} & \shortstack{Sexo \\ (1=Mujer)} & \shortstack{Urbano \\ o rural} \\\\" _n
file write tabla "\hline" _n

// Escribir filas (formato compacto)
quietly {
    forvalues i = 1/`=_N' {
        local y  = year[`i']
        local e  = string(eda[`i'], "%5.2f")
        local n  = string(educacion[`i'], "%5.2f")
        local sm = string(ingocup[`i'], "%8.2f")
        local sh = string(ing_x_hrs[`i'], "%8.2f")
        local h  = string(hrsocup[`i'], "%5.2f")
        local m  = string(female[`i'], "%4.2f")
        local r  = string(rural[`i'], "%4.2f")
        file write tabla "`y' & `e' & `n' & `sm' & `sh' & `h' & `m' & `r' \\\\" _n
    }
}

// Cerrar tabla
file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore

//# 1.7 BOXPLOTS

//## 1.7.1 ENOE_BOX_1.png  
// ---- Gráfica boxplot del salario por hora (log) por año ----

// Preservar base original
preserve

// Gráfico final con color, puntos y etiquetas claras
graph box lingmh [fw=fac] if trabajadorv == 1, ///
    over(year, label(angle(45) labsize(medium))) ///
    ytitle("Logaritmo del salario por hora") ///
    box(1, color("255 69 0")) ///
    marker(1, mcolor("255 69 0")) ///
    name(ENOE_BOX_1, replace) 

// Exportar imagen en alta resolución para mejor visibilidad
graph export "$graf/ENOE_BOX_1.png", replace width(1600) height(900)

// Restaurar base original
restore

//## 1.7.2 ENOE_BOX_2.png  
// ---- Gráfica boxplot del salario trimestral por hora (log) por año ----

// Preservar base original
preserve

// Asegurar que existe la variable en log
capture confirm variable ln_smh_tr
if _rc {
    gen ln_smh_tr = ln(smh)   // log del salario horario trimestral real
    label variable ln_smh_tr "Log salario trimestral por hora"
}

// Gráfico final con color, puntos y etiquetas claras
graph box ln_smh_tr [fw=fac] if trabajadorv == 1, ///
    over(year, label(angle(45) labsize(medium))) ///
    ytitle("Logaritmo del salario trimestral por hora") ///
    box(1, color("24 116 205")) ///
    marker(1, mcolor("24 116 205")) ///
    name(ENOE_BOX_2, replace)

// Exportar imagen en alta resolución
graph export "$graf/ENOE_BOX_2.png", replace width(1600) height(900)

// Restaurar base original
restore

//# 1.8 EVOLUCIÓN DE SALARIOS

//## 1.8.1 ENOE_1_8_1.tex  
// ---- Tabla de salarios promedio por año ----
preserve

// Filtrar solo trabajadores válidos
keep if trabajadorv == 1

// Etiquetas claras a variables
label variable sm  "Salario mensual"
label variable smh "Salario por hora"
label variable year "Año"

// Calcular medias ponderadas por año
collapse (mean) sm smh [fw=fac], by(year)

// Abrir archivo .tex
file open tabla using "$graf\ENOE_1_8_1.tex", write replace

// Encabezado LaTeX con ajuste de espacio vertical
file write tabla "\renewcommand{\arraystretch}{0.9}" _n
file write tabla "\begin{tabular}{l@{\hskip 8pt}c@{\hskip 8pt}c}" _n
file write tabla "\hline" _n
file write tabla "Año & \shortstack{Salario \\ mensual} & \shortstack{Salario \\ por hora} \\\\" _n
file write tabla "\hline" _n

// Escribir filas
quietly {
    forvalues i = 1/`=_N' {
        local y = year[`i']
        local sm = string(sm[`i'],  "%9.2f")
        local sh = string(smh[`i'], "%9.2f")
        file write tabla "`y' & `sm' & `sh' \\\\" _n
    }
}

// Cerrar tabla
file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore

//## 1.8.2 ENOE_1_8_2.tex  
// ---- Tabla de crecimiento de salarios por año ----
preserve

// Filtrar solo trabajadores válidos
keep if trabajadorv == 1

// Etiquetas a variables clave
label variable sm  "Salario mensual"
label variable smh "Salario por hora"
label variable year "Año"

// Calcular medias ponderadas por año
collapse (mean) sm smh [fw=fac], by(year)
order year
sort year

// Generar tasas de crecimiento interanual (%)
gen cambio1 = ((sm / sm[_n-1])  - 1) * 100
gen cambio2 = ((smh / smh[_n-1]) - 1) * 100

label variable cambio1 "Crecimiento salario mensual (%)"
label variable cambio2 "Crecimiento salario por hora (%)"

// Abrir archivo .tex
file open tabla using "$graf\ENOE_1_8_2.tex", write replace

// Encabezado LaTeX con ajuste de espacio vertical
file write tabla "\renewcommand{\arraystretch}{0.9}" _n
file write tabla "\begin{tabular}{l@{\hskip 8pt}c@{\hskip 8pt}c}" _n
file write tabla "\hline" _n
file write tabla "Año & \shortstack{Crec. salario \\ mensual (\%)} & \shortstack{Crec. salario \\ por hora (\%)} \\\\" _n
file write tabla "\hline" _n

// Escribir filas (omitimos el primer año porque no tiene crecimiento definido)
quietly {
    forvalues i = 2/`=_N' {
        local y  = year[`i']
        local c1 = string(cambio1[`i'], "%9.2f")
        local c2 = string(cambio2[`i'], "%9.2f")
        file write tabla "`y' & `c1' & `c2' \\\\" _n
    }
}

// Cerrar tabla
file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore

//## 1.8.3 ENOE_1_8_3.tex  
// ---- Tabla de salario mensual promedio por grupo ----
preserve

// Filtrar solo trabajadores válidos
keep if trabajadorv == 1

label variable year "Año"

// Calcular medias ponderadas de salario mensual por grupo
collapse (mean) sm [fw=fac], by(year grupo)

// Pasar a formato ancho
reshape wide sm, i(year) j(grupo)

label variable sm1 "Grupo 1"
label variable sm2 "Grupo 2"
label variable sm3 "Grupo 3"
label variable sm4 "Grupo 4"
label variable sm5 "Grupo 5"
label variable sm6 "Grupo 6"
label variable sm7 "Grupo 7"
label variable sm8 "Grupo 8"

// Abrir archivo .tex
file open tabla using "$graf\ENOE_1_8_3.tex", write replace

// Encabezado LaTeX con ajuste de espacio vertical
file write tabla "\renewcommand{\arraystretch}{0.9}" _n
file write tabla "\begin{tabular}{lcccccccc}" _n
file write tabla "\hline" _n
file write tabla "Año & Grupo 1 & Grupo 2 & Grupo 3 & Grupo 4 & Grupo 5 & Grupo 6 & Grupo 7 & Grupo 8 \\\\" _n
file write tabla "\hline" _n

// Escribir filas
quietly {
    forvalues i = 1/`=_N' {
        local y  = year[`i']
        local g1 = string(sm1[`i'], "%9.2f")
        local g2 = string(sm2[`i'], "%9.2f")
        local g3 = string(sm3[`i'], "%9.2f")
        local g4 = string(sm4[`i'], "%9.2f")
        local g5 = string(sm5[`i'], "%9.2f")
        local g6 = string(sm6[`i'], "%9.2f")
        local g7 = string(sm7[`i'], "%9.2f")
        local g8 = string(sm8[`i'], "%9.2f")
        file write tabla "`y' & `g1' & `g2' & `g3' & `g4' & `g5' & `g6' & `g7' & `g8' \\\\" _n
    }
}

// Cerrar tabla
file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore


//## 1.8.4 ENOE_1_8_4.tex  
// ---- Tabla de salario por hora promedio por grupo ----
preserve

// Filtrar solo trabajadores válidos
keep if trabajadorv == 1

label variable year "Año"

// Calcular medias ponderadas de salario por hora por grupo
collapse (mean) smh [fw=fac], by(year grupo)

// Pasar a formato ancho
reshape wide smh, i(year) j(grupo)

label variable smh1 "Grupo 1"
label variable smh2 "Grupo 2"
label variable smh3 "Grupo 3"
label variable smh4 "Grupo 4"
label variable smh5 "Grupo 5"
label variable smh6 "Grupo 6"
label variable smh7 "Grupo 7"
label variable smh8 "Grupo 8"

// Abrir archivo .tex
file open tabla using "$graf\ENOE_1_8_4.tex", write replace

// Encabezado LaTeX con ajuste de espacio vertical
file write tabla "\renewcommand{\arraystretch}{0.9}" _n
file write tabla "\begin{tabular}{lcccccccc}" _n
file write tabla "\hline" _n
file write tabla "Año & Grupo 1 & Grupo 2 & Grupo 3 & Grupo 4 & Grupo 5 & Grupo 6 & Grupo 7 & Grupo 8 \\\\" _n
file write tabla "\hline" _n

// Escribir filas
quietly {
    forvalues i = 1/`=_N' {
        local y  = year[`i']
        local g1 = string(smh1[`i'], "%9.2f")
        local g2 = string(smh2[`i'], "%9.2f")
        local g3 = string(smh3[`i'], "%9.2f")
        local g4 = string(smh4[`i'], "%9.2f")
        local g5 = string(smh5[`i'], "%9.2f")
        local g6 = string(smh6[`i'], "%9.2f")
        local g7 = string(smh7[`i'], "%9.2f")
        local g8 = string(smh8[`i'], "%9.2f")
        file write tabla "`y' & `g1' & `g2' & `g3' & `g4' & `g5' & `g6' & `g7' & `g8' \\\\" _n
    }
}

// Cerrar tabla
file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore

//## 1.8.5 ENOE_1_8_5.tex  
// ---- Tabla de crecimiento interanual del salario mensual por grupo ----
preserve

// Filtrar solo trabajadores válidos
keep if trabajadorv == 1
label variable year "Año"

// Calcular medias ponderadas de salario mensual por grupo
collapse (mean) sm [fw=fac], by(year grupo)

// Pasar a formato ancho
reshape wide sm, i(year) j(grupo)
order year
sort year

// Generar tasas de crecimiento interanual (%)
gen cambio1 = ((sm1 / sm1[_n-1]) - 1) * 100
gen cambio2 = ((sm2 / sm2[_n-1]) - 1) * 100
gen cambio3 = ((sm3 / sm3[_n-1]) - 1) * 100
gen cambio4 = ((sm4 / sm4[_n-1]) - 1) * 100
gen cambio5 = ((sm5 / sm5[_n-1]) - 1) * 100
gen cambio6 = ((sm6 / sm6[_n-1]) - 1) * 100
gen cambio7 = ((sm7 / sm7[_n-1]) - 1) * 100
gen cambio8 = ((sm8 / sm8[_n-1]) - 1) * 100

label variable cambio1 "Grupo 1"
label variable cambio2 "Grupo 2"
label variable cambio3 "Grupo 3"
label variable cambio4 "Grupo 4"
label variable cambio5 "Grupo 5"
label variable cambio6 "Grupo 6"
label variable cambio7 "Grupo 7"
label variable cambio8 "Grupo 8"

// Abrir archivo .tex
file open tabla using "$graf\ENOE_1_8_5.tex", write replace

// Encabezado LaTeX con ajuste de espacio vertical
file write tabla "\renewcommand{\arraystretch}{0.9}" _n
file write tabla "\begin{tabular}{lcccccccc}" _n
file write tabla "\hline" _n
file write tabla "Año & Grupo 1 & Grupo 2 & Grupo 3 & Grupo 4 & Grupo 5 & Grupo 6 & Grupo 7 & Grupo 8 \\\\" _n
file write tabla "\hline" _n

// Escribir filas (omitimos el primer año porque no tiene crecimiento definido)
quietly {
    forvalues i = 2/`=_N' {
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

// Cerrar tabla
file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore

//## 1.8.6 Tabla de crecimiento del salario mensual por hora por grupo
// ---- Exportar Tabla a LaTeX ----
preserve

// Mantener solo trabajadores válidos
keep if trabajadorv==1
label variable year "Año"

// Calcular promedio por año y grupo
collapse (mean) smh [fw=fac], by(year grupo)

// Pasar a formato ancho
reshape wide smh, i(year) j(grupo)
order year
sort year

// Generar crecimiento porcentual año contra año
gen cambio1 = ((smh1[_n]/smh1[_n-1])-1)*100
gen cambio2 = ((smh2[_n]/smh2[_n-1])-1)*100
gen cambio3 = ((smh3[_n]/smh3[_n-1])-1)*100
gen cambio4 = ((smh4[_n]/smh4[_n-1])-1)*100
gen cambio5 = ((smh5[_n]/smh5[_n-1])-1)*100
gen cambio6 = ((smh6[_n]/smh6[_n-1])-1)*100
gen cambio7 = ((smh7[_n]/smh7[_n-1])-1)*100
gen cambio8 = ((smh8[_n]/smh8[_n-1])-1)*100

// Etiquetas de variables
label variable cambio1 "Grupo 1"
label variable cambio2 "Grupo 2"
label variable cambio3 "Grupo 3"
label variable cambio4 "Grupo 4"
label variable cambio5 "Grupo 5"
label variable cambio6 "Grupo 6"
label variable cambio7 "Grupo 7"
label variable cambio8 "Grupo 8"

// Abrir archivo .tex
file open tabla using "$graf\ENOE_1_8_6.tex", write replace

// Encabezado LaTeX
file write tabla "\renewcommand{\arraystretch}{0.9}" _n
file write tabla "\begin{tabular}{lcccccccc}" _n
file write tabla "\hline" _n
file write tabla "Año & Grupo 1 & Grupo 2 & Grupo 3 & Grupo 4 & Grupo 5 & Grupo 6 & Grupo 7 & Grupo 8 \\\\" _n
file write tabla "\hline" _n

// Escribir filas
quietly {
    forvalues i = 2/`=_N' {   // empieza en 2 porque el primer año no tiene cambio
        local y  = year[`i']
        local g1 = string(cambio1[`i'], "%6.2f")
        local g2 = string(cambio2[`i'], "%6.2f")
        local g3 = string(cambio3[`i'], "%6.2f")
        local g4 = string(cambio4[`i'], "%6.2f")
        local g5 = string(cambio5[`i'], "%6.2f")
        local g6 = string(cambio6[`i'], "%6.2f")
        local g7 = string(cambio7[`i'], "%6.2f")
        local g8 = string(cambio8[`i'], "%6.2f")
        file write tabla "`y' & `g1' & `g2' & `g3' & `g4' & `g5' & `g6' & `g7' & `g8' \\\\" _n
    }
}

// Cerrar tabla
file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore

//### GRAFICAS

//## 1.8.1 ENOE_GRAF_1_8_1.png
// ---- Gráfica de índices de salarios (base 2005q1=100) ----

preserve
keep if trabajadorv==1

// Colapsar salarios promedio por trimestre
collapse (mean) sm smh [fw=fac], by(date year q)

// Renombrar para mayor claridad
rename sm  s1
rename smh s2

// Declarar datos como series trimestrales
tsset date, quarterly

// Normalizar con base 2005q1 = 100
foreach x in 1 2 {
    gen w  = s`x' if year==2005 & q==1
    egen w1 = max(w)
    replace s`x' = (s`x'/w1)*100
    drop w w1
}

// Etiquetas
label variable s1   "Mensual"
label variable s2   "Mensual por hora"
label variable date "Trimestre"

// Gráfico comparativo
twoway (connected s1 date, lcolor("255 69 0") mcolor("255 69 0") msymbol(circle) lwidth(medium) msize(0.4)) ///
       (connected s2 date, lcolor("24 116 205") mcolor("24 116 205") msymbol(square) lwidth(medium) msize(0.4)), ///
       yline(100, lcolor(black) lpattern(dot)) ///
       xtitle("Trimestre") ///
       ytitle("Índice (2005q1=100)") ///
       xlabel(`=tq(2005q1)'(4)`=tq(2025q2)', format(%tq) angle(45)) ///
       ylabel(50(10)130, grid) ///
       legend(order(1 "Mensual" 2 "Mensual por hora") pos(12) col(2)) ///
       graphregion(color(white)) bgcolor(white)

// Exportar gráfico
graph export "$graf\ENOE_GRAF_1_8_1.png", replace
restore

//## 1.8.2 ENOE_GRAF_1_8_2.png
// ---- Gráfica de índices de salario mensual por grupo (base 2005q1=100) ----

preserve
keep if trabajadorv==1

// Colapsar salarios mensuales promedio por trimestre y grupo
collapse (mean) sm [fw=fac], by(date year q grupo)
reshape wide sm, i(date) j(grupo)
tsset date, quarterly

// Normalizar con base 2005q1 = 100
foreach x in 1 2 3 4 5 6 7 8 {
    gen w  = sm`x' if year==2005 & q==1
    egen w1 = max(w)
    replace sm`x' = (sm`x'/w1)*100
    drop w w1
}

// Etiquetas
label variable sm1 "Grupo 1"
label variable sm2 "Grupo 2"
label variable sm3 "Grupo 3"
label variable sm4 "Grupo 4"
label variable sm5 "Grupo 5"
label variable sm6 "Grupo 6"
label variable sm7 "Grupo 7"
label variable sm8 "Grupo 8"
label variable date "Trimestre"

// Gráfica estilizada (alternando símbolos rellenos y huecos)
twoway ///
(connected sm1 date, msymbol(circle)        lcolor("255 69 0")    mcolor("255 69 0")    lwidth(thin) msize(0.3)) ///
(connected sm2 date, msymbol(square_hollow) lcolor("178 34 34")   mcolor("178 34 34")   lwidth(thin) msize(0.3)) ///
(connected sm3 date, msymbol(triangle)      lcolor("255 99 71")   mcolor("255 99 71")   lwidth(thin) msize(0.3)) ///
(connected sm4 date, msymbol(diamond_hollow) lcolor("220 20 60")  mcolor("220 20 60")   lwidth(thin) msize(0.3)) ///
(connected sm5 date, msymbol(circle_hollow) lcolor("255 105 180") mcolor("255 105 180") lwidth(thin) msize(0.3)) ///
(connected sm6 date, msymbol(square)        lcolor("199 21 133")  mcolor("199 21 133")  lwidth(thin) msize(0.3)) ///
(connected sm7 date, msymbol(triangle_hollow) lcolor("255 182 193") mcolor("255 182 193") lwidth(thin) msize(0.3)) ///
(connected sm8 date, msymbol(diamond)       lcolor("139 0 0")     mcolor("139 0 0")     lwidth(thin) msize(0.3)) ///
, ///
yline(100, lcolor(black) lpattern(dot)) ///
xtitle("Trimestre") ///
ytitle("Índice (2005q1=100)") ///
xlabel(`=tq(2005q1)'(4)`=tq(2025q2)', format(%tq) angle(45)) ///
ylabel(50(10)150, grid) ///
legend(order(1 "Grupo 1" 2 "Grupo 2" 3 "Grupo 3" 4 "Grupo 4" 5 "Grupo 5" 6 "Grupo 6" 7 "Grupo 7" 8 "Grupo 8") pos(2) ring(0) col(4)) ///
graphregion(color(white)) bgcolor(white)

// Exportar gráfico
graph export "$graf\ENOE_GRAF_1_8_2.png", replace
restore

//## 1.8.3 ENOE_GRAF_1_8_3.png
// ---- Gráfica de índices de salario por hora por grupo (base 2005q1=100) ----

preserve
keep if trabajadorv==1

// Colapsar salarios horarios promedio por trimestre y grupo
collapse (mean) smh [fw=fac], by(date year q grupo)
reshape wide smh, i(date) j(grupo)

// Normalizar con base 2005q1 = 100
foreach x in 1 2 3 4 5 6 7 8 {
    gen w  = smh`x' if year==2005 & q==1
    egen w1 = max(w)
    replace smh`x' = (smh`x'/w1)*100
    drop w w1
}

// Etiquetas
label variable smh1 "Grupo 1"
label variable smh2 "Grupo 2"
label variable smh3 "Grupo 3"
label variable smh4 "Grupo 4"
label variable smh5 "Grupo 5"
label variable smh6 "Grupo 6"
label variable smh7 "Grupo 7"
label variable smh8 "Grupo 8"
label variable date "Trimestre"

// Declarar como serie de tiempo trimestral
tsset date, quarterly

// Gráfica estilizada (impares rellenos / pares huecos)
twoway ///
(connected smh1 date, msymbol(circle)        lcolor("255 69 0")    mcolor("255 69 0")    lwidth(thin) msize(0.3)) ///
(connected smh2 date, msymbol(square_hollow) lcolor("178 34 34")   mcolor("178 34 34")   lwidth(thin) msize(0.3)) ///
(connected smh3 date, msymbol(triangle)      lcolor("255 99 71")   mcolor("255 99 71")   lwidth(thin) msize(0.3)) ///
(connected smh4 date, msymbol(diamond_hollow) lcolor("220 20 60")  mcolor("220 20 60")   lwidth(thin) msize(0.3)) ///
(connected smh5 date, msymbol(circle_hollow) lcolor("255 105 180") mcolor("255 105 180") lwidth(thin) msize(0.3)) ///
(connected smh6 date, msymbol(square)        lcolor("199 21 133")  mcolor("199 21 133")  lwidth(thin) msize(0.3)) ///
(connected smh7 date, msymbol(triangle_hollow) lcolor("255 182 193") mcolor("255 182 193") lwidth(thin) msize(0.3)) ///
(connected smh8 date, msymbol(diamond)       lcolor("139 0 0")     mcolor("139 0 0")     lwidth(thin) msize(0.3)) ///
, ///
yline(100, lcolor(black) lpattern(dot)) ///
xtitle("Trimestre") ///
ytitle("Índice (2005q1=100)") ///
xlabel(`=tq(2005q1)'(4)`=tq(2025q2)', format(%tq) angle(45)) ///
ylabel(50(10)150, grid) ///
legend(order(1 "Grupo 1" 2 "Grupo 2" 3 "Grupo 3" 4 "Grupo 4" 5 "Grupo 5" 6 "Grupo 6" 7 "Grupo 7" 8 "Grupo 8") pos(2) ring(0) col(4)) ///
graphregion(color(white)) bgcolor(white)

// Exportar gráfico
graph export "$graf\ENOE_GRAF_1_8_3.png", replace
restore

//## 1.8.4 ENOE_GRAF_1_8_4.png
// ---- Gráfica de brechas relativas en salario real por hora mensual ----

preserve
keep if trabajadorv==1

// Calcular promedios por año y grupo
collapse (mean) smh [fw=fac], by(year grupo)
reshape wide smh, i(year) j(grupo)

// Normalizar con base 2005 (año inicial de ENOE) = 100
foreach x in 1 2 3 4 5 6 7 8 {
    gen w  = smh`x' if year==2005
    egen w1 = max(w)
    replace smh`x' = (smh`x'/w1)*100
    drop w w1
}

// Calcular brechas respecto al grupo 4 (hombres jóvenes con mayor educación)
foreach x in 1 2 3 5 6 7 8 {
    gen Brecha`x' = (smh`x'/smh4)*100
}

// Gráfica estilizada de brechas
twoway ///
(connected Brecha1 year, msymbol(circle)        lcolor("255 69 0")    mcolor("255 69 0")    lwidth(thin) msize(0.3)) ///
(connected Brecha2 year, msymbol(square_hollow) lcolor("178 34 34")   mcolor("178 34 34")   lwidth(thin) msize(0.3)) ///
(connected Brecha3 year, msymbol(triangle)      lcolor("255 99 71")   mcolor("255 99 71")   lwidth(thin) msize(0.3)) ///
(connected Brecha5 year, msymbol(diamond_hollow) lcolor("220 20 60")  mcolor("220 20 60")   lwidth(thin) msize(0.3)) ///
(connected Brecha6 year, msymbol(circle_hollow) lcolor("199 21 133")  mcolor("199 21 133")  lwidth(thin) msize(0.3)) ///
(connected Brecha7 year, msymbol(triangle_hollow) lcolor("255 182 193") mcolor("255 182 193") lwidth(thin) msize(0.3)) ///
(connected Brecha8 year, msymbol(diamond)       lcolor("139 0 0")     mcolor("139 0 0")     lwidth(thin) msize(0.3)) ///
, ///
xtitle("Año") ///
ytitle("Salario relativo al Grupo 4 (%)") ///
xlabel(2005(2)2025) ///
ylabel(40(20)160, grid) ///
yline(100, lcolor(black) lpattern(dot)) ///
legend(order(1 "Grupo 1" 2 "Grupo 2" 3 "Grupo 3" 4 "Grupo 5" 5 "Grupo 6" 6 "Grupo 7" 7 "Grupo 8") ///
       pos(2) ring(0) col(4)) ///
graphregion(color(white)) bgcolor(white)

// Exportar gráfico
graph export "$graf\ENOE_GRAF_1_8_4.png", replace
restore

//## 1.8.5–1.8.8 ENOE_GRAF por año (boxplot ingreso mensual real, 1er trimestre)
preserve
keep if trabajadorv==1 & inlist(year,2022,2023,2024,2025) & q==1 ///
    & sm>0 & !missing(sm)

// Definir colores de la paleta
local col2022 "255 69 0"      // naranja rojizo
local col2023 "178 34 34"     // rojo vino
local col2024 "255 99 71"     // tomato
local col2025 "220 20 60"     // crimson

// Loop para generar y exportar cada gráfico
foreach y in 2022 2023 2024 2025 {
    local color = cond(`y'==2022, "`col2022'", ///
                 cond(`y'==2023, "`col2023'", ///
                 cond(`y'==2024, "`col2024'", "`col2025'")))

    graph box sm [fw=fac] if year==`y' & q==1, ///
        over(grupo, relabel(1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8") ///
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

    // Exportar cada gráfico con su nombre (cambia el índice según capítulo)
    graph export "$graf/ENOE_1_8_GRAF5_`y'.png", replace width(1800) height(700)
}

restore

//## 1.8.11 ENOE_GRAF_1_8_11.png
// ---- Bubble plot de salarios por hora mensual Grupo 1 vs Grupo 7 (Q1, 2005–2025) ----

preserve
keep if inlist(grupo,1,7) & trabajadorv==1 & inrange(year,2005,2025) & q==1

// Calcular salario medio por hora mensual y número de válidos
collapse (mean) salario_hora_mensual=smh ///
         (count) n_validos=smh, by(year grupo)

// Bubble plot con relleno semitransparente y contorno sólido
twoway ///
    (scatter salario_hora_mensual year if grupo==1 [aweight=n_validos], ///
        msymbol(O) mcolor("255 69 0%50") mlcolor("255 69 0") lwidth(thin)) ///
    (scatter salario_hora_mensual year if grupo==7 [aweight=n_validos], ///
        msymbol(O) mcolor("30 144 255%50") mlcolor("30 144 255") lwidth(thin)), ///
    xlabel(2005(2)2025, angle(45)) ///
    xtitle("Año") ///
    ytitle("Salario real por hora mensual") ///
    ylabel(, grid) ///
    legend(order(1 "Grupo 1" 2 "Grupo 7") pos(2) ring(0) row(1) region(lstyle(none))) ///
    graphregion(color(white)) bgcolor(white)

// Exportar gráfico
graph export "$graf\ENOE_GRAF_1_8_11.png", replace
restore

//## 1.8.12 ENOE_GRAF_1_8_12.png
// ---- Bubble plot: Mujeres baja educación (25–45 vs. 46–65) en salario real por hora mensual ----

preserve
keep if inlist(grupo,1,5) & trabajadorv==1 & inrange(year,2005,2025) & q==1

// Calcular salario medio por hora mensual y número de válidas
collapse (mean) salario_hora_mensual=smh ///
         (count) n_validas=smh, by(year grupo)

// Bubble plot con relleno semitransparente y contorno sólido
twoway ///
    (scatter salario_hora_mensual year if grupo==1 [aweight=n_validas], ///
        msymbol(O) mcolor("255 69 0%50") mlcolor("255 69 0") lwidth(thin)) ///
    (scatter salario_hora_mensual year if grupo==5 [aweight=n_validas], ///
        msymbol(O) mcolor("30 144 255%50") mlcolor("30 144 255") lwidth(thin)), ///
    xlabel(2005(2)2025, angle(45)) ///
    xtitle("Año") ///
    ytitle("Salario real por hora mensual") ///
    ylabel(, grid) ///
    legend(order(1 "Grupo 1 (25–45)" 2 "Grupo 5 (46–65)") pos(12) ring(0) row(1) region(lstyle(none))) ///
    graphregion(color(white)) bgcolor(white)

// Exportar gráfico
graph export "$graf\ENOE_GRAF_1_8_12.png", replace
restore








//#1.9

//======================================================
//### 1.9 - Tabla de proporción de trabajadores en la población (ENOE)
//======================================================
preserve
keep if !missing(grupo) & !missing(trabajadorv)

// Calcular proporción ponderada de trabajadores por grupo y año
collapse (mean) trabajadorv [fw=fac], by(year grupo)

// Pasar a formato wide (cada grupo como columna)
reshape wide trabajadorv, i(year) j(grupo)

// Etiquetas
label variable year "Año"
label variable trabajadorv1 "Grupo 1"
label variable trabajadorv2 "Grupo 2"
label variable trabajadorv3 "Grupo 3"
label variable trabajadorv4 "Grupo 4"
label variable trabajadorv5 "Grupo 5"
label variable trabajadorv6 "Grupo 6"
label variable trabajadorv7 "Grupo 7"
label variable trabajadorv8 "Grupo 8"

// ---- Exportar a LaTeX ----
file open tabla using "$graf\ENOE_1_9_1.tex", write replace
file write tabla "\begin{tabular}{lcccccccc}" _n
file write tabla "\hline" _n
file write tabla "Año & \shortstack{Grupo \\ 1} & \shortstack{Grupo \\ 2} & \shortstack{Grupo \\ 3} & \shortstack{Grupo \\ 4} & \shortstack{Grupo \\ 5} & \shortstack{Grupo \\ 6} & \shortstack{Grupo \\ 7} & \shortstack{Grupo \\ 8} \\\\" _n
file write tabla "\hline" _n

quietly {
    forvalues i = 1/`=_N' {
        local y  = year[`i']
        local g1 = string(trabajadorv1[`i']*100, "%9.2f")
        local g2 = string(trabajadorv2[`i']*100, "%9.2f")
        local g3 = string(trabajadorv3[`i']*100, "%9.2f")
        local g4 = string(trabajadorv4[`i']*100, "%9.2f")
        local g5 = string(trabajadorv5[`i']*100, "%9.2f")
        local g6 = string(trabajadorv6[`i']*100, "%9.2f")
        local g7 = string(trabajadorv7[`i']*100, "%9.2f")
        local g8 = string(trabajadorv8[`i']*100, "%9.2f")
        file write tabla "`y' & `g1' & `g2' & `g3' & `g4' & `g5' & `g6' & `g7' & `g8' \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla
restore

//======================================================
//### 1.9.2 - Tabla de proporción total de trabajadores en la población (ENOE)
//======================================================
preserve
keep if !missing(trabajadorv)

// Crear indicador de trabajador válido (1=trabajador, 0=no trabajador)
gen trab = trabajadorv==1

// Calcular proporción ponderada de trabajadores por año
collapse (mean) trab [iw=fac], by(year)
replace trab = trab*100   // pasar a porcentaje

label variable year "Año"
label variable trab "Proporción de trabajadores (%)"

// ---- Exportar a LaTeX ----
file open tabla using "$graf\ENOE_1_9_TOT.tex", write replace
file write tabla "\begin{table}[H]" _n
file write tabla "\centering" _n
file write tabla "\label{tab:ENOE_1_9_TOT}" _n
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
file write tabla "\\\\\" _n
file write tabla "\end{table}" _n
file close tabla
restore

***************************************

//# 3 REGRESION CUANTIL

****************************************


//### PASO 1: CARGA Y LIMPIEZA -----------------------------------
use "$ENOE\Base_ENOE_SDEM_2005_2025.dta", clear   // carga base ENOE

destring year q fac, replace                     // asegura numéricos
rename fac factor                                // renombra factor
gen fac = factor*hrsocup                         // nuevo factor ponderado

//### PASO 2: FILTRO TEMPORAL ------------------------------------
keep if inlist(year,2005,2015,2025)              // años 2005, 2015 y 2025
keep if inlist(q,1,2)                            // trimestres 1 y 2

//### PASO 3: VARIABLES BÁSICAS ----------------------------------
replace anios_esc = . if anios_esc == 99         // limpia escolaridad
gen fem = sex - 1                                // 0=Hombre 1=Mujer

//### PASO 4: INGRESOS LIMPIOS ----------------------------------
replace ingocup   = . if ingocup   == 999999 | ingocup   == 0   // missing
replace ing_x_hrs = . if ing_x_hrs == 999999 | ing_x_hrs == 0

//### PASO 5: FILTRO TRABAJADOR VÁLIDO ---------------------------
gen trabajadorv = 0
replace trabajadorv = 1 if ingocup != . & ing_x_hrs != . & ingocup > 0 & ing_x_hrs > 0
drop if trabajadorv == 0

//### PASO 6: INGRESOS REALES ------------------------------------
gen ing = (ing_x_hrs/INPC)*100                  // ingreso real por hora
replace ing = 1     if ing <= 1   & ing != .    // censura inferior
replace ing = 5000  if ing >= 5000 & ing != .   // censura superior

//### PASO 7: LOGARITMO DE INGRESOS -------------------------------
gen ling = ln(ing)                               // ln ingreso hora
drop if ling == .                                // limpia missing

//### PASO 8: GUARDAR BASE ---------------------------------------
save "$ENOE\ENOE_AJUSTADA.dta", replace


//### PASO 9: GENERAR CUANTILES (T1+T2 juntos) -------------------
foreach x in 2005 2015 2025 {                 // años relevantes
    xtile q`x'_h = ling [aw=fac] if year==`x' & fem==0, nq(100)  // hombres
    xtile q`x'_m = ling [aw=fac] if year==`x' & fem==1, nq(100)  // mujeres
}

//### PASO 10: UNIR CUANTILES ------------------------------------
gen cuantil = .
foreach x in 2005 2015 2025 {
    replace cuantil = q`x'_h if year==`x' & fem==0
    replace cuantil = q`x'_m if year==`x' & fem==1
}

//### PASO 11: ORDENAR Y LIMPIAR ---------------------------------
sort fem cuantil
drop if cuantil == .


//### PASO 12: COLAPSAR PROMEDIOS (T1+T2 juntos) -----------------
collapse (mean) ling [aw=fac], by(cuantil fem year)

//### PASO 13: REORGANIZAR DATOS (reshape wide) ------------------
reshape wide ling, i(cuantil fem) j(year)
sort fem cuantil
drop if cuantil == .


//### PASO 14: INTERPOLAR VALORES FALTANTES ----------------------
// Promedio de vecinos (cuantil anterior/posterior o más cercanos).
// Aplica dentro de cada sexo y cuantil ya ordenado.
foreach var of varlist ling2005 ling2015 ling2025 {
    replace `var' = (`var'[_n-1]+`var'[_n+4])/2 if ///
        `var'==. & `var'[_n-1]!=. & `var'[_n+1]==. & `var'[_n+2]==. & `var'[_n+3]==. & `var'[_n+4]!=.
    replace `var' = (`var'[_n-1]+`var'[_n+3])/2 if ///
        `var'==. & `var'[_n-1]!=. & `var'[_n+1]==. & `var'[_n+2]==. & `var'[_n+3]!=.
    replace `var' = (`var'[_n-2]+`var'[_n+2])/2 if ///
        `var'==. & `var'[_n-1]==. & `var'[_n+1]==. & `var'[_n-2]!=. & `var'[_n+2]!=.
    replace `var' = (`var'[_n-3]+`var'[_n+1])/2 if ///
        `var'==. & `var'[_n+1]!=. & `var'[_n-1]==. & `var'[_n-2]==. & `var'[_n-3]!=.
    replace `var' = (`var'[_n-1]+`var'[_n+1])/2 if ///
        `var'==. & `var'[_n-1]!=. & `var'[_n+1]!=.
    replace `var' = (`var'[_n-1]+`var'[_n+2])/2 if ///
        `var'==. & `var'[_n-1]!=. & `var'[_n+2]!=.
}


//### PASO 15: DIFERENCIAS ENTRE AÑOS (T1+T2 conjuntos) ----------
gen dif_2005_2015 = (ling2015 - ling2005)*100   // 2005→2015
gen dif_2015_2025 = (ling2025 - ling2015)*100   // 2015→2025
gen dif_2005_2025 = (ling2025 - ling2005)*100   // 2005→2025


//## GRAFICAS

//### 3.5.1 2005 vs 2015 (T1+T2 conjuntos)

preserve
capture drop y_top y_bot
gen y_top = 50   // techo eje Y
gen y_bot = -10  // piso eje Y

twoway ///
    (rarea y_top y_bot cuantil if inrange(cuantil,0,10), fcolor(gs12%25) lcolor(white)) ///
    (rarea y_top y_bot cuantil if inrange(cuantil,90,100), fcolor(gs12%25) lcolor(white)) ///
    (connected dif_2005_2015 cuantil if fem==0, lcolor("255 69 0") mcolor("255 69 0") lwidth(vthin) msize(0.6)) ///
    (lowess    dif_2005_2015 cuantil if fem==0, lcolor("255 69 0%40") lwidth(medthick)) ///
    (connected dif_2005_2015 cuantil if fem==1, lcolor("24 116 205") mcolor("24 116 205") lwidth(vthin) msize(0.6)) ///
    (lowess    dif_2005_2015 cuantil if fem==1, lcolor("24 116 205%40") lwidth(medthick)), ///
    xtitle("Cuantiles", size(large)) ///
    ytitle("Δ Log salario por hora (2005–2015)", size(large)) ///
    xlabel(0(10)100, labsize(large)) ///
    ylabel(, labsize(large) angle(horizontal) grid) ///
    legend(order(3 "Hombres" 5 "Mujeres") position(12) ring(0) cols(2) size(medsmall)) ///
    graphregion(color(white)) plotregion(lstyle(none)) ///
    xline(50, lcolor(red) lpattern(dot)) ///
    yline(0,  lcolor(red) lpattern(dot) lwidth(thick))

graph export "$graf/ENOE_3_5_1.png", replace
restore

//### 3.5.2 2015 vs 2025 (T1+T2 conjuntos)

preserve
capture drop y_top y_bot
gen y_top = 50   // techo eje Y
gen y_bot = -10  // piso eje Y

twoway ///
    (rarea y_top y_bot cuantil if inrange(cuantil,0,10), fcolor(gs12%25) lcolor(white)) ///
    (rarea y_top y_bot cuantil if inrange(cuantil,90,100), fcolor(gs12%25) lcolor(white)) ///
    (connected dif_2015_2025 cuantil if fem==0, lcolor("255 69 0") mcolor("255 69 0") lwidth(vthin) msize(0.6)) ///
    (lowess    dif_2015_2025 cuantil if fem==0, lcolor("255 69 0%40") lwidth(medthick)) ///
    (connected dif_2015_2025 cuantil if fem==1, lcolor("24 116 205") mcolor("24 116 205") lwidth(vthin) msize(0.6)) ///
    (lowess    dif_2015_2025 cuantil if fem==1, lcolor("24 116 205%40") lwidth(medthick)), ///
    xtitle("Cuantiles", size(large)) ///
    ytitle("Δ Log salario por hora (2015–2025)", size(large)) ///
    xlabel(0(10)100, labsize(large)) ///
    ylabel(, labsize(large) angle(horizontal) grid) ///
    legend(order(3 "Hombres" 5 "Mujeres") position(12) ring(0) cols(2) size(medsmall)) ///
    graphregion(color(white)) plotregion(lstyle(none)) ///
    xline(50, lcolor(red) lpattern(dot)) ///
    yline(0,  lcolor(red) lpattern(dot) lwidth(thick))

graph export "$graf/ENOE_3_5_2.png", replace
restore

//### 3.5.3 2005 vs 2025 (T1+T2 conjuntos)

preserve
capture drop y_top y_bot
gen y_top = 50   // techo eje Y
gen y_bot = -10  // piso eje Y

twoway ///
    (rarea y_top y_bot cuantil if inrange(cuantil,0,10), fcolor(gs12%25) lcolor(white)) ///
    (rarea y_top y_bot cuantil if inrange(cuantil,90,100), fcolor(gs12%25) lcolor(white)) ///
    (connected dif_2005_2025 cuantil if fem==0, lcolor("255 69 0") mcolor("255 69 0") lwidth(vthin) msize(0.6)) ///
    (lowess    dif_2005_2025 cuantil if fem==0, lcolor("255 69 0%40") lwidth(medthick)) ///
    (connected dif_2005_2025 cuantil if fem==1, lcolor("24 116 205") mcolor("24 116 205") lwidth(vthin) msize(0.6)) ///
    (lowess    dif_2005_2025 cuantil if fem==1, lcolor("24 116 205%40") lwidth(medthick)), ///
    xtitle("Cuantiles", size(large)) ///
    ytitle("Δ Log salario por hora (2005–2025)", size(large)) ///
    xlabel(0(10)100, labsize(large)) ///
    ylabel(, labsize(large) angle(horizontal) grid) ///
    legend(order(3 "Hombres" 5 "Mujeres") position(12) ring(0) cols(2) size(medsmall)) ///
    graphregion(color(white)) plotregion(lstyle(none)) ///
    xline(50, lcolor(red) lpattern(dot)) ///
    yline(0,  lcolor(red) lpattern(dot) lwidth(thick))

graph export "$graf/ENOE_3_5_3.png", replace
restore

//# 3  ESTIMADORES REG CUANTIL

//==========================================================
//### PASO 1: Cargar base ajustada y filtrar años de interés
//==========================================================
use "$ENOE\ENOE_AJUSTADA.dta", clear
keep if inlist(year, 2005, 2015, 2025)

//==========================================================
//### PASO 2: Variables explicativas
//==========================================================

// Edad al cuadrado
capture confirm variable edad2
if _rc gen edad2 = eda^2

// Rural: 1 si t_loc==4, 0 en otro caso
destring t_loc, replace
qui gen rural = 0
qui replace rural = 1 if t_loc==4

// Female: 1 si sex==2, 0 en otro caso   (en ENOE: 1=Hombre, 2=Mujer)
qui gen female = 0
qui replace female = 1 if sex==2

// Eliminamos missings en variable dependiente
drop if missing(ling)

// Lista de regresores
global X "anios_esc eda edad2 rural female"

//==========================================================
//### PASO 2.1: OLS robusto por AÑO con preserve/restore
//==========================================================
foreach y of numlist 2005 2015 2025 {
    preserve
        reg ling $X [pw=factor] if year==`y', robust

        esttab using "$graf/OLS_ENOE_`y'.tex", replace ///
            label booktabs fragment nomtitles ///
            cells("b(fmt(3) star) se(fmt(3)) t(fmt(2)) p(fmt(3)) ci(fmt(3))") ///
            collabels("Coeficiente" "Error Est." "t" "p" "[95\% CI]") ///
            alignment(l|c|c|c|c|c) ///
            varlabels(anios_esc "Escolaridad" ///
                      eda "Edad" ///
                      edad2 "Edad$^2$" ///
                      rural "Rural" ///
                      female "Mujer" ///
                      _cons "Constante") ///
            stats(N r2, labels("N" "R$^2$") fmt(0 3))

        di as text "OLS `y' exportado a $graf/OLS_ENOE_`y'.tex"
    restore
}

//==========================================================
//### PASO 3: Construir variable de cuantiles (1..100) por año
//==========================================================
quietly foreach y of numlist 2005 2015 2025 {
    xtile q`y'_h = ling [pw=factor] if year==`y', nq(100)
}

gen quant = .
replace quant = q2005_h if year==2005
replace quant = q2015_h if year==2015
replace quant = q2025_h if year==2025

drop q2005_h q2015_h q2025_h
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

save "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", replace
restore   // volvemos a la base ajustada con factor


//==========================================================
//### PASO 5: Estimar OLS por año y guardar resultados
//==========================================================
foreach y of numlist 2005 2015 2025 {
    preserve
        // correr la regresión OLS robusta con ponderador
        reg ling $X [pw=factor] if year==`y', robust

        // abrir base de resultados y actualizar
        use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
        replace beta_ols_anios_esc = _b[anios_esc] if year==`y'
        replace beta_ols_edad      = _b[eda]       if year==`y'
        replace beta_ols_edad2     = _b[edad2]     if year==`y'
        replace beta_ols_female    = _b[female]    if year==`y'
        replace beta_ols_rural     = _b[rural]     if year==`y'
        save "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", replace
    restore

    di as text "OLS `y' listo"
}

//==========================================================
//### PASO 6: Estimar regresiones cuantílicas y guardar
//==========================================================
forvalues q = 1/99 {
    local tau = `q'/100
    foreach y of numlist 2005 2015 2025 {
        preserve
            // Filtrar base ajustada por año
            keep if year==`y'

            // Estimar regresión cuantílica ponderada
            quietly qreg ling $X [pw=factor], q(`tau') vce(robust)

            // Abrir base de resultados y actualizar
            use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
            replace beta_q_anios_esc = _b[anios_esc] if year==`y' & quant==`q'
            replace se_q_anios_esc   = _se[anios_esc] if year==`y' & quant==`q'
            replace beta_q_edad      = _b[eda]       if year==`y' & quant==`q'
            replace se_q_edad        = _se[eda]      if year==`y' & quant==`q'
            replace beta_q_edad2     = _b[edad2]     if year==`y' & quant==`q'
            replace se_q_edad2       = _se[edad2]    if year==`y' & quant==`q'
            replace beta_q_female    = _b[female]    if year==`y' & quant==`q'
            replace se_q_female      = _se[female]   if year==`y' & quant==`q'
            replace beta_q_rural     = _b[rural]     if year==`y' & quant==`q'
            replace se_q_rural       = _se[rural]    if year==`y' & quant==`q'
            save "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", replace
        restore

        di as text "`y' cuantil `q' listo"
    }
}

//==========================================================
//### PASO 7: Ordenar y etiquetar dataset final
//==========================================================
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear

order year quant beta_ols_* beta_q_* se_q_*
sort year quant

label var year  "Año"
label var quant "Cuantil (1-99)"

save "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", replace

//## GRAFICAS REG CUANTIL

//### 2005: Gráfica de Regresión Cuantil Escolaridad

use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2005

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
graph export "$graf\QUANTIL_ESC_3_5_2005.png", replace

//### 2005: Gráfica de Regresión Cuantil Female

use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2005

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
graph export "$graf\QUANTIL_FEM_3_5_2005.png", replace

//### 2005: Gráfica de Regresión Cuantil Rural

use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2005

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
graph export "$graf\QUANTIL_RURAL_3_5_2005.png", replace

//### 2005: Gráfica de Regresión Cuantil Edad

use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2005

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
           position(4) ring(0) cols(1)) ///
    note(" ")

// Guardar
graph export "$graf\QUANTIL_EDAD_3_5_2005.png", replace

//### 2005: Gráfica de Regresión Cuantil Edad^2

use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2005

// Intervalos de confianza 95% para edad^2 (solo cuantiles)
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
           position(12) ring(0) cols(3)) ///
    note(" ")

// Guardar
graph export "$graf\QUANTIL_EDAD2_3_5_2005.png", replace

//### 2015: Gráfica de Reg Cuantil Escolaridad

use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2015

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
graph export "$graf\QUANTIL_ESC_2015.png", replace

//### 2015: Gráfica de Reg Cuantil Female

use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2015

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
graph export "$graf\QUANTIL_FEM_2015.png", replace

//### 2015: Gráfica de Reg Cuantil Rural

use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2015

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
           position(4) ring(0) cols(3)) ///
    note(" ")

// Guardar
graph export "$graf\QUANTIL_RURAL_2015.png", replace

//### 2015: Gráfica de Reg Cuantil Edad

use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2015

// Intervalos de confianza 95% para edad (solo cuantiles)
gen lb_q_edad = beta_q_edad - 1.96*se_q_edad
gen hb_q_edad = beta_q_edad + 1.96*se_q_edad

// Graficar
twoway ///
    (rarea lb_q_edad hb_q_edad quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_edad quant, ///
        lcolor("24 116 205") mcolor("24 116 205") ///
        lwidth(vthin) msize(0.3)) ///
    (connected beta_ols_edad quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medthin)), ///
    xtitle("Cuantil") ///
    ytitle("Cambio en el ln del salario por hora") ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(5) ring(0) cols(3)) ///
    note(" ")

// Guardar
graph export "$graf\QUANTIL_EDAD_2015.png", replace

//### 2015: Gráfica de Reg Cuantil Edad^2

use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2015

// Intervalos de confianza 95% para edad2 (solo cuantiles)
gen lb_q_edad2 = beta_q_edad2 - 1.96*se_q_edad2
gen hb_q_edad2 = beta_q_edad2 + 1.96*se_q_edad2

// Graficar
twoway ///
    (rarea lb_q_edad2 hb_q_edad2 quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_edad2 quant, ///
        lcolor("24 116 205") mcolor("24 116 205") ///
        lwidth(vthin) msize(0.3)) ///
    (connected beta_ols_edad2 quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medthin)), ///
    xtitle("Cuantil") ///
    ytitle("Cambio en el ln del salario por hora") ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(12) ring(0) cols(3)) ///
    note(" ")

// Guardar
graph export "$graf\QUANTIL_EDAD2_2015.png", replace

//### 2025: Gráfica de Reg Cuantil Escolaridad

use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2025

// Intervalos de confianza 95% para escolaridad (solo cuantiles)
gen lb_q_escol = beta_q_anios_esc - 1.96*se_q_anios_esc
gen hb_q_escol = beta_q_anios_esc + 1.96*se_q_anios_esc

// Graficar
twoway ///
    (rarea lb_q_escol hb_q_escol quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_anios_esc quant, ///
        lcolor("60 179 113") mcolor("60 179 113") ///  // verde pastel (MediumSeaGreen)
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
graph export "$graf\QUANTIL_ESC_2025.png", replace

//### 2025: Gráfica de Reg Cuantil Female

use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2025

// Intervalos de confianza 95% para female (solo cuantiles)
gen lb_q_fem = beta_q_female - 1.96*se_q_female
gen hb_q_fem = beta_q_female + 1.96*se_q_female

// Graficar
twoway ///
    (rarea lb_q_fem hb_q_fem quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_female quant, ///
        lcolor("60 179 113") mcolor("60 179 113") ///  verde pastel
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
graph export "$graf\QUANTIL_FEM_2025.png", replace

//### 2025: Gráfica de Reg Cuantil Rural

use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2025

// Intervalos de confianza 95% para rural (solo cuantiles)
gen lb_q_rural = beta_q_rural - 1.96*se_q_rural
gen hb_q_rural = beta_q_rural + 1.96*se_q_rural

// Graficar
twoway ///
    (rarea lb_q_rural hb_q_rural quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_rural quant, ///
        lcolor("60 179 113") mcolor("60 179 113") /// verde pastel
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_rural quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medthin)), ///
    xtitle("Cuantil") ///
    ytitle("Cambio en el ln del salario por hora") ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(4) ring(0) cols(3)) ///
    note(" ")

// Guardar
graph export "$graf\QUANTIL_RURAL_2025.png", replace

//### 2025: Gráfica de Reg Cuantil Edad

use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2025

// Intervalos de confianza 95% para edad (solo cuantiles)
gen lb_q_edad = beta_q_edad - 1.96*se_q_edad
gen hb_q_edad = beta_q_edad + 1.96*se_q_edad

// Graficar
twoway ///
    (rarea lb_q_edad hb_q_edad quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_edad quant, ///
        lcolor("60 179 113") mcolor("60 179 113") /// verde pastel
        lwidth(vthin) msize(0.3)) ///
    (connected beta_ols_edad quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medthin)), ///
    xtitle("Cuantil") ///
    ytitle("Cambio en el ln del salario por hora") ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(12) ring(0) cols(3)) ///
    note(" ")

// Guardar
graph export "$graf\QUANTIL_EDAD_2025.png", replace

//### 2025: Gráfica de Reg Cuantil Edad^2

use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2025

// Intervalos de confianza 95% para edad2 (solo cuantiles)
gen lb_q_edad2 = beta_q_edad2 - 1.96*se_q_edad2
gen hb_q_edad2 = beta_q_edad2 + 1.96*se_q_edad2

// Graficar
twoway ///
    (rarea lb_q_edad2 hb_q_edad2 quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_edad2 quant, ///
        lcolor("60 179 113") mcolor("60 179 113") /// verde pastel
        lwidth(vthin) msize(0.3)) ///
    (connected beta_ols_edad2 quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medthin)), ///
    xtitle("Cuantil") ///
    ytitle("Cambio en el ln del salario por hora") ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(12) ring(0) cols(3)) ///
    note(" ")

// Guardar
graph export "$graf\QUANTIL_EDAD2_2025.png", replace


//## COMBINADAS

//#### 2005 ESCOLARIDAD
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2005

gen lb_q_escol = beta_q_anios_esc - 1.96*se_q_anios_esc
gen hb_q_escol = beta_q_anios_esc + 1.96*se_q_anios_esc

twoway ///
    (rarea lb_q_escol hb_q_escol quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_anios_esc quant, ///
        lcolor("255 69 0") mcolor("255 69 0") /// naranja
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_anios_esc quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2005", size(huge)) ///
    ytitle("Cambio en el ln del salario por hora", size(huge)) ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(12) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/ESC_2005.gph", replace


//#### 2015 ESCOLARIDAD
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2015

gen lb_q_escol = beta_q_anios_esc - 1.96*se_q_anios_esc
gen hb_q_escol = beta_q_anios_esc + 1.96*se_q_anios_esc

twoway ///
    (rarea lb_q_escol hb_q_escol quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_anios_esc quant, ///
        lcolor("24 116 205") mcolor("24 116 205") /// azul
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_anios_esc quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2015", size(huge)) ///
    ytitle("") /// sin título en eje Y del medio
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(12) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/ESC_2015.gph", replace


//#### 2025 ESCOLARIDAD
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2025

gen lb_q_escol = beta_q_anios_esc - 1.96*se_q_anios_esc
gen hb_q_escol = beta_q_anios_esc + 1.96*se_q_anios_esc

twoway ///
    (rarea lb_q_escol hb_q_escol quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_anios_esc quant, ///
        lcolor("60 179 113") mcolor("60 179 113") /// verde pastel
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_anios_esc quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2025", size(huge)) ///
    ytitle("") ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(12) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/ESC_2025.gph", replace


//#### COMBINADA ESCOLARIDAD (2005, 2015, 2025)
graph combine "$graf/ESC_2005.gph" "$graf/ESC_2015.gph" "$graf/ESC_2025.gph", ///
    col(3) graphregion(color(white)) ///
    ycommon xcommon imargin(0 0 0 0) ///
    ysize(5) xsize(20) ///
    name(Graf_ESC_Conjunta, replace)

graph export "$graf/ESC_2005_2015_2025.png", replace width(5000)

//#### 2005 FEMALE
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2005

gen lb_q_fem = beta_q_female - 1.96*se_q_female
gen hb_q_fem = beta_q_female + 1.96*se_q_female

twoway ///
    (rarea lb_q_fem hb_q_fem quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_female quant, ///
        lcolor("255 69 0") mcolor("255 69 0") /// naranja
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_female quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2005", size(huge)) ///
    ytitle("Cambio en el ln del salario por hora", size(huge)) ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(10) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/FEM_2005.gph", replace


//#### 2015 FEMALE
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2015

gen lb_q_fem = beta_q_female - 1.96*se_q_female
gen hb_q_fem = beta_q_female + 1.96*se_q_female

twoway ///
    (rarea lb_q_fem hb_q_fem quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_female quant, ///
        lcolor("24 116 205") mcolor("24 116 205") /// azul
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_female quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2015", size(huge)) ///
    ytitle("") ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(10) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/FEM_2015.gph", replace


//#### 2025 FEMALE
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2025

gen lb_q_fem = beta_q_female - 1.96*se_q_female
gen hb_q_fem = beta_q_female + 1.96*se_q_female

twoway ///
    (rarea lb_q_fem hb_q_fem quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_female quant, ///
        lcolor("60 179 113") mcolor("60 179 113") /// verde pastel
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_female quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2025", size(huge)) ///
    ytitle("") ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(10) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/FEM_2025.gph", replace


//#### COMBINADA FEMALE (2005, 2015, 2025)
graph combine "$graf/FEM_2005.gph" "$graf/FEM_2015.gph" "$graf/FEM_2025.gph", ///
    col(3) graphregion(color(white)) ///
    ycommon xcommon imargin(0 0 0 0) ///
    ysize(5) xsize(20) ///
    name(Graf_FEM_Conjunta, replace)

graph export "$graf/FEM_2005_2015_2025.png", replace width(5000)

//#### 2005 RURAL
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2005

gen lb_q_rural = beta_q_rural - 1.96*se_q_rural
gen hb_q_rural = beta_q_rural + 1.96*se_q_rural

twoway ///
    (rarea lb_q_rural hb_q_rural quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_rural quant, ///
        lcolor("255 69 0") mcolor("255 69 0") /// naranja
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_rural quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2005", size(huge)) ///
    ytitle("Cambio en el ln del salario por hora", size(huge)) ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(4) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/RURAL_2005.gph", replace


//#### 2015 RURAL
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2015

gen lb_q_rural = beta_q_rural - 1.96*se_q_rural
gen hb_q_rural = beta_q_rural + 1.96*se_q_rural

twoway ///
    (rarea lb_q_rural hb_q_rural quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_rural quant, ///
        lcolor("24 116 205") mcolor("24 116 205") /// azul
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_rural quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2015", size(huge)) ///
    ytitle("") ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(4) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/RURAL_2015.gph", replace


//#### 2025 RURAL
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2025

gen lb_q_rural = beta_q_rural - 1.96*se_q_rural
gen hb_q_rural = beta_q_rural + 1.96*se_q_rural

twoway ///
    (rarea lb_q_rural hb_q_rural quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_rural quant, ///
        lcolor("60 179 113") mcolor("60 179 113") /// verde pastel
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_rural quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2025", size(huge)) ///
    ytitle("") ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(4) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/RURAL_2025.gph", replace


//#### COMBINADA RURAL (2005, 2015, 2025)
graph combine "$graf/RURAL_2005.gph" "$graf/RURAL_2015.gph" "$graf/RURAL_2025.gph", ///
    col(3) graphregion(color(white)) ///
    ycommon xcommon imargin(0 0 0 0) ///
    ysize(5) xsize(20) ///
    name(Graf_RURAL_Conjunta, replace)

graph export "$graf/RURAL_2005_2015_2025.png", replace width(5000)


//#### 2005 EDAD
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2005

gen lb_q_edad = beta_q_edad - 1.96*se_q_edad
gen hb_q_edad = beta_q_edad + 1.96*se_q_edad

twoway ///
    (rarea lb_q_edad hb_q_edad quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_edad quant, ///
        lcolor("255 69 0") mcolor("255 69 0") /// naranja
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_edad quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2005", size(huge)) ///
    ytitle("Cambio en el ln del salario por hora", size(huge)) ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(4) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/EDAD_2005.gph", replace


//#### 2015 EDAD
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2015

gen lb_q_edad = beta_q_edad - 1.96*se_q_edad
gen hb_q_edad = beta_q_edad + 1.96*se_q_edad

twoway ///
    (rarea lb_q_edad hb_q_edad quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_edad quant, ///
        lcolor("24 116 205") mcolor("24 116 205") /// azul
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_edad quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2015", size(huge)) ///
    ytitle("") ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(4) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/EDAD_2015.gph", replace


//#### 2025 EDAD
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2025

gen lb_q_edad = beta_q_edad - 1.96*se_q_edad
gen hb_q_edad = beta_q_edad + 1.96*se_q_edad

twoway ///
    (rarea lb_q_edad hb_q_edad quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_edad quant, ///
        lcolor("60 179 113") mcolor("60 179 113") /// verde pastel
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_edad quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2025", size(huge)) ///
    ytitle("") ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(4) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/EDAD_2025.gph", replace


//#### COMBINADA EDAD (2005, 2015, 2025)
graph combine "$graf/EDAD_2005.gph" "$graf/EDAD_2015.gph" "$graf/EDAD_2025.gph", ///
    col(3) graphregion(color(white)) ///
    ycommon xcommon imargin(0 0 0 0) ///
    ysize(5) xsize(20) ///
    name(Graf_EDAD_Conjunta, replace)

graph export "$graf/EDAD_2005_2015_2025.png", replace width(5000)

//#### 2005 EDAD²
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2005

gen lb_q_edad2 = beta_q_edad2 - 1.96*se_q_edad2
gen hb_q_edad2 = beta_q_edad2 + 1.96*se_q_edad2

twoway ///
    (rarea lb_q_edad2 hb_q_edad2 quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_edad2 quant, ///
        lcolor("255 69 0") mcolor("255 69 0") /// naranja
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_edad2 quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2005", size(huge)) ///
    ytitle("Cambio en el ln del salario por hora", size(huge)) ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(12) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/EDAD2_2005.gph", replace


//#### 2015 EDAD²
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2015

gen lb_q_edad2 = beta_q_edad2 - 1.96*se_q_edad2
gen hb_q_edad2 = beta_q_edad2 + 1.96*se_q_edad2

twoway ///
    (rarea lb_q_edad2 hb_q_edad2 quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_edad2 quant, ///
        lcolor("24 116 205") mcolor("24 116 205") /// azul
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_edad2 quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2015", size(huge)) ///
    ytitle("") ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(12) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/EDAD2_2015.gph", replace


//#### 2025 EDAD²
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2025

gen lb_q_edad2 = beta_q_edad2 - 1.96*se_q_edad2
gen hb_q_edad2 = beta_q_edad2 + 1.96*se_q_edad2

twoway ///
    (rarea lb_q_edad2 hb_q_edad2 quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_edad2 quant, ///
        lcolor("60 179 113") mcolor("60 179 113") /// verde pastel
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_edad2 quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2025", size(huge)) ///
    ytitle("") ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(12) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/EDAD2_2025.gph", replace


//#### COMBINADA EDAD² (2005, 2015, 2025)
graph combine "$graf/EDAD2_2005.gph" "$graf/EDAD2_2015.gph" "$graf/EDAD2_2025.gph", ///
    col(3) graphregion(color(white)) ///
    ycommon xcommon imargin(0 0 0 0) ///
    ysize(5) xsize(20) ///
    name(Graf_EDAD2_Conjunta, replace)

graph export "$graf/EDAD2_2005_2015_2025.png", replace width(5000)

//#### 2005 ESCOLARIDAD
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2005

gen lb_q_escol = beta_q_anios_esc - 1.96*se_q_anios_esc
gen hb_q_escol = beta_q_anios_esc + 1.96*se_q_anios_esc

twoway ///
    (rarea lb_q_escol hb_q_escol quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_anios_esc quant, ///
        lcolor("255 69 0") mcolor("255 69 0") /// naranja
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_anios_esc quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2005", size(huge)) ///
    ytitle("Cambio en el ln del salario por hora", size(huge)) ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(12) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/ESC_2005.gph", replace


//#### 2025 ESCOLARIDAD
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2025

gen lb_q_escol = beta_q_anios_esc - 1.96*se_q_anios_esc
gen hb_q_escol = beta_q_anios_esc + 1.96*se_q_anios_esc

twoway ///
    (rarea lb_q_escol hb_q_escol quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_anios_esc quant, ///
        lcolor("60 179 113") mcolor("60 179 113") /// verde pastel
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_anios_esc quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2025", size(huge)) ///
    ytitle("") ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(12) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/ESC_2025.gph", replace


//#### COMBINADA ESCOLARIDAD (2005 y 2025)
graph combine "$graf/ESC_2005.gph" "$graf/ESC_2025.gph", ///
    col(2) graphregion(color(white)) ///
    ycommon xcommon imargin(0 0 0 0) ///
    ysize(5) xsize(13) ///
    name(Graf_ESC_2005_2025, replace)

graph export "$graf/ESC_2005_2025.png", replace width(4000)

//#### 2015 ESCOLARIDAD
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2015

gen lb_q_escol = beta_q_anios_esc - 1.96*se_q_anios_esc
gen hb_q_escol = beta_q_anios_esc + 1.96*se_q_anios_esc

twoway ///
    (rarea lb_q_escol hb_q_escol quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_anios_esc quant, ///
        lcolor("24 116 205") mcolor("24 116 205") /// azul
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_anios_esc quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2015", size(huge)) ///
    ytitle("Cambio en el ln del salario por hora", size(huge)) ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(12) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/ESC_2015.gph", replace


//#### 2025 ESCOLARIDAD
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2025

gen lb_q_escol = beta_q_anios_esc - 1.96*se_q_anios_esc
gen hb_q_escol = beta_q_anios_esc + 1.96*se_q_anios_esc

twoway ///
    (rarea lb_q_escol hb_q_escol quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_anios_esc quant, ///
        lcolor("60 179 113") mcolor("60 179 113") /// verde pastel
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_anios_esc quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2025", size(huge)) ///
    ytitle("") ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(12) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/ESC_2025.gph", replace


//#### COMBINADA ESCOLARIDAD (2015 y 2025)
graph combine "$graf/ESC_2015.gph" "$graf/ESC_2025.gph", ///
    col(2) graphregion(color(white)) ///
    ycommon xcommon imargin(0 0 0 0) ///
    ysize(5) xsize(13) ///
    name(Graf_ESC_2015_2025, replace)

graph export "$graf/ESC_2015_2025.png", replace width(4000)

//#### 2015 FEMALE
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2015

gen lb_q_fem = beta_q_female - 1.96*se_q_female
gen hb_q_fem = beta_q_female + 1.96*se_q_female

twoway ///
    (rarea lb_q_fem hb_q_fem quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_female quant, ///
        lcolor("24 116 205") mcolor("24 116 205") /// azul
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_female quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2015", size(huge)) ///
    ytitle("Cambio en el ln del salario por hora", size(huge)) ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(10) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/FEM_2015.gph", replace


//#### 2025 FEMALE
use "$ENOE\REGRESION_CUANTIL_2005_2015_2025.dta", clear
keep if year==2025

gen lb_q_fem = beta_q_female - 1.96*se_q_female
gen hb_q_fem = beta_q_female + 1.96*se_q_female

twoway ///
    (rarea lb_q_fem hb_q_fem quant, color(gs8%35) lcolor(gs8)) ///
    (connected beta_q_female quant, ///
        lcolor("60 179 113") mcolor("60 179 113") /// verde pastel
        lwidth(medium) msize(0.5)) ///
    (connected beta_ols_female quant, ///
        lcolor(black) mcolor(black) ///
        lpattern(dash) msymbol(none) lwidth(medium)), ///
    xtitle("Cuantil 2025", size(huge)) ///
    ytitle("") ///
    xlabel(0(10)100, labsize(huge)) ///
    ylabel(, labsize(huge) angle(horizontal) grid) ///
    legend(order(2 "Quantile" 3 "OLS" 1 "CI 95% Quantile") ///
           position(10) ring(0) cols(3) size(huge)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph save "$graf/FEM_2025.gph", replace


//#### COMBINADA FEMALE (2015 y 2025)
graph combine "$graf/FEM_2015.gph" "$graf/FEM_2025.gph", ///
    col(2) graphregion(color(white)) ///
    ycommon xcommon imargin(0 0 0 0) ///
    ysize(5) xsize(13) ///
    name(Graf_FEM_2015_2025, replace)

graph export "$graf/FEM_2015_2025.png", replace width(4000)

//# 4 BOOTSTRAP

//##LIMPIEZA

//#### PASO 1: Preparar datos ENOE y guardar ajustada
clear
use "$ENOE\ENOE_AJUSTADA.dta", clear
keep if date == tq(2025q2)

// Edad y cuadrado
rename eda edad
gen edad2 = edad^2

// Rural (según t_loc)
gen rural = 0
replace rural = 1 if t_loc == 4

// Mujer
rename fem female
label variable female "Mujer (1=femenino)"

// Ingreso por hora real
gen linghrs = (ing_x_hrs/INPC)*100
label variable linghrs "Ingreso real por hora"

// Guardar base ajustada lista para bootstrap
save "$ENOE\ENOE_AJUSTADA_BOOT.dta", replace

//### A) BOOT 100

//Abrir base ajustada (ENOE_AJUSTADA_BOOT.dta)
clear
use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear

//##### PASO 1: Estimar MCO con errores estándar robustos
reg linghrs anios_esc edad edad2 rural female, robust

//#### PASO 2: Bootstrap no paramétrico con 100 repeticiones
use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear

bootstrap, seed(123) reps(100): ///
    reg linghrs anios_esc edad edad2 rural female, robust

*CAPTURAR MANUALMENTE COLUMNS SE Bootstrap

//#### PASO 3: Intervalo de confianza método Percentil
estat bootstrap, percentile

//#### PASO 4: Intervalos de confianza percentil-t (95%)
foreach v in anios_esc edad edad2 rural female _cons {
    
    * 1. Recargamos la base y corremos OLS robusto
    use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear
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


//### B) BOOT 1000

//Abrir base ajustada (ENOE_AJUSTADA_BOOT.dta)
clear
use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear

//#### PASO 1: Estimar MCO con errores estándar robustos
reg linghrs anios_esc edad edad2 rural female, robust

//#### PASO 2: Bootstrap no paramétrico con 100 repeticiones
use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear

bootstrap, seed(123) reps(1000): ///
    reg linghrs anios_esc edad edad2 rural female, robust

*CAPTURAR MANUALMENTE COLUMNS SE Bootstrap

//#### PASO 3: Intervalo de confianza método Percentil
estat bootstrap, percentile

//#### PASO 4: Intervalos de confianza percentil-t (95%)
foreach v in anios_esc edad edad2 rural female _cons {
    
    * 1. Recargamos la base y corremos OLS robusto
    use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear
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



//### C) BOOT 100 25%

//#### PASO 1: OLS robusto
use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear
reg linghrs anios_esc edad edad2 rural female, robust

//#### PASO 2: Bootstrap con 100 repeticiones y tamaño 0.25*N
use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear

bootstrap, seed(123) reps(100) size(28444): ///
    reg linghrs anios_esc edad edad2 rural female, robust

*CAPTURAR MANUALMENTE COLUMNAS SE Bootstrap

//#### PASO 3: Intervalo de confianza método Percentil
estat bootstrap, percentile

*CAPTURAR MANUALMENTE COLUMNAS IC

//#### PASO 4: Intervalos de confianza percentil-t (95%)
foreach v in anios_esc edad edad2 rural female _cons {
    
    * 1. Recargamos la base y corremos OLS robusto
    use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear
    reg linghrs anios_esc edad edad2 rural female, robust
    local b  = _b[`v']
    local se = _se[`v']

    * 2. Bootstrap de t-star con tamaño reducido
    bootstrap tstar=((_b[`v']-`b')/`se'), reps(100) seed(123) nodots size(28444) ///
        saving(bt_t, replace): reg linghrs anios_esc edad edad2 rural female, robust

    * 3. Abrimos resultados bootstrap y sacamos percentiles
    use bt_t, clear
    _pctile tstar, p(2.5,97.5)

    * 4. Mostramos intervalo percentil-t en pantalla
    di as text "Variable: `v'"
    di "IC 95% percentil-t (0.25N): [" %9.4f (`b' - r(r1)*`se') ", " %9.4f (`b' + r(r2)*`se') "]"
    di "----------------------------------------------------"
}


//### D) BOOT 1000 25%

//#### PASO 1: OLS robusto
use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear
reg linghrs anios_esc edad edad2 rural female, robust

//#### PASO 2: Bootstrap con 100 repeticiones y tamaño 0.25*N
use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear

bootstrap, seed(123) reps(1000) size(28444): ///
    reg linghrs anios_esc edad edad2 rural female, robust

*CAPTURAR MANUALMENTE COLUMNAS SE Bootstrap

//#### PASO 3: Intervalo de confianza método Percentil
estat bootstrap, percentile

*CAPTURAR MANUALMENTE COLUMNAS IC

//#### PASO 4: Intervalos de confianza percentil-t (95%)
foreach v in anios_esc edad edad2 rural female _cons {
    
    * 1. Recargamos la base y corremos OLS robusto
    use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear
    reg linghrs anios_esc edad edad2 rural female, robust
    local b  = _b[`v']
    local se = _se[`v']

    * 2. Bootstrap de t-star con tamaño reducido
    bootstrap tstar=((_b[`v']-`b')/`se'), reps(1000) seed(123) nodots size(28444) ///
        saving(bt_t, replace): reg linghrs anios_esc edad edad2 rural female, robust

    * 3. Abrimos resultados bootstrap y sacamos percentiles
    use bt_t, clear
    _pctile tstar, p(2.5,97.5)

    * 4. Mostramos intervalo percentil-t en pantalla
    di as text "Variable: `v'"
    di "IC 95% percentil-t (0.25N): [" %9.4f (`b' - r(r1)*`se') ", " %9.4f (`b' + r(r2)*`se') "]"
    di "----------------------------------------------------"
}


//### A) BSAMPLE 100

//#### PASO 1 
clear
use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear
save "$ENOE\temporalsample.dta", replace

forval q=1/100 {
    quietly use "$ENOE\temporalsample.dta", clear
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
        save "$ENOE\BOOSTRAP_MANUAL_100.dta", replace
    }
    else {
        append using "$ENOE\BOOSTRAP_MANUAL_100.dta"
        save "$ENOE\BOOSTRAP_MANUAL_100.dta", replace
    }
}

//#### PASO 2

// Abrir la base de resultados bootstrap manual
use "$ENOE\BOOSTRAP_MANUAL_100.dta", clear

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
use "$ENOE\BOOSTRAP_MANUAL_100.dta", clear

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
use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear
reg linghrs anios_esc edad edad2 rural female, robust

// Guardar coeficientes y errores estándar originales
foreach v in anios_esc edad edad2 rural female _cons {
    local b0_`v'  = _b[`v']
    local se0_`v' = _se[`v']
}

// 2. Abrir base de resultados bootstrap manual
use "$ENOE\BOOSTRAP_MANUAL_100.dta", clear

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

//### B) BSAMPLE 1000

//#### PASO 1 
clear
use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear
save "$ENOE\temporalsample.dta", replace

forval q=1/1000 {
    quietly use "$ENOE\temporalsample.dta", clear
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
        save "$ENOE\BOOSTRAP_MANUAL_1000.dta", replace
    }
    else {
        append using "$ENOE\BOOSTRAP_MANUAL_1000.dta"
        save "$ENOE\BOOSTRAP_MANUAL_1000.dta", replace
    }
}

//#### PASO 2

// Abrir la base de resultados bootstrap manual
use "$ENOE\BOOSTRAP_MANUAL_1000.dta", clear

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
use "$ENOE\BOOSTRAP_MANUAL_1000.dta", clear

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
use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear
reg linghrs anios_esc edad edad2 rural female, robust

// Guardar coeficientes y errores estándar originales
foreach v in anios_esc edad edad2 rural female _cons {
    local b0_`v'  = _b[`v']
    local se0_`v' = _se[`v']
}

// 2. Abrir base de resultados bootstrap manual
use "$ENOE\BOOSTRAP_MANUAL_1000.dta", clear

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
use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear
save "$ENOE\temporalsample.dta", replace

forval q=1/100 {
    quietly use "$ENOE\temporalsample.dta", clear
    quietly bsample 28444   // <-- solo 25% de la muestra
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
        save "$ENOE\BOOSTRAP_MANUAL_100_25N.dta", replace
    }
    else {
        append using "$ENOE\BOOSTRAP_MANUAL_100_25N.dta"
        save "$ENOE\BOOSTRAP_MANUAL_100_25N.dta", replace
    }
}

//#### PASO 2

// Abrir la base de resultados bootstrap manual
use "$ENOE\BOOSTRAP_MANUAL_100_25N.dta", clear

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
use "$ENOE\BOOSTRAP_MANUAL_100_25N.dta", clear

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
use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear
reg linghrs anios_esc edad edad2 rural female, robust

// Guardar coeficientes y errores estándar originales
foreach v in anios_esc edad edad2 rural female _cons {
    local b0_`v'  = _b[`v']
    local se0_`v' = _se[`v']
}

// 2. Abrir base de resultados bootstrap manual
use "$ENOE\BOOSTRAP_MANUAL_100_25N.dta", clear

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
use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear
save "$ENOE\temporalsample.dta", replace

forval q=1/1000 {
    quietly use "$ENOE\temporalsample.dta", clear
    quietly bsample 28444   // <-- solo 25% de la muestra
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
        save "$ENOE\BOOSTRAP_MANUAL_1000_25N.dta", replace
    }
    else {
        append using "$ENOE\BOOSTRAP_MANUAL_1000_25N.dta"
        save "$ENOE\BOOSTRAP_MANUAL_1000_25N.dta", replace
    }
}

//#### PASO 2

// Abrir la base de resultados bootstrap manual
use "$ENOE\BOOSTRAP_MANUAL_1000_25N.dta", clear

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
use "$ENOE\BOOSTRAP_MANUAL_1000_25N.dta", clear

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
use "$ENOE\ENOE_AJUSTADA_BOOT.dta", clear
reg linghrs anios_esc edad edad2 rural female, robust

// Guardar coeficientes y errores estándar originales
foreach v in anios_esc edad edad2 rural female _cons {
    local b0_`v'  = _b[`v']
    local se0_`v' = _se[`v']
}

// 2. Abrir base de resultados bootstrap manual
use "$ENOE\BOOSTRAP_MANUAL_1000_25N.dta", clear

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


//# 5 NON PARAMETRICS

//## LIMPIEZA

//### PASO 1: CARGA Y LIMPIEZA -----------------------------------
use "$ENOE\Base_ENOE_SDEM_2005_2025.dta", clear   // carga base ENOE

destring year q fac, replace                     // asegura numéricos
rename fac factor                                // renombra factor
gen fac = factor*hrsocup                         // nuevo factor ponderado

//### PASO 2: FILTRO TEMPORAL ------------------------------------


// Mantener Q1 solo en 2020, y Q2 para todos los demás años
keep if (year == 2020 & q == 1) | (year != 2020 & q == 2)

//### PASO 3: VARIABLES BÁSICAS ----------------------------------
replace anios_esc = . if anios_esc == 99         // limpia escolaridad
gen fem = sex - 1                                // 0=Hombre 1=Mujer

//### PASO 4: INGRESOS LIMPIOS ----------------------------------
replace ingocup   = . if ingocup   == 999999 | ingocup   == 0   // missing
replace ing_x_hrs = . if ing_x_hrs == 999999 | ing_x_hrs == 0

//### PASO 5: FILTRO TRABAJADOR VÁLIDO ---------------------------
gen trabajadorv = 0
replace trabajadorv = 1 if ingocup != . & ing_x_hrs != . & ingocup > 0 & ing_x_hrs > 0
drop if trabajadorv == 0

//### PASO 6: INGRESOS REALES ------------------------------------
gen ing = (ing_x_hrs/INPC)*100                  // ingreso real por hora
replace ing = 1     if ing <= 1   & ing != .    // censura inferior
replace ing = 5000  if ing >= 5000 & ing != .   // censura superior

//### PASO 7: LOGARITMO DE INGRESOS -------------------------------
gen ling = ln(ing)                               // ln ingreso hora
drop if ling == .                                // limpia missing

rename eda edad 
gen rural = 0 
replace rural = 1 if t_loc==4 
gen w = hrsocup * fac

//### PASO 8: GUARDAR BASE ---------------------------------------
save "$ENOE\ENOE_AJUSTADA_DENSITY.dta", replace


//==========================================================
//## 5.2  KDENSITY SALARIO ENOE
//==========================================================

use "$ENOE\ENOE_AJUSTADA_DENSITY.dta", clear

//### PASO 2

* Loop en todos los años de 2005 a 2025 (trimestre II ya filtrado)
local years 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025

foreach A of local years {
    quietly sum ing if year==`A' [aw=w], detail
    
    * Bandwidth: regla de Silverman + ajuste
    local bw = min(r(sd), ((r(p75)-r(p25))/1.349)) * (r(N)^(-1/5)) * 1.3643 * 1.7188
    local bw = round(`bw',0.01)   // redondear a 2 decimales
    
    * Grid de 0–300 (paso 1) para evaluar la densidad
    range xgrid 0 300 301
    tempvar d
    quietly kdensity ing if year==`A' [aw=w], ///
        kernel(epan2) bwidth(`bw') at(xgrid) ///
        generate(`d')

    local nota "BW=`bw'"
    twoway (area `d' xgrid, fcolor("144 238 144%50") lcolor("144 238 144") lwidth(medthick)), ///
        ytitle("Density") xtitle("Ingreso por hora") ///
        title("`A'", pos(12) ring(0)) ///
        ylabel(0(.01).03, labsize(medium)) ///
        yscale(range(0 .03)) ///
        xlabel(0(100)300, labsize(medium)) ///
        xscale(range(0 300)) ///
        note("`nota'") ///
        name(G`A', replace)

    drop xgrid `d'
}

//==========================================================
//### PASO 3: COMBINA GRAFICAS DE 2005 A 2013
//==========================================================

// Combinar primeros 9 años en un grid 3x3
graph combine G2005 G2006 G2007 G2008 G2009 G2010 G2011 G2012 G2013, ///
    cols(3) rows(3) ycommon xcommon ///
    xsize(12) ysize(13) imargin(small) ///
    name(KDENS_ENOE_ING_pt1, replace)

// Exportar al global $graf en dos formatos
graph export "$graf\KDENS_ENOE_ING_pt1.png", replace width(3000)
graph export "$graf\KDENS_ENOE_ING_pt1.emf", replace


//==========================================================
//### PASO 4 COMBINA GRAFICAS DE 2014 A 2022
//==========================================================

// Combinar en un grid 3x3
graph combine G2014 G2015 G2016 G2017 G2018 G2019 G2020 G2021 G2022, ///
    cols(3) rows(2) ycommon xcommon ///
    xsize(12) ysize(13) imargin(small) ///
    name(KDENS_ENOE_ING_pt2, replace)

// Exportar al global $graf en dos formatos
graph export "$graf\KDENS_ENOE_ING_pt2.png", replace width(3000)
graph export "$graf\KDENS_ENOE_ING_pt2.emf", replace

//==========================================================
//### PASO 5 COMBINA GRAFICAS DE 2023 A 2025
//==========================================================

// Combinar en un grid 3x3
graph combine G2023 G2024 G2025 G2017 G2018 G2019 G2020 G2021 G2022, ///
    cols(3) rows(2) ycommon xcommon ///
    xsize(12) ysize(13) imargin(small) ///
    name(KDENS_ENOE_ING_pt3, replace)

// Exportar al global $graf en dos formatos
graph export "$graf\KDENS_ENOE_ING_pt3.png", replace width(3000)
graph export "$graf\KDENS_ENOE_ING_pt3.emf", replace

//==========================================================
//## 5.2.1  KDENSITY LOG SALARIO (2005–2025)
//==========================================================

local years 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025

foreach A of local years {
    quietly sum ling if year==`A' [aw=w], detail
    // Bandwidth sin redondear + piso para evitar que sea 0
    local bw_raw = min(r(sd), ((r(p75)-r(p25))/1.349)) * (r(N)^(-1/5)) * 1.3643 * 1.7188
    local bw     = max(0.02, `bw_raw')   // BW mínimo = 0.02

    // grid 0–8 (log salario en rango razonable)
    range xgrid 0 8 501
    tempvar d
    quietly kdensity ling if year==`A' [aw=w], ///
        kernel(epan2) bwidth(`bw') at(xgrid) ///
        generate(`d')

    // Nota con BW en 2 decimales
    local nota : display "BW: " %4.2f `bw'

    twoway (area `d' xgrid, fcolor("228 0 70%50") lcolor("228 0 70") lwidth(medthick)), ///
        ytitle("Density") xtitle("Log Ingreso por Hora") ///
        title("`A'", pos(12) ring(0)) ///
        ylabel(0(.2).8, labsize(medium)) yscale(range(0 .8)) ///
        xlabel(0(2)8, labsize(medium))  xscale(range(0 8)) ///
        note("`nota'") ///
        name(GL`A', replace)

    drop xgrid `d'
}

//==========================================================
//### PASO 1 COMBINA GRAFICAS DE 2005 A 2013
//==========================================================

graph combine GL2005 GL2006 GL2007 GL2008 GL2009 GL2010 GL2011 GL2012 GL2013, ///
    cols(3) rows(3) ycommon xcommon ///
    xsize(10) ysize(12) imargin(small) ///
    name(KDENS_LOG_pt1, replace)

graph export "$graf\KDENS_ENOE_LOG_pt1.png", replace width(3000)
graph export "$graf\KDENS_ENOE_LOG_pt1.emf", replace

//==========================================================
//### PASO 2 COMBINA GRAFICAS DE 2014 A 2022
//==========================================================

graph combine GL2014 GL2015 GL2016 GL2017 GL2018 GL2019 GL2020 GL2021 GL2022, ///
    cols(3) rows(3) ycommon xcommon ///
    xsize(10) ysize(12) imargin(small) ///
    name(KDENS_ENOE_LOG_pt2, replace)

graph export "$graf\KDENS_ENOE_LOG_pt2.png", replace width(3000)
graph export "$graf\KDENS_ENOE_LOG_pt2.emf", replace

//==========================================================
//### PASO 3 COMBINA GRAFICAS DE 2023 A 2025
//==========================================================

graph combine GL2023 GL2024 GL2025 GL2017 GL2018 GL2019 GL2020 GL2021 GL2022, ///
    cols(3) rows(3) ycommon xcommon ///
    xsize(10) ysize(12) imargin(small) ///
    name(KDENS_ENOE_LOG_pt3, replace)

graph export "$graf\KDENS_ENOE_LOG_pt3.png", replace width(3000)
graph export "$graf\KDENS_ENOE_LOG_pt3.emf", replace


//==========================================================
//## 5.3 Bandwidth y Kernels en kdensity (ejemplo: año 2025)
//   ENOE (Trimestre II, 2005–2025; 2020 = T-I)
//==========================================================

use "$ENOE\ENOE_AJUSTADA_DENSITY.dta", clear


// Fijamos año de análisis
local A 2025

// Calcular estadísticos básicos
quietly sum ling if year==`A' [aw=w], detail
local bw0 = min(r(sd), ((r(p75)-r(p25))/1.349)) * (r(N)^(-1/5)) * 1.3643 * 1.7188
local bw0 = round(`bw0', .01)   // Bandwidth "óptimo"
local bw_low = `bw0'/4          // Bandwidth pequeño
local bw_high = `bw0'*4         // Bandwidth grande

//===========================
// (1) Comparar Bandwidth
//===========================
range xgrid 0 8 501
tempvar d1 d2 d3

kdensity ling if year==`A' [aw=w], kernel(epan2) bwidth(`bw_low')  at(xgrid) generate(`d1')
kdensity ling if year==`A' [aw=w], kernel(epan2) bwidth(`bw0')    at(xgrid) generate(`d2')
kdensity ling if year==`A' [aw=w], kernel(epan2) bwidth(`bw_high') at(xgrid) generate(`d3')

twoway (line `d1' xgrid, lcolor("255 69 0%20") lwidth(medthick) lpattern(solid)) ///
       (line `d2' xgrid, lcolor("255 69 0") lwidth(medthick)) ///
       (line `d3' xgrid, lcolor("pink") lwidth(medthick) lpattern(dash)), ///
       ytitle("Density") xtitle("Log Ingreso por Hora") ///
       legend(order(1 "BW bajo" 2 "BW óptimo" 3 "BW alto") ring(0) pos(1)) ///
       name(CAMBIO_BW, replace)

// Exportar
graph export "$graf\CAMBIO_ENOE_BW.png", replace width(3000)
graph export "$graf\CAMBIO_ENOE_BW.emf", replace

drop xgrid `d1' `d2' `d3'


//===========================
//###(2) Comparar Kernels
//   ENOE (ejemplo: año 2025)
//===========================
range xgrid 0 8 501
tempvar k1 k2

kdensity ling if year==`A' [aw=w], kernel(epan2)    bwidth(`bw0') at(xgrid) generate(`k1')
kdensity ling if year==`A' [aw=w], kernel(gaussian) bwidth(`bw0') at(xgrid) generate(`k2')

twoway (line `k1' xgrid, lcolor("255 69 0%20") lwidth(medthick)) ///
       (line `k2' xgrid, lcolor("255 69 0") lwidth(medthick) lpattern(dash)), ///
       ytitle("Density") xtitle("Log Ingreso por Hora") ///
       legend(order(1 "Epanechnikov" 2 "Gaussiano") ring(0) pos(1)) ///
       name(CAMBIO_KERNEL, replace)

// Exportar
graph export "$graf\CAMBIO_ENOE_KERNEL.png", replace width(3000)
graph export "$graf\CAMBIO_ENOE_KERNEL.emf", replace

drop xgrid `k1' `k2'

//==========================================================
//## 5.4 b) 2018
//   ENOE (Trimestre II, 2005–2025; 2020 = T-I)
//==========================================================
use "$ENOE\ENOE_AJUSTADA_DENSITY.dta", clear

* Restringir a población entre 25 y 65 años
keep if edad >= 25 & edad <= 65

//=============================
//### LPOLY HOMBRES 2018 - Edad 
//=============================
local A 2018

twoway ///
    (scatter ling edad if (year == `A' & fem == 0), ///
        mcolor("135 206 250%10") msymbol(O)) ///   // azul claro con transparencia
    (lpoly ling edad if (year == `A' & fem == 0) [aweight = w], ///
        kernel(gaussian) bwidth(0.8) ///
        lcolor("228 0 70") lwidth(medthick)) ///   // verde tipo "spring green"
    (lowess ling edad if (year == `A' & fem == 0), ///
        lcolor("black") lwidth(medium) lpattern(solid)), ///   // línea negra de comparación
    legend(cols(3) position(2) ring(0)) ///
    legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
    yline(0, lcolor(gs12) lpattern(dash)) ///
    xscale(range(25 65)) xlabel(25(10)65) ///
    ytitle("Log salario por hora") ///
    xtitle("Edad") ///
    name(LPOLY_ENOE_HOMBRES, replace)

// Exportar
graph export "$graf\LPOLY_ENOE_HOMBRES.png", replace width(3000)
graph export "$graf\LPOLY_ENOE_HOMBRES.emf", replace


//=============================
//### LPOLY MUJERES ENOE 2018 - Edad 
//=============================
local A 2018

twoway ///
    (scatter ling edad if (year == `A' & sex == 1), ///
        mcolor("255 192 203%20") msymbol(O)) ///   // rosa pastel con transparencia
    (lpoly ling edad if (year == `A' & sex == 1) [aweight = w], ///
        kernel(gaussian) bwidth(0.8) ///
        lcolor("0 255 127") lwidth(medthick)) ///   // rosa mexicano para consistencia
    (lowess ling edad if (year == `A' & sex == 1), ///
        lcolor("black") lwidth(medium) lpattern(solid)), ///
    legend(cols(3) position(2) ring(0)) ///
    legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
    yline(0, lcolor(gs12) lpattern(dash)) ///
    xscale(range(25 65)) xlabel(25(10)65) ///
    ytitle("Log salario por hora") ///
    xtitle("Edad") ///
    name(LPOLY_ENOE_MUJERES, replace)

// Exportar
graph export "$graf\LPOLY_ENOE_MUJERES.png", replace width(3000)
graph export "$graf\LPOLY_ENOE_MUJERES.emf", replace

//=============================
//### LPOLY HOMBRES 2018 - Escolaridad 
//=============================
local A 2018

twoway ///
    (scatter ling anios_esc if (year == `A' & sex == 1), ///
        mcolor("135 206 250%40") msymbol(O)) ///   // azul claro con transparencia
    (lpoly ling anios_esc if (year == `A' & sex == 1) [aweight = w], ///
        kernel(gaussian) bwidth(0.8) ///
        lcolor("0 255 127") lwidth(medthick)) ///   // verde fosforescente metálico
    (lowess ling anios_esc if (year == `A' & sex == 1), ///
        lcolor("black") lwidth(medthick) lpattern(dot)), ///   // lowess en negro punteado
    legend(cols(3) position(2) ring(0)) ///
    legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
    yline(0, lcolor(gs12) lpattern(dash)) ///
    xscale(range(0 22)) xlabel(0(4)22) ///
    ytitle("Log salario por hora") ///
    xtitle("Años de escolaridad") ///
    name(LPOLY_ENOE_HOMBRES_ESC, replace)

// Exportar
graph export "$graf\LPOLY_ENOE_HOMBRES_ESC.png", replace width(3000)
graph export "$graf\LPOLY_ENOE_HOMBRES_ESC.emf", replace


//=============================
//### LPOLY MUJERES 2018 - Escolaridad 
//=============================
local A 2018

twoway ///
    (scatter ling anios_esc if (year == `A' & fem == 1), ///
        mcolor("255 192 203%10") msymbol(O)) ///   // rosa claro con transparencia
    (lpoly ling anios_esc if (year == `A' & fem == 1) [aweight = w], ///
        kernel(gaussian) bwidth(0.8) ///
        lcolor("0 255 127") lwidth(medthick)) ///   // verde fosforescente metálico
    (lowess ling anios_esc if (year == `A' & fem == 1), ///
        lcolor("black") lwidth(medthick) lpattern(dot)), ///   // lowess en negro punteado
    legend(cols(3) position(2) ring(0)) ///
    legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
    yline(0, lcolor(gs12) lpattern(dash)) ///
    xscale(range(0 22)) xlabel(0(4)22) ///
    ytitle("Log salario por hora") ///
    xtitle("Años de escolaridad") ///
    name(LPOLY_ENOE_MUJERES_ESC, replace)

// Exportar
graph export "$graf\LPOLY_ENOE_MUJERES_ESC.png", replace width(3000)
graph export "$graf\LPOLY_ENOE_MUJERES_ESC.emf", replace

//==========================================================
//## 5.4 c) 2024
//==========================================================

//=============================
//### LPOLY HOMBRES 2024 - Edad 
//=============================
local A 2024

twoway ///
    (scatter ling edad if (year == `A' & fem == 0 & inrange(edad,25,65)), ///
        mcolor("135 206 250%2") msymbol(O)) ///   // azul claro con transparencia
    (lpoly ling edad if (year == `A' & fem == 0 & inrange(edad,25,65)) [aweight = w], ///
        kernel(gaussian) bwidth(0.8) ///
        lcolor("0 255 127") lwidth(medthick)) ///   // verde fosforescente
    (lowess ling edad if (year == `A' & fem == 0 & inrange(edad,25,65)), ///
        lcolor("black") lwidth(medium) lpattern(solid)), ///   // negro línea sólida
    legend(cols(3) position(2) ring(0)) ///
    legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
    yline(0, lcolor(gs12) lpattern(dash)) ///
    xscale(range(25 65)) xlabel(25(10)65) ///
    ytitle("Log salario por hora") ///
    xtitle("Edad") ///
    name(LPOLY_ENOE_HOMBRES_2024, replace)

// Exportar
graph export "$graf\LPOLY_ENOE_HOMBRES_2024.png", replace width(3000)
graph export "$graf\LPOLY_ENOE_HOMBRES_2024.emf", replace

//=============================
//### LPOLY MUJERES 2024 - Edad 
//=============================
local A 2024

twoway ///
    (scatter ling edad if (year == `A' & fem == 1 & inrange(edad,25,65)), ///
        mcolor("255 192 203%2") msymbol(O)) ///   // rosa claro con transparencia
    (lpoly ling edad if (year == `A' & fem == 1 & inrange(edad,25,65)) [aweight = w], ///
        kernel(gaussian) bwidth(0.8) ///
        lcolor("0 255 127") lwidth(medthick)) ///   // verde fosforescente
    (lowess ling edad if (year == `A' & fem == 1 & inrange(edad,25,65)), ///
        lcolor("black") lwidth(medium) lpattern(solid)), ///   // negro sólido
    legend(cols(3) position(2) ring(0)) ///
    legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
    yline(0, lcolor(gs12) lpattern(dash)) ///
    xscale(range(25 65)) xlabel(25(10)65) ///
    ytitle("Log salario por hora") ///
    xtitle("Edad") ///
    name(LPOLY_ENOE_MUJERES_2024, replace)

// Exportar
graph export "$graf\LPOLY_ENOE_MUJERES_2024.png", replace width(3000)
graph export "$graf\LPOLY_ENOE_MUJERES_2024.emf", replace

//=============================
//### LPOLY HOMBRES 2024 - Escolaridad 
//=============================
local A 2024

twoway ///
    (scatter ling anios_esc if (year == `A' & fem == 0), ///
        mcolor("135 206 250%40") msymbol(O)) ///   // azul claro con transparencia
    (lpoly ling anios_esc if (year == `A' & fem == 0) [aweight = w], ///
        kernel(gaussian) bwidth(0.8) ///
        lcolor("0 255 127") lwidth(medthick)) ///   // verde fosforescente metálico
    (lowess ling anios_esc if (year == `A' & fem == 0), ///
        lcolor("black") lwidth(medthick) lpattern(dot)), ///   // lowess negro punteado
    legend(cols(3) position(2) ring(0)) ///
    legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
    yline(0, lcolor(gs12) lpattern(dash)) ///
    xscale(range(0 22)) xlabel(0(4)22) ///
    ytitle("Log salario por hora") ///
    xtitle("Años de escolaridad") ///
    name(LPOLY_ENOE_HOMBRES_ESC_2024, replace)

// Exportar
graph export "$graf\LPOLY_ENOE_HOMBRES_ESC_2024.png", replace width(3000)
graph export "$graf\LPOLY_ENOE_HOMBRES_ESC_2024.emf", replace

//=============================
//### LPOLY MUJERES 2024 - Escolaridad 
//=============================
local A 2024

twoway ///
    (scatter ling anios_esc if (year == `A' & fem == 1), ///
        mcolor("255 192 203%20") msymbol(O)) ///   // rosa claro con transparencia
    (lpoly ling anios_esc if (year == `A' & fem == 1) [aweight = w], ///
        kernel(gaussian) bwidth(0.8) ///
        lcolor("0 255 127") lwidth(medthick)) ///   // verde fosforescente metálico
    (lowess ling anios_esc if (year == `A' & fem == 1), ///
        lcolor("black") lwidth(medthick) lpattern(dot)), ///   // lowess negro punteado
    legend(cols(3) position(2) ring(0)) ///
    legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
    yline(0, lcolor(gs12) lpattern(dash)) ///
    xscale(range(0 22)) xlabel(0(4)22) ///
    ytitle("Log salario por hora") ///
    xtitle("Años de escolaridad") ///
    name(LPOLY_ENOE_MUJERES_ESC_2024, replace)

// Exportar
graph export "$graf\LPOLY_ENOE_MUJERES_ESC_2024.png", replace width(3000)
graph export "$graf\LPOLY_ENOE_MUJERES_ESC_2024.emf", replace

//==========================================================
//## 5.4 e) ii) ENOE
//==========================================================

//### 2018

preserve
    keep if year==2018
    
    // Regress log salario en sexo, ruralidad y escolaridad
    reg ling fem rural anios_esc [aw=w]
    predict res_wage18, resid
    
    // Regress edad en sexo, ruralidad y escolaridad
    reg edad fem rural anios_esc [aw=w]
    predict res_edad18, resid
    
    // Gráfico de residuales
    twoway ///
        (scatter res_wage18 res_edad18, mcolor("135 206 250%10") msymbol(O)) ///
        (lpoly res_wage18 res_edad18 [aw=w], kernel(gaussian) bwidth(0.8) lcolor("228 0 70") lwidth(medthick)) ///
        (lowess res_wage18 res_edad18, lcolor("black") lwidth(medium) lpattern(dot)), ///
        legend(cols(3) position(2) ring(0)) ///
        legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
        yline(0, lcolor(gs12) lpattern(dash)) ///
        xtitle("Edad (residualizada)") ///
        ytitle("Log salario por hora (residualizado)") ///
        name(RESID_ENOE_2018, replace)
    
    // Exportar
    graph export "$graf\RESID_ENOE_2018.png", replace width(3000)
    graph export "$graf\RESID_ENOE_2018.emf", replace
restore

//==========================================================
//## 5.4 e) ii) ENOE - 2022
//==========================================================

preserve
    keep if year==2022
    
    // Regress log salario en sexo, ruralidad y escolaridad
    reg ling fem rural anios_esc [aw=w]
    predict res_wage22, resid
    
    // Regress edad en sexo, ruralidad y escolaridad
    reg edad fem rural anios_esc [aw=w]
    predict res_edad22, resid
    
    // Gráfico de residuales
    twoway ///
        (scatter res_wage22 res_edad22, mcolor("135 206 250%10") msymbol(O)) ///
        (lpoly res_wage22 res_edad22 [aw=w], kernel(gaussian) bwidth(0.8) lcolor("228 0 70") lwidth(medthick)) ///
        (lowess res_wage22 res_edad22, lcolor("black") lwidth(medium) lpattern(dot)), ///
        legend(cols(3) position(2) ring(0)) ///
        legend(order(1 "" 2 "Lpoly (gaussiano)" 3 "Lowess")) ///
        yline(0, lcolor(gs12) lpattern(dash)) ///
        xtitle("Edad (residualizada)") ///
        ytitle("Log salario por hora (residualizado)") ///
        name(RESID_ENOE_2022, replace)
    
    // Exportar
    graph export "$graf\RESID_ENOE_2022.png", replace width(3000)
    graph export "$graf\RESID_ENOE_2022.emf", replace
restore


//==========================================================
//## 5.4 e) iii) ENOE - 2018
//==========================================================

//=============================
//#### plreg 2018
//=============================

net from http://www.stata-journal.com/software/sj6-3
net install st0109

preserve
    keep if year==2018

    * Estimar PLR y guardar la parte no paramétrica de edad
    plreg ling fem rural anios_esc, nlf(edad) generate(g_edad)

    * Ordenar por edad antes de graficar (clave para evitar "abanico")
    sort edad

    * Graficar curva no paramétrica
    twoway line g_edad edad, sort ///
        xscale(range(25 65)) xlabel(25(10)65) ///
        ytitle("Log salario por hora") xtitle("Edad") ///
        lcolor("228 0 70") lwidth(medthick) ///
        name(PLREG_ENOE_2018, replace)

    graph export "$graf\PLREG_ENOE_2018.png", replace width(3000)
    graph export "$graf\PLREG_ENOE_2018.emf", replace
restore

//=============================
//#### plreg 2022 ENOE
//=============================

preserve
    keep if year==2022

    * Estimar PLR y guardar la parte no paramétrica de edad
    plreg ling fem rural anios_esc, nlf(edad) generate(g_edad)

    * Ordenar por edad antes de graficar (clave para evitar "abanico")
    sort edad

    * Graficar curva no paramétrica
    twoway line g_edad edad, sort ///
        xscale(range(25 65)) xlabel(25(10)65) ///
        ytitle("Log salario por hora") xtitle("Edad") ///
        lcolor("228 0 70") lwidth(medthick) ///
        name(PLREG_ENOE_2022, replace)

    graph export "$graf\PLREG_ENOE_2022.png", replace width(3000)
    graph export "$graf\PLREG_ENOE_2022.emf", replace
restore





//# 6 IMPUTACION 





//### LIMPIEZA

use "$ENOE\Base_ENOE_SDEM_2005_2025.dta", clear   // carga base ENOE

//#### PASO 1: FILTRAR ENCUESTAS VÁLIDAS ---------------------------
// Criterios INEGI: solo encuestas válidas y residentes en vivienda
keep if r_def==0 & (c_res==1 | c_res==3)  

//#### PASO 2: CREAR VARIABLE DE EDUCACIÓN -------------------------
// Se recodifica nivel educativo en categorías resumidas
gen educacion = .

replace educacion = 0 if cs_p13_1 == 00   // Sin instrucción
replace educacion = 0 if cs_p13_1 == 01   // Sin instrucción
replace educacion = 1 if cs_p13_1 == 2    // Primaria
replace educacion = 2 if cs_p13_1 == 3    // Secundaria
replace educacion = 3 if cs_p13_1 == 4    // Media Superior
replace educacion = 3 if cs_p13_1 == 5    // Media Superior
replace educacion = 3 if cs_p13_1 == 6    // Media Superior
replace educacion = 4 if cs_p13_1 == 7    // Superior
replace educacion = 5 if cs_p13_1 == 8    // Posgrado
replace educacion = 5 if cs_p13_1 == 9    // Posgrado

//#### PASO 3: ETIQUETAR VARIABLE ----------------------------------
label define educn 0 "Sin instrucción" ///
                  1 "Primaria" ///
                  2 "Secundaria" ///
                  3 "Media Superior" ///
                  4 "Superior" ///
                  5 "Posgrado"

label values educacion educn
label variable educacion "Nivel educativo"

//#### PASO 4: CREAR VARIABLE RURALIDAD ----------------------------
// Se clasifica la localidad en urbana (0) o rural (1)
gen rural = 0
replace rural = 1 if t_loc == 4
replace rural = . if t_loc == .

label define etirur 0 "Urbano" 1 "Rural"
label values rural etirur
label variable rural "Tipo de localidad"

//#### PASO 5: CREAR VARIABLE FORMALIDAD ---------------------------
// Se define condición de formalidad según acceso a salud en el trabajo
gen formal = .
replace formal = 1 if imssissste == 1 | imssissste == 2 | imssissste == 3   // Formal
replace formal = 2 if imssissste == 4                                      // Informal

//#### PASO 6: FILTRAR POBLACIÓN OBJETIVO --------------------------
// Se eliminan observaciones fuera de la población de interés
keep if eda >= 14                           // Personas de 14 años o más
keep if clase2 == 1                         // Sólo ocupados
keep if hrsocup > 0 & hrsocup < 199         // Horas trabajadas en rango válido
drop if pos_ocu==4 | pos_ocu==5 | pos_ocu==. | ing7c==6   // Excluir pos. ocupacional e ingresos no válidos

//#### PASO 7: FORMATO DE FECHA ------------------------------------
format date %tq                             // Se formatea la variable de fecha en trimestres

//#### PASO 8: INGRESOS INVÁLIDOS ---------------------------------
// Se genera indicador de ingreso inválido y se limpian los ingresos
replace ingocup = . if ingocup == 999998 | ingocup == 0   // Ingresos no válidos → missing
gen invalido = 0
replace invalido = 1 if ingocup == .                     // Marca ingresos inválidos

//### 6.2 GRAF: Porcentaje de trabajos con ingresos inválidos ---------

preserve

//#### PASO 1: Eliminar casos sin información
drop if ing7c == .

//#### PASO 2: Calcular proporción de trabajos con ingresos inválidos
collapse (mean) invalido [iw=fac], by(date)

//#### PASO 3: Definir serie temporal trimestral
tsset date, quarterly

//#### PASO 4: Convertir a porcentaje
replace invalido = invalido * 100

//#### PASO 5: Etiquetar variable
label variable invalido "Trabajos con ingresos inválidos"

//#### PASO 6: Graficar con estilo moderno
twoway ///
    (connected invalido date, lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(vthin) msize(0.4)), ///   // Serie en naranja metálico
	ylabel(0(5)40, labsize(medium)) ///
    xtitle("Trimestre", size(medium)) ///
    ytitle("Porcentaje", size(medium)) ///
    legend(off) ///
    graphregion(color(white)) plotregion(lstyle(none))

//#### PASO 7: Exportar gráfica
graph export "$graf\\ENOE_6.png", replace

restore

//### 6.2.1 GRAF: Porcentaje de ingresos inválidos por formalidad ---------

preserve

//#### PASO 1: Eliminar casos sin información
drop if ing7c == .
drop if formal == .

//#### PASO 2: Calcular proporción por formalidad
collapse (mean) invalido [iw=fac], by(date formal)

//#### PASO 3: Reestructurar en formato ancho
reshape wide invalido, i(date) j(formal)

//#### PASO 4: Definir serie temporal trimestral
tsset date, quarterly

//#### PASO 5: Convertir a porcentaje
replace invalido1 = invalido1 * 100   // Formal
replace invalido2 = invalido2 * 100   // Informal

//#### PASO 6: Etiquetar variables
label variable invalido1 "Formal"
label variable invalido2 "Informal"

//#### PASO 7: Graficar con estilo moderno
twoway ///
    (connected invalido1 date, lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(vthin) msize(0.4)) ///   // Formal en naranja metálico
    (connected invalido2 date, lcolor("24 116 205") mcolor("24 116 205") ///
        lwidth(vthin) msize(0.4)), ///  // Informal en azul metálico
    ylabel(0(5)50, labsize(medium)) ///
    xtitle("Trimestre", size(medium)) ///
    ytitle("Porcentaje", size(medium)) ///
    legend(order(1 "Formal" 2 "Informal") position(12) ring(0) cols(2)) ///
    graphregion(color(white)) plotregion(lstyle(none))

//#### PASO 8: Exportar gráfica
graph export "$graf\\ENOE_6_2_1.png", replace

restore

//### 6.2.2 GRAF: Porcentaje de ingresos inválidos por sexo ---------

preserve

//#### PASO 1: Eliminar casos sin información
drop if ing7c == .

//#### PASO 2: Calcular proporción por sexo
collapse (mean) invalido [iw=fac], by(date sex)

//#### PASO 3: Reestructurar en formato ancho
reshape wide invalido, i(date) j(sex)

//#### PASO 4: Definir serie temporal trimestral
tsset date, quarterly

//#### PASO 5: Convertir a porcentaje
replace invalido1 = invalido1 * 100   // Hombres
replace invalido2 = invalido2 * 100   // Mujeres

//#### PASO 6: Etiquetar variables
label variable invalido1 "Hombres"
label variable invalido2 "Mujeres"

//#### PASO 7: Graficar con estilo moderno
twoway ///
    (connected invalido1 date, lcolor("24 116 205") mcolor("24 116 205") ///
        lwidth(vthin) msize(0.4)) ///   // Hombres en azul metálico
    (connected invalido2 date, lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(vthin) msize(0.4)), ///  // Mujeres en naranja metálico
    ylabel(0(5)45, labsize(medium)) ///
    xtitle("Trimestre", size(medium)) ///
    ytitle("Porcentaje", size(medium)) ///
    legend(order(1 "Hombres" 2 "Mujeres") position(12) ring(0) cols(2)) ///
    graphregion(color(white)) plotregion(lstyle(none))

//#### PASO 8: Exportar gráfica
graph export "$graf\\ENOE_6_2_2.png", replace

restore


//### 6.2.3 GRAF: Porcentaje de ingresos inválidos por nivel educativo ---------

preserve

//#### PASO 1: Eliminar casos sin información
drop if ing7c == .
drop if educacion == .

//#### PASO 2: Calcular proporción por nivel educativo
collapse (mean) invalido [iw=fac], by(date educacion)

//#### PASO 3: Reestructurar en formato ancho
reshape wide invalido, i(date) j(educacion)

//#### PASO 4: Definir serie temporal trimestral
tsset date, quarterly

//#### PASO 5: Convertir a porcentaje
replace invalido1 = invalido1 * 100   // Sin instrucción
replace invalido2 = invalido2 * 100   // Primaria
replace invalido3 = invalido3 * 100   // Media Superior
replace invalido4 = invalido4 * 100   // Superior
replace invalido5 = invalido5 * 100   // Posgrado

//#### PASO 6: Etiquetar variables
label variable invalido1 "Sin instrucción"
label variable invalido2 "Primaria"
label variable invalido3 "Media Superior"
label variable invalido4 "Superior"
label variable invalido5 "Posgrado"

//#### PASO 7: Graficar con estilo moderno, paleta cálida y símbolos distintos
twoway ///
    (connected invalido1 date, lcolor("255 69 0") mcolor("255 69 0") ///
        msymbol(circle) lwidth(vthin) msize(0.4)) ///       // Naranja metálico
    (connected invalido2 date, lcolor("219 0 91") mcolor("219 0 91") ///
        msymbol(square) lwidth(vthin) msize(0.4)) ///       // Rosa mexicano
    (connected invalido3 date, lcolor("255 105 180") mcolor("255 105 180") ///
        msymbol(triangle) lwidth(vthin) msize(0.4)) ///     // Rosa claro
    (connected invalido4 date, lcolor("255 215 0") mcolor("255 215 0") ///
        msymbol(diamond) lwidth(vthin) msize(0.4)) ///      // Amarillo intenso
    (connected invalido5 date, lcolor("60 179 113") mcolor("60 179 113") ///
        msymbol(plus) lwidth(vthin) msize(0.4)), ///        // Verde primavera
    ylabel(0(5)70, labsize(medium)) ///
    xtitle("Trimestre", size(medium)) ///
    ytitle("Porcentaje", size(medium)) ///
    legend(order(1 "Sin instrucción" 2 "Primaria" 3 "Media Superior" 4 "Superior" 5 "Posgrado") ///
        position(12) ring(0) cols(3)) ///
    graphregion(color(white)) plotregion(lstyle(none))

//#### PASO 8: Exportar gráfica
graph export "$graf\\ENOE_6_2_3.png", replace

restore


//### 6.2.4 GRAF: Porcentaje de ingresos inválidos por ámbito rural-urbano ---------

preserve

//#### PASO 1: Eliminar casos sin información
drop if ing7c == .
drop if rural == .

//#### PASO 2: Calcular proporción por ruralidad
collapse (mean) invalido [iw=fac], by(date rural)

//#### PASO 3: Reestructurar en formato ancho
reshape wide invalido, i(date) j(rural)

//#### PASO 4: Definir serie temporal trimestral
tsset date, quarterly

//#### PASO 5: Convertir a porcentaje
replace invalido0 = invalido0 * 100   // Urbano
replace invalido1 = invalido1 * 100   // Rural

//#### PASO 6: Etiquetar variables
label variable invalido0 "Urbano"
label variable invalido1 "Rural"

//#### PASO 7: Graficar con estilo moderno, paleta cálida y símbolos distintos
twoway ///
    (connected invalido0 date, lcolor("255 69 0") mcolor("255 69 0") ///
        msymbol(circle) lwidth(vthin) msize(0.4)) ///    // Urbano en naranja metálico
    (connected invalido1 date, lcolor("24 116 205") mcolor("24 116 205") ///
        msymbol(square) lwidth(vthin) msize(0.4)), ///   // Rural en rosa mexicano
    ylabel(0(5)45, labsize(medium)) ///
    xtitle("Trimestre", size(medium)) ///
    ytitle("Porcentaje", size(medium)) ///
    legend(order(1 "Urbano" 2 "Rural") position(12) ring(0) cols(2)) ///
    graphregion(color(white)) plotregion(lstyle(none))

//#### PASO 8: Exportar gráfica
graph export "$graf\\ENOE_6_2_4.png", replace

restore

//### 6.2.5 GRAF: Porcentaje de no respuesta en ingresos y rango salarial ---------

//#### PASO 0: Crear variable de rango salarial inválido
gen invalidorango = 0
replace invalidorango = 1 if ing7c == 7

preserve

//#### PASO 1: Calcular proporciones
collapse (mean) invalido (mean) invalidorango [iw=fac], by(date)

//#### PASO 2: Definir serie temporal trimestral
tsset date, quarterly

//#### PASO 3: Convertir a porcentaje
replace invalido      = invalido * 100
replace invalidorango = invalidorango * 100

//#### PASO 4: Etiquetar variables
label variable invalido      "Pregunta de ingresos"
label variable invalidorango "Pregunta de rango salarial"

//#### PASO 5: Graficar con estilo moderno, paleta cálida y símbolos distintos
twoway ///
    (connected invalido date, lcolor("255 69 0") mcolor("255 69 0") ///
        msymbol(circle) lwidth(vthin) msize(0.4)) ///       // Naranja metálico
    (connected invalidorango date, lcolor("blue") mcolor("blue") ///
        msymbol(square) lwidth(vthin) msize(0.4)), ///      // Rosa mexicano
    ylabel(0(5)50, labsize(medium)) ///
    xtitle("Trimestre", size(medium)) ///
    ytitle("Porcentaje", size(medium)) ///
    legend(order(1 "P. Ingresos" 2 "P. Rango de Salario") ///
        position(12) ring(0) cols(2)) ///
    graphregion(color(white)) plotregion(lstyle(none))

//#### PASO 6: Exportar gráfica
graph export "$graf\\ENOE_6_2_5.png", replace

restore


//## 6.3 POBREZA

//##LIMPIEZA PARA TENER BONITO TODO COMO CONEVAL
//##### PASO A: Definir carpetas
gl enoe "D:\INVESTIGACION\DATA\ENOE"
gl sdem "D:\INVESTIGACION\DATA\ENOE\sdem"
gl coe2 "D:\INVESTIGACION\DATA\ENOE\coe2"

cap mkdir "$sdem"

//##### PASO B: Recorrer años y trimestres
forvalues y = 2005/2025 {
    // en 2025 solo hay T1 y T2
    local tmax = cond(`y'==2025, 2, 4)

    forvalues t = 1/`tmax' {
        // Saltar 2T-2020 porque no existe
        if (`y'==2020 & `t'==2) continue

        // código trimestre-año (ej. 1T2005 -> 105, 2T2025 -> 225)
        local code = `t'*100 + (`y' - 2000)

        // archivo de destino (minúsculas estándar CONEVAL)
        local destino "$sdem/sdem`code'.dta"

        // Si ya existe en destino, saltar
        capture confirm file "`destino'"
        if !_rc {
            di as txt "Ya existe: `destino' -> se omite"
            continue
        }

        // Definir archivo de origen según año
        if `y' < 2020 {
            local origen "$enoe/`y'/`t'T/SDEMT`code'.dta"
        }
        else {
            local origen "$enoe/`y'/`t'T/ENOE_SDEMT`code'.dta"
        }

        // Confirmar origen y copiar si existe
        capture confirm file "`origen'"
        if !_rc {
            copy "`origen'" "`destino'", replace
            di as green "Copiado: `origen' --> `destino'"
        }
        else {
            di as error "NO ENCONTRADO: `origen'"
        }
    }
}


//##### PASO C: Copiar COE2 a carpeta plana (2005–2025)

// Global de salida (carpeta destino de COE2)
gl coe2 "D:\INVESTIGACION\DATA\ENOE\coe2"
cap mkdir "$coe2"

// Recorrer años y trimestres
forvalues y = 2005/2025 {
    // en 2025 solo hay T1 y T2
    local tmax = cond(`y'==2025, 2, 4)

    forvalues t = 1/`tmax' {
        // Saltar 2T-2020 porque no existe
        if (`y'==2020 & `t'==2) continue

        // código trimestre-año (ej. 1T2005 -> 105, 2T2025 -> 225)
        local code = `t'*100 + (`y' - 2000)

        // archivo de destino (en minúsculas como estándar)
        local destino "$coe2/coe2`code'.dta"

        // Si ya existe en destino, saltar
        capture confirm file "`destino'"
        if !_rc {
            di as txt "Ya existe: `destino' -> se omite"
            continue
        }

        // Definir archivo de origen según año
        if `y' < 2020 {
            local origen "$enoe/`y'/`t'T/COE2T`code'.dta"
        }
        else {
            local origen "$enoe/`y'/`t'T/ENOE_COE2T`code'.dta"
        }

        // Confirmar origen y copiar si existe
        capture confirm file "`origen'"
        if !_rc {
            copy "`origen'" "`destino'", replace
            di as green "Copiado: `origen' --> `destino'"
        }
        else {
            di as error "NO ENCONTRADO: `origen'"
        }
    }
}




//### CONEVAL PROGRAMA

//#### CONFIGURACIÓN INICIAL

/*#delimit ;
clear ;
version 8.0 ;
set mem 400m ;
set more off ;
cap log close ;
*/

//#### INFORMACIÓN DEL PROGRAMA

/*
 PROGRAMA PARA LA CONSTRUCCIÓN DEL ÍNDICE DE LA
 TENDENCIA LABORAL DE LA POBREZA CON INTERVALOS DE SALARIOS

 Este programa debe ser utilizado con el Software Stata versión 8 o superior. 

 Bases de datos sociodemográficas de la ENOE y ENOE_N:
 - sdem.dta 
 - coe2.dta 
 Disponibles en: www.inegi.gob.mx

 En este programa se utilizan cuatro tipos de archivos:
 1) Bases originales sociodemográficas: "C:\ENOE\sdem"
 2) Bases originales cuestionario ocupación y empleo 2: "C:\ENOE\coe2"
 3) Bases generadas: "C:\ENOE\temp"
 4) Bitácoras: "C:\ENOE\log"

 Para cambiar estas ubicaciones se modifican los siguientes globals.
*/

//##### PASO 1: Definir rutas globales

* Carpeta raíz donde están todos los años
gl enoe "D:\INVESTIGACION\DATA\ENOE"

* Subcarpetas dentro de cada trimestre
gl sdem "D:\INVESTIGACION\DATA\ENOE\sdem"
gl coe2 "D:\INVESTIGACION\DATA\ENOE\coe2"

* Carpeta para bases temporales
gl temp "D:\INVESTIGACION\DATA\ENOE\temp"


//#### NOTAS METODOLÓGICAS

/*
 - El CONEVAL ajusta los indicadores de pobreza laboral y el ITLP.
 - Incorporación de LPEI actualizadas (valor monetario de la canasta alimentaria).
 - El ITLP toma como periodo base el 1T2020 con las LPEI actualizadas.
 Más información: 
 https://www.coneval.org.mx/Medicion/Documents/ITLP_IS/2024/4T2024/Notas_tecnicas_ITLP_4T2024.zip

 Nota 1: A partir de 2006 se usan estimaciones poblacionales del Marco de Muestreo 2020 (INEGI). 
 La información de 2005 usa proyecciones CONAPO 2013.

 Nota 2: Todas las variables deben estar en minúsculas.

 Nota 3: Por el huracán Otis (Acapulco, 4T2023) no se recomienda comparar ese trimestre.
 Más info: 
 https://www.inegi.org.mx/contenidos/saladeprensa/boletines/2024/ENOE/ENOE2024_02.pdf
*/

//#### NOTAS METODOLÓGICAS

/*
 Nota 1: A partir de 2006 se consideran las estimaciones poblacionales 
 generadas por el Marco de Muestreo de Viviendas 2020 del INEGI. 
 La información de 2005 usa proyecciones demográficas de CONAPO 2013.

 Por lo tanto, se realizaron adecuaciones al programa para considerar el nuevo factor. 
 Es necesario volver a descargar y sustituir las bases desde 2006 hasta el trimestre más reciente.

 Nota 2: Para la estimación del ITLP todas las variables de las bases deben estar en minúsculas.

 Nota 3: Por el impacto del huracán Otis en Acapulco (4T2023) la captación de la información 
 se vio afectada, por lo que no se recomienda comparar con dicho trimestre.
 Más información: 
 https://www.inegi.org.mx/contenidos/saladeprensa/boletines/2024/ENOE/ENOE2024_02.pdf
*/

//#### CREACIÓN DE ESTRUCTURA DE RESULTADOS

//##### PASO 2: Crear dataset vacío para almacenar resultados
clear
set obs 1
gen periodo = .
gen TLP = .
save "$temp\pobreza_laboral.dta", replace

//#### PARTE I: LÍNEA DE POBREZA EXTREMA POR INGRESOS (LPEI)

//##### PASO 3: Definir valores monetarios de la LPEI por trimestre

//--- 2005
scalar uT105 = 754.20   // Urbano 1T2005
scalar rT105 = 556.78   // Rural 1T2005
scalar uT205 = 778.81
scalar rT205 = 581.33
scalar uT305 = 779.81
scalar rT305 = 579.00
scalar uT405 = 777.34
scalar rT405 = 574.19

//--- 2006
scalar uT106 = 793.88
scalar rT106 = 589.73
scalar uT206 = 788.75
scalar rT206 = 583.12
scalar uT306 = 805.16
scalar rT306 = 599.09
scalar uT406 = 834.08
scalar rT406 = 629.22

//--- 2007
scalar uT107 = 851.23
scalar rT107 = 641.50
scalar uT207 = 840.49
scalar rT207 = 629.76
scalar uT307 = 846.91
scalar rT307 = 634.21
scalar uT407 = 866.83
scalar rT407 = 650.59

//--- 2008
scalar uT108 = 875.77
scalar rT108 = 655.79
scalar uT208 = 893.87
scalar rT208 = 671.92
scalar uT308 = 915.77
scalar rT308 = 689.23
scalar uT408 = 945.75
scalar rT408 = 715.18

//--- 2009
scalar uT109 = 959.84
scalar rT109 = 724.50
scalar uT209 = 982.88
scalar rT209 = 747.36
scalar uT309 = 996.59
scalar rT309 = 758.12
scalar uT409 = 998.91
scalar rT409 = 759.10

//--- 2010
scalar uT110 = 1026.57
scalar rT110 = 780.73
scalar uT210 = 1017.39
scalar rT210 = 769.93
scalar uT310 = 1008.45
scalar rT310 = 757.71
scalar uT410 = 1032.81
scalar rT410 = 779.66

//--- 2011
scalar uT111 = 1049.07
scalar rT111 = 791.31
scalar uT211 = 1049.74
scalar rT211 = 793.00
scalar uT311 = 1051.53
scalar rT311 = 794.21
scalar uT411 = 1076.46
scalar rT411 = 817.32

//--- 2012
scalar uT112 = 1106.36
scalar rT112 = 843.60
scalar uT212 = 1113.08
scalar rT212 = 847.74
scalar uT312 = 1152.23
scalar rT312 = 884.25
scalar uT412 = 1172.86
scalar rT412 = 901.01

//--- 2013
scalar uT113 = 1185.68
scalar rT113 = 908.25
scalar uT213 = 1197.91
scalar rT213 = 918.90
scalar uT313 = 1197.24
scalar rT313 = 913.56
scalar uT413 = 1220.45
scalar rT413 = 934.09

//--- 2014
scalar uT114 = 1252.56
scalar rT114 = 952.71
scalar uT214 = 1243.86
scalar rT214 = 939.94
scalar uT314 = 1264.97
scalar rT314 = 954.15
scalar uT414 = 1295.15
scalar rT414 = 982.12

//--- 2015
scalar uT115 = 1296.14
scalar rT115 = 981.50
scalar uT215 = 1300.42
scalar rT215 = 985.56
scalar uT315 = 1312.35
scalar rT315 = 992.04
scalar uT415 = 1329.88
scalar rT415 = 1006.05

//--- 2016
scalar uT116 = 1366.93
scalar rT116 = 1039.95
scalar uT216 = 1359.11
scalar rT216 = 1028.42
scalar uT316 = 1358.61
scalar rT316 = 1025.84
scalar uT416 = 1388.35
scalar rT416 = 1054.02

//--- 2017
scalar uT117 = 1407.01
scalar rT117 = 1061.68
scalar uT217 = 1439.17
scalar rT217 = 1090.56
scalar uT317 = 1490.80
scalar rT317 = 1136.26
scalar uT417 = 1501.22
scalar rT417 = 1141.14

//--- 2018
scalar uT118 = 1509.99
scalar rT118 = 1144.85
scalar uT218 = 1508.32
scalar rT218 = 1139.69
scalar uT318 = 1537.71
scalar rT318 = 1159.55
scalar uT418 = 1564.27
scalar rT418 = 1186.53

//--- 2019
scalar uT119 = 1594.81
scalar rT119 = 1209.52
scalar uT219 = 1597.63
scalar rT219 = 1209.34
scalar uT319 = 1604.31
scalar rT319 = 1212.42
scalar uT419 = 1619.78
scalar rT419 = 1225.79

//--- 2020
scalar uT120 = 1664.71
scalar rT120 = 1266.14
scalar uT320 = 1701.39
scalar rT320 = 1298.60
scalar uT420 = 1719.75
scalar rT420 = 1313.92

//--- 2021
scalar uT121 = 1732.14
scalar rT121 = 1317.79
scalar uT221 = 1777.32
scalar rT221 = 1358.60
scalar uT321 = 1828.63
scalar rT321 = 1400.08
scalar uT421 = 1877.13
scalar rT421 = 1443.29

//--- 2022
scalar uT122 = 1951.74
scalar rT122 = 1498.46
scalar uT222 = 1990.99
scalar rT222 = 1530.41
scalar uT322 = 2081.04
scalar rT322 = 1597.57
scalar uT422 = 2115.73
scalar rT422 = 1625.32

//--- 2023
scalar uT123 = 2154.34
scalar rT123 = 1651.91
scalar uT223 = 2176.94
scalar rT223 = 1665.47
scalar uT323 = 2218.76
scalar rT323 = 1697.79
scalar uT423 = 2239.99
scalar rT423 = 1716.25

//--- 2024
scalar uT124 = 2303.21
scalar rT124 = 1768.38
scalar uT224 = 2301.81
scalar rT224 = 1762.85
scalar uT324 = 2350.35
scalar rT324 = 1797.26
scalar uT424 = 2357.49
scalar rT424 = 1796.86

//--- 2025
scalar uT125 = 2369.94
scalar rT125 = 1793.54
scalar uT225 = 2423.77
scalar rT225 = 1836.75




//#### PARTE II: CÁLCULO DEL INGRESO DE LOS HOGARES

//##### PASO 4: Definir los periodos a procesar

/********************************************************
Parte II CÁLCULO DEL INGRESO DE LOS HOGARES
********************************************************/  

foreach x in 105 205 305 405 106 206 306 406 107 207 307 407 108 208 308 408 109 209 309 409 110 210 310 410 ///
              111 211 311 411 112 212 312 412 113 213 313 413 114 214 314 414 115 215 315 415 116 216 316 416 ///
              117 217 317 417 118 218 318 418 119 219 319 419 120 320 420 121 221 321 421 122 222 322 422 ///
              123 223 323 423 124 224 324 424 125 225 {

    *=================*
    * Bloque COE2
    *=================*
    if `x'==320 | `x'==420 | `x'==121 | `x'==221 {
        use "$coe2\coe2`x'.dta", clear 
        rename *, lower 
        tostring cd_a ent v_sel n_ren, replace format(%02.0f) force 
        tostring con, replace format(%04.0f) force 
        tostring n_hog h_mud tipo ca mes_cal, replace force 
        gen str foliop = (cd_a + ent + con + v_sel + tipo + mes_cal + ca + n_hog + h_mud + n_ren) 
    }
    else if `x'==321 | `x'==421 | `x'==122 | `x'==222 | `x'==322 | `x'==422 {
        use "$coe2\coe2`x'.dta", clear 
        rename *, lower 
        tostring cd_a ent v_sel n_ren, replace format(%02.0f) force 
        tostring con, replace format(%04.0f) force 
        tostring n_hog h_mud tipo mes_cal, replace force 
        gen str foliop = (cd_a + ent + con + v_sel + tipo + mes_cal + n_hog + h_mud + n_ren) 
    }
    else if `x'==123 | `x'==223 | `x'==323 | `x'==423 | `x'==124 | `x'==224 | `x'==324 | `x'==424 | `x'==125 | `x'==225 {
        use "$coe2\coe2`x'.dta", clear 
        rename *, lower 
        tostring cd_a ent v_sel n_ren, replace format(%02.0f) force 
        tostring con, replace format(%04.0f) force 
        tostring n_hog h_mud tipo mes_cal, replace force 
        gen str foliop = (cd_a + ent + con + v_sel + tipo + mes_cal + n_hog + h_mud + n_ren) 
    }
    else {
        use "$coe2\coe2`x'.dta", clear 
        rename *, lower 
        tostring cd_a ent v_sel n_ren, replace format(%02.0f) force 
        tostring con, replace format(%04.0f) force 
        tostring n_hog h_mud, replace force 
        gen str foliop = (cd_a + ent + con + v_sel + n_hog + h_mud + n_ren) 
    }

    keep foliop p6c p6b2 p6_9 p6a3
    sort foliop 
    save "$temp\ingresoT`x'.dta", replace 

    *=================*
    * Bloque SDEM/ENOE
    *=================*
    if `x'==320 | `x'==420 | `x'==121 | `x'==221 {
        use "$sdem\sdem`x'.dta", clear  
        rename *, lower 
        tostring cd_a ent v_sel n_ren, replace format(%02.0f) force 
        tostring con, replace format(%04.0f) force 
        tostring n_hog h_mud tipo ca mes_cal, replace force 

        keep if r_def==0 & (c_res==1 | c_res==3)   
        gen str folioh = (cd_a + ent + con + v_sel + tipo + mes_cal + ca + n_hog + h_mud) 
        gen str foliop = (cd_a + ent + con + v_sel + tipo + mes_cal + ca + n_hog + h_mud + n_ren)  
        rename t_loc_tri t_loc 
        destring t_loc, replace 
        rename fac_tri fac 
    }
    else if `x'==321 | `x'==421 | `x'==122 | `x'==222 | `x'==322 | `x'==422 {
        use "$sdem\sdem`x'.dta", clear  
        rename *, lower 
        tostring cd_a ent v_sel n_ren, replace format(%02.0f) force 
        tostring con, replace format(%04.0f) force 
        tostring n_hog h_mud tipo mes_cal, replace force 

        keep if r_def==0 & (c_res==1 | c_res==3)   
        gen str folioh = (cd_a + ent + con + v_sel + tipo + mes_cal + n_hog + h_mud) 
        gen str foliop = (cd_a + ent + con + v_sel + tipo + mes_cal + n_hog + h_mud + n_ren)  
        rename t_loc_tri t_loc 
        destring t_loc, replace 
        rename fac_tri fac 
    }
    else if `x'==123 | `x'==223 | `x'==323 | `x'==423 | `x'==124 | `x'==224 | `x'==324 | `x'==424 | `x'==125 | `x'==225 {
        use "$sdem\sdem`x'.dta", clear  
        rename *, lower 
        tostring cd_a ent v_sel n_ren, replace format(%02.0f) force  
        tostring con, replace format(%04.0f) force  
        tostring n_hog h_mud tipo mes_cal, replace force  

        keep if r_def==0 & (c_res==1 | c_res==3)  
        gen str folioh = (cd_a + ent + con + v_sel + tipo + mes_cal + n_hog + h_mud)  
        gen str foliop = (cd_a + ent + con + v_sel + tipo + mes_cal + n_hog + h_mud + n_ren)  
        rename t_loc_tri t_loc  
        destring t_loc, replace  
        rename fac_tri fac  
    }
    else {
        use "$sdem\sdem`x'.dta", clear  
        rename *, lower 
        tostring cd_a ent v_sel n_ren, replace format(%02.0f) force 
        tostring con, replace format(%04.0f) force 
        tostring n_hog h_mud, replace force 

        keep if r_def==0 & (c_res==1 | c_res==3)   
        gen str folioh = (cd_a + ent + con + v_sel + n_hog + h_mud) 
        gen str foliop = (cd_a + ent + con + v_sel + n_hog + h_mud + n_ren) 
        destring t_loc, replace 
    }

    *=================*
    * Unificación y cálculo ingreso hogar
    *=================*
    keep folioh foliop salario t_loc fac clase1 clase2 ent ingocup r_def c_res mun cd_a con n_pro_viv v_sel h_mud n_hog n_ren ///
         cs_p13_1 cs_p13_2 par_c sex eda n_hij e_con zona ing7c emple7c niv_ins t_tra anios_esc hrsocup ing_x_hrs imssissste rama_est2 pos_ocu emp_ppal dur_est

    sort foliop 
    merge foliop using "$temp\ingresoT`x'.dta"
    drop _merge 
    save "$temp\touseT`x'.dta", replace 

    gen ocupado = cond(clase1==1 & clase2==1,1,0) 

    destring p6b2 p6c, replace 
    recode p6b2 (999998=.) (999999=.) 

    gen double ingreso=p6b2 
    replace ingreso=0 if ocupado==0 
    replace ingreso=0 if p6b2==. & (p6_9==9 | p6a3==3) 
    replace ingreso=0.5*salario if p6b2==. & p6c==1 
    replace ingreso=1*salario   if p6b2==. & p6c==2 
    replace ingreso=1.5*salario if p6b2==. & p6c==3 
    replace ingreso=2.5*salario if p6b2==. & p6c==4 
    replace ingreso=4*salario   if p6b2==. & p6c==5 
    replace ingreso=7.5*salario if p6b2==. & p6c==6 
    replace ingreso=10*salario  if p6b2==. & p6c==7 

    gen tamh = 1   
    rename fac factor  

    gen rururb = cond(t_loc>=1 & t_loc<=3,0,1)  
    label define ru 0 "Urbano" 1 "Rural"  
    label values rururb ru  

    destring ent, replace 
    gen mv=cond(ingreso==. & ocupado==1,1,0) 

    keep folioh tamh ingreso rururb factor ent mv ocupado 
    collapse (sum) tamh ingreso mv ocupado (mean) rururb factor ent, by(folioh)  

    replace mv=1 if mv>0 & mv!=. 
    drop if mv==1 

    *=================*
    * Parte III: Pobreza laboral
    *=================*
    count
    if r(N)>0 {
        gen factorp = factor*tamh  
        gen lpT`x' = cond(rururb==0,uT`x',rT`x')  
        gen pob = cond((ingreso/tamh)<lpT`x',1,0)  

        sum pob [w=factorp]  
        gen double TLP=r(mean)*100 
        sum pob [w=factorp] if rururb==0  
        gen double TLPu=r(mean)*100 
        sum pob [w=factorp] if rururb==1  
        gen double TLPr=r(mean)*100 

        foreach y in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 {
            sum pob [w=factorp] if ent==`y'  
            gen double TLP`y'=r(mean)*100 
        }

        gen periodo="`x'"  
        keep TLP* periodo 
        keep in 1  

        capture append using "$temp\pobreza_laboral.dta", force 
        save "$temp\pobreza_laboral.dta", replace  
    }
}


destring periodo, replace force  

label define periodo ///
    105 "I 2005"   205 "II 2005"  305 "III 2005"  405 "IV 2005" ///
    106 "I 2006"   206 "II 2006"  306 "III 2006"  406 "IV 2006" ///
    107 "I 2007"   207 "II 2007"  307 "III 2007"  407 "IV 2007" ///
    108 "I 2008"   208 "II 2008"  308 "III 2008"  408 "IV 2008" ///
    109 "I 2009"   209 "II 2009"  309 "III 2009"  409 "IV 2009" ///
    110 "I 2010"   210 "II 2010"  310 "III 2010"  410 "IV 2010" ///
    111 "I 2011"   211 "II 2011"  311 "III 2011"  411 "IV 2011" ///
    112 "I 2012"   212 "II 2012"  312 "III 2012"  412 "IV 2012" ///
    113 "I 2013"   213 "II 2013"  313 "III 2013"  413 "IV 2013" ///
    114 "I 2014"   214 "II 2014"  314 "III 2014"  414 "IV 2014" ///
    115 "I 2015"   215 "II 2015"  315 "III 2015"  415 "IV 2015" ///
    116 "I 2016"   216 "II 2016"  316 "III 2016"  416 "IV 2016" ///
    117 "I 2017"   217 "II 2017"  317 "III 2017"  417 "IV 2017" ///
    118 "I 2018"   218 "II 2018"  318 "III 2018"  418 "IV 2018" ///
    119 "I 2019"   219 "II 2019"  319 "III 2019"  419 "IV 2019" ///
    120 "I 2020"   320 "III 2020" 420 "IV 2020" ///
    121 "I 2021"   221 "II 2021"  321 "III 2021"  421 "IV 2021" ///
    122 "I 2022"   222 "II 2022"  322 "III 2022"  422 "IV 2022" ///
    123 "I 2023"   223 "II 2023"  323 "III 2023"  423 "IV 2023" ///
    124 "I 2024"   224 "II 2024"  324 "III 2024"  424 "IV 2024" ///
    125 "I 2025"   225 "II 2025"

label value periodo periodo  

rename TLP  Nacional  
rename TLPu Urbano  
rename TLPr Rural  
rename TLP1  Aguascalientes  
rename TLP2  Baja_California  
rename TLP3  Baja_California_Sur  
rename TLP4  Campeche  
rename TLP5  Coahuila  
rename TLP6  Colima  
rename TLP7  Chiapas  
rename TLP8  Chihuahua  
rename TLP9  Ciudad_de_México 
rename TLP10 Durango  
rename TLP11 Guanajuato  
rename TLP12 Guerrero  
rename TLP13 Hidalgo  
rename TLP14 Jalisco  
rename TLP15 Estado_de_México  
rename TLP16 Michoacán  
rename TLP17 Morelos  
rename TLP18 Nayarit  
rename TLP19 Nuevo_León  
rename TLP20 Oaxaca  
rename TLP21 Puebla  
rename TLP22 Querétaro  
rename TLP23 Quintana_Roo  
rename TLP24 San_Luis_Potosí  
rename TLP25 Sinaloa  
rename TLP26 Sonora  
rename TLP27 Tabasco  
rename TLP28 Tamaulipas  
rename TLP29 Tlaxcala  
rename TLP30 Veracruz  
rename TLP31 Yucatán  
rename TLP32 Zacatecas  

tabstat Nacional-Zacatecas, by(periodo) format(%6.2f) nototal  
save "$temp\ITLP.dta", replace


use "$temp\ITLP.dta", clear

* Extraer año y trimestre desde periodo
gen year = mod(periodo,100) + 2000
gen qtr  = floor(periodo/100)

* Crear variable de fecha trimestral
gen date = yq(year, qtr)

* Aplicar formato de trimestre
format date %tq

* (opcional) borrar auxiliares
drop year qtr

//### 6.3 GRAFICA PORBREZA LABORAL

twoway ///
    (connected Nacional date, lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(vthin) msize(0.4)), ///   // Serie en naranja metálico
    ylabel(30(5)50, labsize(medium)) ///
    xtitle("Trimestre", size(medium)) ///
    ytitle("Porcentaje", size(medium)) ///
    legend(off) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph export "$graf/POBLAB_6_3.png", as(png) replace

//#### POBREZA MULTIDIMENSIONAL

*Cargar manualmente las 5 observaciones de ENIGH

* Crear variable vacía
gen multidimensional = .

* Asignar valores anuales a todos los trimestres del año
replace multidimensional = 36.0 if inrange(date, yq(2016,1), yq(2016,4))
replace multidimensional = 34.9 if inrange(date, yq(2018,1), yq(2018,4))
replace multidimensional = 35.4 if inrange(date, yq(2020,1), yq(2020,4))
replace multidimensional = 29.3 if inrange(date, yq(2022,1), yq(2022,4))
replace multidimensional = 24.2 if inrange(date, yq(2024,1), yq(2024,4))

//### 6.3.1 GRAFICA POB MULTIDIMENSIONAL 

twoway ///
    (line multidimensional date if inrange(date, tq(2016q1), tq(2024q4)), ///
        lcolor("135 206 250") lwidth(medthick)), /// azul pastel (light sky blue)
    ylabel(20(5)35, labsize(medium)) ///
    xlabel(`=tq(2016q1)'(4)`=tq(2024q4)', format(%tq) angle(45)) ///
    xtitle("Trimestre", size(medium)) ///
    ytitle("Porcentaje de la Población", size(medium)) ///
    legend(off) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph export "$graf/POBMULTI_2016_2024.png", as(png) replace


//### 6.3.2 GRAFICA ENOE VS ENIGH

twoway ///
    (connected Nacional date if inrange(date, tq(2016q1), tq(2024q4)), ///
        lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(vthin) msize(0.4)) /// Nacional - conectado naranja
    (line multidimensional date if inrange(date, tq(2016q1), tq(2024q4)), ///
        lcolor("135 206 250") lwidth(medthick)), /// Multidimensional - línea azul pastel
    ylabel(20(5)60, labsize(medium)) ///
    xlabel(`=tq(2016q1)'(4)`=tq(2024q4)', format(%tq) angle(45)) ///
    xtitle("Trimestre", size(medium)) ///
    ytitle("Porcentaje de la Población", size(medium)) ///
    legend(order(1 "ENOE (Pobreza Laboral)" 2 "ENIGH (Multidimensional)") ///
           pos(2) ring(0) region(lstyle(none))) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph export "$graf/POBREZA_ENIGH_ENOE.png", as(png) replace

//### 6.3.3 SCATTER

//##### PASO 1. Mantener solo trimestres de interés (Q4 de cada par)
keep if inlist(date, tq(2016q4), tq(2018q4), tq(2020q4), tq(2022q4), tq(2024q4))

//##### PASO 2. Graficar scatter ENOE vs ENIGH
twoway ///
    (scatter multidimensional Nacional, mcolor(blue) msymbol(triangle)) ///
    (lfit multidimensional Nacional, lcolor("255 69 0") lpattern(dash)), ///
    xtitle("Pobreza Laboral ENOE (Nacional)", size(medium)) ///
    ytitle("Pobreza Multidimensional ENIGH", size(medium)) ///
    legend(order(1 "Datos observados" 2 "Recta de ajuste") pos(12) ring(0)) ///
    graphregion(color(white)) plotregion(lstyle(none))
	
	graph export "$graf/POBREZA_SCATTER.png", as(png) replace


//### 6.3 MAPAS

//#### LIMPIEZA

//##### PASO 1. Abrir base ITLP
use "$temp/ITLP.dta", clear

* Extraer año y trimestre desde periodo
gen year = mod(periodo,100) + 2000
gen qtr  = floor(periodo/100)

* Crear variable de fecha trimestral
gen date = yq(year, qtr)

* Aplicar formato de trimestre
format date %tq

* (opcional) borrar auxiliares
drop year qtr

// Quitamos variables que no son entidades
drop Nacional Urbano Rural periodo 

// Mantener solo 2025q2
keep if date == tq(2025q2)

//##### PASO 2. Transponer base
xpose, clear varname

//##### PASO 3. Renombrar variables
rename _varname ent     // nombres de las entidades
rename v1       ipl     // valores de pobreza laboral

//##### PASO 4. Limpiar
drop if missing(ipl)    // quitar filas vacías

//##### PASO 4. Limpiar observaciones
drop if ent == "date"

//##### PASO 5. Crear clave numérica oficial INEGI
gen str2 cve_ent = ""
replace cve_ent = "01" if ent=="Aguascalientes"
replace cve_ent = "02" if ent=="Baja_California"
replace cve_ent = "03" if ent=="Baja_California_Sur"
replace cve_ent = "04" if ent=="Campeche"
replace cve_ent = "05" if ent=="Coahuila"
replace cve_ent = "06" if ent=="Colima"
replace cve_ent = "07" if ent=="Chiapas"
replace cve_ent = "08" if ent=="Chihuahua"
replace cve_ent = "09" if ent=="Ciudad_de_México"
replace cve_ent = "10" if ent=="Durango"
replace cve_ent = "11" if ent=="Guanajuato"
replace cve_ent = "12" if ent=="Guerrero"
replace cve_ent = "13" if ent=="Hidalgo"
replace cve_ent = "14" if ent=="Jalisco"
replace cve_ent = "15" if ent=="Estado_de_México"
replace cve_ent = "16" if ent=="Michoacán"
replace cve_ent = "17" if ent=="Morelos"
replace cve_ent = "18" if ent=="Nayarit"
replace cve_ent = "19" if ent=="Nuevo_León"
replace cve_ent = "20" if ent=="Oaxaca"
replace cve_ent = "21" if ent=="Puebla"
replace cve_ent = "22" if ent=="Querétaro"
replace cve_ent = "23" if ent=="Quintana_Roo"
replace cve_ent = "24" if ent=="San_Luis_Potosí"
replace cve_ent = "25" if ent=="Sinaloa"
replace cve_ent = "26" if ent=="Sonora"
replace cve_ent = "27" if ent=="Tabasco"
replace cve_ent = "28" if ent=="Tamaulipas"
replace cve_ent = "29" if ent=="Tlaxcala"
replace cve_ent = "30" if ent=="Veracruz"
replace cve_ent = "31" if ent=="Yucatán"
replace cve_ent = "32" if ent=="Zacatecas"

//##### PASO 6. Verificar
order cve_ent ent ipl
list in 1/10

//##### PASO 7. Guardar base final lista para mapear
save "$ENOE/ILP_2025q2.dta", replace

//## MAPA 1 ENOE

use "$ENOE/ILP_2025q2.dta", clear

ssc install shp2dta
ssc install spmap


//##### PASO 1. Convertir shapefile a formato Stata
shp2dta using "$ENOE/mex_ent.shp", ///
    database("$ENOE/mex_ent_db.dta") ///
    coordinates("$ENOE/mex_ent_coord.dta") ///
    genid(id) genc(cve_ent) replace
	
//##### PASO 2. Abrir la base shapefile convertida (atributos)
use "$ENOE/mex_ent_db.dta", clear

// Poner todas las variables en minúsculas
rename *, lower

// Revisar estructura
list in 1/5


//##### PASO 3. Hacer merge con tu base ITLP 2025q2
merge 1:1 cve_ent using "$ENOE/ILP_2025q2.dta"

// Revisar resultado
tab _merge
drop if _merge != 3   // nos quedamos sólo con matches
drop _merge

//##### PASO 4. Llamar coordenadas del shapefile

spmap ipl using "$ENOE/mex_ent_coord.dta", id(id) ///
    fcolor("255 245 235" "255 225 200" "255 200 160" "255 170 120" ///
           "255 140 80" "255 110 50" "255 80 20" "200 40 0") ///
    ocolor(black ..) ///
    clmethod(custom) clbreaks(0 10 20 30 40 50 60 70 80) ///
    legend(label(1 "Índice de pobreza laboral (%)") size(medium)) ///
    graphregion(color(white))

	
	//##### PASO 5. Guardar mapa
graph export "$graf/MAPA_6_3_1.png", replace

***CARGO MANUALMENTE POBREZA MULTIDIMENCIONAL ENIGH 2024

*##### PASO 1. Crear variable multidimensional
gen multidimensional = .   // variable vacía

*##### PASO 2. Reemplazar valores en orden 01–32
replace multidimensional = 16.5 if cve_ent=="01"
replace multidimensional = 9.5  if cve_ent=="02"
replace multidimensional = 8.9  if cve_ent=="03"
replace multidimensional = 30.9 if cve_ent=="04"
replace multidimensional = 11.6 if cve_ent=="05"
replace multidimensional = 14.0 if cve_ent=="06"
replace multidimensional = 38.8 if cve_ent=="07"
replace multidimensional = 12.9 if cve_ent=="08"
replace multidimensional = 17.9 if cve_ent=="09"
replace multidimensional = 23.5 if cve_ent=="10"
replace multidimensional = 24.3 if cve_ent=="11"
replace multidimensional = 36.7 if cve_ent=="12"
replace multidimensional = 29.7 if cve_ent=="13"
replace multidimensional = 17.3 if cve_ent=="14"
replace multidimensional = 27.5 if cve_ent=="15"
replace multidimensional = 28.9 if cve_ent=="16"
replace multidimensional = 30.5 if cve_ent=="17"
replace multidimensional = 19.8 if cve_ent=="18"
replace multidimensional = 10.1 if cve_ent=="19"
replace multidimensional = 35.3 if cve_ent=="20"
replace multidimensional = 36.1 if cve_ent=="21"
replace multidimensional = 15.2 if cve_ent=="22"
replace multidimensional = 15.1 if cve_ent=="23"
replace multidimensional = 25.3 if cve_ent=="24"
replace multidimensional = 15.5 if cve_ent=="25"
replace multidimensional = 12.6 if cve_ent=="26"
replace multidimensional = 28.3 if cve_ent=="27"
replace multidimensional = 18.7 if cve_ent=="28"
replace multidimensional = 36.5 if cve_ent=="29"
replace multidimensional = 35.7 if cve_ent=="30"
replace multidimensional = 23.1 if cve_ent=="31"
replace multidimensional = 32.9 if cve_ent=="32"


//#### MAPA ENIGH 2024

spmap multidimensional using "$ENOE/mex_ent_coord.dta", id(id) ///
    fcolor("230 245 255" "190 220 240" "150 200 230" "100 170 210" ///
           "50 130 190" "20 90 160" "0 60 120" "0 30 80") ///
    ocolor(black ..) ///
    clmethod(custom) clbreaks(0 10 20 30 40) ///
    legend(label(1 "Índice de multidimensional (%)") size(medium)) ///
    graphregion(color(white))

	
	//##### PASO 5. Guardar mapa
graph export "$graf/MAPA_6_3_2.png", replace



//## 6.4 IMPUTACION

//###LIMPIEZA

//#### PASO 1: generar variables de fecha y guardar bases trimestrales
foreach x in 105 205 305 405 106 206 306 406 107 207 307 407 108 208 308 408 ///
            109 209 309 409 110 210 310 410 111 211 311 411 112 212 312 412 ///
            113 213 313 413 114 214 314 414 115 215 315 415 116 216 316 416 ///
            117 217 317 417 118 218 318 418 119 219 319 419 120 320 420 ///
            121 221 321 421 122 222 322 422 123 223 323 423 124 224 324 424 125 225 {
    
    // si no existe el archivo base, saltar al siguiente
    capture confirm file "$temp\touseT`x'.dta"
    if _rc continue

    // si ya existe el archivo procesado (_1), saltar al siguiente
    capture confirm file "$temp\touseT`x'_1.dta"
    if _rc==0 continue

    // abrir archivo base
    use "$temp\touseT`x'.dta", clear
    
    // crear variable fecha base
    gen fecha = `x'
    tostring fecha, replace
    
    // extraer año y trimestre
    gen year = "20" + substr(fecha,2,2)
    gen q    = substr(fecha,1,1)
    destring q year, replace
    
    // construir fecha en formato trimestral (%tq)
    gen date = yq(year, q)
    format date %tq
    
    // guardar base temporal con sufijo _1
    save "$temp\touseT`x'_1.dta", replace
}


****************************************************
 //#### PASO 2: unir todas las bases trimestrales en una sola
****************************************************

use "$temp\touseT105_1.dta", clear

foreach x in 205 305 405 106 206 306 406 107 207 307 407 108 208 308 408 ///
            109 209 309 409 110 210 310 410 111 211 311 411 112 212 312 412 ///
            113 213 313 413 114 214 314 414 115 215 315 415 116 216 316 416 ///
            117 217 317 417 118 218 318 418 119 219 319 419 120 320 420 ///
            121 221 321 421 122 222 322 422 123 223 323 423 124 224 324 424 125 225 {
    
    // verificar si el archivo existe
    capture confirm file "$temp\touseT`x'_1.dta"
    if _rc {
        di as error ">>> ADVERTENCIA: no se encontró touseT`x'_1.dta, se omite."
        continue
    }

    // anexar base
    append using "$temp\touseT`x'_1.dta"
    save "$temp\ENOE_coneval.dta", replace

    // mensaje de progreso
    di as txt ">>> Trimestre `x' ya fue anexado a ENOE_coneval.dta"
}


//#### PASO 3: preparar base para imputación hotdeck
use "$temp\ENOE_coneval.dta", clear
qui compress

//##### PASO 3.1: convertir variables clave a numéricas
qui destring eda sex e_con niv_ins anios_esc hrsocup imssissste ///
             rama_est2 pos_ocu ing7c clase1 clase2 cs_p13_1 cs_p13_2, replace

//##### PASO 3.2: ajustar etiquetas de localidad
tostring t_loc, replace

//##### PASO 3.3: generar variables binarias de control
gen female  = sex==2
gen married = e_con==1 | e_con==5
gen formal  = imssissste>=1 & imssissste<=3

//##### PASO 3.4: etiquetar variables
label var clase1   "PEA 1, NoPEA 2"
label var clase2   "2 Desoc, 3 PNEA Disp"
label var pos_ocu  "Ocup"
label var niv_ins  "Nivel Instr"
label var rama_est2 "Rama"
label var hrsocup  "Horas Ocupadas"
label var t_loc    "Tam Localidad"
label var female   "Female"
label var eda      "Edad"
label var married  "Casado"
label var ingocup  "Ingreso Ocupacion"

//##### PASO 3.5: construir variable de nivel educativo
gen nivel_educ=.
replace nivel_educ=1 if ((cs_p13_1==0)|(cs_p13_1==1)| ///
 (cs_p13_1==2&cs_p13_2==0)|(cs_p13_1==99)|(cs_p13_1==.))
replace nivel_educ=1 if ((cs_p13_1==2&(cs_p13_2>=1&cs_p13_2<6))| ///
 (cs_p13_1==2&cs_p13_2==9))
replace nivel_educ=2 if ((cs_p13_1==2&(cs_p13_2==6|cs_p13_2==7|cs_p13_2==8))| ///
 (cs_p13_1==3&cs_p13_2<=2)|(cs_p13_1==3&cs_p13_2==9))
replace nivel_educ=3 if ((cs_p13_1==3&(cs_p13_2==3|cs_p13_2==4|cs_p13_2==5|cs_p13_2==6))| ///
 (cs_p13_1==4&(cs_p13_2<=2|cs_p13_2==9)))
replace nivel_educ=4 if ((cs_p13_1==4&(cs_p13_2==3|cs_p13_2==4))| ///
 (cs_p13_1==5&cs_p13_2<=3)|(cs_p13_1==7&cs_p13_2<=3)|(cs_p13_1==6))
replace nivel_educ=5 if ((cs_p13_1==7&(cs_p13_2>=4))| ///
 (cs_p13_1==5&cs_p13_2>3)|(cs_p13_1==8)|(cs_p13_1==9))
tab nivel_educ
label var nivel_educ "Nivel educ"

//##### PASO 3.6: generar variable rural

destring t_loc, replace
gen rural = t_loc==4
label var rural "Rural 1, <2500habs"

// limpiar variables innecesarias
drop cs_p* h_mud zona
qui compress

//##### PASO 3.7: agrupar edades en rangos
gen edadg=1 if eda>=20 & eda<=24
replace edadg=2 if eda>=25 & eda<=29
replace edadg=3 if eda>=30 & eda<=34
replace edadg=4 if eda>=35 & eda<=39
replace edadg=5 if eda>=40 & eda<=44
replace edadg=6 if eda>=45 & eda<=49
replace edadg=7 if eda>=50 & eda<=54
replace edadg=8 if eda>=55 & eda<=59
replace edadg=9 if eda>=60 & eda<=64
replace edadg=0 if eda<20
replace edadg=10 if eda>=65 & eda<=70
replace edadg=11 if eda>70

//##### PASO 3.8: depurar ingresos y ocupación
replace ingocup = . if ingocup==0
gen wage_invalid = (ingocup==.)
keep if clase2==1                        // población ocupada
keep if hrsocup>0 & hrsocup<199          // horas trabajo positivas
drop if pos_ocu==4 | pos_ocu==5 | pos_ocu==. | ing7c==6 | ing7c==.   // excluir sin pago

//##### PASO 3.9: ajustar variable rural
destring rural, replace


//### HOTDECK


//#### PASO 4: Hotdeck a Ingresos

//##### PASO 4.1: instalar paquete hotdeck (solo 1 vez)
ssc install hotdeck, replace

//##### PASO 4.2: hotdeck con variable ing7c como estrato
hotdeck ingocup using "$temp\impu", ///
    by(year q cd_a female edadg nivel_educ rural ing7c) ///
    store impute(5) ///
    keep(foliop folioh wage_invalid ingocup year q cd_a)

//##### PASO 4.3: hotdeck sin variable ing7c
hotdeck ingocup using "$temp\impu_2", ///
    by(year q cd_a female edadg nivel_educ rural) ///
    store impute(5) ///
    keep(foliop folioh wage_invalid ingocup year q cd_a)

//##### PASO 4.4: combinar imputaciones con y sin ing7c
forvalues i=1/5 {
    
    // usar solo registros con ingresos inválidos de impu`i'
    use if wage_invalid==1 & ingocup!=. using "$temp\impu`i'.dta", replace
    gen rep=1
    
    // anexar imputaciones sin ing7c
    append using "$temp\impu_2`i'.dta"
    replace rep=2 if rep==.
    
    // ordenar para asegurar consistencia
    sort foliop year q cd_a rep
    
    // quedarnos solo con la primera observación de cada grupo
    by foliop year q cd_a: keep if _n==1
    
    // guardar imputación final de esta réplica
    save "$temp\hotdeck`i'.dta", replace
}


/********************************************************
             combinar bases imputadas hotdeck
********************************************************/

//#### PASO 5: UNIR HOTDECKS
forvalues x=2/5 {
    
    use "$temp\hotdeck`x'.dta", clear
    
    //##### PASO 5.1: renombrar ingresos imputados
    rename ingocup ingocup`x'
    
    //##### PASO 5.2: primer merge (imputación 2 con imputación 1)
    if `x'==2 {
        merge 1:1 foliop folioh year q cd_a using "$temp\hotdeck1.dta"
        
        // renombrar ingreso original de la base 1
        rename ingocup ingocup1
        
        // verificar y limpiar _merge
        tab _merge
        drop _merge
        
        // guardar base combinada
        save "$temp\hotdeck.dta", replace
    }
    
    //##### PASO 5.3: merges siguientes (imputación 3, 4, 5)
    else {
        merge 1:1 foliop folioh year q cd_a using "$temp\hotdeck.dta"
        
        tab _merge
        drop _merge
        
        save "$temp\hotdeck.dta", replace
    }
}



//#### PASO 6 Hotdeck con ENOE

//##### PASO 6.1: crear base hotdeck consolidada
use "$temp\hotdeck.dta", clear
keep foliop folioh year q cd_a ingocup* rep
save "$temp\data_hotdeck.dta", replace

//##### PASO 6.2: integrar hotdeck a la base original ENOE
use "$temp\ENOE_coneval.dta", clear
quietly merge m:1 foliop folioh year q cd_a using "$temp\hotdeck.dta"

tab _merge
drop _merge
quietly compress

//##### PASO 6.3: reemplazar imputaciones con ingreso válido
forval j=1/5 {
    replace ingocup`j' = ingocup if ingocup>0 & ingocup!=.
}

//##### PASO 6.4: crear código de clasificación de ingresos
gen code_earn=.

// casos: sin pago o fuera del flujo laboral
replace code_earn=0 if ingocup==0 & ingocup1==.
// casos: ingreso imputado
replace code_earn=1 if ingocup==0 & (ingocup1>0 & ingocup1!=.)
// casos: ingreso válido original
replace code_earn=2 if ingocup>0 & ingocup!=.

tab code_earn
count

label var code_earn "Codigo Imp"
label def code_earn 0 "Sin Pago o Fuera FL" ///
                     1 "Imputado" ///
                     2 "Ing Valido"
label values code_earn code_earn

//##### PASO 6.5: guardar base final
save "$temp\coneval_hotdeck.dta", replace
di as txt ">>> Base final CONEVAL_HOTDECK.DTA creada con éxito"



//### iPOLATE

//#### PASO 1: preparar base para imputación ipolate
use "$temp\ENOE_coneval.dta", clear
qui compress

//##### PASO 1.1: convertir variables clave a numéricas
qui destring eda sex e_con niv_ins anios_esc hrsocup imssissste ///
             rama_est2 pos_ocu ing7c clase1 clase2 cs_p13_1 cs_p13_2, replace

//##### PASO 1.2: ajustar etiquetas de localidad
tostring t_loc, replace

//##### PASO 1.3: generar variables binarias de control
gen female  = sex==2
gen married = e_con==1 | e_con==5
gen formal  = imssissste>=1 & imssissste<=3

//##### PASO 1.4: etiquetar variables
label var clase1    "PEA 1, NoPEA 2"
label var clase2    "2 Desoc, 3 PNEA Disp"
label var pos_ocu   "Ocup"
label var niv_ins   "Nivel Instr"
label var rama_est2 "Rama"
label var hrsocup   "Horas Ocupadas"
label var t_loc     "Tam Localidad"
label var female    "Female"
label var eda       "Edad"
label var married   "Casado"
label var ingocup   "Ingreso Ocupacion"

//##### PASO 1.5: construir variable de nivel educativo
gen nivel_educ=.
replace nivel_educ=1 if ((cs_p13_1==0)|(cs_p13_1==1)| ///
 (cs_p13_1==2&cs_p13_2==0)|(cs_p13_1==99)|(cs_p13_1==.))
replace nivel_educ=1 if ((cs_p13_1==2&(cs_p13_2>=1&cs_p13_2<6))| ///
 (cs_p13_1==2&cs_p13_2==9))
replace nivel_educ=2 if ((cs_p13_1==2&(cs_p13_2==6|cs_p13_2==7|cs_p13_2==8))| ///
 (cs_p13_1==3&cs_p13_2<=2)|(cs_p13_1==3&cs_p13_2==9))
replace nivel_educ=3 if ((cs_p13_1==3&(cs_p13_2==3|cs_p13_2==4|cs_p13_2==5|cs_p13_2==6))| ///
 (cs_p13_1==4&(cs_p13_2<=2|cs_p13_2==9)))
replace nivel_educ=4 if ((cs_p13_1==4&(cs_p13_2==3|cs_p13_2==4))| ///
 (cs_p13_1==5&cs_p13_2<=3)|(cs_p13_1==7&cs_p13_2<=3)|(cs_p13_1==6))
replace nivel_educ=5 if ((cs_p13_1==7&(cs_p13_2>=4))| ///
 (cs_p13_1==5&cs_p13_2>3)|(cs_p13_1==8)|(cs_p13_1==9))
tab nivel_educ
label var nivel_educ "Nivel educ"

//##### PASO 1.6: generar variable rural
destring t_loc, replace
gen rural = t_loc==4
label var rural "Rural 1, <2500habs"

// limpiar variables innecesarias
drop cs_p* h_mud zona
qui compress

//##### PASO 1.7: agrupar edades en rangos
gen edadg=1 if eda>=20 & eda<=24
replace edadg=2 if eda>=25 & eda<=29
replace edadg=3 if eda>=30 & eda<=34
replace edadg=4 if eda>=35 & eda<=39
replace edadg=5 if eda>=40 & eda<=44
replace edadg=6 if eda>=45 & eda<=49
replace edadg=7 if eda>=50 & eda<=54
replace edadg=8 if eda>=55 & eda<=59
replace edadg=9 if eda>=60 & eda<=64
replace edadg=0 if eda<20
replace edadg=10 if eda>=65 & eda<=70
replace edadg=11 if eda>70

//##### PASO 1.8: depurar ingresos y ocupación
replace ingocup = . if ingocup==0
gen wage_invalid = (ingocup==.)
keep if clase2==1                        // solo población ocupada
keep if hrsocup>0 & hrsocup<199          // horas de trabajo válidas
drop if pos_ocu==4 | pos_ocu==5 | pos_ocu==. | ing7c==6 | ing7c==.  // excluir sin pago

//##### PASO 1.9: asegurar formato numérico de rural
destring rural, replace


//#### PASO 2: imputación de ingresos con ipolate y combinación final

//##### PASO 2.1: asignar ingresos con rangos salariales (criterio CONEVAL)
replace ingocup=0.5*salario if p6b2==. & p6c==1
replace ingocup=1*salario   if p6b2==. & p6c==2
replace ingocup=1.5*salario if p6b2==. & p6c==3
replace ingocup=2.5*salario if p6b2==. & p6c==4
replace ingocup=4*salario   if p6b2==. & p6c==5
replace ingocup=7.5*salario if p6b2==. & p6c==6
replace ingocup=10*salario  if p6b2==. & p6c==7

//##### PASO 2.2: interpolación con años de escolaridad
sort date anios_esc
by date: ipolate ingocup anios_esc, generate(ingipp1) epolate

//##### PASO 2.3: interpolación con horas de ocupación
sort date hrsocup
by date: ipolate ingocup hrsocup, generate(ingipp2) epolate

//##### PASO 2.4: promedio de imputaciones ipolate
egen ing_ipo=rowmean(ingipp1 ingipp2)
replace ing_ipo=. if ing_ipo<0
save "$temp\ipolate.dta", replace

//##### PASO 2.5: juntar ipolate con hotdeck (archivo guardado como coneval_hotdeack.dta)
use "$temp\coneval_hotdeck.dta", clear
merge m:m foliop folioh year q cd_a using "$temp\ipolate.dta"

replace ing_ipo=ingocup if ingocup>0 & ingocup!=.
drop _merge

// promedio del ingreso imputado por hotdeck
egen ingh=rowmean(ingocup1 ingocup2 ingocup3 ingocup4 ingocup5)

save "$temp\coneval_hotdeck_ipolate.dta", replace

// antes del merge con INPC
preserve
    use "$temp\INPC_TRIM.dta", clear
drop q
drop year
format date %tq          // asegurar formato trimestral
gen q    = quarter(dofq(date))   // extrae trimestre (1 a 4)
gen year = year(dofq(date))      // extrae año (ej. 2005, 2025)

    
    // guardar versión lista para merge
    save "$temp\INPC_TRIM.dta", replace
restore

//##### PASO 2.6: añadir INPC trimestral

use "$temp\coneval_hotdeck_ipolate.dta", clear

merge m:1 q year using "$temp\INPC_TRIM.dta"
gen tamh=1
drop if _merge==2

// limpiar ingresos en cero
replace ingocup=. if ingocup==0
replace ingh=.    if ingh==0
replace ing_ipo=. if ing_ipo==0

save "$temp\coneval_hotdeck_ipolate_c.dta", replace
di as txt ">>> Base CONEVAL_HOTDECK_IPOLATE_C.DTA creada con éxito"

//### GRAFICA 6.4 HOTDECK VS IPOLI VS REPORTADO

use "$temp\coneval_hotdeck_ipolate_c.dta", clear

preserve
    //##### PASO: generar series ajustadas por INPC
    gen laboral1 = (ingocup/INPC)*100
    gen laboral2 = (ingh/INPC)*100
    gen laboral3 = (ing_ipo/INPC)*100

    //##### PASO: colapsar a nivel hogar
    collapse (sum) tamh laboral1 laboral2 laboral3 [iw=fac], by(folioh date q year)
    replace laboral1 = laboral1/tamh
    replace laboral2 = laboral2/tamh
    replace laboral3 = laboral3/tamh

    //##### PASO: promedio trimestral
    collapse (mean) laboral1 laboral2 laboral3, by(date)
    tsset date, quarterly

    // etiquetas
    label variable laboral1 "Oficial"
    label variable laboral2 "Hot-Deck"
    label variable laboral3 "Ipolate"

    //##### PASO: gráfica con paleta preferida
    twoway ///
        (connected laboral1 date, lcolor("34 139 34") mcolor("34 139 34") ///
            lwidth(vthin) msize(0.4)) ///   // Oficial en naranja metálico
        (connected laboral2 date, lcolor("24 116 205") mcolor("24 116 205") ///
            lwidth(vthin) msize(0.4)) ///   // Hot-Deck en azul fuerte
        (connected laboral3 date, lcolor("255 69 0") mcolor("255 69 0") ///
            lwidth(vthin) msize(0.4)), ///  // Ipolate en verde
        ylabel(, labsize(medium)) ///
        xtitle("Trimestre", size(medium)) ///
        ytitle("Ingreso Real", size(medium)) ///
        legend(order(1 "Oficial" 2 "Hot-Deck" 3 "Ipolate") position(12) ring(0) cols(3)) ///
        graphregion(color(white)) plotregion(lstyle(none))

    //##### PASO: exportar gráfica
    graph export "$graf\IMPUTACION_6_4.png", replace
restore





//##### PASO 3 % POBLACION POBREZA LABORAL HOT DECK

clear 
set mem 400m 
set more off 

***************************************************************
set obs 1  
gen periodo = .  
gen TLP = .  
save "$temp\PL_Hotdeck.dta", replace  

*****************************************************************************
*Parte I LÍNEA DE POBREZA EXTREMA POR INGRESOS :
*****************************************************************************  

di in red "Promedio trimestral de los valores de la  Línea de Pobreza Extrema por Ingresos"

//--- 2005
scalar uT105 = 754.20   // Urbano 1T2005
scalar rT105 = 556.78   // Rural 1T2005
scalar uT205 = 778.81
scalar rT205 = 581.33
scalar uT305 = 779.81
scalar rT305 = 579.00
scalar uT405 = 777.34
scalar rT405 = 574.19

//--- 2006
scalar uT106 = 793.88
scalar rT106 = 589.73
scalar uT206 = 788.75
scalar rT206 = 583.12
scalar uT306 = 805.16
scalar rT306 = 599.09
scalar uT406 = 834.08
scalar rT406 = 629.22

//--- 2007
scalar uT107 = 851.23
scalar rT107 = 641.50
scalar uT207 = 840.49
scalar rT207 = 629.76
scalar uT307 = 846.91
scalar rT307 = 634.21
scalar uT407 = 866.83
scalar rT407 = 650.59

//--- 2008
scalar uT108 = 875.77
scalar rT108 = 655.79
scalar uT208 = 893.87
scalar rT208 = 671.92
scalar uT308 = 915.77
scalar rT308 = 689.23
scalar uT408 = 945.75
scalar rT408 = 715.18

//--- 2009
scalar uT109 = 959.84
scalar rT109 = 724.50
scalar uT209 = 982.88
scalar rT209 = 747.36
scalar uT309 = 996.59
scalar rT309 = 758.12
scalar uT409 = 998.91
scalar rT409 = 759.10

//--- 2010
scalar uT110 = 1026.57
scalar rT110 = 780.73
scalar uT210 = 1017.39
scalar rT210 = 769.93
scalar uT310 = 1008.45
scalar rT310 = 757.71
scalar uT410 = 1032.81
scalar rT410 = 779.66

//--- 2011
scalar uT111 = 1049.07
scalar rT111 = 791.31
scalar uT211 = 1049.74
scalar rT211 = 793.00
scalar uT311 = 1051.53
scalar rT311 = 794.21
scalar uT411 = 1076.46
scalar rT411 = 817.32

//--- 2012
scalar uT112 = 1106.36
scalar rT112 = 843.60
scalar uT212 = 1113.08
scalar rT212 = 847.74
scalar uT312 = 1152.23
scalar rT312 = 884.25
scalar uT412 = 1172.86
scalar rT412 = 901.01

//--- 2013
scalar uT113 = 1185.68
scalar rT113 = 908.25
scalar uT213 = 1197.91
scalar rT213 = 918.90
scalar uT313 = 1197.24
scalar rT313 = 913.56
scalar uT413 = 1220.45
scalar rT413 = 934.09

//--- 2014
scalar uT114 = 1252.56
scalar rT114 = 952.71
scalar uT214 = 1243.86
scalar rT214 = 939.94
scalar uT314 = 1264.97
scalar rT314 = 954.15
scalar uT414 = 1295.15
scalar rT414 = 982.12

//--- 2015
scalar uT115 = 1296.14
scalar rT115 = 981.50
scalar uT215 = 1300.42
scalar rT215 = 985.56
scalar uT315 = 1312.35
scalar rT315 = 992.04
scalar uT415 = 1329.88
scalar rT415 = 1006.05

//--- 2016
scalar uT116 = 1366.93
scalar rT116 = 1039.95
scalar uT216 = 1359.11
scalar rT216 = 1028.42
scalar uT316 = 1358.61
scalar rT316 = 1025.84
scalar uT416 = 1388.35
scalar rT416 = 1054.02

//--- 2017
scalar uT117 = 1407.01
scalar rT117 = 1061.68
scalar uT217 = 1439.17
scalar rT217 = 1090.56
scalar uT317 = 1490.80
scalar rT317 = 1136.26
scalar uT417 = 1501.22
scalar rT417 = 1141.14

//--- 2018
scalar uT118 = 1509.99
scalar rT118 = 1144.85
scalar uT218 = 1508.32
scalar rT218 = 1139.69
scalar uT318 = 1537.71
scalar rT318 = 1159.55
scalar uT418 = 1564.27
scalar rT418 = 1186.53

//--- 2019
scalar uT119 = 1594.81
scalar rT119 = 1209.52
scalar uT219 = 1597.63
scalar rT219 = 1209.34
scalar uT319 = 1604.31
scalar rT319 = 1212.42
scalar uT419 = 1619.78
scalar rT419 = 1225.79

//--- 2020
scalar uT120 = 1664.71
scalar rT120 = 1266.14
scalar uT320 = 1701.39
scalar rT320 = 1298.60
scalar uT420 = 1719.75
scalar rT420 = 1313.92

//--- 2021
scalar uT121 = 1732.14
scalar rT121 = 1317.79
scalar uT221 = 1777.32
scalar rT221 = 1358.60
scalar uT321 = 1828.63
scalar rT321 = 1400.08
scalar uT421 = 1877.13
scalar rT421 = 1443.29

//--- 2022
scalar uT122 = 1951.74
scalar rT122 = 1498.46
scalar uT222 = 1990.99
scalar rT222 = 1530.41
scalar uT322 = 2081.04
scalar rT322 = 1597.57
scalar uT422 = 2115.73
scalar rT422 = 1625.32

//--- 2023
scalar uT123 = 2154.34
scalar rT123 = 1651.91
scalar uT223 = 2176.94
scalar rT223 = 1665.47
scalar uT323 = 2218.76
scalar rT323 = 1697.79
scalar uT423 = 2239.99
scalar rT423 = 1716.25

//--- 2024
scalar uT124 = 2303.21
scalar rT124 = 1768.38
scalar uT224 = 2301.81
scalar rT224 = 1762.85
scalar uT324 = 2350.35
scalar rT324 = 1797.26
scalar uT424 = 2357.49
scalar rT424 = 1796.86

//--- 2025
scalar uT125 = 2369.94
scalar rT125 = 1793.54
scalar uT225 = 2423.77
scalar rT225 = 1836.75


****************************************************
 //##### PASO 3: cálculo de pobreza laboral y consolidación
****************************************************

foreach x in 105 205 305 405 106 206 306 406 ///
            107 207 307 407 108 208 308 408 ///
            109 209 309 409 110 210 310 410 ///
            111 211 311 411 112 212 312 412 ///
            113 213 313 413 114 214 314 414 ///
            115 215 315 415 116 216 316 416 ///
            117 217 317 417 118 218 318 418 ///
            119 219 319 419 120 320 420 ///
            121 221 321 421 122 222 322 422 ///
            123 223 323 423 124 224 324 424 ///
            125 225 {

    //##### PASO 3.1: abrir base con imputación Hotdeck
    use "$temp\coneval_hotdeck_ipolate_c.dta", clear
    rename fac factor  

    //##### PASO 3.2: generar variable de ruralidad
    gen rururb = cond(t_loc>=1 & t_loc<=3,0,1)  
    label define ru 0 "Urbano" 1 "Rural"  
    label values rururb ru  

    //##### PASO 3.3: preparar variables clave
    destring ent fecha, replace  
    keep if fecha==`x'

    //##### PASO 3.4: colapsar a nivel hogar
    collapse (sum) tamh ingh (mean) rururb factor ent, by(folioh)  

    //##### PASO 3.5: construir indicadores de pobreza laboral
    gen factorp = factor*tamh  
    gen lpT`x' = cond(rururb==0,uT`x',rT`x')  
    gen pob    = cond((ingh/tamh)<lpT`x',1,0)  

    //##### PASO 3.6: tasas nacional, urbana y rural
    sum pob [w=factorp]  
    gen double TLP  = r(mean)*100 
    format TLP %14.12gc 

    sum pob [w=factorp] if rururb==0  
    gen double TLPu = r(mean)*100 
    format TLPu %14.12gc 

    sum pob [w=factorp] if rururb==1  
    gen double TLPr = r(mean)*100 
    format TLPr %14.12gc 

    //##### PASO 3.7: tasas por entidad federativa
    foreach y in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 ///
                 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 {
        sum pob [w=factorp] if ent==`y'  
        gen double TLP`y' = r(mean)*100 
        format TLP`y' %14.12gc 
    }

    //##### PASO 3.8: preparar y guardar resultados del trimestre
    gen periodo = "`x'"  
    keep TLP* periodo 
    keep in 1  

    // acumular en la base final
    capture append using "$temp\PL_Hotdeck.dta", force 
    save "$temp\PL_Hotdeck.dta", replace  
}


****************************************************
 //###### PASO 3.9: preparar base final de pobreza laboral Hotdeck
****************************************************

* convertir variable periodo a numérica
destring periodo, replace force  

* definir etiquetas para cada periodo trimestral
label define periodo ///
    105 "I 2005"   205 "II 2005"   305 "III 2005"   405 "IV 2005" ///
    106 "I 2006"   206 "II 2006"   306 "III 2006"   406 "IV 2006" ///
    107 "I 2007"   207 "II 2007"   307 "III 2007"   407 "IV 2007" ///
    108 "I 2008"   208 "II 2008"   308 "III 2008"   408 "IV 2008" ///
    109 "I 2009"   209 "II 2009"   309 "III 2009"   409 "IV 2009" ///
    110 "I 2010"   210 "II 2010"   310 "III 2010"   410 "IV 2010" ///
    111 "I 2011"   211 "II 2011"   311 "III 2011"   411 "IV 2011" ///
    112 "I 2012"   212 "II 2012"   312 "III 2012"   412 "IV 2012" ///
    113 "I 2013"   213 "II 2013"   313 "III 2013"   413 "IV 2013" ///
    114 "I 2014"   214 "II 2014"   314 "III 2014"   414 "IV 2014" ///
    115 "I 2015"   215 "II 2015"   315 "III 2015"   415 "IV 2015" ///
    116 "I 2016"   216 "II 2016"   316 "III 2016"   416 "IV 2016" ///
    117 "I 2017"   217 "II 2017"   317 "III 2017"   417 "IV 2017" ///
    118 "I 2018"   218 "II 2018"   318 "III 2018"   418 "IV 2018" ///
    119 "I 2019"   219 "II 2019"   319 "III 2019"   419 "IV 2019" ///
    120 "I 2020"   320 "III 2020"  420 "IV 2020" ///
    121 "I 2021"   221 "II 2021"   321 "III 2021"   421 "IV 2021" ///
    122 "I 2022"   222 "II 2022"   322 "III 2022"   422 "IV 2022" ///
    123 "I 2023"   223 "II 2023"   323 "III 2023"   423 "IV 2023" ///
    124 "I 2024"   224 "II 2024"   324 "III 2024"   424 "IV 2024" ///
    125 "I 2025"   225 "II 2025", replace  

label value periodo periodo  

****************************************************
 //###### PASO 3.10: renombrar variables de tasas
****************************************************

rename TLP     Nacional_H  
rename TLPu    Urbano_H  
rename TLPr    Rural_H  

rename TLP1    Aguascalientes_H  
rename TLP2    Baja_California_H  
rename TLP3    Baja_California_Sur_H  
rename TLP4    Campeche_H  
rename TLP5    Coahuila_H  
rename TLP6    Colima_H  
rename TLP7    Chiapas_H  
rename TLP8    Chihuahua_H  
rename TLP9    Ciudad_de_Mexico_H  
rename TLP10   Durango_H  
rename TLP11   Guanajuato_H  
rename TLP12   Guerrero_H  
rename TLP13   Hidalgo_H  
rename TLP14   Jalisco_H  
rename TLP15   Estado_de_Mexico_H  
rename TLP16   Michoacan_H  
rename TLP17   Morelos_H  
rename TLP18   Nayarit_H  
rename TLP19   Nuevo_Leon_H  
rename TLP20   Oaxaca_H  
rename TLP21   Puebla_H  
rename TLP22   Queretaro_H  
rename TLP23   Quintana_Roo_H  
rename TLP24   San_Luis_Potosi_H  
rename TLP25   Sinaloa_H  
rename TLP26   Sonora_H  
rename TLP27   Tabasco_H  
rename TLP28   Tamaulipas_H  
rename TLP29   Tlaxcala_H  
rename TLP30   Veracruz_H  
rename TLP31   Yucatan_H  
rename TLP32   Zacatecas_H  

****************************************************
 //###### PASO 3.11: resumen y guardar base final
****************************************************

* tabulado de verificación
tabstat Nacional_H-Zacatecas_H, by(periodo) format(%6.2f) nototal  

* guardar base consolidada
save "$temp\PL_Hotdeck.dta", replace


//##### PASO 4 % POBLACION POBREZA LABORAL iPolate


***************************************************************
clear 
set mem 400m 
set more off 

set obs 1  
gen periodo = .  
gen TLP = .  
save "$temp\PL_Ipolate.dta", replace  

*****************************************************************************
*Parte I LÍNEA DE POBREZA EXTREMA POR INGRESOS :
*****************************************************************************  

di in red "Promedio trimestral de los valores de la  Línea de Pobreza Extrema por Ingresos"

//--- 2005
scalar uT105 = 754.20   // Urbano 1T2005
scalar rT105 = 556.78   // Rural 1T2005
scalar uT205 = 778.81
scalar rT205 = 581.33
scalar uT305 = 779.81
scalar rT305 = 579.00
scalar uT405 = 777.34
scalar rT405 = 574.19

//--- 2006
scalar uT106 = 793.88
scalar rT106 = 589.73
scalar uT206 = 788.75
scalar rT206 = 583.12
scalar uT306 = 805.16
scalar rT306 = 599.09
scalar uT406 = 834.08
scalar rT406 = 629.22

//--- 2007
scalar uT107 = 851.23
scalar rT107 = 641.50
scalar uT207 = 840.49
scalar rT207 = 629.76
scalar uT307 = 846.91
scalar rT307 = 634.21
scalar uT407 = 866.83
scalar rT407 = 650.59

//--- 2008
scalar uT108 = 875.77
scalar rT108 = 655.79
scalar uT208 = 893.87
scalar rT208 = 671.92
scalar uT308 = 915.77
scalar rT308 = 689.23
scalar uT408 = 945.75
scalar rT408 = 715.18

//--- 2009
scalar uT109 = 959.84
scalar rT109 = 724.50
scalar uT209 = 982.88
scalar rT209 = 747.36
scalar uT309 = 996.59
scalar rT309 = 758.12
scalar uT409 = 998.91
scalar rT409 = 759.10

//--- 2010
scalar uT110 = 1026.57
scalar rT110 = 780.73
scalar uT210 = 1017.39
scalar rT210 = 769.93
scalar uT310 = 1008.45
scalar rT310 = 757.71
scalar uT410 = 1032.81
scalar rT410 = 779.66

//--- 2011
scalar uT111 = 1049.07
scalar rT111 = 791.31
scalar uT211 = 1049.74
scalar rT211 = 793.00
scalar uT311 = 1051.53
scalar rT311 = 794.21
scalar uT411 = 1076.46
scalar rT411 = 817.32

//--- 2012
scalar uT112 = 1106.36
scalar rT112 = 843.60
scalar uT212 = 1113.08
scalar rT212 = 847.74
scalar uT312 = 1152.23
scalar rT312 = 884.25
scalar uT412 = 1172.86
scalar rT412 = 901.01

//--- 2013
scalar uT113 = 1185.68
scalar rT113 = 908.25
scalar uT213 = 1197.91
scalar rT213 = 918.90
scalar uT313 = 1197.24
scalar rT313 = 913.56
scalar uT413 = 1220.45
scalar rT413 = 934.09

//--- 2014
scalar uT114 = 1252.56
scalar rT114 = 952.71
scalar uT214 = 1243.86
scalar rT214 = 939.94
scalar uT314 = 1264.97
scalar rT314 = 954.15
scalar uT414 = 1295.15
scalar rT414 = 982.12

//--- 2015
scalar uT115 = 1296.14
scalar rT115 = 981.50
scalar uT215 = 1300.42
scalar rT215 = 985.56
scalar uT315 = 1312.35
scalar rT315 = 992.04
scalar uT415 = 1329.88
scalar rT415 = 1006.05

//--- 2016
scalar uT116 = 1366.93
scalar rT116 = 1039.95
scalar uT216 = 1359.11
scalar rT216 = 1028.42
scalar uT316 = 1358.61
scalar rT316 = 1025.84
scalar uT416 = 1388.35
scalar rT416 = 1054.02

//--- 2017
scalar uT117 = 1407.01
scalar rT117 = 1061.68
scalar uT217 = 1439.17
scalar rT217 = 1090.56
scalar uT317 = 1490.80
scalar rT317 = 1136.26
scalar uT417 = 1501.22
scalar rT417 = 1141.14

//--- 2018
scalar uT118 = 1509.99
scalar rT118 = 1144.85
scalar uT218 = 1508.32
scalar rT218 = 1139.69
scalar uT318 = 1537.71
scalar rT318 = 1159.55
scalar uT418 = 1564.27
scalar rT418 = 1186.53

//--- 2019
scalar uT119 = 1594.81
scalar rT119 = 1209.52
scalar uT219 = 1597.63
scalar rT219 = 1209.34
scalar uT319 = 1604.31
scalar rT319 = 1212.42
scalar uT419 = 1619.78
scalar rT419 = 1225.79

//--- 2020
scalar uT120 = 1664.71
scalar rT120 = 1266.14
scalar uT320 = 1701.39
scalar rT320 = 1298.60
scalar uT420 = 1719.75
scalar rT420 = 1313.92

//--- 2021
scalar uT121 = 1732.14
scalar rT121 = 1317.79
scalar uT221 = 1777.32
scalar rT221 = 1358.60
scalar uT321 = 1828.63
scalar rT321 = 1400.08
scalar uT421 = 1877.13
scalar rT421 = 1443.29

//--- 2022
scalar uT122 = 1951.74
scalar rT122 = 1498.46
scalar uT222 = 1990.99
scalar rT222 = 1530.41
scalar uT322 = 2081.04
scalar rT322 = 1597.57
scalar uT422 = 2115.73
scalar rT422 = 1625.32

//--- 2023
scalar uT123 = 2154.34
scalar rT123 = 1651.91
scalar uT223 = 2176.94
scalar rT223 = 1665.47
scalar uT323 = 2218.76
scalar rT323 = 1697.79
scalar uT423 = 2239.99
scalar rT423 = 1716.25

//--- 2024
scalar uT124 = 2303.21
scalar rT124 = 1768.38
scalar uT224 = 2301.81
scalar rT224 = 1762.85
scalar uT324 = 2350.35
scalar rT324 = 1797.26
scalar uT424 = 2357.49
scalar rT424 = 1796.86

//--- 2025
scalar uT125 = 2369.94
scalar rT125 = 1793.54
scalar uT225 = 2423.77
scalar rT225 = 1836.75



****************************************************
 //###### PASO 4: cálculo de pobreza laboral con Ipolate
****************************************************

foreach x in 105 205 305 405 106 206 306 406 ///
            107 207 307 407 108 208 308 408 ///
            109 209 309 409 110 210 310 410 ///
            111 211 311 411 112 212 312 412 ///
            113 213 313 413 114 214 314 414 ///
            115 215 315 415 116 216 316 416 ///
            117 217 317 417 118 218 318 418 ///
            119 219 319 419 120 320 420 ///
            121 221 321 421 122 222 322 422 ///
            123 223 323 423 124 224 324 424 ///
            125 225 {

    //##### PASO 4.1: abrir base con imputación Ipolate
    use "$temp\coneval_hotdeck_ipolate_c.dta", clear
    rename fac factor  

    //##### PASO 4.2: generar variable de ruralidad
    gen rururb = cond(t_loc>=1 & t_loc<=3,0,1)  
    label define ru 0 "Urbano" 1 "Rural"  
    label values rururb ru  

    //##### PASO 4.3: preparar variables clave
    destring ent fecha, replace  
    keep if fecha==`x'

    //##### PASO 4.4: colapsar a nivel hogar
    collapse (sum) tamh ing_ipo (mean) rururb factor ent, by(folioh)  

    //##### PASO 4.5: construir indicadores de pobreza laboral
    gen factorp = factor*tamh  
    gen lpT`x'  = cond(rururb==0,uT`x',rT`x')  
    gen pob     = cond((ing_ipo/tamh)<lpT`x',1,0)  

    //##### PASO 4.6: tasas nacional, urbana y rural
    sum pob [w=factorp]  
    gen double TLP = r(mean)*100 
    format TLP %14.12gc 

    sum pob [w=factorp] if rururb==0  
    gen double TLPu = r(mean)*100 
    format TLPu %14.12gc 

    sum pob [w=factorp] if rururb==1  
    gen double TLPr = r(mean)*100 
    format TLPr %14.12gc 

    //##### PASO 4.7: tasas por entidad federativa
    foreach y in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 ///
                 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 {
        sum pob [w=factorp] if ent==`y'  
        gen double TLP`y' = r(mean)*100 
        format TLP`y' %14.12gc 
    }

    //##### PASO 4.8: preparar y guardar resultados del trimestre
    gen periodo = "`x'"  
    keep TLP* periodo 
    keep in 1  

    capture append using "$temp\PL_Ipolate.dta", force 
    save "$temp\PL_Ipolate.dta", replace  
}


****************************************************
 //##### PASO 4.9: preparar base final de pobreza laboral Ipolate
****************************************************

* convertir variable periodo a numérica
destring periodo, replace force  

* definir etiquetas para cada periodo trimestral
label define periodo ///
    105 "I 2005"   205 "II 2005"   305 "III 2005"   405 "IV 2005" ///
    106 "I 2006"   206 "II 2006"   306 "III 2006"   406 "IV 2006" ///
    107 "I 2007"   207 "II 2007"   307 "III 2007"   407 "IV 2007" ///
    108 "I 2008"   208 "II 2008"   308 "III 2008"   408 "IV 2008" ///
    109 "I 2009"   209 "II 2009"   309 "III 2009"   409 "IV 2009" ///
    110 "I 2010"   210 "II 2010"   310 "III 2010"   410 "IV 2010" ///
    111 "I 2011"   211 "II 2011"   311 "III 2011"   411 "IV 2011" ///
    112 "I 2012"   212 "II 2012"   312 "III 2012"   412 "IV 2012" ///
    113 "I 2013"   213 "II 2013"   313 "III 2013"   413 "IV 2013" ///
    114 "I 2014"   214 "II 2014"   314 "III 2014"   414 "IV 2014" ///
    115 "I 2015"   215 "II 2015"   315 "III 2015"   415 "IV 2015" ///
    116 "I 2016"   216 "II 2016"   316 "III 2016"   416 "IV 2016" ///
    117 "I 2017"   217 "II 2017"   317 "III 2017"   417 "IV 2017" ///
    118 "I 2018"   218 "II 2018"   318 "III 2018"   418 "IV 2018" ///
    119 "I 2019"   219 "II 2019"   319 "III 2019"   419 "IV 2019" ///
    120 "I 2020"   320 "III 2020"  420 "IV 2020" ///
    121 "I 2021"   221 "II 2021"   321 "III 2021"   421 "IV 2021" ///
    122 "I 2022"   222 "II 2022"   322 "III 2022"   422 "IV 2022" ///
    123 "I 2023"   223 "II 2023"   323 "III 2023"   423 "IV 2023" ///
    124 "I 2024"   224 "II 2024"   324 "III 2024"   424 "IV 2024" ///
    125 "I 2025"   225 "II 2025", replace  

label value periodo periodo  

****************************************************
 //##### PASO 4.10: renombrar variables de tasas
****************************************************

rename TLP     Nacional_I  
rename TLPu    Urbano_I  
rename TLPr    Rural_I  

rename TLP1    Aguascalientes_I  
rename TLP2    Baja_California_I  
rename TLP3    Baja_California_Sur_I  
rename TLP4    Campeche_I  
rename TLP5    Coahuila_I  
rename TLP6    Colima_I  
rename TLP7    Chiapas_I  
rename TLP8    Chihuahua_I  
rename TLP9    Ciudad_de_Mexico_I  
rename TLP10   Durango_I  
rename TLP11   Guanajuato_I  
rename TLP12   Guerrero_I  
rename TLP13   Hidalgo_I  
rename TLP14   Jalisco_I  
rename TLP15   Estado_de_Mexico_I  
rename TLP16   Michoacan_I  
rename TLP17   Morelos_I  
rename TLP18   Nayarit_I  
rename TLP19   Nuevo_Leon_I  
rename TLP20   Oaxaca_I  
rename TLP21   Puebla_I  
rename TLP22   Queretaro_I  
rename TLP23   Quintana_Roo_I  
rename TLP24   San_Luis_Potosi_I  
rename TLP25   Sinaloa_I  
rename TLP26   Sonora_I  
rename TLP27   Tabasco_I  
rename TLP28   Tamaulipas_I  
rename TLP29   Tlaxcala_I  
rename TLP30   Veracruz_I  
rename TLP31   Yucatan_I  
rename TLP32   Zacatecas_I  

****************************************************
 //##### PASO 4.11: resumen y guardar base final
****************************************************

* tabulado de verificación
tabstat Nacional_I-Zacatecas_I, by(periodo) format(%6.2f) nototal  

* guardar base consolidada
save "$temp\PL_Ipolate.dta", replace



****************************************************
 //##### PASO 5: juntar las tres bases de pobreza laboral
****************************************************

* abrir base ITLP
use "$temp\ITLP.dta", clear

* merge con Hotdeck
merge 1:1 periodo using "$temp\PL_Hotdeck.dta"
drop _merge

* merge con Ipolate
merge 1:1 periodo using "$temp\PL_Ipolate.dta"
drop _merge

****************************************************
 //##### PASO 5.1: generar variables de fecha
****************************************************

generate fecha = periodo
tostring fecha, replace

* extraer últimos dos dígitos del año
gen year_2 = substr(fecha, length(fecha)-1, 2)

* reconstruir año y trimestre
gen year = "20" + year_2
gen q    = substr(fecha, 1, 1)
destring year q, replace

* construir variable date en formato trimestral
gen date = yq(year, q)
format date %tq

****************************************************
 //##### PASO 5.2: guardar base consolidada
****************************************************
save "$temp\3pobrezas.dta", replace


//### GRAFICA ITLP OFICIAL VS HOT VS iPOLATE

****************************************************
 //##### PASO 6: gráfica comparativa de pobreza laboral
****************************************************

use "$temp\3pobrezas.dta", replace
tsset date, quarterly

twoway ///
    (connected Nacional date, lcolor("34 139 34") mcolor("34 139 34") ///
        lwidth(vthin) msize(0.4)) ///   // Oficial (ITLP) en naranja metálico
    (connected Nacional_H date, lcolor("24 116 205") mcolor("24 116 205") ///
        lwidth(vthin) msize(0.4)) ///   // Hotdeck en azul fuerte
    (connected Nacional_I date, lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(vthin) msize(0.4)), ///  // Ipolate en verde
    ylabel(20(5)50, labsize(medium)) ///
    xtitle("Trimestre", size(medium)) ///
    ytitle("Porcentaje", size(medium)) ///
    legend(order(1 "Oficial (ITLP)" 2 "Hotdeck" 3 "Ipolate") ///
           position(12) ring(0) cols(3)) ///
    graphregion(color(white)) plotregion(lstyle(none))

graph export "$graf\IMPUTACION_6_4_1.png", replace


//### GRAFICA SCATTER : ING NO VALIDO VS TASA DE PARTICIPACION LABORAL

* Abrir base ENOE
use "$ENOE\Base_ENOE_SDEM_2005_2025.dta", clear

****************************************************
 //##### PASO 1: generar dummy de ingreso inválido
****************************************************

replace ingocup = . if ingocup==999998 | ingocup==0
gen ing_inv = 0
replace ing_inv = 1 if ingocup==.

****************************************************
 //##### PASO 2: calcular población en edad laboral (PEL) y PEA
****************************************************

* PEA: población económicamente activa (clase1 == 1)
* PEL: población en edad laboral (todos)

egen total_PEL = total(fac), by(year q)
egen total_PEA = total(fac) if clase1==1, by(year q)

gen tasa_participacion = (total_PEA / total_PEL) * 100

****************************************************
 //##### PASO 3: calcular % de trabajadores con ingreso inválido
****************************************************

egen total_workers = total(fac) if clase2==1, by(year q)
egen invalid_income_workers = total(fac) if ing_inv==1 & clase2==1, by(year q)

gen pct_invalid_income = (invalid_income_workers / total_workers) * 100

****************************************************
 //##### PASO 4: colapsar resultados y etiquetar
****************************************************

collapse (mean) pct_invalid_income tasa_participacion, by(year)

label var pct_invalid_income "% de Trabajadores con ingresos inválidos"

****************************************************
 //##### PASO 5: scatter invalidez vs participación
****************************************************

****************************************************
 //##### PASO 6: scatter invalidez vs participación
****************************************************

twoway (scatter pct_invalid_income tasa_participacion, ///
            mcolor("255 69 0") msize(medium) ///
            mlab(year) mlabsize(small) mlabcolor(black)) ///
       (lfit pct_invalid_income tasa_participacion, ///
            lcolor(blue%60) lpattern(dash) lwidth(thin)), ///
       xtitle("% de Trabajadores con ingresos inválidos", size(medium)) ///
       ytitle("Tasa de participación laboral", size(medium)) ///
       legend(order(1 "Observaciones" 2 "Tendencia lineal") position(12) ring(0)) ///
       graphregion(color(white)) plotregion(lstyle(none))

graph export "$graf\POBREZA_6_7.png", replace

//### GRAFICA SCATTER : CAMBIOS ING NO VALIDO VS CAMBIOS TASA DE PARTICIPACION LABORAL


// Preparar diferencias
tsset year
gen d_pct_invalid_income = D.pct_invalid_income
gen d_tasa_participacion = D.tasa_participacion

// Gráfica con formato preferido
twoway (scatter d_pct_invalid_income d_tasa_participacion, ///
            mcolor("255 69 0") msize(medium) ///
            mlab(year) mlabsize(small) mlabcolor(black)), ///
       xtitle("Cambios de % de Trabajadores con ingresos inválidos", size(medium)) ///
       ytitle("Cambios de Tasa de participación laboral", size(medium)) ///
       graphregion(color(white)) plotregion(lstyle(none))

// Exportar
graph export "$graf\POBREZA_6_7_1.png", replace


//### GRAFICA SCATTER : POBREZ LABORAL VS # DE ASALARIADOS

//#### PASO 0 , Preparar bases :

//##### PASO 1. Abrir base ITLP
use "$temp/ITLP.dta", clear

* Extraer año y trimestre desde periodo
gen year = mod(periodo,100) + 2000
gen qtr  = floor(periodo/100)

* Crear variable de fecha trimestral
gen date = yq(year, qtr)

* Aplicar formato de trimestre
format date %tq

* (opcional) borrar auxiliares
drop year qtr

// Quitamos variables que no son entidades
drop Nacional Urbano Rural periodo 

// Mantener solo 2025q2
keep if date == tq(2018q2)

//##### PASO 2. Transponer base
xpose, clear varname

//##### PASO 3. Renombrar variables
rename _varname ent     // nombres de las entidades
rename v1       ipl     // valores de pobreza laboral

//##### PASO 4. Limpiar
drop if missing(ipl)    // quitar filas vacías

//##### PASO 4. Limpiar observaciones
drop if ent == "date"

//##### PASO 5. Crear clave numérica oficial INEGI
gen str2 cve_ent = ""
replace cve_ent = "01" if ent=="Aguascalientes"
replace cve_ent = "02" if ent=="Baja_California"
replace cve_ent = "03" if ent=="Baja_California_Sur"
replace cve_ent = "04" if ent=="Campeche"
replace cve_ent = "05" if ent=="Coahuila"
replace cve_ent = "06" if ent=="Colima"
replace cve_ent = "07" if ent=="Chiapas"
replace cve_ent = "08" if ent=="Chihuahua"
replace cve_ent = "09" if ent=="Ciudad_de_México"
replace cve_ent = "10" if ent=="Durango"
replace cve_ent = "11" if ent=="Guanajuato"
replace cve_ent = "12" if ent=="Guerrero"
replace cve_ent = "13" if ent=="Hidalgo"
replace cve_ent = "14" if ent=="Jalisco"
replace cve_ent = "15" if ent=="Estado_de_México"
replace cve_ent = "16" if ent=="Michoacán"
replace cve_ent = "17" if ent=="Morelos"
replace cve_ent = "18" if ent=="Nayarit"
replace cve_ent = "19" if ent=="Nuevo_León"
replace cve_ent = "20" if ent=="Oaxaca"
replace cve_ent = "21" if ent=="Puebla"
replace cve_ent = "22" if ent=="Querétaro"
replace cve_ent = "23" if ent=="Quintana_Roo"
replace cve_ent = "24" if ent=="San_Luis_Potosí"
replace cve_ent = "25" if ent=="Sinaloa"
replace cve_ent = "26" if ent=="Sonora"
replace cve_ent = "27" if ent=="Tabasco"
replace cve_ent = "28" if ent=="Tamaulipas"
replace cve_ent = "29" if ent=="Tlaxcala"
replace cve_ent = "30" if ent=="Veracruz"
replace cve_ent = "31" if ent=="Yucatán"
replace cve_ent = "32" if ent=="Zacatecas"

//##### PASO 6. Verificar
order cve_ent ent ipl
list in 1/10

//##### PASO 7. Guardar base final lista para mapear
save "$ENOE/ILP_2018q2.dta", replace


//#### PASO 8: IMSS 2018
use "$IMSS_2018\IMSS_2018.dta", clear

// calcular promedio anual de trabajadores asegurados (en lugar de sumarlos)
collapse (mean) ta_sal masa_sal_ta, by(cve_entidad)

gen year = 2018

save "$ENOE\imss2018.dta", replace



//#### PASO 9: IMSS 2025
use "$IMSS_2025\IMSS_2025.dta", clear

// calcular promedio anual de trabajadores asegurados (en lugar de sumarlos)
collapse (mean) ta_sal masa_sal_ta, by(cve_entidad)

gen year = 2025

save "$ENOE\imss2025.dta", replace


//#### PASO 10: Unir 2018 y 2025 IMSS
append using "$ENOE\imss2018.dta"

save "$ENOE\imss2018_2025.dta", replace

//##### PASO 11 MERGE 2018 y 2025 ENOE

***************** 2018 **************
use "$ENOE/ILP_2018q2.dta",clear
gen year= 2018
destring cve_ent, replace
save "$ENOE\enoepoblab2018.dta", replace


***************** 2025 **************
use "$ENOE/ILP_2025q2.dta",clear
gen year= 2025
destring cve_ent, replace
save "$ENOE\enoepoblab2025.dta", replace

***************** 2018-2025 **************

append using "$ENOE\enoepoblab2018.dta"

rename cve_ent cve_entidad

save "$ENOE\enoepoblab2018_2022.dta", replace

********************************************

use "$ENOE\enoepoblab2018_2022.dta", clear

merge m:m year cve_entidad using "$ENOE\imss2018_2025.dta"

drop _merge

//#### PASO 12: Agregar etiquetas y generar cambios interanuales

* Unimos con base de etiquetas de entidades
merge m:1 cve_entidad using "$ENOE\imss_entidades.dta"
drop _merge

* Ordenamos por entidad y año
sort cve_entidad year

//#### PASO 11: Agregar etiquetas y generar cambios interanuales

//#### PASO: Unir solo variable abreviado desde imss_entidades
merge m:1 cve_entidad using "$ENOE\imss_entidades.dta", keepusing(abreviado)
drop _merge

sort cve_entidad year

* Generamos cambios en IPL y variables laborales
by cve_entidad: gen d_ipl = ipl - ipl[_n-1]

by cve_entidad: gen pct_d_masa_sal_ta = ///
    (masa_sal_ta - masa_sal_ta[_n-1]) / masa_sal_ta[_n-1] * 100


by cve_entidad: gen pct_d_ta_sal = ///
    (ta_sal - ta_sal[_n-1]) / ta_sal[_n-1] * 100
	

//#### PASO 12: Scatter entre cambio en pobreza laboral y cambio porcentual en número de asalariados

twoway (scatter d_ipl pct_d_ta_sal, ///
            mcolor("255 69 0") msize(medium) ///
            mlab(abreviado) mlabsize(small) mlabcolor(black)), ///
       xtitle("Cambios % de pobreza laboral", size(medium)) ///
       ytitle("Cambios % de número de asalariados", size(medium)) ///
       graphregion(color(white)) plotregion(lstyle(none)) ///
       legend(position(12) ring(0))

graph export "$graf\POBREZA_6_7_2.png", replace

//#### 13: Scatter pobreza vs ingreso promedio diario
scatter d_ipl pct_d_masa_sal_ta , ///
        mcolor("255 69 0") msize(medium) /// bolitas en naranja metálico
        mlab(abreviado) mlabsize(small) mlabcolor(black) /// etiquetas visibles y negras
        xtitle("Cambios % de pobreza laboral", size(medium)) ///
        ytitle("Cambios % de ingreso promedio diario", size(medium)) ///
        legend(off) ///
        graphregion(color(white)) plotregion(lstyle(none))

// Guardar gráfica
graph export "$graf\POBREZA_6_7_3.png", replace














