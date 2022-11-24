% ------------------------------------------------------------------------------
% Create drift data set from decoded CTDO messages without date information.
% NOTE THAT IN THIS CASE, WE CAN NOT DETERMINE THE ORDER OF THE DRIFT
% MEASUREMENTS.
%
% SYNTAX :
%  [o_parkOcc, o_parkDate, o_parkTransDate, ...
%    o_parkPres, o_parkTemp, o_parkSal, o_parkRawDoxy] = ...
%    create_prv_drift_without_dates_27_28_29(a_tabDrifCTDO)
%
% INPUT PARAMETERS :
%   a_tabDrifCTDO : drift CTDO data
%
% OUTPUT PARAMETERS :
%   o_parkOcc       : redundancy of parking measurements
%   o_parkDate      : date of parking measurements (always equal to default value)
%   o_parkTransDate : transmitted (=1) or computed (=0) date of parking
%                     measurements (always equal to 1)
%   o_parkPres      : parking pressure measurements
%   o_parkTemp      : parking temperature measurements
%   o_parkSal       : parking salinity measurements
%   o_parkRawDoxy   : parking oxygen measurements
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/06/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkOcc, o_parkDate, o_parkTransDate, ...
   o_parkPres, o_parkTemp, o_parkSal, o_parkRawDoxy] = ...
   create_prv_drift_without_dates_27_28_29(a_tabDrifCTDO)

% output parameters initialization
o_parkOcc = [];
o_parkDate = [];
o_parkTransDate = [];
o_parkPres = [];
o_parkTemp = [];
o_parkSal = [];
o_parkRawDoxy = [];

% default values
global g_decArgo_dateDef;
global g_decArgo_presCountsDef;


% no drift message received
if (isempty(a_tabDrifCTDO))
   return;
end

% store drift measurements
for idMsg = 1:size(a_tabDrifCTDO, 1)
   msgOcc = a_tabDrifCTDO(idMsg, 1);

   for idMes = 1:a_tabDrifCTDO(idMsg, 4)
      parkPres = a_tabDrifCTDO(idMsg, 5+idMes-1);
      parkPresOk = a_tabDrifCTDO(idMsg, 10+idMes-1);
      parkTemp = a_tabDrifCTDO(idMsg, 15+idMes-1);
      parkSal = a_tabDrifCTDO(idMsg, 20+idMes-1);
      parkOxy = a_tabDrifCTDO(idMsg, 25+idMes-1);
      if ~((parkPres == 0) && (parkTemp == 0) && (parkSal == 0) && (parkOxy == 0))
         o_parkOcc = [o_parkOcc; msgOcc];
         if (parkPresOk == 0)
            parkPres = g_decArgo_presCountsDef;
         end
         o_parkPres = [o_parkPres; parkPres];
         o_parkTemp = [o_parkTemp; parkTemp];
         o_parkSal = [o_parkSal; parkSal];
         o_parkRawDoxy = [o_parkRawDoxy; parkOxy];
      end
   end
end

o_parkDate = ones(length(o_parkPres), 1)*g_decArgo_dateDef;
o_parkTransDate = zeros(length(o_parkPres), 1);

return;
