pro	rt_stat_year, year, radar

common rt_data_blk

set_colorsteps, 250

mjuls = timegen(start=julday(06,01,year), final=julday(01,01,year+1), units='months')
caldat, mjuls[0], month, day, year
date = year*10000L+month*100L+day

rt_run, date, radar
power = rt_data.lpower*0.
ionospower = power

for im=0,n_elements(mjuls)-2 do begin
	djuls = timegen(start=mjuls[im], final=mjuls[im+1], units='days')
	caldat, djuls, month, day, years
	date = years*10000L+month*100L+day

	filen = strtrim(year,2)+strtrim(string(month[0],format='(I02)'),2)+'_'+radar+'.stat'
	ps_open, '~/Desktop/rt_year/'+filen+'.ps'
	set_format, /portrait, /sardines
	clear_page

	for id=0,n_elements(djuls)-1 do begin
		rt_run, date[id], radar, /ionos;, /force
		pinds = where(rt_data.power gt 0., cc)
		if cc gt 0. then $
			power[pinds] = power[pinds] + 10.^(rt_data.power[pinds]/10.)/max(10.^(rt_data.power[pinds]/10.))
		pinds = where(rt_data.ionospower gt 0., cc)
		if cc gt 0. then $
			ionospower[pinds] = ionospower[pinds] + 10.^(rt_data.ionospower[pinds]/10.)/max(10.^(rt_data.ionospower[pinds]/10.))
	endfor
	rt_data.power = power/max(power)
	rt_data.ionospower = ionospower/max(ionospower)
	
	rt_plot_rti_panel, 1,2,0,0, scale=[0.,1.], /bar, param='power'
	plot_colorbar, 1, 1, 0, 0, scale=[0.,1.], level_format='(f4.2)', legend='count', /no_rotate
	
	rt_plot_rti_panel, 1,2,0,1, /ionos, scale=[0.,1.], /bar, param='power'
	plot_colorbar, 1, 1, 0, 0, scale=[0.,1.], level_format='(f4.2)', legend='count', /no_rotate

	ps_close
	spawn, 'ps2png.sh ~/Desktop/rt_year/'+filen+'.ps'
	spawn, 'mv '+filen+'.png '+'~/Desktop/rt_year/'+filen+'.png' 
endfor

set_colorsteps, 8

end