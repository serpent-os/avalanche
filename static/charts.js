/*
 * SPDX-FileCopyrightText: Copyright © 2020-2022 Serpent OS Developers
 *
 * SPDX-License-Identifier: Zlib
 */

/**
 * charts.js
 *
 * Simple system metrics for Avalanche landing page
 *
 * Authors: Copyright © 2020-2022 Serpent OS Developers
 * License: Zlib
 */

/**
 * 5-step labels just rendered as percentages
 */
const PercentLabels = Object.freeze(
    {
        0: 0.00,
        1: 0.25,
        2: 0.50,
        3: 0.75,
        4: 1.0,
    }
);

/**
 * Our global options default to area view
 */
const globalOptions = {
    chart: {
        type: 'area',
        parentHeightOffset: 0,
        fontFamily: 'inherit',
        height: 240,
        toolbar: {
            show: false
        },
        dataLabels: {
            enabled: true
        },
        animations: {
            enabled: true,
            animateGradually: false,
            easing: 'easein',
            speed: 150,
            dynamicAnimation: {
                speed: 150
            }
        },
        tooltip: {
            theme: 'dark'
        },
    },
    colors: [tabler.getColor("purple"), tabler.getColor("info"), tabler.getColor("primary")],
    dataLabels: {
        enabled: false
    },
    grid: {
        show: false
    },
    legend: {
        show: true
    },
    series: [],
    stroke: {
        width: 2,
        curve: 'smooth',
        lineCap: 'round'
    },
    fill: {
        opacity: .16,
        type: 'solid'
    },
    xaxis: {
        type: 'datetime',
        labels: {
            show: false
        }
    },
    yaxis: {}
}

/**
 * Initialise an auto-discovered chart element
 *
 * @param {Element} element Chart element
 */
function initialiseChartElement(element)
{
    let dataSource = element.getAttribute('avalanche:data-source');
    let dataForm = element.getAttribute('avalanche:data-form')
    let dataFrequency = parseInt(element.getAttribute('avalanche:data-frequency'));
    let dataTotalEl = element.getAttribute('avalanche:data-total');

    let options = Object.assign({}, globalOptions);
    options.chart.type = dataForm;

    switch (dataSource)
    {
        case 'memory':
            options.yaxis =  {
                type: 'numeric',
                tickAmount: 4,
                labels: {
                    formatter: function(val, idx)
                    {
                        /* If its not an index in the series, render as GiB, otherwise percent */
                        if (!idx.hasOwnProperty('dataPointIndex'))
                        {
                            return Number(PercentLabels[idx]).toLocaleString(undefined, {style: 'percent', minimumFractionDigits: 0});
                        }
                        return ((parseInt(val) / 1024 / 1024 / 1024).toFixed(1))  + "GiB";
                    }
                },
                min: 0
            };
            break;
        case 'disk':
            options.colors = [tabler.getColor('primary'), tabler.getColor('warning', 0.7)];

            delete options.fill;
            options.chart.animations.enabled = false;
            break;
        case 'cpu':
            delete options.colors;
            delete options.fill;
            options.yaxis =  {
                type: 'numeric',
                labels: {
                    formatter: function(val, idx)
                    {
                        return ((parseInt(val) / 1024 / 1024).toFixed(1))  + "GHz";
                    }
                }
            };
            break;
        default:
            console.log('Unsupported chart');
            return;
    }

    /* Record total value in the index page */
    if (dataTotalEl !== null)
    {
        options.yaxis.max = parseFloat(dataTotalEl);
    }

    var chart = new ApexCharts(element, options);
    chart.render();

    updateChart(element, chart, dataSource);
    setInterval(() => {
        updateChart(element, chart, dataSource);
        return true;
    }, dataFrequency);
}

/**
 * Update memory chart using the Stats API
 *
 * @param {Element} element div for the chart
 * @param {ApexChart} chart corresponding Chart object
 */
function updateChart(element, chart, domain)
{
    const uri = `/api/v1/stats/${domain}`;
    fetch(uri, {
        credentials: 'include',
        method: 'GET',
        headers: {
            'Accept': 'application/json'
        }
    }).then((response) => {
        if (!response.ok) {
            throw new Error('Charts: ' + response.statusText);
        }
        return response.json();
    }).then((obj) => {
        let options = {
            series: obj.series
        };
        if (obj.hasOwnProperty('labels'))
        {
            options.labels = obj.labels;
        }
        chart.updateOptions(options);
    }).catch((err) => console.log(err));
}

/**
 * Preload all charts ready for loading
 */
document.addEventListener('DOMContentLoaded', function(ev)
{
    Array.from(document.getElementsByClassName('chart')).forEach(
            (element) => {
                initialiseChartElement(element);
            }
    );
});