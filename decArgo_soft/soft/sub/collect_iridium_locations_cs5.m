% ------------------------------------------------------------------------------
% Retrieve and store Iridium locations of few floats that are located with
% Iridium system because of and issue on their GPS receiver.
%
% SYNTAX :
%  collect_iridium_locations_cs5
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/15/2023 - RNU - creation
% ------------------------------------------------------------------------------
function collect_iridium_locations_cs5

% current float WMO number
global g_decArgo_floatNum;

% json meta-data
global g_decArgo_jsonMetaData;

% SBD sub-directories
global g_decArgo_archiveDirectory;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;

% array to store USEA technical data
global g_decArgo_useaTechData;

% existing cycle and pattern numbers
global g_decArgo_cyclePatternNumFloat;


% retrieve float IMEI
if (isfield(g_decArgo_jsonMetaData, 'IMEI') && ...
      length(strtrim(g_decArgo_jsonMetaData.IMEI)) == 15)
   floatImei = strtrim(g_decArgo_jsonMetaData.IMEI);
else
   fprintf('ERROR: Float #%d: unable to retrieve IMEI number in JSON meta-data\n', ...
      g_decArgo_floatNum);
   return
end

% read mail files and store Iridium locations
mailFiles = dir([g_decArgo_archiveDirectory '/' sprintf('co*_%s_*.txt', floatImei)]);
mailContentsTab = repmat(get_iridium_mail_init_struct(''), 1, length(mailFiles));
cptMailCont = 1;
for idFile = 1:length(mailFiles)
   mailFileName = mailFiles(idFile).name;

   [mailContents, ~] = read_mail_and_extract_attachment( ...
      mailFileName, g_decArgo_archiveDirectory, '');
   if (~isempty(mailContents))
      mailContentsTab(cptMailCont) = mailContents;
      cptMailCont = cptMailCont + 1;
   end
end
mailContentsTab(cptMailCont:end) = [];
g_decArgo_iridiumMailData = [g_decArgo_iridiumMailData mailContentsTab];

if (~isempty(g_decArgo_iridiumMailData) && ~isempty(g_decArgo_useaTechData))

   % collect surface times
   cyPtnSurfJuld = nan(size(g_decArgo_cyclePatternNumFloat, 1), 3);
   cyPtnSurfJuld(:, 1:2) = g_decArgo_cyclePatternNumFloat;
   for idCyPat = 1:size(g_decArgo_cyclePatternNumFloat, 1)
      floatCyNum = g_decArgo_cyclePatternNumFloat(idCyPat, 1);
      floatPtnNum = g_decArgo_cyclePatternNumFloat(idCyPat, 2);
      idF = find(([g_decArgo_useaTechData{:, 1}] == floatCyNum) & ([g_decArgo_useaTechData{:, 2}] == floatPtnNum));
      for id = 1:length(idF)
         apmtTimeFromTech = g_decArgo_useaTechData{idF(id), 5};
         if (~isempty(apmtTimeFromTech))
            apmtTimeFromTech = [apmtTimeFromTech{:}];
            idF2 = find(strcmp({apmtTimeFromTech.label}, 'FINAL PUMP ACTION START TIME'));
            if (~isempty(idF2))
               cyPtnSurfJuld(idCyPat, 3) = apmtTimeFromTech(idF2).time;
            else
               idF2 = find(strcmp({apmtTimeFromTech.label}, 'ASCENT END TIME'));
               if (~isempty(idF2))
                  cyPtnSurfJuld(idCyPat, 3) = apmtTimeFromTech(idF2).time;
               end
            end
         end
      end
   end
   cyPtnSurfJuld(isnan(cyPtnSurfJuld(:, 3)), :) = [];

   % assign cycle and profile number to each Iridium location
   for idL = 1:length(g_decArgo_iridiumMailData)
      locJuld = g_decArgo_iridiumMailData(idL).timeOfSessionJuld;
      idF = find(locJuld >= cyPtnSurfJuld(:, 3), 1, 'last');
      if (~isempty(idF))
         g_decArgo_iridiumMailData(idL).floatCycleNumber = cyPtnSurfJuld(idF, 1);
         g_decArgo_iridiumMailData(idL).floatProfileNumber = cyPtnSurfJuld(idF, 2);
      end
   end
end

return
