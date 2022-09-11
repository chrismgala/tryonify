import React, { useEffect, useRef } from 'react';
import PropTypes from 'prop-types';
import Chartjs from 'chart.js/auto';

export default function Chart({ data }) {
  const canvas = useRef(null);
  const chart = useRef(null);

  useEffect(() => {
    const config = {
      type: 'line',
      data,
      options: {
        responsive: true,
        animation: false,
        plugins: {
          legend: {
            display: false,
          },
        },
        scales: {
          y: {
            ticks: {
              stepSize: 1,
            },
          },
        },
      },
    };

    if (!chart.current) {
      chart.current = new Chartjs(canvas.current, config);
    } else {
      chart.current.data = data;
      chart.current.update();
    }
  }, [data]);

  return (
    <div>
      <canvas ref={canvas} />
    </div>
  );
}

Chart.propTypes = {
  data: PropTypes.shape({
    labels: PropTypes.arrayOf(PropTypes.string),
    datasets: PropTypes.arrayOf(PropTypes.shape({})),
  }).isRequired,
};
