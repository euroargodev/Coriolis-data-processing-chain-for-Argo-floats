% ------------------------------------------------------------------------------
% Create drift data set from decoded CTD messages.
%
% SYNTAX :
%  [o_parkOcc, o_parkDate, o_parkTransDate, ...
%    o_parkPres, o_parkTemp, o_parkSal, o_parkRawDoxy] = ...
%    create_prv_drift_32(a_tabDrifCTDO, a_nbDriftMeas, ...
%    a_descentStartDate, a_floatClockDrift, ...
%    a_descentEndDate, a_descentToProfStartDate, ...
%    a_driftSamplingPeriod)
%
% INPUT PARAMETERS :
%   a_tabDrifCTDO            : drift CTDO data
%   a_nbDriftMeas            : number of CTDO measurements in drift
%   a_descentStartDate       : descent start date
%   a_floatClockDrift        : float clock drift
%   a_descentEndDate         : descent end date
%   a_descentToProfStartDate : descent to profile start date
%   a_driftSamplingPeriod    : sampling period during drift phase (in hours)
%
% OUTPUT PARAMETERS :
%   o_parkOcc       : redundancy of parking measurements
%   o_parkDate      : date of parking measurements
%   o_parkTransDate : transmitted (=1) or computed (=0) date of parking
%                     measurements
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
%   07/07/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkOcc, o_parkDate, o_parkTransDate, ...
   o_parkPres, o_parkTemp, o_parkSal, o_parkRawDoxy] = ...
   create_prv_drift_32(a_tabDrifCTDO, a_nbDriftMeas, ...
   a_descentStartDate, a_floatClockDrift, ...
   a_descentEndDate, a_descentToProfStartDate, ...
   a_driftSamplingPeriod)

% output parameters initialization
o_parkOcc = [];
o_parkDate = [];
o_parkTransDate = [];
o_parkPres = [];
o_parkTemp = [];
o_parkSal = [];
o_parkRawDoxy = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% default values
global g_decArgo_dateDef;
global g_decArgo_presCountsDef;
global g_decArgo_tempCountsDef;
global g_decArgo_salCountsDef;
global g_decArgo_tPhaseDoxyCountsDef;

% configuration values
global g_decArgo_add3Min;
global g_decArgo_generateNcTech;


% no drift message received
if (isempty(a_tabDrifCTDO))
   return;
end

% add and offset of 3 minutes to technical dates (given in tenths of an
% hour after truncation))
zeroOr3Min = 0;
if (g_decArgo_add3Min == 1)
   zeroOr3Min = 3/1440;
end

% retrieve the drift sampling period from the configuration
[configNames, configValues] = get_float_config_argos_1(0);
driftSamplingPeriod = get_config_value('CONFIG_MC8_', configNames, configValues);
if (isempty(driftSamplingPeriod))
   driftSamplingPeriod = a_driftSamplingPeriod;
end

% drift sampling period in days
driftSampPeriodDay = double(driftSamplingPeriod)/24;

% compute descent start date in float time
noDates = 0;
if (a_descentStartDate ~= g_decArgo_dateDef)
   % the incoming float times are not corrected yet from clock drift
   %    descentStartDate = a_descentStartDate - zeroOr3Min + round(a_floatClockDrift*1440)/1440;
   descentStartDate = a_descentStartDate - zeroOr3Min;
   descentStartDay = fix(descentStartDate);
   descentStartHour = round((descentStartDate - descentStartDay)*24*1440)/1440;
else
   fprintf('DEC_ERROR: Float #%d Cycle #%d: unable to determine drift measurements dates (Descent Start Date is missing)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   noDates = 1;
end

% decode transmitted drift measurement dates and determine the associated
% number of drift measurements
msgDates = ones(size(a_tabDrifCTDO, 1), 1)*g_decArgo_dateDef;
msgNbMeas = zeros(size(a_tabDrifCTDO, 1), 1);
for idMsg = 1:size(a_tabDrifCTDO, 1)
   
   if (noDates == 0)
      day = a_tabDrifCTDO(idMsg, 2);
      hourDelay = a_tabDrifCTDO(idMsg, 3);
      date = descentStartDay + day + ceil(descentStartHour+hourDelay)/24;
      
      msgDates(idMsg) = date;
   end

   % determine the number of drift measurements in this message
   nbMeas = 0;
   for idMes = 1:a_tabDrifCTDO(idMsg, 4)
      parkPres = a_tabDrifCTDO(idMsg, 5+idMes-1);
      parkTemp = a_tabDrifCTDO(idMsg, 15+idMes-1);
      parkSal = a_tabDrifCTDO(idMsg, 20+idMes-1);
      parkOxy = a_tabDrifCTDO(idMsg, 25+idMes-1);
      if ~((parkPres == 0) && (parkTemp == 0) && (parkSal == 0) && (parkOxy == 0))
         nbMeas = nbMeas + 1;
      end
   end

   msgNbMeas(idMsg) = nbMeas;
end

% generate array of drift measurements
nbMeasTot = sum(msgNbMeas);
if (noDates == 0)
   o_parkDate = ones(nbMeasTot, 1)*g_decArgo_dateDef;
   o_parkTransDate = zeros(nbMeasTot, 1);
end
o_parkOcc = zeros(nbMeasTot, 1);
o_parkPres = ones(nbMeasTot, 1)*g_decArgo_presCountsDef;
o_parkTemp = ones(nbMeasTot, 1)*g_decArgo_tempCountsDef;
o_parkSal = ones(nbMeasTot, 1)*g_decArgo_salCountsDef;
o_parkRawDoxy = ones(nbMeasTot, 1)*g_decArgo_tPhaseDoxyCountsDef;

% fill drift measurement arrays
idCurMes = 1;
[unused, idSort] = sort(msgDates);
for id = 1:size(a_tabDrifCTDO, 1)
   idMsg = idSort(id);
   msgOcc = a_tabDrifCTDO(idMsg, 1);
   
   for idMes = 1:a_tabDrifCTDO(idMsg, 4)
      
      parkPres = a_tabDrifCTDO(idMsg, 5+idMes-1);
      parkPresOk = a_tabDrifCTDO(idMsg, 10+idMes-1);
      parkTemp = a_tabDrifCTDO(idMsg, 15+idMes-1);
      parkSal = a_tabDrifCTDO(idMsg, 20+idMes-1);
      parkOxy = a_tabDrifCTDO(idMsg, 25+idMes-1);
      
      if ~((parkPres == 0) && (parkTemp == 0) && (parkSal == 0) && (parkOxy == 0))
         o_parkOcc(idCurMes) = msgOcc;
         if (noDates == 0)
            if (idMes == 1)
               o_parkDate(idCurMes) = msgDates(idMsg);
               o_parkTransDate(idCurMes) = 1;
            else
               o_parkDate(idCurMes) = msgDates(idMsg) + (idMes-1)*driftSampPeriodDay;
               o_parkTransDate(idCurMes) = 0;
            end
         end
         if (parkPresOk == 0)
            parkPres = g_decArgo_presCountsDef;
         end
         o_parkPres(idCurMes) = parkPres;
         o_parkTemp(idCurMes) = parkTemp;
         o_parkSal(idCurMes) = parkSal;
         o_parkRawDoxy(idCurMes) = parkOxy;
         
         idCurMes = idCurMes + 1;
      end
   end
end

% check number of drift measurements done by the float
if (~isempty(a_nbDriftMeas))
   if (a_nbDriftMeas ~= nbMeasTot)
      fprintf('DEC_INFO: Float #%d Cycle #%d: all expected drift measurements has not been received: done (%d) / received (%d)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_nbDriftMeas, nbMeasTot);
   end
end

% check the consistency of drift measurement dates vs the
% [a_descentEndDate - a_descentToProfStartDate] interval
if (noDates == 0)
   if (a_descentEndDate ~= g_decArgo_dateDef)
      % the incoming float times are not corrected yet from clock drift
      %       idKo = find(o_parkDate < a_descentEndDate - zeroOr3Min + a_floatClockDrift);
      idKo = find(o_parkDate < a_descentEndDate - zeroOr3Min);
      if (~isempty(idKo))
         fprintf('DEC_WARNING: Float #%d Cycle #%d: the following drift measurement dates are dated before the Descent En Date (%s):', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, julian_2_gregorian_dec_argo(a_descentEndDate));
         fprintf(' #%d', idKo);
         fprintf('\n');
      end
   end
   if (a_descentToProfStartDate ~= g_decArgo_dateDef)
      % the incoming float times are not corrected yet from clock drift
      %       idKo = find(o_parkDate > a_descentToProfStartDate - zeroOr3Min + a_floatClockDrift);
      idKo = find(o_parkDate > a_descentToProfStartDate - zeroOr3Min);
      if (~isempty(idKo))
         fprintf('DEC_WARNING: Float #%d Cycle #%d: the following drift measurement dates are dated after the Descent To Prof Start Date (%s):', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, julian_2_gregorian_dec_argo(a_descentToProfStartDate));
         fprintf(' #%d', idKo);
         fprintf('\n');
      end
   end
end

% output NetCDF files
if (g_decArgo_generateNcTech ~= 0)
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 321];
   g_decArgo_outputNcParamValue{end+1} = size(a_tabDrifCTDO, 1);
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 323];
   g_decArgo_outputNcParamValue{end+1} = sum(msgNbMeas);
end

return;
