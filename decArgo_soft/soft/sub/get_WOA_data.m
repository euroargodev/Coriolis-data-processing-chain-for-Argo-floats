% ------------------------------------------------------------------------------
% Retrieve data from World Ocean Atlas.
%
% SYNTAX :
%  [o_profInfo] = get_WOA_data(a_profInfo)
%
% INPUT PARAMETERS :
%   a_profInfo : input data
%
% OUTPUT PARAMETERS :
%   o_profInfo : output updated data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/28/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profInfo] = get_WOA_data(a_profInfo)

% WOA file path name
global g_decArgo_woaFile;

% output parameters initialization
o_profInfo = [];


% check that World Ocean Atlas is available
WOA_FILE_NAME = g_decArgo_woaFile;
if ~(exist(WOA_FILE_NAME, 'file') == 2)
   fprintf('ERROR: World Ocean Atlas file not found: %s - NITRATE data cannot be adjusted\n', WOA_FILE_NAME);
   return
end

% retrieve data from WOA file
wantedVars = [ ...
   {'time'} ...
   {'depth'} ...
   {'lat'} ...
   {'lon'} ...
   {'n_an'} ...
   ];
woaData = get_data_from_nc_file(WOA_FILE_NAME, wantedVars);

woaTime = get_data_from_name('time', woaData);
woaDepth = get_data_from_name('depth', woaData);
woaLat = get_data_from_name('lat', woaData);
woaLon = get_data_from_name('lon', woaData);
woaNan = get_data_from_name('n_an', woaData);

% retrieve information from WOA file
wantedVarAtts = [ ...
   {'n_an'} {'_FillValue'} ...
   ];

woaDataAtt = get_att_from_nc_file(WOA_FILE_NAME, wantedVarAtts);

woaFillValue = get_att_from_name('n_an', '_FillValue', woaDataAtt);

if (length(woaTime) ~= 1)
   fprintf('ERROR: Time is expected to be unique in World Ocean Atlas file: %s - NITRATE data cannot be adjusted\n', WOA_FILE_NAME);
   return
end

% for idProf = 1:size(a_profInfo, 1)
%    profInfo = a_profInfo(idProf, :);
%    if (profInfo(10) == 1)
%       [~, idDepth] = min(abs(woaDepth-profInfo(7)));
%       [~, idLat] = min(abs(woaLat-profInfo(6)));
%       [~, idLon] = min(abs(woaLon-profInfo(5)));
%       if (woaNan(idLon, idLat, idDepth) ~= woaFillValue)
%          a_profInfo(idProf, 9) = woaNan(idLon, idLat, idDepth);
%       end
%    end
% end

% for idProf = 1:size(a_profInfo, 1)
%    profInfo = a_profInfo(idProf, :);
%    if (profInfo(10) == 1)
%       [~, idDepth] = min(abs(woaDepth-profInfo(7)));
%       tabRes = [];
%       for idLon = 1:length(woaLon)
%          for idLat = 1:length(woaLat)
%             if (woaNan(idLon, idLat, idDepth) ~= woaFillValue)
%                dist = distance_lpo([profInfo(6) woaLat(idLat)], [profInfo(5) woaLon(idLon)]);
%                tabRes = [tabRes; ...
%                   idLon idLat woaNan(idLon, idLat, idDepth) dist];
%             end
%          end
%       end
%       if (~isempty(tabRes))
%          [~, idMin] = min(tabRes(:, 4));
%          a_profInfo(idProf, 9) = tabRes(idMin, 3);
%       end
%    end
% end

for idProf = 1:size(a_profInfo, 1)
   profInfo = a_profInfo(idProf, :);
   if (profInfo(10) == 1)
      [~, idDepth] = min(abs(woaDepth-profInfo(7)));
      [~, idLat] = min(abs(woaLat-profInfo(6)));
      [~, idLon] = min(abs(woaLon-profInfo(5)));
      noFillValFoundFlag = 0;
      STEP = 0;
      while (~noFillValFoundFlag && (STEP < 180))
         idLatList = idLat-STEP:idLat+STEP;
         idLatList(find((idLatList < 1) | (idLatList > length(woaLat)))) = [];
         idLonList = idLon-STEP:idLon+STEP;
         idLonList(find(idLonList > 360)) = idLonList(find(idLonList > 360)) - 360;
         idLonList(find(idLonList < 1)) = idLonList(find(idLonList < 1)) + 360;
         tabRes = [];
         for idLt = idLatList
            for idLn = idLonList
               if (woaNan(idLn, idLt, idDepth) ~= woaFillValue)
                  dist = distance_lpo([profInfo(6) woaLat(idLt)], [profInfo(5) woaLon(idLn)]);
                  tabRes = [tabRes;  woaNan(idLn, idLt, idDepth) dist];
               end
            end
         end
         if (~isempty(tabRes))
            [~, idMin] = min(tabRes(:, 2));
            a_profInfo(idProf, 9) = tabRes(idMin, 1);
            noFillValFoundFlag = 1;
            %             fprintf('WOA_NITRATE(PRES_WOA) value found with STEP = %d\n', STEP);
         end
         STEP = STEP + 1;
      end
   end
end

% update output parameters
o_profInfo = a_profInfo;

return
