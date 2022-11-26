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

date  = 20080715        ; NH summer
date  = 20211005        ; NH summer

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
; plot results
;*************************************************
fout = "Figure_IVT&DIV_" + date

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

; printVarSummary(div)
DIV  = div(nt,{LEVP},:,:)                     ; keep meta data
DIV  = DIV*scl6                               ; nicer numbers


plot := new(2,graphic)
; wks_type@wkPaperSize = "A4"
wks_type = "pdf"
wks_type@wkPaperWidthF  = 12  ; in inches
wks_type@wkPaperHeightF = 8  ; in inches
wks   = gsn_open_wks(wks_type, fout)        ; send graphics to PNG file

; Figure1: divergent wind
resd = plot_div()
resd@tiMainString    = "Divergence and Divergent Winds"
resd@gsnCenterString = LEVP+"hPa: "+date
resd@gsnRightString  = sclab6+" "+div@units
dplt = gsn_csm_vector_scalar_map(wks, ud(nt,{LEVP},:,:), vd(nt,{LEVP},:,:), DIV, resd)
; delete(fid)



; Figure2: Moisture Transport [uq, vq] at a specified pressure level
res = plot_ivt()
LEVP    = 700
res@gsnCenterString      = LEVP+"hPa"
plot(0) = gsn_csm_contour_map(wks,fid->uq(nt,{LEVP},:,:),res)
plot(1) = gsn_csm_contour_map(wks,fid->vq(nt,{LEVP},:,:),res)

resP                     = True                ; modify the panel plot
resP@gsnPanelMainString  = date+": Unweighted Moisture Flux Components"
resP@gsnPanelLabelBar    = True                ; add common colorbar
gsn_panel(wks,plot,(/1,2/),resP)               ; now draw as one plot


;Figure3: Integrated Moisture Transport [iuq, ivq]
delete(res@gsnCenterString)              ; not used for this plot
res@cnMaxLevelValF       = 10.0          ; min level
res@cnMinLevelValF       = -res@cnMaxLevelValF     ; min level
res@cnLevelSpacingF      =  0.5          ; contour interval

IUQ     = fid->iuq(nt,:,:)                    ; local array: keep meta data
IUQ     = IUQ/scl5                       ; scale for plot
res@gsnRightString  = SCLAB5+" "+fid->iuq@units
plot(0) = gsn_csm_contour_map(wks,IUQ,res)

IVQ     = fid->ivq(nt,:,:)                    ; local array: keep meta data
IVQ     = IVQ/scl5
; res@gsnRightString  = SCLAB5+" "+fid->ivq@units
plot(1) = gsn_csm_contour_map(wks,IVQ,res)

resP@gsnPanelMainString  = date+": Mass Wgt. Component Moisture Flux"
gsn_panel(wks,plot,(/1,2/),resP)               ; now draw as one plot

delete( [/IUQ, IVQ/] )                   ; no longer needed



; Figure4: Divergence of Moisture Flux
res@cnMaxLevelValF       = 100.0               ; min level
res@cnMinLevelValF       = -res@cnMaxLevelValF ; min level
res@cnLevelSpacingF      =  5.0                ; contour interval

plot := new(3,graphic)

procedure plot_duvq(LEVP, i)
begin
  DUVQ = fid->duvq(nt,{LEVP},:,:)               ; keep meta data
  DUVQ = DUVQ*scl6                              ; scale for plot
  res@gsnCenterString = LEVP+"hPa"
  res@gsnRightString  = sclab6+" "+fid->duvq@units
  plot(i) = gsn_csm_contour_map(wks, DUVQ, res)
  ; return p
end
plot_duvq(850, 0)
plot_duvq(500, 1)
plot_duvq(300, 2)

resP@gsnPanelMainString  = date+": Divergence of Moisture Flux"
gsn_panel(wks,plot,(/2,2/),resP)                ; now draw as one plot

; delete(DUVQ)                                        ; no longer needed



; Figure5: ---Integrated Divergence of Moisture Flux Convergence [no scaling]
delete([/res@gsnCenterString, res@gsnRightString/]) ; not used in next plot

; res@gsnDraw              = True
; res@gsnFrame             = True
; res@lbLabelBarOn         = True
; ;res@cnFillPalette        = "cmp_flux"
; res@cnMaxLevelValF       =  0.50                ; min level
; res@cnMinLevelValF       = -res@cnMaxLevelValF  ; min level
; res@cnLevelSpacingF      =  0.050               ; contour interval
; res@tiMainString         = date+": VIMFC"
; plt = gsn_csm_contour_map(wks,fid->VIMFC(nt,:,:) ,res)

printVarSummary(fid)

resd = plot_div()
resd@tiMainString    = "Integrated Moisture Flux Convergence and IVT wind"
resd@gsnCenterString = LEVP+"hPa: "+date
resd@gsnRightString  = sclab6+" "+div@units
dplt = gsn_csm_vector_scalar_map(wks, fid->iuq(nt,:,:), fid->ivq(nt,:,:), \
  fid->VIMFC(nt,:,:), resd)
