% ------------------------------------------------------------------------------
% Print profile and park data measurements in CSV file.
%
% SYNTAX :
%  print_data_meas_in_csv_file( ...
%    a_tabProfiles, a_tabDrift, a_tabSurf, a_outputFileDir, a_floatLoginName, a_fileDateStr)
%
% INPUT PARAMETERS :
%   a_tabProfiles    : profile data
%   a_tabDrift       : park data
%   a_tabSurf        : surface data
%   a_outputFileDir  : output file directory
%   a_floatLoginName : float login name
%   a_fileDateStr    : date of the Matlab session
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/09/2022 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_meas_in_csv_file( ...
   a_tabProfiles, a_tabDrift, a_tabSurf, a_outputFileDir, a_floatLoginName, a_fileDateStr)


% create output file pathname
outputDirName = [a_outputFileDir '/' a_floatLoginName '/'];
if ~(exist(outputDirName, 'dir') == 7)
   mkdir(outputDirName);
end

% print profile measurements
outputPathFileName = [outputDirName '/' a_floatLoginName '_profile_meas_' a_fileDateStr '.csv'];
fidOut = fopen(outputPathFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create output file: %s\n', outputPathFileName);
   return
end

for idProf = 1:length(a_tabProfiles)
   print_data_meas(fidOut, a_floatLoginName, a_tabProfiles(idProf));
end

fclose(fidOut);

% print park measurements
outputPathFileName = [outputDirName '/' a_floatLoginName '_park_meas_' a_fileDateStr '.csv'];
fidOut = fopen(outputPathFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create output file: %s\n', outputPathFileName);
   return
end

for idDrift = 1:length(a_tabDrift)
   print_data_meas(fidOut, a_floatLoginName, a_tabDrift(idDrift));
end

fclose(fidOut);

% print surface measurements
outputPathFileName = [outputDirName '/' a_floatLoginName '_surf_meas_' a_fileDateStr '.csv'];
fidOut = fopen(outputPathFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create output file: %s\n', outputPathFileName);
   return
end

for idSurf = 1:length(a_tabSurf)
   print_data_meas(fidOut, a_floatLoginName, a_tabSurf(idSurf));
end

fclose(fidOut);

return

% ------------------------------------------------------------------------------
% Print data measurements in CSV file.
%
% SYNTAX :
%  print_data_meas(a_fidOut, a_floatLoginName, a_dataStruct)
%
% INPUT PARAMETERS :
%   a_fidOut         : CSV file Id
%   a_floatLoginName : float login name
%   a_dataStruct     : data measurements
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/05/2021 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_meas(a_fidOut, a_floatLoginName, a_dataStruct)

cyNum = a_dataStruct.cycleNumber;
profNum = a_dataStruct.profileNumber;
phaseNum = a_dataStruct.phaseNumber;
paramList = a_dataStruct.paramList;
paramNumberWithSubLevels = a_dataStruct.paramNumberWithSubLevels;
paramNumberOfSubLevels = a_dataStruct.paramNumberOfSubLevels;
data = a_dataStruct.data;
dates = a_dataStruct.dates;
sensorNum = a_dataStruct.sensorNumber;

format = '%s';
header = 'Login name; Sensor num; Cycle num; Profile num; Phase; Date';
for idParam = 1:length(paramList)
   paramInfo = get_netcdf_param_attributes(paramList(idParam).name);
   if (~ismember(idParam, paramNumberWithSubLevels))
      format = [format ';' paramInfo.cFormat];
      header = [header '; ' paramList(idParam).name];
   else
      idSL = find(paramNumberWithSubLevels == idParam);
      format = [format repmat([';' paramInfo.cFormat], 1, paramNumberOfSubLevels(idSL))];
      for idS = 1:paramNumberOfSubLevels(idSL)
         header = [header '; ' paramList(idParam).name '_' num2str(idS)];
      end
   end
end
format = [format '\n'];

fprintf(a_fidOut, '%s\n', header);
for idM = 1:size(data, 1)
   fprintf(a_fidOut, '%s; %d; %d; %d; %s; ', ...
      a_floatLoginName, sensorNum, cyNum, profNum, get_phase_name(phaseNum));
   fprintf(a_fidOut, format, ...
      julian_2_gregorian_dec_argo(dates(idM)), ...
      data(idM, :));
end

return
