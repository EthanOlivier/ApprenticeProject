import Chart from 'chart.js/auto';

document.querySelectorAll('.chart').forEach(chartElem => {
    const ctx = chartElem.getContext('2d');
    const labels = JSON.parse(chartElem.dataset.labels);
    const reportMonthValues = JSON.parse(chartElem.dataset.reportMonthValues);
    const priorMonthValues = JSON.parse(chartElem.dataset.priorMonthValues);

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
          label: `${monthName}`,
          data: reportMonthValues,
          pointBackgroundColor: 'white',
          borderColor: 'rgb(75, 192, 255)',
          tension: 0.1
        },
        {
          label: `${lastMonthName}`,
          data: priorMonthValues,
          pointBackgroundColor: 'white',
          borderColor: 'rgba(180, 63, 63, 0.35)',
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
            maxTicksLimit: 5,
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