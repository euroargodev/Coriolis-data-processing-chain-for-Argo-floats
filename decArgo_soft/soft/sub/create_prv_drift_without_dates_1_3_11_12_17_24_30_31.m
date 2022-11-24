% ------------------------------------------------------------------------------
% Create drift data set from decoded CTD messages without date information.
% NOTE THAT IN THIS CASE, WE CAN NOT DETERMINE THE ORDER OF THE DRIFT
% MEASUREMENTS.
%
% SYNTAX :
%  [o_parkOcc, o_parkDate, o_parkTransDate, ...
%    o_parkPres, o_parkTemp, o_parkSal] = ...
%    create_prv_drift_without_dates_1_3_11_12_17_24_30_31(a_tabDrifCTD)
%
% INPUT PARAMETERS :
%   a_tabDrifCTD : drift CTD data
%
% OUTPUT PARAMETERS :
%   o_parkOcc       : redundancy of parking measurements
%   o_parkDate      : date of parking measurements (always equal to default value)
%   o_parkTransDate : transmitted (=1) or computed (=0) date of parking
%                     measurements (always equal to 1)
%   o_parkPres      : parking pressure measurements
%   o_parkTemp      : parking temperature measurements
%   o_parkSal       : parking salinity measurements
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkOcc, o_parkDate, o_parkTransDate, ...
   o_parkPres, o_parkTemp, o_parkSal] = ...
   create_prv_drift_without_dates_1_3_11_12_17_24_30_31(a_tabDrifCTD)

% output parameters initialization
o_parkOcc = [];
o_parkDate = [];
o_parkTransDate = [];
o_parkPres = [];
o_parkTemp = [];
o_parkSal = [];

% default values
global g_decArgo_dateDef;
global g_decArgo_presCountsDef;

% no drift message received
if (isempty(a_tabDrifCTD))
   return
end

% store drift measurements
for idMsg = 1:size(a_tabDrifCTD, 1)
   msgOcc = a_tabDrifCTD(idMsg, 1);

   for idMes = 1:a_tabDrifCTD(idMsg, 4)
      parkPres = a_tabDrifCTD(idMsg, 5+idMes-1);
      parkPresOk = a_tabDrifCTD(idMsg, 12+idMes-1);
      parkTemp = a_tabDrifCTD(idMsg, 19+idMes-1);
      parkSal = a_tabDrifCTD(idMsg, 26+idMes-1);
      if ~((parkPres == 0) && (parkTemp == 0) && (parkSal == 0))
         o_parkOcc = [o_parkOcc; msgOcc];
         if (parkPresOk == 0)
            parkPres = g_decArgo_presCountsDef;
         end
         o_parkPres = [o_parkPres; parkPres];
         o_parkTemp = [o_parkTemp; parkTemp];
         o_parkSal = [o_parkSal; parkSal];
      end
   end
end

o_parkDate = ones(length(o_parkPres), 1)*g_decArgo_dateDef;
o_parkTransDate = zeros(length(o_parkPres), 1);

return
