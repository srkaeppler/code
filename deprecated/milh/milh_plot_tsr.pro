PRO	milh_plot_tsr, param=param, altm=altm, azm=azm

clear_page
milh_read, nlines, juls, alt, az, el, range, lat, lon, ti, te, nel, vo, dti, dtr, dnel, dvo

; altitude and azimuth of interest
; azm = -90.

if ~keyword_set(param) then $
	param = 'vo'
nparams = n_elements(param)

sjul = JULDAY(11, 17, 2010, 21, 00)
fjul = JULDAY(11, 18, 2010, 13, 00)
xrange = [sjul, fjul]
xticks = get_xticks(sjul, fjul, xminor=_xminor)

; Set number of panels
xmaps = 1
ymaps = nparams
nsum = 2
charsize = get_charsize(1, 2)
if nparams gt 3 then $
  set_format, /sardines, /portrait $
else $
  set_format, /sardines, /landscape

; Data plotting
for np=0,nparams-1 do begin
	CASE param[np] OF
		'vo': 	begin
			  ytitle = textoidl('Velocity [m/s]')
			  scale = [-100.,100.]
			end
		'ti': 	begin
			  ytitle = textoidl('T_i [K]')
			  scale = [600.,1000.]
			end
		'te': 	begin
			  ytitle = textoidl('T_e [K]')
			  scale = [500.,3000.]
			end
		'nel': begin
			  ytitle = textoidl('N_{el} [log(m^{3})]')
			  scale = [10.,12.]
			end
	ENDCASE
	xmap = 0
	ymap = np
	
	if ymap eq nparams-1 then $
		last = 1L $
	else $
		last = 0L

	s = execute('paramdata = '+param[np])
	inds = where(alt ge altm-20. and alt le altm+20. $
			and az ge azm-1. and az le azm+1.,cinds)
	
	trendX = timegen(500,start=sjul,final=fjul,minutes=indgen(6)*10)
	trend = median(paramdata[inds],50)

	position = define_panel(xmaps, ymaps, xmap, ymap)
	if last eq 0L then begin
	  plot, juls[inds], paramdata[inds], position = position, $
	    xtitle = '', ytitle = ytitle, xtickname=REPLICATE(' ',60), $
	    min_value=scale[0], max_value=scale[1], nsum=nsum, $
	    xticks=xticks, xminor=_xminor, xtickformat='', xstyle=1, $
	    charsize=charsize, charthick=2, thick=1, yrange=scale, xrange=xrange
	  oplot, juls[inds], trend, color=240, thick=2
	endif else begin
	  plot, juls[inds], paramdata[inds], position = position, $
	    xtitle = 'Time (UT)', ytitle = ytitle, $
	    min_value=scale[0], max_value=scale[1], nsum=nsum, $
	    xticks=xticks, xminor=_xminor, xtickformat='label_date', xstyle=1, $
	    charsize=charsize, charthick=2, thick=1, yrange=scale, xrange=xrange
	  oplot, juls[inds], trend, color=240, thick=2
	endelse
endfor

title = 'MILSTONE HILL'
subtitle = 'Parameter plot at '+STRTRIM(altm,2)+' km'
sdate = format_juldate(sjul)
right_title = sdate+'!C!5 to !C!5'+format_juldate(fjul)
plot_title, title, subtitle, top_right_title=right_title


END