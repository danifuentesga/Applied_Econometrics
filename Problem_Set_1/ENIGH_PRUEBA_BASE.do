/******************************************************************************************
* AUTOR:   Daniel Fuentes
* FECHA:   23-ago-2025
* TEMA:    Homologación de bases de datos ENIGH (1992-2024)
* NOTA:    Se trabaja principamente con bases de "CONCENTRADO" Y "POBLACION" de cada año
******************************************************************************************/

/************************************************************************/
/*              HOMOLOGACIÓN DE BASES CONCENTRADO ENIGH                */
/************************************************************************/

/* Paso 1. Definir el entorno de trabajo */
global ENIGH "D:\INVESTIGACION\DATA\ENIGH"

/* Paso 2. Agregar variable de año 'year' a las bases concentrado originales
   y guardarlas con nuevo nombre: concenXXXXv.dta */
foreach x in 1992 1994 1996 1998 2000 2002 2004 2005 2006 2008 2010 2012 2014 2016 2018 2020 2022 2024 {
    use "$ENIGH/`x'/concentrado_`x'.dta", clear
    gen year = `x'
    save "$ENIGH/`x'/concen`x'v.dta", replace
}

/* Paso 3. Homologación de variables por año */

/*** Bases de 1992 a 2006 (sin educación en algunos casos) ***/
foreach x in 1992 1994 1996 1998 2000 2002 {
    use "$ENIGH/`x'/concen`x'v.dta", clear
    keep folio ubica_geo estrato hog edad n_ocup year
    rename (folio ubica_geo estrato hog edad n_ocup) ///
           (foliohog ubica_geo tam_loc factor edad_jefe ocupados)
    gen folio = foliohog
    quietly tostring folio foliohog ubica_geo tam_loc year factor edad_jefe ocupados, replace
    save "$ENIGH/`x'/concen`x'v.dta", replace
}

/*** Bases 2004–2006 (ya incluyen educación) ***/
foreach x in 2004 2005 2006 {
    use "$ENIGH/`x'/concen`x'v.dta", clear
    keep folio ubica_geo estrato hog edad ed_formal n_ocup year
    rename (folio ubica_geo estrato hog edad ed_formal n_ocup) ///
           (foliohog ubica_geo tam_loc factor edad_jefe educa_jefe ocupados)
    gen folio = foliohog
    quietly tostring folio foliohog ubica_geo year tam_loc factor edad_jefe educa_jefe ocupados, replace
    save "$ENIGH/`x'/concen`x'v.dta", replace
}

/*** Bases 2008 y 2010: concatenan foliohog + folioviv para crear folio único ***/
foreach x in 2008 2010 {
    use "$ENIGH/`x'/concen`x'v.dta", clear
    keep foliohog folioviv ubica_geo estrato factor sexo edad ed_formal n_ocup year
    rename (estrato factor sexo edad ed_formal n_ocup) ///
           (tam_loc factor sexo_jefe edad_jefe educa_jefe ocupados)
    label values tam_loc sexo_jefe educa_jefe ocupados .
    tostring foliohog folioviv tam_loc factor sexo_jefe edad_jefe educa_jefe ocupados year, replace
    gen folio = folioviv + foliohog
    save "$ENIGH/`x'/concen`x'v.dta", replace
}

/*** Bases 2012 y 2014: cambiar nombre de factor_hog a factor ***/
foreach x in 2012 2014 {
    use "$ENIGH/`x'/concen`x'v.dta", clear
    keep foliohog folioviv ubica_geo tam_loc factor_hog sexo_jefe edad_jefe educa_jefe ocupados year
    rename factor_hog factor
    tostring foliohog folioviv ubica_geo tam_loc factor sexo_jefe edad_jefe educa_jefe ocupados year, replace
    gen folio = folioviv + foliohog
    save "$ENIGH/`x'/concen`x'v.dta", replace
}

/*** Bases 2016–2024: ya con nombres estándar ***/
foreach x in 2016 2018 2020 2022 2024 {
    use "$ENIGH/`x'/concen`x'v.dta", clear
    keep foliohog folioviv ubica_geo tam_loc factor sexo_jefe edad_jefe educa_jefe ocupados year
    tostring foliohog folioviv ubica_geo tam_loc factor sexo_jefe edad_jefe educa_jefe ocupados year, replace
    gen folio = folioviv + foliohog
    save "$ENIGH/`x'/concen`x'v.dta", replace
}

/************************************************************************/
/*                  HOMOLOGACIÓN DE BASES POBLACIÓN                     */
/************************************************************************/

/* Paso 1. Agregar variable de año y renombrar archivos a poblaXXXXv.dta */
foreach x in 1992 1994 1996 1998 2000 2002 2004 2005 2006 2008 2010 2012 2014 2016 2018 2020 2022 2024 {
    use "$ENIGH/`x'/poblacion_`x'.dta", clear
    gen year = `x'
    save "$ENIGH/`x'/pobla`x'v.dta", replace
}

/*** Homologación 1992–2006 (algunos años sin variables adicionales) ***/
foreach x in 1992 1994 1996 1998 2000 2002 {
    use "$ENIGH\\`x'\\pobla`x'v.dta", clear
    if `x' == 1992 {
        rename (numren edad sexo ed_formal trab_m_p) ///
               (numren edad sexo nivelaprob trabajo_mp)
        keep folio numren edad sexo nivelaprob trabajo_mp year
    }
    else if `x' == 1994 {
        rename (num_ren edad sexo ed_formal trabajo) ///
               (numren edad sexo nivelaprob trabajo_mp)
        keep folio numren edad sexo nivelaprob trabajo_mp year
    }
    else {
        rename (num_ren edad sexo ed_formal trabajo edo_civil) ///
               (numren edad sexo nivelaprob trabajo_mp edo_conyug)
        keep folio numren edad sexo nivelaprob trabajo_mp edo_conyug year
    }
    tostring *, replace
    save "$ENIGH\\`x'\\pobla`x'v.dta", replace
}

/*** Homologación 2004–2006 con hijos sobrevivientes ***/
foreach x in 2004 2005 {
    use "$ENIGH\\`x'\\pobla`x'v.dta", clear
    rename (num_ren edad sexo n_instr161 trabajo edocony h_sobrev) ///
           (numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob)
    keep folio numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob year
    tostring *, replace
    save "$ENIGH\\`x'\\pobla`x'v.dta", replace
}
use "$ENIGH\\2006\\pobla2006v.dta", clear
rename (num_ren edad sexo n_instr141 trabajo edocony h_sobrev) ///
       (numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob)
keep folio numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob year
tostring *, replace
save "$ENIGH\\2006\\pobla2006v.dta", replace

/*** Homologación 2008 y 2010: se crea folio compuesto y se renombran ***/
foreach x in 2008 2010 {
    use "$ENIGH\\`x'\\pobla`x'v.dta", clear
    if `x' == 2008 {
        rename (foliohog folioviv numren edad sexo n_instr161 trabajo edocony hijos_sob) ///
               (foliohog folioviv numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob)
        label value sexo nivelaprob edo_conyug hijos_sob trabajo_mp .
    }
    else {
        rename (foliohog folioviv numren edad sexo nivelaprob trabajo edocony hijos_sob) ///
               (foliohog folioviv numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob)
        label value edad hijos_sob .
    }
    tostring *, replace
    gen folio = folioviv + foliohog
    keep folio numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob year
    save "$ENIGH\\`x'\\pobla`x'v.dta", replace
}

/*** Homologación 2012–2024 con loop generalizado ***/
forvalues x = 2012(2)2024 {
    use "$ENIGH\\`x'\\pobla`x'v.dta", clear
    tostring *, replace
    gen folio = folioviv + foliohog
    keep folio numren edad sexo nivelaprob trabajo_mp edo_conyug hijos_sob year
    save "$ENIGH\\`x'\\pobla`x'v.dta", replace
}

/************************************************************************/
/*                MERGE POR AÑO – NIVEL HOGAR Y TRABAJADOR             */
/************************************************************************/

/*** Merge nivel hogar: solo el jefe (numren == "01") ***/
foreach x in 1992 1994 1996 1998 2000 2002 2004 2005 2006 2008 2010 2012 2014 2016 2018 2020 2022 2024 {
    use "$ENIGH\\`x'\\pobla`x'v.dta", clear
    keep if numren == "01"
    save "$ENIGH\\`x'\\pobla`x'm.dta", replace

    use "$ENIGH\\`x'\\concen`x'v.dta", clear
    order folio
    sort folio
    merge 1:1 folio using "$ENIGH\\`x'\\pobla`x'm.dta"
    save "$ENIGH\\`x'\\baseporhogares`x'.dta", replace
}

/*** Merge nivel individuo: todos los registros ***/
foreach x in 1992 1994 1996 1998 2000 2002 2004 2005 2006 2008 2010 2012 2014 2016 2018 2020 2022 2024 {
    use "$ENIGH\\`x'\\pobla`x'v.dta", clear
    order folio
    sort folio
    merge m:1 folio using "$ENIGH\\`x'\\concen`x'v.dta"
    save "$ENIGH\\`x'\\baseportrabajadores`x'.dta", replace
}

/************************************************************************/
/*                      APPEND FINAL: HOGARES E INDIVIDUOS              */
/************************************************************************/

/* Append final de hogares */
use "$ENIGH\\1992\\baseporhogares1992.dta", clear
foreach x in 1994 1996 1998 2000 2002 2004 2005 2006 2008 2010 2012 2014 2016 2018 2020 2022 2024 {
    append using "$ENIGH\\`x'\\baseporhogares`x'", force
    save "$ENIGH\\enighhogaresf.dta", replace
}
clear

/* Append final de individuos */
use "$ENIGH\\1992\\baseportrabajadores1992.dta", clear
foreach x in 1994 1996 1998 2000 2002 2004 2005 2006 2008 2010 2012 2014 2016 2018 2020 2022 2024 {
    append using "$ENIGH\\`x'\\baseportrabajadores`x'.dta", force
    save "$ENIGH\\enightrabajadores.dta", replace
}
clear


/****************************************************************************************/
/*                                  PREGUNTA 4 – ENIGH                                  */
/*     Filtrado y tabulación de variables clave desde ENIGH para generación de tablas  */
/****************************************************************************************/

// Cargar base de individuos
use "$ENIGH\\enightrabajadores.dta", clear

// Definir carpeta de salida para resultados
global graf "D:\INVESTIGACION\DATA\ENIGH\TABLAS"


/****************************************************************************************/
/*                              TABLA 1 – Hogares e Individuos                          */
/****************************************************************************************/

// Asegurar formato numérico de las variables
destring year factor ocupado numren trabajo_mp edad nivelaprob tam_loc sexo hijos_sob edo_conyug, replace

// Conteo rápido para referencia
tab year [fw=factor]
tab year if numren == 01 [fw=factor]

// Crear indicadores
gen ind = 1
gen hog = .
replace hog = 1 if numren == 01
label variable ind "Individuos"
label variable hog "Hogares"

// ---- Exportar a Excel ----
preserve
collect: table year, statistic(total ind hog) nototals, [fw=factor]
putexcel set "$graf\Tabla_1", sheet(g1) modify
putexcel A2 = collect
restore

// Limitar a personas en edad productiva
keep if edad >= 20 & edad <= 65

// ---- Exportar a LaTeX ----
preserve
destring factor, replace force
collapse (sum) ind hog [fw=factor], by(year)

file open tabla using "$graf\Tabla_1.tex", write replace
file write tabla "%% Tabla generada desde Stata - Número de hogares e individuos ENIGH" _n
file write tabla "\begin{tabular}{lrr}" _n
file write tabla "\hline" _n
file write tabla "Año & Hogares (exp.) & Personas (exp.) \\\\" _n
file write tabla "\hline" _n

quietly {
    forvalues i = 1/`=_N' {
        local y = year[`i']
        local h = string(hog[`i'], "%15.0fc")
        local p = string(ind[`i'], "%15.0fc")
        file write tabla "`y' & `h' & `p' \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla
restore


/****************************************************************************************/
/*                              TABLA 2 – Nivel de Educación                            */
/****************************************************************************************/

// Homologación de variable "educacion" por año y codificación
gen educacion = .

// Sin instrucción
replace educacion = 0 if nivelaprob == 0 & inrange(year, 1992, 1994)
replace educacion = 0 if inrange(nivelaprob,0,1) & year == 1996
replace educacion = 0 if inrange(nivelaprob,1,2) & inrange(year, 1998, 2002)
replace educacion = 0 if inrange(nivelaprob,0,1) & inrange(year, 2004, 2024)

// Primaria
replace educacion = 1 if inrange(nivelaprob,1,2) & inrange(year, 1992, 1994)
replace educacion = 1 if inrange(nivelaprob,2,7) & year == 1996
replace educacion = 1 if inrange(nivelaprob,3,8) & inrange(year, 1998, 2002)
replace educacion = 1 if nivel == 2 & inrange(year, 2004, 2024)

// Secundaria
replace educacion = 2 if inrange(nivelaprob,3,4) & inrange(year, 1992, 1994)
replace educacion = 2 if inrange(nivelaprob,8,10) & year == 1996
replace educacion = 2 if inrange(nivelaprob,9,11) & inrange(year, 1998, 2002)
replace educacion = 2 if nivel == 3 & inrange(year, 2004, 2024)

// Media superior
replace educacion = 3 if inrange(nivelaprob,5,6) & inrange(year, 1992, 1994)
replace educacion = 3 if inrange(nivelaprob,11,12) & year == 1996
replace educacion = 3 if inrange(nivelaprob,12,13) & inrange(year, 1998, 2000)
replace educacion = 3 if inrange(nivelaprob,12,20) & year == 2002
replace educacion = 3 if inrange(nivelaprob,4,6) & inrange(year, 2004, 2024)

// Superior
replace educacion = 4 if inrange(nivelaprob,7,8) & inrange(year, 1992, 1994)
replace educacion = 4 if inrange(nivelaprob,13,14) & year == 1996
replace educacion = 4 if inrange(nivelaprob,14,15) & inrange(year, 1998, 2000)
replace educacion = 4 if inrange(nivelaprob,21,31) & year == 2002
replace educacion = 4 if nivel == 7 & inrange(year, 2004, 2024)

// Posgrado
replace educacion = 5 if nivelaprob == 9 & inrange(year, 1992, 1994)
replace educacion = 5 if nivelaprob == 15 & year == 1996
replace educacion = 5 if nivelaprob == 16 & inrange(year, 1998, 2000)
replace educacion = 5 if nivelaprob >= 32 & year == 2002
replace educacion = 5 if nivelaprob >= 8 & inrange(year, 2004, 2024)

// Faltantes
replace educacion = . if nivelaprob == .

// Etiquetas
label define educn 0 "Sin instrucción" 1 "Primaria" 2 "Secundaria" 3 "Media Superior" 4 "Superior" 5 "Posgrado"
label values educacion educn
label variable educacion "Nivel de educación"

// ---- Exportar a Excel ----
collect: table year, statistic(fvpercent educacion) nototals, [fw=factor]
putexcel set "$graf\Tabla_2", sheet(g2) modify
putexcel A2 = collect

// ---- Exportar a LaTeX ----
preserve
destring factor, replace force
capture confirm variable ind
if _rc gen ind = 1
collapse (sum) personas=ind [fw=factor], by(year educacion)
bys year: egen tot = total(personas)
gen pct = 100*personas/tot

file open tabla using "$graf\Tabla_2.tex", write replace
file write tabla "%% Tabla generada desde Stata - Distribución educativa ENIGH (porcentaje)" _n
file write tabla "\begin{tabular}{lrrrrrr}" _n
file write tabla "\hline" _n
file write tabla "Año & Sin instrucción & Primaria & Secundaria & Media Superior & Superior & Posgrado \\\\" _n
file write tabla "\hline" _n

quietly {
    levelsof year, local(anios)
    foreach y of local anios {
        local fila "`y'"
        foreach e in 0 1 2 3 4 5 {
            quietly summarize pct if year==`y' & educacion==`e'
            local val = cond(r(N)>0, string(r(mean), "%5.1f"), "0.0")
            local fila "`fila' & `val'\%"
        }
        file write tabla "`fila' \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla
restore


/****************************************************************************************/
/*                              TABLA 3 – POBLACIÓN OCUPADA                             */
/****************************************************************************************/

// Crear variable 'ocupado' para identificar población ocupada
gen ocupado = 0

// Año 1992 y 2004 en adelante: trabajo_mp == 1 indica ocupado
replace ocupado = 1 if trabajo_mp == 1 & year >= 2004
replace ocupado = 1 if trabajo_mp == 1 & year == 1992

// Valores faltantes
replace ocupado = . if trabajo_mp == .

// Entre 1994 y 2002: se considera ocupado si trabajo_mp != 0
replace ocupado = 1 if trabajo_mp != 0 & year > 1992 & year < 2004

// Excluir ciertos códigos como no ocupados
replace ocupado = 0 if trabajo_mp == 2 | trabajo_mp == 222
replace ocupado = 0 if trabajo_mp >= 22211

// Etiquetas descriptivas
label define ocupadoe 0 "No ocupado" 1 "Ocupado"
label values ocupado ocupadoe, nofix
label variable ocupado "Situación laboral"

// Revisión rápida de proporciones
tab year ocupado [fw=factor], nofreq row

// ---- Exportar a Excel ----
collect: table year, statistic(fvpercent ocupado) nototals, [fw=factor]
putexcel set "$graf\Tabla_3", sheet(g3) modify
putexcel A2 = collect

// ---- Exportar a LaTeX ----
preserve

// Asegurar ponderador numérico
destring factor, replace force

// Generar variable constante para conteo
gen __uno = 1

// Colapsar por año y situación laboral
collapse (sum) personas=__uno [fw=factor], by(year ocupado)

// Calcular porcentaje por año
bysort year: egen tot = total(personas)
gen pct = 100 * personas / tot

// Crear archivo .tex
file open tabla using "$graf\Tabla_3.tex", write replace
file write tabla "%% Tabla generada desde Stata - Porcentaje que trabaja (ENIGH)" _n
file write tabla "\begin{tabular}{lrr}" _n
file write tabla "\hline" _n
file write tabla "Año & No ocupado (\%) & Ocupado (\%) \\\\" _n
file write tabla "\hline" _n

// Escribir líneas por año
quietly {
    levelsof year, local(anios)
    foreach y of local anios {
        summarize pct if year == `y' & ocupado == 0
        local p0 = cond(r(N) > 0, string(r(mean), "%5.1f"), "0.0")

        summarize pct if year == `y' & ocupado == 1
        local p1 = cond(r(N) > 0, string(r(mean), "%5.1f"), "0.0")

        file write tabla "`y' & `p0'\% & `p1'\% \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore


/****************************************************************************************/
/*                             TABLA 4 – SECTOR RURAL / URBANO                          */
/****************************************************************************************/

// Crear variable binaria para sector rural (tam_loc == 4)
gen rural = 0
replace rural = 1 if tam_loc == 4

// Etiquetado y descripción
label define rurale 0 "Urbano" 1 "Rural"
label values rural rurale, nofix
label variable rural "Tipo de localidad"

// Verificación rápida
tab year rural [fw=factor], nofreq row

// ---- Exportar a Excel ----
collect: table year, statistic(fvpercent rural) nototals, [fw=factor]
putexcel set "$graf\Tabla_4.xlsx", sheet(g4) modify
putexcel A2 = collect

// ---- Exportar a LaTeX ----
preserve

// Asegurar ponderador numérico
destring factor, replace force

// Crear constante para conteo
gen __uno = 1

// Colapsar por año y sector
collapse (sum) personas=__uno [fw=factor], by(year rural)

// Calcular porcentaje por año
bysort year: egen tot = total(personas)
gen pct = 100 * personas / tot

// Crear archivo .tex
file open tabla using "$graf\Tabla_4.tex", write replace
file write tabla "%% Tabla generada desde Stata - Porcentaje en sector rural ENIGH" _n
file write tabla "\begin{tabular}{lrr}" _n
file write tabla "\hline" _n
file write tabla "Año & Urbano (\%) & Rural (\%) \\\\" _n
file write tabla "\hline" _n

// Escribir líneas por año
quietly {
    levelsof year, local(anios)
    foreach y of local anios {
        summarize pct if year == `y' & rural == 0
        local urbano = cond(r(N) > 0, string(r(mean), "%5.1f"), "0.0")

        summarize pct if year == `y' & rural == 1
        local rural = cond(r(N) > 0, string(r(mean), "%5.1f"), "0.0")

        file write tabla "`y' & `urbano'\% & `rural'\% \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore


/****************************************************************************************/
/*                        TABLA 5 – SITUACIÓN LABORAL DE MUJERES                        */
/****************************************************************************************/

// ---- Exportar a Excel ----
preserve

// Filtrar sólo mujeres (sexo == 2)
keep if sexo == 2

// Generar tabla de porcentaje ocupado/no ocupado (solo mujeres)
collect: table year, statistic(fvpercent ocupado) nototals, [fw=factor]
putexcel set "$graf\Tabla_5.xlsx", sheet(g5) modify
putexcel A2 = collect

restore

// ---- Exportar a LaTeX ----
preserve

// Filtrar mujeres
keep if sexo == 2

// Convertir ponderador a numérico por seguridad
destring factor, replace force

// Generar variable constante para el conteo
gen __uno = 1

// Sumar personas por año y situación laboral
collapse (sum) personas=__uno [fw=factor], by(year ocupado)

// Calcular porcentajes
bysort year: egen tot = total(personas)
gen pct = 100 * personas / tot

// Crear archivo .tex
file open tabla using "$graf\Tabla_5.tex", write replace
file write tabla "%% Tabla generada desde Stata - Situación laboral de mujeres (ENIGH)" _n
file write tabla "\begin{tabular}{lrr}" _n
file write tabla "\hline" _n
file write tabla "Año & No ocupadas (\%) & Ocupadas (\%) \\\\" _n
file write tabla "\hline" _n

// Escribir fila por año
quietly {
    levelsof year, local(anios)
    foreach y of local anios {
        summarize pct if year == `y' & ocupado == 0
        local noocc = cond(r(N) > 0, string(r(mean), "%5.1f"), "0.0")

        summarize pct if year == `y' & ocupado == 1
        local occ = cond(r(N) > 0, string(r(mean), "%5.1f"), "0.0")

        file write tabla "`y' & `noocc'\% & `occ'\% \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore



/****************************************************************************************/
/*                  TABLA 6 – NIVEL DE EDUCACIÓN DE MUJERES OCUPADAS                   */
/****************************************************************************************/

// ---- Exportar a Excel ----
preserve

// Filtrar mujeres ocupadas
keep if sexo == 2
keep if ocupado == 1

// Tabla de distribución de nivel educativo (mujeres ocupadas)
collect: table year, statistic(fvpercent educacion) nototals, [fw=factor]
putexcel set "$graf\Tabla_6.xlsx", sheet(g6) modify
putexcel A2 = collect

restore

// ---- Exportar a LaTeX ----
preserve

// Filtrar mujeres ocupadas
keep if sexo == 2
keep if ocupado == 1

// Asegurar ponderador numérico
destring factor, replace force

// Variable para conteo
gen __uno = 1

// Agrupar por año y nivel educativo
collapse (sum) personas=__uno [fw=factor], by(year educacion)

// Calcular porcentajes por año
bysort year: egen tot = total(personas)
gen pct = 100 * personas / tot

// Crear archivo .tex
file open tabla using "$graf\Tabla_6.tex", write replace
file write tabla "%% Tabla generada desde Stata - Distribución educativa de mujeres ocupadas (ENIGH)" _n
file write tabla "\begin{tabular}{lrrrrrr}" _n
file write tabla "\hline" _n
file write tabla "Año & Sin instrucción & Primaria & Secundaria & Media Superior & Superior & Posgrado \\\\" _n
file write tabla "\hline" _n

// Escribir cada fila por año
quietly {
    levelsof year, local(anios)
    foreach y of local anios {
        local fila "`y'"
        foreach e in 0 1 2 3 4 5 {
            summarize pct if year == `y' & educacion == `e'
            local val = cond(r(N) > 0, string(r(mean), "%5.1f"), "0.0")
            local fila "`fila' & `val'\%"
        }
        file write tabla "`fila' \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore



/****************************************************************************************/
/*                        TABLA 7 – ESTADO CIVIL DE MUJERES OCUPADAS                   */
/****************************************************************************************/

// ---- Limpieza y homogeneización del estado civil ----

// Guardamos el valor original en una variable auxiliar
gen edo2 = edo_conyug

// Reasignamos los códigos de estado civil para ciertos años según estructura de ENIGH
replace edo_conyug = 2 if edo2 == 5 & inrange(year, 2004, 2008)  // Viuda -> Casada
replace edo_conyug = 3 if edo2 == 2 & inrange(year, 2004, 2008)  // Casada -> Separada
replace edo_conyug = 4 if edo2 == 3 & inrange(year, 2004, 2008)  // Separada -> Divorciada
replace edo_conyug = 5 if edo2 == 4 & inrange(year, 2004, 2008)  // Divorciada -> Viuda

// Reemplazamos ceros como datos perdidos
replace edo_conyug = . if edo2 == 0

// Eliminamos variable auxiliar
drop edo2

// Etiquetamos los valores del estado civil
label define conyue 1 "Union libre" 2 "Casada" 3 "Separada" 4 "Divorciada" 5 "Viuda" 6 "Soltera"
label values edo_conyug conyue, nofix
label variable edo_conyug "Estado Civil"

// ---- Exportar a Excel ----
preserve

// Filtrar mujeres ocupadas desde 1996
keep if sexo == 2
keep if ocupado == 1 & year >= 1996

// Tabla en formato Excel
collect: table year, statistic(fvpercent edo_conyug) nototals, [fw=factor]
putexcel set "$graf\Tabla_7.xlsx", sheet(g7) modify
putexcel A2 = collect

restore

// ---- Exportar a LaTeX ----
preserve

// Filtrar mujeres ocupadas desde 1996
keep if sexo == 2
keep if ocupado == 1 & year >= 1996

// Convertir factor a numérico por seguridad
destring factor, replace force

// Crear constante para conteo
gen __uno = 1

// Agrupar por año y estado civil
collapse (sum) personas=__uno [fw=factor], by(year edo_conyug)

// Calcular porcentajes por año
bys year: egen tot = total(personas)
gen pct = 100 * personas / tot

// Abrir archivo .tex
file open tabla using "$graf\Tabla_7.tex", write replace
file write tabla "%% Tabla generada desde Stata - Estado civil de mujeres ocupadas (ENIGH)" _n
file write tabla "\begin{tabular}{lrrrrrr}" _n
file write tabla "\hline" _n
file write tabla "Año & Unión libre & Casada & Separada & Divorciada & Viuda & Soltera \\\\" _n
file write tabla "\hline" _n

// Escribir cada fila por año
quietly {
    levelsof year, local(anios)
    foreach y of local anios {
        local fila "`y'"
        foreach e in 1 2 3 4 5 6 {
            summarize pct if year == `y' & edo_conyug == `e'
            local val = cond(r(N) > 0, string(r(mean), "%5.1f"), "0.0")
            local fila "`fila' & `val'\%"
        }
        file write tabla "`fila' \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore


/****************************************************************************************/
/*                              TABLA 8 – CONDICIÓN DE HIJOS                            */
/****************************************************************************************/

// ---- Crear variable "hijos" binaria ----
gen hijos = .

// Clasificamos como "tiene hijos" si hijos_sob es mayor a 0 y no es missing
replace hijos = 1 if hijos_sob > 0 & hijos_sob != .

// Clasificamos como "no tiene hijos"
replace hijos = 0 if hijos_sob == 0

// Asignamos 0 (sin hijos) si falta el dato pero el año es reciente
replace hijos = 0 if hijos_sob == . & year >= 2008

// Etiquetamos los valores
label define lhijos 0 "No tiene hijos" 1 "Tiene Hijos"
label values hijos lhijos, nofix
label variable hijos "Número de hijos"

// ---- Exportar a Excel ----
preserve

// Filtrar mujeres ocupadas desde 2004
keep if sexo == 2 & ocupado == 1 & year >= 2004

// Generar tabla de porcentaje de mujeres con/sin hijos
collect: table year, statistic(fvpercent hijos) nototals, [fw=factor]
putexcel set "$graf\Tabla_8.xlsx", sheet(g8) modify
putexcel A2 = collect

restore

// ---- Exportar a LaTeX ----
preserve

// Filtrar mujeres ocupadas desde 2004
keep if sexo == 2 & ocupado == 1 & year >= 2004

// Convertimos factor a numérico por seguridad
destring factor, replace force

// Variable para conteo
gen __uno = 1

// Agrupar por año y condición de hijos
collapse (sum) personas=__uno [fw=factor], by(year hijos)

// Calcular porcentajes
bysort year: egen tot = total(personas)
gen pct = 100 * personas / tot

// Crear archivo .tex
file open tabla using "$graf\Tabla_8.tex", write replace
file write tabla "%% Tabla generada desde Stata - Hijos de mujeres ocupadas (ENIGH)" _n
file write tabla "\begin{tabular}{lrr}" _n
file write tabla "\hline" _n
file write tabla "Año & No tiene hijos (\%) & Tiene hijos (\%) \\\\" _n
file write tabla "\hline" _n

// Escribir filas por año
quietly {
    levelsof year, local(anios)
    foreach y of local anios {
        summarize pct if year == `y' & hijos == 0
        local no = cond(r(N)>0, string(r(mean), "%5.1f"), "0.0")

        summarize pct if year == `y' & hijos == 1
        local si = cond(r(N)>0, string(r(mean), "%5.1f"), "0.0")

        file write tabla "`y' & `no'\% & `si'\% \\\\" _n
    }
}

file write tabla "\hline" _n
file write tabla "\end{tabular}" _n
file close tabla

restore


/****************************************************************************************/
/*  GRAFICA 1 – NÚMERO DE INDIVIDUOS Y HOGARES EN LA ENIGH (esquema: The Economist)    */
/****************************************************************************************/

preserve

*--- Activar esquema "The Economist" (instala si no existe) ---
capture noisily set scheme economist
if _rc {
    ssc install schemepack, replace
    set scheme economist
}

* Colapsar datos a nivel anual con suma de individuos y hogares
collapse (sum) ind hog [fw=factor], by(year)

* Crear variable de fecha tipo trimestre (Trimestre 1 de cada año)
gen fecha_yq = yq(year, 1)
format fecha_yq %tq

* Crear variables en millones para visualización
gen ind2 = ind / 1000000
gen hog2 = hog / 1000000

* Etiquetas para el gráfico
label variable ind2 "Individuos"
label variable hog2 "Hogares"

* Gráfico de líneas (ajustado para Economist)
twoway ///
    (line ind2 fecha_yq, lwidth(thick)) ///
    (line hog2 fecha_yq, lwidth(thick)), ///
    title("Número de hogares e individuos en la ENIGH", size(large)) ///
    subtitle("1992–2024", size(medlarge)) ///
    xtitle("Trimestres", size(medium)) ///
    ytitle("Millones", size(medium)) ///
    xlabel(, format(%tq) labsize(medium)) ///
    ylabel(, labsize(medium)) ///
    legend(order(1 "Individuos" 2 "Hogares") ///
           cols(1) size(medium) ring(0) pos(10)) ///
    xscale(range(`=fecha_yq[1]-1' `=fecha_yq[_N]')) ///
    graphregion(margin(l+4)) ///
    xsize(8) ysize(5)

* Exportar gráfico
graph export "$graf\Grafica_NUMR_HOG_IND_ENIGH.png", replace

restore




/****************************************************************************************/
/*                         GRAFICA 2 – NIVEL EDUCATIVO EN LA ENIGH                      */
/****************************************************************************************/

preserve

*--- Activar esquema "The Economist" (instala si no existe) ---
capture noisily set scheme economist
if _rc {
    ssc install schemepack, replace
    set scheme economist
}

* Crear variables dummies para cada nivel educativo
quietly tab educacion, gen(edu_)

* Colapsar para obtener porcentaje promedio por año
collapse (mean) edu_1 edu_2 edu_3 edu_4 edu_5 edu_6 [fw=factor], by(year)

* Convertir proporciones a porcentajes
foreach var of varlist edu_1 edu_2 edu_3 edu_4 edu_5 edu_6 {
    replace `var' = `var' * 100
}

* Crear variable de fecha tipo trimestre
gen fecha_yq = yq(year, 1)
format fecha_yq %tq

* Etiquetas de cada nivel educativo
label variable edu_1 "Sin instrucción"
label variable edu_2 "Primaria"
label variable edu_3 "Secundaria"
label variable edu_4 "Media Superior"
label variable edu_5 "Superior"
label variable edu_6 "Posgrado"

*--- Gráfico de líneas con estilo Economist ---
twoway ///
    (line edu_1 fecha_yq, lcolor("228 26 28") lwidth(thick)) /// Rojo
    (line edu_2 fecha_yq, lcolor("55 126 184") lwidth(thick)) /// Azul
    (line edu_3 fecha_yq, lcolor("77 175 74") lwidth(thick))  /// Verde
    (line edu_4 fecha_yq, lcolor("255 127 0") lwidth(thick))  /// Naranja
    (line edu_5 fecha_yq, lcolor("152 78 163") lwidth(thick)) /// Púrpura
    (line edu_6 fecha_yq, lcolor("166 86 40") lwidth(thick)), /// Marrón
    ///
    title("Distribución Educativa en la ENIGH", size(large)) ///
    subtitle("Porcentaje por nivel de instrucción, 1992–2024", size(medlarge)) ///
    xtitle("Trimestres", size(medium)) ///
    ytitle("%", size(medium)) ///
    xlabel(, labsize(medium) format(%tq)) ///
    ylabel(, labsize(medium)) ///
    legend(order(1 "Sin instrucción" 2 "Primaria" 3 "Secundaria" 4 "Media Superior" 5 "Superior" 6 "Posgrado") ///
           cols(1) rows(1) size(small) ring(1) pos(6)) ///
    xscale(range(`=fecha_yq[1]-1' `=fecha_yq[_N]')) ///
    graphregion(margin(l+4)) ///
    xsize(8) ysize(5)

* Exportar imagen
graph export "$graf\Grafica_EDUCACION_ENIGH.png", replace

restore


/****************************************************************************************/
/*                         GRAFICA 3 – PERSONAS OCUPADAS EN LA ENIGH                   */
/****************************************************************************************/

preserve

*--- Activar esquema "The Economist" (instala si no existe) ---
capture noisily set scheme economist
if _rc {
    ssc install schemepack, replace
    set scheme economist
}

* Calcular porcentaje promedio de personas ocupadas por año
collapse (mean) ocupado [fw=factor], by(year)
replace ocupado = ocupado * 100
label variable ocupado "Trabaja"

* Crear variable de fecha tipo trimestre
gen fecha_yq = yq(year, 1)
format fecha_yq %tq

*--- Gráfico de línea estilo Economist ---
twoway ///
    (line ocupado fecha_yq, lcolor("38 93 140") lwidth(thick)), ///
    title("Personas que Trabajan en la ENIGH", size(large)) ///
    subtitle("Porcentaje de ocupación, 1992–2024", size(medlarge)) ///
    xtitle("Trimestres", size(medium)) ///
    ytitle("%", size(large)) ///
    xlabel(, labsize(large) format(%tq)) ///
    ylabel(, labsize(medium)) ///
    legend(order(1 "Trabaja") ///
           cols(1) rows(1) size(small) ring(1) pos(6)) ///
    xscale(range(`=fecha_yq[1]-1' `=fecha_yq[_N]')) ///
    graphregion(margin(l+4)) ///
    xsize(8) ysize(5)

* Exportar imagen
graph export "$graf\Grafica_OCUPADO_ENIGH.png", replace

restore


/****************************************************************************************/
/*                             GRAFICA 4 – SECTOR RURAL EN LA ENIGH                     */
/****************************************************************************************/

preserve

*--- Activar esquema "The Economist" (instala si no existe) ---
capture noisily set scheme economist
if _rc {
    ssc install schemepack, replace
    set scheme economist
}

* Crear variable de fecha trimestral (Trimestre 1 de cada año)
gen fecha_yq = yq(year, 1)
format fecha_yq %tq

* Calcular porcentaje promedio de población rural por año
collapse (mean) rural [fw=factor], by(fecha_yq)
replace rural = rural * 100
label variable rural "Rural"

*--- Gráfico de línea estilo Economist ---
twoway ///
    (line rural fecha_yq, lcolor("38 93 140") lwidth(thick)), ///
    title("Población Rural en la ENIGH", size(large)) ///
    subtitle("Porcentaje por trimestre (T1), 1992–2024", size(medlarge)) ///
    xtitle("Trimestres", size(medium)) ///
    ytitle("%", size(medium)) ///
    xlabel(, format(%tq) labsize(medium)) ///
    ylabel(, labsize(medium)) ///
    legend(order(1 "Rural") ///
           cols(1) rows(1) size(small) ring(1) pos(6)) ///
    xscale(range(`=fecha_yq[1]-1' `=fecha_yq[_N]')) ///
    graphregion(margin(l+4)) ///
    xsize(8) ysize(5)

* Exportar gráfico
graph export "$graf\Grafica_RURAL_ENIGH.png", replace

restore



/****************************************************************************************/
/*                    GRAFICA 5 – SITUACIÓN LABORAL DE MUJERES EN LA ENIGH             */
/****************************************************************************************/

preserve

// ---- Filtrar solo mujeres ----
keep if sexo == 2

// Crear variable de fecha tipo trimestre (Trimestre 1)
gen fecha_yq = yq(year, 1)
format fecha_yq %tq

// ---- Crear variables dummies para la variable de ocupación ----
quietly tab ocupado, gen(ocu_)

// Calcular proporción promedio por trimestre
collapse (mean) ocu_1 ocu_2 [fw=factor], by(fecha_yq)

// Convertir a porcentajes
replace ocu_1 = ocu_1 * 100
replace ocu_2 = ocu_2 * 100

// Etiquetas de las variables para el gráfico
label variable ocu_1 "No trabaja"
label variable ocu_2 "Trabaja"

// ---- Gráfico de líneas con fondo blanco y colores diferenciados ----
twoway ///
(line ocu_1 fecha_yq, lcolor(red) lwidth(vthick)) ///
(line ocu_2 fecha_yq, lcolor(blue) lwidth(vthick)), ///
    title("Mujeres ocupadas en la ENIGH", size(large) color(black) pos(11)) ///
    subtitle("Porcentaje por trimestre (T1), 1992–2024", size(medsmall) color(gs6) pos(11)) ///
    xtitle("Trimestre", size(5)) ///
    ytitle("%", size(5)) ///
    xlabel(, format(%tq) labsize(5)) ///
    ylabel(, labsize(5)) ///
    legend(order(1 "No trabaja" 2 "Trabaja") ///
           placement(south outside) cols(1) size(5) region(lcolor(none))) ///
    note(" ", size(vsmall)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    xsize(8) ysize(4)

// ---- Exportar imagen ----
graph export "$graf\Grafica_MUJERES_OCUPADAS_ENIGH.png", replace

restore


/****************************************************************************************/
/*                    GRAFICA 6 – NIVEL EDUCATIVO DE MUJERES OCUPADAS ENIGH            */
/****************************************************************************************/

preserve

// ---- Filtrar mujeres que trabajan ----
keep if sexo == 2
keep if ocupado == 1

// Crear variable de fecha tipo trimestre
gen fecha_yq = yq(year, 1)
format fecha_yq %tq

// ---- Crear variables dummies por nivel educativo ----
quietly tab educacion, gen(edu_)

// Calcular proporción promedio por trimestre
collapse (mean) edu_1 edu_2 edu_3 edu_4 edu_5 edu_6 [fw=factor], by(fecha_yq)

// Convertir a porcentaje
foreach var of varlist edu_1 edu_2 edu_3 edu_4 edu_5 edu_6 {
    replace `var' = `var' * 100
}

// Etiquetas descriptivas
label variable edu_1 "Sin instrucción"
label variable edu_2 "Primaria"
label variable edu_3 "Secundaria"
label variable edu_4 "Media Superior"
label variable edu_5 "Superior"
label variable edu_6 "Posgrado"

// ---- Gráfico de líneas con fondo blanco y leyenda clara ----
twoway ///
(line edu_1 fecha_yq, lcolor(gs8) lwidth(medthick)) ///
(line edu_2 fecha_yq, lcolor(navy) lwidth(medthick)) ///
(line edu_3 fecha_yq, lcolor(midblue) lwidth(medthick)) ///
(line edu_4 fecha_yq, lcolor(orange) lwidth(medthick)) ///
(line edu_5 fecha_yq, lcolor(maroon) lwidth(medthick)) ///
(line edu_6 fecha_yq, lcolor(forest_green) lwidth(medthick)), ///
    title("Nivel Educativo de Mujeres", size(medlarge) color(black) pos(11)) ///
    subtitle("Porcentaje por trimestre (T1), 1992–2024", size(medsmall) color(gs6) pos(11)) ///
    xtitle("Trimestre", size(3)) ///
    ytitle("%", size(5)) ///
    xlabel(, format(%tq) labsize(3)) ///
    ylabel(, labsize(3)) ///
    legend(order(1 "Sin instrucción" 2 "Primaria" 3 "Secundaria" 4 "Media Superior" 5 "Superior" 6 "Posgrado") ///
           position(6) cols(3) size(3) region(lcolor(none))) ///
    note(" ", size(vsmall)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    xsize(8) ysize(5.5)

// ---- Exportar gráfico ----
graph export "$graf\Grafica_EDUCACION_MUJERES_ENIGH.png", replace

restore


/****************************************************************************************/
/*                    GRAFICA 7 – ESTADO CIVIL DE MUJERES OCUPADAS EN LA ENIGH         */
/****************************************************************************************/

preserve

// ---- Filtrar mujeres ocupadas ----
keep if sexo == 2
keep if ocupado == 1

// Crear variable de fecha tipo trimestre (Trimestre 1)
gen fecha_yq = yq(year, 1)
format fecha_yq %tq

// ---- Crear variables dummies por estado civil ----
quietly tab edo_conyug, gen(con_)

// Calcular proporciones promedio ponderadas por trimestre
collapse (mean) con_1 con_2 con_3 con_4 con_5 con_6 [fw=factor], by(fecha_yq)

// Convertir a porcentajes
foreach var of varlist con_1 con_2 con_3 con_4 con_5 con_6 {
    replace `var' = `var' * 100
}

// Etiquetas para claridad
label variable con_1 "Unión libre"
label variable con_2 "Casada"
label variable con_3 "Separada"
label variable con_4 "Divorciada"
label variable con_5 "Viuda"
label variable con_6 "Soltera"

// ---- Gráfico de líneas con colores distintos para cada categoría ----
twoway ///
(line con_1 fecha_yq, lcolor(navy) lwidth(medthick)) ///
(line con_2 fecha_yq, lcolor(maroon) lwidth(medthick)) ///
(line con_3 fecha_yq, lcolor(midblue) lwidth(medthick)) ///
(line con_4 fecha_yq, lcolor(cranberry) lwidth(medthick)) ///
(line con_5 fecha_yq, lcolor(olive) lwidth(medthick)) ///
(line con_6 fecha_yq, lcolor(forest_green) lwidth(medthick)), ///
    title("Estado Civil de Mujeres en la ENIGH", size(medlarge) color(black) pos(11)) ///
    subtitle("Porcentaje por trimestre (T1), 1992–2024", size(medsmall) color(gs6) pos(11)) ///
    xtitle("Trimestre", size(3)) ///
    ytitle("%", size(5)) ///
    xlabel(, format(%tq) labsize(3)) ///
    ylabel(, labsize(3)) ///
    legend(order(1 "Unión libre" 2 "Casada" 3 "Separada" 4 "Divorciada" 5 "Viuda" 6 "Soltera") ///
           position(6) cols(3) size(3) region(lcolor(none))) ///
    note(" ", size(vsmall)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    xsize(8) ysize(5.5)

// ---- Exportar gráfico ----
graph export "$graf\Grafica_ESTADO_CIVIL_MUJERES_ENIGH.png", replace

restore


/****************************************************************************************/
/*                 GRAFICA 8 – MUJERES OCUPADAS CON HIJOS EN LA ENIGH                  */
/****************************************************************************************/

preserve

// ---- Filtrar mujeres ocupadas a partir del año 2004 ----
keep if sexo == 2
keep if ocupado == 1
keep if year >= 2004

// Crear variable de fecha tipo trimestre (Trimestre 1)
gen fecha_yq = yq(year, 1)
format fecha_yq %tq

// ---- Crear variables dummies para condición de hijos ----
quietly tab hijos, gen(hij_)

// Calcular proporciones promedio ponderadas por trimestre
collapse (mean) hij_1 hij_2 [fw=factor], by(fecha_yq)

// Convertir a porcentajes
replace hij_1 = hij_1 * 100
replace hij_2 = hij_2 * 100

// Etiquetas para el gráfico
label variable hij_1 "No tiene hijos"
label variable hij_2 "Tiene hijos"

// ---- Gráfico de líneas con dos grupos: con y sin hijos ----
twoway ///
(line hij_1 fecha_yq, lcolor(navy) lwidth(vthick)) ///
(line hij_2 fecha_yq, lcolor(red) lwidth(vthick)), ///
    title("Mujeres con Hijos en la ENIGH", size(large) color(black) pos(11)) ///
    subtitle("Porcentaje por trimestre (T1), 2004–2024", size(medsmall) color(gs6) pos(11)) ///
    xtitle("Trimestre", size(3)) ///
    ytitle("%", size(3)) ///
    xlabel(, format(%tq) labsize(5)) ///
    ylabel(, labsize(3)) ///
    legend(order(1 "No tiene hijos" 2 "Tiene hijos") ///
           position(6) cols(2) size(3) region(lcolor(none))) ///
    note(" ", size(vsmall)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    xsize(8) ysize(5)

// ---- Exportar gráfico ----
graph export "$graf\Grafica_HIJOS_MUJERES_OCUPADAS_ENIGH.png", replace

restore





