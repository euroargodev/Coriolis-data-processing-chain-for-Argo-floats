% ------------------------------------------------------------------------------
% Write statistics on trajectory file.
%
% SYNTAX :
%   nc_traj_statistics or nc_traj_statistics(6900189, 7900118)
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
%   06/12/2014 - RNU - creation
% ------------------------------------------------------------------------------
function nc_traj_statistics(varargin)

% top directory of the NetCDF files to convert
DIR_INPUT_NC_FILES = 'C:\users\RNU\Argo\work\nc_output_decPrv_\';
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';

% default list of floats to convert
FLOAT_LIST_FILE_NAME = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/rem_all.txt';

% directory to store the log and csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log';

% default values initialization
init_default_values;


if (nargin == 0)
   floatListFileName = FLOAT_LIST_FILE_NAME;
   
   % floats to process come from floatListFileName
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

logFile = [DIR_LOG_CSV_FILE '/' 'nc_traj_statistics' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_traj_statistics' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end

tic;

wantedVars = [ ...
   {'JULD'} ...
   {'LATITUDE'} ...
   {'LONGITUDE'} ...
   {'POSITION_ACCURACY'} ...
   {'CYCLE_NUMBER'} ...
   {'MEASUREMENT_CODE'} ...
   ];

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   minSubsurface = 9999999999;
   maxSurface = 0;
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   ncFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];
   
   if (exist(ncFileDir, 'dir') == 7)
      
      % convert trajectory file
      ncFiles = dir([ncFileDir sprintf('%d_*traj.nc', floatNum)]);
      for idFile = 1:length(ncFiles)
         
         ncFileName = ncFiles(idFile).name;
         ncFilePathName = [ncFileDir '/' ncFileName];
         
         % retrieve the data
         [data] = get_data_from_nc_file(ncFilePathName, wantedVars);
         
         idVal = find(strcmp('JULD', data(1:2:end)) == 1, 1);
         julD = data{2*idVal};

         idVal = find(strcmp('LATITUDE', data(1:2:end)) == 1, 1);
         latitude = data{2*idVal};

         idVal = find(strcmp('LONGITUDE', data(1:2:end)) == 1, 1);
         longitude = data{2*idVal};
         
         idVal = find(strcmp('POSITION_ACCURACY', data(1:2:end)) == 1, 1);
         posAcc = data{2*idVal};
         
         idVal = find(strcmp('CYCLE_NUMBER', data(1:2:end)) == 1, 1);
         cycleNum = data{2*idVal};
         
         idVal = find(strcmp('MEASUREMENT_CODE', data(1:2:end)) == 1, 1);
         measCode = data{2*idVal};
         
         % collect times
         id702 = find(measCode == 702);
         fmtJulD = julD(id702);
         fmtCyNum = cycleNum(id702);
         
         id703 = find(measCode == 703);
         locJulD = julD(id703);
         locCyNum = cycleNum(id703);
         
         id704 = find(measCode == 704);
         lmtJulD = julD(id704);
         lmtCyNum = cycleNum(id704);

         % check the data
         cyMin = min(cycleNum(find(cycleNum ~= 99999)));
         cyMax = max(cycleNum(find(cycleNum ~= 99999)));
         
         if (cyMin ~= -1)
            fprintf('WARNING: Minimum cycle number is %d (expected -1)\n', cyMin);
         end
         
         for cyNum = cyMin:cyMax
         
            if (cyNum > 0)
               
               % cycle duration
               idLmtPrev = find(lmtCyNum == cyNum-1);
               if (~isempty(idLmtPrev))
                  idLmtPrev = idLmtPrev(end);
                  lmtPrev = lmtJulD(idLmtPrev);
                  idFmt = find(fmtCyNum == cyNum);
                  idLmt = find(lmtCyNum == cyNum);
                  if (~isempty(idFmt) && ~isempty(idLmt))
                     fmt = fmtJulD(idFmt);
                     lmt = lmtJulD(idLmt);
                     idLoc = find(locCyNum == cyNum);
                     
                     subsurface = (fmt-lmtPrev)*24;
                     surface = (lmt-fmt)*24;
                     
                     minSubsurface = min(minSubsurface, subsurface);
                     maxSurface = max(maxSurface, surface);

                     flagErr = 0;
                     if (maxSurface > minSubsurface)
                        flagErr = 1;
                        fprintf('WARNING: buff error for cycle %d\n', cyNum);
                     end
                     
                     fprintf(fidOut, '%d; %d; %s; %s; %s; %s; %s; %d; %s; %s; %d\n', ...
                        floatNum, cyNum, ...
                        julian_2_gregorian_dec_argo(lmtPrev), ...
                        julian_2_gregorian_dec_argo(fmt), ...
                        julian_2_gregorian_dec_argo(lmt), ...
                        format_duration(subsurface), ...
                        format_duration(surface), ...
                        length(idLoc), ...
                        format_duration(minSubsurface), ...
                        format_duration(maxSurface), ...
                        flagErr);
                  else
                  end
               else
               end
               
            elseif (cyNum == 0)
               idCy = find(cycleNum == cyNum);
               if (isempty(idCy))
                  fprintf('WARNING: Cycle #0 no data\n');
               elseif (length(unique(measCode(idCy))) ~= 3)
                  fprintf('WARNING: Cycle #0 inconsistent contents\n');
               end
            elseif (cyNum == -1)
               idCy = find(cycleNum == cyNum);
               if (length(unique(measCode(idCy))) ~= 1)
                  fprintf('WARNING: Data stored in cycle #-1\n');
               end
            end
         end
      end
      
   else
      fprintf('WARNING: Directory not found: %s\n', ncFileDir);
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

fclose(fidOut);

return


% ------------------------------------------------------------------------------
% Duration format.
%
% SYNTAX :
%   [o_time] = format_time_dec_argo(a_time)
%
% INPUT PARAMETERS :
%   a_time : hour (in float)
%
% OUTPUT PARAMETERS :
%   o_time : formated duration
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_durationStr] = format_duration(a_duration)

% output parameters initialization
o_durationStr = [];

a_duration = abs(a_duration);
h = fix(a_duration);
m = fix((a_duration-h)*60);
s = round(((a_duration-h)*60-m)*60);
if (s == 60)
   s = 0;
   m = m + 1;
   if (m == 60)
      m = 0;
      h = h + 1;
   end
end
days = fix(h/24);
h = h -24*days;
o_durationStr = sprintf('%d day %02d:%02d:%02d', days, h, m, s);

return
