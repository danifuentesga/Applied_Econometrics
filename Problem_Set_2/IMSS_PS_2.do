/****************************************************************************************** AUTOR:   Daniel Fuentes (Github: danifuentesga )
* FECHA:   31-ago-2025
* TEMA:    Homologación de bases de datos IMSS (2000-2025)
******************************************************************************************/

* Si Stata se tarda, no se desesperen: está echando chamba fina (o eso dice).
*Y si sale un error raro... respira hondo, prende una veladora junto al busto de Alfonso Reyes 
*que esta en la entrada del Colegio, revisa los labels, Y A DARLE QUE ESTO ES MOLE DE OLLA


**************************************************************************
               //# PASO 0: GLOBALS      *
**************************************************************************

* Definir ruta principal del proyecto donde están los datos del IMSS
global IMSS "D:\INVESTIGACION\DATA\IMSS"

* Ruta de destino de graficas
global graf "D:\INVESTIGACION\DATA\IMSS\GRAFICAS_PS2"


// *******************************************************************
// PASO 0: (OPCIONAL) RECONSTRUIR IMSS_x.dta CON VARAIABLES DE AÑO, MES Y FECHA
// *******************************************************************

// *******************************************************************
// APPEND ANUAL DE BASES MENSUALES (ROBUSTO Y COMPACTO)
// *******************************************************************

forvalues x = 2000/2025 {

    local folder "$IMSS\\`x'"
    local outfile "`folder'\\IMSS_`x'.dta"
    local files : dir "`folder'" files "asg-*.dta"
    local n : word count `files'

    // --- Abrir primer archivo del año ---
    local f1 : word 1 of `files'
    use "`folder'\\`f1'", clear

    // Homologar fecha -> siempre 'date'
    capture confirm variable fecha
    if !_rc {
        capture confirm variable date
        if _rc rename fecha date
        else drop fecha
    }

    // YEAR constante del año de la carpeta
    capture drop year
    gen year = `x'

    // MONTH para el primer archivo (tomado del nombre asg-AAAA-MM-DD.dta)
    capture drop month
    local m1 = real(substr("`f1'", 10, 2))
    gen month = `m1'

    // --- Append del resto de archivos del año ---
    forvalues i = 2/`n' {
        local f : word `i' of `files'
        local mcur = real(substr("`f'", 10, 2))
        local N0 = _N

        append using "`folder'\\`f'"

        // Homologar fecha tras el append
        capture confirm variable fecha
        if !_rc {
            replace date = fecha if missing(date)
            drop fecha
        }

        // Asignar year y month SOLO a las filas recién anexadas
        replace year  = `x'    if _n > `N0'
        replace month = `mcur' if _n > `N0'
    }

    save "`outfile'", replace
    di ">>> Archivo IMSS_`x'.dta creado."
}


//***************************************************************************

            //#2 PROBLEMA   *
			
//***************************************************************************

//***************************************************************************

            //##2.1: GRAFICA POR SEXO DE LOS QUE TRABAJAN     *
			
//***************************************************************************

//###PASO 1. Crear bases anuales colapsadas a nivel ta
// Cada loop abre la base anual, colapsa y guarda versión reducida
forvalues x = 2000/2025 {
    use "$IMSS\\`x'\\IMSS_`x'.dta", clear
    keep ta sexo year month date masa_sal_ta
    keep if masa_sal_ta > 0
    collapse (sum) ta, by(month year date sexo)
    save "$IMSS\\`x'\\IMSS_`x'ta.dta", replace
}

//###PASO 2. Unir todas las bases anuales en una sola
// Empezamos con la primera (2000) y vamos anexando las demás
use "$IMSS\\2000\\IMSS_2000ta.dta", clear
forvalues x = 2001/2025 {
    append using "$IMSS\\`x'\\IMSS_`x'ta.dta"
}
save "$IMSS\\IMSShoja1.dta", replace

//### PASO 3. Reestructurar para graficar
// Abrimos la base consolidada
use "$IMSS\\IMSShoja1.dta", clear

// Eliminamos registros con sexo missing porque no sirven para el reshape
drop if missing(sexo)

// Pasamos de formato largo a ancho (crea ta1=Hombres, ta2=Mujeres)
reshape wide ta, i(month year date) j(sexo)

// Creamos variable total sumando hombres y mujeres
gen ta = ta1 + ta2

// Etiquetas descriptivas
label variable ta  "Trabajadores asegurados"
label variable ta1 "Hombres"
label variable ta2 "Mujeres"


//### PASO 4. Escalar a millones y preparar serie
// Convertimos las cifras a millones para mejor interpretación
replace ta  = ta/1000000
replace ta1 = ta1/1000000
replace ta2 = ta2/1000000

preserve

* Declarar serie de tiempo mensual
tsset date, monthly

* Etiquetas claras para la gráfica
label variable ta  "Total"
label variable ta1 "Hombres"
label variable ta2 "Mujeres"

* Gráfica con formato estandarizado
twoway ///
    (connected ta  date, lcolor("255 69 0")   mcolor("255 69 0")   lwidth(vvvthin) msize(0.2)) ///
    (connected ta1 date, lcolor("24 116 205") mcolor("24 116 205") lwidth(vvvthin) msize(0.2)) ///
    (connected ta2 date, lcolor("34 139 34")  mcolor("34 139 34")  lwidth(vvvthin) msize(0.2)), ///
    xtitle("Mes", size(medium)) ///
    ytitle("Trabajadores asegurados (millones)", size(medium)) ///
    xlabel(, labsize(medium)) ///
    ylabel(, labsize(medium)) ///
    legend(order(1 "Total" 2 "Hombres" 3 "Mujeres") position(12) ring(0) cols(3)) ///
    graphregion(color(white)) plotregion(lstyle(none)) ///
    note(" ")

graph export "$graf\\IMSS_2_1.png", replace

restore
//***************************************************************************

            //##2.2: GRAFICA PROMEDIO Y MEDIANA DEL INGRESO   *
			
//***************************************************************************

//### PASO 1. Importar Excel de INPC DE BAXICO (Indice) y guardar en .dta sin cambios de Ene 200 a Jul 2025
//**** https://www.banxico.org.mx/SieInternet/consultarDirectorioInternetAction.do?sector=8&accion=consultarCuadro&idCuadro=CP154&locale=es*********************



import excel "$IMSS\\INPC_MENSUAL.xlsx", firstrow clear
save "$IMSS\\INPC_raw.dta", replace

//### PASO 2. Convertir fecha y generar variables auxiliares
use "$IMSS\\INPC_raw.dta", clear

gen mdate = mofd(date)   // convierte la fecha diaria a mensual
format mdate %tm

gen year  = year(dofm(mdate))
gen month = month(dofm(mdate))
drop date
order mdate year month ipc
rename mdate date
rename ipc inpc

save "$IMSS\\INPC_MENSUAL.dta", replace

//### PASO 3. Incorporar INPC y calcular ingresos reales
forvalues x = 2000/2025 {
    
    * Abrir base anual
    use "$IMSS\\`x'\\IMSS_`x'.dta", clear
    
    * Conservar sólo variables necesarias
    keep year month date cve_entidad cve_municipio cve_delegacion sexo rango_edad ta ta_sal masa_sal_ta
    keep if masa_sal_ta > 0
    
    * Unir con INPC mensual
    merge m:1 date using "$IMSS\\INPC_MENSUAL.dta", keep(match) nogenerate
    
    * Ingreso promedio nominal y real
    gen ing = masa_sal_ta/ta
    replace ing = (ing/inpc)*100
    
    * Guardar resultado
    save "$IMSS\\`x'\\IMSS_INPC_`x'.dta", replace
}


clear

//### PASO 4. Medias, medianas y percentiles de ingresos reales
forvalues x = 2000/2025 {
    
    * Abrir la base anual con ingresos reales
    use "$IMSS\\`x'\\IMSS_INPC_`x'.dta", clear
    
    * Colapsar por mes con ponderador ta (en silencio)
	* Elegimos p65 p70 p75 porque por aqui se acerca mas el promedio
    qui collapse (mean)   ing_mean=ing ///
                 (median) ing_med=ing ///
                 (p65)    ing_p65=ing ///
                 (p70)    ing_p70=ing ///
                 (p75)    ing_p75=ing [aw=ta], by(date)
    
    * Guardar resultados en nueva base anual (en silencio)
    qui save "$IMSS\\`x'\\IMSS_INGREAL`x'.dta", replace
}



//### PASO 5. Unir todas las bases anuales con medias, medianas y percentiles

* Abrir la primera base (año 2000)
use "$IMSS\\2000\\IMSS_INGREAL2000.dta", clear

* Hacer append de los años siguientes
forvalues x = 2001/2025 {
    append using "$IMSS\\`x'\\IMSS_INGREAL`x'.dta"
}

* Guardar la base consolidada
save "$IMSS\\IMSShoja2.dta", replace

//### PASO 6. Gráfica de la media y mediana de salarios reales
use "$IMSS\\IMSShoja2.dta", clear
preserve

* Etiquetas claras
label variable ing_mean "Media"
label variable ing_med  "Mediana"

* Definir serie temporal mensual
tsset date, monthly

** Grafica 
twoway ///
    (connected ing_mean date, lcolor("255 69 0")   mcolor("255 69 0") ///
        lwidth(vthin) msize(0.4)) ///
    (connected ing_med  date, lcolor("24 116 205") mcolor("24 116 205") ///
        lwidth(vthin) msize(0.4)), ///
    xtitle("Mes", size(medium)) ///
    ytitle("Salario Real", size(medium)) ///
    legend(order(1 "Promedio" 2 "Mediana") position(12) ring(0) cols(2)) ///
    graphregion(color(white)) plotregion(lstyle(none)) ///
    note(" ")

graph export "$graf\\IMSS_2_2.png", replace
restore

*******************************************************************

//## 2.3 GRAFICA POR PERCENTILES


********************************************************************

//### PASO 1. Deinifir variables
use "$IMSS\\IMSShoja2.dta", clear
preserve

* Etiquetas
label variable ing_mean "Media"
label variable ing_med  "Mediana"
label variable ing_p65  "P65"
label variable ing_p70  "P70"
label variable ing_p75  "P75"

* Definir serie temporal
tsset date, monthly

* Gráfica con mspline y distintos estilos
* Gráfica por percentil 
twoway ///
    (connected ing_mean date, lcolor("255 69 0")   lwidth(thin) mcolor("255 69 0")   msize(0.4)) /// naranja metálico
    (connected ing_med  date, lcolor("24 116 205") lwidth(thin) mcolor("24 116 205") msize(0.4)) /// azul metálico
    (connected ing_p65  date, lcolor("78 238 148")  lpattern(thin) mcolor("78 238 148")  msize(0.4)) /// cyan
    (connected ing_p70  date, lcolor("127 255 0")  lpattern(thin) mcolor("127 255 0")  msize(0.4)) /// verde neón
    (connected ing_p75  date, lcolor("238 201 0")         lpattern(thin) mcolor("238 201 0")         msize(0.4)), /// teal
    xtitle("Mes", size(medium)) ///
    ytitle("Salario Real", size(medium)) ///
    legend(order(1 "Promedio" 2 "Mediana" 3 "P65" 4 "P70" 5 "P75") ///
           position(12) ring(0) cols(3)) ///
    graphregion(color(white)) plotregion(lstyle(none)) ///
    note(" ")

graph export "$graf\\IMSS_2_3.png", replace
restore

***************************************************************

//## 2.4 GRAFICA DE BRECHA DE GENERO DE INGRESO REAL 

***************************************************************

//### PASO 1. Calcular medias y medianas por sexo (ponderadas por ta) y guardar por año
forvalues x = 2000/2025 {
    use "$IMSS\\`x'\\IMSS_INPC_`x'.dta", clear
    collapse (mean) ing_mean=ing (median) ing_med=ing [aw=ta], by(date sexo)
    save "$IMSS\\`x'\\IMSS_BRECHA`x'.dta", replace
}

clear

//### PASO 2. Unir todas las bases anuales en una sola
use "$IMSS\\2000\\IMSS_BRECHA2000.dta", clear
forvalues x = 2001/2025 {
    append using "$IMSS\\`x'\\IMSS_BRECHA`x'.dta"
}
save "$IMSS\\IMSS_hoja3.dta", replace


//### PASO 3. Reestructurar y calcular brechas
use "$IMSS\\IMSS_hoja3.dta", clear

* Pasar a formato ancho: hombres vs mujeres
reshape wide ing_mean ing_med, i(date) j(sexo)

* Calcular brechas porcentuales (Mujeres/Hombres - 1)*100
gen gap_mean = ((ing_mean1/ing_mean2) - 1) * 100
gen gap_med  = ((ing_med1/ing_med2)  - 1) * 100

save "$IMSS\\IMSS_hoja3.dta", replace



//### PASO 4. Gráfica de medias de salario real por sexo
preserve

* Etiquetas claras
label variable ing_mean1 "Mujeres"
label variable ing_mean2 "Hombres"

* Definir serie temporal mensual
tsset date, monthly

** Gráfica con estilo moderno
twoway /// 
    (connected ing_mean1 date, lcolor("255 69 0")   mcolor("255 69 0") ///
        lwidth(vthin) msize(0.4)) ///    // Mujeres en naranja metálico
    (connected ing_mean2 date, lcolor("24 116 205") mcolor("24 116 205") ///
        lwidth(vthin) msize(0.4)), ///   // Hombres en azul metálico
    xtitle("Mes", size(medium)) ///
    ytitle("Salario Real", size(medium)) ///
    legend(order(1 "Hombres" 2 "Mujeres") position(12) ring(0) cols(2)) ///
    graphregion(color(white)) plotregion(lstyle(none)) ///
    note(" ")

graph export "$graf\\IMSS_2_4.png", replace
restore


//### PASO 5. Gráfica de la brecha salarial (medias)
preserve

* Etiqueta clara
label variable gap_mean "Brecha salarial (Promedio, %) "

* Definir serie temporal mensual
tsset date, monthly

** Gráfica con estilo moderno
twoway ///
    (connected gap_mean date, lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(vthin) msize(0.4)), /// dorado metálico (gold2)
    xtitle("Mes", size(medium)) ///
    ytitle("Brecha salarial (%)", size(medium)) ///
    legend(order(1 "Brecha (media)") position(12) ring(0) cols(1)) ///
    graphregion(color(white)) plotregion(lstyle(none)) ///
    note(" ")

graph export "$graf\\IMSS_2_41.png", replace
restore

***************************************************************

//## 2.5 FREAKING BOOTSTRAP

***************************************************************

//### PASO 1. Crear versiones ligeras para bootstrap
forvalues x = 2000/2025 {
    use "$IMSS\\`x'\\IMSS_INPC_`x'.dta", clear
    
    // Nos quedamos solo con las variables que necesitamos
    keep sexo ing ta month date
    
    // Guardar base reducida
    save "$IMSS\\`x'\\IMSS_LIGHT_BOOTS_`x'.dta", replace
    di ">>> Base ligera creada: IMSS_LIGHT_BOOTS_`x'.dta"
}

//### PASO 2. Bootstrap manual de la brecha de género
clear

// Crear archivo final vacío
save "$IMSS\\IMSS_BOOTSTRAP.dta", emptyok replace

// Loop por años
forvalues x = 2000/2025 {
    
    // Abrir base anual (LIGHT)
    use "$IMSS\\`x'\\IMSS_LIGHT_BOOTS_`x'.dta", clear
    
    // Definir número de meses
    local maxm = cond(`x'==2025, 7, 12)
    
    // Loop por meses
    forvalues m = 1/`maxm' {
        preserve
            keep if month == `m'
            gen ling = ln(ing)
            gen sex  = sexo - 1   // Hombres=0, Mujeres=1
            
            // Guardar submuestra temporal
            save "$IMSS\\TEMPORAL.dta", replace
            
            // Bootstrap manual con 100 réplicas
            forvalues q = 1/100 {
                quietly use "$IMSS\\TEMPORAL.dta", clear
                quietly bsample
                quietly regress ling sex [aw=ta], robust
                gen bsample = `q'
                gen bsex    = _b[sex]
                keep bsample bsex
                keep if _n==1
                
                if `q'==1 {
                    save "$IMSS\\BSAMPLE_`x'_`m'.dta", replace
                }
                else {
                    append using "$IMSS\\BSAMPLE_`x'_`m'.dta"
                    save "$IMSS\\BSAMPLE_`x'_`m'.dta", replace
                }
            }
            
            // Calcular promedio y desviación estándar
            use "$IMSS\\BSAMPLE_`x'_`m'.dta", clear
            egen se   = sd(bsex)
            egen coef = mean(bsex)
            keep if _n==1
            gen year = `x'
            gen mes  = `m'
            
            // Acumular en archivo final
            append using "$IMSS\\IMSS_BOOTSTRAP.dta"
            save "$IMSS\\IMSS_BOOTSTRAP.dta", replace
            
            di ">>> Listo: Año `x', Mes `m'"
        restore
    }
}



//### PASO FINAL. Graficar
use "$IMSS\\IMSS_BOOTSTRAP.dta", clear

// --- Asegurarte que 2025 solo usa los meses disponibles ---
drop if year == 2025 & mes == 7


// Generar fecha mensual
gen date = ym(year, mes)
format date %tm

// Intervalos de confianza
gen lb = coef - (1.96*se)
gen hb = coef + (1.96*se)

label variable coef "OLS"
label variable lb   "CI 95%"
label variable hb   "CI 95%"

// Graficar
twoway ///
    (rarea lb hb date, color(gs8%35) lcolor(gs8)) ///
    (connected coef date, ///
        lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(vthin) msize(0.3)), ///
    yscale(reverse range(-0.16 0)) ///
    ylabel(-0.16(0.02)0, format(%4.2f)) ///
    xtitle("Mes") ///
    ytitle("Brecha salarial de género 2000–2025") ///
    note(" ") ///
    legend(order(2 "OLS" 1 "CI 95%") position(1) ring(0) cols(1))

graph export "$graf\\IMSS_2_5_Bootstrap1.png", replace


//### PASO EXTRA 

twoway ///
    (rarea lb hb date, color(gs8%35) lcolor(gs8)) ///
    (connected coef date, ///
        lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(vthin) msize(0.4)), ///
		ylabel(-0.16(0.02)0, format(%4.2f)) ///
    xtitle("Mes", size(medium)) ///
    ytitle("Brecha salarial (%)", size(medium)) ///
    legend(order(2 "Brecha (media)" 1 "IC 95%") ///
           position(12) ring(0) cols(1)) ///
    graphregion(color(white)) ///
    plotregion(lstyle(none)) ///
    note(" ")


	graph export "$graf\\IMSS_2_51_Bootstrap2.png", replace

	
//### PASO EXTRA Graficar con promedios anuales
use "$IMSS\\IMSS_BOOTSTRAP.dta", clear

// Colapsar a nivel anual (promedio de coef y se)
collapse (mean) coef se, by(year)

// Calcular intervalos de confianza anuales
gen lb = coef - 1.96*se
gen hb = coef + 1.96*se

// Fecha representada como junio de cada año (mes 6)
gen date = ym(year, 6)
format date %tm

// Etiquetas
label variable coef "OLS"
label variable lb   "CI 95%"
label variable hb   "CI 95%"

// Gráfico con promedios anuales
twoway ///
    (rarea lb hb date, color(gs8%35) lcolor(gs8)) /// banda IC
    (connected coef date, ///
        lcolor("255 69 0") mcolor("255 69 0") ///
        lwidth(thin) msize(0.5)), ///
		ylabel(-0.16(0.02)0, format(%4.2f)) ///
    xtitle("Año") ///
    ytitle("Brecha salarial de género (promedio anual)") ///
    legend(order(2 "OLS" 1 "IC 95%") position(12) ring(0) cols(1)) ///
    graphregion(color(white)) ///
    plotregion(lstyle(none)) ///
    note(" ")

graph export "$graf\\IMSS_Bootstrap_promedios.png", replace

***************************************************************

//## 2.6 GRAFICAS DE BRCHA DE GENERO FEB 2020 VS JULIO 2025

***************************************************************

//### PASO 1. Generar base de Febrero 2020
use "$IMSS\\2020\\IMSS_INPC_2020.dta", clear
keep if month == 2
collapse (mean) ing_mean=ing (median) ing_med=ing [aw=ta], by(year cve_entidad sexo)
save "$IMSS\\2020\\FEBRERO2020.DTA", replace
clear

//### PASO 2. Generar base de Julio 2025
use "$IMSS\\2025\\IMSS_INPC_2025.dta", clear
keep if month == 7
collapse (mean) ing_mean=ing (median) ing_med=ing [aw=ta], by(year cve_entidad sexo)
save "$IMSS\\2025\\JULIO2025.DTA", replace
clear

//### PASO 3. Unir las dos bases y calcular brecha
use "$IMSS\\2020\\FEBRERO2020.DTA", clear
append using "$IMSS\\2025\\JULIO2025.DTA"

// Pasar a formato ancho: ingresos por sexo
reshape wide ing_mean ing_med, i(year cve_entidad) j(sexo)

// Calcular brecha salarial en %
gen brecha = ((ing_mean1 / ing_mean2) - 1) * 100   // hombres vs mujeres

// Variables separadas por año
gen brecha2020 = brecha if year == 2020
gen brecha2025 = brecha if year == 2025

save "$IMSS\\RESUMEN_BRECHA.DTA", replace
label variable brecha2020 "2020 (Febrero)"
label variable brecha2025 "2025 (Julio)"

//### PASO 4. Calcular medias por año
summarize brecha2020 if !missing(brecha2020)
local m2020 = r(mean)

summarize brecha2025 if !missing(brecha2025)
local m2025 = r(mean)

//### PASO 5. Gráfica de barras comparativa con líneas de medias
graph bar brecha2020 brecha2025, over(cve_entidad, ///
    label(angle(90)) relabel(1"Ags" 2"BC" 3"BCS" 4"Camp" 5"Coah" 6"Col" 7"Chis" 8"Chih" 9"CDMX" ///
    10"Dur" 11"Gto" 12"Grro" 13"Hgo" 14"Jal" 15"Mex" 16"Mich" 17"Mor" 18"Nay" 19"NL" 20"Oax" ///
    21"Pue" 22"Qro" 23"QRoo" 24"SLP" 25"Sin" 26"Son" 27"Tab" 28"Tamps" 29"Tlax" 30"Ver" 31"Yuc" 32"Zac")) ///
    bar(1, bcolor(black) lcolor(black) lwidth(thin)) /// 2020 barra negra sólida
    bar(2, bcolor(white) lcolor(black) lwidth(thin)) /// 2025 blanca con borde negro
    legend(label(1 "2020 (Febrero (Promedio en Rojo))") label(2 "2025 (Julio (Promedio en Verde))") position(12) ring(0)) ///
    yline(`m2020', lcolor(red) lpattern(dot) lwidth(thick)) /// línea media 2020 negra
    yline(`m2025', lcolor(green) lpattern(dot) lwidth(thick)) /// línea media 2025 negra distinta

// Exportar gráfica
graph export "$graf\\IMSS_2_6.png", replace

******************************************************************

//## 2.7 GRAFICAS DE EMPLEO

*******************************************************************

//### PASO 1. Preparar bases de 2012 y 2025 (julio)
foreach y in 2012 2025 {
    use "$IMSS\\`y'\\IMSS_INPC_`y'.dta", clear
    keep if month==7
    collapse (mean) ta, by(year cve_entidad)
    save "$IMSS\\EMP_`y'.DTA", replace
}

//### PASO 2. Unir ambas bases
use "$IMSS\\EMP_2012.DTA", clear
append using "$IMSS\\EMP_2025.DTA"
save "$IMSS\\EMP_RESUMEN.DTA", replace

//### PASO 3. Reshape para calcular crecimiento
reshape wide ta, i(cve_entidad) j(year)
gen gta = ((ta2025/ta2012)-1)*100
label variable gta "Crecimiento porcentual 2012–2025"

//### PASO 4. Gráfica de barras con línea de promedio
summarize gta if !missing(gta)
local mgta = r(mean)

graph bar gta, over(cve_entidad, ///
    label(angle(90)) relabel(1"Ags" 2"BC" 3"BCS" 4"Camp" 5"Coah" 6"Col" 7"Chis" 8"Chih" 9"CDMX" ///
    10"Dur" 11"Gto" 12"Grro" 13"Hgo" 14"Jal" 15"Mex" 16"Mich" 17"Mor" 18"Nay" 19"NL" 20"Oax" ///
    21"Pue" 22"Qro" 23"QRoo" 24"SLP" 25"Sin" 26"Son" 27"Tab" 28"Tamps" 29"Tlax" 30"Ver" 31"Yuc" 32"Zac")) ///
    bar(1, bcolor(black) lcolor(black)) ///
    ytitle("Crecimiento porcentual del empleo (2012–2025)") ///
    yline(`mgta', lcolor(red) lpattern(dot) lwidth(thick))

graph export "$graf\\IMSS_2_7.png", replace




























