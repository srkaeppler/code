"""The madrigalWeb module provides access to all Madrigal data via web services.

"""

# $Id: madrigalWeb.py 4077 2012-09-18 17:47:42Z brideout $


import os, os.path, sys
import traceback
import urllib,urllib2
import types
import re
import urlparse
import datetime


class MadrigalData:
    """MadrigalData is a class that acquires data from a particular Madrigal site.


    Usage example::

        import madrigalWeb.madrigalWeb
    
        test =  madrigalWeb.madrigalWeb.MadrigalData('http://madrigal.haystack.mit.edu/madrigal')

        instList = test.getInstrumentList()
            


    Non-standard Python modules used: None


    Change history:

    Written by "Bill Rideout":mailto:wrideout@haystack.mit.edu  Feb. 10, 2004

    """
    def __init__(self, url):
        """__init__ initializes a MadrigalData object.

        Inputs::

            url - (string) url of main page of madrigal site. Example: 'http://madrigal.haystack.mit.edu/madrigal'

        Affects: Converts main page to cgi url, and stores that.

        Also stores self.siteDict, with key = site id, value= site url, and self.siteId

        Exceptions: If url not found.
        """
        cgiName = 'accessData.cgi'

        regExp = re.compile('".*' + cgiName)

        # get base of url
        urlParts = urlparse.urlparse(url)

        urlBase = urlParts[0] + '://' + urlParts[1]

        # read main url
        try:
            mainUrl = urllib2.urlopen(url)
        except:
            raise ValueError, 'unable to open url ' + str(url)

        page = mainUrl.read()

        mainUrl.close()

        result = regExp.search(page)

        # check for success
        if result == None:
            raise ValueError, 'invalid url: ' + str(url)

        result = result.group()

        if type(result) != types.StringType:
            result = result[0]

        self.cgiurl = urlBase + result[1:(-1*len(cgiName))]

        self.siteDict = self.__getSiteDict()

        self.siteId = self.__getSiteId()
        
        # get Madrigal version
        self._madVers = self.getVersion()


    def __getSiteDict(self):
        """__getSiteDict returns a dictionary with key = site id, value= site url.

        Uses getMetadata cgi script
        """
        url = os.path.join(self.cgiurl, 'getMetadata?fileType=5')

        f = urllib2.urlopen(url)

        page = f.read()

        f.close()

        lines = page.split('\n')

        siteDict = {}

        for line in lines:
            items = line.split(',')
            if len(items) < 4:
                continue
            site = int(items[0])
            thisUrl = 'http://%s/%s' % (items[2], items[3])
            siteDict[site] = thisUrl

        return siteDict


    def __getSiteId(self):
        """__getSiteId returns the local site id

        Uses getMetadata cgi script
        """
        url = os.path.join(self.cgiurl, 'getMetadata?fileType=0')

        f = urllib2.urlopen(url)

        page = f.read()

        f.close()

        lines = page.split('\n')

        for line in lines:
            items = line.split(',')
            if len(items) < 4:
                continue
            siteId = int(items[3])
            return(siteId)

        raise IOError, 'No siteId found'
            
        



    def getAllInstruments(self):
        """ returns a list of all MadrigalInstruments at the given Madrigal site"""

        scriptName = 'getInstrumentsService.py'

        url = self.cgiurl + scriptName

        # read main url
        try:
            mainUrl = urllib2.urlopen(url)
        except:
            raise ValueError, 'unable to open url ' + str(url)

        page = mainUrl.readlines()

        mainUrl.close()

        # parse the result
        if len(page) == 0:
            raise ValueError, 'No data found at url' + str(url)

        # check that html was not returned
        for line in page:
            if line.find('Error occurred') != -1:
                raise ValueError, 'error raised using url ' + str(url) + ' ' + str(page)

        result = []

        for line in page:
            items = line.split(',')
            if len(items) > 6:
                category = items[6]
            else:
                category = 'unknown'
            result.append(MadrigalInstrument(items[0],
                                             items[1],
                                             items[2],
                                             items[3],
                                             items[4],
                                             items[5],
                                             category))

        return result


    
    def getExperiments(self,
                       code,
                       startyear,
                       startmonth,
                       startday,
                       starthour,
                       startmin,
                       startsec,
                       endyear,
                       endmonth,
                       endday,
                       endhour,
                       endmin,
                       endsec,
                       local=1):
        """ returns a list of all MadrigalExperiments that meet criteria at the given Madrigal site

        Inputs:

           code - int or list of ints representing instrument code(s). Special value of 0 selects all instruments.
           
           startyear - int or string convertable to int
           
           startmonth - int or string convertable to int
           
           startday - int or string convertable to int
           
           starthour - int or string convertable to int
           
           startmin - int or string convertable to int
           
           startsec - int or string convertable to int
           
           endyear - int or string convertable to int
           
           endmonth - int or string convertable to int
           
           endday - int or string convertable to int
           
           endhour - int or string convertable to int
           
           endmin - int or string convertable to int
           
           endsec - int or string convertable to int

           local - 0 if all sites desired, 1 (default) if only local experiments desired

        Outputs:

            List of MadrigalExperiment objects that meet the criteria.  Note that if the returned
            MadrigalExperiment is not local, the experiment id will be -1.  This means that you
            will need to create a new MadrigalData object with the url of the 
            non-local experiment (MadrigalExperiment.madrigalUrl), and then call 
            getExperiments a second time using that Madrigal url.  This is because 
            while Madrigal sites share metadata about experiments, the real experiment ids are only
            known by the individual Madrigal sites.  See examples/exampleMadrigalWebServices.py
            for an example of this.


        """

        scriptName = 'getExperimentsService.py'

        url = self.cgiurl + scriptName + '?'

        # first append code(s)
        if type(code) == types.ListType:
            for item in code:
                url += 'code=%i&' % (int(item))
        else:
            url += 'code=%i&' % (int(code))

        # append times
        url += 'startyear=%i&' % (int(startyear))
        url += 'startmonth=%i&' % (int(startmonth))
        url += 'startday=%i&' % (int(startday))
        url += 'starthour=%i&' % (int(starthour))
        url += 'startmin=%i&' % (int(startmin))
        url += 'startsec=%i&' % (int(startsec))
        url += 'endyear=%i&' % (int(endyear))
        url += 'endmonth=%i&' % (int(endmonth))
        url += 'endday=%i&' % (int(endday))
        url += 'endhour=%i&' % (int(endhour))
        url += 'endmin=%i&' % (int(endmin))
        url += 'endsec=%i&' % (int(endsec))
        url += 'local=%i'% (int(local))
        


        # read main url
        try:
            mainUrl = urllib2.urlopen(url)
        except:
            raise ValueError, 'unable to open url ' + str(url)
                

        

        page = mainUrl.readlines()

        mainUrl.close()

        # parse the result
        if len(page) == 0:
            return []

        # check that error was not returned
        for line in page:
            if line.find('Error occurred') != -1:
                raise ValueError, 'error raised using url ' + str(url) + ' ' + str(page)

        result = []


        for line in page:
            items = line.split(',')
            # calculate isLocal
            if int(items[3]) == self.siteId:
                isLocal = True
            else:
                isLocal = False
            if isLocal:
                expIdStr = items[0]
            else:
                expIdStr = '-1'
            if len(items) > 21:
                pi = items[20]
                piEmail = items[21]
            else:
                pi = 'unknown'
                piEmail = 'unknown'
            result.append(MadrigalExperiment(expIdStr,
                                             items[1],
                                             items[2],
                                             items[3],
                                             items[4],
                                             items[5],
                                             items[6],
                                             items[7],
                                             items[8],
                                             items[9],
                                             items[10],
                                             items[11],
                                             items[12],
                                             items[13],
                                             items[14],
                                             items[15],
                                             items[16],
                                             items[17],
                                             items[18],
                                             isLocal,
                                             self.siteDict[int(items[3])],
                                             pi,
                                             piEmail))
            

        return result


    def getExperimentFiles(self, id, getNonDefault=False):
        """ returns a list of all default MadrigalExperimentFiles for a given experiment id

        Inputs:

           id - Experiment id.

           getNonDefault - if False (the default), only get default files, or realtime
                           files if no default files found.  If True, get all files.
                           In general, users should set this to False because default files
                           are the most reliable.

        Outputs:

            List of MadrigalExperimentFile objects for that experiment id


        """

        scriptName = 'getExperimentFilesService.py'
        
        if int(id) == -1:
            raise ValueError, """Illegal experiment id -1.  This is usually caused by calling
            getExperiments with the isLocal flag set to 0.  To get the experiment id for a non-local
            experiment, you will need to create a new MadrigalData object with the url of the 
            non-local experiment (MadrigalExperiment.madrigalUrl), and then call 
            getExperiments a second time using that Madrigal url.  This is because 
            while Madrigal sites share metadata about experiments, the real experiment ids are only
            known by the individual Madrigal sites. See examples/exampleMadrigalWebServices.py
            for an example of this.
            """

        url = self.cgiurl + scriptName + '?id=%i' % (int(id))


        # read main url
        try:
            mainUrl = urllib2.urlopen(url)
        except:
            raise ValueError, 'unable to open url ' + str(url)
                

        page = mainUrl.readlines()

        mainUrl.close()

        # parse the result
        if len(page) == 0:
            return []

        # check that error was not returned
        for line in page:
            if line.find('Error occurred') != -1:
                raise ValueError, 'error raised using url ' + str(url) + ' ' + str(page)

        result = []

        # find out if no default files.  If so, return realtime also
        hasDefault = False
        for line in page:
            items = line.split(',')
            if int(items[3]) == 1:
                hasDefault = True
                break

        for line in page:
            items = line.split(',')
            category = int(items[3])
            if hasDefault and category != 1 and not getNonDefault:
                continue
            if not hasDefault and category != 4 and not getNonDefault:
                continue
            result.append(MadrigalExperimentFile(items[0],
                                                 items[1],
                                                 items[2],
                                                 items[3],
                                                 items[4],
                                                 items[5],
                                                 id))
            

        return result


    def getExperimentFileParameters(self,fullFilename):
        """ getExperimentFileParameters returns a list of all measured and derivable parameters in file

        Inputs:

           fullFilename - full path to experiment file as returned by getExperimentFiles.

        Outputs:

            List of MadrigalParameter objects for that fullFilename.  Includes both measured
            and derivable parameters in file.


        """

        scriptName = 'getParametersService.py'

        url = self.cgiurl + scriptName + '?filename=%s' % (str(fullFilename))


        # read main url
        try:
            mainUrl = urllib2.urlopen(url)
        except:
            raise ValueError, 'unable to open url ' + str(url)
                

        page = mainUrl.readlines()

        mainUrl.close()

        # parse the result
        if len(page) == 0:
            return []

        # check that error was not returned
        for line in page:
            if line.find('Error occurred') != -1:
                raise ValueError, 'error raised using url ' + str(url) + ' ' + str(page)

        result = []



        for line in page:
            items = line.split('\\')
            # with Madrigal 2.5, isAddIncrement was added as 8th column
            try:
                isAddIncrement = int(items[7])
            except:
                isAddIncrement = -1
            result.append(MadrigalParameter(items[0],
                                            items[1],
                                            int(items[2]),
                                            items[3],
                                            int(items[4]),
                                            items[5],
                                            int(items[6]),
                                            isAddIncrement))
            

        return result


    def simplePrint(self, filename, user_fullname, user_email, user_affiliation):
        """simplePrint prints the data in the given file is a simple ascii format.

        simplePrint prints only the parameters in the file, without filters or derived
        parameters.  To choose which parameters to print, to print derived parameters, or
        to filter the data, use isprint instead.

        Inputs:

            filename - The absolute filename to be printed.  Returned by getExperimentFiles.

            user_fullname - full name of user making request

            user_email - email address of user making request

            user_affiliation - affiliation of user making request

        Returns: string representing all data in the file in ascii, space-delimited form.
                 The first line if the list of parameters printed.  The first six parameters will
                 always be year, month, day, hour, min, sec, representing the middle time of
                 the measurment.
        """
        parms = self.getExperimentFileParameters(filename)

        parmStr = 'year,month,day,hour,min,sec'
        labelStr = 'YEAR     MONTH       DAY      HOUR       MIN       SEC        '

        for parm in parms:
            if parm.isMeasured and parm.isAddIncrement != 1:
                parmStr += ',%s' % (parm.mnemonic)
                thisLabel = parm.mnemonic[:11].upper()
                labelStr += '%s%s' % (thisLabel, ' '*(11-len(thisLabel)))

        retStr = '%s\n' % (labelStr)

        retStr += self.isprint(filename, parmStr, '', user_fullname, user_email, user_affiliation)

        return(retStr)

        

    def isprint(self, filename, parms, filters, user_fullname, user_email, user_affiliation):
        """returns as a string the isprint output given filename, parms, filters without headers or summary.

        Inputs:

            filename - The absolute filename to be analyzed by isprint.

            parms - Comma delimited string listing requested parameters (no spaces allowed).

            filters - Space delimited string listing filters desired, as in "isprint command":http://madrigal.haystack.mit.edu/madrigal/ug_commandLine.html#isprint

            user_fullname - full name of user making request

            user_email - email address of user making request

            user_affiliation - affiliation of user making request

        Returns:
        
            a string holding the isprint output
        """
        
        scriptName = 'isprintService.py'

        # build the complete cgi string, replacing characters as required by cgi standard

        url = self.cgiurl + scriptName + '?'

        
        url += 'file=%s&' % (filename.replace('/', '%2F'))
        parms = parms.replace('+','%2B')
        parms = parms.replace(',','+')
        url += 'parms=%s&' % (parms)
        filters = filters.replace('=','%3D')
        filters = filters.replace(',','%2C')
        filters = filters.replace('/','%2F')
        filters = filters.replace('+','%2B')
        filters = filters.replace(' ','+')
        url += 'filters=%s&' % (filters)
        user_fullname = user_fullname.replace(' ','+').strip()
        url += 'user_fullname=%s&' % (user_fullname)
        user_email = user_email.strip()
        url += 'user_email=%s&' % (user_email)
        user_affiliation = user_affiliation.replace(' ','+').strip()
        url += 'user_affiliation=%s' % (user_affiliation)

        # read main url
        try:
            mainUrl = urllib2.urlopen(url)
        except:
            raise ValueError, 'unable to open url ' + str(url)
                

        page = mainUrl.read()

        mainUrl.close()

        if page.find('Error occurred') != -1:
            raise ValueError, 'error raised using url ' + str(url)

        return page


    def madCalculator(self,
                      year,
                      month,
                      day,
                      hour,
                      min,
                      sec,
                      startLat,
                      endLat,
                      stepLat,
                      startLong,
                      endLong,
                      stepLong,
                      startAlt,
                      endAlt,
                      stepAlt,
                      parms,
                      oneDParmList=[],
                      oneDParmValues=[]):
        """

        Input arguments:

            1. year - int 

            2. month - int 

            3. day - int
            
            4. hour - int 

            5. min - int 

            6. sec - int 

            7. startLat - Starting geodetic latitude, -90 to 90 (float)

            8. endLat - Ending geodetic latitude, -90 to 90 (float)

            9. stepLat - Latitude step (0.1 to 90) (float)

            10. startLong - Starting geodetic longitude, -180 to 180  (float)

            11. endLong - Ending geodetic longitude, -180 to 180 (float)

            12. stepLong - Longitude step (0.1 to 180) (float)

            13. startAlt - Starting geodetic altitude, >= 0 (float)

            14. endAlt - Ending geodetic altitude, > 0 (float)

            15. stepAlt - Altitude step (>= 0.1) (float)

            16. parms - comma delimited string of Madrigal parameters desired

            17. oneDParmList - a list of one-D parameters whose values should
                               be set for the calculation.  Can be codes or mnemonics.
                               Defaults to empty list.

            18. oneDParmValues - a list of values (doubles) associated with the one-D
                                 parameters specified in oneDParmList. Defaults to empty list.

        Returns:

            A list of lists of doubles, where each list contains 3 + number of parameters doubles.
            The first three doubles are the input latitude, longitude, and altitude.  The rest of the
            doubles are the values of each of the calculated values.  If the value cannot be calculated,
            it will be set to nan.

            Example:

                result = testData.madCalculator(1999,2,15,12,30,0,45,55,5,-170,-150,10,200,200,0,'bmag,bn')

                result = [  [45.0, -170.0, 200.0, 4.1315700000000002e-05, 2.1013500000000001e-05]
                            [45.0, -160.0, 200.0, 4.2336899999999998e-05, 2.03685e-05]
                            [45.0, -150.0, 200.0, 4.3856400000000002e-05, 1.97411e-05]
                            [50.0, -170.0, 200.0, 4.3913599999999999e-05, 1.9639999999999998e-05]
                            [50.0, -160.0, 200.0, 4.4890099999999999e-05, 1.8870999999999999e-05]
                            [50.0, -150.0, 200.0, 4.6337800000000002e-05, 1.80077e-05]
                            [55.0, -170.0, 200.0, 4.6397899999999998e-05, 1.78115e-05]
                            [55.0, -160.0, 200.0, 4.7265400000000003e-05, 1.6932500000000001e-05]
                            [55.0, -150.0, 200.0, 4.85495e-05,            1.5865399999999999e-05] ]

                Columns:     gdlat  glon    gdalt  bmag                    bn

	"""

        scriptName = 'madCalculatorService.py'

        url = self.cgiurl + scriptName + '?year'

        if len(oneDParmList) != len(oneDParmValues):
            raise ValueError, 'len(oneDParmList) != len(oneDParmValues)'

        # append arguments
        url += '=%i&month' % (int(year))
        url += '=%i&day' % (int(month))
        url += '=%i&hour' % (int(day))
        url += '=%i&min' % (int(hour))
        url += '=%i&sec' % (int(min))
        url += '=%i&startLat' % (int(sec))
        url += '=%f&endLat' % (float(startLat))
        url += '=%f&stepLat' % (float(endLat))
        url += '=%f&startLong' % (float(stepLat))
        url += '=%f&endLong' % (float(startLong))
        url += '=%f&stepLong' % (float(endLong))
        url += '=%f&startAlt' % (float(stepLong))
        url += '=%f&endAlt' % (float(startAlt))
        url += '=%f&stepAlt' % (float(endAlt))
        url += '=%f&parms' % (float(stepAlt))
        url += '=%s' % (parms)

        for i in range(len(oneDParmList)):
            url += '&oneD=%s,%s' % (str(oneDParmList[i]), str(oneDParmValues[i]))
            
        # remove any pluses in the url due to scientific notation
        url = url.replace('+', '%2B')

        # read main url
        try:
            mainUrl = urllib2.urlopen(url)
        except:
            raise ValueError, 'unable to open url ' + str(url)
                

        page = mainUrl.readlines()

        mainUrl.close()

        # parse the result
        if len(page) == 0:
            raise ValueError, 'No data found at url' + str(url)

        # check that error was not returned
        for line in page:
            if line.find('Error occurred') != -1:
                raise ValueError, 'error raised using url ' + str(url) + ' ' + str(page)

        result = []

        # parse output
        for line in page:
            items = line.split()
            if len(items) < 3:
                # blank line
                continue
            newList = []
            for item in items:
                try:
                    newList.append(float(item))
                except:
                    newList.append(str(item))
            result.append(newList)

        return result
    
    
    def madCalculator2(self,
                      year,
                      month,
                      day,
                      hour,
                      min,
                      sec,
                      latList,
                      lonList,
                      altList,
                      parms,
                      oneDParmList=[],
                      oneDParmValues=[],
                      twoDParmList = [],
                      twoDParmValues = []):
        """
        madCalculator2 is similar to madCalculator, except that a random collection of points in space can be specified,
        rather than a grid of points.  Also, a user can input 2D data.
        
        Added to Madrigal2.6 as web service - will not run on earlier Madrigal installations.

        Input arguments:

            1. year - int 

            2. month - int 

            3. day - int
            
            4. hour - int 

            5. min - int 

            6. sec - int 

            7. latList - a list of geodetic latitudes, -90 to 90

            8. lonList - a list of longitudes, -180 to 180. Length must = lats
            
            9. altList - a list of geodetic altitudes in km. Length must = lats

            10. parms - comma delimited string of Madrigal parameters desired

            11. oneDParmList - a list of one-D parameters whose values should
                               be set for the calculation.  Can be codes or mnemonics.
                               Defaults to empty list.

            12. oneDParmValues - a list of values (doubles) associated with the one-D
                                 parameters specified in oneDParmList. Defaults to empty list.
                                 
            13. twoDParmList - a python list of two-D parameters as mnemonics.  Defaults to [].
            
            14. twoDParmValues - a python list of lists of len = len(twoDParmList). Each individual 
                             list is a list of doubles representing values of the two-D
                             parameter set in twoDParmList, with a length = number 
                             of points (or equal to len(lats)). Defaults to [].

        Returns:

            A list of lists of doubles, where each list contains 3 + number of parameters doubles.
            The first three doubles are the input latitude, longitude, and altitude.  The rest of the
            doubles are the values of each of the calculated values.  If the value cannot be calculated,
            it will be set to nan.

            Example:

                result = testData.madCalculator2(1999,2,15,12,30,0,[45,55],[-170,-150],[200,300],'sdwht,kp')

                result = [ [1999.0, 2.0, 15.0, 12.0, 30.0, 0.0, 3.0, 15.0]
                           [1999.0, 2.0, 15.0, 12.0, 45.0, 0.0, 3.0, 15.0]
                           [1999.0, 2.0, 15.0, 13.0, 0.0, 0.0, 3.0, 15.0]
                           [1999.0, 2.0, 15.0, 13.0, 15.0, 0.0, 3.0, 15.0] ]


                Columns:     gdlat  glon    gdalt  sdwht   kp
                
        Now uses POST to avoid long url issue

    """
    
        # verify Madrigal site can call this command
        if self.compareVersions('2.6', self._madVers) > 0:
            raise IOError, 'madCalculator2 requires Madrigal 2.6 or greater, but this site is version %s' % (self._madVers)

        scriptName = 'madCalculator2Service.py'

        url = self.cgiurl + scriptName
        
        postUrl = 'year'

        # error checking
        if len(oneDParmList) != len(oneDParmValues):
            raise ValueError, 'len(oneDParmList) != len(oneDParmValues)'
        
        if len(latList) == 0:
            raise ValueError, 'length of latList must be at least one'
        
        if len(latList) != len(lonList) or len(latList) != len(altList):
            raise ValueError, 'lengths of latList, lonList, altList must all be equal'
        
        if len(oneDParmList) != len(oneDParmValues):
            raise ValueError, 'len(oneDParmList) != len(oneDParmValues)'
        
        # 
        

        # append arguments
        delimiter = ','
        postUrl += '=%i&month' % (int(year))
        postUrl += '=%i&day' % (int(month))
        postUrl += '=%i&hour' % (int(day))
        postUrl += '=%i&min' % (int(hour))
        postUrl += '=%i&sec' % (int(min))
        postUrl += '=%i&lats=' % (int(sec))
        for i in range(len(latList)):
            postUrl += str(latList[i])
            if i + 1 < len(latList):
                postUrl += ','
        postUrl += '&longs='
        for i in range(len(lonList)):
            postUrl += str(lonList[i])
            if i + 1 < len(lonList):
                postUrl += ','
        postUrl += '&alts='
        for i in range(len(altList)):
            postUrl += str(altList[i])
            if i + 1 < len(altList):
                postUrl += ','
        postUrl += '&parms=%s' % (parms)

        for i in range(len(oneDParmList)):
            postUrl += '&oneD=%s,%s' % (str(oneDParmList[i]), str(oneDParmValues[i]))
            
        for i in range(len(twoDParmList)):
            postUrl += '&twoD=%s,' % (str(twoDParmList[i]))
            for j in range(len(twoDParmValues[i])):
                postUrl += str(twoDParmValues[i][j])
                if j + 1 < len(twoDParmValues[i]):
                    postUrl += ','
            
        # remove any pluses in the postUrl due to scientific notation
        postUrl = postUrl.replace('+', '%2B')

        # read main url
        try:
            req = urllib2.Request(url, postUrl)
            response = urllib2.urlopen(req)
        except:
            raise ValueError, 'unable to open url ' + str(url)
                

        page = response.readlines()

        response.close()

        # parse the result
        if len(page) == 0:
            raise ValueError, 'No data found at url' + str(url)

        # check that error was not returned
        for line in page:
            if line.find('Error occurred') != -1:
                raise ValueError, 'error raised using url ' + str(url) + ' ' + str(page)

        result = []

        # parse output
        for line in page:
            items = line.split()
            if len(items) < 3:
                # blank line
                continue
            newList = []
            for item in items:
                try:
                    newList.append(float(item))
                except:
                    newList.append(str(item))
            result.append(newList)

        return result
    
    
    def madCalculator3(self,
                      yearList,
                      monthList,
                      dayList,
                      hourList,
                      minList,
                      secList,
                      latList,
                      lonList,
                      altList,
                      parms,
                      oneDParmList=[],
                      oneDParmValues=[],
                      twoDParmList = [],
                      twoDParmValues = []):
        """
        madCalculator3 is similar to madCalculator, except that multiple times can be specified,
        where each time can have its own unique spatial positions and 1D and 2D parms. It is
        equivalent to multiple calls to madCalculator2, except that it should greatly improve 
        performance where multiple calls to madCalculator2 are required for different times.
        The only restriction is that the same parameters must be requested for every time.
        
        Added to Madrigal2.6 as web service - will not run on earlier Madrigal installations.
        
        Now uses POST to send arguments, due to large volume of data possible

        Input arguments:

            1. yearList - a list of years, one for each time requested (ints)

            2. monthList - a list of months, one for each time requested. (ints)

            3. dayList - a list of days, one for each time requested. (ints)
            
            4. hourList - a list of hours, one for each time requested. (ints)

            5. minList - a list of minutes, one for each time requested. (ints)

            6. secList - a list of seconds, one for each time requested. (ints)

            7. latList - a list of lists of geodetic latitudes, -90 to 90.  The
               first list is for the first time, the second for the second time, etc.
               The list do not need to have the same number of points.  The number
               of times must match yearList.
               Data organization: latList[timeIndex][positionIndex]

            8. lonList - a list of lists of longitudes, -180 to 180. The
               first list is for the first time, the second for the second time, etc.
               The list do not need to have the same number of points.  The number
               of times must match yearList. Lens must match latList
               Data organization: lonList[timeIndex][positionIndex]
            
            9. altList - a list of lists of geodetic altitudes in km. The
               first list is for the first time, the second for the second time, etc.
               The list do not need to have the same number of points.  The number
               of times must match yearList. Lens must match latList
               Data organization: altList[timeIndex][positionIndex]

            10. parms - comma delimited string of Madrigal parameters desired

            11. oneDParmList - a list of one-D parameters whose values should
                               be set for the calculation.  Can be codes or mnemonics.
                               Defaults to empty list.

            12. oneDParmValues - a list of lists of values (doubles) associated with the one-D
                                 parameters specified in oneDParmList. Defaults to empty list.
                                 The first list is for the first 1D parameter in oneDParmList,
                                 and must be on length len(yearList).  The second list is for 
                                 the second parameter, etc. 
                                 Data organization: onDParmValues[parameterIndex][timeIndex]
                                 
            13. twoDParmList - a python list of of two-D parameters as mnemonics.  Defaults to [].
            
            14. twoDParmValues - a list of lists of lists of values (doubles) associated with the two-D
                                 parameters specified in twoDParmList. Defaults to empty list.
                                 The first list is for the first 2D parameter in oneDParmList,
                                 and must be a list of length len(yearList).  Each list in that
                                 list must be of len(num positions for that time). The second list is for 
                                 the second parameter, etc. 
                                 Data organization: twoDParmValues[parameterIndex][timeIndex][positionIndex]

        Returns:

            A list of lists of doubles, where each list contains 9 + number of parameters doubles.
            The first nine doubles are:
            1) year, 2) month, 3) day, 4) hour, 5) minute, 6) second,
            7) input latitude, 8) longitude, and 9) altitude.  
            The rest of the doubles are the values of each of the calculated values.  If the value 
            cannot be calculated, it will be set to nan.

            Example:

                testData.madCalculator3(yearList=[2001,2001], monthList=[3,3], dayList=[19,20],
                                     hourList=[12,12], minList=[30,40], secList=[20,0],
                                     latList=[[45,46,47,48.5],[46,47,48.2,49,50]],
                                     lonList=[[-70,-71,-72,-73],[-70,-71,-72,-73,-74]],
                                     altList=[[145,200,250,300.5],[200,250,300,350,400]],
                                     parms='bmag,pdcon,ne_model',
                                     oneDParmList=['kinst','elm'],
                                     oneDParmValues=[[31.0,31.0],[45.0,50.0]],
                                     twoDParmList=['ti','te','ne'],
                                     twoDParmValues=[[[1000,1000,1000,1000],[1000,1000,1000,1000,1000]],
                                                     [[1100,1200,1300,1400],[1500,1000,1100,1200,1300]],
                                                     [[1.0e10,1.0e10,1.0e10,1.0e10],[1.0e10,1.0e10,1.0e10,1.0e10,1.0e10]]])


                Columns:     year month day hour minute second gdlat  glon  gdalt  bmag  pdcon  ne_model

    """
        # verify Madrigal site can call this command
        if self.compareVersions('2.6', self._madVers) > 0:
            raise IOError, 'madCalculator3 requires Madrigal 2.6 or greater, but this site is version %s' % (self._madVers)


        scriptName = 'madCalculator3Service.py'

        url = self.cgiurl + scriptName
        
        postUrl = ''

        # error checking
        try:
            totalTimes = len(yearList)
        except:
            raise ValueError, 'yearList mus be a list, not %s' % (str(yearList))
        
        if len(monthList) != totalTimes or \
           len(dayList) != totalTimes or \
           len(hourList) != totalTimes or \
           len(minList) != totalTimes or \
           len(secList) != totalTimes:
            raise ValueError, 'Not all time lists have same length'
        
        # add time arguments
        postUrl += 'year='
        for i, year in enumerate(yearList):
            postUrl += '%i' % (year)
            if i+1 < len(yearList):
                postUrl += ','
                
        postUrl += '&month='
        for i, month in enumerate(monthList):
            postUrl += '%i' % (month)
            if i+1 < len(monthList):
                postUrl += ','
        
        postUrl += '&day='
        for i, day in enumerate(dayList):
            postUrl += '%i' % (day)
            if i+1 < len(dayList):
                postUrl += ','
        
        postUrl += '&hour='
        for i, hour in enumerate(hourList):
            postUrl += '%i' % (hour)
            if i+1 < len(hourList):
                postUrl += ','
                
        postUrl += '&min='
        for i, minute in enumerate(minList):
            postUrl += '%i' % (minute)
            if i+1 < len(minList):
                postUrl += ','
                
        postUrl += '&sec='
        for i, sec in enumerate(secList):
            postUrl += '%i' % (sec)
            if i+1 < len(secList):
                postUrl += ','
                
        # get numPos list from latList
        numPos = []
        for lats in latList:
            numPos.append(len(lats))
            
        postUrl += '&numPos='
        for i, pos in enumerate(numPos):
            postUrl += '%i' % (pos)
            if i+1 < len(numPos):
                postUrl += ','
                
        postUrl += '&lats='
        for i, posList in enumerate(latList):
            if len(posList) != numPos[i]:
                raise ValueError, 'mismatched number of points in latList'
            for j, pos in enumerate(posList):
                postUrl += '%f' % (pos)
                if i+1 < len(latList) or j+1 < len(posList):
                    postUrl += ','
                    
        postUrl += '&longs='
        for i, posList in enumerate(lonList):
            if len(posList) != numPos[i]:
                raise ValueError, 'mismatched number of points in lonList'
            for j, pos in enumerate(posList):
                postUrl += '%f' % (pos)
                if i+1 < len(lonList) or j+1 < len(posList):
                    postUrl += ','
                    
        postUrl += '&alts='
        for i, posList in enumerate(altList):
            if len(posList) != numPos[i]:
                raise ValueError, 'mismatched number of points in altList'
            for j, pos in enumerate(posList):
                postUrl += '%f' % (pos)
                if i+1 < len(altList) or j+1 < len(posList):
                    postUrl += ','
                    
        postUrl += '&parms=%s' % (parms)
                                                                  
        if len(oneDParmList) != len(oneDParmValues):
            raise ValueError, 'len(oneDParmList) != len(oneDParmValues)'

        for i, parm in enumerate(oneDParmList):
            postUrl += '&oneD=%s,' % (str(parm))
            if len(oneDParmValues[i]) != totalTimes:
                raise ValueError, 'wrong number of 1D parms for %s' % (str(parm))
            for j, value in enumerate(oneDParmValues[i]):
                postUrl += '%f' % (value)
                if j+1 < len(oneDParmValues[i]):
                    postUrl += ','
                    
        for i, parm in enumerate(twoDParmList):
            postUrl += '&twoD=%s,' % (str(parm))
            if len(twoDParmValues[i]) != totalTimes:
                raise ValueError, 'wrong number of 2D parms for %s' % (str(parm))
            for j, valueList in enumerate(twoDParmValues[i]):
                if len(valueList) != numPos[j]:
                    raise ValueError, 'wrong number of 2D parms for %s' % (str(parm))
                for k, value in enumerate(valueList):
                    postUrl += '%f' % (value)
                    if j+1 < len(twoDParmValues[i]) or k+1 < len(valueList):
                        postUrl += ','           
            
        # remove any pluses in the postUrl due to scientific notation
        postUrl = postUrl.replace('+', '%2B')

        # read main url
        try:
            req = urllib2.Request(url, postUrl)
            response = urllib2.urlopen(req)
        except:
            raise ValueError, 'unable to open url ' + str(url)
                

        page = response.readlines()

        response.close()

        # parse the result
        if len(page) == 0:
            raise ValueError, 'No data found at url' + str(url)

        # check that error was not returned
        for line in page:
            if line.find('Error occurred') != -1:
                raise ValueError, 'error raised using url ' + str(url) + ' ' + str(page)

        result = []
        
        # time data to add to each line
        year=None
        month=None
        day=None
        hour=None
        minute=None
        second=None
        
        for line in page:
            items = line.split()
            if len(items) < 3:
                # blank line
                continue
            if line.find('TIME') != -1:
                # new time found
                dates=items[1].split('/')
                year = int(dates[2])
                month = int(dates[0])
                day = int(dates[1])
                times=items[2].split(':')
                hour = int(times[0])
                minute = int(times[1])
                second = int(times[2])
                continue
            newList = [year,month,day,hour,minute,second]
            for item in items:
                try:
                    newList.append(float(item))
                except:
                    newList.append(str(item))
            result.append(newList)

        return result


    def madTimeCalculator(self,
                          startyear,
                          startmonth,
                          startday,
                          starthour,
                          startmin,
                          startsec,
                          endyear,
                          endmonth,
                          endday,
                          endhour,
                          endmin,
                          endsec,
                          stephours,
                          parms):
        """

        Input arguments:

            1. startyear - int 

            2. startmonth - int 

            3. startday - int
            
            4. starthour - int 

            5. startmin - int 

            6. startsec - int

            7. endyear - int 

            8. endmonth - int 

            9. endday - int
            
            10. endhour - int 

            11. endmin - int 

            12. endsec - int

            13. stephours - float - number of hours per time step

            16. parms - comma delimited string of Madrigal parameters desired (must not depend on location)

        Returns:

            A list of lists, where each list contains 6 ints (year, month, day, hour, min, sec)  + number
            of parameters.  If the value cannot be calculated, it will be set to nan.

            Example:

                result = testData.madTestCalculator(1999,2,15,12,30,0,
                                                    1999,2,20,12,30,0,
                                                    24.0, 'kp,dst')

                result = [[1999.0, 2.0, 15.0, 12.0, 30.0, 0.0, 3.0, -9.0]
                          [1999.0, 2.0, 16.0, 12.0, 30.0, 0.0, 1.0, -6.0]
                          [1999.0, 2.0, 17.0, 12.0, 30.0, 0.0, 4.0, -31.0]
                          [1999.0, 2.0, 18.0, 12.0, 30.0, 0.0, 6.7000000000000002, -93.0]
                          [1999.0, 2.0, 19.0, 12.0, 30.0, 0.0, 5.2999999999999998, -75.0]]

                Columns:     year, month, day, hour, min, sec, kp, dst

	"""

        scriptName = 'madTimeCalculatorService.py'

        url = self.cgiurl + scriptName + '?startyear'

        # append arguments
        url += '=%i&startmonth' % (int(startyear))
        url += '=%i&startday' % (int(startmonth))
        url += '=%i&starthour' % (int(startday))
        url += '=%i&startmin' % (int(starthour))
        url += '=%i&startsec' % (int(startmin))
        url += '=%i&endyear' % (int(startsec))
        url += '=%i&endmonth' % (int(endyear))
        url += '=%i&endday' % (int(endmonth))
        url += '=%i&endhour' % (int(endday))
        url += '=%i&endmin' % (int(endhour))
        url += '=%i&endsec' % (int(endmin))
        url += '=%i&stephours' % (int(endsec))
        url += '=%f&parms' % (float(stephours))
        url += '=%s' % (parms)

        # read main url
        try:
            mainUrl = urllib2.urlopen(url)
        except:
            raise ValueError, 'unable to open url ' + str(url)
                

        page = mainUrl.readlines()

        mainUrl.close()

        # parse the result
        if len(page) == 0:
            raise ValueError, 'No data found at url' + str(url)

        # check that error was not returned
        for line in page:
            if line.find('Error occurred') != -1:
                raise ValueError, 'error raised using url ' + str(url) + ' ' + str(page)

        result = []

        # parse output
        for line in page:
            items = line.split()
            if len(items) < 3:
                # blank line
                continue
            newList = []
            for item in items:
                try:
                    newList.append(float(item))
                except:
                    newList.append(str(item))
            result.append(newList)

        return result



    def radarToGeodetic(self,
                        slatgd,
                        slon,
                        saltgd,
                        az,
                        el,
                        radarRange):
        """radarToGeodetic converts arrays of az, el, and ranges to geodetic locations.

        Input arguments:

            1. slatgd - radar geodetic latitude 

            2. slon - radar longitude 

            3. saltgd - radar altitude
            
            4. az - either a single azimuth, or a list of azimuths 

            5. el - either a single elevation, or a list of elevations.  If so, len(el)
                    must = len(az)

            6. radarRange - either a single range, or a list of ranges.  If so, len(radarRange)
                            must = len(az)


        Returns:

            A list of lists, where each list contains 3 floats (gdlat, glon, and gdalt)
        """
        scriptName = 'radarToGeodeticService.py'

        url = self.cgiurl + scriptName + '?slatgd'

        # append arguments
        url += '=%f&slon' % (float(slatgd))
        url += '=%f&saltgd' % (float(slon))
        url += '=%f&' % (float(saltgd))

        if type(az) == types.ListType or type(az) == types.TupleType:
            if len(az) != len(el) or len(az) != len(radarRange):
                raise ValueError, 'all lists most have same length'
            for i in range(len(az)):
                if i == 0:
                    arg = str(az[i])
                else:
                    arg += ',' + str(az[i])
            url += 'az=%s&' % (arg)

            for i in range(len(el)):
                if i == 0:
                    arg = str(el[i])
                else:
                    arg += ',' + str(el[i])
            url += 'el=%s&' % (arg)

            for i in range(len(radarRange)):
                if i == 0:
                    arg = str(radarRange[i])
                else:
                    arg += ',' + str(radarRange[i])
            url += 'range=%s' % (arg)

        else:
            url += 'az=%f&' % (az)
            url += 'el=%f&' % (el)
            url += 'range=%f&' % (radarRange)

        # read main url
        try:
            mainUrl = urllib2.urlopen(url)
        except:
            raise ValueError, 'unable to open url ' + str(url)
                
        page = mainUrl.readlines()

        mainUrl.close()

        # parse the result
        if len(page) == 0:
            raise ValueError, 'No data found at url' + str(url)

        # check that error was not returned
        for line in page:
            if line.find('Error occurred') != -1:
                raise ValueError, 'error raised using url ' + str(url) + ' ' + str(page)

        result = []

        # parse output
        for line in page:
            items = line.split(',')
            if len(items) < 3:
                # blank line
                continue
            newList = []
            for item in items:
                try:
                    newList.append(float(item))
                except:
                    newList.append(str(item))
            result.append(newList)

        return result


    def geodeticToRadar(self,
                        slatgd,
                        slon,
                        saltgd,
                        gdlat,
                        glon,
                        gdalt):
        """geodeticToRadar converts arrays of points in space to az, el, and range.

        Input arguments:

            1. slatgd - radar geodetic latitude 

            2. slon - radar longitude 

            3. saltgd - radar altitude
            
            4. gdlat - either a single geodetic latitude, or a list of geodetic latitudes 

            5. glon - either a single longitude, or a list of longitudes.  If so, len(gdlat)
                      must = len(glon)

            6. gdalt - either a single deodetic altitude, or a list of geodetic altitudes.
                       If so, len(gdalt) must = len(gdlat)


        Returns:

            A list of lists, where each list contains 3 floats (az, el, and range)
        """
        scriptName = 'geodeticToRadarService.py'

        url = self.cgiurl + scriptName + '?slatgd'

        # append arguments
        url += '=%f&slon' % (float(slatgd))
        url += '=%f&saltgd' % (float(slon))
        url += '=%f&' % (float(saltgd))

        if type(gdlat) == types.ListType or type(gdlat) == types.TupleType:
            if len(gdlat) != len(glon) or len(gdlat) != len(gdalt):
                raise ValueError, 'all lists most have same length'
            for i in range(len(gdlat)):
                if i == 0:
                    arg = str(gdlat[i])
                else:
                    arg += ',' + str(gdlat[i])
            url += 'gdlat=%s&' % (arg)

            for i in range(len(glon)):
                if i == 0:
                    arg = str(glon[i])
                else:
                    arg += ',' + str(glon[i])
            url += 'glon=%s&' % (arg)

            for i in range(len(gdalt)):
                if i == 0:
                    arg = str(gdalt[i])
                else:
                    arg += ',' + str(gdalt[i])
            url += 'gdalt=%s' % (arg)

        else:
            url += 'gdlat=%f&' % (gdlat)
            url += 'glon=%f&' % (glon)
            url += 'gdalt=%f&' % (gdalt)

        # read main url
        try:
            mainUrl = urllib2.urlopen(url)
        except:
            raise ValueError, 'unable to open url ' + str(url)
                
        page = mainUrl.readlines()

        mainUrl.close()

        # parse the result
        if len(page) == 0:
            raise ValueError, 'No data found at url' + str(url)

        # check that error was not returned
        for line in page:
            if line.find('Error occurred') != -1:
                raise ValueError, 'error raised using url ' + str(url) + ' ' + str(page)

        result = []

        # parse output
        for line in page:
            items = line.split(',')
            if len(items) < 3:
                # blank line
                continue
            newList = []
            for item in items:
                try:
                    newList.append(float(item))
                except:
                    newList.append(str(item))
            result.append(newList)

        return result


    def downloadFile(self, filename, destination, user_fullname, user_email, user_affiliation, 
                     format='simple'):
        """downloadFile will download a Cedar file in the specified format.

        Inputs:

            filename - The absolute filename to as returned via getExperimentFiles.

            destination - where the file is to be stored
            
            user_fullname - full name of user making request

            user_email - email address of user making request

            user_affiliation - affiliation of user making request

            format - file format desired.  May be  'simple', 'hdf5' , 'madrigal', 
                     'blockedBinary', 'ncar',
                     'unblockedBinary', or 'ascii'.  Default is 'simple'
                     Simple is a simple ascii space delimited column format.
                     Simple and hdf5 are recommended since they are standard formats
                     
            hdf5 format works for Madrigal 2.6 or later

        """
        fileType = 0
        if format not in ('hdf5', 'madrigal', 'blockedBinary', 'ncar', 
                          'unblockedBinary', 'ascii', 'simple'):
            raise ValueError, 'Illegal format specified: %s' % (str(format))
        if format == 'blockedBinary':
            fileType = 1
        elif format == 'ncar':
            fileType = 2
        elif format == 'unblockedBinary':
            fileType = 3
        elif format == 'simple':
            fileType = -1
        elif format == 'hdf5':
            # verify Madrigal site can handle this argument
            if self.compareVersions('2.6', self._madVers) > 0:
                raise IOError, 'downloadFile with hdf5 format requires Madrigal 2.6 or greater, but this site is version %s' % (self._madVers)
            fileType = -2
        else:
            fileType = 4



        
        url = os.path.join(self.cgiurl,'getMadfile.cgi?fileName=%s&fileType=%i&' % (filename, fileType))
        user_fullname = user_fullname.replace(' ','+').strip()
        url += 'user_fullname=%s&' % (user_fullname)
        user_email = user_email.strip()
        url += 'user_email=%s&' % (user_email)
        user_affiliation = user_affiliation.replace(' ','+').strip()
        url += 'user_affiliation=%s' % (user_affiliation)

        urlFile = urllib2.urlopen(url)

        data = urlFile.read()

        urlFile.close()

        if format in ('ascii', 'simple'):
            f = open(destination, 'w')
        else:
            f = open(destination, 'wb')

        f.write(data)

        f.close()
        
        
    
    def listFileTimes(self, expDir=None):
        """listFileTimes lists the filenames and last modification times for all files in a Madrigal database.

        Inputs: expDir - experiment directory to which to start.  May be any directory or subdirectory below 
            experiments[0-9]*.  Path may be absolute or relative to experiments[0-9]*.  If None (the default),
            include entire experiments[0-9]* directory(s).  Examples: ('/opt/madrigal/experiments/1998',
            'experiments/2002/gps')
            
        Returns: a list of tuple of 1. filename relative to experiments[0-9]* directory, and 2) datetime in UT of 
            last file modification
            
        Requires:  Madrigal 2.6 or greater
        """
        # verify Madrigal site can call this command
        if self.compareVersions('2.6', self._madVers) > 0:
            raise IOError, 'listFileTimes requires Madrigal 2.6 or greater, but this site is version %s' % (self._madVers)
    
        url = os.path.join(self.cgiurl,'listFileTimesService.py')
        
        if expDir:
            url += '?expDir=%s' % (expDir)

        urlFile = urllib2.urlopen(url)
        
        retList = []

        data = urlFile.read()
        lines = data.split('\n')
        for line in lines:
            items = line.split(',')
            if len(items) != 2:
                continue
            filename = items[0].strip()[1:-1] # strip off quotes
            dt = datetime.datetime.strptime(items[1].strip(), '%Y-%m-%d %H:%M:%S')
            retList.append((filename, dt))
            
        return(retList)
        
        
        
    def traceMagneticField(self, year, month, day, hour, minute,second,
                           inputType, outputType, alts, lats, lons,
                           model, qualifier, stopAlt=None):
        """
        traceMagneticField returns a point along a magnetic field line for each
        point specified by the lists alts, lats, lons.
        Traces to either 1) conjugate point, 2) intersection with a given altitude in the
        northern or southern hemisphere, 3) to the apex, or 4) to GSM XY plane, depending on qualifier
        argument.  Uses Tsyganenko or IGRF fields, depending on model argument.
        Input arguments are either GSM or Geodetic, depending on inputType argument.
        Output arguments are either GSM or Geodetic, depending on outputType
        argument.

        Inputs:
        
            year, month, day, hour, minute, second - time at which to do the trace

            inputType  - 0 for geodetic, 1 for GSM

            outputType - 0 for geodetic, 1 for GSM
        
            The following parameter depend on inputType:
            
            alts - a list of geodetic altitudes or ZGSMs of starting point
        
            lats - a clist of geodetic latitudes or XGSMs of starting point
        
            lons - a list of longitude or YGSM of starting point

            Length of all three lists must be the same
        
            model - 0 for Tsyganenko, 1 for IGRF
        
            qualifier - 0 for conjugate, 1 for north_alt, 2 for south_alt, 3 for apex, 4 for GSM XY plane
        
            stopAlt - altitude in km to stop trace at, if qualifier is north_alt or south_alt.
                If other qualifier, this parameter is not required. Default is None, which will raise
                exception if qualifier is north_alt or south_alt

        Returns a tuple of tuples, one tuple for point in (alts, lats, lons) lists, where each tuple has
        three items:
    
            1. geodetic altitude or ZGSM of ending point
    
            2. geodetic latitude or XGSM of ending point
    
            3. longitude or YGSM of ending point
    
    
        If error, traceback includes error description
        """
        scriptName = 'traceMagneticFieldService.py'

        url = self.cgiurl + scriptName + '?'

        # append arguments
        url += 'year=%i&' % (int(year))
        url += 'month=%i&' % (int(month))
        url += 'day=%i&' % (int(day))
        url += 'hour=%i&' % (int(hour))
        url += 'min=%i&' % (int(minute))
        url += 'sec=%i&' % (int(second))
        url += 'inputType=%i&' % (int(inputType))
        url += 'outputType=%i&' % (int(outputType))
        in1Str = ''
        for alt in alts:
            in1Str += str(alt)
            if alt != alts[-1]:
                in1Str += ','
        url += 'in1=%s&' % (in1Str)
        in2Str = ''
        for lat in lats:
            in2Str += str(lat)
            if lat != lats[-1]:
                in2Str += ','
        url += 'in2=%s&' % (in2Str)
        in3Str = ''
        for lon in lons:
            in3Str += str(lon)
            if lon != lons[-1]:
                in3Str += ','
        url += 'in3=%s&' % (in3Str)
        url += 'model=%i&' % (int(model))
        url += 'qualifier=%i&' % (int(qualifier))
        if stopAlt == None:
            if int(qualifier) in (1,2):
                raise ValueError, 'stopAlt must be set for qualifer in (1,2)'
            else:
                stopAlt = 0.0
        url += 'stopAlt=%s' % (str(stopAlt))

        # read main url
        try:
            mainUrl = urllib2.urlopen(url)
        except:
            raise ValueError, 'unable to open url ' + str(url)

        page = mainUrl.readlines()

        mainUrl.close()

        # parse the result
        if len(page) == 0:
            raise ValueError, 'No data found at url' + str(url)

        # check that html was not returned
        for line in page:
            if line.find('Error occurred') != -1:
                raise ValueError, 'error raised using url ' + str(url) + ' ' + str(page)

        result = []
        
        for line in page:
            items = line.split(',')
            result.append((float(items[0]),
                           float(items[1]),
                           float(items[2])))

        return result
    
    
    def getVersion(self):
        """getVersion gets the version number of Madrigal in form number dot number etc.
        
        Assumes version is 2.5 if no getVersionService.py installed
        """
        scriptName = 'getVersionService.py'

        url = self.cgiurl + scriptName

        # read main url
        try:
            mainUrl = urllib2.urlopen(url)
        except:
            # if this fails, must be 2.5
            return('2.5')

        page = mainUrl.read()

        mainUrl.close()
        
        return(page.strip())
    
    
    def compareVersions(self, ver1, ver2):
        """compareVersions returns -1 if ver1 < ver2, 0 if equal, 1 if ver1 > ver2
        
        Inputs: version number strings, in form number dot number (any number of dots)
        """
        versList1 = ver1.split('.')
        versList2 = ver2.split('.')
        
        index = 0
        while(True):
            if len(versList1) < index + 1 and len(versList2) >= index + 1:
                return(-1)
            elif len(versList1) >= index + 1 and len(versList2) < index + 1:
                return(1)
            elif len(versList1) < index + 1 and len(versList2) < index + 1:
                return(0)
            verNum1 = int(versList1[index])
            verNum2 = int(versList2[index])
            result = cmp(verNum1, verNum2)
            if result:
                return(result)
            index += 1
            

        
    

class MadrigalInstrument:
    """MadrigalInstrument is a class that encapsulates information about a Madrigal Instrument.


    Attributes::

      name (string) Example: 'Millstone Hill Incoherent Scatter Radar'
      
      code (int) Example: 30
      
      mnemonic (3 char string) Example: 'mlh'
      
      latitude (double) Example: 45.0
      
      longitude (double) Example: 110.0
      
      altitude (double)  Example: 0.015 (km)
      
      category (string) Example 'Incoherent Scatter Radars'
            


    Non-standard Python modules used: None


    Change history:

    Written by "Bill Rideout":mailto:wrideout@haystack.mit.edu  Feb. 10, 2004

    """
    def __init__(self, name, code, mnemonic, latitude, longitude, altitude, category='unknown'):
        """__init__ initializes a MadrigalInstrument.

        Inputs::

            name - (string) Example: 'Millstone Hill Incoherent Scatter Radar'
          
            code - (int, or string that can be converted) Example: 30
          
            mnemonic - (3 char string) Example: 'mlh'
          
            latitude - (double, or string that can be converted) Example: 45.0
          
            longitude (double, or string that can be converted) Example: 110.0
          
            altitude (double, or string that can be converted)  Example: 0.015 (km)
            
            category  (string) Example: 'Incoherent Scatter Radars'
        
        Returns: void

        Affects: Initializes all the class member variables.

        Exceptions: If illegal argument passed in.
        """

        if type(name) != types.StringType:
            raise ValueError, 'In MadrigalInstrument, name not string type: %s' % (str(name))

        self.name = name

        self.code = int(code)

        if type(mnemonic) != types.StringType:
            raise ValueError, 'In MadrigalInstrument, mnemonic not string type: %s' % (str(mnemonic))

        if len(mnemonic) != 3:
            raise ValueError, 'In MadrigalInstrument, mnemonic not three characters: %s' % (str(mnemonic))

        self.mnemonic = mnemonic.lower()

        self.latitude = float(latitude)

        self.longitude = float(longitude)

        self.altitude = float(altitude)
        
        self.category = str(category)
        

    def __str__(self):
        """return a readible form of this object"""
        retStr = ''
        retStr += 'name: %s\n' % (str(self.name))
        retStr += 'code: %s\n' % (str(self.code))
        retStr += 'mnemonic: %s\n' % (str(self.mnemonic))
        retStr += 'latitude: %s\n' % (str(self.latitude))
        retStr += 'longitude: %s\n' % (str(self.longitude))
        retStr += 'altitude: %s\n'%  (str(self.altitude))
        retStr += 'category: %s\n'%  (str(self.category))
        return retStr



class MadrigalExperiment:
    """MadrigalExperiment is a class that encapsulates information about a Madrigal Experiment.


    Attributes::

        id (int) Example: 10000111.  Uniquely identifies experiment.
        
        realUrl (string) the real url to display this experiment in a web browser.
        
        url (string) Example: 'http://madrigal.haystack.mit.edu/cgi-bin/madtoc/1997/mlh/03dec97'
            Note: this is a an old url that no longer works, but it is the form stored in the metadata
        
        name (string) Example: 'Wide Latitude Substorm Study'
        
        siteid (int) Example: 1
        
        sitename (string) Example: 'Millstone Hill Observatory'
        
        instcode (int) Code of instrument. Example: 30
        
        instname (string) Instrument name. Example: 'Millstone Hill Incoherent Scatter Radar'
        
        startyear - int
           
        startmonth - int
       
        startday - int
       
        starthour - int
       
        startmin - int
       
        startsec - int
       
        endyear - int
       
        endmonth - int
       
        endday - int
       
        endhour - int
       
        endmin - int
       
        endsec - int

        isLocal - True if a local experiment, False if not

        madrigalUrl - url of Madrigal site.  Used if not a local experiment.
        
        pi - experiment Principal investigator
        
        piEmail - experiment Principal investigator's email
            

    Non-standard Python modules used: None


    Change history:

    Written by "Bill Rideout":mailto:wrideout@haystack.mit.edu  Feb. 10, 2004

    """
    def __init__(self,
                 id,
                 url,
                 name,
                 siteid,
                 sitename,
                 instcode,
                 instname,
                 startyear,
                 startmonth,
                 startday,
                 starthour,
                 startmin,
                 startsec,
                 endyear,
                 endmonth,
                 endday,
                 endhour,
                 endmin,
                 endsec,
                 isLocal,
                 madrigalUrl,
                 pi,
                 piEmail):
        """__init__ initializes a MadrigalExperiment.

        Inputs::

            id (int, or string that can be converted) Example: 10000111.  Uniquely identifies experiment.
        
            url (string) Example: 'http://madrigal.haystack.mit.edu/cgi-bin/madtoc/1997/mlh/03dec97'
            
            name (string) Example: 'Wide Latitude Substorm Study'
            
            siteid (int, or string that can be converted) Example: 1
            
            sitename (string) Example: 'Millstone Hill Observatory'
            
            instcode (int, or string that can be converted) Code of instrument. Example: 30
            
            instname (string) Instrument name. Example: 'Millstone Hill Incoherent Scatter Radar'

            startyear - int, or string that can be converted
           
            startmonth - int, or string that can be converted
       
            startday - int, or string that can be converted
       
            starthour - int, or string that can be converted
       
            startmin - int, or string that can be converted
       
            startsec - int, or string that can be converted
       
            endyear - int, or string that can be converted
       
            endmonth - int, or string that can be converted
       
            endday - int, or string that can be converted
       
            endhour - int, or string that can be converted
       
            endmin - int, or string that can be converted
       
            endsec - int, or string that can be converted
            
            isLocal - True if a local experiment, False if not

            madrigalUrl - url of Madrigal site.  Used if not a local experiment.
            
            pi - experiment PI
            
            piEmail - experiment PI email
        
        Returns: void

        Affects: Initializes all the class member variables.

        Exceptions: If illegal argument passed in.
        """

        self.id = int(id)

        if type(url) != types.StringType:
            raise ValueError, 'In MadrigalExperiment, url not string type: %s' % (str(url))

        self.url = url

        if type(name) != types.StringType:
            raise ValueError, 'In MadrigalExperiment, name not string type: %s' % (str(name))

        self.name = name

        self.siteid = int(siteid)

        if type(sitename) != types.StringType:
            raise ValueError, 'In MadrigalExperiment, sitename not string type: %s' % (str(sitename))

        self.sitename = sitename

        self.instcode = int(instcode)

        if type(instname) != types.StringType:
            raise ValueError, 'In MadrigalExperiment, instname not string type: %s' % (str(instname))

        self.instname = instname

        self.startyear = int(startyear)

        self.startmonth = int(startmonth)

        self.startday = int(startday)

        self.starthour = int(starthour)

        self.startmin = int(startmin)

        self.startsec = int(startsec)

        self.endyear = int(endyear)

        self.endmonth = int(endmonth)

        self.endday = int(endday)

        self.endhour = int(endhour)

        self.endmin = int(endmin)

        self.endsec = int(endsec)

        if isLocal not in (True, False):
            raise ValueError, 'In MadrigalExperiment, isLocal not boolean: %s' % (str(isLocal))

        self.isLocal = isLocal

        if type(madrigalUrl) != types.StringType:
            raise ValueError, 'In MadrigalExperiment, madrigalUrl not string type: %s' % (str(madrigalUrl))

        self.madrigalUrl = madrigalUrl
        
        self.pi = str(pi)
        
        self.piEmail = str(piEmail)
        
        self.realUrl = self._getRealExperimentUrl()
        
        
        
    def _getRealExperimentUrl(self):
        """getRealExperimentUrl is a private method that returns the url used in a web browser to see 
        this experiment's page in full data access interface. Uses to create attribute realUrl
        """
        retStr = ''
        index = self.url.find('/madtoc/')
        retStr += self.url[:index] + '/madExperiment.cgi?exp='
        retStr += self.url[index+8:] + '&displayLevel=0&expTitle='
        retStr += urllib.quote_plus(self.name)
        return(retStr)
        

    def __str__(self):
        """return a readible form of this object"""
        retStr = ''
        retStr += 'id: %s\n' % (str(self.id))
        retStr += 'realUrl: %s\n' % (str(self.realUrl))
        retStr += 'url: %s\n' % (str(self.url))
        retStr += 'name: %s\n' % (str(self.name))
        retStr += 'siteid: %s\n' % (str(self.siteid))
        retStr += 'sitename: %s\n' % (str(self.sitename))
        retStr += 'instcode: %s\n'%  (str(self.instcode))
        retStr += 'instname: %s\n' % (str(self.instname))
        retStr += 'startyear: %s\n' % (str(self.startyear))
        retStr += 'startmonth: %s\n'%  (str(self.startmonth))
        retStr += 'startday: %s\n' % (str(self.startday))
        retStr += 'starthour: %s\n'%  (str(self.starthour))
        retStr += 'startmin: %s\n' % (str(self.startmin))
        retStr += 'startsec: %s\n'%  (str(self.startsec))
        retStr += 'endyear: %s\n' % (str(self.endyear))
        retStr += 'endmonth: %s\n'%  (str(self.endmonth))
        retStr += 'endday: %s\n' % (str(self.endday))
        retStr += 'endhour: %s\n'%  (str(self.endhour))
        retStr += 'endmin: %s\n' % (str(self.endmin))
        retStr += 'endsec: %s\n'%  (str(self.endsec))
        retStr += 'isLocal: %s\n' % (str(self.isLocal))
        retStr += 'madrigalUrl: %s\n'%  (str(self.madrigalUrl))
        retStr += 'PI: %s\n'%  (str(self.pi))
        retStr += 'PIEmail: %s\n'%  (str(self.piEmail))
        return retStr

    def __cmp__(self, other):
        """ __cmp__ compares two MadrigalExperiment objects.

        Compared by start time, then by end time.
        """
        dt1 = datetime.datetime(self.startyear, self.startmonth, self.startday,
                                self.starthour, self.startmin, self.startsec)
        dt2 = datetime.datetime(other.startyear, other.startmonth, other.startday,
                                other.starthour, other.startmin, other.startsec)
        result = cmp(dt1, dt2)
        if result != 0:
            return(result)

        
        dt1 = datetime.datetime(self.endyear, self.endmonth, self.endday,
                                self.endhour, self.endmin, self.endsec)
        dt2 = datetime.datetime(other.endyear, other.endmonth, other.endday,
                                other.endhour, other.endmin, other.endsec)
        return(cmp(dt1, dt2))                       
        
        


class MadrigalExperimentFile:
    """MadrigalExperimentFile is a class that encapsulates information about a Madrigal ExperimentFile.


    Attributes::

        name (string) Example '/opt/mdarigal/blah/mlh980120g.001'
        
        kindat (int) Kindat code.  Example: 3001
        
        kindatdesc (string) Kindat description: Example 'Basic Derived Parameters'
        
        category (int) (1=default, 2=variant, 3=history, 4=real-time)
        
        status (string)('preliminary', 'final', or any other description)
        
        permission (int)  0 for public, 1 for private

        expId - experiment id of the experiment this MadrigalExperimentFile belongs in
            

    Non-standard Python modules used: None


    Change history:

    Written by "Bill Rideout":mailto:wrideout@haystack.mit.edu  Feb. 10, 2004

    """
    def __init__(self, name, kindat, kindatdesc, category, status, permission, expId = None):
        """__init__ initializes a MadrigalExperimentFile.

        Inputs::

            name - (string) Example '/opt/mdarigal/blah/mlh980120g.001'
        
            kindat - (int, or string that can be converted) Kindat code.  Example: 3001
        
            kindatdesc - (string) Kindat description: Example 'Basic Derived Parameters'
        
            category - (int, or string that can be converted) (1=default, 2=variant, 3=history, 4=real-time)
        
            status - (string)('preliminary', 'final', or any other description)
        
            permission - (int, or string that can be converted)  0 for public, 1 for private

            expId - experiment id of the experiment this MadrigalExperimentFile belongs in

        
        Returns: void

        Affects: Initializes all the class member variables.

        Exceptions: If illegal argument passed in.
        """

        if type(name) != types.StringType:
            raise ValueError, 'In MadrigalExperimentFile, name not string type: %s' % (str(name))

        self.name = name

        self.kindat = int(kindat)

        if type(kindatdesc) != types.StringType:
            raise ValueError, 'In MadrigalExperimentFile, kindatdesc not string type: %s' % (str(kindatdesc))

        self.kindatdesc = kindatdesc

        self.category = int(category)

        if type(status) != types.StringType:
            raise ValueError, 'In MadrigalExperimentFile, status not string type: %s' % (str(status))

        self.status = status

        self.permission = int(permission)

        if expId == None:
            self.expId = None
        else:
            self.expId = int(expId)
            
        

    def __str__(self):
        """return a readible form of this object"""
        retStr = ''
        retStr += 'name: %s\n' % (str(self.name))
        retStr += 'kindat: %s\n' % (str(self.kindat))
        retStr += 'kindatdesc: %s\n' % (str(self.kindatdesc))
        retStr += 'category: %s\n' % (str(self.category))
        retStr += 'status: %s\n' % (str(self.status))
        retStr += 'permission: %s\n'%  (str(self.permission))
        retStr += 'expId: %s\n'%  (str(self.expId))
        return retStr


class MadrigalParameter:
    """MadrigalParameter is a class that encapsulates information about a Madrigal Parameter.


    Attributes::

        mnemonic (string) Example 'dti'

        description (string) Example: "F10.7 Multiday average observed (Ott)"

        isError (int) 1 if error parameter, 0 if not

        units (string) Example "W/m2/Hz"

        isMeasured (int) 1 if measured, 0 if derivable

        category (string) Example: "Time Related Parameter"

        isSure (int) - 1 if parameter can be found for every record, 0 if can only be found for some

        isAddIncrement - 1 if additional increment, 0 if normal, -1 if unknown (this capability
                         only added with Madrigal 2.5)


    Non-standard Python modules used: None


    Change history:

    Written by "Bill Rideout":mailto:wrideout@haystack.mit.edu  Aug. 8, 2005

    """
    def __init__(self, mnemonic, description, isError, units, isMeasured, category, isSure, isAddIncrement):
        """__init__ initializes a MadrigalParameter.

        Inputs::

            mnemonic (string) Example 'dti'

            description (string) Example: "F10.7 Multiday average observed (Ott)"

            isError (int) 1 if error parameter, 0 if not

            units (string) Example "W/m2/Hz"

            isMeasured (int) 1 if measured, 0 if derivable

            category (string) Example: "Time Related Parameter"

            isSure (int) - 1 if parameter can be found for every record, 0 if can only be found for some

            isAddIncrement - 1 if additional increment, 0 if normal, -1 if unknown (this capability
                             only added with Madrigal 2.5)
 

        Returns: void

        Affects: Initializes all the class member variables.

        Exceptions: If illegal argument passed in.
        """

        if type(mnemonic) != types.StringType:
            raise ValueError, 'In MadrigalParameter, mnemonic not string type: %s' % (str(mnemonic))

        self.mnemonic = mnemonic

        if type(description) != types.StringType:
            raise ValueError, 'In MadrigalParameter, description not string type: %s' % (str(description))

        self.description = description

        self.isError = int(isError)

        if type(units) != types.StringType:
            raise ValueError, 'In MadrigalParameter, units not string type: %s' % (str(units))

        self.units = units

        self.isMeasured = int(isMeasured)

        if type(category) != types.StringType:
            raise ValueError, 'In MadrigalParameter, category not string type: %s' % (str(category))

        self.category = category
            
        self.isSure = int(isSure)

        self.isAddIncrement = int(isAddIncrement)
        

    def __str__(self):
        """return a readible form of this object"""
        retStr = ''
        retStr += 'mnemonic: %s\n' % (str(self.mnemonic))
        retStr += 'description: %s\n' % (str(self.description))
        retStr += 'isError: %s\n' % (str(self.isError))
        retStr += 'units: %s\n' % (str(self.units))
        retStr += 'isMeasured: %s\n' % (str(self.isMeasured))
        retStr += 'category: %s\n'%  (str(self.category))
        retStr += 'isSure: %s\n'%  (str(self.isSure))
        retStr += 'isAddIncrement: %s\n'%  (str(self.isAddIncrement))
        return retStr     



if __name__ == '__main__':

    testInst  = MadrigalInstrument("Millstone Hill AMISR Radar", '33', 'Mlh', 45.0, 110.0, '0.015')
    print testInst

    
    testExp  = MadrigalExperiment('10000111',
                                  'http://madrigal.haystack.mit.edu/cgi-bin/madtoc/1997/mlh/03dec97',
                                  "World day",
                                  '33',
                                  'Westford',
                                  30,
                                  'SuperDarn',
                                  1993,1,2,3,4,5,
                                  '1993','1','2','3','4','5',
                                  True,
                                  'http://madrigal.haystack.mit.edu/madrigal')
    print testExp


    testExpFile  = MadrigalExperimentFile("/opt/madrigal/blah/mlh980120g.001", '33', 'Blah blah', '2', 'final', '0')
    print testExpFile

    testData = MadrigalData('http://grail/madrigal/')

    # save a file
    testData.downloadFile('/home/grail/brideout/madroot/experiments/1998/mlh/20jan98/mil980120g.001',
                          '/tmp/junk.001')

    instList = testData.getAllInstruments()

    for inst in instList:
        print inst

    expList = testData.getExperiments(20, 1960,1,1,0,0,0,2005,1,1,0,0,0)

    for exp in expList:
        print exp

    fileList = testData.getExperimentFiles(expList[0].id)

    for file in fileList:
        print file

    print 'Parameter list for %s' % (file.name)
    parmList = testData.getExperimentFileParameters(file.name)
    for parm in parmList:
        print str(parm) + '\n'

    testData.simplePrint('/home/grail/brideout/madroot/experiments/1998/mlh/20jan98/mlh980120g.001',
                               'Bill Rideout', 'brideout@haystack.mit.edu', 'MIT Haystack')

    print testData.isprint('/home/grail/brideout/madroot/experiments/1998/mlh/20jan98/mlh980120g.001',
                           'gdalt,ti', 'filter=gdalt,500,600 filter=ti,1000,2000','Bill Rideout',
                           'brideout@haystack.mit.edu', 'MIT Haystack')

    result = testData.madCalculator(1999,2,15,12,30,0,45,55,5,-170,-150,10,200,200,0,'bmag,bn')

    for line in result:
        print line

    result = testData.madTimeCalculator(1999,2,15,12,30,0,
                                        1999,2,20,12,30,0,
                                        24.0, 'kp,dst')

    for line in result:
        print line

    print 'test of radarToGeodetic with arg 42,-70,0.1,(0,90),(45,45),(1000,1000):'
    result = testData.radarToGeodetic(42,-70,0.1,(0,90),(45,45),(1000,1000))
    print result

    print 'test of radarToGeodetic with arg 42,-70,0.1,90, 45, 1000:'
    result = testData.radarToGeodetic(42,-70,0.1,90,45,1000)
    print result

    print 'test of geodeticToRadar with arg 42,-70,0.1,(50,60),(-70,-70),(1000,1000):'
    result = testData.geodeticToRadar(42,-70,0.1,(50,60),(-70,-70),(1000,1000))
    print result

    print 'test of geodeticToRadar with arg 42,-70,0.1,50, -70, 1000:'
    result = testData.geodeticToRadar(42,-70,0.1,50,-70,1000)
    print result

    
    print('test of traceMagneticField with args 1999,2,15,12,30,0,0,0,[300], [42], [-71],1,1,200')
    result = testData.traceMagneticField(1999,2,15,12,30,0,0,0,[300], [42], [-71],1,1,200)
    print(result)

