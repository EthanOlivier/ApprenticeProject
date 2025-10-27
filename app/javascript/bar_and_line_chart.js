import Chart from 'chart.js/auto';

function initializeBarAndLineCharts() {
    document.querySelectorAll('.bar-and-line-chart').forEach(chartElem => {
        const ctx = chartElem.getContext('2d');
            
        // Destroy existing chart if it exists
        if (Chart.getChart(ctx)) {
            Chart.getChart(ctx).destroy();
        }

        const labels = JSON.parse(chartElem.dataset.labels);
        const barLabels = JSON.parse(chartElem.dataset.barLabels);
        const lineLabels = JSON.parse(chartElem.dataset.lineLabels);
        const barValues = JSON.parse(chartElem.dataset.barValues);
        const lineValues = JSON.parse(chartElem.dataset.lineValues);
        const barBorderColors = JSON.parse(chartElem.dataset.barBorderColors);
        const barBackgroundColors = JSON.parse(chartElem.dataset.barBackgroundColors);
        const lineColors = JSON.parse(chartElem.dataset.lineColors);

        new Chart(ctx, {
            data: {
                labels: labels,
                datasets: [
                    ...barLabels.map((label, index) => (
                        {
                            type: 'bar',
                            label: label,
                            data: barValues[index],
                            backgroundColor: barBackgroundColors[index],
                            borderColor: barBorderColors[index],
                            borderWidth: 3,
                            order: 1,
                            hidden: Math.max(...barValues[index]) === 0
                        }
                    )),
                    ...lineLabels.map((label, index) => (
                        {
                            type: 'line',
                            label: label,
                            data: lineValues[index],
                            borderColor: lineColors[index],
                            backgroundColor: lineColors[index].replace('rgb', 'rgba').replace(')', ', 0.35)'),
                            pointBackgroundColor: 'white',
                            fill: false,
                            borderWidth: 4,
                            tension: 0.1,
                            order: 0,
                            hidden: Math.max(...lineValues[index]) === 0
                        }
                    ))
                ],
            },
            options: {
                maintainAspectRatio: true,
                responsive: true,
                elements: {
                    point: {
                        radius: 5,
                        borderWidth: 2
                    },
                    line: {
                        borderWidth: 4
                    },
                },
                scales: {
                    x: {
                        ticks: {
                        maxTicksLimit: 12
                        },
                    },
                    y: {
                        beginAtZero: true,
                        ticks: {
                        maxTicksLimit: 5
                        }
                    }
                },
                plugins: {
                    legend: {
                        position: "bottom",
                        onClick: Chart.defaults.plugins.legend.onClick,
                        labels: {
                            boxWidth: 40,
                            boxHeight: 15,
                            color: "black",
                            font: {
                                size: 17
                            },
                            generateLabels: function(chart) {
                                var data = chart.data;
                                if (data.datasets.length) {
                                    return data.datasets.map(function(dataset, i) {
                                        const backgroundColorRGB = dataset.borderColor?.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/);

                                        return {
                                            text: dataset.label,
                                            fillStyle: `rgba(${backgroundColorRGB[1]}, ${backgroundColorRGB[2]}, ${backgroundColorRGB[3]}, 0.35)`,
                                            strokeStyle: dataset.borderColor,
                                            lineWidth: 4,
                                            hidden: !chart.isDatasetVisible(i),
                                            index: i,
                                            datasetIndex: i
                                        };
                                    });
                                }
                                return [];
                            },
                        }
                    },
                    tooltip: {
                        callbacks: {
                            title: function(context) {
                                return context[0].dataset.label;
                            },
                            label: function(context) {
                                let singleDayValue = 0;
                                if (context.dataIndex > 0) {
                                    singleDayValue = context.dataset.data[context.dataIndex] - context.dataset.data[context.dataIndex - 1];
                                }
                                else {
                                    singleDayValue = context.formattedValue;
                                }
                                if (singleDayValue < 0) {
                                    return `${context.formattedValue} (${singleDayValue})`;
                                }
                                else {
                                    return `${context.formattedValue} (+${singleDayValue})`;
                                }
                            }
                        }
                    },
                    filler: {
                        drawTime: "beforeDatasetsDraw" // allows the secondary line to be drawn over the primary lines fill
                    },
                }
            }
        });
    });
}

document.addEventListener('DOMContentLoaded', initializeBarAndLineCharts);
document.addEventListener('turbo:load', initializeBarAndLineCharts);