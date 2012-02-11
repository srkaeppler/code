pro iri_plot

common rt_data_blk

rt_run, 20100813, 'bks', time=[1300,500]

for it=0,n_elements(rt_data.juls[*,0])-1 do begin
	caldat, rt_data.juls[it,0], month, day, year, hr, mn
	date = year*10000L + month*100L + day
	time = hr*100L + mn
	iri_run, date, time, param='alti', lati=42.6, longi=288.5, alti=[60.,560.], nel=nel, /ut

	rt_data.edens[it,0,*] = nel*1e11
endfor



end