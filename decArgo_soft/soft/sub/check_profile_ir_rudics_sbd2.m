% ------------------------------------------------------------------------------
% In case of buffer anomaly we set JULD_QC and POSITION_QC to '3'.
%
% SYNTAX :
%  [o_tabProfiles] = check_profile_ir_rudics_sbd2(a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_tabProfiles   : input profile structures
%
% OUTPUT PARAMETERS :
%   o_tabProfiles   : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/12/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = check_profile_ir_rudics_sbd2(a_tabProfiles)

% output parameters initialization
o_tabProfiles = a_tabProfiles;

% current float WMO number
global g_decArgo_floatNum;

% QC flag values (char)
global g_decArgo_qcStrCorrectable;


% collect information on profiles
profInfo = [];
for idProf = 1:length(a_tabProfiles)
   profile = a_tabProfiles(idProf);
   direction = 2;
   if (profile.direction == 'D')
      direction = 1;
   end
   profInfo = [profInfo; ...
      [profile.outputCycleNumber direction profile.sensorNumber]];
end

if (~isempty(profInfo))
   
   % check that we have at most 2 profiles for sensor #0 and #1 and 1 profile
   % for other sensors
   uOutputCycleNumber = sort(unique(profInfo(:, 1)));
   uDirection = sort(unique(profInfo(:, 2)));
   for idCy = 1:length(uOutputCycleNumber)
      for idDir = 1:length(uDirection)
         cycNum = uOutputCycleNumber(idCy);
         direct = uDirection(idDir);
         
         idF = find((profInfo(:, 1) == cycNum) & (profInfo(:, 2) == direct));
         if (~isempty(idF))
            sensorNumbers = profInfo(idF, 3);
            anomaly = 0;
            for sensorNum = 0:max(sensorNumbers);
               idFS = find(sensorNumbers == sensorNum);
               if ((((sensorNum == 0) || (sensorNum == 0) )&& (length(idFS) > 2)) || ...
                     ((sensorNum > 1) && (length(idFS) > 1)))
                  anomaly = 1;
                  break
               end
            end
            if (anomaly == 1)
               [a_tabProfiles(idF).dateQc] = deal(g_decArgo_qcStrCorrectable);
               [a_tabProfiles(idF).locationQc] = deal(g_decArgo_qcStrCorrectable);
               
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d Output Cycle #%d Direction ''%c'': multiple profiles mixed - JULD_QC and POSITION_QC set to ''3''\n', ...
                  g_decArgo_floatNum, ...
                  a_tabProfiles(idF(1)).cycleNumber, ...
                  a_tabProfiles(idF(1)).profileNumber, ...
                  a_tabProfiles(idF(1)).outputCycleNumber, ...
                  a_tabProfiles(idF(1)).direction);
            end
         end
      end
   end
end

% update output parameters
o_tabProfiles = a_tabProfiles;

return
