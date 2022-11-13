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
 * Initialise an auto-discovered chart element
 *
 * @param {Element} element Chart element
 */
function initialiseChartElement(element)
{
    let context = element.getAttribute('avalanche:data-source');

    var options = {
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
        noData: {
            text: 'Loading graph'
        },
        xaxis: {
            type: 'datetime',
            labels: {
                show: false
            }
        },
    };
    var chart = new ApexCharts(element, options);
    chart.render();

    if (context !== 'memory')
    {
        return;
    }

    updateChart(element, chart);

    /* Update on interval */
    setInterval(ev => {
        updateChart(element, chart);
        return true;
    }, 1000);
}

/**
 * Update a chart using the Stats API
 *
 * @param {Element} element div for the chart
 * @param {ApexChart} chart corresponding Chart object
 */
function updateChart(element, chart)
{
    const uri = '/api/v1/stats/memory';
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
        let series = [{
            name: 'Free',
            data: obj.free.map((o) => {
                return {
                    x: o.timestamp * 1000,
                    y: o.value
                }
            })
        },
        {
            name: 'Available',
            data: obj.available.map((o) => {
                return {
                    x: o.timestamp * 1000,
                    y: o.value
                }
            })
        },
        {
            name: 'Used',
            data: obj.used.map((o) => {
                return {
                    x: o.timestamp * 1000,
                    y: o.value
                }
            })
        }];
        let opts = {
            series: series,
            yaxis: {
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
                max: obj.total,
                min: 0
            },
        };
        chart.updateOptions(opts);
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