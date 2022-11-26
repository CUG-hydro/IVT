
load "src/main_IVT.ncl"

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

scl5  = 1e5                                  ; arbitrary: used for nicer plot values
sclab5= "(10~S~-5~N~)"                       ; used later
SCLAB5= "(10~S~5~N~)"

scl6  = 1e6
sclab6= "(10~S~-6~N~)"
SCLAB6= "(10~S~6~N~)"

fid = addfile("./IVT.nc", "r")
; printVarSummary(fid)

date = 20211005
ymd  = cd_calendar(fid->time, -2)    ; ymd[*]: human readable
nt   = ind(ymd.eq.date)             ; date for plotting and testing

; ------------------------------------------------------------------------------
; VISUALIZATION
fout = "Figure1"
; wks_type@wkPaperSize = "A4"
wks_type = "pdf"
wks_type@wkPaperWidthF  = 12  ; in inches
wks_type@wkPaperHeightF = 8  ; in inches
wks   = gsn_open_wks(wks_type, fout)        ; send graphics to PNG file

iuq = fid->iuq(nt,:,:) * 1e5
ivq = fid->ivq(nt,:,:) * 1e5
div = fid->VIMFC(nt,:,:) 

resd = plot_div()
resd@tiMainString    = "Integrated Moisture Flux Convergence and IVT wind"
; resd@gsnCenterString = LEVP+"hPa: "+date
resd@gsnRightString  = " "+div@units ; sclab6+

dplt = gsn_csm_vector_scalar_map(wks, iuq, ivq, div, resd)
