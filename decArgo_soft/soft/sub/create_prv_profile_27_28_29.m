% ------------------------------------------------------------------------------
% Create descending and ascending profile from decoded CTDO messages.
%
% SYNTAX :
%  [o_descProfOcc, o_descProfDate, ...
%    o_descProfPres, o_descProfTemp, o_descProfSal, o_descProfRawDoxy, ...
%    o_ascProfOcc, o_ascProfDate, ...
%    o_ascProfPres, o_ascProfTemp, o_ascProfSal, o_ascProfRawDoxy] = ...
%    create_prv_profile_27_28_29(a_tabProfCTDO, a_tabTech, ...
%    a_descentStartDate, a_ascentStartDate)
%
% INPUT PARAMETERS :
%   a_tabProfCTDO      : profile CTDO data
%   a_tabTech          : technical data
%   a_descentStartDate : descent start date
%   a_ascentStartDate  : ascent start date
%
% OUTPUT PARAMETERS :
%   o_descProfOcc     : redundancy of descending profile measurements
%   o_descProfDate    : relative dates of descending profile measurements
%   o_descProfPres    : descending profile pressure measurements
%   o_descProfTemp    : descending profile temperature measurements
%   o_descProfSal     : descending profile salinity measurements
%   o_descProfRawDoxy : descending profile oxygen measurements
%   o_ascProfOcc      : redundancy of ascending profile measurements
%   o_ascProfDate     : relative dates of ascending profile measurements
%   o_ascProfPres     : ascending profile pressure measurements
%   o_ascProfTemp     : ascending profile temperature measurements
%   o_ascProfSal      : ascending profile salinity measurements
%   o_ascProfRawDoxy  : ascending profile oxygen measurements
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/06/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_descProfOcc, o_descProfDate, ...
   o_descProfPres, o_descProfTemp, o_descProfSal, o_descProfRawDoxy, ...
   o_ascProfOcc, o_ascProfDate, ...
   o_ascProfPres, o_ascProfTemp, o_ascProfSal, o_ascProfRawDoxy] = ...
   create_prv_profile_27_28_29(a_tabProfCTDO, a_tabTech, ...
   a_descentStartDate, a_ascentStartDate)

% output parameters initialization
o_descProfOcc = [];
o_descProfDate = [];
o_descProfPres = [];
o_descProfTemp = [];
o_descProfSal = [];
o_descProfRawDoxy = [];
o_ascProfOcc = [];
o_ascProfDate = [];
o_ascProfPres = [];
o_ascProfTemp = [];
o_ascProfSal = [];
o_ascProfRawDoxy = [];

% current cycle number
global g_decArgo_cycleNum;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% configuration values
global g_decArgo_generateNcTech;

% default values
global g_decArgo_dateDef;
global g_decArgo_presCountsDef;


if (isempty(a_tabProfCTDO))
   return;
end

% compute first CTDO measurement dates (9 bits coded in transmitted message)
msgTypes = unique(a_tabProfCTDO(:, 1));
for idType = 1:length(msgTypes)

   % process data of this type
   idForType = find(a_tabProfCTDO(:, 1) == msgTypes(idType));

   if (~isempty(idForType))
      dataDate = a_tabProfCTDO(idForType, 3);
      while (~isempty(find(diff(dataDate) < 0, 1)))
         idRoll = find(diff(dataDate) < 0, 1);
         dataDate(idRoll+1:end) = dataDate(idRoll+1:end) + 512;
      end
      a_tabProfCTDO(idForType, 3) = dataDate;
   end
end

% process data by type to create descending and ascending profiles
for idType = 1:length(msgTypes)

   % process data of this type
   idForType = find(a_tabProfCTDO(:, 1) == msgTypes(idType));

   if (~isempty(idForType))
      % number of PTS data (possibly) stored in Argos messages
      nbMesTot = sum(a_tabProfCTDO(idForType, 4));

      % collect PTS data
      dataOcc = zeros(nbMesTot, 1);
      dataDate = ones(nbMesTot, 1)*g_decArgo_dateDef;
      dataPres = [];
      dataPresOk = [];
      dataTemp = [];
      dataSal = [];
      dataOxy = [];

      curMes = 1;
      for idM = 1:length(idForType)
         idMes = idForType(idM);
         nbMes = a_tabProfCTDO(idMes, 4);

         dataOcc(curMes:curMes+nbMes-1) = ones(nbMes, 1)*a_tabProfCTDO(idMes, 2);
         dataDate(curMes) = a_tabProfCTDO(idMes, 3);
         dataPres = [dataPres; a_tabProfCTDO(idMes, 5:5+nbMes-1)'];
         dataPresOk = [dataPresOk; a_tabProfCTDO(idMes, 10:10+nbMes-1)'];
         dataTemp = [dataTemp; a_tabProfCTDO(idMes, 15:15+nbMes-1)'];
         dataSal = [dataSal; a_tabProfCTDO(idMes, 20:20+nbMes-1)'];
         dataOxy = [dataOxy; a_tabProfCTDO(idMes, 25:25+nbMes-1)'];

         curMes = curMes + nbMes;
      end

      % sort the data by decreasing pressure
      [dataPres, idSorted] = sort(dataPres, 'descend');
      dataPresOk = dataPresOk(idSorted);
      dataOcc = dataOcc(idSorted);
      dataDate = dataDate(idSorted);
      dataTemp = dataTemp(idSorted);
      dataSal = dataSal(idSorted);
      dataOxy = dataOxy(idSorted);

      % delete NULL values
      idDel = find((dataPres == 0) & (dataTemp == 0) & (dataSal == 0) & (dataOxy == 0));
      if (~isempty(idDel) && isempty(find(dataDate(idDel) ~= g_decArgo_dateDef, 1)))
         dataOcc(idDel) = [];
         dataDate(idDel) = [];
         dataPres(idDel) = [];
         dataPresOk(idDel) = [];
         dataTemp(idDel) = [];
         dataSal(idDel) = [];
         dataOxy(idDel) = [];
      end

      % store the profile data
      if (msgTypes(idType) == 6)
         o_ascProfOcc = dataOcc;
         idDated = find(dataDate ~= g_decArgo_dateDef);
         if (a_ascentStartDate ~= g_decArgo_dateDef)
            dataDate(idDated) = a_ascentStartDate + dataDate(idDated)/1440;
         else
            dataDate = ones(length(dataDate), 1)*g_decArgo_dateDef;
         end
         o_ascProfDate = dataDate;
         dataPres(find(dataPresOk == 0)) = g_decArgo_presCountsDef;
         o_ascProfPres = dataPres;
         o_ascProfTemp = dataTemp;
         o_ascProfSal = dataSal;
         o_ascProfRawDoxy = dataOxy;
      else
         o_descProfOcc = dataOcc;
         idDated = find(dataDate ~= g_decArgo_dateDef);
         if (a_descentStartDate ~= g_decArgo_dateDef)
            dataDate(idDated) = a_descentStartDate + dataDate(idDated)/1440;
         else
            dataDate = ones(length(dataDate), 1)*g_decArgo_dateDef;
         end
         o_descProfDate = dataDate;
         dataPres(find(dataPresOk == 0)) = g_decArgo_presCountsDef;
         o_descProfPres = dataPres;
         o_descProfTemp = dataTemp;
         o_descProfSal = dataSal;
         o_descProfRawDoxy = dataOxy;
      end
   end
end

% output NetCDF files
if (g_decArgo_generateNcTech ~= 0)
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 221];
   g_decArgo_outputNcParamValue{end+1} = length(find(a_tabProfCTDO(:, 1) == 4));
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 225];
   g_decArgo_outputNcParamValue{end+1} = length(o_descProfPres);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 521];
   g_decArgo_outputNcParamValue{end+1} = length(find(a_tabProfCTDO(:, 1) == 6));
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 525];
   g_decArgo_outputNcParamValue{end+1} = length(o_ascProfPres);
end

return;
