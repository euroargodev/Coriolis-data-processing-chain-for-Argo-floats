% ------------------------------------------------------------------------------
% Compare JULD and JULD_LOCATION between 2 sets of NetCDF mono-profile files.
%
% SYNTAX :
%   nc_compare_profile_date_and_loc or nc_compare_profile_date_and_loc(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/18/2017 - RNU - creation
% ------------------------------------------------------------------------------
function nc_compare_profile_date_and_loc(varargin)

% top directory of NetCDF mono-profile files (set #1)
DIR_INPUT_SET1_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo_apx_ir_20170918\';

% top directory of NetCDF mono-profile files (set #2)
DIR_INPUT_SET2_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\Apx_Ir_rudics_&_Navis_EDAC_20170918\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% default list of floats to compare
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_ir_rudics_all.txt';

% default values
global g_dateDef;
global g_janFirst1950InMatlab;
g_dateDef = 99999.99999999;
g_janFirst1950InMatlab = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');

% Matlab date to julian day shift
SHIFT_DATE = 712224;

% input parameters management
if (nargin == 0)
   % floats to process come from FLOAT_LIST_FILE_NAME
   floatListFileName = FLOAT_LIST_FILE_NAME;
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
      return
   end
   
   fprintf('Floats from list: %s\n', floatListFileName);
   floatList = load(floatListFileName);
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file recording
if (nargin == 0)
   [pathstr, name, ext] = fileparts(floatListFileName);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

logFile = [DIR_LOG_CSV_FILE '/' 'nc_compare_profile_date_and_loc' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

fprintf('PARAMETERS:\n');
fprintf('   SET1 input directory: %s\n', DIR_INPUT_SET1_NC_FILES);
fprintf('   SET2 input directory: %s\n', DIR_INPUT_SET2_NC_FILES);
fprintf('   Log/csv output directory: %s\n', DIR_LOG_CSV_FILE);
if (nargin == 0)
   fprintf('   List of floats to process: %s\n', FLOAT_LIST_FILE_NAME);
else
   fprintf('   Floats to process:');
   fprintf(' %d', floatList);
   fprintf('\n');
end
fprintf('\n');

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_compare_profile_date_and_loc' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = 'Line; WMO; Dir; CyNum; DateDiffer; DateLocDiffer; Date1 (new); DateLoc1; Date2 (EDAC); DateLoc2; Date1-Date2; DateLoc1-DateLoc2';
fprintf(fidOut, '%s\n', header);

% process the floats
lineNum = 1;
nbFloats = length(floatList);
for idFloat = 1:nbFloats

   floatNum = floatList(idFloat);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   
   % retrieve profile dates and numbers of both sets
   [descProfNumSet1, descProfDateSet1, descProfLocDateSet1, ...
      ascProfNumSet1, ascProfDateSet1, ascProfLocDateSet1] = ...
      get_nc_profile_dates(DIR_INPUT_SET1_NC_FILES, floatNum, 'Set1');
   
   [descProfNumSet2, descProfDateSet2, descProfLocDateSet2, ...
      ascProfNumSet2, ascProfDateSet2, ascProfLocDateSet2] = ...
      get_nc_profile_dates(DIR_INPUT_SET2_NC_FILES, floatNum, 'SET2');
   
   % compute anew the dates for comparisons
   idNoDef = find(descProfDateSet1 ~= g_dateDef);
   if (~isempty(idNoDef))
      descProfDateSet1(idNoDef) = datenum(datestr(descProfDateSet1(idNoDef)+SHIFT_DATE, 0), 'dd-mmm-yyyy HH:MM:SS')-SHIFT_DATE;
   end
   idNoDef = find(descProfDateSet2 ~= g_dateDef);
   if (~isempty(idNoDef))
      descProfDateSet2(idNoDef) = datenum(datestr(descProfDateSet2(idNoDef)+SHIFT_DATE, 0), 'dd-mmm-yyyy HH:MM:SS')-SHIFT_DATE;
   end
   idNoDef = find(ascProfDateSet1 ~= g_dateDef);
   if (~isempty(idNoDef))
      ascProfDateSet1(idNoDef) = datenum(datestr(ascProfDateSet1(idNoDef)+SHIFT_DATE, 0), 'dd-mmm-yyyy HH:MM:SS')-SHIFT_DATE;
   end
   idNoDef = find(ascProfDateSet2 ~= g_dateDef);
   if (~isempty(idNoDef))
      ascProfDateSet2(idNoDef) = datenum(datestr(ascProfDateSet2(idNoDef)+SHIFT_DATE, 0), 'dd-mmm-yyyy HH:MM:SS')-SHIFT_DATE;
   end

   descProfNum = unique([descProfNumSet1; descProfNumSet2]);
   for idCy = 1:length(descProfNum)
      
      idF1 = find(descProfNumSet1 == descProfNum(idCy));
      idF2 = find(descProfNumSet2 == descProfNum(idCy));
      
      if (~isempty(idF1) && ~isempty(idF2))
         fprintf(fidOut, '%d; %d; D; %d; %d; %d; %s; %s; %s; %s; %s; %s\n', ...
            lineNum, floatNum, descProfNum(idCy), ...
            ~(descProfDateSet1(idF1) == descProfDateSet2(idF2)), ...
            ~(descProfLocDateSet1(idF1) == descProfLocDateSet2(idF2)), ...
            julian_2_gregorian(descProfDateSet1(idF1)), ...
            julian_2_gregorian(descProfLocDateSet1(idF1)), ...
            julian_2_gregorian(descProfDateSet2(idF2)), ...
            julian_2_gregorian(descProfLocDateSet2(idF2)), ...
            format_time_dec_argo((descProfDateSet1(idF1)-descProfDateSet2(idF2))*24), ...
            format_time_dec_argo((descProfLocDateSet1(idF1)-descProfLocDateSet2(idF2))*24));
      elseif (~isempty(idF1))
         fprintf(fidOut, '%d; %d; D; %d; %d; %d; %s; %s\n', ...
            lineNum, floatNum, descProfNum(idCy), ...
            -1, ...
            -1, ...
            julian_2_gregorian(descProfDateSet1(idF1)), ...
            julian_2_gregorian(descProfLocDateSet1(idF1)));
         lineNum = lineNum + 1;
      else
         fprintf(fidOut, '%d; %d; D; %d; %d; %d; ; ; %s; %s\n', ...
            lineNum, floatNum, descProfNum(idCy), ...
            -1, ...
            -1, ...
            julian_2_gregorian(descProfDateSet2(idF2)), ...
            julian_2_gregorian(descProfLocDateSet2(idF2)));
      end
      lineNum = lineNum + 1;
   end
   
   ascProfNum = unique([ascProfNumSet1; ascProfNumSet2]);
   for idCy = 1:length(ascProfNum)
      
      idF1 = find(ascProfNumSet1 == ascProfNum(idCy));
      idF2 = find(ascProfNumSet2 == ascProfNum(idCy));
      
      if (~isempty(idF1) && ~isempty(idF2))
         fprintf(fidOut, '%d; %d; A; %d; %d; %d; %s; %s; %s; %s; %s; %s\n', ...
            lineNum, floatNum, ascProfNum(idCy), ...
            ~(ascProfDateSet1(idF1) == ascProfDateSet2(idF2)), ...
            ~(ascProfLocDateSet1(idF1) == ascProfLocDateSet2(idF2)), ...
            julian_2_gregorian(ascProfDateSet1(idF1)), ...
            julian_2_gregorian(ascProfLocDateSet1(idF1)), ...
            julian_2_gregorian(ascProfDateSet2(idF2)), ...
            julian_2_gregorian(ascProfLocDateSet2(idF2)), ...
            format_time_dec_argo((ascProfDateSet1(idF1)-ascProfDateSet2(idF2))*24), ...
            format_time_dec_argo((ascProfLocDateSet1(idF1)-ascProfLocDateSet2(idF2))*24));
      elseif (~isempty(idF1))
         fprintf(fidOut, '%d; %d; A; %d; %d; %d; %s; %s\n', ...
            lineNum, floatNum, ascProfNum(idCy), ...
            -1, ...
            -1, ...
            julian_2_gregorian(ascProfDateSet1(idF1)), ...
            julian_2_gregorian(ascProfLocDateSet1(idF1)));
         lineNum = lineNum + 1;
      else
         fprintf(fidOut, '%d; %d; A; %d; %d; %d; ; ; %s; %s\n', ...
            lineNum, floatNum, ascProfNum(idCy), ...
            -1, ...
            -1, ...
            julian_2_gregorian(ascProfDateSet2(idF2)), ...
            julian_2_gregorian(ascProfLocDateSet2(idF2)));
      end
      lineNum = lineNum + 1;
   end
   
   fprintf(fidOut, '%d; %d\n', ...
      lineNum, floatNum);
   lineNum = lineNum + 1;

end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Retrieve information on profile dates of a mono-profile NetCDF file.
%
% SYNTAX :
%  [o_descProfNum, o_descProfDate, o_descProfLocDate, ...
%    o_ascProfNum, o_ascProfDate, o_ascProfLocDate] = ...
%    get_nc_profile_dates(a_ncDirName, a_floatNum, a_commentStr)
%
% INPUT PARAMETERS :
%   a_ncDirName  : NetCDF top directory
%   a_floatNum   : float WMO number
%   a_commentStr : additional information (for comment only)
%
% OUTPUT PARAMETERS :
%   o_descProfNum     : descent profile numbers
%   o_descProfDate    : descent profile dates
%   o_descProfLocDate : descent profile location dates
%   o_ascProfNum      : ascent profile numbers
%   o_ascProfDate     : ascent profile dates
%   o_ascProfLocDate  : ascent profile location dates
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/26/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_descProfNum, o_descProfDate, o_descProfLocDate, ...
   o_ascProfNum, o_ascProfDate, o_ascProfLocDate] = ...
   get_nc_profile_dates(a_ncDirName, a_floatNum, a_commentStr)

% output parameters initialization
o_descProfNum = [];
o_descProfDate = [];
o_descProfLocDate = [];
o_ascProfNum = [];
o_ascProfDate = [];
o_ascProfLocDate = [];

% default values
global g_dateDef;


% extract profile dates in mono-profile NetCDF files
profNum = [];
profDir = [];
profDate = [];
profLocDate = [];
monoProfDirName = [a_ncDirName sprintf('/%d/profiles/', a_floatNum)];
monoProfFileName = [monoProfDirName sprintf('*%d_*.nc', a_floatNum)];
monoProfFiles = dir(monoProfFileName);
for idFile = 1:length(monoProfFiles)
    
   fileName = monoProfFiles(idFile).name;
   % do not consider b file (if exists)
   if (fileName(1) == 'B')
      continue
   end
   profFileName = [monoProfDirName fileName];

   if (exist(profFileName, 'file') == 2)
            
      % open NetCDF file
      fCdf = netcdf.open(profFileName, 'NC_NOWRITE');
      if (isempty(fCdf))
         fprintf('ERROR: Unable to open NetCDF input file: %s\n', profFileName);
         return
      end

      % retrieve information
      if (var_is_present(fCdf, 'CYCLE_NUMBER') && ...
            var_is_present(fCdf, 'DIRECTION') && ...
            var_is_present(fCdf, 'JULD') && ...
            var_is_present(fCdf, 'JULD_LOCATION') && ...
            var_is_present(fCdf, 'DATA_MODE'))
         
         cycleNumber = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'CYCLE_NUMBER'));
         direction = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DIRECTION'));
         
         julD = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD'));
         julDFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'JULD'), '_FillValue');
         julD(find(julD == julDFillVal)) = g_dateDef;
         
         julDLocation = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_LOCATION'));
         julDLocationFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'JULD_LOCATION'), '_FillValue');
         julDLocation(find(julDLocation == julDLocationFillVal)) = g_dateDef;
         
         dataMode = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_MODE'));
         
         netcdf.close(fCdf);
         
         idDel = find(dataMode == ' ');
         cycleNumber(idDel) = [];
         direction(idDel) = [];
         julD(idDel) = [];
         julDLocation(idDel) = [];
         
         [uJulD, idA, idC] = unique(julD);
         if (length(uJulD) > 1)
            fprintf('WARNING: %d profiles in the %s NetCDF input file: %s - only the first one is considered\n', ...
               length(uJulD), a_commentStr, profFileName);
         end
                    
         profNum = [profNum; cycleNumber(1)];
         profDir = [profDir direction(1)];
         profDate = [profDate; julD(1)];
         profLocDate = [profLocDate; julDLocation(1)];
         
      else
         if (~var_is_present(fCdf, 'CYCLE_NUMBER'))
            fprintf('WARNING: Variable CYCLE_NUMBER not present in %s file : %s\n', ...
               a_commentStr, profFileName);
         end
         if (~var_is_present(fCdf, 'DIRECTION'))
            fprintf('WARNING: Variable DIRECTION not present in %s file : %s\n', ...
               a_commentStr, profFileName);
         end
         if (~var_is_present(fCdf, 'JULD'))
            fprintf('WARNING: Variable JULD not present in %s file : %s\n', ...
               a_commentStr, profFileName);
         end
         if (~var_is_present(fCdf, 'JULD_LOCATION'))
            fprintf('WARNING: Variable JULD_LOCATION not present in %s file : %s\n', ...
               a_commentStr, profFileName);
         end
         netcdf.close(fCdf);
         continue
      end
   end
end

if (isempty(monoProfFiles))
   fprintf('WARNING: no mono-profile %s file for float #%d\n', ...
      a_commentStr, a_floatNum);
end

% output parameters
idDesc = find(profDir == 'D');
o_descProfNum = profNum(idDesc);
o_descProfDate = profDate(idDesc);
o_descProfLocDate = profLocDate(idDesc);
idAsc = find(profDir == 'A');
o_ascProfNum = profNum(idAsc);
o_ascProfDate = profDate(idAsc);
o_ascProfLocDate = profLocDate(idAsc);

return

% ------------------------------------------------------------------------------
% Check if a variable (defined by its name) is present in a NetCDF file.
%
% SYNTAX :
%  [o_present] = var_is_present(a_ncId, a_varName)
%
% INPUT PARAMETERS :
%   a_ncId    : NetCDF file Id
%   a_varName : variable name
%
% OUTPUT PARAMETERS :
%   o_present : exist flag (1 if exists, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/26/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_present] = var_is_present(a_ncId, a_varName)

o_present = 0;

[nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(a_ncId);

for idVar= 0:nbVars-1
   [varName, varType, varDims, nbAtts] = netcdf.inqVar(a_ncId, idVar);
   if (strcmp(varName, a_varName))
      o_present = 1;
      break
   end
end

return

% ------------------------------------------------------------------------------
% Convert a julian 1950 date to a gregorian date.
%
% SYNTAX :
%   [o_gregorianDate] = julian_2_gregorian(a_julDay)
%
% INPUT PARAMETERS :
%   a_julDay : julian 1950 date
%
% OUTPUT PARAMETERS :
%   o_gregorianDate : gregorain date (in 'yyyy/mm/dd HH:MM' or 
%                     'yyyy/mm/dd HH:MM:SS' format)
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_gregorianDate] = julian_2_gregorian(a_julDay)

% default values
global g_dateDef;

% output parameters initialization
o_gregorianDate = [];

[dayNum, dd, mm, yyyy, HH, MI, SS] = format_juld(a_julDay);

for idDate = 1:length(dayNum)
   if (a_julDay(idDate) ~= g_dateDef)
      o_gregorianDate = [o_gregorianDate; sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
         yyyy(idDate), mm(idDate), dd(idDate), HH(idDate), MI(idDate), SS(idDate))];
   else
      o_gregorianDate = [o_gregorianDate; '9999/99/99 99:99:99'];
   end
end

return

% ------------------------------------------------------------------------------
% Split of a julian 1950 date in gregorian date parts.
%
% SYNTAX :
%   [o_dayNum, o_day, o_month, o_year, o_hour, o_min, o_sec] = format_juld(a_juld)
%
% INPUT PARAMETERS :
%   a_juld : julian 1950 date
%
% OUTPUT PARAMETERS :
%   o_dayNum : julian 1950 day number
%   o_day    : gregorian day
%   o_month  : gregorian month
%   o_year   : gregorian year
%   o_hour   : gregorian hour
%   o_min    : gregorian minute
%   o_sec    : gregorian second
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dayNum, o_day, o_month, o_year, o_hour, o_min, o_sec] = format_juld(a_juld)
 
% output parameters initialization
o_dayNum = []; 
o_day = []; 
o_month = []; 
o_year = [];   
o_hour = [];   
o_min = [];
o_sec = [];

% default values
global g_dateDef;
global g_janFirst1950InMatlab;


for id = 1:length(a_juld)
   juldStr = num2str(a_juld(id), 11);
   res = sscanf(juldStr, '%5d.%6d');
   o_day(id) = res(1);
   
   if (o_day(id) ~= fix(g_dateDef))
      o_dayNum(id) = fix(a_juld(id));
      
      dateNum = o_day(id) + g_janFirst1950InMatlab;
      ymd = datestr(dateNum, 'yyyy/mm/dd');
      res = sscanf(ymd, '%4d/%2d/%d');
      o_year(id) = res(1);
      o_month(id) = res(2);
      o_day(id) = res(3);

      hms = datestr(a_juld(id), 'HH:MM:SS');
      res = sscanf(hms, '%d:%d:%d');
      o_hour(id) = res(1);
      o_min(id) = res(2);
      o_sec(id) = res(3);
   else
      o_dayNum(id) = 99999;
      o_day(id) = 99;
      o_month(id) = 99;
      o_year(id) = 9999;
      o_hour(id) = 99;
      o_min(id) = 99;
      o_sec(id) = 99;
   end
   
end

return
