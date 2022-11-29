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
diri = "data/"
year = 2021
f_u = diri+"uwnd."+year+".nc"
f_v = diri+"vwnd."+year+".nc"
f_q = diri+"shum."+year+".nc"   ; daily data for current year [366 days]
f_ps= diri+"pres.sfc."+year+".nc"

fu   = addfile(f_u ,"r")
fv   = addfile(f_v ,"r")
fq   = addfile(f_q ,"r")
fps  = addfile(f_ps,"r")

;---Time
ymd  = cd_calendar(fu->time, -2)    ; ymd[*]: human readable
nt   = ind(ymd.eq.date)             ; date for plotting and testing

; ncl没有简便的写法
; indt = (/nt/)
; u2 = fu->uwnd(indt,{1000:ptop},:,:); m/s, (time,level,lat,lon)  
u    = fu->uwnd(nt:nt,{1000:ptop},:,:); m/s, (time,level,lat,lon)
v    = fv->vwnd(nt:nt,{1000:ptop},:,:)
q    = fq->shum(nt:nt,{1000:ptop},:,:)        ; [kg/kg], 1000-300 levels only
ps   = fps->pres(nt:nt,:,:)         ; Pa=>[kg/(m-s2)], (time,lat,lon)
nt   := 0                            ; only one time step

fout = "IVT.nc"
fid = cal_IVT(u, v, q, ps, ptop, fout)
; print(fid)
; printVarSummary(fid)

;*************************************************
; plot results
;*************************************************
fout = "Figure1_wind&DIV_" + date

scl5  = 1e5                                  ; arbitrary: used for nicer plot values
sclab5= "(10~S~-5~N~)"                       ; used later
SCLAB5= "(10~S~5~N~)"

scl6  = 1e6
sclab6= "(10~S~-6~N~)"
SCLAB6= "(10~S~6~N~)"

LEVP = 700
div = fid->div
vd = fid->vd
ud = fid->ud
uq = fid->uq

plot := new(4, graphic)
; wks_type@wkPaperSize = "A4"
wks_type = "pdf"
wks_type@wkPaperWidthF  = 12  ; in inches
wks_type@wkPaperHeightF = 8  ; in inches
wks   = gsn_open_wks(wks_type, fout)        ; send graphics to PNG file

; Figure1: divergent wind
; res                 = True
res = plot_div(True)
res@gsnDraw  = False 
res@gsnFrame = False                          ; don't advance frame
res@lbLabelBarOn = False            ; turn off individual cb's
res@cnLineLabelsOn = False

max_duvq = 200.
res@cnMaxLevelValF  =  max_duvq                  ; set max contour level
res@cnMinLevelValF  = -max_duvq                  ; set min contour level
res@cnLevelSpacingF = 20.                  ; set contour spacing
res@vcRefMagnitudeF = 10
res@vcMinDistanceF  = 0.02

function plot_div_wind(LEVP)
begin
  ; DIV  = div(nt,{LEVP},:,:)                     ; keep meta data
  ; DIV  = DIV*scl6                               ; nicer numbers
  DUVQ = fid->duvq(nt,{LEVP},:,:)               ; keep meta data
  DUVQ = DUVQ*scl6                              ; scale for plot
  
  res@gsnCenterString = LEVP+"hPa"
  res@gsnRightString  = sclab6+" "+fid->duvq@units
  p = gsn_csm_vector_scalar_map(wks, u(nt,{LEVP},:,:), v(nt,{LEVP},:,:), DUVQ, res)
  return p
end

levs = (/920, 850, 500, 300/)
do i=0,3
  plot(i) = plot_div_wind(levs(i))
end do

resP = True
resP@gsnPanelMainString = "Divergence of Moisture Flux (fill) and Winds (vector): " + date
resP@gsnPanelLabelBar   = True                ; add common colorbar

gsn_panel(wks, plot,(/2,2/), resP)               ; now draw as one plot

; how to share the same legend?
