/******************************************************************************************
*  AUTORA DE APPEND: Camila Galaz  ( Github : lcgalaz )
*  AUTOR DE GRAFICAS Y CUADROS PROPIOS (+PASO 7) : Daniel Fuentes ( Gihub : danifuentesga )
*  FECHA: Agosto 2025
*  OBJETIVO: Integrar en un solo formato la ENOE-SDEM de 2005 a 2025, omitiendo 2020-2T.
*  NOTA: Se asume estructura de carpetas por año y trimestre: AAAA/1T, 2T, 3T, 4T
*        Se procesan diferentes tipos de archivo según el año.
******************************************************************************************/


****    Si algo falla, abre "La historia mínima de Stata"         ****
****   (versión no publicada), colocala frente al monitor        ****
****    y cruza los dedos. 

/******************************************************************************************
*                        PASO 1 : CONFIGURACIÓN DEL ENTORNO DE TRABAJO                             *
******************************************************************************************/

* Define carpeta raíz donde están almacenadas las bases por año
global enoe_path "D:\INVESTIGACION\DATA\ENOE"

* Tip: Siempre revisen que las rutas usen "/" aunque estén en Windows


/******************************************************************************************
*                PASO 2 : PROCESAMIENTO DE ENOE 2005-1T A 2019-4T (Formato: SDEMTxy.dta)           *
******************************************************************************************/

* En este bloque, los archivos se nombran como: SDEMT`trimestre'`año'.dta (ej. SDEMT105.dta)
forvalues anio = 2005/2019 {
    local aa = substr("`anio'",3,2)

    forvalues trim = 1/4 {
        local in  "${enoe_path}/`anio'/`trim'T/SDEMT`trim'`aa'.dta"
        local out "${enoe_path}/`anio'/`trim'T/SDEMT`trim'`aa'v.dta"

        di as txt ">>> Procesando: Año=`anio', Trimestre=`trim'"

        * Si el archivo ya fue procesado, saltar
        if (filereadable("`out'")) {
            di as result "• Ya existe: `out' -> se omite"
            continue
        }

        * Si el archivo de entrada no existe, continuar con advertencia
        if (!filereadable("`in'")) {
            di as err "!! No se encontró: `in' -> se omite"
            continue
        }

        * Abrir, renombrar a minúsculas, comprimir
        use "`in'", clear
        rename *, lower
        quietly compress

        * Seleccionar variables clave (ojo: mantén consistencia)
        keep r_def c_res mun cd_a ent con n_pro_viv v_sel h_mud n_hog n_ren t_loc cs_p13_1 ///
             cs_p13_2 par_c sex eda n_hij e_con zona salario fac clase1 clase2 ing7c ///
             emple7c niv_ins t_tra anios_esc hrsocup ingocup ing_x_hrs imssissste ///
             rama_est2 pos_ocu dur_est

        * Crear variables temporales para identificar año y trimestre
        gen year = `anio'
        gen q = `trim'
        gen date = yq(year, q)
        format date %tq

        * Guardar versión procesada
        save "`out'", replace
        di as result "✓ Guardado: `out'"
    }
}


/******************************************************************************************
*                           PASO 3: PROCESAMIENTO DE ENOE 2020-1T                                 *
******************************************************************************************/

* En este trimestre, el archivo se llama diferente: ENOE_SDEMT120.dta

local input2020 "${enoe_path}/2020/1T/ENOE_SDEMT120.dta"
local output2020 "${enoe_path}/2020/1T/SDEMT120v.dta"

di as txt ">>> Procesando: Año=2020, Trimestre=1"

if (filereadable("`output2020'")) {
    di as result "• Ya existe: `output2020' -> se omite"
}
else {
    if (!filereadable("`input2020'")) {
        di as err "¡¡ERROR!! No se encontró archivo: `input2020'"
        error 601
    }

    use "`input2020'", clear
    rename *, lower
    quietly compress

    keep r_def c_res mun cd_a ent con n_pro_viv v_sel h_mud n_hog n_ren t_loc cs_p13_1 ///
         cs_p13_2 par_c sex eda n_hij e_con zona salario fac clase1 clase2 ing7c ///
         emple7c niv_ins t_tra anios_esc hrsocup ingocup ing_x_hrs imssissste ///
         rama_est2 pos_ocu dur_est

    gen year = 2020
    gen q = 1
    gen date = yq(year, q)
    format date %tq

    save "`output2020'", replace
    di as result "✓ Guardado: `output2020'"
}

/******************************************************************************************
*                  PASO 4 : PROCESAMIENTO DE ENOEN (2020-3T A 2022-4T)                             *
*   NOTA: Los archivos llevan una "N" en el nombre → ENOEN_SDEMT`trimestre'`año'.dta     *
*   EX: ENOEN_SDEMT320.dta = ENOEN, 3er trimestre de 2020                                 *
******************************************************************************************/

* Procesamos 2020 (solo 3T y 4T), y 2021–2022 (todos los trimestres)
foreach anio in 2020 2021 2022 {
    
    * Determinar trimestres según el año
    local trimestres = cond(`anio' == 2020, "3 4", "1 2 3 4")

    * Extraer últimos dos dígitos del año (para nombres de archivo)
    local aa = substr("`anio'", 3, 2)

    foreach t of local trimestres {

        local infile  "${enoe_path}/`anio'/`t'T/ENOEN_SDEMT`t'`aa'.dta"
        local outfile "${enoe_path}/`anio'/`t'T/SDEMT`t'`aa'v.dta"

        di as txt ">>> Procesando ENOEN: Año=`anio', Trimestre=`t'"

        * Si archivo ya fue procesado, omitir
        if (filereadable("`outfile'")) {
            di as result "• Ya existe: `outfile' → se omite"
            continue
        }

        * Si archivo original no existe, lanzar error
        if (!filereadable("`infile'")) {
            di as err "¡¡ERROR!! No se encontró archivo: `infile'"
            error 601
        }

        * Abrir base, normalizar estructura
        use "`infile'", clear
        rename *, lower
        quietly compress

        * Algunas variables cambiaron de nombre desde 2020, las renombramos si existen
        capture confirm variable t_loc_tri
        if !_rc rename t_loc_tri t_loc

        capture confirm variable fac_tri
        if !_rc rename fac_tri fac

        * Selección de variables clave (las mismas en todo el proyecto)
        keep r_def c_res mun cd_a ent con n_pro_viv v_sel h_mud n_hog n_ren t_loc cs_p13_1 ///
             cs_p13_2 par_c sex eda n_hij e_con zona salario fac clase1 clase2 ing7c ///
             emple7c niv_ins t_tra anios_esc hrsocup ingocup ing_x_hrs imssissste ///
             rama_est2 pos_ocu dur_est

        * Añadir fecha en formato año-trimestre
        gen year = `anio'
        gen q = `t'
        gen date = yq(year, q)
        format date %tq

        * Guardar base procesada
        save "`outfile'", replace
        di as result "✓ Guardado: `outfile'"
    }
}


/******************************************************************************************
*        PASO 5 : PROCESAMIENTO DE ENOE (2023-1T A 2025-1T) — SIN "N" EN EL NOMBRE DEL ARCHIVO     *
*    Política de faltantes:                                                               *
*      • Años anteriores al actual → si falta, error.                                     *
*      • Año actual → si falta, solo aviso.                                               *
******************************************************************************************/

* ¿Aplicar validación estricta a años pasados?
local validar_estrictamente 1

* Obtener año actual del sistema
local hoy = date(c(current_date), "DMY")
local anio_actual = year(`hoy')

* Recorrer años recientes (solo hasta el actual)
foreach anio in 2023 2024 2025 {
    if `anio' > `anio_actual' continue

    * Intentar todos los trimestres posibles
    local trimestres "1 2 3 4"
    local aa = substr("`anio'", 3, 2)

    foreach t of local trimestres {

        local entrada  "${enoe_path}/`anio'/`t'T/ENOE_SDEMT`t'`aa'.dta"
        local salida   "${enoe_path}/`anio'/`t'T/SDEMT`t'`aa'v.dta"

        di as txt ">>> Procesando ENOE: Año=`anio', Trimestre=`t'"

        * Si archivo ya fue procesado, lo omitimos
        if (filereadable("`salida'")) {
            di as result "• Ya existe: `salida' → se omite"
            continue
        }

        * Si archivo no existe...
        if (!filereadable("`entrada'")) {

            if `anio' < `anio_actual' & `validar_estrictamente' {
                di as err "¡¡ERROR!! No se encontró entrada histórica: `entrada'"
                error 601
            }
            else {
                di as err "!! No disponible aún (año actual): `entrada' → se omite"
                continue
            }
        }

        * Cargar y procesar archivo
        use "`entrada'", clear
        rename *, lower
        quietly compress

        * Renombrar variables si traen sufijo "_tri"
        capture confirm variable t_loc_tri
        if !_rc rename t_loc_tri t_loc

        capture confirm variable fac_tri
        if !_rc rename fac_tri fac

        * Seleccionar conjunto de variables estándar
        keep r_def c_res mun cd_a ent con n_pro_viv v_sel h_mud n_hog n_ren t_loc cs_p13_1 ///
             cs_p13_2 par_c sex eda n_hij e_con zona salario fac clase1 clase2 ing7c ///
             emple7c niv_ins t_tra anios_esc hrsocup ingocup ing_x_hrs imssissste ///
             rama_est2 pos_ocu dur_est

        * Crear variable de fecha y formatearla
        gen year = `anio'
        gen q    = `t'
        gen date = yq(year, q)
        format date %tq

        * Guardar base procesada
        save "`salida'", replace
        di as result "✓ Guardado: `salida'"
    }
}


/******************************************************************************************
*                               PASO 6 - UNIFICAR BASES SDEM                              *
*     Objetivo: Reunir todas las bases SDEMT procesadas en una sola base 2005–2025        *
*     Política:                                                                           
*       - Bases anteriores al año actual deben existir sí o sí (error si faltan)         
*       - Para el año actual, si falta un trimestre se omite con aviso                   
******************************************************************************************/

* Inicializar lista de archivos a unir
local archivos ""

* Configurar validación estricta para años pasados
local validar_pasado 1

* Obtener año actual del sistema
local hoy = date(c(current_date), "DMY")
local anio_actual = year(`hoy')

/******************************************************************************************
*                                6.1 RECOLECCIÓN DE ARCHIVOS                              *
******************************************************************************************/

* Bases de 2005 a 2019 (4 trimestres por año)
forvalues anio = 2005/2019 {
    local aa = substr("`anio'", 3, 2)
    forvalues t = 1/4 {
        local ruta = "${enoe_path}/`anio'/`t'T/SDEMT`t'`aa'v.dta"
        if (filereadable("`ruta'")) {
            local archivos `archivos' "`ruta'"
        }
        else {
            di as err "¡¡ERROR!! Falta base histórica: `ruta'"
            error 601
        }
    }
}

* ENOE/ENOEN 2020: Solo 1T, 3T, 4T
foreach t in 1 3 4 {
    local ruta = "${enoe_path}/2020/`t'T/SDEMT`t'20v.dta"
    if (filereadable("`ruta'")) {
        local archivos `archivos' "`ruta'"
    }
    else {
        di as err "¡¡ERROR!! Falta base de 2020: `ruta'"
        error 601
    }
}

* Años completos: 2021 y 2022
foreach anio in 2021 2022 {
    local aa = substr("`anio'", 3, 2)
    forvalues t = 1/4 {
        local ruta = "${enoe_path}/`anio'/`t'T/SDEMT`t'`aa'v.dta"
        if (filereadable("`ruta'")) {
            local archivos `archivos' "`ruta'"
        }
        else {
            di as err "¡¡ERROR!! Falta base: `ruta'"
            error 601
        }
    }
}

* Años recientes: 2023 a 2025 (solo si existen, sin error)
foreach anio in 2023 2024 2025 {
    local aa = substr("`anio'", 3, 2)
    forvalues t = 1/4 {
        local ruta = "${enoe_path}/`anio'/`t'T/SDEMT`t'`aa'v.dta"
        if (filereadable("`ruta'")) {
            local archivos `archivos' "`ruta'"
        }
        else if (`anio' <= `anio_actual') {
            di as txt "Nota: Trimestre no encontrado para año actual: `ruta'"
        }
    }
}

/******************************************************************************************
*                      6.2 NORMALIZACIÓN DE VARIABLES CONFLICTIVAS                        *
*                      (t_loc y fac: pueden ser string o numéricas)                       *
******************************************************************************************/

local vars_revisar t_loc fac
local base_inicial : word 1 of `archivos'

di as txt ">>> Usando como base inicial: `base_inicial'"
use "`base_inicial'", clear

foreach v of local vars_revisar {
    capture confirm variable `v'
    if !_rc {
        capture confirm string variable `v'
        if !_rc destring `v', replace force
    }
}

/******************************************************************************************
*                         6.3 APPEND DE ARCHIVOS RESTANTES CON LIMPIEZA                   *
******************************************************************************************/

local total = wordcount("`archivos'")
forvalues i = 2/`total' {
    local next : word `i' of `archivos'
    di as txt "→ Uniendo archivo `i'/`total': `next'"

    preserve
        use "`next'", clear

        foreach v of local vars_revisar {
            capture confirm variable `v'
            if !_rc {
                capture confirm string variable `v'
                if !_rc destring `v', replace force
            }
        }

        tempfile tmp_`i'
        save "`tmp_`i''", replace
    restore

    append using "`tmp_`i''"
}

/******************************************************************************************
*                             6.4 ORDENAR, ETIQUETAR Y COMPRIMIR                          *
******************************************************************************************/

quietly compress
capture order year q date, first
sort year q

label var year "Año calendario"
label var q    "Trimestre (1-4)"
label var date "Fecha trimestral (yq)"

/******************************************************************************************
*                            6.5 GUARDAR BASE FINAL E INFORMAR                            *
******************************************************************************************/

local salida_final "${enoe_path}/Base_ENOE_SDEM_2005_2025.dta"
save "`salida_final'", replace
di as result "🎉 ¡Base integrada creada exitosamente!"
di as result "✓ Archivo guardado: `salida_final'"
di as result "✓ Observaciones totales: " _N


/******************************************************************************************
*                                 PASO 7 - BASE ENOE SDEM                                 *
*   Objetivo: Cargar la base integrada de ENOE-SDEM y generar una versión depurada        *
*             para análisis de personas entre 15 y 65 años                                *
******************************************************************************************/

* Cargar base integrada
use "${enoe_path}/Base_ENOE_SDEM_2005_2025.dta", clear

* Asegurar formato correcto de la fecha
format date %tq

* Filtrar población en edad laboral: 15 a 65 años
keep if inrange(eda, 15, 65)

* Convertir a numéricas las variables clave si vienen como string
destring c_res r_def y q fac, replace

* Eliminar entrevistas suspendidas (r_def == 15)
drop if r_def == 15

* Conservar solo residentes habituales (1) y nuevos residentes (3)
keep if inlist(c_res, 1, 3)

* Eliminar observaciones del año 2025 (por ser incompleto o preliminar)
keep if year <= 2024

* Guardar base limpia y acotada
save "${enoe_path}/ENOE_Analitica.dta", replace


/******************************************************************************************
*                  DEFINIR RUTA DE SALIDA PARA TABLAS Y RESULTADOS                        *
******************************************************************************************/

* Definir ruta de archivo Excel donde se exportarán los cuadros
local xfile "${enoe_path}/ENOE_cuadros.xlsx"


/******************************************************************************************
*                                PASO 8 - TABLA 1: POBLACIÓN Y HOGARES                    *
*     Objetivo: Calcular el número promedio de individuos y hogares por año (2005–2024)   *
*     Notas:                                                                               *
*       - Se usa el ponderador de expansión (fac)                                          *
*       - Para 2020, solo se incluyen 3 trimestres (no ETOE)                              *
******************************************************************************************/

preserve

    * Crear indicadores de conteo
    gen individuo = 1
    gen hogar     = (n_ren == 1)

    * Asegurar que el ponderador esté en formato numérico
    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    * Colapsar: sumar individuos y hogares por año, usando ponderador
    collapse (sum) individuo hogar [fw=fac], by(year)

    * Ajuste por trimestres disponibles
    gen trimestres = cond(year == 2020, 3, 4)
    replace individuo = individuo / trimestres
    replace hogar     = hogar     / trimestres

    * Etiquetas para presentación
    label var year      "Año"
    label var individuo "Individuos promedio por año"
    label var hogar     "Hogares promedio por año"

    /******************************************************************************************
    *                        EXPORTAR TABLA 1 A EXCEL (putexcel + collect)                   *
    ******************************************************************************************/

    collect clear
    collect: table year, statistic(total individuo hogar) nototals
    putexcel set "${enoe_path}/ENOE_cuadros.xlsx", sheet(indiv_hogares) modify
    putexcel A2 = collect

restore



/******************************************************************************************
*                      BLOQUE EXTRA: EXPORTAR TABLA 1 A FORMATO LaTeX                    *
******************************************************************************************/

preserve

    * Repetimos procedimiento para asegurar consistencia
    gen individuo = 1
    gen hogar     = (n_ren == 1)

    * Validar tipo numérico del ponderador
    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    * Colapsar por año
    collapse (sum) individuo hogar [fw=fac], by(year)

    * Ajuste por trimestres
    gen trimestres = cond(year == 2020, 3, 4)
    replace individuo = individuo / trimestres
    replace hogar     = hogar     / trimestres

    * Exportar a archivo .tex en formato LaTeX
    file open tex_out using "${enoe_path}/ENOE_IndivHog.tex", write replace
    file write tex_out "%% Tabla generada desde Stata - Individuos y Hogares ENOE" _n
    file write tex_out "\begin{tabular}{lrr}" _n
    file write tex_out "\hline" _n
    file write tex_out "Año & Individuos promedio por año & Hogares promedio por año \\\\" _n
    file write tex_out "\hline" _n

    quietly {
        forvalues i = 1/`=_N' {
            local y  = year[`i']
            local ii = string(individuo[`i'], "%15.0fc")
            local hh = string(hogar[`i'], "%15.0fc")
            file write tex_out "`y' & `ii' & `hh' \\\\" _n
        }
    }

    file write tex_out "\hline" _n
    file write tex_out "\end{tabular}" _n
    file close tex_out

restore

/******************************************************************************************
*                                GRAFICA 1 - INDIVIDUOS Y HOGARES                         *
*       Objetivo: Visualizar el promedio anual de individuos y hogares en la ENOE         *
*       Notas:                                                                             *
*         - Se ajusta 2020 a 3 trimestres                                                 *
*         - Se grafican series anuales en millones                                        *
******************************************************************************************/

preserve

    * Activar esquema "economist" para estilo limpio
    capture noisily set scheme economist
    if _rc {
        ssc install schemepack, replace
        set scheme economist
    }

    * Generar indicadores base
    gen ind = 1
    gen hog = (n_ren == 1)

    * Asegurar ponderador numérico
    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    * Colapsar con ponderadores por año
    collapse (sum) ind hog [fw=fac], by(year)

    * Ajustar por trimestres disponibles
    gen trimestres = cond(year == 2020, 3, 4)
    replace ind = ind / trimestres
    replace hog = hog / trimestres

    * Convertir a millones
    gen ind_mill = ind / 1e6
    gen hog_mill = hog / 1e6

    * Crear variable de fecha para eje X (usamos primer trimestre como marcador)
    gen fecha = yq(year, 1)
    format fecha %tq

    * Etiquetas
    label var ind_mill "Individuos"
    label var hog_mill "Hogares"

    * Gráfico de líneas estilo Economist
    twoway ///
        (line ind_mill fecha, lwidth(medthick)) ///
        (line hog_mill fecha, lwidth(medthick) lpattern(dash)), ///
        title("Promedio anual de individuos y hogares en la ENOE", size(medium)) ///
        subtitle("Ajustado por número de trimestres. Años 2005–2024", size(small)) ///
        xtitle("Año", size(small)) ///
        ytitle("Millones", size(small)) ///
        xlabel(, format(%tq) labsize(small)) ///
        ylabel(, labsize(small)) ///
        legend(order(1 "Individuos" 2 "Hogares") cols(2) size(small) pos(6) ring(0)) ///
        graphregion(margin(l+4 r+2 t+2 b+2)) ///
        xsize(8) ysize(5)

    * Guardar gráfico (define carpeta si no lo has hecho antes)
    local graf_path = "${enoe_path}/graficas"
    cap mkdir "`graf_path'"

    graph export "`graf_path'/Grafica_ENOE_Individuos_Hogares.png", replace

restore


/******************************************************************************************
*                    PASO 9 - NIVEL EDUCATIVO (PORCENTAJE POR AÑO)                        *
*     Objetivo: Calcular distribución porcentual de nivel educativo según cs_p13_1        *
*     Notas: Codificación en 6 niveles. Se utiliza ponderador fac                         *
******************************************************************************************/

preserve

    * Recodificar variable de educación
    gen nivel_edu = .
    replace nivel_edu = 0 if inlist(cs_p13_1, 0, 1)
    replace nivel_edu = 1 if cs_p13_1 == 2
    replace nivel_edu = 2 if cs_p13_1 == 3
    replace nivel_edu = 3 if inlist(cs_p13_1, 4, 5, 6)
    replace nivel_edu = 4 if cs_p13_1 == 7
    replace nivel_edu = 5 if inlist(cs_p13_1, 8, 9)

    * Etiquetas
    label define educniv 0 "Sin estudios" 1 "Primaria" 2 "Secundaria" 3 "Media Superior" ///
                         4 "Superior" 5 "Posgrado"
    label values nivel_edu educniv
    label variable nivel_edu "Nivel educativo"

    * Asegurar que fac es numérica
    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    * Tabla con % por categoría
    collect clear
    collect: table year, statistic(fvpercent nivel_edu) nototals [fw=fac]

    * Exportar a Excel
    putexcel set "${enoe_path}/ENOE_cuadros.xlsx", sheet(educacion) modify
    putexcel A2 = collect

restore

/******************************************************************************************
*           BLOQUE EXTRA - EXPORTACIÓN A LaTeX: DISTRIBUCIÓN NIVEL EDUCATIVO             *
******************************************************************************************/

preserve

    * Recalcular variable educativa
    gen nivel_edu = .
    replace nivel_edu = 0 if inlist(cs_p13_1, 0, 1)
    replace nivel_edu = 1 if cs_p13_1 == 2
    replace nivel_edu = 2 if cs_p13_1 == 3
    replace nivel_edu = 3 if inlist(cs_p13_1, 4, 5, 6)
    replace nivel_edu = 4 if cs_p13_1 == 7
    replace nivel_edu = 5 if inlist(cs_p13_1, 8, 9)

    label values nivel_edu educniv

    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    gen uno = 1
    collapse (sum) personas = uno [fw=fac], by(year nivel_edu)

    bysort year (nivel_edu): egen total = total(personas)
    gen pct = 100 * personas / total

    * Exportación a archivo .tex
    file open out_tex using "${enoe_path}/ENOE_Educacion.tex", write replace
    file write out_tex "%% Tabla generada desde Stata - Nivel educativo (ENOE)" _n
    file write out_tex "\begin{tabular}{lrrrrrr}" _n
    file write out_tex "\hline" _n
    file write out_tex "Año & Sin estudios & Primaria & Secundaria & Media Superior & Superior & Posgrado \\\\" _n
    file write out_tex "\hline" _n

    quietly {
        levelsof year, local(anios)
        foreach y of local anios {
            local fila "`y'"
            foreach e in 0 1 2 3 4 5 {
                quietly summarize pct if year == `y' & nivel_edu == `e'
                local val = cond(r(N) > 0, string(r(mean), "%4.1f"), "0.0")
                local fila "`fila' & `val'\%"
            }
            file write out_tex "`fila' \\\\" _n
        }
    }

    file write out_tex "\hline" _n
    file write out_tex "\end{tabular}" _n
    file close out_tex

restore


/******************************************************************************************
*                 GRAFICA 2 - EVOLUCIÓN DEL NIVEL EDUCATIVO EN LA ENOE                   *
*     Objetivo: Mostrar la evolución porcentual de cada nivel educativo en el tiempo      *
******************************************************************************************/

preserve

    * Activar esquema economist
    capture noisily set scheme economist
    if _rc {
        ssc install schemepack, replace
        set scheme economist
    }

    * Recodificar nivel educativo
    gen nivel_edu = .
    replace nivel_edu = 0 if inlist(cs_p13_1, 0, 1)
    replace nivel_edu = 1 if cs_p13_1 == 2
    replace nivel_edu = 2 if cs_p13_1 == 3
    replace nivel_edu = 3 if inlist(cs_p13_1, 4, 5, 6)
    replace nivel_edu = 4 if cs_p13_1 == 7
    replace nivel_edu = 5 if inlist(cs_p13_1, 8, 9)

    label define educniv 0 "Sin estudios" 1 "Primaria" 2 "Secundaria" 3 "Media Superior" 4 "Superior" 5 "Posgrado"
    label values nivel_edu educniv

    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    gen uno = 1
    collapse (sum) personas = uno [fw=fac], by(year nivel_edu)
    bysort year (nivel_edu): egen total = total(personas)
    gen pct = 100 * personas / total
    drop personas total

    reshape wide pct, i(year) j(nivel_edu)

    * Etiquetar
    label variable pct0 "Sin estudios"
    label variable pct1 "Primaria"
    label variable pct2 "Secundaria"
    label variable pct3 "Media Superior"
    label variable pct4 "Superior"
    label variable pct5 "Posgrado"

    * Variable de tiempo
    gen fecha = yq(year, 1)
    format fecha %tq

    * Gráfico de líneas por nivel educativo
    twoway ///
        (line pct0 fecha, lcolor("228 26 28") lwidth(thick)) ///
        (line pct1 fecha, lcolor("55 126 184") lwidth(thick)) ///
        (line pct2 fecha, lcolor("77 175 74") lwidth(thick)) ///
        (line pct3 fecha, lcolor("255 127 0") lwidth(thick)) ///
        (line pct4 fecha, lcolor("152 78 163") lwidth(thick)) ///
        (line pct5 fecha, lcolor("166 86 40") lwidth(thick)), ///
        title("Nivel educativo en la ENOE", size(medium)) ///
        subtitle("Porcentaje por nivel, 2005–2024", size(small)) ///
        xtitle("Año") ///
        ytitle("Porcentaje") ///
        xlabel(, format(%tq) labsize(small)) ///
        ylabel(, labsize(small)) ///
        legend(order(1 "Sin estudios" 2 "Primaria" 3 "Secundaria" 4 "Media Superior" ///
                     5 "Superior" 6 "Posgrado") ///
               cols(3) size(small) pos(6)) ///
        xsize(8) ysize(5)

    * Crear carpeta si no existe
    local graf_path = "${enoe_path}/graficas"
    cap mkdir "`graf_path'"

    graph export "`graf_path'/Grafica_ENOE_Nivel_Educativo.png", replace

restore


/******************************************************************************************
*                      PASO 10 - SITUACIÓN LABORAL (% DE OCUPADOS)                        *
*     Objetivo: Calcular y exportar la proporción de personas ocupadas por año            *
*     Nota: Se usa la variable clase2 (1 = ocupado, 0 = no ocupado)                        *
******************************************************************************************/

preserve

    * Crear variable binaria de ocupación
    gen ocupado = .
    replace ocupado = 0 if clase2 == 0
    replace ocupado = 1 if clase2 == 1

    label define ocup_lbl 0 "No ocupados" 1 "Ocupados"
    label values ocupado ocup_lbl
    label variable ocupado "Situación laboral"

    * Verificar formato del ponderador
    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    * Crear tabla con porcentaje por categoría
    collect clear
    collect: table year, statistic(fvpercent ocupado) nototals [fw=fac]

    * Exportar a Excel
    putexcel set "${enoe_path}/ENOE_cuadros.xlsx", sheet(ocupacion) modify
    putexcel A2 = collect

restore


/******************************************************************************************
*               EXPORTACIÓN A LaTeX: DISTRIBUCIÓN DE SITUACIÓN LABORAL                   *
******************************************************************************************/

preserve

    gen ocupado = .
    replace ocupado = 0 if clase2 == 0
    replace ocupado = 1 if clase2 == 1

    label values ocupado ocup_lbl

    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    gen uno = 1
    collapse (sum) personas = uno [fw=fac], by(year ocupado)
    bys year: egen total = total(personas)
    gen pct = 100 * personas / total

    file open out_tex using "${enoe_path}/ENOE_OCUPA.tex", write replace
    file write out_tex "%% Tabla generada desde Stata - ENOE: Situación laboral" _n
    file write out_tex "\begin{tabular}{lrr}" _n
    file write out_tex "\hline" _n
    file write out_tex "Año & No ocupados (\%) & Ocupados (\%) \\\\" _n
    file write out_tex "\hline" _n

    quietly {
        levelsof year, local(anios)
        foreach y of local anios {
            summarize pct if year == `y' & ocupado == 0
            local nooc = cond(r(N) > 0, string(r(mean), "%4.1f"), "0.0")
            summarize pct if year == `y' & ocupado == 1
            local oc = cond(r(N) > 0, string(r(mean), "%4.1f"), "0.0")
            file write out_tex "`y' & `nooc'\% & `oc'\% \\\\" _n
        }
    }

    file write out_tex "\hline" _n
    file write out_tex "\end{tabular}" _n
    file close out_tex

restore


/******************************************************************************************
*                      GRAFICA - SITUACIÓN LABORAL EN LA ENOE                             *
*     Objetivo: Representar la proporción de ocupados y no ocupados por año               *
******************************************************************************************/

preserve

    * Estilo gráfico tipo The Economist
    capture noisily set scheme economist
    if _rc {
        ssc install schemepack, replace
        set scheme economist
    }

    * Crear variable de ocupación
    gen ocupado = .
    replace ocupado = 0 if clase2 == 0
    replace ocupado = 1 if clase2 == 1

    label values ocupado ocup_lbl

    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    gen uno = 1
    collapse (sum) personas = uno [fw=fac], by(year ocupado)
    bysort year (ocupado): egen total = total(personas)
    gen pct = 100 * personas / total

    drop if missing(ocupado)
    drop personas total

    reshape wide pct, i(year) j(ocupado)
    label var pct0 "No ocupados"
    label var pct1 "Ocupados"

    gen fecha = yq(year, 1)
    format fecha %tq

    * Graficar evolución de ocupación
    twoway ///
        (line pct0 fecha, lcolor("228 26 28") lwidth(thick)) ///
        (line pct1 fecha, lcolor("77 175 74") lwidth(thick)), ///
        title("Situación laboral en la ENOE", size(medium)) ///
        subtitle("Porcentaje anual, 2005–2024", size(small)) ///
        xtitle("Año") ///
        ytitle("Porcentaje") ///
        xlabel(, format(%tq) labsize(small)) ///
        ylabel(, labsize(small)) ///
        legend(order(1 "No ocupados" 2 "Ocupados") cols(2) size(small) pos(6)) ///
        xsize(8) ysize(5)

    * Crear carpeta de salida si no existe
    local graf_path = "${enoe_path}/graficas"
    cap mkdir "`graf_path'"

    graph export "`graf_path'/Grafica_ENOE_Situacion_Laboral.png", replace

restore


/******************************************************************************************
*                  PASO 11 - PORCENTAJE DE POBLACIÓN EN ZONA RURAL                        *
*     Objetivo: Calcular proporción de población en localidades rurales por año           *
******************************************************************************************/

preserve

    * Crear variable binaria rural
    gen rural = .
    replace rural = 0 if t_loc != . & t_loc != 4
    replace rural = 1 if t_loc == 4

    * Etiquetas
    label define localidad 0 "Urbano" 1 "Rural"
    label values rural localidad
    label variable rural "Tipo de localidad"

    * Verificar tipo de ponderador
    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    * Tabla con porcentaje por tipo de localidad
    collect clear
    collect: table year, statistic(fvpercent rural) nototals [fw=fac]

    * Exportar a Excel
    putexcel set "${enoe_path}/ENOE_cuadros.xlsx", sheet(rural) modify
    putexcel A2 = collect

restore

/******************************************************************************************
*          EXPORTACIÓN A LaTeX - PORCENTAJE POR TIPO DE LOCALIDAD (URBANO/RURAL)         *
******************************************************************************************/

preserve

    * Crear variable rural
    gen rural = .
    replace rural = 0 if t_loc != . & t_loc != 4
    replace rural = 1 if t_loc == 4

    label values rural localidad

    * Verificar tipo del ponderador
    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    gen uno = 1
    collapse (sum) personas = uno [fw=fac], by(year rural)
    bys year: egen tot = total(personas)
    gen pct = 100 * personas / tot

    * Exportar a LaTeX
    file open tex_out using "${enoe_path}/ENOE_RURAL.tex", write replace
    file write tex_out "%% Tabla generada desde Stata - Sector Rural" _n
    file write tex_out "\begin{tabular}{lrr}" _n
    file write tex_out "\hline" _n
    file write tex_out "Año & Urbano (\%) & Rural (\%) \\\\" _n
    file write tex_out "\hline" _n

    quietly {
        levelsof year, local(anios)
        foreach y of local anios {
            summarize pct if year == `y' & rural == 0
            local urbano = cond(r(N)>0, string(r(mean), "%4.1f"), "0.0")
            summarize pct if year == `y' & rural == 1
            local rur = cond(r(N)>0, string(r(mean), "%4.1f"), "0.0")
            file write tex_out "`y' & `urbano'\% & `rur'\% \\\\" _n
        }
    }

    file write tex_out "\hline" _n
    file write tex_out "\end{tabular}" _n
    file close tex_out
	
	restore
	
/******************************************************************************************
*              GRAFICA - PORCENTAJE DE POBLACIÓN URBANA Y RURAL EN LA ENOE               *
******************************************************************************************/

preserve

    * Activar esquema tipo Economist
    capture noisily set scheme economist
    if _rc {
        ssc install schemepack, replace
        set scheme economist
    }

    * Crear variable rural
    gen rural = .
    replace rural = 0 if t_loc != . & t_loc != 4
    replace rural = 1 if t_loc == 4

    label values rural localidad

    * Asegurar que el ponderador sea numérico
    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    * Conteo por año y tipo de localidad
    gen uno = 1
    collapse (sum) personas = uno [fw=fac], by(year rural)
    bysort year (rural): egen tot = total(personas)
    gen pct = 100 * personas / tot

    drop if missing(rural)
    drop personas tot

    * Reestructurar para graficar
    reshape wide pct, i(year) j(rural)

    label variable pct0 "Urbano"
    label variable pct1 "Rural"

    * Variable de fecha
    gen fecha = yq(year, 1)
    format fecha %tq

    * Gráfico de líneas
    twoway ///
        (line pct0 fecha, lcolor("55 126 184") lwidth(thick)) ///
        (line pct1 fecha, lcolor("228 26 28") lwidth(thick)), ///
        title("Distribución por Tipo de Localidad en la ENOE", size(medium)) ///
        subtitle("Porcentaje de población urbana y rural, 2005–2024", size(small)) ///
        xtitle("Año") ///
        ytitle("Porcentaje") ///
        xlabel(, format(%tq) labsize(small)) ///
        ylabel(, labsize(small)) ///
        legend(order(1 "Urbano" 2 "Rural") cols(2) size(small) pos(6)) ///
        xsize(8) ysize(5)

    * Exportar gráfico
    local graf_path = "${enoe_path}/graficas"
    cap mkdir "`graf_path'"
    graph export "`graf_path'/Grafica_ENOE_Localidad_RuralUrbana.png", replace

restore


/******************************************************************************************
*                  PASO 12 - PORCENTAJE DE MUJERES OCUPADAS POR AÑO                       *
*     Objetivo: Calcular la proporción de mujeres que trabajan según ENOE-SDEM            *
*     Población: Mujeres (sex == 2)                                                       *
******************************************************************************************/

preserve

    * Filtrar solo mujeres
    keep if sex == 2

    * Crear variable binaria de ocupación
    gen ocupado = .
    replace ocupado = 0 if clase2 == 0
    replace ocupado = 1 if clase2 == 1

    label define trab 0 "No ocupadas" 1 "Ocupadas", replace
    label values ocupado trab
    label variable ocupado "Situación laboral"

    * Verificar que el ponderador es numérico
    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    * Crear tabla con porcentaje de ocupadas
    collect clear
    collect: table year, statistic(fvpercent ocupado) nototals [fw=fac]

    * Exportar a Excel
    putexcel set "${enoe_path}/ENOE_cuadros.xlsx", sheet(mujeres_ocupacion) modify
    putexcel A2 = collect

restore


/******************************************************************************************
*          EXPORTACIÓN A LaTeX - PORCENTAJE DE MUJERES OCUPADAS Y NO OCUPADAS            *
******************************************************************************************/

preserve

    keep if sex == 2

    gen ocupado = .
    replace ocupado = 0 if clase2 == 0
    replace ocupado = 1 if clase2 == 1
    label values ocupado trab

    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    gen uno = 1
    collapse (sum) personas = uno [fw=fac], by(year ocupado)
    bys year: egen total = total(personas)
    gen pct = 100 * personas / total

    file open tex_out using "${enoe_path}/ENOE_MUJERES_OCUPA.tex", write replace
    file write tex_out "%% Tabla generada desde Stata - ENOE: Mujeres ocupadas" _n
    file write tex_out "\begin{tabular}{lrr}" _n
    file write tex_out "\hline" _n
    file write tex_out "Año & No ocupadas (\%) & Ocupadas (\%) \\\\" _n
    file write tex_out "\hline" _n

    quietly {
        levelsof year, local(anios)
        foreach y of local anios {
            summarize pct if year == `y' & ocupado == 0
            local no = cond(r(N) > 0, string(r(mean), "%4.1f"), "0.0")
            summarize pct if year == `y' & ocupado == 1
            local si = cond(r(N) > 0, string(r(mean), "%4.1f"), "0.0")
            file write tex_out "`y' & `no'\% & `si'\% \\\\" _n
        }
    }

    file write tex_out "\hline" _n
    file write tex_out "\end{tabular}" _n
    file close tex_out

restore

/******************************************************************************************
*                    GRAFICA - EVOLUCIÓN DEL TRABAJO FEMENINO EN LA ENOE                 *
******************************************************************************************/

preserve

    * Filtrar mujeres
    keep if sex == 2

    * Variable de ocupación
    gen ocupado = .
    replace ocupado = 0 if clase2 == 0
    replace ocupado = 1 if clase2 == 1
    label values ocupado trab

    * Validar tipo de ponderador
    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    gen uno = 1
    collapse (sum) personas = uno [fw=fac], by(year ocupado)
    bysort year (ocupado): egen total = total(personas)
    gen pct = 100 * personas / total

    drop if missing(ocupado)
    drop personas total
    reshape wide pct, i(year) j(ocupado)

    label var pct0 "No ocupadas"
    label var pct1 "Ocupadas"

    * Variable de fecha
    gen fecha = yq(year, 1)
    format fecha %tq

    * Gráfico estilo Economist personalizado
    twoway ///
        (line pct0 fecha, lcolor("228 26 28") lwidth(thick)) ///
        (line pct1 fecha, lcolor("77 175 74") lwidth(thick)), ///
        title("Situación laboral de las mujeres en la ENOE", size(medium)) ///
        subtitle("Porcentaje anual, 2005–2024", size(small)) ///
        xtitle("Año") ///
        ytitle("Porcentaje") ///
        xlabel(, format(%tq) labsize(small)) ///
        ylabel(, labsize(small)) ///
        legend(order(1 "No ocupadas" 2 "Ocupadas") cols(2) size(small) pos(6)) ///
        xsize(8) ysize(4)

    * Exportar imagen
    local graf_path = "${enoe_path}/graficas"
    cap mkdir "`graf_path'"
    graph export "`graf_path'/Grafica_MUJERES_OCUPADAS_ENOE.png", replace

restore

/******************************************************************************************
*           PASO 13 - DISTRIBUCIÓN DE MUJERES POR NIVEL EDUCATIVO (POR AÑO)              *
*     Objetivo: Calcular la proporción de mujeres en cada nivel educativo según ENOE      *
******************************************************************************************/

preserve

    * Filtrar solo mujeres
    keep if sex == 2

    * Crear variable educativa
    gen nivel_edu = .
    replace nivel_edu = 0 if inlist(cs_p13_1, 0, 1)
    replace nivel_edu = 1 if cs_p13_1 == 2
    replace nivel_edu = 2 if cs_p13_1 == 3
    replace nivel_edu = 3 if inlist(cs_p13_1, 4, 5, 6)
    replace nivel_edu = 4 if cs_p13_1 == 7
    replace nivel_edu = 5 if inlist(cs_p13_1, 8, 9)

    * Etiquetas
    label define educn 0 "Sin estudios" 1 "Primaria" 2 "Secundaria" 3 "Media Superior" ///
                       4 "Superior" 5 "Posgrado"
    label values nivel_edu educn
    label variable nivel_edu "Nivel educativo"

    * Verificar tipo del ponderador
    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    * Tabla con porcentajes por nivel
    collect clear
    collect: table year, statistic(fvpercent nivel_edu) nototals [fw=fac]

    * Exportar a Excel
    putexcel set "${enoe_path}/ENOE_cuadros.xlsx", sheet(mujeres_educacion) modify
    putexcel A2 = collect

restore


/******************************************************************************************
*           EXPORTACIÓN A LaTeX - MUJERES POR NIVEL EDUCATIVO (PORCENTAJE)               *
******************************************************************************************/

preserve

    * Filtrar solo mujeres
    keep if sex == 2

    * Crear variable educativa
    gen nivel_edu = .
    replace nivel_edu = 0 if inlist(cs_p13_1, 0, 1)
    replace nivel_edu = 1 if cs_p13_1 == 2
    replace nivel_edu = 2 if cs_p13_1 == 3
    replace nivel_edu = 3 if inlist(cs_p13_1, 4, 5, 6)
    replace nivel_edu = 4 if cs_p13_1 == 7
    replace nivel_edu = 5 if inlist(cs_p13_1, 8, 9)

    label values nivel_edu educn

    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    gen uno = 1
    collapse (sum) personas = uno [fw=fac], by(year nivel_edu)

    bys year: egen total = total(personas)
    gen pct = 100 * personas / total

    * Exportación a archivo .tex
    file open tex_out using "${enoe_path}/ENOE_MUJERES_EDUCACION.tex", write replace
    file write tex_out "%% Tabla generada desde Stata - Mujeres por nivel educativo" _n
    file write tex_out "\begin{tabular}{lrrrrrr}" _n
    file write tex_out "\hline" _n
    file write tex_out "Año & Sin estudios & Primaria & Secundaria & Media Superior & Superior & Posgrado \\\\" _n
    file write tex_out "\hline" _n

    quietly {
        levelsof year, local(anios)
        foreach y of local anios {
            local fila "`y'"
            foreach e in 0 1 2 3 4 5 {
                quietly summarize pct if year == `y' & nivel_edu == `e'
                local val = cond(r(N) > 0, string(r(mean), "%5.1f"), "0.0")
                local fila "`fila' & `val'\%"
            }
            file write tex_out "`fila' \\\\" _n
        }
    }

    file write tex_out "\hline" _n
    file write tex_out "\end{tabular}" _n
    file close tex_out

restore


/******************************************************************************************
*               GRAFICA - DISTRIBUCIÓN EDUCATIVA DE MUJERES EN LA ENOE                   *
******************************************************************************************/

preserve

    * Filtrar solo mujeres
    keep if sex == 2

    * Crear variable educativa
    gen nivel_edu = .
    replace nivel_edu = 0 if inlist(cs_p13_1, 0, 1)
    replace nivel_edu = 1 if cs_p13_1 == 2
    replace nivel_edu = 2 if cs_p13_1 == 3
    replace nivel_edu = 3 if inlist(cs_p13_1, 4, 5, 6)
    replace nivel_edu = 4 if cs_p13_1 == 7
    replace nivel_edu = 5 if inlist(cs_p13_1, 8, 9)

    label values nivel_edu educn

    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    gen uno = 1
    collapse (sum) personas = uno [fw=fac], by(year nivel_edu)
    bysort year: egen total = total(personas)
    gen pct = 100 * personas / total

    drop personas
    drop if missing(nivel_edu)

    reshape wide pct, i(year) j(nivel_edu)

    * Crear variable de tiempo
    gen fecha = yq(year, 1)
    format fecha %tq

    * Etiquetas
    label variable pct0 "Sin estudios"
    label variable pct1 "Primaria"
    label variable pct2 "Secundaria"
    label variable pct3 "Media Superior"
    label variable pct4 "Superior"
    label variable pct5 "Posgrado"

    * Gráfico tipo connected con símbolos pequeños
    twoway ///
    (connected pct0 fecha, lcolor(red)       lwidth(thin) msymbol(o) msize(vsmall)) ///
    (connected pct1 fecha, lcolor(blue)      lwidth(thin) msymbol(o) msize(vsmall)) ///
    (connected pct2 fecha, lcolor(green)     lwidth(thin) msymbol(o) msize(vsmall)) ///
    (connected pct3 fecha, lcolor(orange)    lwidth(thin) msymbol(o) msize(vsmall)) ///
    (connected pct4 fecha, lcolor(purple)    lwidth(thin) msymbol(o) msize(vsmall)) ///
    (connected pct5 fecha, lcolor(gs5)       lwidth(thin) msymbol(o) msize(vsmall)), ///
        title("Nivel educativo de mujeres en la ENOE", size(medium)) ///
        subtitle("Porcentaje anual, 2005–2024", size(small)) ///
        xtitle("Año") ///
        ytitle("Porcentaje") ///
        xlabel(, format(%tq) labsize(small)) ///
        ylabel(, labsize(small)) ///
        legend(order(1 "Sin estudios" 2 "Primaria" 3 "Secundaria" 4 "Media Superior" 5 "Superior" 6 "Posgrado") ///
               cols(3) size(small) pos(6)) ///
        graphregion(color(white) margin(l+5)) ///
        plotregion(color(white)) ///
        xsize(8) ysize(4.5)

    * Exportar imagen
    local graf_path = "${enoe_path}/graficas"
    cap mkdir "`graf_path'"
    graph export "`graf_path'/Grafica_MUJERES_EDUCACION_ENOE.png", replace

restore


/******************************************************************************************
*     PASO 14.1 - Distribución de mujeres por estado civil (promedio anual)              *
******************************************************************************************/

preserve

    * Filtrar solo mujeres
    keep if sex == 2

    * Limpiar estado civil: 9 = No especificado
    gen estado_civil = e_con
    replace estado_civil = . if estado_civil == 9

    * Etiquetas
    label define edocivil 1 "Unión libre" 2 "Separada" 3 "Divorciada" 4 "Viuda" 5 "Casada" 6 "Soltera", replace
    label values estado_civil edocivil
    label variable estado_civil "Estado civil"

    * Tabla con porcentajes por año
    collect clear
    collect: table year, statistic(fvpercent estado_civil) nototals [fw=fac]

    * Exportar a Excel
    putexcel set "${enoe_path}/ENOE_cuadros.xlsx", sheet(mujeres_estado_civil) modify
    putexcel A2 = collect

restore


/******************************************************************************************
*     PASO 14.2 - Exportación a LaTeX: Mujeres por estado civil                          *
******************************************************************************************/

preserve

    keep if sex == 2

    * Limpiar variable
    gen estado_civil = e_con
    replace estado_civil = . if estado_civil == 9
    label values estado_civil edocivil

    * Ponderador
    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    * Conteo y porcentajes
    gen uno = 1
    collapse (sum) personas = uno [fw=fac], by(year estado_civil)
    bys year: egen total = total(personas)
    gen pct = 100 * personas / total

    * Exportación
    file open tex_out using "${enoe_path}/ENOE_MUJERES_EDOCIVIL.tex", write replace
    file write tex_out "%% Tabla generada desde Stata - ENOE: Mujeres por estado civil" _n
    file write tex_out "\begin{tabular}{lrrrrrr}" _n
    file write tex_out "\hline" _n
    file write tex_out "Año & Unión libre & Separada & Divorciada & Viuda & Casada & Soltera \\\\" _n
    file write tex_out "\hline" _n

    quietly {
        levelsof year, local(anios)
        foreach y of local anios {
            local fila "`y'"
            foreach e in 1 2 3 4 5 6 {
                quietly summarize pct if year == `y' & estado_civil == `e'
                local val = cond(r(N)>0, string(r(mean), "%5.1f"), "0.0")
                local fila "`fila' & `val'\%"
            }
            file write tex_out "`fila' \\\\" _n
        }
    }

    file write tex_out "\hline" _n
    file write tex_out "\end{tabular}" _n
    file close tex_out

restore


/******************************************************************************************
*     PASO 14.3 - Gráfico de evolución del estado civil de mujeres                       *
******************************************************************************************/

preserve

    keep if sex == 2

    * Variable limpia
    gen estado_civil = e_con
    replace estado_civil = . if estado_civil == 9
    label values estado_civil edocivil

    * Verificación del ponderador
    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    gen uno = 1
    collapse (sum) personas = uno [fw=fac], by(year estado_civil)
    bysort year: egen total = total(personas)
    gen pct = 100 * personas / total

    drop personas
    drop if missing(estado_civil)

    * Reshape para graficar
    reshape wide pct, i(year) j(estado_civil)

    * Crear fecha para eje X
    gen fecha_yq = yq(year, 1)
    format fecha_yq %tq

    * Etiquetas de cada línea
    label variable pct1 "Unión libre"
    label variable pct2 "Separada"
    label variable pct3 "Divorciada"
    label variable pct4 "Viuda"
    label variable pct5 "Casada"
    label variable pct6 "Soltera"

    * Gráfico
    twoway ///
    (connected pct1 fecha_yq, lcolor(red)       lwidth(thin) msymbol(o) msize(vsmall)) ///
    (connected pct2 fecha_yq, lcolor(blue)      lwidth(thin) msymbol(o) msize(vsmall)) ///
    (connected pct3 fecha_yq, lcolor(green)     lwidth(thin) msymbol(o) msize(vsmall)) ///
    (connected pct4 fecha_yq, lcolor(orange)    lwidth(thin) msymbol(o) msize(vsmall)) ///
    (connected pct5 fecha_yq, lcolor(purple)    lwidth(thin) msymbol(o) msize(vsmall)) ///
    (connected pct6 fecha_yq, lcolor(gs5)       lwidth(thin) msymbol(o) msize(vsmall)), ///
        title("Estado civil de mujeres en la ENOE", size(large)) ///
        subtitle("Porcentaje por trimestre (T1), 2005–2024", size(small)) ///
        xtitle("Trimestre", size(medium)) ///
        ytitle("%", size(medium)) ///
        xlabel(, format(%tq) labsize(small)) ///
        ylabel(, labsize(small)) ///
        legend(order(1 "Unión libre" 2 "Separada" 3 "Divorciada" 4 "Viuda" 5 "Casada" 6 "Soltera") ///
               cols(3) size(small) placement(south outside) region(fcolor(white) lcolor(none))) ///
        xscale(range(`=fecha_yq[1]-1' `=fecha_yq[_N]')) ///
        graphregion(color(white) margin(l+5)) ///
        plotregion(color(white)) ///
        xsize(8) ysize(4.5)

    * Exportación
    graph export "${graf_path}/Grafica_MUJERES_EDOCIVIL_ENOE.png", replace

restore


/******************************************************************************************
*     PASO 15.1 - Porcentaje de mujeres que tienen hijos                                 *
******************************************************************************************/

preserve

    * Filtrar solo mujeres
    keep if sex == 2

    * Crear variable binaria: tiene hijos
    gen byte hijos = .
    replace hijos = 0 if n_hij == 0
    replace hijos = 1 if inrange(n_hij, 1, 98)
    replace hijos = . if n_hij == 99

    * Etiquetas para visualización
    capture label define hijosl 0 "No tiene" 1 "Tiene", replace
    label values hijos hijosl
    label variable hijos "Tiene hijos"

    * Tabla: porcentaje ponderado
    collect clear
    collect: table year, statistic(fvpercent hijos) nototals [fw=fac]

    * Exportar a Excel
    putexcel set "D:\INVESTIGACION\DATA\ENOE\ENOE_cuadros.xlsx", sheet(mujeres_hijos) modify
    putexcel A2 = collect

restore


/******************************************************************************************
*     PASO 15.2 - Exportación a LaTeX: Mujeres con hijos                                 *
******************************************************************************************/

preserve

    keep if sex == 2

    * Variable binaria de hijos
    gen byte hijos = .
    replace hijos = 0 if n_hij == 0
    replace hijos = 1 if inrange(n_hij, 1, 98)
    replace hijos = . if n_hij == 99
    label values hijos hijosl

    * Ponderador
    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    * Conteo y porcentaje
    gen uno = 1
    collapse (sum) personas = uno [fw=fac], by(year hijos)
    bys year: egen total = total(personas)
    gen pct = 100 * personas / total

    * Exportar a .tex
    file open tex_out using "D:\INVESTIGACION\DATA\ENOE\ENOE_MUJERES_HIJOS.tex", write replace
    file write tex_out "%% Tabla generada desde Stata - Mujeres que tienen hijos" _n
    file write tex_out "\begin{tabular}{lrr}" _n
    file write tex_out "\hline" _n
    file write tex_out "Año & No tiene (\%) & Tiene (\%) \\\\" _n
    file write tex_out "\hline" _n

    quietly {
        levelsof year, local(anios)
        foreach y of local anios {
            quietly summarize pct if year == `y' & hijos == 0
            local no = cond(r(N)>0, string(r(mean), "%5.1f"), "0.0")
            quietly summarize pct if year == `y' & hijos == 1
            local si = cond(r(N)>0, string(r(mean), "%5.1f"), "0.0")
            file write tex_out "`y' & `no'\% & `si'\% \\\\" _n
        }
    }

    file write tex_out "\hline" _n
    file write tex_out "\end{tabular}" _n
    file close tex_out

restore

/******************************************************************************************
*     PASO 15.3 - Gráfico de mujeres que tienen hijos (porcentaje)                      *
******************************************************************************************/

preserve

    keep if sex == 2

    gen byte hijos = .
    replace hijos = 0 if n_hij == 0
    replace hijos = 1 if inrange(n_hij, 1, 98)
    replace hijos = . if n_hij == 99
    label values hijos hijosl

    capture confirm numeric variable fac
    if _rc != 0 destring fac, replace force

    gen uno = 1
    collapse (sum) personas = uno [fw=fac], by(year hijos)
    bys year: egen total = total(personas)
    gen pct = 100 * personas / total

    drop personas
    drop if missing(hijos)
    reshape wide pct, i(year) j(hijos)

    gen fecha_yq = yq(year, 1)
    format fecha_yq %tq

    label variable pct0 "No tiene"
    label variable pct1 "Tiene"

    twoway ///
    (connected pct0 fecha_yq, lcolor(red)   lwidth(thin) msymbol(o) mcolor(red)   msize(vsmall)) ///
    (connected pct1 fecha_yq, lcolor(blue)  lwidth(thin) msymbol(o) mcolor(blue)  msize(vsmall)), ///
        title("Mujeres con hijos en la ENOE", size(large) color(black)) ///
        subtitle("Porcentaje por trimestre (T1), 2005–2024", size(medsmall) color(gs6)) ///
        xtitle("Trimestre", size(medium)) ///
        ytitle("%", size(medium)) ///
        xlabel(, format(%tq) labsize(medium)) ///
        ylabel(, labsize(medium)) ///
        legend(order(1 "No tiene" 2 "Tiene") ///
               cols(2) size(small) placement(south outside) region(fcolor(white) lcolor(none))) ///
        xscale(range(`=fecha_yq[1]-1' `=fecha_yq[_N]')) ///
        graphregion(color(white) margin(l+5)) ///
        plotregion(color(white)) ///
        xsize(8) ysize(4.5)

    * Exportar imagen
    graph export "$graf\Grafica_MUJERES_HIJOS_ENOE.png", replace

restore



