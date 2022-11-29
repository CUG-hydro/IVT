;*************************************************
; Concepts illustrated:
;   - Calculate mass weightined layer thickness [units="kg/m2"]
;   - Calculate moisture flux [uq, vq]
;   - Calculate moisture flux divergence using spherical harmonics
;   - Integrate the moisture flux divergence using mass weighting
;   - Plot a number of quantities
;*************************************************
;---Calculate the Horizontal Moisture Flux Convergence [MFC]
; """
; Arguments:
; - `ptop`:
; - `date`: 
; + `f_q`: 
; + `f_u`: 
; + `f_v`: 
; + `f_ps`: 
load "src/main_IVT.ncl"

ptop = 300              ; 'shum' upper level
ptop@units = "hPa"

date  = 20080715        ; NH summer
date  = 20211001        ; NH summer
date  = 20211002        ; NH summer
date  = 20211003        ; NH summer
date  = 20211004        ; NH summer
date  = 20211005        ; NH summer
; date  = 20210721        ; NH summer

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

fout = "IVT.nc"
fid = cal_IVT(u, v, q, ps, ptop, fout)
; print(fid)
; printVarSummary(fid)

;*************************************************
fout = "Figure_IVT&DIV_" + date

scl5  = 1e5                                  ; arbitrary: used for nicer plot values
sclab5= ten_pown(-5)
SCLAB5= ten_pown(5)

scl6  = 1e6
sclab6= ten_pown(-6)
SCLAB6= ten_pown(6)

levs = (/920, 850, 500, 300/)
LEVP = 700
div = fid->div
vd = fid->vd
ud = fid->ud
uq = fid->uq

; wks_type@wkPaperSize = "A4"
wks_type = "pdf"
wks_type@wkPaperWidthF  = 12  ; in inches
wks_type@wkPaperHeightF = 8  ; in inches
wks   = gsn_open_wks(wks_type, fout)        ; send graphics to PNG file


; 图1. 比湿 -------------------------------------------------------------------------
res := plot_div()
res@gsnDraw  = False 
res@gsnFrame = False                          ; don't advance frame
res@lbLabelBarOn = False            ; turn off individual cb's
res@cnLineLabelsOn = False

res@cnMaxLevelValF  = 10.                  ; set max contour level
res@cnMinLevelValF  = 0.                  ; set min contour level
res@cnLevelSpacingF = 0.5                  ; set contour spacing
res@cnFillPalette   = "MPL_Blues"

plot := new(4,graphic)
do i=0,3
  LEVP = levs(i)
  x = fq->shum(nt,{LEVP},:,:)  
  x = x * 1000
  res@gsnCenterString = LEVP+"hPa"
  res@gsnRightString  = "g/kg"
  plot(i) = gsn_csm_vector_scalar_map(wks, u(nt,{LEVP},:,:), v(nt,{LEVP},:,:), x, res)
end do

resP = True
resP@gsnPanelMainString = "q (fill) and Winds (vector): " + date
resP@gsnPanelLabelBar   = True                ; add common colorbar
gsn_panel(wks, plot,(/2,2/), resP)               ; now draw as one plot
res@cnFillPalette = "ViBlGrWhYeOrRe"


; Figure 1a: Moisture Transport [uq, vq] at a specified pressure level
res := plot_ivt()

plot := new(8,graphic)
do i=0,3
  k = i*2
  LEVP = levs(i)
  res@gsnCenterString      = LEVP+"hPa"
  plot(k) = gsn_csm_contour_map(wks,fid->uq(nt,{LEVP},:,:),res)
  plot(k+1) = gsn_csm_contour_map(wks,fid->vq(nt,{LEVP},:,:),res)
end do
resP                     := True                ; modify the panel plot
resP@gsnPanelMainString  = date+": Unweighted Moisture Flux Components"
resP@gsnPanelLabelBar    = True                ; add common colorbar
gsn_panel(wks, plot,(/4,2/),resP)               ; now draw as one plot


; Figure 1b: Integrated Moisture Transport [iuq, ivq]
IUQ     = fid->iuq(nt,:,:)                    ; local array: keep meta data
IUQ     = IUQ/scl5                       ; scale for plot
IVQ     = fid->ivq(nt,:,:)                    ; local array: keep meta data
IVQ     = IVQ/scl5

plot := new(2, graphic)
delete(res@gsnCenterString)              ; not used for this plot
; res@gsnRightString  = SCLAB5+" "+fid->ivq@units
res@cnMaxLevelValF       = 10.0          ; min level
res@cnMinLevelValF       = -res@cnMaxLevelValF     ; min level
res@cnLevelSpacingF      =  0.5          ; contour interval
res@gsnRightString  = SCLAB5+" "+fid->iuq@units
plot(0) = gsn_csm_contour_map(wks,IUQ,res)
plot(1) = gsn_csm_contour_map(wks,IVQ,res)
resP@gsnPanelMainString  = date+": Mass Wgt. Component Moisture Flux"
gsn_panel(wks,plot(0:1),(/1,2/),resP)               ; now draw as one plot

; Figure 1c: IVT
res := plot_div()
delete([/res@cnFillPalette/]) ; not used in next plot
gsn_define_colormap(wks,"ViBlGrWhYeOrRe")
; gsn_reverse_colormap(wks)           ; Reverse the color map.

res@cnMaxLevelValF       = 10.0          ; min level
res@cnMinLevelValF       = -res@cnMaxLevelValF     ; min level
res@cnLevelSpacingF      =  1.          ; contour interval
; res@gsnDraw  = False 
; res@gsnFrame = False                          ; don't advance frame
IVT = uv2speed(IVQ, IUQ)
; res@gsnCenterString = LEVP+"hPa"
res@tiMainString  = date+": IVT(fill)"
res@gsnRightString  = sclab5+" "+IVT@units
plt = gsn_csm_vector_scalar_map(wks, IUQ, IVQ, IVT, res)  




; 图2: divergent wind ------------------------------------------------------
res := plot_div()
res@gsnDraw  = False 
res@gsnFrame = False                          ; don't advance frame

levs = (/920, 850, 500, 300/)
plot := new(4,graphic)
do i=0,3
  LEVP = levs(i)
  DIV  = div(nt,{LEVP},:,:)                     ; keep meta data
  DIV  = DIV*scl6                               ; nicer numbers
  res@gsnCenterString = LEVP+"hPa"
  res@gsnRightString  = sclab6+" "+fid->duvq@units
  plot(i) = gsn_csm_vector_scalar_map(wks, ud(nt,{LEVP},:,:), vd(nt,{LEVP},:,:), DIV, res)  
end do

resP = True
resP@gsnPanelMainString = "Divergence (fill) and Divergent Winds (vector): " + date
gsn_panel(wks, plot,(/2,2/), resP)               ; now draw as one plot


; 图3. 单层水汽通量散度: Divergence of Moisture Flux ------------------------------
res := plot_div()
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

do i=0,3
  LEVP = levs(i)
  DUVQ = fid->duvq(nt,{LEVP},:,:)               ; keep meta data
  DUVQ = DUVQ*scl6                              ; scale for plot
  
  res@gsnCenterString = LEVP+"hPa"
  res@gsnRightString  = sclab6+" "+fid->duvq@units
  plot(i) = gsn_csm_vector_scalar_map(wks, u(nt,{LEVP},:,:), v(nt,{LEVP},:,:), DUVQ, res)
end do

resP = True
resP@gsnPanelMainString = "Divergence of Moisture Flux (fill) and Winds (vector): " + date
resP@gsnPanelLabelBar   = True                ; add common colorbar
gsn_panel(wks, plot,(/2,2/), resP)               ; now draw as one plot

; Figure4: ---Integrated Divergence of Moisture Flux Convergence [no scaling]
res := plot_ivt()
res@gsnDraw              = True
res@gsnFrame             = True
res@lbLabelBarOn         = True
;res@cnFillPalette        = "cmp_flux"
res@cnMaxLevelValF       =  0.50                ; min level
res@cnMinLevelValF       = -res@cnMaxLevelValF  ; min level
res@cnLevelSpacingF      =  0.050               ; contour interval
res@tiMainString         = "Integrated Divergence of Moisture Flux Divergence: " + date
plt = gsn_csm_contour_map(wks,fid->VIMFC(nt,:,:) ,res)
