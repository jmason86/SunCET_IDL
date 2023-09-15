;+
; NAME:
;   add_timestamp_to_meng_mhd_em_maps
;
; PURPOSE:
;   Read in Meng's MHD simulation data that generated EM maps but didn't include a time stamp
;
; INPUTS:
;   None, but need access to the files
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Updated saveset files
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires access to the data
;
; EXAMPLE:
;
;-
PRO add_timestamp_to_meng_mhd_em_maps

dataloc = '/Users/masonjp2/Dropbox/suncet_dropbox/9000 Processing/data/mhd/'

models = ['bright_fast', 'bright_slow', 'dimmest']

FOREACH model, models DO BEGIN
  model_path = dataloc + model
  files = file_search(model_path + '/em_maps/*.sav', count=count)
  
  timestep = 0
  FOREACH file, files DO BEGIN
    restore, file
    date_obs_start = '1979-09-02T12:00:00Z' ; Dan's birthday
    jd = jpmiso2jd(date_obs_start) + (timestep / (24. * 60. * 60.))
    date_obs = jpmjd2iso(jd)
    date_obs = date_obs[0]
    save, em_maps_plus, date_obs, filename=file
    timestep += 10 ; [seconds]
  ENDFOREACH
ENDFOREACH

END