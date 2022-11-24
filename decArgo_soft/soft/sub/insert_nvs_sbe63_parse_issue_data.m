% ------------------------------------------------------------------------------
% Insert SBE 63 recovered data (lost in .msg file because of parsing issue but
% recovered from .log file) in drift or LR profiles.
%
% SYNTAX :
%  [o_driftData, o_profLrData] = insert_nvs_sbe63_parse_issue_data( ...
%    a_driftData, a_profLrData, a_sbe63ParseIssueData)
%
% INPUT PARAMETERS :
%   a_driftData           : input drift data profile
%   a_profLrData          : input LR data profile
%   a_sbe63ParseIssueData : recovered SBE63 data
%
% OUTPUT PARAMETERS :
%   o_driftData  : updated drift data profile
%   o_profLrData : updated LR data profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftData, o_profLrData] = insert_nvs_sbe63_parse_issue_data( ...
   a_driftData, a_profLrData, a_sbe63ParseIssueData)

% output parameters initialization
o_driftData = a_driftData;
o_profLrData = a_profLrData;


idDriftPhaseDelayDoxy  = find(strcmp({o_driftData.paramList.name}, 'PHASE_DELAY_DOXY2') == 1, 1);
idDriftTempDoxy2 = find(strcmp({o_driftData.paramList.name}, 'TEMP_DOXY2') == 1, 1);
idProfPhaseDelayDoxy  = find(strcmp({o_profLrData.paramList.name}, 'PHASE_DELAY_DOXY2') == 1, 1);
idProfTempDoxy2 = find(strcmp({o_profLrData.paramList.name}, 'TEMP_DOXY2') == 1, 1);
idSbe63PhaseDelayDoxy  = find(strcmp({a_sbe63ParseIssueData.paramList.name}, 'PHASE_DELAY_DOXY2') == 1, 1);
idSbe63TempDoxy2 = find(strcmp({a_sbe63ParseIssueData.paramList.name}, 'TEMP_DOXY2') == 1, 1);

idDriftDef = find((o_driftData.data(:, idDriftPhaseDelayDoxy) == o_driftData.paramList(idDriftPhaseDelayDoxy).fillValue) & ...
   (o_driftData.data(:, idDriftTempDoxy2) == o_driftData.paramList(idDriftTempDoxy2).fillValue));
for idM = 1:length(idDriftDef)
   idDriftLev = dsearchn(a_sbe63ParseIssueData.dates+12/86400, o_driftData.dates(idDriftDef(idM)));
   if (abs(o_driftData.dates(idDriftDef(idM))-(a_sbe63ParseIssueData.dates(idDriftLev)+12/86400))*86400 <= 5)
      o_driftData.data(idDriftDef(idM), idDriftPhaseDelayDoxy) = a_sbe63ParseIssueData.data(idDriftLev, idSbe63PhaseDelayDoxy);
      o_driftData.data(idDriftDef(idM), idDriftTempDoxy2) = a_sbe63ParseIssueData.data(idDriftLev, idSbe63TempDoxy2);
      %    else
      %       fprintf('drift: %.1f\n', (a_sbe63ParseIssueData.dates(idDriftLev)-o_driftData.dates(idDriftDef(idM)))*86400);
   end
end

idProfDef = find((o_profLrData.data(:, idProfPhaseDelayDoxy) == o_profLrData.paramList(idProfPhaseDelayDoxy).fillValue) & ...
   (o_profLrData.data(:, idProfTempDoxy2) == o_profLrData.paramList(idProfTempDoxy2).fillValue));
for idM = 1:length(idProfDef)
   idProfLev = dsearchn(a_sbe63ParseIssueData.dates-12/86400, o_profLrData.dates(idProfDef(idM)));
   if (abs(o_profLrData.dates(idProfDef(idM))-(a_sbe63ParseIssueData.dates(idProfLev)-12/86400))*86400 <= 5)
      o_profLrData.data(idProfDef(idM), idProfPhaseDelayDoxy) = a_sbe63ParseIssueData.data(idProfLev, idSbe63PhaseDelayDoxy);
      o_profLrData.data(idProfDef(idM), idProfTempDoxy2) = a_sbe63ParseIssueData.data(idProfLev, idSbe63TempDoxy2);
      %    else
      %       fprintf('prof: %.1f\n', (a_sbe63ParseIssueData.dates(idProfLev)-o_profLrData.dates(idProfDef(idM)))*86400);
   end
end

return;
