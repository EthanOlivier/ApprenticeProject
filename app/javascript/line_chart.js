import Chart from 'chart.js/auto';

document.addEventListener('DOMContentLoaded', () => {
  const ctx = document.getElementById('move-ins-chart').getContext('2d');
  const labels = JSON.parse(document.getElementById('move-ins-chart').dataset.labels);
  const values = JSON.parse(document.getElementById('move-ins-chart').dataset.values);
  console.log("Running line_chart.js");

  new Chart(ctx, {
    type: 'line',
    data: {
      labels: labels,
      datasets: [{
        label: 'Move Ins',
        data: values,
        borderColor: 'rgb(75, 192, 192)',
        tension: 0.1
      }]
    },
    options: {
      responsive: false
    }
  });
});