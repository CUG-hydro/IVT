load "src/main_IVT.ncl"

ptop = 300              ; 'shum' upper level
ptop@units = "hPa"

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

fout = "IVT.nc"
fid = cal_IVT(u, v, q, ps, ptop, fout)
; print(fid)
; printVarSummary(fid)

;*************************************************
; plot results
;*************************************************
fout = "Figure_tmp"

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

wks_type = "pdf"
; wks_type@wkPaperSize = "A4"
wks_type@wkPaperWidthF  = 10  ; in inches
wks_type@wkPaperHeightF = 8  ; in inches
wks_type@gsnPaperMargin = 0.1; 
wks_type@gsnBoxMargin = 0.01;

wks   = gsn_open_wks(wks_type, fout)        ; send graphics to PNG file

; Figure1: divergent wind
resd = plot_div()
resd@tiMainString    = "Divergence and Divergent Winds"
resd@gsnCenterString = LEVP+"hPa: "+date
resd@gsnRightString  = sclab6+" "+div@units

; resd@wkPaperWidthF  = 10
; resd@wkPaperHeightF = 10
; resd@gsnMaximize        = True                   ; use full page

dplt = gsn_csm_vector_scalar_map(wks, ud(nt,{LEVP},:,:), vd(nt,{LEVP},:,:), DIV, resd)
; delete(fid)
