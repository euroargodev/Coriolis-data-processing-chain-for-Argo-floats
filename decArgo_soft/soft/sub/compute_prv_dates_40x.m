% ------------------------------------------------------------------------------
% Compute the main dates of an ARVOR float cycle.
%
% SYNTAX :
% o_cycleTimeData = compute_prv_dates_40x(a_selfTest, a_tech1, a_tech2, a_eol, a_cycleNum)
%
% INPUT PARAMETERS :
%   a_selfTest : self test tech data
%   a_tech1    : tech #1 data
%   a_tech2    : tech #2 data
%   a_eol      : EOL tech data
%   a_cycleNum : cycle number
%
% OUTPUT PARAMETERS :
%   o_cycleTimeData : cycle timings structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/24/2024 - RNU - creation
% ------------------------------------------------------------------------------
function o_cycleTimeData = compute_prv_dates_40x(a_selfTest, a_tech1, a_tech2, a_eol, a_cycleNum)

% output parameters initialization
o_cycleTimeData = get_prv_ir_float_time_init_struct(a_cycleNum);

% TET management
global g_decArgo_transTimes;

% times and information to be set
cycleStartTime = nan;
descentToParkStartTime = nan;
firstStabTime = nan;
firstStabPres = nan;
descentToParkEndTime = nan;
descentToProfStartTime = nan;
descentToProfEndTime = nan;
ascentStartTime = nan;
ascentEndTime = nan;
transStartTime = nan;
transEndTimePrevCy = nan;
gpsTime = [];
groundingTime = [];
groundingPres = [];
groundingOil = [];
eolStartTime = [];
emergencyAscentTime = [];
emergencyAscentPres = [];

for file = 1:4
   if (file == 1)
      inputData = a_selfTest;
   elseif (file == 2)
      inputData = a_tech2;
   elseif (file == 3)
      inputData = a_tech1;
   elseif (file == 4)
      inputData = a_eol;
   end

   for idL = 1:size(inputData, 1)      

      techData = inputData{idL, 1};
      techTimeData = inputData{idL, 2};
      techTrajData = inputData{idL, 3};

      if (file == 2)
         cycleStartTime = get_traj_juld(techTrajData, 100000);
         descentToParkStartTime = get_traj_juld(techTrajData, 100100);
         [firstStabTime, firstStabPres] = get_traj_juld_pres(techTrajData, 800000);
         descentToParkEndTime = get_traj_juld(techTrajData, 100500);
         descentToProfStartTime = get_traj_juld(techTrajData, 100900);
         descentToProfEndTime = get_traj_juld(techTrajData, 100700);
         ascentStartTime = get_traj_juld(techTrajData, 101100);
         ascentEndTime = get_traj_juld(techTrajData, 101300);
         transStartTime = get_traj_juld(techTrajData, 101600);
         transEndTimePrevCy = get_tech_juld(techData, 700100);

         % store information to manage TET
         g_decArgo_transTimes.cycleNum = [g_decArgo_transTimes.cycleNum a_cycleNum];
         g_decArgo_transTimes.techNum = [g_decArgo_transTimes.techNum 2];
         g_decArgo_transTimes.transStartTime = [g_decArgo_transTimes.transStartTime transStartTime];
         g_decArgo_transTimes.transStartTimeAdj = [g_decArgo_transTimes.transStartTimeAdj nan];
         g_decArgo_transTimes.transEndTimePrevCy = [g_decArgo_transTimes.transEndTimePrevCy transEndTimePrevCy];
         g_decArgo_transTimes.transEndTimePrevCyAdj = [g_decArgo_transTimes.transEndTimePrevCyAdj transEndTimePrevCy];
      end

      if (file == 3)
         transStartTime2 = get_traj_juld(techTrajData, 101600);
         transEndTimePrevCy2 = get_tech_juld(techData, 700100);

         % store information to manage TET
         g_decArgo_transTimes.cycleNum = [g_decArgo_transTimes.cycleNum a_cycleNum];
         g_decArgo_transTimes.techNum = [g_decArgo_transTimes.techNum 1];
         g_decArgo_transTimes.transStartTime = [g_decArgo_transTimes.transStartTime transStartTime2];
         g_decArgo_transTimes.transStartTimeAdj = [g_decArgo_transTimes.transStartTimeAdj transStartTime2];
         g_decArgo_transTimes.transEndTimePrevCy = [g_decArgo_transTimes.transEndTimePrevCy transEndTimePrevCy2];
         g_decArgo_transTimes.transEndTimePrevCyAdj = [g_decArgo_transTimes.transEndTimePrevCyAdj nan];
      end

      idLoc = find([techTrajData.techId] == 700000);
      idValid = find([techTimeData.techId] == 700004);
      idClockOffset = find([techTimeData.techId] == 700008);
      for idP = 1:length(idLoc)
         if (techTimeData(idValid(idP)).value)
            gpsTime = [gpsTime; techTrajData(idLoc(idP)).julD];

            % store clock offset
            % clock offset is relevant only on a valid GPS fix
            % only use TECH #2 information (TECH #1 is not relevant < 1 sec)
            if (file ~= 3)
               store_clock_offset_prv_ir(a_cycleNum, techTrajData(idLoc(idP)).julD, techTimeData(idClockOffset(idP)).value);
            end
         end
      end

      [grdTime, grdPres, grdOil] = get_traj_juld_pres_oil(techTrajData, 200000);
      if (~isnan(grdTime))
         groundingTime = [groundingTime; grdTime'];
         groundingPres = [groundingPres; grdPres'];
         groundingOil = [groundingOil; grdOil'];
      end

      eolTime = get_tech_juld(techData, 101900);
      if (~isnan(eolTime))
         eolStartTime = [eolStartTime eolTime];
      end

      eAscentTime = get_tech_juld(techData, 101700);
      if (~isnan(eAscentTime))
         emergencyAscentTime = [emergencyAscentTime eAscentTime];
         emergencyAscentPres = [emergencyAscentPres str2double(get_tech_value(techData, 101701))];
      end
   end
end

% fill output structure
o_cycleTimeData.cycleStartDate = cycleStartTime;
o_cycleTimeData.cycleStartDateAdj = nan;
o_cycleTimeData.descentToParkStartDate = descentToParkStartTime;
o_cycleTimeData.descentToParkStartDateAdj = nan;
o_cycleTimeData.firstStabDate = firstStabTime;
o_cycleTimeData.firstStabDateAdj = nan;
o_cycleTimeData.firstStabPres = firstStabPres;
o_cycleTimeData.descentToParkEndDate = descentToParkEndTime;
o_cycleTimeData.descentToParkEndDateAdj = nan;
o_cycleTimeData.descentToProfStartDate = descentToProfStartTime;
o_cycleTimeData.descentToProfStartDateAdj = nan;
o_cycleTimeData.descentToProfEndDate = descentToProfEndTime;
o_cycleTimeData.descentToProfEndDateAdj = nan;
o_cycleTimeData.ascentStartDate = ascentStartTime;
o_cycleTimeData.ascentStartDateAdj = nan;
o_cycleTimeData.ascentEndDate = ascentEndTime;
if (isnan(ascentEndTime) && ~isempty(emergencyAscentTime))
   o_cycleTimeData.ascentEndDate = emergencyAscentTime(1);
end
o_cycleTimeData.ascentEndDateAdj = nan;
o_cycleTimeData.transStartDate = transStartTime;
o_cycleTimeData.transStartDateAdj = nan;
o_cycleTimeData.transEndDate = nan;
o_cycleTimeData.transEndDateAdj = nan;
o_cycleTimeData.transEndDateCyPrev = transEndTimePrevCy;
o_cycleTimeData.transEndDateCyPrevAdj = nan;
o_cycleTimeData.gpsDate = gpsTime;
o_cycleTimeData.eolStartDate = eolStartTime;
o_cycleTimeData.eolStartDateAdj = nan(size(eolStartTime));
o_cycleTimeData.groundingDate = groundingTime;
o_cycleTimeData.groundingDateAdj = nan(size(groundingTime));
o_cycleTimeData.groundingPres = groundingPres;
o_cycleTimeData.groundingOil = groundingOil;
o_cycleTimeData.emergencyAscentDate = emergencyAscentTime;
o_cycleTimeData.emergencyAscentDateAdj = nan(size(emergencyAscentTime));
o_cycleTimeData.emergencyAscentPres = emergencyAscentPres;
o_cycleTimeData.iceAscentAbortedFlag = 0;

% print = 0;
% if (print == 1)
% 
%    fprintf('Float #%d cycle #%d:\n', ...
%       g_decArgo_floatNum, g_decArgo_cycleNum);
%    if (~isnan(cycleStartTime))
%       fprintf('CYCLE START DATE              : %s\n', ...
%          julian_2_gregorian_dec_argo(cycleStartTime));
%    else
%       fprintf('CYCLE START DATE              : UNDEF\n');
%    end
%    if (~isnan(descentToParkStartTime))
%       fprintf('DESCENT TO PARK START DATE    : %s\n', ...
%          julian_2_gregorian_dec_argo(descentToParkStartTime));
%    else
%       fprintf('DESCENT TO PARK START DATE    : UNDEF\n');
%    end
%    if (~isnan(firstStabTime))
%       fprintf('FIRST STAB DATE               : %s (%.1f dbar)\n', ...
%          julian_2_gregorian_dec_argo(firstStabTime), firstStabPres);
%    else
%       fprintf('FIRST STAB DATE               : UNDEF\n');
%    end
%    if (~isnan(descentToParkEndTime))
%       fprintf('DESCENT TO PARK END DATE      : %s\n', ...
%          julian_2_gregorian_dec_argo(descentToParkEndTime));
%    else
%       fprintf('DESCENT TO PARK END DATE      : UNDEF\n');
%    end
%    if (~isnan(descentToProfStartTime))
%       fprintf('DESCENT TO PROF START DATE    : %s\n', ...
%          julian_2_gregorian_dec_argo(descentToProfStartTime));
%    else
%       fprintf('DESCENT TO PROF START DATE    : UNDEF\n');
%    end
%    if (~isnan(descentToProfEndTime))
%       fprintf('DESCENT TO PROF END DATE      : %s\n', ...
%          julian_2_gregorian_dec_argo(descentToProfEndTime));
%    else
%       fprintf('DESCENT TO PROF END DATE      : UNDEF\n');
%    end
%    if (~isnan(ascentStartTime))
%       fprintf('ASCENT START DATE             : %s\n', ...
%          julian_2_gregorian_dec_argo(ascentStartTime));
%    else
%       fprintf('ASCENT START DATE             : UNDEF\n');
%    end
%    if (~isnan(ascentEndTime))
%       fprintf('ASCENT END DATE               : %s\n', ...
%          julian_2_gregorian_dec_argo(ascentEndTime));
%    else
%       fprintf('ASCENT END DATE               : UNDEF\n');
%    end
%    if (~isnan(transStartTime))
%       fprintf('TRANSMISSION START DATE       : %s\n', ...
%          julian_2_gregorian_dec_argo(transStartTime));
%    else
%       fprintf('TRANSMISSION START DATE       : UNDEF\n');
%    end
%    if (~isnan(transEndTimePrevCy))
%       fprintf('TRANSMISSION END DATE CY PREV : %s\n', ...
%          julian_2_gregorian_dec_argo(transEndTimePrevCy));
%    else
%       fprintf('TRANSMISSION END DATE CY PREV : UNDEF\n');
%    end
%    if (~isempty(gpsTime))
%       fprintf('GPS DATE                      : \n');
%       for id = 1:length(gpsTime)
%          fprintf('   #%d: %s\n', ...
%             id, julian_2_gregorian_dec_argo(gpsTime(id)));
%       end
%    else
%       fprintf('GPS DATE                      : UNDEF\n');
%    end
%    if (~isempty(groundingTime))
%       fprintf('GROUNDING DATE                      : \n');
%       for id = 1:length(groundingTime)
%          fprintf('   #%d: %s (%.1f dbar)\n', ...
%             id, julian_2_gregorian_dec_argo(groundingTime(id)), groundingPres(id));
%       end
%    end
%    if (~isempty(eolStartTime))
%       fprintf('EOL START DATE                      : \n');
%       for id = 1:length(eolStartTime)
%          fprintf('   #%d: %s\n', ...
%             id, julian_2_gregorian_dec_argo(eolStartTime(id)));
%       end
%    end
%    if (~isempty(emergencyAscentTime))
%       fprintf('EMERGENCY ASCENT DATE                      : \n');
%       for id = 1:length(emergencyAscentTime)
%          fprintf('   #%d: %s (%.1f dbar)\n', ...
%             id, julian_2_gregorian_dec_argo(emergencyAscentTime(id)), emergencyAscentPres(id));
%       end
%    end
% end

return

% ------------------------------------------------------------------------------
% Get TRAJ juld from techId.
%
% SYNTAX :
% [o_julD] = get_traj_juld(a_techTrajData, a_techId)
%
% INPUT PARAMETERS :
%   a_techTrajData : TRAJ data
%   a_techId       : tech Id
%
% OUTPUT PARAMETERS :
%   o_julD : julian day
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/25/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_julD] = get_traj_juld(a_techTrajData, a_techId)

% output parameters initialization
o_julD = nan;

idF = find([a_techTrajData.techId] == a_techId);
if (~isempty(idF))
   o_julD = a_techTrajData(idF).julD;
end

return

% ------------------------------------------------------------------------------
% Get TRAJ juld and PRES from techId.
%
% SYNTAX :
% [o_julD, o_pres] = get_traj_juld_pres(a_techTrajData, a_techId)
%
% INPUT PARAMETERS :
%   a_techTrajData : TRAJ data
%   a_techId       : tech Id
%
% OUTPUT PARAMETERS :
%   o_julD : julian day
%   o_pres : associated PRES
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/25/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_julD, o_pres] = get_traj_juld_pres(a_techTrajData, a_techId)

% output parameters initialization
o_julD = nan;
o_pres = nan;

idF = find([a_techTrajData.techId] == a_techId);
if (~isempty(idF))
   o_julD = a_techTrajData(idF).julD;
   o_pres = a_techTrajData(idF).pres;
end

return

% ------------------------------------------------------------------------------
% Get TRAJ juld, PRES and oil volume from techId.
%
% SYNTAX :
% [o_julD, o_pres, o_oil] = get_traj_juld_pres_oil(a_techTrajData, a_techId)
%
% INPUT PARAMETERS :
%   a_techTrajData : TRAJ data
%   a_techId       : tech Id
%
% OUTPUT PARAMETERS :
%   o_julD : julian day
%   o_pres : associated PRES
%   o_oil  : associated oil volume
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/01/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_julD, o_pres, o_oil] = get_traj_juld_pres_oil(a_techTrajData, a_techId)

% output parameters initialization
o_julD = nan;
o_pres = nan;
o_oil = nan;

idF = find([a_techTrajData.techId] == a_techId);
if (~isempty(idF))
   o_julD = a_techTrajData(idF).julD;
   o_pres = a_techTrajData(idF).pres;
   o_oil = a_techTrajData(idF).value;
end

return

% ------------------------------------------------------------------------------
% Get TECH value from techId.
%
% SYNTAX :
% [o_value] = get_tech_value(a_techData, a_techId)
%
% INPUT PARAMETERS :
%   a_techData : TECH data
%   a_techId   : tech Id
%
% OUTPUT PARAMETERS :
%   o_value : value
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/25/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = get_tech_value(a_techData, a_techId)

% output parameters initialization
o_value = nan;

idF = find([a_techData.techId] == a_techId);
if (~isempty(idF))
   o_value = a_techData(idF).value;
end

return

% ------------------------------------------------------------------------------
% Get TECH juld from techId.
%
% SYNTAX :
% [o_julD] = get_tech_juld(a_techData, a_techId)
%
% INPUT PARAMETERS :
%   a_techData : TECH data
%   a_techId   : tech Id
%
% OUTPUT PARAMETERS :
%   o_julD : julian day
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/25/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_julD] = get_tech_juld(a_techData, a_techId)

% output parameters initialization
o_julD = nan;

idF = find([a_techData.techId] == a_techId);
if (~isempty(idF))
   o_julD = a_techData(idF).julD;
end

return
