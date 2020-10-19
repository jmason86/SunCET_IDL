;+
; NAME:
;   cal_line_image_dbs
;
; PURPOSE:
;   Convert MHD DEM data into pure synthetic images
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   emission_lines [strarr]: The names of the emission lines to process. 
;                            Warning: These need to be precisely named or aia_sparse_em_em2lines won't recognize them.
;                            Default is ['Fe IX 171.073', 'Fe X 174.531', 'Fe X 177.240', 'Fe XI 180.401', 'Fe VIII 185.213', 'Fe XI 188.217', 'Fe XII 193.509', 'Fe XII 195.119', 'Fe XIII 202.044', 'Fe XIII 203.827', 'Fe XIV 211.317']
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   savesets on disk containing the synthetic images for each line and metadata
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires access to the data and Mark Cheung's aia_sparse_em_em2lines
;
; EXAMPLE:
;   Just run it!
;-
PRO cal_line_image_dbs, emission_lines=emission_lines

; Defaults
dataloc = getenv('SunCET_base') + 'MHD/em_maps'
saveloc = getenv('SunCET_base') + 'MHD/Rendered_EUV_Maps/'
IF emission_lines EQ !NULL THEN BEGIN
  emission_lines = ['Fe IX 171.073', $   ; 0
                    'Fe X 174.531', $    ; 1
                    'Fe X 177.240', $    ; 2
                    'Fe XI 180.401',$    ; 3
                    'Fe VIII 185.213', $ ; 4
                    'Fe XI 188.217', $   ; 5
                    'Fe XII 193.509', $  ; 6
                    'Fe XII 195.119', $  ; 7
                    'Fe XIII 202.044', $ ; 8 (probably out of band for primary coating)
                    'Fe XIII 203.827', $ ; 9 (probably out of band for primary coating)
                    'Fe XIV 211.317']    ; 10 (probably out of band for primary coating)
ENDIF

; Config
lgTmin = 5.45   ; minimum for lgT axis for inversion
dlgT   = 0.1   ; width of lgT bin       
nlgT   = 12    ; number of lgT bins     

rSizeImage=5.6
nPix=1024.
dxy=rSizeImage*1920./nPix
UTtime='2018-02-12T04:00:00'
dt=10
ts=utc2tai(UTtime)

;For initiating common valuables (e.g., pre-saved CHIANTI lines) only
aia_sparse_em_init, timedepend=UTtime, /evenorm, $
                    bases_sigmas=[0,0.1,0.2], use_lgtaxis=findgen(nlgT)*dlgT+lgTmin
lgtaxis = aia_sparse_em_lgtaxis()

files=file_search(dataloc,'*.sav')
MM=n_elements(files)

for i=0,MM-1 do begin
  print,'Processing '+strtrim(i+1,2)+' / '+strtrim(MM,2)
  restore,files[i]
  ts_new=anytim2utc(ts+10.*i,/ccsds)
  aia_sparse_em_em2lines, em_maps_plus, image=euvimage, status=status,lines=lines, eislines=emission_lines

  rendered_maps = fltarr(nPix, nPix, n_elements(lines))

  for j = 0, n_elements(lines) - 1 do begin
    map_out = make_map(euvimage[*, *, j], dx=dxy, dy=dxy, time=ts_new)
    rendered_maps[*, *, j] = map_out.data
  endfor

  map_metadata = map_out
  struct_delete_field, map_metadata, 'data'
  struct_delete_field, lines, 'goft' 

  save, rendered_maps, map_metadata, lines, filename=saveloc+'euv_sim_'+STRTRIM(STRING(i,FORMAT='(I3.3)'),2)+'.sav'

endfor

END
