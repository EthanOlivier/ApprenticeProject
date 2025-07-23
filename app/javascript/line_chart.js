import Chart from 'chart.js/auto';

document.addEventListener('DOMContentLoaded', () => {
  const chartElem = document.getElementById('move-ins-chart');
  const ctx = chartElem.getContext('2d');
  const labels = JSON.parse(chartElem.dataset.labels);
  const currentValues = JSON.parse(chartElem.dataset.currentValues);
  const lastValues = JSON.parse(chartElem.dataset.lastValues);

  const firstDate = new Date(labels[1]);
  const monthName = firstDate.toLocaleString('en-US', { month: 'long' });

  const lastDate = new Date(labels[0]);
  const lastMonthName = lastDate.toLocaleString('en-US', { month: 'long' });

  new Chart(ctx, {
    type: 'line',
    data: {
      labels: labels,
      datasets: [
        {
          label: `${monthName}'s Move Ins`,
          data: currentValues,
          pointBackgroundColor: 'white',
          borderColor: 'rgb(75, 192, 192)',
          tension: 0.1
        },
        {
          label: `${lastMonthName}'s Move Ins`,
          data: lastValues,
          pointBackgroundColor: 'white',
          borderColor: 'rgba(180, 63, 63, 0.8)',
          tension: 0.1
        }
      ]
    },
    options: {
      responsive: false,
      elements: {
        point: {
          radius: 5,
          borderWidth: 2
        }
      },
      scales: {
        x: {
          ticks: {
            callback: function(val) {
              const dateString = this.getLabelForValue(val + 1);
              const date = new Date(dateString);

              if (date.getDate() === 1 || date.getDate() % 7 === 0) {
                return date.toLocaleDateString('en-US', {
                  month: 'short',
                  day: 'numeric'
                });
              }
            }
          },
        },
        y: {
          beginAtZero: true,
          ticks: {
            stepSize: 1,
            callback: function(value) {
              if (Number.isInteger(value)) {
                return value;
              }
              return '';
            }
          }
        }
      }
    }
  });
});