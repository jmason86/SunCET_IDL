
savedir='./euv_img/'

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

files=file_search('./em_maps','*.sav')
MM=n_elements(files)

for i=0,MM-1 do begin
   print,'Processing '+strtrim(i+1,2)+' / '+strtrim(MM,2)
   restore,files[i]
   ts_new=anytim2utc(ts+10.*i,/ccsds)
   aia_sparse_em_em2lines,em_maps_plus, image=euvimage, status=status,lines=lines,$
                          eislines=['Fe IX 171.073','Fe X 177.243','Fe XI 180.407',$
                                    'Fe XII 195.119','Fe XIII 202.044']
   euv171=euvimage[*,*,0]
   euv171_image=make_map(euv171,dx=dxy,dy=dxy,time=ts_new)
   
   euv177=euvimage[*,*,1]
   euv177_image=make_map(euv177,dx=dxy,dy=dxy,time=ts_new)
   
   euv180=euvimage[*,*,2]
   euv180_image=make_map(euv180,dx=dxy,dy=dxy,time=ts_new)

   euv195=euvimage[*,*,3]
   euv195_image=make_map(euv195,dx=dxy,dy=dxy,time=ts_new)

   euv202=euvimage[*,*,4]
   euv202_image=make_map(euv202,dx=dxy,dy=dxy,time=ts_new)

   save,euv171_image,euv177_image,euv180_image,euv195_image,euv202_image,filename=savedir+'euv_sim_'+STRTRIM(STRING(i,FORMAT='(I3.3)'),2)+'.sav'

endfor

end
