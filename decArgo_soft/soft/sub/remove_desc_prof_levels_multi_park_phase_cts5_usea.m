% ------------------------------------------------------------------------------
% During multi-park drift phase, descending measurement can be sampled and
% stored in descending profile. Remove these measurements.
%
% SYNTAX :
%   [o_tabProfiles] = remove_desc_prof_levels_multi_park_phase_cts5_usea(a_tabProfiles, a_tabTrajNCycle)
%
% INPUT PARAMETERS :
%   a_tabProfiles   : input profile structures
%   a_tabTrajNCycle : N_CYCLE trajectory data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles  : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%  07/08/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = remove_desc_prof_levels_multi_park_phase_cts5_usea(a_tabProfiles, a_tabTrajNCycle)

% output parameters initialization
o_tabProfiles = a_tabProfiles;


if (isempty(o_tabProfiles))
   return
end

if (any([o_tabProfiles.direction] == 'D'))

   profDescId = find([o_tabProfiles.direction] == 'D');
   for idProf = profDescId
      prof = o_tabProfiles(idProf);
      [configNames, configValues] = get_float_config_ir_rudics_sbd2(prof.cycleNumber, prof.profileNumber);

      % if CONFIG_APMT_PATTERN_01_P01 == Nan we are in multi park mode
      confName = 'CONFIG_APMT_PATTERN_01_P01';
      confId = find(strcmp(confName, configNames), 1);
      if (any(isnan(configValues(confId, :))))
         idTrajList = find([a_tabTrajNCycle.outputCycleNumber] == prof.outputCycleNumber);
         for idTraj = idTrajList
            if (~isempty(a_tabTrajNCycle(idTraj).juldParkStart))
               idToDel = find(prof.dates > a_tabTrajNCycle(idTraj).juldParkStart);
               if (~isempty(idToDel))
                  prof.data(idToDel, :) = [];
                  if (~isempty(prof.dataQc))
                     prof.dataQc(idToDel, :) = [];
                  end
                  if (~isempty(prof.dataAdj))
                     prof.dataAdj(idToDel, :) = [];
                  end
                  if (~isempty(prof.dataAdjQc))
                     prof.dataAdjQc(idToDel, :) = [];
                  end
                  if (~isempty(prof.dataAdjError))
                     prof.dataAdjError(idToDel, :) = [];
                  end
                  if (~isempty(prof.ptsForDoxy))
                     prof.ptsForDoxy(idToDel, :) = [];
                  end
                  if (~isempty(prof.rmsError))
                     prof.rmsError(idToDel) = [];
                  end
                  if (~isempty(prof.dates))
                     prof.dates(idToDel) = [];
                  end
                  if (~isempty(prof.datesAdj))
                     prof.datesAdj(idToDel) = [];
                  end

                  o_tabProfiles(idProf) = prof;
               end
            end
         end
      end
   end
end

return
