;+
; NAME:
;   suncet_read_whi_reference_spectrum.pro
;
; PURPOSE:
;   Description of algorithm. Turns what input into what output, in broad terms.
;
; INPUTS:
;   variableName [data type (e.g., string)]: Description
;
; OPTIONAL INPUTS:
;   variableName [data type]: Description
;
; KEYWORD PARAMETERS:
;   KEYWORD1: Description
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

FUNCTION suncet_read_whi_reference_spectrum

dataloc = getenv('SunCET_base') + 'reference_solar_spectrum/'

; Read data
bla = read_ascii(dataloc + 'ref_solar_irradiance_whi-2008_ver2.dat', data_start=142)
yar = bla.field1
wavelength = yar[0, *] ; [nm]
irradiance = yar[2, *] ; [W/m^2/nm] -- this is the second period of time (column 2) which corresponds to 2008 March 29 to April 4 with 3 small active regions on disk and a slightly higher TSI than the first column -- this is moderately low activity level


return, {wavelength:wavelength, irradiance:irradiance, wave_unit:'nm', irrad_unit:'W/m2/nm'}

END