
procedure add_china(res)
begin
  shp = "data/map/Earth..4"
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

