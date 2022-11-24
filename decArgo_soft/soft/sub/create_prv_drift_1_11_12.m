% ------------------------------------------------------------------------------
% Create drift data set from decoded CTD messages.
%
% SYNTAX :
%  [o_parkOcc, o_parkDate, o_parkTransDate, o_parkPres, o_parkTemp, o_parkSal] = ...
%    create_prv_drift_1_11_12(a_tabDrifCTD, a_nbDriftMeas, a_refDay, ...
%    a_descentEndDate, a_descentToProfStartDate, ...
%    a_ascentStartDate, a_driftSamplingPeriod)
%
% INPUT PARAMETERS :
%   a_tabDrifCTD             : drift CTD data
%   a_nbDriftMeas            : number of CTD measurements in drift
%   a_refDay                 : reference day (day of the first descent)
%   a_descentEndDate         : descent end date
%   a_descentToProfStartDate : descent to profile start date
%   a_ascentStartDate        : ascent start date
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
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkOcc, o_parkDate, o_parkTransDate, o_parkPres, o_parkTemp, o_parkSal] = ...
   create_prv_drift_1_11_12(a_tabDrifCTD, a_nbDriftMeas, a_refDay, ...
   a_descentEndDate, a_descentToProfStartDate, ...
   a_ascentStartDate, a_driftSamplingPeriod)

% output parameters initialization
o_parkOcc = [];
o_parkDate = [];
o_parkTransDate = [];
o_parkPres = [];
o_parkTemp = [];
o_parkSal = [];

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

% configuration values
global g_decArgo_add3Min;
global g_decArgo_generateNcTech;


% no drift message received
if (isempty(a_tabDrifCTD))
   return
end

% add and offset of 3 minutes to technical dates (given in tenths of an
% hour after truncation))
zeroOr3Min = 0;
if (g_decArgo_add3Min == 1)
   zeroOr3Min = 3/1440;
end

% find day of transmitted drift measurement dates and determine the associated
% number of drift measurements
msgDates = ones(size(a_tabDrifCTD, 1), 1)*g_decArgo_dateDef;
msgNbMeas = zeros(size(a_tabDrifCTD, 1), 1);
msgNbMod = ones(size(a_tabDrifCTD, 1), 1)*999;
fail = 0;
for idMsg = 1:size(a_tabDrifCTD, 1)
   % find exact day number (6 bits coded in transmitted message)
   day = a_tabDrifCTD(idMsg, 2);
   hour = a_tabDrifCTD(idMsg, 3);
   date = a_refDay + day + hour/24;

   nMod1 = ceil(((a_descentEndDate-zeroOr3Min) - date)/64);
   nMod2 = floor((a_descentToProfStartDate - date)/64);
   if (nMod1 == nMod2)
      msgNbMod(idMsg) = nMod1;
   else
      fail = 1;
   end

   msgDates(idMsg) = date;

   % determine the number of drift measurements in this message
   nbMeas = 0;
   for idMes = 1:a_tabDrifCTD(idMsg, 4)
      parkPres = a_tabDrifCTD(idMsg, 5+idMes-1);
      parkTemp = a_tabDrifCTD(idMsg, 19+idMes-1);
      parkSal = a_tabDrifCTD(idMsg, 26+idMes-1);
      if ~((parkPres == 0) && (parkTemp == 0) && (parkSal == 0))
         nbMeas = nbMeas + 1;
      end
   end

   msgNbMeas(idMsg) = nbMeas;
end

if (~isempty(find(msgNbMod == 999, 1)))
   id = find(msgNbMod ~= 999, 1);
   if (~isempty(id))
      idRef = id(1);
   else
      msgNbMod(1) = ceil(((a_descentEndDate-zeroOr3Min) - msgDates(1))/64);
      idRef = 1;
   end

   days = a_tabDrifCTD(:, 2);
   idKo = find(msgNbMod == 999);
   for id = 1:length(idKo)
      idK = idKo(id);
      msgNbMod(idK) = msgNbMod(idRef);
      if (abs(days(idK)-days(idRef)) > 20)
         if (idK < idRef)
            msgNbMod(idK) = msgNbMod(idK) + 1;
         else
            msgNbMod(idK) = msgNbMod(idK) - 1;
         end
      end
   end
end

msgDates = msgDates + msgNbMod*64;

% try to fit the decoded dates into the
%[a_descentEndDate - a_descentToProfStartDate] interval
if (fail == 1)
   nbDayCor = 0;
   if (min(msgDates - (a_descentEndDate-zeroOr3Min)) < 0)
      corDates = msgDates;
      while ~(((min(corDates - (a_descentEndDate-zeroOr3Min)) > 0) && ...
            (max(corDates - a_descentToProfStartDate) < 0)) || ...
            (max(corDates - a_descentToProfStartDate) > 0))
         nbDayCor = nbDayCor + 1;
         corDates = msgDates + nbDayCor;
      end
      if (max(corDates - a_descentToProfStartDate) <= 0)
         fail = 0;
      end
   elseif (max(msgDates - a_descentToProfStartDate) > 0)
      corDates = msgDates;
      while ~(((min(corDates - (a_descentEndDate-zeroOr3Min)) > 0) && ...
            (max(corDates - a_descentToProfStartDate) < 0)) || ...
            (min(corDates - (a_descentEndDate-zeroOr3Min)) < 0))
         nbDayCor = nbDayCor - 1;
         corDates = msgDates + nbDayCor;
      end
      if (min(corDates - (a_descentEndDate-zeroOr3Min)) >= 0)
         fail = 0;
      end
   end

   if (fail == 0)
      oldRefDate = julian_2_gregorian_dec_argo(a_refDay);
      newRefDate = julian_2_gregorian_dec_argo(a_refDay + nbDayCor);
      fprintf('WARNING: Float #%d Cycle #%d: new value for ''Day of first descent'' = %s (instead of %s)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, newRefDate(1:10), oldRefDate(1:10));
      msgDates = corDates;
   end
end

% try to determine drift measurement dates
[parkDateHour] = compute_drift_dates_1_4_11_12_19( ...
   1, a_tabDrifCTD, a_driftSamplingPeriod, ...
   (a_descentEndDate-zeroOr3Min), a_descentToProfStartDate, msgDates, msgNbMeas);

if (isempty(parkDateHour))
   if ((min(msgDates - (a_descentEndDate-zeroOr3Min)) >= 0) && ...
         (max(msgDates - a_descentToProfStartDate) <= 0))
      nbDayBefore = floor(min(msgDates - (a_descentEndDate-zeroOr3Min)));
      nbDayAfter = floor(min(a_descentToProfStartDate - msgDates));
      for nbDayCor = -nbDayBefore:nbDayAfter
         % try to determine drift measurement dates
         [parkDateHour] = compute_drift_dates_1_4_11_12_19( ...
            1, a_tabDrifCTD, a_driftSamplingPeriod, ...
            (a_descentEndDate-zeroOr3Min), a_descentToProfStartDate, msgDates+nbDayCor, msgNbMeas);
         if (~isempty(parkDateHour))
            oldRefDate = julian_2_gregorian_dec_argo(a_refDay);
            newRefDate = julian_2_gregorian_dec_argo(a_refDay + nbDayCor);
            fprintf('WARNING: Float #%d Cycle #%d: new value for ''Day of first descent'' = %s (instead of %s)\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, newRefDate(1:10), oldRefDate(1:10));
            msgDates = msgDates + nbDayCor;
            break
         end
      end
   end
end

if (isempty(parkDateHour))
   fprintf('DEC_INFO: Float #%d Cycle #%d: determination of drift measurement dates failed (trying with an enlarged drift phase)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);

   % determination of drift measurement dates failed
   % another try with an enlarged drift phase
   [parkDateHour] = compute_drift_dates_1_4_11_12_19( ...
      2, a_tabDrifCTD, a_driftSamplingPeriod, ...
      (a_descentEndDate-zeroOr3Min), a_ascentStartDate, msgDates, msgNbMeas);

   if (isempty(parkDateHour))
      if ((min(msgDates - (a_descentEndDate-zeroOr3Min)) >= 0) && ...
            (max(msgDates - a_ascentStartDate) <= 0))
         nbDayBefore = floor(min(msgDates - (a_descentEndDate-zeroOr3Min)));
         nbDayAfter = floor(min(a_ascentStartDate - msgDates));
         for nbDayCor = nbDayBefore:nbDayAfter
            % try to determine drift measurement dates
            [parkDateHour] = compute_drift_dates_1_4_11_12_19( ...
               1, a_tabDrifCTD, a_driftSamplingPeriod, ...
               (a_descentEndDate-zeroOr3Min), a_ascentStartDate, msgDates+nbDayCor, msgNbMeas);
            if (~isempty(parkDateHour))
               oldRefDate = julian_2_gregorian_dec_argo(a_refDay);
               newRefDate = julian_2_gregorian_dec_argo(a_refDay + nbDayCor);
               fprintf('WARNING: Float #%d Cycle #%d: new value for ''Day of first descent'' = %s (instead of %s)\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, newRefDate(1:10), oldRefDate(1:10));
               msgDates = msgDates + nbDayCor;
               break
            end
         end
      end
   end
end

if (isempty(parkDateHour))
   fprintf('DEC_ERROR: Float #%d Cycle #%d: unable to determine drift measurements dates\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
end

% check number of drift measurements done by the float
if (a_nbDriftMeas ~= length(parkDateHour))
   if (a_nbDriftMeas < length(parkDateHour))
      fprintf('DEC_INFO: Float #%d Cycle #%d: number of drift measurements: done (%d) < theoretical (%d)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_nbDriftMeas, length(parkDateHour));
   else
      fprintf('DEC_ERROR: Float #%d Cycle #%d: number of drift measurements: done (%d) > theoretical (%d) - unable to date %d drift measurements\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_nbDriftMeas, length(parkDateHour), a_nbDriftMeas-length(parkDateHour));
   end
end

% output NetCDF files
if (g_decArgo_generateNcTech ~= 0)
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 321];
   g_decArgo_outputNcParamValue{end+1} = size(a_tabDrifCTD, 1);
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 323];
   g_decArgo_outputNcParamValue{end+1} = sum(msgNbMeas);
end

% generate array of drift measurements
o_parkOcc = zeros(length(parkDateHour), 1);
o_parkTransDate = zeros(length(parkDateHour), 1);
o_parkPres = ones(length(parkDateHour), 1)*g_decArgo_presCountsDef;
o_parkTemp = ones(length(parkDateHour), 1)*g_decArgo_tempCountsDef;
o_parkSal = ones(length(parkDateHour), 1)*g_decArgo_salCountsDef;

% fill drift measurement arrays
[~, idSort] = sort(msgDates);
for id = 1:size(a_tabDrifCTD, 1)
   idMsg = idSort(id);
   msgOcc = a_tabDrifCTD(idMsg, 1);

   % find the right place and store drift measurement
   firstMesDate = msgDates(idMsg)*24;

   idCurMes = find(parkDateHour == firstMesDate);
   if (~isempty(idCurMes))
      for idMes = 1:a_tabDrifCTD(idMsg, 4)
         parkPres = a_tabDrifCTD(idMsg, 5+idMes-1);
         parkPresOk = a_tabDrifCTD(idMsg, 12+idMes-1);
         parkTemp = a_tabDrifCTD(idMsg, 19+idMes-1);
         parkSal = a_tabDrifCTD(idMsg, 26+idMes-1);
         if ~((parkPres == 0) && (parkTemp == 0) && (parkSal == 0))
            if (idCurMes == -1)
               fprintf('DEC_ERROR: Float #%d Cycle #%d: this should never happen!\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum);
               return
            end

            o_parkOcc(idCurMes) = msgOcc;
            if (idMes == 1)
               o_parkTransDate(idCurMes) = 1;
            else
               o_parkTransDate(idCurMes) = 0;
            end
            if (parkPresOk == 0)
               parkPres = g_decArgo_presCountsDef;
            end
            o_parkPres(idCurMes) = parkPres;
            o_parkTemp(idCurMes) = parkTemp;
            o_parkSal(idCurMes) = parkSal;

            idCurMes = idCurMes + 2;
            if (idCurMes > length(parkDateHour))
               if (length(parkDateHour) > 1)
                  idCurMes = 2;
               else
                  idCurMes = -1;
               end
            end
         end
      end
   else
      fprintf('DEC_ERROR: Float #%d Cycle #%d: unable to determine drift measurements dates - unable to define drift measurements order\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      return
   end
end
o_parkDate = parkDateHour/24;

return
