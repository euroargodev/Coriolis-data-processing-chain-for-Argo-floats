% ------------------------------------------------------------------------------
% Retrieve data from World Ocean Atlas 2013 (file woa13_all_n00_01.nc which
% should be in the Matlab path).
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
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/28/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profInfo] = get_WOA_data(a_profInfo)

% output parameters initialization
o_profInfo = [];


% check that World Ocean Atlas 2013 is available in the Matlab path
WOA_FILE_NAME = 'woa13_all_n00_01.nc';
if ~(exist(WOA_FILE_NAME, 'file') == 2)
   fprintf('ERROR: World Ocean Atlas 2013 file not found in the Matlab path: %s => NITRATE data cannot be adjusted\n', WOA_FILE_NAME);
   return;
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
   fprintf('ERROR: Time is expected to be unique in World Ocean Atlas 2013 file: %s => NITRATE data cannot be adjusted\n', WOA_FILE_NAME);
   return;
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

return;

% ------------------------------------------------------------------------------
% Get data from name in a {var_name}/{var_data} list.
%
% SYNTAX :
%  [o_dataValues] = get_data_from_name(a_dataName, a_dataList)
%
% INPUT PARAMETERS :
%   a_dataName : name of the data to retrieve
%   a_dataList : {var_name}/{var_data} list
%
% OUTPUT PARAMETERS :
%   o_dataValues : concerned data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/28/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataValues] = get_data_from_name(a_dataName, a_dataList)

% output parameters initialization
o_dataValues = [];

idVal = find(strcmp(a_dataName, a_dataList(1:2:end)) == 1, 1);
if (~isempty(idVal))
   o_dataValues = a_dataList{2*idVal};
end

return;

% ------------------------------------------------------------------------------
% Retrieve data from NetCDF file.
%
% SYNTAX :
%  [o_ncDataAtt] = get_att_from_nc_file(a_ncPathFileName, a_wantedVarAtts)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%   a_wantedVarAtts  : NetCDF variable names and attribute names to retrieve
%                      from the file
%
% OUTPUT PARAMETERS :
%   o_ncDataAtt : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncDataAtt] = get_att_from_nc_file(a_ncPathFileName, a_wantedVarAtts)

% output parameters initialization
o_ncDataAtt = [];


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return;
   end
   
   % retrieve attributes from NetCDF file
   for idVar = 1:2:length(a_wantedVarAtts)
      varName = a_wantedVarAtts{idVar};
      attName = a_wantedVarAtts{idVar+1};
      
      if (var_is_present_dec_argo(fCdf, varName) && att_is_present_dec_argo(fCdf, varName, attName))
         attValue = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, varName), attName);
         o_ncDataAtt = [o_ncDataAtt {varName} {attName} {attValue}];
      else
         o_ncDataAtt = [o_ncDataAtt {varName} {attName} {' '}];
      end
      
   end
   
   netcdf.close(fCdf);
end

return;

% ------------------------------------------------------------------------------
% Get attribute data from variable name and attribute in a
% {var_name}/{var_att}/{att_data} list.
%
% SYNTAX :
%  [o_dataValues] = get_att_from_name(a_varName, a_attName, a_dataList)
%
% INPUT PARAMETERS :
%   a_varName : name of the variable
%   a_attName : name of the attribute
%   a_dataList : {var_name}/{var_att}/{att_data} list
%
% OUTPUT PARAMETERS :
%   o_dataValues : concerned data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataValues] = get_att_from_name(a_varName, a_attName, a_dataList)

% output parameters initialization
o_dataValues = [];

idVal = find(strcmp(a_varName, a_dataList(1:3:end)) & strcmp(a_attName, a_dataList(2:3:end)));
if (~isempty(idVal))
   o_dataValues = a_dataList{3*idVal};
end

return;
