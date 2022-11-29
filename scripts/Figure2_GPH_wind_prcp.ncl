load "src/main_IVT.ncl"

ptop = 300              ; 'shum' upper level
ptop@units = "hPa"

date  = 20080715        ; NH summer
date  = 20211001        ; NH summer
date  = 20211002        ; NH summer
date  = 20211003        ; NH summer
; date  = 20211004        ; NH summer
; date  = 20211005        ; NH summer
date  = 20210721        ; NH summer


;---ESRL: CDC data
diri  = "data/"
year  = 2021
f_u   = diri+"uwnd."+year+".nc"
f_v   = diri+"vwnd."+year+".nc"
f_hgt = diri+"hgt."+year+".nc"   ; daily data for current year [366 days]
f_pr  = diri+"prate.sfc.gauss."+year+".nc"

fid_u   = addfile(f_u ,"r")
fid_v   = addfile(f_v ,"r")
fid_hgt = addfile(f_hgt,"r")
fid_pr = addfile(f_pr,"r")

; print(fid_hgt)
; print(fid_pr)

;---Time
ymd  = cd_calendar(fid_u->time, -2)    ; ymd[*]: human readable
nt   = ind(ymd.eq.date)             ; date for plotting and testing

u    = fid_u->uwnd(:,{1000:ptop},:,:); m/s, (time,level,lat,lon)
v    = fid_v->vwnd(:,{1000:ptop},:,:)
hgt  = fid_hgt->hgt(:,{1000:ptop},:,:)        ; [kg/kg], 1000-300 levels only
pr   = fid_pr->prate(:,:,:)         ; Pa=>[kg/(m-s2)], (time,lat,lon)

pr   = pr * 86400; Kg/m^2/s to mm/d
pr@units = "mm/d"
pr@long_name = "Total Daily Precipitation af surface"
; nt   := 0                            ; only one time step

; print(pr)
; print(hgt)
; printVarSummary(pr)

undef("plot_level")
function plot_level(wks, LEV)
begin
  ; ;---Set some resources
  res                             = True
  res@gsnDraw                     = False
  res@gsnFrame                    = False
  ; res@gsnMaximize               = True     ; maximize plot in frame
  res@cnFillOn                    = True     ; turn on color fill
  res@cnLinesOn                   = False            ; turn off contour lines
  res@cnLineLabelsOn              = False            ; turn off contour lines
  res@cnLevelSpacingF             = 5.                  ; set contour spacing
  res@cnFillPalette               = precip_pal()
  res@gsnAddCyclic                = False
  res@mpGeophysicalLineThicknessF = 2.0 
  res@mpNationalLineThicknessF    = 2.0
  res@gsnLeftString               = LEV + "hPa  Wind&Height&Prcp"
  res@gsnRightString              = date
  res@gsnRightStringFontHeightF   = .02
  res@gsnLeftStringFontHeightF    = .02
  res@lbLabelBarOn                = False            ; turn off individual cb's
  res@lbOrientation               = "vertical"
  res@lbTitleOn                   = True                  ; turn on title
  ; res@lbTitleString             = "%"
  res@lbTitleFontHeightF          = .015                 ; make title smaller
  res@pmTickMarkDisplayMode       = "Always"
  res@tmXBTickSpacingF            = 40
  ; res@tiXAxisString             = "NCEP GFS 0.25~S~o~N~*0.25~S~o~N~       VALID TIME: 2020/02/29/06 +000hrs" 
  res@tiXAxisFontHeightF          = .015
  add_china(res)
  ; res@cnLevelSelectionMode = "ExplicitLevels"          ;绘制等值线
  ; res@cnLevels             = (/80,90,100/)
  ; res@cnFillColors         = (/0,40,80,110,128/)
  plot0 = gsn_csm_contour_map(wks, pr(nt, :, :), res)
 
  res                            := True
  res@gsnDraw                    = False          
  res@gsnFrame                   = False 
  res@gsnAddCyclic               = False          
  res@cnFillOn                   = False
  res@cnLinesOn                  = True
  res@cnLineThicknessF           = 1.5
  res@cnLevelSpacingF            = 30.               ;-- contour level spacing
  res@cnInfoLabelOn              = False
  res@cnHighLabelsOn             = True
  res@cnLowLabelsOn              = True
  res@cnHighLabelFontAspectF     = 1.
  res@cnLowLabelFontAspectF      = 1.
  res@gsnLeftString              = ""
  res@gsnRightString             = ""
  res@cnLineColor                = "red"
  res@cnLineLabelBackgroundColor = "grey80"; -1    ; transparent
  res@cnHighLabelBackgroundColor = "red"
  res@cnLowLabelBackgroundColor  = "blue"
  res@cnInfoLabelFontColor           = "red"
  plot1 = gsn_csm_contour(wks, hgt(nt, {LEV}, :, :), res)
 
  res                         := True               ; plot mods desired
  res@gsnDraw                  = False          
  res@gsnFrame                 = False 
  res@gsnAddCyclic             = False
  res@vcRefMagnitudeF          = 10.                ; make vectors larger
  res@vcRefLengthF             = 0.050              ; ref vec length
  res@vcGlyphStyle             = "WindBarb"         ; select wind barbs 
  res@vcMinDistanceF           = 0.03              ; thin out windbarbs
  res@vcRefMagnitudeF          = 4.
  res@vcRefLengthF             = 0.030
  res@vcWindBarbScaleFactorF   = 2.5
  res@vcWindBarbLineThicknessF = 1.0
  res@gsnLeftString            = ""
  res@gsnRightString           = ""
  res@vcRefAnnoString2On       = False
  res@lbLabelBarOn             = False
  res@vcRefAnnoOn              = False
  plot2=gsn_csm_vector(wks, u(nt, {LEV},:,:), v(nt, {LEV},:,:), res)
  
  ; if LEV .eq. 950 then
    overlay(plot0,plot1)
    overlay(plot0,plot2)
    return plot0
  ; else 
  ;   overlay(plot1,plot2)
  ;   return plot1
  ; end if
end
; frame(wks)
; end do
; end
plot := new(4, graphic)
wks_type = "pdf"
wks_type@wkPaperWidthF  = 12  ; in inches
wks_type@wkPaperHeightF = 8  ; in inches
wks   = gsn_open_wks(wks_type, "Figure1")        ; send graphics to PNG file

; gsn_define_colormap(wks,"MPL_Blues")

levs = (/920, 850, 500, 300/)
; LEV = 850;
do i=0,3
  plot(i) = plot_level(wks, levs(i))
end do

resP = True
resP@gsnPanelMainString = "HGT (contour), precipitation (fill) and Winds (vector): " + date
resP@gsnPanelLabelBar   = True                ; add common colorbar
; resP@gsnPaperOrientation = "portrait" ; portrait, landscape

gsn_panel(wks, plot,(/2,2/), resP)               ; now draw as one plot
