% ------------------------------------------------------------------------------
% Store NEMO .profile file information of a given section.
%
% SYNTAX :
%  [o_rafosData, o_profileData] = store_nemo_data(a_nemoData, a_sectionName)
%
% INPUT PARAMETERS :
%   a_nemoData    : NEMO data
%   a_sectionName : concerned section name in the .profile file
%
% OUTPUT PARAMETERS :
%   o_rafosData   : RAFOS data
%   o_profileData : profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/04/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_rafosData, o_profileData] = store_nemo_data(a_nemoData, a_sectionName)

% output parameters initialization
o_rafosData = [];
o_profileData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(a_nemoData))
   return
end

switch (a_sectionName)
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 'RAFOS_VALUES'
      
      juld = [];
      status = [];
      corData = nan(size(a_nemoData.paramValue, 1), 6);
      toaData = nan(size(a_nemoData.paramValue, 1), 6);
      pres = [];
      temp = [];
      psal = [];
      colNames = a_nemoData.paramName;
      for idC = 1:length(colNames)
         colName = colNames{idC};
         switch (colName)
            case 'rtcJulD'
               idF = find(strcmp(colName, colNames));
               juld = a_nemoData.paramValue(:, idF);
            case 'status'
               idF = find(strcmp(colName, colNames));
               status = a_nemoData.paramValue(:, idF);
            case '1STCORHEIGHT'
               idF = find(strcmp(colName, colNames));
               corData(:, 1) = a_nemoData.paramValue(:, idF);
            case '2NDCORHEIGHT'
               idF = find(strcmp(colName, colNames));
               corData(:, 2) = a_nemoData.paramValue(:, idF);
            case '3RDCORHEIGHT'
               idF = find(strcmp(colName, colNames));
               corData(:, 3) = a_nemoData.paramValue(:, idF);
            case '4THCORHEIGHT'
               idF = find(strcmp(colName, colNames));
               corData(:, 4) = a_nemoData.paramValue(:, idF);
            case '5THCORHEIGHT'
               idF = find(strcmp(colName, colNames));
               corData(:, 5) = a_nemoData.paramValue(:, idF);
            case '6THCORHEIGHT'
               idF = find(strcmp(colName, colNames));
               corData(:, 6) = a_nemoData.paramValue(:, idF);
            case '1STTRAVELTIME'
               idF = find(strcmp(colName, colNames));
               toaData(:, 1) = a_nemoData.paramValue(:, idF);
            case '2NDTRAVELTIME'
               idF = find(strcmp(colName, colNames));
               toaData(:, 2) = a_nemoData.paramValue(:, idF);
            case '3RDTRAVELTIME'
               idF = find(strcmp(colName, colNames));
               toaData(:, 3) = a_nemoData.paramValue(:, idF);
            case '4THTRAVELTIME'
               idF = find(strcmp(colName, colNames));
               toaData(:, 4) = a_nemoData.paramValue(:, idF);
            case '5THTRAVELTIME'
               idF = find(strcmp(colName, colNames));
               toaData(:, 5) = a_nemoData.paramValue(:, idF);
            case '6THTRAVELTIME'
               idF = find(strcmp(colName, colNames));
               toaData(:, 6) = a_nemoData.paramValue(:, idF);
            case 'pressure'
               idF = find(strcmp(colName, colNames));
               pres = a_nemoData.paramValue(:, idF);
            case 'salinity'
               idF = find(strcmp(colName, colNames));
               psal = a_nemoData.paramValue(:, idF);
            case 'temp'
               idF = find(strcmp(colName, colNames));
               temp = a_nemoData.paramValue(:, idF);
            otherwise
               fprintf('WARNING: Float #%d Cycle #%d: ''%s'' column of ''%s'' section not managed yet\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  colName, 'RAFOS_VALUES');
         end
      end
      
      if (~isempty(juld) && ~isempty(status) && ~isempty(pres) && ~isempty(temp) && ~isempty(psal))
         paramJuld = get_netcdf_param_attributes('JULD');
         paramPres = get_netcdf_param_attributes('PRES');
         paramTemp = get_netcdf_param_attributes('TEMP');
         paramSal = get_netcdf_param_attributes('PSAL');
         paramStatus = get_netcdf_param_attributes('RAFOS_STATUS');
         paramCor = get_netcdf_param_attributes('COR');
         paramToa = get_netcdf_param_attributes('TOA');
         
         % convert NaN values to netCDF fill values
         juld(find(isnan(juld))) = paramJuld.fillValue;
         pres(find(isnan(pres))) = paramPres.fillValue;
         temp(find(isnan(temp))) = paramTemp.fillValue;
         psal(find(isnan(psal))) = paramSal.fillValue;
         status(find(isnan(status))) = paramStatus.fillValue;
         corData(find(isnan(corData))) = paramCor.fillValue;
         toaData(find(isnan(toaData))) = paramToa.fillValue;
         
         idDel = find((juld == paramJuld.fillValue) & ...
            (sum(corData == paramCor.fillValue, 2) == size(corData, 2)) & ...
            (sum(toaData == paramToa.fillValue, 2) == size(toaData, 2)));
         juld(idDel) = [];
         pres(idDel) = [];
         temp(idDel) = [];
         psal(idDel) = [];
         status(idDel, :) = [];
         corData(idDel, :) = [];
         toaData(idDel, :) = [];

         o_rafosData = get_apx_profile_data_init_struct;
         o_rafosData.dateList = paramJuld;
         o_rafosData.dates = juld;
         o_rafosData.paramList = [paramPres paramTemp paramSal paramStatus paramCor paramToa];
         o_rafosData.data = [pres temp psal status corData toaData];
      else
         fprintf('ERROR: Float #%d Cycle #%d: anomaly in ''%s'' section\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            'RAFOS_VALUES');
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 'PROFILE_DATA'
      
      hour = [];
      minute = [];
      second = [];
      dataTime = [];
      colNames = a_nemoData.paramName;
      idF = find(strcmp('hour', colNames));
      if (~isempty(idF))
         hour = a_nemoData.paramValue(:, idF);
      end
      idF = find(strcmp('minute', colNames));
      if (~isempty(idF))
         minute = a_nemoData.paramValue(:, idF);
      end
      idF = find(strcmp('second', colNames));
      if (~isempty(idF))
         second = a_nemoData.paramValue(:, idF);
      end
      if (~isempty(hour) && ~isempty(minute) && ~isempty(second))
         dataTime = hour + minute/60 + second/3600;
         [dataTime, idSort] = sort(dataTime);
         while (any(diff(dataTime) > 12))
            idF = find(diff(dataTime) > 12);
            dataTime(idF) = dataTime(idF) + 24;
            [dataTime, idSort2] = sort(dataTime);
            idSort = idSort(idSort2);
         end
         a_nemoData.paramValue = a_nemoData.paramValue(idSort, :);
      end
      
      pres = [];
      temp = [];
      psal = [];
      light442 = [];
      light550 = [];
      light676 = [];
      for idC = 1:length(colNames)
         colName = colNames{idC};
         switch (colName)
            case {'#', 'hour', 'minute', 'second', 'temp_flag', 'pres_flag', 'sal_flag', 'temp_raw', 'pres_raw', 'sal_raw'}
            case 'temp'
               idF = find(strcmp(colName, colNames));
               temp = a_nemoData.paramValue(:, idF);
            case 'pressure'
               idF = find(strcmp(colName, colNames));
               pres = a_nemoData.paramValue(:, idF);
            case 'salinity'
               idF = find(strcmp(colName, colNames));
               psal = a_nemoData.paramValue(:, idF);
            case 'light_442_nm'
               idF = find(strcmp(colName, colNames));
               light442 = a_nemoData.paramValue(:, idF);
            case 'light_550_nm'
               idF = find(strcmp(colName, colNames));
               light550 = a_nemoData.paramValue(:, idF);
            case 'light_676_nm'
               idF = find(strcmp(colName, colNames));
               light676 = a_nemoData.paramValue(:, idF);
            otherwise
               fprintf('WARNING: Float #%d Cycle #%d: ''%s'' column of ''%s'' section not managed yet\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, ...
                  colName, 'PROFILE_DATA');
         end
      end      
      
      if (~isempty(pres) && ~isempty(temp) && ~isempty(psal))
         paramPres = get_netcdf_param_attributes('PRES');
         paramTemp = get_netcdf_param_attributes('TEMP');
         paramSal = get_netcdf_param_attributes('PSAL');
         
         % convert NaN values to netCDF fill values
         pres(find(isnan(pres))) = paramPres.fillValue;
         temp(find(isnan(temp))) = paramTemp.fillValue;
         psal(find(isnan(psal))) = paramSal.fillValue;

         o_profileData = get_apx_profile_data_init_struct;
         o_profileData.paramList = [paramPres paramTemp paramSal];
         o_profileData.data = [pres temp psal];
         
         if (~isempty(dataTime))
            paramJuld = get_netcdf_param_attributes('JULD');
            
            % convert NaN values to netCDF fill values
            dataTime(find(isnan(dataTime))) = paramJuld.fillValue;
            
            o_profileData.dateList = paramJuld;
            o_profileData.dates = dataTime;
         end
         
         if (~isempty(light442) && ~isempty(light550) && ~isempty(light676) && ...
               (any(find(light442 ~= 0)) || any(find(light550 ~= 0)) || any(find(light676 ~= 0))))
            paramLight442 = get_netcdf_param_attributes('LIGHT442');
            paramLight550 = get_netcdf_param_attributes('LIGHT550');
            paramLight676 = get_netcdf_param_attributes('LIGHT676');
            
            o_profileData.paramList = [o_profileData.paramList ...
               paramLight442 paramLight550 paramLight676];
            o_profileData.data = [o_profileData.data ...
               light442 light550 light676];
         end
         
         idDel = (find((o_profileData.data(:, 1) == paramPres.fillValue) & ...
            (o_profileData.data(:, 2) == paramTemp.fillValue) & ...
            (o_profileData.data(:, 3) == paramSal.fillValue)));
         o_profileData.data(idDel, :) = [];
         o_profileData.dates(idDel) = [];
         if (isempty(o_profileData.data))
            o_profileData = [];
         end

      else
         fprintf('ERROR: Float #%d Cycle #%d: anomaly in ''%s'' section\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            'PROFILE_DATA');
      end
      
   otherwise
      fprintf('ERROR: Float #%d Cycle #%d: unexpected section name (%s)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_sectionName);
      return
end

return
