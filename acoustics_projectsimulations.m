%% Room Dimensions, Volume, and Surface Area 
room_length = 15;
width = 11;
height = 8;

room_volume = room_length*width*height;
room_sa = 2*(room_length*width + room_length*height + width*height);

%% Room Dimension Ratios
figure;
norm_width = width/height;
norm_length = room_length/height;

bolt_x = [1.2, 1.4, 1.6, 1.8, 1.6, 1.5, 1.4, 1.35, 1.3, 1.15, 1.2];
bolt_x_interp = interp(bolt_x, 5);
bolt_y = [1.4, 1.6, 1.8, 2.2, 2.4, 2.5, 2.4, 2.0, 1.8, 1.45, 1.4];
bolt_y_interp = interp(bolt_y, 5);

fill(bolt_x_interp, bolt_y_interp, [0.8 0.8 0.8]  ,'EdgeColor', 'none', 'FaceAlpha', 0.3);
hold on;

plot(norm_width, norm_length, 'o', 'MarkerSize', 10, 'MarkerFaceColor', 'b');
plot(1.4, 1.9, 'o', 'MarkerSize', 10, 'MarkerFaceColor','r');
grid on;

xlim([1.0 2.0]);
xticks(1.0:0.1:2.0); 
ylim([1.2 2.6]);
yticks(1.2:0.2:2.6);
xlabel('Normalized Width');
ylabel('Normalized Length');
title('Room Ratio & Bolt Area');
legend('Bolt Area', 'Model Room', 'Louden');

%% Alpha Values at 125 Hz-1kHz
alpha_plaster = [0.14, 0.1, 0.06, 0.05];
alpha_hardwood = [0.15, 0.11, 0.1, 0.07];
alpha_paintedcc = [0.1, 0.05, 0.06, 0.07];
alpha_tapestry = [0.07, 0.37, 0.49, 0.81];
alpha_window = [0.35, 0.25, 0.18, 0.12];


%% Percentage Coverage of Material
percent_window = 0.05;
percent_plaster = 0.65;
percent_tapestry = 0.3;
percent_paintedcc = 1;
percent_hardwood = 1;

%% Total Absorption (Sabins)

total_sabins = room_length*width*(percent_paintedcc*alpha_paintedcc + percent_hardwood*alpha_hardwood) + 2*height*(width + room_length)*(percent_plaster*alpha_plaster + percent_tapestry*alpha_tapestry + percent_window*alpha_window);
total_sabins_table = array2table(total_sabins, 'RowNames', {'Total Sabins'});
total_sabins_table.Properties.VariableNames = {'125 Hz', '250 Hz', '500 Hz', '1 kHz'};

%% RT60 Approximation (Sabine & Eyring-Norris)

rt_60_sabine = 0.049*room_volume./total_sabins;
alpha_avg = total_sabins/room_sa;
rt_60_en = 0.049*room_volume./(-room_sa*log(1 - alpha_avg));
rt_frequencies = [125, 250, 500, 1000];


figure;
plot(rt_frequencies, rt_60_sabine, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', 'g');
hold on;
plot(rt_frequencies, rt_60_en, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', 'm');

xlabel('Frequency (Hz)');
ylabel('RT 60 (Seconds)');
title('Modeled RT 60 Times')
legend('Sabine', 'Eyring-Norris');

% rt_60_table = array2table([rt_60_sabine; rt_60_en], 'VariableNames' ,{'125 Hz', '250 Hz', '500 Hz', '1 kHz'}, 'RowNames', {'RT 60 (Sabine)', 'RT 60 (Eyring-Norris)'});



%% Bass Rise Ratio

bass_rise = (rt_60_sabine(1) + rt_60_sabine(2))/(rt_60_sabine(3) + rt_60_sabine(4));

%% Schroeder Frequency

schroeder = 11885*sqrt(rt_60_sabine(3)/room_volume);


%% Axial Room-Modes

sound_speed = 1130;
dimensions = [room_length, width, height];
axial_modes = cell(1, 3);

for dim = 1:3
    modes = [];
    n = 1;
    
    
    while true
        f = (sound_speed/2)*(n/dimensions(dim));
        if f < 4*schroeder
            modes(end + 1) = f;
            n = n + 1;
        else
            break;
        end
    end
    axial_modes{dim} = modes;
end

length_axial_modes = axial_modes{1};
width_axial_modes = axial_modes{2};
height_axial_modes = axial_modes{3};

%% Modal Spacing Plot
figure;
stem(length_axial_modes, 0.67*ones(size(length_axial_modes)), 'r', 'DisplayName', 'Length', 'MarkerFaceColor','auto');
hold on;
stem(width_axial_modes, 0.67*ones(size(width_axial_modes)), 'b', 'DisplayName', 'Width', 'MarkerFaceColor', 'auto');
stem(height_axial_modes, 0.67*ones(size(height_axial_modes)), 'g', 'DisplayName', 'Height', 'MarkerFaceColor', 'auto');
hold off;

xlabel('Frequency (Hz)');
xlim([0 schroeder]);
ylim([0 1]);
set(gca, 'YTick', []);
ylabel('');
title('Axial Room Modes Less Than Schroeder Frequency');
legend('Length', 'Width', 'Height');

all_axial_modes = sort([length_axial_modes, width_axial_modes, height_axial_modes]);

axial_mode_spacing = diff(all_axial_modes);
ams_std = std(axial_mode_spacing);
ams_mean = mean(axial_mode_spacing);



%% Modal Density Plot

f_center = 12;
table_row = 0;
axial_modes_array = [];

while f_center < 4*schroeder
    table_row = table_row + 1;

    f_lower = f_center*2^(-1/4);
    f_upper = f_center*2^(1/4);

    num_modes = sum(all_axial_modes >= f_lower & all_axial_modes < f_upper);
            
        

    axial_modes_array(table_row, 1) = f_center;
    axial_modes_array(table_row, 2) = num_modes;

    f_center = f_center*2^(1/2);
end

figure;
plot(axial_modes_array(:,1), axial_modes_array(:,2), '-o', 'MarkerFaceColor', 'k', 'Color', 'm');

xlabel('Frequency (Hz)');
yticks(0:1:25);
ylabel('Modal Density per 1/2 octave');
title('Modal Density Plot');

if any(diff(axial_modes_array(:,2)) < 0)
    subtitle('Bonnello Criterion not met :(')
else
    subtitle('Bonnello Criterion met :)')
end


%% First Reflection Analysis

src_coords = [1.5, 5, 3];
receiver_coords = [5.5, 5, 3];
src_2_receiver = norm(receiver_coords - src_coords);
off_axis = [3, 5, 6];
theta = atan(2*off_axis/src_2_receiver);
reflection_length = 2*off_axis./sin(theta);

reflection_delays = reflection_length/sound_speed;
rel_level = db(src_2_receiver./reflection_length);


figure; 
plot(1000*reflection_delays, rel_level, 'o', MarkerSize=10,MarkerFaceColor='b');


ylim([-12 0]);
yticks(-12:3:0);
ylabel('Relative Level (dB)');
xlabel('Delay Time (ms)');
title('Relative Level of First Reflections')
xlim([0 12]);
xticks(0:3:12);
grid on;

figure; hold on;
fs = 44100;
xlim([0 500]);
for i = 1:length(reflection_delays)
    k = round(reflection_delays(i)*fs);
    coefficients = zeros(k, 1);
    coefficients(1) = 1;
    coefficients(k) = db2mag(rel_level(i));

    comb_spacing = 1/reflection_delays(i);

    [h, w] = freqz(coefficients, 1, fs, fs);
    semilogx(w, db(abs(h)), 'DisplayName', sprintf('Δf = %.1f Hz', comb_spacing), 'LineWidth', 3);
    drawnow();
end

xlabel('Frequency (Hz)');
ylabel('Magnitude (dB');
title('Comb Spacing & Levels for 1st Reflections');
legend('Location', 'best');


%% Absorption w/ Treatment

% Alpha Values of Treatment Materials
alpha_bass_panel = [0.9, 1.2, 1.26, 1.16];
alpha_absorptive_sheet = [0.12, 0.38, 0.96, 1.11];

% Percentage Coverage of Material
percent_window_treated = 0.05;
percent_plaster_treated = 0.58;
percent_bass_panel = 0.01;
percent_absorptive_sheet = 0.06;
percent_tapestry_treated = 0.3;
percent_paintedcc_treated = 1;
percent_hardwood_treated = 1;

% Total Absorption (Sabins)

total_sabins_treated = room_length*width*(percent_paintedcc_treated*alpha_paintedcc + percent_hardwood_treated*alpha_hardwood) + 2*height*(width + room_length)*(percent_plaster_treated*alpha_plaster + percent_tapestry_treated*alpha_tapestry + percent_window_treated*alpha_window + percent_absorptive_sheet*alpha_absorptive_sheet + percent_bass_panel*alpha_bass_panel);
total_sabins_table_treated = array2table(total_sabins_treated, 'RowNames', {'Total Sabins'});
total_sabins_table_treated.Properties.VariableNames = {'125 Hz', '250 Hz', '500 Hz', '1 kHz'};

% RT60 Approximation after Treatment (Sabine & Eyring-Norris)

rt_60_sabine_treated = 0.049*room_volume./total_sabins_treated;
alpha_avg_treated = total_sabins_treated/room_sa;
rt_60_en_treated = 0.049*room_volume./(-room_sa*log(1 - alpha_avg_treated));
rt_frequencies = [125, 250, 500, 1000];


figure(2);
hold on;
plot(rt_frequencies, rt_60_sabine_treated, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', 'c');
hold on;
plot(rt_frequencies, rt_60_en_treated, '-o', 'LineWidth', 2, 'MarkerSize', 8, 'Color', 'r');

xlabel('Frequency (Hz)');
ylabel('RT 60 (Seconds)');
title('Modeled RT 60 Times After Treatment')
legend('Sabine', 'Eyring-Norris', 'Sabine Post-Treatment', 'Eyring-Norris Post-Treatment');
