import Chart from 'chart.js/auto';
import ChartDataLabels from 'chartjs-plugin-datalabels';

function initializePieCharts() {
  document.querySelectorAll('.pie-chart').forEach(chartElem => {
    const ctx = chartElem.getContext('2d');
    
    // Destroy existing chart if it exists
    if (Chart.getChart(ctx)) {
      Chart.getChart(ctx).destroy();
    }

    const plugins = [ChartDataLabels];
    
    const labels = JSON.parse(chartElem.dataset.labels);
    const value1 = Number(chartElem.dataset.value1);
    const value2 = Number(chartElem.dataset.value2);
    const value3 = Number(chartElem.dataset.value3);
    const value4 = Number(chartElem.dataset.value4);

    new Chart(ctx, {
        type: 'pie',
        plugins: plugins,
        data: {
          labels: labels.reverse(),
          datasets: [
            {
              data: [value4, value3, value2, value1],
              backgroundColor: [
                'rgba(239, 189, 77, 0.75)',
                'rgba(152, 218, 209, 0.75)',
                'rgba(152, 194, 218, 0.75)',
                'rgba(239, 108, 77, 0.75)',
              ],
              borderColor: [
                'rgb(239, 189, 77)',
                'rgb(152, 218, 209)',
                'rgb(152, 194, 218)',
                'rgb(239, 108, 77)',
              ],
              borderAlign: 'inner',
              borderWidth: 3,
              fill: false
            }
          ]
        },
        options: {
          maintainAspectRatio: true,
          responsive: true,
          onClick: (event, activeElements, chart) => {
            if (activeElements.length > 0) {
              const clickedIndex = activeElements[0].index;
              chart.options.plugins.legend.onClick.call(chart, event, { text: labels[clickedIndex], index: clickedIndex }, chart.legend);
            }
          },
          plugins: {
            datalabels: {     // labels inside the pie segments
              display: true,
              color: 'black',
              font: {
                weight: 500,
                size: 17
              },
              align: 'center',
              anchor: 'center',
              textAlign: 'center',
              formatter: (value, ctx) => {
                const total = ctx.chart.data.datasets[0].data.reduce((a, b) => a + b, 0);
                if (total === 0 || value === 0) {
                  return ``;
                }
                const percentage = (value / total) * 100;
                if (percentage < 5) {
                  return '';
                }
                else if (percentage < 10) {
                  return [`${value}`, ''];
                }
                else
                {
                  return [`${value} `, `(${percentage.toFixed(1)}%)`];
                }
              }
            },
            legend: {
              position: "bottom",
              reverse: true,
              labels: {
                boxWidth: 40,
                boxHeight: 15,
                color: "black",
                font: {
                  size: 17
                },
                generateLabels: function(chart) {
                  var data = chart.data;
                  if (data.labels.length && data.datasets.length) {
                    return data.labels.map(function(label, i) {
                      const backgroundColorRGBA = data.datasets[0].backgroundColor[i].match(/rgba\((\d+),\s*(\d+),\s*(\d+),\s*[\d.]+\)/);

                      console.log(data.datasets[0].data);

                      return {
                        text: label,
                        fillStyle: `rgba(${backgroundColorRGBA[1]}, ${backgroundColorRGBA[2]}, ${backgroundColorRGBA[3]}, 0.35)`,
                        strokeStyle: data.datasets[0].borderColor[i],
                        lineWidth: 4,
                        hidden: !chart.getDataVisibility(i) || data.datasets[0].data[i] === 0,
                        index: i
                      };
                    });
                  }
                  return [];
                }
              }
            },
            tooltip: {
              callbacks: {
                title: function(context) {
                  return context.label;
                },
                label: function(context) {
                  const value = context.parsed;
                  const total = context.dataset.data.reduce((a, b) => a + b, 0);
                  const percentage = (value / total) * 100;
                  return `${value} (${percentage.toFixed(1)}%)`;
                },
              }
            }
          }
        }
    });
  });
}

document.addEventListener('DOMContentLoaded', initializePieCharts);
document.addEventListener('turbo:load', initializePieCharts);