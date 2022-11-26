; global functions
; load "main_pkgs.ncl"

undef("make_var")
function make_var(x, units)
begin
  x@units = units
  return(x)
end


procedure print_var(x, name)
begin
  print("[" + name + "]" + "-----")
  printVarSummary(x)                          ; (time,level,lat,lon); m/s
  printMinMax(x,0)
  print("-----")
end


procedure print_line()
begin
  print("[--------------------------------------------------------------------")
end

; N = 1 kg·m/s²
; 气压的单位：P = F/A = 1 kg·m-1·s-2

; , outfile, debug
; Arguments
; - ptop: hPa
; - ps: Pa
undef("cal_IVT")
function cal_IVT(u, v, q, ps, ptop, fout)
begin
  ; CONSTANTS
  g    = 9.80665          ; m/s2
  
  ;---Change [kg/kg] to [g/kg]; not necessary: but common units for q
  q    = q*1000
  q@units = "g/kg"
  
  ptop = ptop*100
  ptop@units = "Pa"

  plev = q&level                      ; hPa  
  plev = plev*100                     ; [100000,...,30000] Pa [kg/(m-s2)]
  plev@units = "Pa"

  ;---Divergence function [used later] requires S->N grid order
  u    = u(:,:,::-1,:)
  v    = v(:,:,::-1,:)
  q    = q(:,:,::-1,:)
  ps   =ps(:,  ::-1,:)

  ;---Layer thickness: ; Pa=>[kg/(m-s2)], (time,level,lat,lon) 
  ;---Mass weighting:  (dp/g) => [Pa/(m/s2)] => (Pa-s2)/m => [kg/(m-s2)][s2/m] =>  (kg/m2)
  ;---Reference: http://www.cgd.ucar.edu/cas/catalog/newbudgets/
  dp   = dpres_plevel_Wrap(plev, ps, ptop, 0) ; Pa; layar thickness 
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

  ;---Integrated mass weighted moisture flux components
  uq_dpg = uq*dpg                ; mass weighted 'uq'; [m/s][g/kg][kg/m2]=>[m/s][g/kg]
  iuq    = dim_sum_n(uq_dpg, 1)
  iuq@long_name = "Integrated Zonal UQ [uq*dpg]" 
  iuq@LONG_NAME = "Sum: Mass Weighted Integrated Zonal Moisture Flux [uq*dpg]" 
  iuq@units     = "[m/s][g/kg]"
  copy_VarCoords(u(:,0,:,:), iuq); (time,lat,lon)
  delete(uq_dpg)

  vq_dpg = vq*dpg                ; mass weighted 'vq'; [m/s][g/kg][kg/m2]=>[m/s][g/kg] 
  ivq    = dim_sum_n(vq_dpg, 1)
  ivq@long_name = "Integrated Meridional VQ [vq*dpg]" 
  ivq@LONG_NAME = "Sum: Mass Weighted Integrated Meridional Moisture Flux [vq*dpg]" 
  ivq@units     = "[m/s][g/kg]"
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

  ; ## save data to nefcdf
  system("rm -rf " + fout)
  fid = addfile(fout, "c")
  fid->uq = uq
  fid->vq = vq
  fid->iuq = iuq
  fid->ivq = ivq
  fid->duvq = duvq
  fid->VIMFC = VIMFC
  fid->ud = ud
  fid->vd = vd
  fid->div = div
  ; delete(fid)
  return fid
  ; res = True
  ; res@uq = uq
  ; res@vq = vq
  ; res@iuq = iuq
  ; res@ivq = ivq
  ; res@duvq = duvq
  ; res@VIMFC = VIMFC
  ; res@ud = ud
  ; res@vd = vd
  ; res@div = div
  ; printVarSummary(div)
  ; print("-------------")
  ; return(res)
end


procedure add_china(res)
begin
  shp = "database/Earth..4"
  ; 2022-10-20
  ; China broder
  res@mpMinLatF             = 5.
  res@mpMaxLatF             = 55.
  res@mpMinLonF             = 72.
  res@mpMaxLonF             = 155.
  res@mpDataBaseVersion     = "MediumRes" ; or "Ncarg4_1"
  res@mpDataSetName         = shp
  res@mpAreaMaskingOn       = True
  res@mpMaskAreaSpecifiers  = (/"China"/)
  res@mpOutlineOn           = True         ; Turn on map outlines
  res@mpOutlineSpecifiers   = (/"China","China:Provinces"/)
  res@mpFillAreaSpecifiers  = (/"water","land"/)
  res@mpSpecifiedFillColors = (/0,0/)
  res@mpFillDrawOrder       = "PostDraw"
end

undef("plot_div")
function plot_div()
begin
  ; wks   = gsn_open_wks("png","mfc_div")        ; send graphics to PNG file
  res                 = True
  res@cnFillOn        = True                  ; color
  res@cnLinesOn       = False                 ; turn off contour lines

  res@cnLevelSelectionMode = "ManualLevels"   ; set manual contour levels
  res@cnMinLevelValF  = -15.                  ; set min contour level
  res@cnMaxLevelValF  =  15.                  ; set max contour level
  res@cnLevelSpacingF =   1.                  ; set contour spacing
  ;res@cnFillPalette   = "cmocean_balance"     ; NCL 6.5.0
  res@cnFillPalette   = "ViBlGrWhYeOrRe"

  res@mpFillOn        = False                 ; turn off map fill
  res@vcRefMagnitudeF = 3.                    ; make vectors larger
  res@vcRefLengthF    = 0.025                 ; reference vector length
  res@vcGlyphStyle    = "CurlyVector"         ; turn on curly vectors
  res@vcMinDistanceF  = 0.010                 ; thin the vectors
  res@vcRefAnnoOrthogonalPosF = -1.0          ; move ref vector up
  res@gsnLeftString   = "Divergent Wind"
  res@gsnScalarContour= True                  ; vectors over contours

  ; add china boundary
  add_china(res)

  return res
end

undef("plot_ivt")
function plot_ivt()
begin
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

  return res
end

