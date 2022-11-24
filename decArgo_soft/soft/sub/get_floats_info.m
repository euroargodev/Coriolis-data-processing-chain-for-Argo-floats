% ------------------------------------------------------------------------------
% Get floats information from floats information file.
%
% SYNTAX :
%  [o_listWmoNum, o_listDecId, o_listArgosId, o_listFrameLen, ...
%    o_listCycleTime, o_listDriftSamplingPeriod, o_listDelay, ...
%    o_listLaunchDate, o_listLaunchLon, o_listLaunchLat, ...
%    o_listRefDay, o_listEndDate, o_listDmFlag] = get_floats_info(a_floatInfoFileName)
%
% INPUT PARAMETERS :
%   a_floatInfoFileName : float information file name
%
% OUTPUT PARAMETERS :
%   o_listWmoNum          : floats WMO number
%   o_listDecId           : floats decoder Id
%   o_listArgosId         : floats PTT number
%   o_listFrameLen        : floats data frame length
%   o_listCycleTime       : floats cycle duration
%   o_driftSamplingPeriod : sampling period during drift phase (in hours)
%   o_listDelay           : DELAI parameter (in hours)
%   o_listLaunchDate      : floats launch date
%   o_listLaunchLon       : floats launch longitude
%   o_listLaunchLat       : floats launch latitude
%   o_listRefDay          : floats reference day (day of the first descent)
%   o_listEndDate         : floats end decoding date
%   o_listDmFlag          : floats DM flag
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_listWmoNum, o_listDecId, o_listArgosId, o_listFrameLen, ...
   o_listCycleTime, o_listDriftSamplingPeriod, o_listDelay, ...
   o_listLaunchDate, o_listLaunchLon, o_listLaunchLat, ...
   o_listRefDay, o_listEndDate, o_listDmFlag] = get_floats_info(a_floatInfoFileName)

% output parameters initialization
o_listWmoNum = [];
o_listDecId = [];
o_listArgosId = [];
o_listFrameLen = [];
o_listCycleTime = [];
o_listDriftSamplingPeriod = [];
o_listDelay = [];
o_listLaunchDate = [];
o_listLaunchLon = [];
o_listLaunchLat = [];
o_listRefDay = [];
o_listEndDate = [];
o_listDmFlag = [];

% default values
global g_decArgo_dateDef;


if ~(exist(a_floatInfoFileName, 'file') == 2)
   fprintf('ERROR: Float information file not found: %s\n', a_floatInfoFileName);
   return
end

fId = fopen(a_floatInfoFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Error while opening file : %s\n', a_floatInfoFileName);
end

data = textscan(fId, '%d %d %s %d %d %d %f %s %f %f %s %s %d');

o_listWmoNum = data{1}(:);
o_listDecId = data{2}(:);
o_listArgosId = data{3}(:);
o_listFrameLen = data{4}(:);
o_listCycleTime = data{5}(:);
o_listDriftSamplingPeriod = data{6}(:);
o_listDelay = data{7}(:);
listLaunchDate = data{8}(:);
o_listLaunchLon = data{9}(:);
o_listLaunchLat = data{10}(:);
listRefDay = data{11}(:);
listEndDate = data{12}(:);
o_listDmFlag = data{13}(:);

fclose(fId);

o_listLaunchDate = ones(length(listLaunchDate), 1)*g_decArgo_dateDef;
o_listRefDay = ones(length(listRefDay), 1)*g_decArgo_dateDef;
o_listEndDate = ones(length(listRefDay), 1)*g_decArgo_dateDef;
for id = 1:length(listRefDay)
   launchDate = listLaunchDate{id};
   refDay = listRefDay{id};
   endDate = listEndDate{id};
   if (length(launchDate) == 14)
      o_listLaunchDate(id, 1) = gregorian_2_julian_dec_argo(sprintf('%s/%s/%s %s:%s:%s', ...
         launchDate(1:4), launchDate(5:6), launchDate(7:8), ...
         launchDate(9:10), launchDate(11:12), launchDate(13:14)));
   end
   if (length(refDay) == 8)
      o_listRefDay(id, 1) = gregorian_2_julian_dec_argo(sprintf('%s/%s/%s 00:00:00', ...
         refDay(1:4), refDay(5:6), refDay(7:8)));
   end
   if ((length(endDate) == 14) && (strcmp(endDate, '99999999999999') == 0))
      o_listEndDate(id, 1) = gregorian_2_julian_dec_argo(sprintf('%s/%s/%s %s:%s:%s', ...
         endDate(1:4), endDate(5:6), endDate(7:8), ...
         endDate(9:10), endDate(11:12), endDate(13:14)));
   end
end

return
