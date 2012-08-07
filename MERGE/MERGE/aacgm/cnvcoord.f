	subroutine cnv$coord(in_lat,in_long,height,order,
     &		out_lat,out_long,out_r,mgflag,err)
c
c	$Revision: 3.2 $
c*****************************************************************
c	Author:  Kile B. Baker
c		 Johns Hopkins Applied Physics Laboratory
c*****************************************************************
c
c
c	This routine uses a set of coefficients from the file
c	cnv$coord.dat to perform a coordinate
c	conversion between geographic and magnetic (or visa versa)
c	coordinates.  The conversion is done using a spherical
c	harmonic expansion.
c
c	REFERENCE:  Baker, K.B. and S. Wing,
c		      J. Geophys. Res.,  Vol. 94, pg. 9139, 1989.
c
c**********************************************************************
c	This program and all the associated subroutines and data files 
c	may be freely copied and distributed, but the Authors and the
c	Applied Physics Laboratory will not be responsible for the 
c	accuracy of the results.  Any publication which utilizes results
c	from this software should reference the paper listed above.
c**********************************************************************
c
c       This version of the program uses the code written for the
c       Space Forecast Center.  The SFC code is modeled after the original
c       PACE magnetic coordinates code.
c
c       Differences between the original PACE code and the SFC code:
c          The PACE code was based on Corrected Geomagnetic Coordinates
c          for 1980, with the conjugate mapping to the southern hemisphere
c          based on the 1985 IGRF, with time derivatives to model the
c          field at 1988.
c
c          The PACE code used a spherical expansion of order 4 or less.
c          The new code ignores the "order" parameter in the call to
c          cnv$coord, since the SFC code uses an order of 10 and that is
c          hardcoded.
c
c          The error codes now include -32 to indicate that the
c          conversion was unsuccessful because the mapping could
c          not be made to the unit sphere.  This condition is also
c          indicated by the fact that "out_r" has the value 0.0.
c
c          The PACE code calculated a value of "out_r".  For a successful
c          conversion, the value had to be close to 1.0.  The SFC code
c          does not return the value out_r.  Therefore, if the conversion
c          was successful, the value of out_r is set to 1.0 exactly.  If
c          the conversion was not successful, the value of out_r is set
c          to 0.
c
c          The PACE code returned non-zero values for out_lat and out_long
c          even if the conversion was not successful (i.e. out_r was not 1.0).
c          The SFC code will return 0.0, 0.0 if the conversion is not
c          successful.
c
c       ERROR CODES:
c       0    OK
c       -2   height is invalid (must be between 0 and 2000)
c       -4   mgflag is invalid (must be 1 or 2)
c       -8   in_lat is invalid (must be -90.0 to +90.0)
c       -16  in_long is invalid (must be between -360 and + 360)
c       -32  conversion was invalid (see above)
c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c
c       $Log: cnvcoord.f,v $
c Revision 3.2  1996/03/20  22:52:00  baker
c explicitly declared the size of the integer arguments
c to the subroutine.  This will help avoid trouble when
c mixing C and Fortran on different machines and different
c compilers.
c
c Revision 3.1  1994/10/14  10:39:49  baker
c This is the initial version of the wrapper for sfc$$convert_geo_coord.
c This version also uses the RCS standards to maintain information about the
c revisions.  The previous version of cnv$coord was 2.02.  That version
c is not maintained by RCS.
c
c
	real in_lat, in_long, height, out_lat, out_long, out_r
	integer*2 mgflag, err, order

	integer*4 i_flag, i_error
c
c
c       The PACE software accepts in_long values either in the range -180 to 
c       +180 or in the range 0 to 360.  The SFC software only allows the
c       0 to 360 range.
c

	i_flag = mgflag

	if (in_long .lt. 0.0) in_long = in_long + 360.0

	call sfc$$convert_geo_coord (in_lat, in_long, height, 
     1                     out_lat, out_long, i_flag, i_error)

	err = i_error

	if (err .eq. 0) then
	   out_r = 1.0
c
c       The SFC code returns longitudes in the range 0 - 360.  The
c       PACE code has to return the values in the range -180 to +180.
c
	   if (out_long .gt. 180.0) out_long = out_long - 360.0
	   return
	else if (err .eq. -32) then
	   out_r = 0.0
	   return
	else
	   return
	endif
	end

	   
