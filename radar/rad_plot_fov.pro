;+
; NAME:
; RAD_PLOT_FOV
;
; PURPOSE:
; This procedure plots radar field of views and highlight one or more beams if desired
;
; CATEGORY:
; graphics
;
; CALLING SEQUENCE:
; rad_plot_fov, radar, date=date, beam=beam, coords=coords, grid=grid, ps=ps, no_fill_beam=no_fill_beam
;
; INPUTS:
; RADAR: radar code(s)
;
; DATE: by default the current date, but since radar configurations change with time, you can provide a team
;
; COORDS: Default if 'magn', but you can also use 'geog'
;
; XYRANGE: The ranges are automatically adjusted to fit all the fovs properly, but if you want to adjust them manually, use these 2 keywords
;
; KEYWORD PARAMETERS:
;
; COMMON BLOCKS:
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
;
; MODIFICATION HISTORY:
; Written by Sebastien de Larquier 02/2012
; -
pro	rad_plot_fov, radar, date=date, beam=beam, coords=coords, $
		grid=grid, ps=ps, no_fill_beam=no_fill_beam, xrange=xrange, yrange=yrange, $
		fovonly=fovonly, rotate=rotate, panel=panel, xpanel=xpanel, fovcolor=fovcolor, $
		fillannotate=fillannotate

common radarinfo

if n_elements(xrange) eq 2 then $
	xrangeset = xrange
if n_elements(yrange) eq 2 then $
	yrangeset = yrange

if n_elements(panel) ne 2 then $
	panel = [1,0]
ymaps = panel[0]
ymap = panel[1]
if n_elements(xpanel) ne 2 then $
	xpanel = [1,0]
xmaps = xpanel[0]
xmap = xpanel[1]
charsize = get_charsize(xmaps,ymaps)

; if radar eq 'all' then radar = network[1:*].code[0]

radptr = PTRARR(n_elements(radar), /allocate_heap)
n_valid_radars = 0L
hemi = intarr(n_elements(radar))
for ir=0,n_elements(radar)-1 do begin
	; Set coordinate system
	if ~keyword_set(coords) then $
		coords = 'magn'
	if coords ne 'magn' and coords ne 'geog' then begin
		print, 'Invalid coordinate system. Using magn'
		coords = 'magn'
	endif
	
	; First find radar site structure
	radID = where(network.code[0,*] eq radar[ir], cc)
	if cc le 0 then begin
		print, 'Unknown radar. Skipping.'
		continue
	end
	n_valid_radars = n_valid_radars + 1

	; Find range-gate locations
	if ~keyword_set(date) then $
		ajul = systime(/julian, /utc) $
	else $
	ajul = calc_jul(date,1200)
	caldat, ajul, mm, dd, year
	tval = TimeYMDHMSToEpoch(year, mm, dd, 12, 0, 0)
	if tval lt network[radID].st_time then begin
		tval = network[radID].st_time
		jul0 = julday(1,1,1970)
		ajul = (jul0 + tval/86400.d)
		caldat, ajul, mm, dd, year
	endif
	for s=0,31 do begin
		if (network[radID].site[s].tval eq -1) then break
		if (network[radID].site[s].tval ge tval) then break
	endfor
	radarsite = network[radID].site[s]
	yrsec = (ajul-julday(1,1,year,0,0,0))*86400.d
	ngates = 75
	nbeams = radarsite.maxbeam
	rad_define_beams, network[radID].id, nbeams, ngates, year, yrsec, coords=coords, $
			/normal, fov_loc_full=fov_loc_full

	; +1 for North hemisphere, -1 for south
	hemi[ir] = fix( radarsite.geolat/abs(radarsite.geolat) )
	if ir gt 0 then if hemi[ir]*hemi[ir-1] lt 0 then return

	; Calculate stereographic projection and plot
	for ib=0,nbeams do begin
		for ig=0,ngates do begin
			for p=0,3 do begin
				lat = fov_loc_full[0,p,ib,ig]
				lon = fov_loc_full[1,p,ib,ig]
				tmp = calc_stereo_coords(lat, lon, rotate=rotate)
				fov_loc_full[0,p,ib,ig] = tmp[0]
				fov_loc_full[1,p,ib,ig] = tmp[1]
			endfor
		endfor
	endfor
	*radptr[ir] = {fov_loc_full: fov_loc_full, nbeams: nbeams, ngates:ngates}

	; Set plot limits
	txrange = [min(fov_loc_full[0,*,*,*],xmin)-5, max(fov_loc_full[0,*,*,*],xmax)+5]
	tyrange = [min(fov_loc_full[1,*,*,*],ymin)-5, max(fov_loc_full[1,*,*,*],ymax)+5]
	if ir eq 0 then begin
		xrange = txrange
		yrange = tyrange
	endif else begin
		if abs(txrange[0]) gt abs(xrange[0]) then $
			xrange[0] = txrange[0]
		if abs(txrange[1]) gt abs(xrange[1]) then $
			xrange[1] = txrange[1]
		if abs(tyrange[0]) gt abs(yrange[0]) then $
			yrange[0] = tyrange[0]
		if abs(tyrange[1]) gt abs(yrange[1]) then $
			yrange[1] = tyrange[1]
	endelse

endfor
; If no valid radars were provided
if n_valid_radars eq 0 then begin
	loadct, 0
	map_plot_panel, xmaps, ymaps, xmap, ymap, coords=coords, /iso, yrange=yrange, xrange=xrange, hemi=hemi[0], $
		coast_linecolor=150, grid_linecolor=200, lake_fillcolor=255, rotate=rotate, charsize=charsize
	return
endif

; Adjust plot limits so that they cover the same extent
ext = abs(abs(xrange[1]-xrange[0]) - abs(yrange[1]-yrange[0]))
if abs(xrange[1]-xrange[0]) gt abs(yrange[1]-yrange[0]) then begin
	yrange[1] = yrange[1] + ext/2.
	yrange[0] = yrange[0] - ext/2.
endif else if abs(xrange[1]-xrange[0]) lt abs(yrange[1]-yrange[0]) then begin
	xrange[1] = xrange[1] + ext/2.
	xrange[0] = xrange[0] - ext/2.
endif

; User overwrites auto-set limits
if n_elements(xrangeset) eq 2 then $
	xrange = xrangeset
if n_elements(yrangeset) eq 2 then $
	yrange = yrangeset

; Set plot area
if keyword_set(ps) then $
	ps_open, '~/Desktop/rad_plot_fov.ps', /no_init
loadct, 0
if ~keyword_set(fovonly) then begin
map_plot_panel, xmaps, ymaps, xmap, ymap, coords=coords, /iso, yrange=yrange, xrange=xrange, hemi=hemi[0], $
	coast_linecolor=150, lake_fillcolor=255, rotate=rotate, charsize=charsize, /no_grid
endif else begin
map_plot_panel, xmaps, ymaps, xmap, ymap, coords=coords, /iso, yrange=yrange, xrange=xrange, hemi=hemi[0], $
	/no_grid, rotate=rotate, charsize=charsize; /no_axis, /no_label,
endelse
; Calculate stereographic projection and plot
xx = fltarr(4)
yy = fltarr(4)
ibeam = 0L
loadct, 13
if radar[0] ne '' then begin
	for ir=0,n_elements(radar)-1 do begin
		for ib=0,(*radptr[ir]).nbeams-1 do begin
			for ig=0,(*radptr[ir]).ngates-1 do begin
				xx = reform((*radptr[ir]).fov_loc_full[0,*,ib,ig])
				yy = reform((*radptr[ir]).fov_loc_full[1,*,ib,ig])
				if (max(xx) gt xrange[1]) or (min(xx) lt xrange[0]) then continue
				if (max(yy) gt yrange[1]) or (min(yy) lt yrange[0]) then continue
				; Highlight field of view
				if n_elements(fovcolor) eq n_elements(radar) then begin
						if fovcolor[ir] gt 0 then polyfill, xx, yy, col=fovcolor[ir]
				endif
			endfor
		endfor
	endfor
endif
loadct,8
if radar[0] ne '' then begin
	for ir=0,n_elements(radar)-1 do begin
		if keyword_set(fovcolor) and keyword_set(fillannotate) then begin
				if fovcolor[ir] gt 0 then overlay_radar, date=date, name=radar[ir], /anno, coords=coords, rotate=rotate, charsize=charsize
		endif
		if ~keyword_set(fillannotate) then overlay_radar, date=date, name=radar[ir], /anno, coords=coords, rotate=rotate, charsize=charsize
		for ib=0,(*radptr[ir]).nbeams-1 do begin
			for ig=0,(*radptr[ir]).ngates-1 do begin
				xx = reform((*radptr[ir]).fov_loc_full[0,*,ib,ig])
				yy = reform((*radptr[ir]).fov_loc_full[1,*,ib,ig])
				if (max(xx) gt xrange[1]) or (min(xx) lt xrange[0]) then continue
				if (max(yy) gt yrange[1]) or (min(yy) lt yrange[0]) then continue
				; Highlight selected beam(s)
				if n_elements(beam) eq 1 then begin
					if (ib eq beam) then begin
						if ~keyword_set(no_fill_beam) then $
							polyfill, xx, yy, col=220
						plots, xx[1:2], yy[1:2], thick=2
						plots, [xx[0],xx[3]], [yy[0],yy[3]], thick=2
					endif
				endif else if n_elements(beam) eq n_elements(radar) then begin
					if (ib eq beam[ir]) then begin
						if ~keyword_set(no_fill_beam) then $
							polyfill, xx, yy, col=220
						plots, xx[1:2], yy[1:2], thick=2
						plots, [xx[0],xx[3]], [yy[0],yy[3]], thick=2
					endif
				endif else if n_elements(beam) gt 1 then begin
					if (ib eq beam[ibeam]) then begin
						if ~keyword_set(no_fill_beam) then $
							polyfill, xx, yy, col=220
						plots, xx[1:2], yy[1:2], thick=2
						plots, [xx[0],xx[3]], [yy[0],yy[3]], thick=2
						ibeam = ibeam + 1
					endif
				endif
				if keyword_set(grid) then $
					plots, [xx, xx[0]], [yy, yy[0]], thick=.25
				; Plot fov limits
				if ib eq 0 then $
					plots, [xx[0],xx[3]], [yy[0],yy[3]], thick=.5
				if (ib eq (*radptr[ir]).nbeams-1) then $
					plots, xx[1:2], yy[1:2], thick=.5
				if (ig eq (*radptr[ir]).ngates-1) then $
					plots, xx[2:3], yy[2:3], thick=.5
				if (ig eq 0) then $
					plots, xx[0:1], yy[0:1], thick=.5
			endfor
		endfor
	endfor
endif

if ~keyword_set(fovonly) then begin
	loadct, 0
	map_plot_panel, xmaps, ymaps, xmap, ymap, coords=coords, /iso, /no_fill, yrange=yrange, xrange=xrange, hemi=hemi[0], $
		coast_linecolor=150, rotate=rotate, charsize=charsize, grid_linecolor=200, grid_linethick=.2
endif

if keyword_set(ps) then $
	ps_close, /no_filename, /no_init

end
