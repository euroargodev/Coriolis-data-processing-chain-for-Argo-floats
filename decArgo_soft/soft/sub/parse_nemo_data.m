% ------------------------------------------------------------------------------
% Parse NEMO parameter data.
%
% SYNTAX :
%  [o_data] = parse_nemo_data(a_paramName, a_paramValue, a_timeInfo, a_headerName)
%
% INPUT PARAMETERS :
%   a_paramName  : parameter names
%   a_paramValue : input ASCII parameter values
%   a_timeInfo   : information to compute parameter times (JULD)
%   a_headerName : header name for parameter names information
%
% OUTPUT PARAMETERS :
%   o_data : parameter data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/04/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_data] = parse_nemo_data(a_paramName, a_paramValue, a_timeInfo, a_headerName)

% output parameters initialization
o_data = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(a_paramName) && isempty(a_paramValue))
   return
end

errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

if (isempty(a_paramName) && ~isempty(a_paramValue))
   fprintf('ERROR: %s header ''[%s]'' is missing => data ignored\n', errorHeader, a_headerName);
   return
end

% create the list of parameter names
paramNameList = strsplit(a_paramName{:}, '\t');

% read the data
paramDataList = [];
for idL = 1:size(a_paramValue, 2)
   paramDataList = [paramDataList;
      str2double(strsplit(a_paramValue{idL}, '\t'))];
end

if (~isempty(paramDataList))
   
   % compute JULD of data
   if (~isempty(a_timeInfo))
      idTimesDel = [];
      for idJ = 1:size(a_timeInfo, 1)
         timeInfo = a_timeInfo(idJ, :);
         idTimes = timeInfo{2};
         idTimesDel = [idTimesDel idTimes];
         julD = [];
         for idL = 1:size(paramDataList, 1)
            if (~any(isnan(paramDataList(idL, idTimes)) == 1))
               julD(end+1) = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
                  paramDataList(idL, idTimes)));
            else
               julD(end+1) = nan;
            end
         end
         paramNameList = [paramNameList timeInfo(1)];
         paramDataList = [paramDataList julD'];
      end
      paramNameList(idTimesDel) = [];
      paramDataList(:, idTimesDel) = [];
      for idJ = 1:size(a_timeInfo, 1)
         paramNameList = [paramNameList(end) paramNameList(1:end-1)];
         paramDataList = [paramDataList(:, end) paramDataList(:, 1:end-1)];
      end
   end
   
   % store output data
   o_data.paramName = paramNameList;
   o_data.paramValue = paramDataList;
end

return,
