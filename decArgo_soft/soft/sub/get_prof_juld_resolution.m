% ------------------------------------------------------------------------------
% Retrieve the resolution of the profile JULD for each float transmission type
% and decoder Id.
%
% SYNTAX :
%  [o_profJuldRes, o_profJulDComment] = get_prof_juld_resolution(a_floatTransType, a_decoderId)
%
% INPUT PARAMETERS :
%   a_floatTransType : float transmission type
%   a_decoderId      : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_profJuldRes     : profile JULD resolution
%   o_profJulDComment : comment on profile JULD resolution
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profJuldRes, o_profJulDComment] = get_prof_juld_resolution(a_floatTransType, a_decoderId)

% output parameter initialization
o_profJuldRes = [];
o_profJulDComment = [];

switch (a_floatTransType)
   
   case {1} % Argos floats
      
      switch (a_decoderId)
         
         case {1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29, 31}
            o_profJuldRes = double(6/1440); % 6 minutes
            o_profJulDComment = 'JULD resolution is 6 minutes, except when JULD = JULD_LOCATION or when JULD = JULD_FIRST_MESSAGE (TRAJ file variable); in that case, JULD resolution is 1 second';
            
         case {30, 32}
            o_profJuldRes = double(1/1440); % 1 minutes
            o_profJulDComment = 'JULD resolution is 1 minute, except when JULD = JULD_LOCATION or when JULD = JULD_FIRST_MESSAGE (TRAJ file variable); in that case, JULD resolution is 1 second';
            
         case {1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, ...
               1011, 1012, 1013, 1014, 1015, 1016, 1021, 1022}
            o_profJuldRes = double(1/86400); % 1 second

         otherwise
            fprintf('WARNING: Nothing done yet in get_prof_juld_resolution for decoderId #%d\n', ...
               a_decoderId);
      end
      
   case {2} % Iridium RUDICS floats
      
      switch (a_decoderId)
         
         case {105, 106, 107, 109, 110, 111, 112, 113, 121, 122, 123, 124, 125} % NKE CTS4 and CTS5 floats
            o_profJuldRes = double(1/1440); % 1 minute
            o_profJulDComment = 'JULD resolution is 1 minute, except when JULD = JULD_LOCATION or when JULD = JULD_FIRST_MESSAGE (TRAJ file variable); in that case, JULD resolution is 1 second';
            
         case {1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, 1201, 1314} % Apex Ir Rudics & navis floats
            o_profJuldRes = double(1/86400); % 1 second
            
         case {1121} % Apex APF11 Ir
            o_profJuldRes = double(1/86400); % 1 second
            
         case {3001} % NEMO
            o_profJuldRes = double(1/86400); % 1 second
            
         otherwise
            fprintf('WARNING: Nothing done yet in get_prof_juld_resolution for decoderId #%d\n', ...
               a_decoderId);
      end

   case {3} % Iridium SBD floats
      
      switch (a_decoderId)
         
         case {101, 102, 103}
            o_profJuldRes = double(6/1440); % 6 minutes
            o_profJulDComment = 'JULD resolution is 6 minutes, except when JULD = JULD_LOCATION or when JULD = JULD_FIRST_MESSAGE (TRAJ file variable); in that case, JULD resolution is 1 second';
            
         case {104}
            o_profJuldRes = double(1/1440); % 1 minute
            o_profJulDComment = 'JULD resolution is 1 minute, except when JULD = JULD_LOCATION or when JULD = JULD_FIRST_MESSAGE (TRAJ file variable); in that case, JULD resolution is 1 second';
        
         case {201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220}
            o_profJuldRes = double(1/1440); % 1 minute
            o_profJulDComment = 'JULD resolution is 1 minute, except when JULD = JULD_LOCATION or when JULD = JULD_FIRST_MESSAGE (TRAJ file variable); in that case, JULD resolution is 1 second';
            
         case {1314} % Apex Ir Sbd
            o_profJuldRes = double(1/86400); % 1 second
            
         case {1321, 1322} % Apex APF11 Ir
            o_profJuldRes = double(1/86400); % 1 second
            
         case {2001, 2002}
            o_profJuldRes = double(1/86400); % 1 second
            
         case {2003}
            o_profJuldRes = double(6/1440); % 6 minutes
            o_profJulDComment = 'JULD resolution is 6 minutes, except when JULD = JULD_FIRST_MESSAGE (TRAJ file variable); in that case, JULD resolution is 1 second';

         otherwise
            fprintf('WARNING: No JULD profile resolution defined yet for float transmission type #%d and decoder Id #%d\n', ...
               a_floatTransType, a_decoderId);
            
      end
      
   case {4} % Iridium SBD CTS4
      
      switch (a_decoderId)
         
         case {301, 302, 303}
            % CTS4 floats
            o_profJuldRes = double(1/1440); % 1 minute
            o_profJulDComment = 'JULD resolution is 1 minute, except when JULD = JULD_LOCATION or when JULD = JULD_FIRST_MESSAGE (TRAJ file variable); in that case, JULD resolution is 1 second';
                  
         otherwise
            fprintf('WARNING: No JULD profile resolution defined yet for float transmission type #%d and decoder Id #%d\n', ...
               a_floatTransType, a_decoderId);
            
      end
      
   otherwise
      fprintf('WARNING: No JULD profile resolution defined yet for float transmission type #%d\n', ...
         a_floatTransType);
end

return
