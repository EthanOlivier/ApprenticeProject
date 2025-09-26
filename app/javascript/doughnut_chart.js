import Chart from 'chart.js/auto';
import ChartDataLabels from 'chartjs-plugin-datalabels';

function initializeDoughnutCharts() {
  document.querySelectorAll('.doughnut-chart').forEach(chartElem => {
    const ctx = chartElem.getContext('2d');
    
    // Destroy existing chart if it exists
    if (Chart.getChart(ctx)) {
      Chart.getChart(ctx).destroy();
    }

    const plugins = [ChartDataLabels];
    
    const labels = JSON.parse(chartElem.dataset.labels);
    const newCustomerValues = JSON.parse(chartElem.dataset.newCustomerValues);
    const returningCustomerValues = JSON.parse(chartElem.dataset.returningCustomerValues);
    const enhancedLegend = chartElem.dataset.enhancedLegend || "false";

    const hasData = (returningCustomerValues + newCustomerValues) > 0;
    if (!hasData) {
      plugins.push(emptyDoughnutPlugin);
    }

    new Chart(ctx, {
        type: 'doughnut',
        plugins: plugins,
        data: {
          labels: labels,
          datasets: [
            {
              data: [returningCustomerValues, newCustomerValues],
              backgroundColor: [
                'rgba(152, 194, 218, 0.75)',
                'rgba(239, 108, 77, 0.75)'
              ],
              borderColor: [
                'rgb(152, 194, 218)',
                'rgb(239, 108, 77)'
              ],
              borderWidth: 3,
              fill: false
            }
          ]
        },
        options: {
          maintainAspectRatio: true,
          responsive: true,
          plugins: {
            datalabels: {     // labels inside the doughnut segments
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
                if (total === 0) {
                  return ``;
                }
                const percentage = (value / total) * 100;
                return [`${value} `, `(${percentage.toFixed(1)}%)`];
              }
            },
            legend: {
              onClick: {},
              reverse: true,
              position: enhancedLegend === "true" ? "bottom" : "top",
              labels: enhancedLegend === "true" ? {
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
                      const originalColor = data.datasets[0].backgroundColor[i];
                      const rgbaMatch = originalColor.match(/rgba\((\d+),\s*(\d+),\s*(\d+),\s*[\d.]+\)/);
                      const boxColor = rgbaMatch
                        ? `rgba(${rgbaMatch[1]}, ${rgbaMatch[2]}, ${rgbaMatch[3]}, 0.35)`
                        : originalColor;

                      return {
                        text: label,
                        fillStyle: boxColor,
                        strokeStyle: data.datasets[0].borderColor[i],
                        lineWidth: 4,
                        index: i
                      };
                    });
                  }
                  return [];
                }
              } : {
                font: {
                  size: 15
                }
              }
            },
            ...(hasData ? {} : {
              emptyDoughnut: {
                color: 'rgb(152, 194, 218)',
                width: 3,
                radiusDecrease: 20
              }
            })
          }
        }
    });
  });
}

const emptyDoughnutPlugin = {
  id: 'emptyDoughnut',
  afterDraw(chart, _, options) {
    const {datasets} = chart.data;
    const {color, width, radiusDecrease} = options;
    let hasData = false;
    
    for (let i = 0; i < datasets.length; i += 1) {
      const dataset = datasets[i];
      const total = dataset.data.reduce((a, b) => a + b, 0);
      hasData |= total > 0;
    }
    
    if (!hasData) {
      const {chartArea: {left, top, right, bottom}, ctx} = chart;
      const centerX = (left + right) / 2;
      const centerY = (top + bottom) / 2;
      const r = Math.min(right - left, bottom - top) / 2;
      
      // Draw the circle
      ctx.beginPath();
      ctx.lineWidth = width || 2;
      ctx.strokeStyle = color || 'rgba(152, 194, 218, 0.5)';
      ctx.arc(centerX, centerY, (r - radiusDecrease || 0), 0, 2 * Math.PI);
      ctx.stroke();
      
      // Draw center text
      ctx.save();
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillStyle = 'black';
      ctx.font = '600 17px sans-serif';
      ctx.fillText('0', centerX, centerY - 8);
      ctx.restore();
    }
  }
};

// Change the default doughnut chart legend style to the same style as line charts
// Chart.overrides.doughnut.plugins.legend.labels = {
//   generateLabels: Chart.overrides.doughnut.plugins.legend.labels.generateLabels, // generateLabels function is required
//   font: Chart.defaults.font,
// };

document.addEventListener('DOMContentLoaded', initializeDoughnutCharts);
document.addEventListener('turbo:load', initializeDoughnutCharts);
