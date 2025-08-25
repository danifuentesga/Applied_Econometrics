/******************************************************************************************
* AUTOR DEL APPENDE DE BASES : Jaime Arrieta ( Github: Jaaror12 )
* AUTOR DE GRAFICAS:   Daniel Fuentes ( Github: danifuentesga )
* FECHA:   23-ago-2025
* TEMA:    Medición de Pobreza 2016-2024
* NOTA:    Se trabajo con do files ya proporcionado por INEGI para el Calculo de Pobreza
******************************************************************************************/

* Antes de correr esto... nos persignamos, echamos la bendición y que Stata nos agarre confesados.
* Suerte, compa.

/********************************************************************************
* DEFINICION DE CAMPO DE TRABAJO
********************************************************************************/

clear all
set more off

* Definir ruta principal de trabajo
global base "D:\INVESTIGACION\DATA\POBREZA"

* Cargar base de datos con panel de pobreza
use "$base\Pobreza Panel\pobreza_panel_16_24.dta", clear



/********************************************************************************
* 1. POBREZA POR INGRESO (TOTAL NACIONAL)
********************************************************************************/

preserve

* Calcular media ponderada del indicador plp por año
collapse (mean) plp [aw=factor], by(year)
gen pobreza_ingreso = plp*100

* Graficar evolución anual del porcentaje de población en pobreza de ingreso
twoway (connected pobreza_ingreso year, lcolor(navy) lwidth(medium) msymbol(O) mcolor(navy)), ///
    ytitle("Pobreza de ingreso (%)") ///
    xtitle("Año") ///
    title("Evolución de la pobreza de ingreso", size(medium) pos(11) style(bold)) ///
    subtitle("Porcentaje de la población con ingreso menor a la línea de pobreza", size(small) pos(11) color(gs8)) ///
    ylabel(, angle(horizontal) grid) xlabel(, labsize(small) grid) ///
    graphregion(color(white)) plotregion(color(white)) legend(off) ///
    yscale(lcolor(ltgreen%30)) xscale(lcolor(ltgreen%30))

* Exportar gráfica en alta resolución
graph export "$base\GRAFICAS\pobreza_ingreso.png", replace width(2000) height(1200)

restore



/********************************************************************************
* 2. TRAYECTORIAS DE CARENCIAS SOCIALES POR AÑO (PROMEDIOS PONDERADOS)
********************************************************************************/

preserve

* Calcular promedios ponderados de indicadores de carencias por año
collapse (mean) ic_rezedu ic_asalud ic_segsoc ic_cv ic_sbv ic_ali [aw=factor], by(year)

* Convertir variables de carencias a porcentaje
foreach v in ic_rezedu ic_asalud ic_segsoc ic_cv ic_sbv ic_ali {
    gen `v'_pct = `v'*100
}

* Etiquetar variables con nombres descriptivos
label var ic_rezedu_pct "Rezago educativo"
label var ic_asalud_pct "Acceso a servicios de salud"
label var ic_segsoc_pct "Acceso a seguridad social"
label var ic_cv_pct     "Calidad y espacios de la vivienda"
label var ic_sbv_pct    "Servicios básicos en la vivienda"
label var ic_ali_pct    "Alimentación nutritiva y de calidad"

* Gráfica de trayectorias de carencias (estilo CONEVAL)
twoway ///
 (connected ic_rezedu_pct year, msymbol(O) mcolor(navy)      lcolor(navy)      lwidth(med)) ///
 (connected ic_asalud_pct year, msymbol(O) mcolor(teal)      lcolor(teal)      lwidth(med)) ///
 (connected ic_segsoc_pct year, msymbol(O) mcolor(emerald)   lcolor(emerald)   lwidth(med)) ///
 (connected ic_cv_pct     year, msymbol(O) mcolor(maroon)    lcolor(maroon)    lwidth(med)) ///
 (connected ic_sbv_pct    year, msymbol(O) mcolor(orange)    lcolor(orange)    lwidth(med)) ///
 (connected ic_ali_pct    year, msymbol(O) mcolor(purple)    lcolor(purple)    lwidth(med)), ///
 ytitle("Población con carencia (%)") ///
 xtitle("Año") ///
 title("Pobreza Multidimensional por Carencia Social", pos(11) size(medium) style(bold)) ///
 subtitle("Trayectorias por dimensión (promedio ponderado)", pos(11) size(small) color(gs8)) ///
 ylabel(, angle(horizontal) grid labsize(medium)) ///
 xlabel(, grid labsize(medium)) ///
 graphregion(color(white)) plotregion(color(white)) ///
 legend(order(1 "Rezago educativo" 2 "Servicios de salud" 3 "Seguridad social" ///
              4 "Calidad y espacios" 5 "Servicios básicos" 6 "Alimentación") ///
        cols(3) ring(1) pos(6) region(lstyle(none)))

* Guardar imagen de salida
graph export "$base\GRAFICAS\trayectorias_carencias.png", replace width(2200) height(1300)

restore



/********************************************************************************
* 3. POBREZA POR INGRESO SEGÚN SEXO
********************************************************************************/

preserve

* Crear variable numérica para sexo (1 = Hombres, 2 = Mujeres)
gen sexo_num = .
replace sexo_num = 1 if sexo=="1"
replace sexo_num = 2 if sexo=="2"

* Asignar etiquetas
label define sexolbl 1 "Hombres" 2 "Mujeres"
label values sexo_num sexolbl

* Calcular promedio de pobreza por ingreso por sexo y año
collapse (mean) plp [aw=factor], by(year sexo_num)
gen pobreza_ingreso = plp*100

* Gráfica comparativa por sexo
twoway ///
 (connected pobreza_ingreso year if sexo_num==1, msymbol(O) mcolor(navy) lcolor(navy) lwidth(med)) ///
 (connected pobreza_ingreso year if sexo_num==2, msymbol(O) mcolor(maroon) lcolor(maroon) lwidth(med)), ///
 ytitle("Pobreza de ingreso (%)") ///
 xtitle("Año") ///
 title("Pobreza de ingreso por sexo", pos(11) size(medium) style(bold)) ///
 subtitle("Porcentaje de la población con ingreso menor a la línea de pobreza, por sexo", pos(11) size(small) color(gs8)) ///
 ylabel(, angle(horizontal) grid labsize(medium)) ///
 xlabel(, grid labsize(medium)) ///
 graphregion(color(white)) plotregion(color(white)) ///
 legend(order(1 "Hombres" 2 "Mujeres") cols(2) ring(0) pos(6) region(lstyle(none)))

* Exportar imagen
graph export "$base\GRAFICAS\pobreza_sexo.png", replace width(2000) height(1200)

restore


/********************************************************************************
* 4. TOP-5 POR ÁMBITO (RURAL/URBANO) CON MAYOR AUMENTO DE POBREZA DE INGRESO
* Comparación entre el primer y el último año disponible del panel
********************************************************************************/

preserve

* Paso 1. Crear panel promedio por entidad–ámbito–año
collapse (mean) plp [aw=factor], by(ent rururb year)

* Paso 2. Identificar primer y último año disponibles
quietly su year, meanonly
local y0 = r(min)
local y1 = r(max)

* Paso 3. Calcular cambio porcentual (delta_pp) entre `y0' y `y1'
bys ent rururb (year): gen plp_start = plp if year==`y0'
bys ent rururb: egen start = mean(plp_start)
bys ent rururb (year): gen plp_end = plp if year==`y1'
bys ent rururb: egen end   = mean(plp_end)
gen delta_pp = (end - start)*100

* Guardar panel temporal con cambio de pobreza
tempfile panel
save `panel', replace

* Paso 4. Seleccionar el top-5 por ámbito rural/urbano
use `panel', clear
keep ent rururb delta_pp
bys ent rururb: keep if _n==1
drop if missing(delta_pp)
sort rururb -delta_pp
by rururb: gen rank = _n
keep if rank<=5
tempfile top5
save `top5', replace

* Paso 5. Filtrar trayectorias completas solo para top-5
use `panel', clear
merge m:1 ent rururb using `top5', keep(match) nogen
gen pobreza_ingreso = plp*100

* Paso 6. Generar una gráfica por ámbito (rural o urbano)
levelsof rururb, local(ambitos)
foreach a of local ambitos {

    * Etiqueta legible para el ámbito
    local ambilbl : label (rururb) `a'
    if "`ambilbl'"=="" local ambilbl = "ámbito `a'"

    * Etiquetas de las 5 entidades top por ámbito
    forvalues i=1/5 {
        quietly levelsof ent if rururb==`a' & rank==`i', local(e`i')
        local lab`i' : label (ent) `e`i''
        if "`lab`i''"=="" local lab`i' = "Ent `e`i''"
    }

    * Generar gráfica de trayectorias
    twoway ///
     (connected pobreza_ingreso year if rururb==`a' & rank==1, msymbol(O) mcolor(navy)    lcolor(navy)    lwidth(med)) ///
     (connected pobreza_ingreso year if rururb==`a' & rank==2, msymbol(O) mcolor(maroon)  lcolor(maroon)  lwidth(med)) ///
     (connected pobreza_ingreso year if rururb==`a' & rank==3, msymbol(O) mcolor(emerald) lcolor(emerald) lwidth(med)) ///
     (connected pobreza_ingreso year if rururb==`a' & rank==4, msymbol(O) mcolor(orange)  lcolor(orange)  lwidth(med)) ///
     (connected pobreza_ingreso year if rururb==`a' & rank==5, msymbol(O) mcolor(purple)  lcolor(purple)  lwidth(med)), ///
     ytitle("Pobreza de ingreso (%)") ///
     xtitle("Año") ///
     title("Top 5 con mayor aumento de pobreza de ingreso", pos(11) size(medium) style(bold)) ///
     subtitle("Ámbito: `ambilbl' — cambio `y0'–`y1'", pos(11) size(small) color(gs8)) ///
     ylabel(, angle(horizontal) grid labsize(medium)) ///
     xlabel(, grid labsize(medium)) ///
     legend(order(1 "`lab1'" 2 "`lab2'" 3 "`lab3'" 4 "`lab4'" 5 "`lab5'") cols(2) ring(1) pos(6) region(lstyle(none))) ///
     graphregion(color(white)) plotregion(color(white))

    * Exportar gráfica por ámbito
    graph export "$base\GRAFICAS\top5_pobreza_ingreso_ambito_`a'.png", ///
        replace width(2200) height(1300)
}

restore

/********************************************************************************
* 5. POBREZA DE INGRESO EN HOGARES CON AL MENOS UN ADULTO MAYOR (65 AÑOS O MÁS)
********************************************************************************/

preserve

* Paso 1. Identificar hogares con al menos un miembro de 65 años o más
bys folioviv foliohog year: egen maxedad = max(edad)
gen hogar65 = (maxedad >= 65)

* Paso 2. Calcular media ponderada del indicador plp por año y condición hogar65
collapse (mean) plp [aw=factor], by(year hogar65)
gen pobreza_ingreso = plp*100

* Paso 3. Etiquetar variable indicador
label define hogar65lbl 0 "Hogares sin 65+" 1 "Hogares con 65+"
label values hogar65 hogar65lbl

* Paso 4. Graficar evolución comparada por tipo de hogar
twoway ///
 (connected pobreza_ingreso year if hogar65==0, msymbol(O) mcolor(navy)   lcolor(navy)   lwidth(med)) ///
 (connected pobreza_ingreso year if hogar65==1, msymbol(O) mcolor(maroon) lcolor(maroon) lwidth(med)), ///
 ytitle("Pobreza de ingreso (%)") ///
 xtitle("Año") ///
 title("Pobreza de ingreso en hogares según presencia de adultos mayores", pos(11) size(medium) style(bold)) ///
 subtitle("Comparación entre hogares con y sin al menos un miembro de 65 años", pos(11) size(small) color(gs8)) ///
 ylabel(, angle(horizontal) grid labsize(medium)) ///
 xlabel(, grid labsize(medium)) ///
 legend(order(1 "Sin 65+" 2 "Con 65+") cols(2) ring(0) pos(6) region(lstyle(none))) ///
 graphregion(color(white)) plotregion(color(white))

* Exportar gráfico
graph export "$base\GRAFICAS\pobreza_hogares65.png", replace width(2200) height(1300)

restore



/********************************************************************************
* 6. POBREZA DE INGRESO: POBLACIÓN INDÍGENA VS NO INDÍGENA
********************************************************************************/

preserve

* Paso 1. Calcular promedio ponderado de pobreza por año y pertenencia indígena
collapse (mean) plp [aw=factor], by(year hli)
gen pobreza_ingreso = plp*100

* Paso 2. Etiquetar variable hli
label define indig 0 "No indígena" 1 "Indígena"
label values hli indig

* Paso 3. Gráfica comparativa entre población indígena y no indígena
twoway ///
 (connected pobreza_ingreso year if hli==0, msymbol(O) mcolor(navy)   lcolor(navy)   lwidth(med)) ///
 (connected pobreza_ingreso year if hli==1, msymbol(O) mcolor(maroon) lcolor(maroon) lwidth(med)), ///
 ytitle("Pobreza de ingreso (%)") ///
 xtitle("Año") ///
 title("Pobreza de ingreso por condición indígena", pos(11) size(medium) style(bold)) ///
 subtitle("Comparación entre población indígena y no indígena", pos(11) size(small) color(gs8)) ///
 ylabel(, angle(horizontal) grid labsize(medium)) ///
 xlabel(, grid labsize(medium)) ///
 legend(order(1 "No indígena" 2 "Indígena") cols(2) ring(0) pos(6) region(lstyle(none))) ///
 graphregion(color(white)) plotregion(color(white))

* Exportar gráfico
graph export "$base\GRAFICAS\pobreza_indigena.png", replace width(2200) height(1300)

restore



/********************************************************************************
* 7. POBREZA DE INGRESO EN HOGARES CON VS SIN NIÑOS (0–17 AÑOS)
********************************************************************************/

preserve

* Paso 1. Calcular promedio ponderado por presencia de menores de edad en el hogar
collapse (mean) plp [aw=factor], by(year id_men)
gen pobreza_ingreso = plp*100

* Paso 2. Etiquetar variable id_men
label define menores 0 "Sin menores (0-17)" 1 "Con menores (0-17)"
label values id_men menores

* Paso 3. Gráfica comparativa entre hogares con y sin menores
twoway ///
 (connected pobreza_ingreso year if id_men==0, msymbol(O) mcolor(navy)   lcolor(navy)   lwidth(med)) ///
 (connected pobreza_ingreso year if id_men==1, msymbol(O) mcolor(maroon) lcolor(maroon) lwidth(med)), ///
 ytitle("Pobreza de ingreso (%)") ///
 xtitle("Año") ///
 title("Pobreza de ingreso según presencia de niños en el hogar", pos(11) size(medium) style(bold)) ///
 subtitle("Comparación entre hogares con y sin menores de 0 a 17 años", pos(11) size(small) color(gs8)) ///
 ylabel(, angle(horizontal) grid labsize(medium)) ///
 xlabel(, grid labsize(medium)) ///
 legend(order(1 "Sin menores" 2 "Con menores") cols(2) ring(0) pos(6) region(lstyle(none))) ///
 graphregion(color(white)) plotregion(color(white))

* Exportar gráfico
graph export "$base\GRAFICAS\pobreza_hogares_menores.png", replace width(2200) height(1300)

restore




/********************************************************************************
* 8. POBREZA DE INGRESO: PEA VS JUBILADOS / PENSIONADOS
********************************************************************************/

preserve

* Paso 1. Crear variable de grupo mutuamente excluyente
gen grupo = .
replace grupo = 1 if pea==1
replace grupo = 2 if jub==1

* Mantener únicamente observaciones clasificadas
keep if inlist(grupo, 1, 2)

* Paso 2. Calcular promedio ponderado por grupo y año
collapse (mean) plp [aw=factor], by(year grupo)
gen pobreza_ingreso = plp*100

* Paso 3. Etiquetar categorías
label define grupos 1 "Población Económicamente Activa (PEA)" 2 "Jubilados/Pensionados"
label values grupo grupos

* Paso 4. Gráfica comparativa entre PEA y jubilados
twoway ///
 (connected pobreza_ingreso year if grupo==1, msymbol(O) mcolor(navy)   lcolor(navy)   lwidth(med)) ///
 (connected pobreza_ingreso year if grupo==2, msymbol(O) mcolor(maroon) lcolor(maroon) lwidth(med)), ///
 ytitle("Pobreza de ingreso (%)") ///
 xtitle("Año") ///
 title("Pobreza de ingreso: PEA vs Jubilados", pos(11) size(medium) style(bold)) ///
 subtitle("Comparación entre población activa y jubilada/pensionada", pos(11) size(small) color(gs8)) ///
 ylabel(, angle(horizontal) grid labsize(medium)) ///
 xlabel(, grid labsize(medium)) ///
 legend(order(1 "PEA" 2 "Jubilados/Pensionados") cols(2) ring(0) pos(6) region(lstyle(none))) ///
 graphregion(color(white)) plotregion(color(white))

* Exportar gráfica
graph export "$base\GRAFICAS\pobreza_pea_jub.png", replace width(2200) height(1300)

restore



/********************************************************************************
* 9. POBREZA DE INGRESO: BENEFICIARIOS DE PAM VS NO BENEFICIARIOS
********************************************************************************/

preserve

* Paso 1. Calcular promedio ponderado de plp por año y condición de beneficiario
collapse (mean) plp [aw=factor], by(year pam)
gen pobreza_ingreso = plp*100

* Paso 2. Etiquetar variable pam
label define pamlbl 0 "No beneficiarios PAM" 1 "Beneficiarios PAM"
label values pam pamlbl

* Paso 3. Gráfica comparativa según acceso al programa PAM
twoway ///
 (connected pobreza_ingreso year if pam==0, msymbol(O) mcolor(navy)   lcolor(navy)   lwidth(med)) ///
 (connected pobreza_ingreso year if pam==1, msymbol(O) mcolor(maroon) lcolor(maroon) lwidth(med)), ///
 ytitle("Pobreza de ingreso (%)") ///
 xtitle("Año") ///
 title("Pobreza de ingreso según acceso a PAM", pos(11) size(medium) style(bold)) ///
 subtitle("Comparación entre beneficiarios y no beneficiarios del programa de adultos mayores", ///
          pos(11) size(small) color(gs8)) ///
 ylabel(, angle(horizontal) grid labsize(medium)) ///
 xlabel(, grid labsize(medium)) ///
 legend(order(1 "No beneficiarios" 2 "Beneficiarios") cols(2) ring(0) pos(6) region(lstyle(none))) ///
 graphregion(color(white)) plotregion(color(white))

* Exportar gráfica
graph export "$base\GRAFICAS\pobreza_pam.png", replace width(2200) height(1300)

restore



/********************************************************************************
* FIN DEL SCRIPT
********************************************************************************/






