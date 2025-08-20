import Chart from 'chart.js/auto';
import ChartDataLabels from 'chartjs-plugin-datalabels';

function initializeDoughnutCharts() {
  document.querySelectorAll('.doughnut-chart').forEach(chartElem => {
  const ctx = chartElem.getContext('2d');
  const labels = JSON.parse(chartElem.dataset.labels);
  const newCustomerValues = JSON.parse(chartElem.dataset.newCustomerValues);
  const existingCustomerValues = JSON.parse(chartElem.dataset.existingCustomerValues);

  new Chart(ctx, {
      type: 'doughnut',
      plugins: [ChartDataLabels],
      data: {
        labels: labels,
        datasets: [
          {
            data: [newCustomerValues, existingCustomerValues],
            backgroundColor: [
              '#3B82F6',
              '#EF4444'
            ]
          }
        ]
      },
      options: {
        responsive: false,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'top',
            reverse: true,
            font: {
              size: 18,
              weight: '400'
            }
          },
          datalabels: {
            display: true,
            color: 'black',
            font: {
              weight: 400,
              size: 18
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