;+
; NAME:
;   suncet_load_final_mirror_coating_measurements.pro
;
; PURPOSE:
;   Load the final mirror coating reflectivity measurements for the mission
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   fm [integer]: Flight model. Default is 1. 
;
; KEYWORD PARAMETERS:
;   SEPARATE_MIRRORS: If set, will return the reflecitivies for the two mirrors separately. Otherwise, returns the average of the reflectivities for the two mirrors.
;
; OUTPUTS:
;   variableName [data type]: Description
;
; OPTIONAL OUTPUTS:
;   variableName [data type]: Description
;
; RESTRICTIONS:
;   Custom dependencies e.g., minxss-specific IDL code, custom time libraries, and limitations of this code in its forseeable usage
;+
FUNCTION suncet_load_final_mirror_coating_measurements, fm=fm, $
                                                        SEPARATE_MIRRORS=SEPARATE_MIRRORS

; Defaults
IF fm EQ !NULL THEN fm = 1
dataloc = getenv('SunCET_base')+ 'mirror_reflectivity/2024-03-21 rigaku measurements final/'


IF fm EQ 1 THEN BEGIN
  m1_filename = 'm1_sn2_final.csv'
  m2_filename = 'm2_sn3_final.csv'
ENDIF

restore, dataloc + 'b4c_rigaku_final_template.sav'
rigaku_m1 = read_ascii(dataloc + m1_filename, template=b4c_rigaku_final_template)
rigaku_m2 = read_ascii(dataloc + m2_filename, template=b4c_rigaku_final_template)


IF NOT keyword_set(SEPARATE_MIRRORS) THEN BEGIN
  common_wavelength = jpmrange(min([min(rigaku_m1.wavelength_nm), min(rigaku_m2.wavelength_nm)]), max([max(rigaku_m1.wavelength_nm), max(rigaku_m2.wavelength_nm)]), npts=200)
  interp_reflectivity_m1 = interpol(rigaku_m1.reflectivity, rigaku_m1.wavelength_nm, common_wavelength, /spline)
  interp_reflectivity_m2 = interpol(rigaku_m2.reflectivity, rigaku_m2.wavelength_nm, common_wavelength, /spline)
  average_reflectivity = ((interp_reflectivity_m1 + interp_reflectivity_m2) / 2.0) > 0.0
  rigaku = {wavelength_nm: common_wavelength, reflectivity: average_reflectivity}
  return, rigaku
ENDIF ELSE BEGIN
  return, {rigaku_m1: rigaku_m1, rigaku_m2: rigaku_m2}
ENDELSE

END