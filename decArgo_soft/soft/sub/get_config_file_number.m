% ------------------------------------------------------------------------------
% Choose between configuration files using the first float WMO number available
% in the parameter list.
%
% SYNTAX :
%  [o_configFileNumber] = get_config_file_number(a_varargin)
%
% INPUT PARAMETERS :
%   a_varargin : input parameters
%
% OUTPUT PARAMETERS :
%   o_configFileNumber : number of the configuration file to use
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/09/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configFileNumber] = get_config_file_number(a_varargin)

% output parameters initialization
o_configFileNumber = '';

% global input parameter information
global g_decArgo_configFilePathName;

% DOM node of XML report
global g_decArgo_xmlReportDOMNode;

% global configuration values
global g_decArgo_dirInputJsonFloatDecodingParametersFile;


% we need a float WMO to choose the config file
refWmo = '';
idF = find(strcmp('floatwmo', a_varargin) == 1);
if (~isempty(idF))
   refWmo = str2num(a_varargin{idF+1});
else
   idF = find(strcmp('floatwmolist', a_varargin) == 1);
   if (~isempty(idF))
      floatWmoList = load(a_varargin{idF+1});
      if (~isempty(floatWmoList))
         refWmo = floatWmoList(1);
      end
   end
end

if (~isempty(refWmo))

   % configuration parameters to retrieve from each configuration file
   configVar = [];
   configVar{end+1} = 'FLOAT_TRANSMISSION_TYPE';
   configVar{end+1} = 'DIR_INPUT_JSON_FLOAT_DECODING_PARAMETERS_FILE';
   tabConfigFilePathName = g_decArgo_configFilePathName;
   for idConfigFile = 1:length(tabConfigFilePathName)
      
      % get configuration parameters
      g_decArgo_configFilePathName = tabConfigFilePathName{idConfigFile};
      [ ...
         configVal, ...
         ~, ...
         o_inputError ...
         ] = get_config_dec_argo(configVar, '');
      
      if (o_inputError == 0)
         
         floatTransType = str2num(configVal{1});
         configVal(1) = [];
         g_decArgo_dirInputJsonFloatDecodingParametersFile = configVal{1};
         
         [floatNum, floatArgosId, ...
            floatDecVersion, floatDecId, ...
            floatFrameLen, ...
            floatCycleTime, floatDriftSamplingPeriod, floatDelay, ...
            floatLaunchDate, floatLaunchLon, floatLaunchLat, ...
            floatRefDay, floatEndDate, floatDmFlag] = get_one_float_info(refWmo, []);
         
         % decoder Ids:
         % decId = 1 to 99: NKE floats with Argos transmission => Trans Type = 1
         % decId = 1xx    : NKE CTS4 and CTS5 floats with Iridium Rudics transmission => Trans Type = 2
         % decId = 2xx    : NKE floats with Iridium Sbd transmission => Trans Type = 3
         % decId = 3xx    : NKE BGC floats with Iridium Sbd #2 transmission => Trans Type = 4
         % decId = 10xx   : Apex floats with Argos transmission => Trans Type = 1
         % decId = 11xx   : Apex floats with Iridium Rudics transmission => Trans Type = 2
         % decId = 12xx   : Navis floats with Iridium Rudics transmission => Trans Type = 2
         % decId = 13xx   : Apex floats with Iridium Sbd transmission => Trans Type = 3
         % decId = 20xx   : Nova floats with Iridium Sbd transmission => Trans Type = 3
         
         if (~isempty(floatDecId))
            if (((fix(floatDecId / 100) == 0) && (floatTransType == 1)) || ...
                  ((fix(floatDecId / 100) == 1) && (floatTransType == 2)) || ...
                  ((fix(floatDecId / 100) == 2) && (floatTransType == 3)) || ...
                  ((fix(floatDecId / 100) == 3) && (floatTransType == 4)) || ...
                  ((fix(floatDecId / 100) == 10) && (floatTransType == 1)) || ...
                  ((fix(floatDecId / 100) == 11) && (floatTransType == 2)) || ...
                  ((fix(floatDecId / 100) == 11) && (floatTransType == 2)) || ...
                  ((fix(floatDecId / 100) == 13) && (floatTransType == 3)) || ...
                  ((fix(floatDecId / 100) == 20) && (floatTransType == 3)))
               g_decArgo_configFilePathName = tabConfigFilePathName;
               g_decArgo_dirInputJsonFloatDecodingParametersFile = [];
               o_configFileNumber = idConfigFile;
               return;
            end
         end
      end
   end
end

if (isempty(refWmo))
   errorLabel = 'ERROR: we need a float WMO number (through ''floatwmo'' or ''floatwmolist'' parameter) to select the correct configuration file => exit\n';
else
   errorLabel = sprintf('ERROR: unavailable information to select the correct configuration file for float #%d => exit\n', ...
      refWmo);
end

% finalize the report
docNode = g_decArgo_xmlReportDOMNode;
docRootNode = docNode.getDocumentElement;

newChild = docNode.createElement('error');
newChild.appendChild(docNode.createTextNode(errorLabel));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('status');
newChild.appendChild(docNode.createTextNode('nok'));
docRootNode.appendChild(newChild);

fprintf(errorLabel);

return;
