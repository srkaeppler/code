pro	hwm_fig

ps_open, '~/Desktop/hwm_igrf.ps'

time = 1900

hwm_plot_map, 20100621, time, param='dipdecvect', panel=[0,0,4], imod=1
hwm_plot_map, 20101221, time, param='dipdecvect', panel=[0,1,4], imod=1
hwm_plot_map, 20100621, time, param='eff', panel=[1,0,4], imod=1
hwm_plot_map, 20101221, time, param='eff', panel=[1,1,4], imod=1

ps_close


end