classdef MS_DECOMP_PLUGIN < audioPlugin
    %MS_DECOMP_PLUGIN 
    %   MID SIDE Decomposition
    %   SID: 2105221

   
    properties
        MS_TOGGLE = MS_MODE.enc; % Set encode mode
        MS_SIDE_GAIN = 1; % set side gain
        MS_MID_GAIN = 1; % set mid gain

        GAIN = 0; % set output gain
        SUM_MONO = false; % mono?
        MSOutput = false; % MID/SIDE output mode 

        POL_FLIP_RIGHT = false; % flip right?
        POL_FLIP_LEFT = false; % flip left?

        OUTPUT_MODE = MS_OUTPUT_MODE.stereo; % set ouptu mode

        SWAP_OUTPUTS = false; % SWAP outputs?
    end
    properties (Constant)
        PluginInterface = audioPluginInterface( ...
            audioPluginParameter('MS_TOGGLE', ...
                'Mapping', ...
                {'enum','Disabled','Encode', 'Decode'}, ...
                'Style','dropdown', ...
                'Layout', [2,1], ...
                'DisplayName', 'Mode Select', ...
                'DisplayNameLocation', 'above'), ...
            audioPluginParameter('MSOutput', ...
                'Mapping', ...
                {'enum','Mid/Side','Mixed'}, ...
                'Style','vtoggle', ...
                'Layout', [2,3], ...
                'DisplayName', 'Output Mode Select', ...
                'DisplayNameLocation', 'above'), ...
            audioPluginParameter('MS_SIDE_GAIN', ...
                'Mapping',{'lin',0,1}, ...
                'Style','rotaryknob', ...
                'Layout', [2,5], ...
                'DisplayName', 'Side Gain', ...
                'DisplayNameLocation', 'above'), ...
            audioPluginParameter('MS_MID_GAIN', ...
                'Mapping',{'lin',0,1}, ...
                'Style','rotaryknob', ...
                'Layout', [2,7], ...
                'DisplayName', 'Mid Gain', ...
                'DisplayNameLocation', 'above'), ...
             audioPluginParameter('POL_FLIP_LEFT', ...
                'Mapping', ...
                {'enum','false','true'}, ...
                'Style','vrocker', ...
                'Layout', [4,1], ...
                'DisplayName', 'Polarity Flip Left', ...
                'DisplayNameLocation', 'above'),  ...
            audioPluginParameter('POL_FLIP_RIGHT', ...
                'Mapping', ...
                {'enum','false','true'}, ...
                'Style','vrocker', ...
                'Layout', [4,3], ...
                'DisplayName', 'Polarity Flip Right', ...
                'DisplayNameLocation', 'above'), ...
             audioPluginParameter('SUM_MONO', ...
                'Mapping', ...
                {'enum','false','true'}, ...
                'Style','vrocker', ...
                'Layout', [4,5], ...
                'DisplayName', 'Sum To Mono', ...
                'DisplayNameLocation', 'above'), ...
             audioPluginParameter('OUTPUT_MODE', ...
                'Mapping', ...
                {'enum','Left','Right', 'Stereo', 'Flip'}, ...
                'Style','dropdown', ...
                'Layout', [4,7], ...
                'DisplayName', 'Output Mode', ...
                'DisplayNameLocation', 'above'),...
             audioPluginParameter('GAIN', ...
                'Mapping',{'pow',1/3,-140,24}, ...
                'Style','rotaryknob', ...
                'Layout', [2,9], ...
                'DisplayName', 'Output Gain', ...
                'DisplayNameLocation', 'above', ...
                'Label', 'dB'), ...
                'VendorName', 'Hazell Design', 'PluginName', 'SHORT BACK AND SIDES', 'VendorVersion', '1.1.1', 'InputChannels',2,'OutputChannels',2, audioPluginGridLayout( ...
                'RowHeight',[20,150,20,150,5], ...
                'ColumnWidth',[120,5,120,5,120,5,120,5,120,5], ...
                'RowSpacing',30))
       
        % Define UI
    end
    %% THE HELP FILE™
    %
    % ENCODE - Converts Stereo audio into a MID / SIDE Representation
    %   Outputs
    %
    %       Mixed (MSOuput = True)
    %           Mixes the SIDE_GAIN and MID_GAIN back together
    %           This can be used to change the balance between the Mid and
    %           Side gain
    %
    %       MID/SIDE (MSOutput = False)
    %           Outputs the processed mid side components
    %           In this output
    %               LEFT = MID
    %               RIGHT = SIDE
    methods
        function out = process(plugin,in)
            % Define size of buffer
            [N,M] = size(in);
            % Define output array
            out = zeros(N,M);
            % get sample rate
            fs = getSampleRate(plugin);
            % Time loop
            for n = 1:N
                
                % For the purposes of this plugin I could use a switch case
                % to check MS_TOGGLE as it caused the plugin to badly
                % underrun
                % I also could use an if statement to check MS_TOGGLE
                % aginst MS_MODE.x as that would also cause the plugin to
                % underrun. 

                % Thus I have had to use the number assignments of enc,
                % dec, and disabled in the following if statments

                % Disabled = 0 
                % Encode = 1
                % Decode = 2
                
                if plugin.MS_TOGGLE == 1
                    % ENCODE
                    [mid_out, side_out] = plugin.encode(in(n,:),plugin.MSOutput,plugin.MS_SIDE_GAIN,plugin.MS_MID_GAIN);
                    out(n,1) = mid_out;
                    out(n,2) = side_out;
                elseif plugin.MS_TOGGLE == 2
                    % DECODE
                    [left_out, right_out] = plugin.decode(in(n,:),plugin.MSOutput,plugin.MS_SIDE_GAIN,plugin.MS_MID_GAIN);
                    out(n,1) = left_out;
                    out(n,2) = right_out;
                elseif plugin.MS_TOGGLE == 0
                    % M/S Disabled
                    out(n,1) = in(n,1);
                    out(n,2) = in(n,2);
                end

               

                % FLIP POLARITY - LEFT
                if plugin.POL_FLIP_LEFT
                    out(n,1) = -out(n,1);
                end

                % FLIP POLARITY - RIGHT
                if plugin.POL_FLIP_RIGHT
                    out(n,2) = -out(n,2);
                end

                 % SUM TO MONO CHECK
                if plugin.SUM_MONO == true
                    out_left = out(n,1);
                    out_right = out(n,2);
                    out(n,1) = (out_left + out_right) / 2;
                    out(n,2) = (out_left + out_right) / 2;
                end
                

                if isequal(plugin.OUTPUT_MODE,0)
                    % LEFT ONLY OUTPUT
                    out(n,2) = 0;
                elseif isequal(plugin.OUTPUT_MODE,1)
                    % RIGHT ONLY OUTPUT
                    out(n,1) = 0;
                elseif isequal(plugin.OUTPUT_MODE,3)
                    % FLIP OUTPUTS
                    out_temp = out(n,1);
                    out(n,1) = out(n,2);
                    out(n,2) = out_temp;
                end
                

                
                % OUTPUTs with gain applied
                out(n,1) = out(n,1) * plugin.convbin(plugin.GAIN);
                out(n,2) = out(n,2) * plugin.convbin(plugin.GAIN);
            end
        end 
       
        %% ENCODE / DECODE FUNCTIONS
        function [left,right] = encode(plugin,x, MSOutput, SIDE_GAIN, MID_GAIN)
            % WHEN ENCODING
            % x(1) = LEFT
            % x(2) = RIGHT
        
            % This formula is the same for encode and decode
            LEFT = x(1);
            RIGHT = x(2);
            MID = LEFT + RIGHT; % LEFT + RIGHT ( SUM )
            SIDE = LEFT - RIGHT; % LEFT - RIGHT ( DIFFERENCE )
            if MSOutput
                % Output the Mixed output
                % This is to change the balance between the MID's and the SIDE
                left = ((0.5*SIDE)*SIDE_GAIN) + ((0.5*MID)*MID_GAIN);
                right = ((0.5*-SIDE)*SIDE_GAIN) + ((0.5*MID)*MID_GAIN);
            else 
                % OUTPUT M/S 
                left = MID;
                right = SIDE;
            end
           
            
            
        end
        function [left,right] = decode(plugin,x, MSOutput, SIDE_GAIN, MID_GAIN)

            % WHEN DECODING
            % x(1) = MID
            % x(2) = SIDE
        
            % This formula is the same for encode and decode
            MID = x(1);
            SIDE = x(2);
            LEFT = MID + SIDE; % LEFT + RIGHT ( SUM )
            RIGHT = MID - SIDE; % LEFT - RIGHT ( DIFFERENCE )
            if MSOutput
                % Output the Mixed output
                % This is to change the balance between the MID's and the SIDE
                left = ((0.5*LEFT)*SIDE_GAIN) + ((0.5*RIGHT)*MID_GAIN);
                right = ((0.5*-LEFT)*SIDE_GAIN) + ((0.5*RIGHT)*MID_GAIN);
            else
                % OUTPUT L/R
                left = LEFT;
                right = RIGHT;
            end
        end

        function out = convbin(plugin,x)
            % convert dbfs to 1-0
            out = 10^(x/20);
        end


         
    end

    
end



