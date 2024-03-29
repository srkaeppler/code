;+ 
; NAME: 
; RT_PLOT_IONOSCAT3
;
; PURPOSE: 
; This procedure plots the ionosphric scatter surface as a function of:
; 	- ground range and beam
; 	- elevation or altitude
; PREREQUISITE: RT_RUN
; 
; CATEGORY: 
; Graphics
; 
; CALLING SEQUENCE:
; RT_PLOT_IONOSCAT3, time, xparam=xparam, zparam=zparam, date=date, ps=ps
;
; INPUTS:
; TIME: time of your raytracing run for which you want to plot the ray paths
;
; KEYWORD PARAMETERS:
; ZPARAM: 'elevation' or 'altitude' (Default is 'elevation')
;
; KEYWORDS:
;
; COMMON BLOCKS:
; RT_DATA_BLK
;
; EXAMPLE:
;
; COPYRIGHT:
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
; THE SOFTWARE.
;
; MODIFICATION HISTORY:
; Written by Sebastien de Larquier, Nov.2010
;-
pro rt_plot_ionoscat3, time, zparam=zparam, date=date, ps=ps, az=az, scale=scale

common rt_data_blk

Rav = 6370.

; Z axis 
if ~keyword_set(zparam) then $
	zparam = 'altitude'

case zparam of
	'elevation': 	begin
						ztitle = 'Elevation'
						zrange = [0.,40.]
					end
	'altitude': 	begin
						ztitle = 'Altitude [km]'
						zrange = [0.,500.]
					end
endcase

; Retrieve raytracing parameters from structure
radar = rt_info.name
caldat, rt_data.juls[*,0], month, day, year, hours, minutes
tdate 	= year*10000L + month*100L + day

parse_time, time, hour, minute
if ~keyword_set(date) then $
	date = tdate[0]
timeind = where(tdate eq date and hours eq hour and minutes eq minute)
juls = julday(month[timeind], day[timeind], year[timeind], hours[timeind], minutes[timeind])

; Test for data availability
rt_read_rays, date, radar, time, radpos=radpos, thtpos=thtpos, grppth=grppth, raysteps=raysteps, code=code
if ~code then $
	return

if ~keyword_set(scale) then $
	scale = [rt_info.elev_beg, rt_info.elev_end]

; Count element of matrix
nrays = n_elements(radpos[0,*,0])

; Open postscript if desired
if keyword_set(ps) then begin
	ps_open, '~/Desktop/ionoscat3_'+STRTRIM(date,2)+'_'+ $
		STRTRIM(STRING(time,format='(I04)'),2)+rt_info.timez+'.ps', /no_init
	set_format, /landscape
	clear_page
endif

; Set plot limits
nbeams = n_elements(rt_data.beam[timeind,*])
xrange = [rt_data.beam[timeind,0], rt_data.beam[timeind,nbeams-1]+1]
xtitle = 'Beam #'
yrange = [0.,2000.]
ytitle = 'Ground range [km]'
scale3, xrange=xrange, yrange=yrange, zrange=zrange, az=az
t3d, translate=[-.04,0.,0.]

; Set tolerance (in degree) for how much deviation from perfect aspect condition is allowed
tol = 1.

; latitude/longitude distribution (expressed as angle from radar with Earth center)
ndip = n_elements(rt_data.dip[timeind,0,0,*])
thtdip = findgen(ndip)*2500./Rav/ndip

dgates = 5.*45.
rgates = 180. + findgen(100)*dgates
for ib=nbeams-1,0,-1 do begin
	for nr=0,nrays-1 do begin
		nrsteps = raysteps[ib,nr]
		ng = 0
		for ns=1,nrsteps-1 do begin
			if grppth[ib,nr,ns-1] gt 180e3 and thtpos[ib,nr,ns]*Rav le yrange[1] then begin

				; Calculate k vector
				kx = radpos[ib,nr,ns]*sin(thtpos[ib,nr,ns]-thtpos[ib,nr,ns-1])
				kz = radpos[ib,nr,ns]*cos(thtpos[ib,nr,ns]-thtpos[ib,nr,ns-1]) - radpos[ib,nr,ns-1]
				kvect = sqrt( kx^2. + kz^2. )

				; Plot coordinates
				xx = rt_data.beam[timeind[0],ib] + [0, 1]
				yy = [thtpos[ib,nr,ns-1], thtpos[ib,nr,ns]]*Rav
				case zparam of
					'elevation': zz = [1., 1.]*(rt_info.elev_beg + nr*rt_info.elev_stp)
					'altitude': zz = [radpos[ib,nr,ns-1], radpos[ib,nr,ns]]*1e-3 - Rav
				endcase
				if zz[1] ge zrange[1] then $
					continue
				
				; Middle of the step: position and index in B grid
				midtht = (thtpos[ib,nr,ns]-thtpos[ib,nr,ns-1])/2. + thtpos[ib,nr,ns-1]
				diff = min(midtht-thtdip, thtind, /abs)
				
				; Dip and declination at this position
				middip = rt_data.dip[timeind,ib,0,thtind]
				middec = rt_data.dip[timeind,ib,1,thtind]

				; calculate vector magnetic field
				Bx = cos(-middip*!dtor) * cos(rt_data.azim[timeind[0],ib]*!dtor - middec*!dtor)
				Bz = sin(-middip*!dtor)
				
				; calculate cosine of aspect angle
				cos_aspect = (Bx*kx + Bz*kz)/kvect
				
				if abs(cos_aspect) le cos(!pi/2. - tol*!dtor) then begin
					col = bytscl(rt_info.elev_beg + nr*rt_info.elev_stp, min=scale[0], max=scale[1], top=251) + 3b
; 					col = bytscl(zz[0], min=0., max=500., top=251) + 3b
					polyfill, [xx[0],xx[0],xx[1],xx[1]], $
							[yy[0],yy[1],yy[1],yy[0]], $
							[zz[0],zz[1],zz[1],zz[0]], color=col, /t3d
				endif

			endif
		; end ray steps loop
		endfor
	; end rays loop
	endfor
; End beam loop
endfor
for ib=nbeams-1,0,-1 do begin
	for ng=0,rt_info.ngates-2 do begin
		plots, rt_data.beam[timeind[0],ib]+[0,0,1,1,0], $
			rt_data.grange[timeind[0],ib,ng]+[0,45.,45.,0,0]*cos(rt_data.elevation[timeind[0],ib,ng]*!dtor), $
			rt_data.altitude[timeind[0],ib,ng]+[0,45.,45.,0,0]*sin(rt_data.elevation[timeind[0],ib,ng]*!dtor), /t3d
	endfor
endfor


edensrange = [8.,12.]
altsNe = 60. + findgen(n_elements(rt_data.edens[0,0,*,0]))*500./n_elements(rt_data.edens[0,0,*,0])
edens = reform((alog10(rt_data.edens[timeind,round(nbeams/2.)-1,*,125]) - edensrange[0])/(edensrange[1]-edensrange[0])*xrange[1] + xrange[0])
plotinds = where(altsNe le zrange[1] and edens ge xrange[0] and edens le xrange[1])
plots, edens[plotinds], yrange[1]+fltarr(n_elements(plotinds)), altsNe[plotinds], /t3d, thick=2

; Plot axis
title = STRMID(format_juldate(rt_data.juls[timeind]),0,17)
subtitle = 'Radar: '+rt_info.name+', Freq. '+$
	STRTRIM(string(rt_data.tfreq[timeind],format='(F5.2)'),2)+' MHz'

charsize=2
plot, xrange, yrange, xstyle=1, ystyle=1, position=[0,0,1,1,0,0], /t3d, /nodata, charsize=charsize, $
	xticklen=1, yticklen=1, xgridstyle=2, ygridstyle=2, $
	xtitle=xtitle, ytitle=ytitle
t3d, /yzexch
plot, xrange, zrange, xstyle=9, ystyle=1, position=[0,0,1,1,1,1], /t3d, /nodata, charsize=charsize, $
	xtickname=replicate(' ', 60), $
	xticklen=1, yticklen=1, xgridstyle=2, ygridstyle=2, $
	ytitle=ztitle, xtick_get=xticks
axis, xax=1, /t3d, charsize=charsize, xrange=xrange, xstyle=1, xtitle='N!Ie!N [log(m!e-3!N)]', $
	xtickname=strtrim(string((xticks-xrange[0])/xrange[1]*(edensrange[1]-edensrange[0])+edensrange[0], format='(f5.2)'),2)
t3d, /xzexch
plot, yrange, zrange, xstyle=1, ystyle=1, position=[0,0,1,1,1,1], /t3d, /nodata, charsize=charsize, $
	xtickname=replicate(' ', 60), ytickname=replicate(' ', 60), xgridstyle=2, ygridstyle=2, $
	xticklen=1, yticklen=1

; xyouts, .8, .9, STRTRIM(STRING(time,format='(I04)'),2)+' '+rt_info.timez, align=.5, /normal

plot, [0., 24.], [0., 1.], /nodata, xstyle=1, ystyle=1, $
	xticks=1, yticks=1, ytickname=replicate(' ', 60), $
	position=[.8,.9,.95,.95], title='UT'
timeflt = hour + minute/60.
polyfill, [0,timeflt,timeflt,0], [0,0,1,1], col=1

plot_colorbar, /vert, charthick=charthick, /continuous, $
	nlevels=4, scale=scale, position=[.9,.1,.92,.8], charsize=charsize, $
	legend='Elevation', /no_rotate, $
	level_format='(F4.1)', /keep_first_last_label

; Close potscript if necessary
if keyword_set(ps) then $
	ps_close, /no_init

end