% ------------------------------------------------------------------------------
% Decode meta-data XML file data transmitted by a CTS5-USEA float.
%
% SYNTAX :
%  [o_metaData] = decode_apmt_metadata_128(a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_inputFilePathName : APMT meta-data XML file to decode
%
% OUTPUT PARAMETERS :
%   o_metaData : meta-data XML file decoded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/15/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = decode_apmt_metadata_128(a_inputFilePathName)

% output parameters initialization
o_metaData = [];


if ~(exist(a_inputFilePathName, 'file') == 2)
   fprintf('ERROR: decode_apmt_metadata_128: File not found: %s\n', a_inputFilePathName);
   return
end

% open the file and read the data
fId = fopen(a_inputFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_inputFilePathName);
   return
end
data = fread(fId);
fclose(fId);

% find the position of the last useful byte
lastByteNum = get_last_byte_number(data, hex2dec('1a'));

% write the file without the padding bytes
[inputPathName, inputFileName, inputFileExt] = fileparts(a_inputFilePathName);
floatTmpDirName = [inputPathName '/tmp/'];
if (exist(floatTmpDirName, 'dir') == 7)
   rmdir(floatTmpDirName, 's');
end
mkdir(floatTmpDirName);
inputFilePathName = [floatTmpDirName inputFileName inputFileExt];

% write the data in the temporary file
fId = fopen(inputFilePathName, 'wt');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', inputFilePathName);
   return
end
fwrite(fId, data(1:lastByteNum));
fclose(fId);

% parse the XML data
dataStruct = parse_xml_2_struct(inputFilePathName);
if (isempty(dataStruct))
   fprintf('ERROR: Unable to parse file: %s\n', inputFilePathName);
   return
end

% retrieve metada from Matlab structure
o_metaData = read_metadata_struct(dataStruct);

if (exist(floatTmpDirName, 'dir') == 7)
   rmdir(floatTmpDirName, 's');
end

return

% ------------------------------------------------------------------------------
% Read CTS5-USEA meta-data from a Matlab structure.
%
% SYNTAX :
%  [o_metaData] = read_metadata_struct(a_metaDataStruct)
%
% INPUT PARAMETERS :
%   a_metaDataStruct : Matlab structure of CTS5 meta-data XML file
%
% OUTPUT PARAMETERS :
%   o_metaData : CTS5 meta-data XML data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/09/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = read_metadata_struct(a_metaDataStruct)

% output parameters initialization
o_metaData = [];

% create the metadata info structure
metaDataStruct = init_metadata_info_struct;

% fill the metadata info structure
[metaDataStruct, ~] = read_child(a_metaDataStruct.Children, metaDataStruct, '');

% removed empty fields in metadata info structure
metaDataStruct = remove_empty_fields(metaDataStruct);

o_metaData = metaDataStruct;

return

% ------------------------------------------------------------------------------
% Recursively remove the unused fields of the input structure
%
% SYNTAX :
%  [o_metaDataStruct] = remove_empty_fields(a_metaDataStruct)
%
% INPUT PARAMETERS :
%   a_metaDataStruct : input structure
%
% OUTPUT PARAMETERS :
%   o_metaDataStruct : output structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/13/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaDataStruct] = remove_empty_fields(a_metaDataStruct)

% output parameters initialization
o_metaDataStruct = a_metaDataStruct;

fieldNames = fields(a_metaDataStruct);
for idF = 1:length(fieldNames)
   if (~isstruct(a_metaDataStruct.(fieldNames{idF})))
      if (isempty(a_metaDataStruct.(fieldNames{idF})))
         o_metaDataStruct = rmfield(o_metaDataStruct, fieldNames{idF});
      end
   else
      metaDataStruct = remove_empty_fields(o_metaDataStruct.(fieldNames{idF}));
      if (isempty(fields(metaDataStruct)))
         o_metaDataStruct = rmfield(o_metaDataStruct, fieldNames{idF});
      else
         o_metaDataStruct.(fieldNames{idF}) = metaDataStruct;
      end
   end
end

return

% ------------------------------------------------------------------------------
% Recursively read the CTS5-USEA meta-data Matlab structure.
%
% SYNTAX :
%  [o_metaDataStruct, o_path] = read_child(a_children, a_metaDataStruct, a_path)
%
% INPUT PARAMETERS :
%   a_children       : current children of the structure
%   a_metaDataStruct : input Matlab structure of CTS5 meta-data XML file
%   a_path           : input path to structure field
%
% OUTPUT PARAMETERS :
%   o_metaDataStruct : output Matlab structure of CTS5 meta-data XML file
%   o_path           : output path to structure field
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/09/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaDataStruct, o_path] = read_child(a_children, a_metaDataStruct, a_path)

% output parameters initialization
o_metaDataStruct = a_metaDataStruct;
o_path = a_path;

for idChild = 1:length(a_children)
   childData = a_children(idChild);
   if (strcmp(childData.Name, '#text'))
      if (idChild == length(a_children))
         idF = strfind(o_path, '.');
         if (~isempty(idF))
            o_path = o_path(1:idF(end)-1);
         end
      end
      continue
   end
   if (isempty(childData.Children))
      
      % read the current childrens
      childName = lower(childData.Name);
      if (~eval(['isfield(o_metaDataStruct' o_path ', childName)']))
         fprintf('ERROR: Unexpected field: %s\n', childName);
         continue
      end
      attList = childData.Attributes;
      for idAtt = 1:length(attList)
         att = attList(idAtt);
         attName = att.Name;
         attValue = att.Value;
         fieldName = lower(attName);
         if (~eval(['isfield(o_metaDataStruct' o_path '.(childName), fieldName)']))
            fprintf('ERROR: Unexpected attribute: %s\n', fieldName);
            continue
         end
         eval(['o_metaDataStruct' o_path '.(childName).(fieldName) = attValue;']);
      end
      if (idChild == length(a_children))
         idF = strfind(o_path, '.');
         if (~isempty(idF))
            o_path = o_path(1:idF(end)-1);
         end
      end
   else
      
      % read the childrens of the current children
      childName = lower(childData.Name);
      if (~eval(['isfield(o_metaDataStruct' o_path ', childName)']))
         fprintf('ERROR: Unexpected field: %s\n', childName);
         continue
      end
      o_path = [o_path '.' childName];
      
      % read the new children
      [o_metaDataStruct, o_path] = read_child(childData.Children, o_metaDataStruct, o_path);
   end
end

return

% ------------------------------------------------------------------------------
% Get the basic structure to read CTS5-USEA meta-data.
%
% SYNTAX :
%  [o_metaDataStruct] = init_metadata_info_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_metaDataStruct : meta-data structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/09/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaDataStruct] = init_metadata_info_struct

% output parameters initialization
o_metaDataStruct = [];


profiler = [];
profiler.sn = '';
profiler.id = '';
profiler.model = '';

telecom = [];
telecom.type = '';
telecom.cid = '';
telecom.login = '';

hardware = [];
hardware.control_board = [];
hardware.control_board.model = '';
hardware.control_board.sn = '';
hardware.control_board.firmware = '';
hardware.control_board.sdcard = '';

hardware.measure_board = [];
hardware.measure_board.model = '';
hardware.measure_board.sn = '';
hardware.measure_board.firmware = '';

hardware.extension_board = [];
hardware.extension_board.model = '';

hardware.hull = [];
hardware.hull.model = '';

hardware.battery = [];
hardware.battery.pack_1.type = '';
hardware.battery.pack_1.voltage = '';
hardware.battery.pack_1.capacity = '';
hardware.battery.pack_2.type = '';
hardware.battery.pack_2.voltage = '';
hardware.battery.pack_2.capacity = '';

sensors = [];
sensors.sensor_sbe41 = [];
sensors.sensor_sbe41.sensor.sn = '';
sensors.sensor_sbe41.sensor.model = '';
sensors.sensor_sbe41.sbe41_board.firmware = '';
sensors.sensor_sbe41.sensor_pressure.sn = '';
sensors.sensor_sbe41.temperature_coeff.ta0 = '';
sensors.sensor_sbe41.temperature_coeff.ta1 = '';
sensors.sensor_sbe41.temperature_coeff.ta2 = '';
sensors.sensor_sbe41.temperature_coeff.ta3 = '';
sensors.sensor_sbe41.conductivity_coeff.g = '';
sensors.sensor_sbe41.conductivity_coeff.h = '';
sensors.sensor_sbe41.conductivity_coeff.i = '';
sensors.sensor_sbe41.conductivity_coeff.j = '';
sensors.sensor_sbe41.conductivity_coeff.ctcor = '';
sensors.sensor_sbe41.conductivity_coeff.cpcor = '';
sensors.sensor_sbe41.conductivity_coeff.wbotc = '';

sensors.sensor_do = [];
sensors.sensor_do.sensor.sn = '';
sensors.sensor_do.sensor.model = '';
sensors.sensor_do.phase_coeff.c0 = '';
sensors.sensor_do.svu_foil_coeff.c0 = '';
sensors.sensor_do.svu_foil_coeff.c1 = '';
sensors.sensor_do.svu_foil_coeff.c2 = '';
sensors.sensor_do.svu_foil_coeff.c3 = '';
sensors.sensor_do.svu_foil_coeff.c4 = '';
sensors.sensor_do.svu_foil_coeff.c5 = '';
sensors.sensor_do.svu_foil_coeff.c6 = '';

sensors.sensor_ocr = [];
sensors.sensor_ocr.sensor.sn = '';
sensors.sensor_ocr.sensor.model = '';
sensors.sensor_ocr.channel_01.a0 = '';
sensors.sensor_ocr.channel_01.a1 = '';
sensors.sensor_ocr.channel_01.im = '';
sensors.sensor_ocr.channel_02.a0 = '';
sensors.sensor_ocr.channel_02.a1 = '';
sensors.sensor_ocr.channel_02.im = '';
sensors.sensor_ocr.channel_03.a0 = '';
sensors.sensor_ocr.channel_03.a1 = '';
sensors.sensor_ocr.channel_03.im = '';
sensors.sensor_ocr.channel_04.a0 = '';
sensors.sensor_ocr.channel_04.a1 = '';
sensors.sensor_ocr.channel_04.im = '';

sensors.sensor_eco = [];
sensors.sensor_eco.sensor.sn = '';
sensors.sensor_eco.sensor.model = '';
sensors.sensor_eco.sensor.type = '';
sensors.sensor_eco.channel_01.sf = '';
sensors.sensor_eco.channel_01.dc = '';
sensors.sensor_eco.channel_02.sf = '';
sensors.sensor_eco.channel_02.dc = '';
sensors.sensor_eco.channel_03.sf = '';
sensors.sensor_eco.channel_03.dc = '';

sensors.sensor_sbeph = [];
sensors.sensor_sbeph.sensor.sn = '';

sensors.sensor_crover = [];
sensors.sensor_crover.sensor.sn = '';

sensors.sensor_suna = [];
sensors.sensor_suna.sensor.sn = '';
sensors.sensor_suna.sensor.model = '';
sensors.sensor_suna.sensor.spectrum = '';
sensors.sensor_suna.suna_board.firmware = '';
sensors.sensor_suna.spectrometer.spintper = '';

sensors.sensor_uvp6 = [];
sensors.sensor_uvp6.sensor.sn = '';
sensors.sensor_uvp6.sensor.model = '';
sensors.sensor_uvp6.hw_conf.frame = '';
sensors.sensor_uvp6.acq_conf_01.frame = '';
sensors.sensor_uvp6.acq_conf_02.frame = '';
sensors.sensor_uvp6.acq_conf_03.frame = '';
sensors.sensor_uvp6.acq_conf_04.frame = '';
sensors.sensor_uvp6.acq_conf_05.frame = '';
sensors.sensor_uvp6.acq_conf_06.frame = '';
sensors.sensor_uvp6.acq_conf_07.frame = '';
sensors.sensor_uvp6.acq_conf_08.frame = '';
sensors.sensor_uvp6.acq_conf_09.frame = '';
sensors.sensor_uvp6.acq_conf_10.frame = '';

sensors.sensor_opus = [];
sensors.sensor_opus.sensor.sn = '';
sensors.sensor_opus.opus_board.firmware = '';
sensors.sensor_opus.sensor_lamp.sn = '';
sensors.sensor_opus.waterbase.length = '';
sensors.sensor_opus.waterbase.intensities = '';

sensors.sensor_ramses = [];

sensors.sensor_mpe = [];
sensors.sensor_mpe.sensor.sn = '';
sensors.sensor_mpe.sensor.type = '';
sensors.sensor_mpe.acquisition.average = '';
sensors.sensor_mpe.acquisition.rate = '';
sensors.sensor_mpe.photodetector.responsivityw = '';
sensors.sensor_mpe.photodetector.responsivitya = '';
sensors.sensor_mpe.photodetector.units = '';
sensors.sensor_mpe.microradiometer.gainhm = '';
sensors.sensor_mpe.microradiometer.gainml = '';
sensors.sensor_mpe.microradiometer.offseth = '';
sensors.sensor_mpe.microradiometer.offsetm = '';
sensors.sensor_mpe.microradiometer.offsetl = '';

sensors.sensor_hydroc = [];
sensors.sensor_hydroc.sensor.sn = '';
sensors.sensor_hydroc.hydroc_board.firmware = '';
sensors.sensor_hydroc.hydroc_board.hardware = '';

o_metaDataStruct.profiler = profiler;
o_metaDataStruct.telecom = telecom;
o_metaDataStruct.hardware = hardware;
o_metaDataStruct.sensors = sensors;

return
