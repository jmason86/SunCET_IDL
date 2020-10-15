
savedir='./Rendered_EUV_Maps/'

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
aia_sparse_em_init, timedepend = '2018-02-12T04:00:00', /evenorm, $
                    bases_sigmas=[0,0.1,0.2],use_lgtaxis=findgen(nlgT)*dlgT+lgTmin
lgtaxis = aia_sparse_em_lgtaxis()

files=file_search('./EM_Maps','*.sav')
MM=n_elements(files)

for i=0,MM-1 do begin
  print,'Processing '+strtrim(i+1,2)+' / '+strtrim(MM,2)
  restore,files[i]
  ts_new=anytim2utc(ts+10.*i,/ccsds)
  aia_sparse_em_em2lines, em_maps_plus, image=euvimage, status=status,lines=lines,$
                          eislines=['Fe IX 171.073', $ ; 0 
                                    'Fe X 174.531', $ ; 1
                                    'Fe X 177.240', $ ; 2
                                    'Fe XI 180.401',$  ;3 
                                    'Fe VIII 185.213', $ ; 4
                                    'Fe XI 188.217', $ ; 5
                                    'Fe XII 193.509', $ ; 6
                                    'Fe XII 195.119'] ; 7

  rendered_maps = fltarr(nPix, nPix, n_elements(lines))

  for j = 0, n_elements(lines) - 1 do begin
    map_out = make_map(euvimage[*, *, j], dx=dxy, dy=dxy, time=ts_new)
    rendered_maps[*, *, j] = map_out.data
  endfor

  map_metadata = map_out
  struct_delete_field, map_metadata, 'data'
  struct_delete_field, lines, 'goft' 

  save, rendered_maps, map_metadata, lines, filename=savedir+'euv_sim_'+STRTRIM(STRING(i,FORMAT='(I3.3)'),2)+'.sav'

endfor

end
