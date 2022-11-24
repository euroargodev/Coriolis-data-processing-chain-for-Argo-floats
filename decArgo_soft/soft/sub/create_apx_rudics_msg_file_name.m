% ------------------------------------------------------------------------------
% Create the name of an Apex Iridium Rudics or Navis msg file (according to
% matlab decoder specifications).
%
% SYNTAX :
%  [o_logFileName] = create_apx_rudics_log_file_name(a_filePathName, ...
%    a_floatWmo, a_floatId, a_floatLaunchDate, a_floatEndDate)
%
% INPUT PARAMETERS :
%   a_filePathName    : input file path name
%   a_floatWmo        : float WMO number
%   a_floatId         : float Rudics Id
%   a_floatDecId      : float decoder Id
%   a_floatLaunchDate : float launch date
%   a_floatLaunchDate : float end decoding date
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_msgFileName] = create_apx_rudics_msg_file_name(a_filePathName, ...
   a_floatWmo, a_floatId, a_floatDecId, ...
   a_floatLaunchDate, a_floatEndDate)

% output parameters initialization
o_msgFileName = [];

% default values
global g_decArgo_dateDef;
global g_decArgo_janFirst1950InMatlab;


% retrieve input cycle and pid number
[~, inputFileName, ~] = fileparts(a_filePathName);
idF = strfind(inputFileName, '_');
if (length(idF) < 3)
   fprintf('ERROR: Inconsistent input file name: %s => ignored\n', a_filePathName);
   return;
end
inputCyNum = inputFileName(idF(2)+1:idF(3)-1);
pidNum = str2num(inputFileName(idF(end)+1:end));

% read input file
[error, ...
   configDataStr, ...
   driftMeasDataStr, ...
   profInfoDataStr, ...
   profLowResMeasDataStr, ...
   profHighResMeasDataStr, ...
   gpsFixDataStr, ...
   engineeringDataStr, ...
   nearSurfaceDataStr ...
   ] = read_apx_ir_rudics_msg_file(a_filePathName);
if (error == 1)
   fprintf('ERROR: Error in file: %s => ignored\n', a_filePathName);
   return;
end

[profInfo] = parse_apx_ir_rudics_profile_info(profInfoDataStr);
[driftData] = parse_apx_ir_rudics_drift_data(driftMeasDataStr, a_floatDecId);
[gpsLocDate, gpsLocLon, gpsLocLat, ...
   gpsLocNbSat, gpsLocAcqTime, ...
   gpsLocFailedAcqTime, gpsLocFailedIce] = parse_apx_ir_rudics_gps_fix(gpsFixDataStr);

dates = [];
if (~isempty(profInfo) && isfield(profInfo, 'ProfTime'))
   dates = [dates profInfo.ProfTime];
end
if (~isempty(driftData))
   dates = [dates; driftData.dates(:, 1)];
end
if (~isempty(gpsLocDate))
   dates = [dates; gpsLocDate];
end

if (isempty(dates))
   fprintf('ERROR: No dates in file: %s => ignored\n', a_filePathName);
   return;
end

fileNameDate = min(dates);

if (~any(dates > a_floatLaunchDate))
   
   % file dates are before launch date
   outputCyNum = 'TTT';
else
   if (a_floatEndDate ~= g_decArgo_dateDef)
      if(~any(dates < a_floatEndDate))
         
         % file dates are after float end date
         outputCyNum = 'UUU';
      else
         outputCyNum = inputCyNum;
      end
   else
      outputCyNum = inputCyNum;
   end
end

o_msgFileName = sprintf('%04d_%s_%s_%d_%s_%08d.msg', ...
   a_floatId, ...
   datestr(fileNameDate + g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
   inputCyNum, ...
   a_floatWmo, ...
   outputCyNum, ...
   pidNum);

return;
