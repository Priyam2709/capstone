function fig = plotSimulationResults(simResults, outputPath)
% PLOTSIMULATIONRESULTS Visualizes discrete-event simulation performance & queues.
%
%   fig = plotSimulationResults(simResults)
%   fig = plotSimulationResults(simResults, outputPath)
%
%   Generates a publication-quality multi-panel visualization of rural screening
%   camp operational metrics:
%     Panel 1: Queue Length Dynamics over Time (all 5 stations)
%     Panel 2: Cumulative Arrivals vs Departures (Backlog Trajectory)
%     Panel 3: Patient Total System Time Distribution (Histogram & P95)
%     Panel 4: Resource Server Utilization & Bottleneck Identification
%     Panel 5: Waiting Time Breakdown per Station (Mean & P95)
%
%   Inputs:
%       simResults - Struct returned by runCampSimulation().
%       outputPath - (Optional) File path to save output PNG figure.
%                    Default: 'results/figures/simulink_queue_analysis.png'
%
%   Outputs:
%       fig - Figure handle to generated diagnostic visualization.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 1 || isempty(simResults)
        simResults = runCampSimulation();
    end

    if nargin < 2 || isempty(outputPath)
        root = getProjectRoot();
        outputPath = fullfile(root, 'results', 'figures', 'simulink_queue_analysis.png');
    end

    logger.info('Generating Simulink queueing simulation visualizations...');

    % Ensure destination folder exists
    outDir = fileparts(outputPath);
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end

    % Create Figure with modern theme
    fig = figure('Name', 'SIH26038: Rural Camp Simulink Queueing & Workflow Analysis', ...
                 'Units', 'pixels', 'Position', [80, 50, 1280, 800], ...
                 'Color', [0.97, 0.98, 1.0], 'Visible', 'off');

    timeHours = simResults.timeSeries.time / 60; % Convert minutes to hours

    % -----------------------------------------------------------------
    % Subplot 1: Queue Length Dynamics over Time
    % -----------------------------------------------------------------
    subplot(2, 3, [1, 2]);
    hold on;
    plot(timeHours, simResults.timeSeries.queues.registration, 'Color', [0.2, 0.6, 0.8], 'LineWidth', 1.8);
    plot(timeHours, simResults.timeSeries.queues.camera,       'Color', [0.85, 0.25, 0.2], 'LineWidth', 2.2);
    plot(timeHours, simResults.timeSeries.queues.ai,           'Color', [0.15, 0.75, 0.35], 'LineWidth', 1.5, 'LineStyle', '--');
    plot(timeHours, simResults.timeSeries.queues.doctor,       'Color', [0.95, 0.55, 0.1], 'LineWidth', 1.8);
    plot(timeHours, simResults.timeSeries.queues.counselling,  'Color', [0.55, 0.35, 0.75], 'LineWidth', 1.5);
    hold off;
    grid on;
    xlabel('Camp Operating Hours', 'FontSize', 10, 'FontWeight', 'bold');
    ylabel('Queue Length (Patients Waiting)', 'FontSize', 10, 'FontWeight', 'bold');
    title('Station Queue Length Dynamics (8-Hour Shift)', 'FontSize', 12, 'FontWeight', 'bold');
    legend({'Registration Desk', 'Fundus Camera Station', 'Edge AI Node', 'Tele-Ophthalmologist', 'Counselling Desk'}, ...
           'Location', 'northwest', 'FontSize', 9);
    xlim([0, simResults.simParams.campHours]);

    % -----------------------------------------------------------------
    % Subplot 2: Cumulative Arrivals vs Departures
    % -----------------------------------------------------------------
    subplot(2, 3, 3);
    hold on;
    plot(timeHours, simResults.timeSeries.cumulativeArrivals, 'Color', [0.15, 0.45, 0.85], 'LineWidth', 2.0);
    plot(timeHours, simResults.timeSeries.cumulativeDepartures, 'Color', [0.15, 0.65, 0.3], 'LineWidth', 2.0);
    hold off;
    grid on;
    xlabel('Camp Operating Hours', 'FontSize', 10, 'FontWeight', 'bold');
    ylabel('Cumulative Patients', 'FontSize', 10, 'FontWeight', 'bold');
    title('Throughput & Backlog Trajectory', 'FontSize', 12, 'FontWeight', 'bold');
    legend({'Cumulative Arrivals', 'Completed Departures'}, 'Location', 'northwest', 'FontSize', 9);
    xlim([0, simResults.simParams.campHours]);

    % Annotate completion rate
    text(0.55 * simResults.simParams.campHours, 0.25 * simResults.summary.totalArrivals, ...
         sprintf('Completed: %d / %d (%.1f%%)', simResults.summary.totalCompleted, ...
                 simResults.summary.totalArrivals, simResults.summary.completionRatePct), ...
         'FontSize', 9, 'FontWeight', 'bold', 'BackgroundColor', [1 1 1], 'EdgeColor', [0.7 0.7 0.7]);

    % -----------------------------------------------------------------
    % Subplot 3: Patient Total System Time Distribution
    % -----------------------------------------------------------------
    subplot(2, 3, 4);
    systemTimes = [simResults.patients.totalSystemTime];
    histogram(systemTimes, 15, 'FaceColor', [0.35, 0.55, 0.8], 'EdgeColor', [0.2, 0.3, 0.5]);
    hold on;
    xline(simResults.summary.meanSystemTimeMinutes, 'r--', ...
          sprintf('Mean: %.1f m', simResults.summary.meanSystemTimeMinutes), ...
          'LineWidth', 2.0, 'LabelVerticalAlignment', 'top', 'FontSize', 9);
    xline(simResults.summary.p95SystemTimeMinutes, 'm:', ...
          sprintf('95th: %.1f m', simResults.summary.p95SystemTimeMinutes), ...
          'LineWidth', 2.0, 'LabelVerticalAlignment', 'bottom', 'FontSize', 9);
    hold off;
    grid on;
    xlabel('Total Visit Time (Minutes)', 'FontSize', 10, 'FontWeight', 'bold');
    ylabel('Patient Count', 'FontSize', 10, 'FontWeight', 'bold');
    title('Total System Time Distribution (Arrival to Exit)', 'FontSize', 11, 'FontWeight', 'bold');

    % -----------------------------------------------------------------
    % Subplot 4: Resource Server Utilization & Bottleneck
    % -----------------------------------------------------------------
    subplot(2, 3, 5);
    categories = {'Registration', 'Camera', 'Edge AI', 'Doctor Review', 'Counselling'};
    utilValues = [simResults.stationMetrics.registration.serverUtilization, ...
                  simResults.stationMetrics.camera.serverUtilization, ...
                  simResults.stationMetrics.ai.serverUtilization, ...
                  simResults.stationMetrics.doctor.serverUtilization, ...
                  simResults.stationMetrics.counselling.serverUtilization] * 100;

    b = bar(utilValues, 0.55);
    b.FaceColor = 'flat';
    for k = 1:numel(utilValues)
        if utilValues(k) > 75
            b.CData(k, :) = [0.85, 0.25, 0.2]; % Red: Critical bottleneck
        elseif utilValues(k) > 40
            b.CData(k, :) = [0.95, 0.65, 0.15]; % Amber: Moderate load
        else
            b.CData(k, :) = [0.25, 0.65, 0.35]; % Green: Efficient
        end
    end
    grid on;
    set(gca, 'XTickLabel', categories, 'FontSize', 8);
    xtickangle(25);
    ylabel('Server Utilization (%)', 'FontSize', 10, 'FontWeight', 'bold');
    ylim([0, 110]);
    yline(80, 'k--', 'Capacity Limit (80%)', 'LineWidth', 1.2, 'FontSize', 8);
    title(sprintf('Server Utilization (Bottleneck: %s)', simResults.summary.bottleneckStation), ...
          'FontSize', 11, 'FontWeight', 'bold');

    % -----------------------------------------------------------------
    % Subplot 5: Station Waiting Time Breakdown
    % -----------------------------------------------------------------
    subplot(2, 3, 6);
    stnNames = {'Registration', 'Camera', 'Edge AI', 'Doctor Review', 'Counselling'};
    meanWaits = [simResults.stationMetrics.registration.meanWaitMinutes, ...
                 simResults.stationMetrics.camera.meanWaitMinutes, ...
                 simResults.stationMetrics.ai.meanWaitMinutes, ...
                 simResults.stationMetrics.doctor.meanWaitMinutes, ...
                 simResults.stationMetrics.counselling.meanWaitMinutes];
    p95Waits = [simResults.stationMetrics.registration.p95WaitMinutes, ...
                simResults.stationMetrics.camera.p95WaitMinutes, ...
                simResults.stationMetrics.ai.p95WaitMinutes, ...
                simResults.stationMetrics.doctor.p95WaitMinutes, ...
                simResults.stationMetrics.counselling.p95WaitMinutes];

    barData = [meanWaits; p95Waits]';
    bWait = bar(barData, 0.7);
    bWait(1).FaceColor = [0.2, 0.45, 0.75]; % Mean
    bWait(2).FaceColor = [0.9, 0.4, 0.2];   % P95
    grid on;
    set(gca, 'XTickLabel', stnNames, 'FontSize', 8);
    xtickangle(25);
    ylabel('Waiting Time (Minutes)', 'FontSize', 10, 'FontWeight', 'bold');
    legend({'Mean Wait', '95th Percentile'}, 'Location', 'northeast', 'FontSize', 8);
    title('Station Waiting Time Comparison', 'FontSize', 11, 'FontWeight', 'bold');

    % Master Super Title
    sgtitle(sprintf('SIH26038: Rural Screening Camp Queueing & Capacity Analysis (N=%d Patients, 8-Hr Shift)', ...
                    simResults.summary.totalArrivals), 'FontSize', 14, 'FontWeight', 'bold');

    % Export to Disk
    try
        exportgraphics(fig, outputPath, 'Resolution', 300);
        logger.info('Simulink queueing figure exported to: %s', outputPath);
    catch
        % Fallback for older MATLAB versions
        saveas(fig, outputPath);
        logger.info('Saved figure using saveas: %s', outputPath);
    end
end
