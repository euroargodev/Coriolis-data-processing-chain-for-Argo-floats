% ------------------------------------------------------------------------------
% Check that the provided configuration frames (HW_CONF, ACQ_CONF and TAXO_CONF)
% are consistent with what is expected.
% Put in the (first level) configuration the parameters that will be used by the
% decoder:
%   - META_AUX_UVP_FIRMWARE_VERSION
%   - CONFIG_UVP_IMAGE_VOLUME
%
% SYNTAX :
%  [o_metaStruct] = get_uvp_configuration_frames(a_metaStruct, a_floatNum)
%
% INPUT PARAMETERS :
%   a_metaStruct : input meta-data structure
%   a_floatNum   : float WMO number
%
% OUTPUT PARAMETERS :
%   o_metaStruct : output meta-data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/23/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaStruct] = get_uvp_configuration_frames(a_metaStruct, a_floatNum)

% output parameters initialization
o_metaStruct = a_metaStruct;


% retrieve UVP firmware version
if (isfield(a_metaStruct, 'META_AUX_UVP_CONFIG_NAMES') && isfield(a_metaStruct, 'META_AUX_UVP_CONFIG_PARAMETERS'))
   uvpConfNames = a_metaStruct.META_AUX_UVP_CONFIG_NAMES;
   uvpConfParams = a_metaStruct.META_AUX_UVP_CONFIG_PARAMETERS;
   idF = find(strcmp(uvpConfNames, 'HW_CONF'));
   if (~isempty(idF))
      hwConf = uvpConfParams{idF};
      hwConfValues = textscan(hwConf, '%s', 'delimiter', ',');
      hwConfValues = hwConfValues{:};

      % look for UVP firmware version
      if (length(hwConfValues) == 42)
         uvpFirmVersion = strtrim(hwConfValues{end});
         [~, count, errmsg, ~] = sscanf(uvpFirmVersion, 'ver%d.%d');
         if ~(isempty(errmsg) && (count == 2))
            fprintf('ERROR: Float #%d: Cannot recognize UVP firmware version from HW_CONF frame\n', ...
               a_floatNum);
            return
         end
         uvpFirmVersion = uvpFirmVersion(4:end);
      elseif (ismember(a_floatNum, [6902968, 6903069, 6903093, 6903095, 6903096, 6904139, 6903125]))
         uvpFirmVersion = '2020.01';
      else
         uvpFirmVersion = '2022.01';
      end
      o_metaStruct.META_AUX_UVP_FIRMWARE_VERSION = uvpFirmVersion;

      switch (uvpFirmVersion)
         case '2022.01'
            HW_CONF_LENGTH = 41;
            ACQ_CONF_LENGTH = 19;
            TAXO_CONF_LENGTH = 44;
            CONFIG_UVP_PIXEL_SIZE_ID = 19;
            CONFIG_UVP_IMAGE_VOLUME_ID = 20;
         case '2020.01'
            HW_CONF_LENGTH = 43;
            ACQ_CONF_LENGTH = 22;
            TAXO_CONF_LENGTH = -1;
            CONFIG_UVP_PIXEL_SIZE_ID = 21;
            CONFIG_UVP_IMAGE_VOLUME_ID = 22;
         otherwise
            fprintf('ERROR: Float #%d: Not managed UVP firmware version (''%s'') - ASK FOR AN UPDATE OF THE DECODER\n', ...
               a_floatNum, uvpFirmVersion);
            return
      end
      taxoModelDataList = [];
      for idC = 1:length(uvpConfNames)
         uvpConfName = uvpConfNames{idC};
         uvpConfParam = uvpConfParams{idC};
         uvpConfParamValues = textscan(uvpConfParam, '%s', 'delimiter', ',');
         uvpConfParamValues = uvpConfParamValues{:};
         if (strncmp(uvpConfName, 'ACQ', length('ACQ')))
            if (length(uvpConfParamValues) ~= ACQ_CONF_LENGTH)
               fprintf('ERROR: Float #%d: ACQ frame ''%s'' has %d parameters while %d is expected\n', ...
                  a_floatNum, uvpConfName, length(uvpConfParamValues), ACQ_CONF_LENGTH);
               return
            end
         elseif (strncmp(uvpConfName, 'TAXO', length('TAXO')))
            if (length(uvpConfParamValues) ~= TAXO_CONF_LENGTH)
               fprintf('ERROR: Float #%d: TAXO frame ''%s'' has %d parameters while %d is expected\n', ...
                  a_floatNum, uvpConfName, length(uvpConfParamValues), TAXO_CONF_LENGTH);
               return
            end
            taxoModelDataList{end+1} = uvpConfParamValues;
         elseif (strncmp(uvpConfName, 'HW', length('HW')))
            if (length(uvpConfParamValues) ~= HW_CONF_LENGTH)
               fprintf('ERROR: Float #%d: HW frame ''%s'' has %d parameters while %d is expected\n', ...
                  a_floatNum, uvpConfName, length(uvpConfParamValues), HW_CONF_LENGTH);
               return
            end
            o_metaStruct.CONFIG_UVP_PIXEL_SIZE = uvpConfParamValues{CONFIG_UVP_PIXEL_SIZE_ID};
            o_metaStruct.CONFIG_UVP_IMAGE_VOLUME = uvpConfParamValues{CONFIG_UVP_IMAGE_VOLUME_ID};
         else
            fprintf('ERROR: Float #%d: Cannot recognize frame from its name (''%s'')\n', ...
               a_floatNum, uvpConfName);
            return
         end
      end
   else
      fprintf('ERROR: Float #%d: Cannot find HW_CONF frame in UVP configuration\n', ...
         a_floatNum);
      return
   end
end

% add TAXO models
if (~isempty(taxoModelDataList))
   [catIdList, catNameList] = get_taxo_model_info(taxoModelDataList, a_floatNum);
   ecotaxaNames = sprintf('%s,', catNameList{:});
   ecotaxaIds = sprintf('%d,', catIdList{:});
   o_metaStruct.META_AUX_UVP_ECOTAXA_NAMES = ecotaxaNames(1:end-1);
   o_metaStruct.META_AUX_UVP_ECOTAXA_IDS = ecotaxaIds(1:end-1);
   o_metaStruct.TAXO_CATEGORY_ID = catIdList;
   o_metaStruct.TAXO_CATEGORY_NAME = catNameList;
end

return

% ------------------------------------------------------------------------------
% Retrieve category names and Ids from taxonomy input data.
%
% SYNTAX :
% [o_catIdList, o_catNameList] = get_taxo_model_info(a_taxoModelDataList, a_floatNum)
%
% INPUT PARAMETERS :
%   a_taxoModelDataList : input taxonomy model names and category Ids
%   a_floatNum          : float WMO number
%
% OUTPUT PARAMETERS :
%   o_taxoModelCatId   : output list of category Ids
%   o_taxoModelCatName : output list of category names
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/12/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_catIdList, o_catNameList] = get_taxo_model_info(a_taxoModelDataList, a_floatNum)

% output parameters initialization
o_catIdList = [];
o_catNameList = [];

doneList = [];
for idT = 1:length(a_taxoModelDataList)
   taxoData = a_taxoModelDataList{idT};
   nbCat = str2double(taxoData{4});
   for idC = 1:nbCat
      catId = str2double(taxoData{4+idC});
      if (~ismember(catId, doneList))
         o_catIdList{end+1} = catId;
         o_catNameList{end+1} = get_taxo_category_name(catId, a_floatNum);
         doneList = [doneList catId];
      end
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve taxonomy category name from Id.
%
% SYNTAX :
% [o_taxoCatName] = get_taxo_category_name(a_taxoCatId, a_floatNum)
%
% INPUT PARAMETERS :
%   a_taxoCatId : input taxonomy category Id
%   a_floatNum  : float WMO number
%
% OUTPUT PARAMETERS :
%   o_taxoCatName : output taxonomy category name
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/22/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_taxoCatName] = get_taxo_category_name(a_taxoCatId, a_floatNum)

% reference : https://ecotaxa.obs-vlfr.fr/api/docs#/Taxonomy%20Tree/query_taxa
switch (a_taxoCatId)
   case 342
      o_taxoCatName = 'Rhizaria';
   case 8976
      o_taxoCatName = 'Trichodesmium';
   case 11514
      o_taxoCatName = 'Chaetognatha';
   case 11758
      o_taxoCatName = 'Foraminifera';
   case 13381
      o_taxoCatName = 'Collodaria';
   case 25828
      o_taxoCatName = 'Copepoda<Maxillopoda';
   case 25942
      o_taxoCatName = 'Salpida';
   case 27642
      o_taxoCatName = 'Aulacanthidae';
   case 27647
      o_taxoCatName = 'Aulosphaeridae';
   case 45074
      o_taxoCatName = 'Calanoida';
   case 56317
      o_taxoCatName = 'Creseis';
   case 56693
      o_taxoCatName = 'Actinopterygii';
   case 84963
      o_taxoCatName = 'detritus';
   case 85008
      o_taxoCatName = 'artefact';
   case 85011
      o_taxoCatName = 'other<living';
   case 85015
      o_taxoCatName = 't004';
   case 85024
      o_taxoCatName = 'Trichodesmium<puff';
   case 85025
      o_taxoCatName = 'Trichodesmium<tuff';
   case 85039
      o_taxoCatName = 'Collodaria<solitaryglobule';
   case 85050
      o_taxoCatName = 'disc';
   case 85076
      o_taxoCatName = 'fiber<detritus';
   case 85079
      o_taxoCatName = 'multiple<other';
   case 85123
      o_taxoCatName = 'Appendicularia';
   case 85217
      o_taxoCatName = 'darksphere';
   case 93382
      o_taxoCatName = 'Acantharia';
   case 93491
      o_taxoCatName = 'small-bell<Hydrozoa';
   case 93724
      o_taxoCatName = 'filament<detritus';
   case 93755
      o_taxoCatName = 'reflection';
   case 93973
      o_taxoCatName = 'crystal';
   case 94020
      o_taxoCatName = 'triangle';
   case 94021
      o_taxoCatName = 'rectangle<uvp-testre';
   case 94022
      o_taxoCatName = 'carre';
   case 94023
      o_taxoCatName = 'ovale';
   case 94024
      o_taxoCatName = 'octogone';
   case 94142
      o_taxoCatName = 'fake uvp taxon';
   otherwise
      o_taxoCatName = ['TBD_' num2str(a_taxoCatId)];
      fprintf('ERROR: Float #%d: No name defined yet for taxonomy category Id #%d (temporarily set to ''%s'') - Ask for an update of the list (Ref. https://ecotaxa.obs-vlfr.fr/api/docs#/Taxonomy%20Tree/query_taxa)\n', ...
         a_floatNum, a_taxoCatId, o_taxoCatName);
end

return
