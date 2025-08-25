import Chart from 'chart.js/auto';
import ChartDataLabels from 'chartjs-plugin-datalabels';

function initializeDoughnutCharts() {
  document.querySelectorAll('.doughnut-chart').forEach(chartElem => {
  const ctx = chartElem.getContext('2d');
  
  // Destroy existing chart if it exists
  if (Chart.getChart(ctx)) {
    Chart.getChart(ctx).destroy();
  }
  
  const labels = JSON.parse(chartElem.dataset.labels);
  const newCustomerValues = JSON.parse(chartElem.dataset.newCustomerValues);
  const existingCustomerValues = JSON.parse(chartElem.dataset.existingCustomerValues);
  const enhancedLegend = chartElem.dataset.enhancedLegend || "false";

  new Chart(ctx, {
      type: 'doughnut',
      plugins: [ChartDataLabels],
      data: {
        labels: labels,
        datasets: [
          {
            data: [newCustomerValues, existingCustomerValues],
            backgroundColor: [
              'rgb(239, 108, 77)',
              'rgb(152, 194, 218)'
            ]
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            reverse: true,
            onClick: {},
            labels: enhancedLegend === "true" ? {
              font: {
                size: 15,
                weight: '700',
              }
            } : undefined
          },
          datalabels: {
            display: true,
            color: 'black',
            font: {
              weight: 500,
              size: 17
            },
            anchor: 'center',
            align: 'center',
            formatter: (value, ctx) => {
              const total = ctx.chart.data.datasets[0].data.reduce((a, b) => a + b, 0);
              const percentage = (value / total) * 100;
              return `${value} (${percentage.toFixed(1)}%)`;
            }
          }
        }
      }
  });
  });
}

document.addEventListener('DOMContentLoaded', initializeDoughnutCharts);
document.addEventListener('turbo:load', initializeDoughnutCharts);