import Chart from 'chart.js/auto';
// import ChartFillerPlugin from 'chartjs-plugin-filler';

function initializeLineCharts() {
  document.querySelectorAll('.line-chart').forEach(chartElem => {
    const ctx = chartElem.getContext('2d');
    
    // Destroy existing chart if it exists
    if (Chart.getChart(ctx)) {
      Chart.getChart(ctx).destroy();
    }
    
    const labels = JSON.parse(chartElem.dataset.labels);
    const primaryLegendLabel = chartElem.dataset.primaryLegendLabel || "Primary";
    const secondaryLegendLabel = chartElem.dataset.secondaryLegendLabel || "Secondary";
    const primaryColor = chartElem.dataset.primaryColor || 'rgb(239, 108, 77)';
    const secondaryColor = chartElem.dataset.secondaryColor || 'rgb(152, 194, 218)';
    const primaryValues = JSON.parse(chartElem.dataset.primaryValues);
    const secondaryValues = JSON.parse(chartElem.dataset.secondaryValues);
    const enhancedLegend = chartElem.dataset.enhancedLegend || "false";


    new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [
          {
            data: primaryValues,
            label: primaryLegendLabel,
            borderColor: primaryColor,
            backgroundColor: primaryColor.replace('rgb', 'rgba').replace(')', ', 0.35)'),
            pointBackgroundColor: 'white',
            fill: "origin",
            order: 0,
            tension: 0.1
          },
          {
            data: secondaryValues,
            label: secondaryLegendLabel,
            borderColor: secondaryColor,
            backgroundColor: secondaryColor.replace('rgb', 'rgba').replace(')', ', 0.35)'),
            pointBackgroundColor: 'white',
            fill: false,
            order: 1,
            tension: 0.1
          }
        ]
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
            position: enhancedLegend === "true" ? "bottom" : "top",
            labels: enhancedLegend === "true" ? {
              color: 'black',
              font: {
                size: 16
              }
            } : {
              font: {
                size: 15
              }
            }
          },
          tooltip: {
            callbacks: {
              title: function(context) {
                // Checks to see if the label can be used to create a date
                // to determine if it should place the day of the month afterwards
                const date = new Date(`${context[0].label} ${new Date().getFullYear()}`);
                if (isNaN(date) == false) {
                  return `${context[0].dataset.label} ${date.getDate()}`;
                } else {
                  return context[0].dataset.label;
                }
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

document.addEventListener('DOMContentLoaded', initializeLineCharts);
document.addEventListener('turbo:load', initializeLineCharts);