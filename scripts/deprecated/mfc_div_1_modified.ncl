;*************************************************
; mfc_div_1.ncl
;
; Concepts illustrated:
;   - Read daily mean wind components, humidity and sfc. pressure
;     from different files
;   - Reorder the input (N==>S) grid order to (S==>N) via NCL syntax  ::-1
;   - Calculate mass weightined layer thickness [units="kg/m2"]
;   - Calculate moisture flux [uq, vq]
;   - Calculate moisture flux divergence using spherical harmonics
;   - Integrate the moisture flux divergence using mass weighting
;   - Plot a number of quantities
;*************************************************
;---Calculate the Horizontal Moisture Flux Convergence [MFC]
;*************************************************
;---High frequency source data: hourly/3hr/6hr/12hr/daily .... NOT monthly values
;---References:
;---http://www.cgd.ucar.edu/cas/catalog/newbudgets/
;---http://tornado.sfsu.edu/geosciences/classes/e260/AtmosphericRivers/Moisture%20Flux.pdf
;---https://www.spc.noaa.gov/publications/banacos/mfc-sls.pdf
;===================================================================
;   Data Source: ESRL Physical Sciences Division
;        https://www.esrl.noaa.gov/psd/data/gridded/data.ncep.reanalysis.html
;   NCEP Reanalysis data provided by the NOAA/OAR/ESRL PSD, Boulder, Colorado, USA,
;   from their Web site at https://www.esrl.noaa.gov/psd/
;===================================================================

; """
; Arguments:
; - `ptop`:
; - `date`: 
; - files:
; - `indir`:
; + `f_q`: 
; + `f_u`: 
; + `f_v`: 
; + `f_ps`: 
; """
load "src/main_IVT.ncl"

ptop = 300              ; 'shum' upper level
ptop@units = "hPa"
g    = 9.80665          ; m/s2
date  = 20080715        ; NH summer

;---ESRL: CDC data
diri = "data/"
f_u = diri+"uwnd.2008.nc"
f_v = diri+"vwnd.2008.nc"
f_q = diri+"shum.2008.nc"   ; daily data for current year [366 days]
f_ps= diri+"pres.sfc.2008.nc"

fu   = addfile(f_u ,"r")
fv   = addfile(f_v ,"r")
fq   = addfile(f_q ,"r")
fps  = addfile(f_ps,"r")

;---Time
  ymd  = cd_calendar(fu->time, -2)    ; ymd[*]: human readable
  nt   = ind(ymd.eq.date)             ; date for plotting and testing

TEST = True
if (.not.TEST) then                   ; all times
  u    = fu->uwnd(:,{1000:ptop},:,:)  ; m/s, (time,level,lat,lon)
  v    = fv->vwnd(:,{1000:ptop},:,:)
  q    = fq->shum(:,{1000:ptop},:,:)  ; [kg/kg], 1000-300 levels only
  ps   = fps->pres                    ; Pa=>[kg/(m-s2)], (time,lat,lon)
else                                  ; one time step; keep time dimension [ nt:nt: ]
  ; ncl没有简便的写法
  ; indt = (/nt/)
  ; u2 = fu->uwnd(indt,{1000:ptop},:,:); m/s, (time,level,lat,lon)  
  u    = fu->uwnd(nt:nt,{1000:ptop},:,:); m/s, (time,level,lat,lon)
  v    = fv->vwnd(nt:nt,{1000:ptop},:,:)
  q    = fq->shum(nt:nt,{1000:ptop},:,:)        ; [kg/kg], 1000-300 levels only
  ps   = fps->pres(nt:nt,:,:)         ; Pa=>[kg/(m-s2)], (time,lat,lon)
  nt   := 0                            ; only one time step
end if

;---Vertical levels
ptop = ptop*100
ptop@units = "Pa"

plev = q&level                      ; hPa
plev = plev*100                     ; [100000,...,30000] Pa [kg/(m-s2)]
plev@units = "Pa"
;---Change [kg/kg] to [g/kg]; not necessary: but common units for q
q    = q*1000
q@units = "g/kg"
;---Divergence function [used later] requires S->N grid order
u    = u(:,:,::-1,:)
v    = v(:,:,::-1,:)
q    = q(:,:,::-1,:)
ps   =ps(:,  ::-1,:)

;---Layer thickness: ; Pa=>[kg/(m-s2)], (time,level,lat,lon)
;---Mass weighting:  (dp/g) => [Pa/(m/s2)] => (Pa-s2)/m => [kg/(m-s2)][s2/m] =>  (kg/m2)
;---Reference: http://www.cgd.ucar.edu/cas/catalog/newbudgets/
  dp   = dpres_plevel_Wrap(plev, ps, ptop, 0) ; Pa; layar thickness
  ; printVarSummary(dp)
  ; print(dp&plev/100)
  dpg  = dp/g
  dpg@long_name = "Layer Mass Weighting"
  dpg@units     = "kg/m2"                     ; dp/g, Pa/(m s-2), reduce to kg m-2

;---Moisture flux components at each pressure level
  uq   = u*q                                  ; (:,:,:,:)
  uq@long_name = "Zonal Moisture Flux [uq]"
  uq@units = "["+u@units+"]["+q@units+"]"     ; [m/s][g/kg]
  copy_VarCoords(u,uq)                        ; (time,level,lat,lon)

  vq   = v*q                                  ; (:,:,:,:)
  vq@long_name = "Meridional Moisture Flux [vq]"
  vq@units = "["+v@units+"]["+q@units+"]"
  copy_VarCoords(v,vq)                        ; (time,level,lat,lon)

; PRINT_RAW = True
PRINT_RAW = False
if (PRINT_RAW) then
  print_var(q, "q")  ; (time,level,lat,lon); g/kg
  print_var(u, "u")  ; (time,level,lat,lon); m/s
  print_var(v, "v")  ; 
  print_var(ps, "ps"); (time,lat,lon); Pa => kg/(m-s2)
  print_var(uq, "uq"); (time,level,lat,lon); (m/s)(g/kg)
  print_var(vq, "vq"); 
  print_var(vq, "dp"); (time,level,lat,lon); Pa => kg/(m-s2)

  ; examine layer thickness at selected locations
  print(dp(nt,:,{40},{180}))    ; mid-Pacific
  print(dp(nt,:,{40},{255}))    ; Boulder, CO
  print("-----")
end if

;---Integrated mass weighted moisture flux components
  unit_ivq = "[g m-1 s-1]"
  uq_dpg = uq*dpg                ; mass weighted 'uq'; [m/s][g/kg][kg/m2]=>[m/s][g/m2]=>[g m-1 s-1]
  iuq    = dim_sum_n(uq_dpg, 1)
  iuq@long_name = "Integrated Zonal UQ [uq*dpg]"
  iuq@LONG_NAME = "Sum: Mass Weighted Integrated Zonal Moisture Flux [uq*dpg]"
  iuq@units     = unit_ivq
  copy_VarCoords(u(:,0,:,:), iuq); (time,lat,lon)
  delete(uq_dpg)

  vq_dpg = vq*dpg                ; mass weighted 'vq'; [m/s][g/kg][kg/m2]=>[m/s][g/m2]=>[g m-1 s-1]
  ivq    = dim_sum_n(vq_dpg, 1)
  ivq@long_name = "Integrated Meridional VQ [vq*dpg]"
  ivq@LONG_NAME = "Sum: Mass Weighted Integrated Meridional Moisture Flux [vq*dpg]"
  ivq@units     = unit_ivq
  copy_VarCoords(v(:,0,:,:), ivq); (time,lat,lon)
  delete(vq_dpg)

;---Divergence of moisture flux: uv2dvF => global 'fixed' rectilinear grid

  duvq  = uv2dvF_Wrap(uq, vq)    ; (time,level,lat,lon)
  duvq@long_name = "Divergence of Moisture Flux"
  duvq@units     = "g/(kg-s)"    ; (1/m)*[(m/s)(g/kg)] => [g/(kg-s)]

;---Mass weighted integration [sum] of the divergence of moisture flux

  duvq_dpg = duvq*dpg            ;  [g/(kg-s)][kg/m2] => [g/(m2-s)]
  iduvq    = dim_sum_n(duvq_dpg, 1)
  iduvq@long_name = "Integrated Mass Wgt MFC"
  iduvq@LONG_NAME = "Integrated Mass Weighted Moisture Flux Convergence"
  iduvq@units     = "g/(m2-s)"
  copy_VarCoords(u(:,0,:,:), iduvq)      ; (time,lat,lon)
  delete(duvq_dpg)

  VIMFC =  iduvq           ; keep meta data
  VIMFC = -VIMFC           ; Note the preceding -1 [negative precedes integration]
  VIMFC@long_name = "VIMFC"

;*************************************************
; Calculate divergence: Use Wrap to include meta data
; Calculate divergent wind components; used for graphics
;*************************************************
  div = uv2dvF_Wrap(u,v)                ; u,v ==> divergence; (:,:,:,:)

  ud  = new ( dimsizes(u), typeof(u), "No_FillValue")
  vd  = new ( dimsizes(v), typeof(v), "No_FillValue")
  dv2uvf(div,ud,vd)                     ; divergence ==> divergent components

  copy_VarCoords(u, ud )
  copy_VarCoords(u, vd )
  ud@long_name  = "Zonal Divergent Wind"
  ud@units      = u@units
  vd@long_name  = "Meridional Divergent Wind"
  vd@units      = v@units

;*************************************************
; plot results
;*************************************************
fout = "mfc_div"

  scl5  = 1e5                                  ; arbitrary: used for nicer plot values
  sclab5= "(10~S~-5~N~)"                       ; used later
  SCLAB5= "(10~S~5~N~)"

  scl6  = 1e6
  sclab6= "(10~S~-6~N~)"
  SCLAB6= "(10~S~6~N~)"

  plot := new(2,graphic)
  wks   = gsn_open_wks("pdf", fout)        ; send graphics to PNG file
  ; wks   = gsn_open_wks("png","mfc_div")        ; send graphics to PNG file
  resd                 = True
  resd@cnFillOn        = True                  ; color
  resd@cnLinesOn       = False                 ; turn off contour lines

  resd@cnLevelSelectionMode = "ManualLevels"   ; set manual contour levels
  resd@cnMinLevelValF  = -15.                  ; set min contour level
  resd@cnMaxLevelValF  =  15.                  ; set max contour level
  resd@cnLevelSpacingF =   1.                  ; set contour spacing
 ;resd@cnFillPalette   = "cmocean_balance"     ; NCL 6.5.0
  resd@cnFillPalette   = "ViBlGrWhYeOrRe"

  resd@mpFillOn        = False                 ; turn off map fill
  resd@vcRefMagnitudeF = 3.                    ; make vectors larger
  resd@vcRefLengthF    = 0.025                 ; reference vector length
  resd@vcGlyphStyle    = "CurlyVector"         ; turn on curly vectors
  resd@vcMinDistanceF  = 0.010                 ; thin the vectors
  resd@vcRefAnnoOrthogonalPosF = -1.0          ; move ref vector up
  resd@gsnLeftString   = "Divergent Wind"
  resd@gsnScalarContour= True                  ; vectors over contours

  add_china(resd)

  LEVP = 700
  DIV  = div(nt,{LEVP},:,:)                     ; keep meta data
  DIV  = DIV*scl6                               ; nicer numbers

  resd@tiMainString    = "Divergence and Divergent Winds"
  resd@gsnCenterString = LEVP+"hPa: "+date
  resd@gsnRightString  = sclab6+" "+div@units
  dplt = gsn_csm_vector_scalar_map(wks,ud(nt,{LEVP},:,:),vd(nt,{LEVP},:,:),DIV,resd)

;--- Moisture Transport [uq, vq] at a specified pressure level
  res                   = True             ; plot mods desired
  res@gsnDraw           = False            ; don't draw yet
  res@gsnFrame          = False            ; don't advance frame yet

  res@cnFillOn          = True             ; turn on color
  res@cnLinesOn         = False            ; turn off contour lines
  res@cnLineLabelsOn    = False            ; turn off contour lines
  res@cnFillPalette     = "ViBlGrWhYeOrRe" ; set White-in-Middle color map
  res@lbLabelBarOn      = False            ; turn off individual cb's
  res@mpFillOn          = False            ; turn off map fill
                                           ; Use a common scale
  res@cnLevelSelectionMode = "ManualLevels"; manual set levels so lb consistent
  res@cnMaxLevelValF       =  140.0        ; max level
  res@cnMinLevelValF       = -res@cnMaxLevelValF     ; min level
  res@cnLevelSpacingF      =   10.0        ; contour interval
  ; add china boundary
  add_china(res)

  LEVP    = 700
  res@gsnCenterString      = LEVP+"hPa"
  plot(0) = gsn_csm_contour_map(wks,uq(nt,{LEVP},:,:),res)
  plot(1) = gsn_csm_contour_map(wks,vq(nt,{LEVP},:,:),res)

  resP                     = True                ; modify the panel plot
  resP@gsnPanelMainString  = date+": Unweighted Moisture Flux Components"
  resP@gsnPanelLabelBar    = True                ; add common colorbar
  gsn_panel(wks,plot,(/2,1/),resP)               ; now draw as one plot

;--- Integrated Moisture Transport [iuq, ivq]
  delete(res@gsnCenterString)              ; not used for this plot
  res@cnMaxLevelValF       = 10.0          ; min level
  res@cnMinLevelValF       = -res@cnMaxLevelValF     ; min level
  res@cnLevelSpacingF      =  0.5          ; contour interval
  ; add_china(res)

  IUQ     = iuq(nt,:,:)                    ; local array: keep meta data
  IUQ     = IUQ/scl5                       ; scale for plot
  res@gsnRightString  = SCLAB5+" "+iuq@units
  plot(0) = gsn_csm_contour_map(wks,IUQ,res)

  IVQ     = ivq(nt,:,:)                    ; local array: keep meta data
  IVQ     = IVQ/scl5
  res@gsnRightString  = SCLAB5+" "+ivq@units
  ; add_china(res)
  plot(1) = gsn_csm_contour_map(wks,IVQ,res)

  resP@gsnPanelMainString  = date+": Mass Wgt. Component Moisture Flux"
  gsn_panel(wks,plot,(/2,1/),resP)               ; now draw as one plot

  delete( [/IUQ, IVQ/] )                   ; no longer needed

;---Divergence of Moisture Flux
  res@cnMaxLevelValF       = 100.0          ; min level
  res@cnMinLevelValF       = -res@cnMaxLevelValF     ; min level
  res@cnLevelSpacingF      =  5.0          ; contour interval

  LEVP    = 700
  DUVQ    = duvq(nt,{LEVP},:,:)                    ; keep meta data
  DUVQ    = DUVQ*scl6                              ; scale for plot
  res@gsnCenterString = LEVP+"hPa"
  res@gsnRightString  = sclab6+" "+duvq@units
  ; add_china(res)

  plot(0) = gsn_csm_contour_map(wks,DUVQ,res)

  LEVP    = 500
  DUVQ    = duvq(nt,{LEVP},:,:)                    ; keep meta data
  DUVQ    = DUVQ*scl6
  res@gsnCenterString = LEVP+"hPa"
  res@gsnRightString  = sclab6+" "+duvq@units
  ; add_china(res)
  plot(1) = gsn_csm_contour_map(wks,DUVQ,res)

  resP@gsnPanelMainString  = date+": Divergence of Moisture Flux"
  gsn_panel(wks,plot,(/2,1/),resP)                ; now draw as one plot

  delete(DUVQ)                                        ; no longer needed
  delete([/res@gsnCenterString, res@gsnRightString/]) ; not used in next plot

;---Integrated Divergence of Moisture Flux Convergence [no scaling]
  res@gsnDraw              = True
  res@gsnFrame             = True
  res@lbLabelBarOn         = True
 ;res@cnFillPalette        = "cmp_flux"
  res@cnMaxLevelValF       =  0.50                ; min level
  res@cnMinLevelValF       = -res@cnMaxLevelValF  ; min level
  res@cnLevelSpacingF      =  0.050               ; contour interval
  res@tiMainString         = date+": VIMFC"
  ; add_china(res)
  plt = gsn_csm_contour_map(wks,VIMFC(nt,:,:) ,res)
